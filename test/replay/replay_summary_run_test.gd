# TASK-14, the whole road of the replay summary (testes-e-entrega.md §4, "O resumo"): a Sozinho
# session with the player and the dummy, recorded by the real ReplayRecorder, plays again through
# the headless player (tools/replay_run.gd), and the summary (tools/replay_summary.gd) is fed its
# state trace, parsed back line by line, with the inputs of the file's rows. The session opens as
# test/replay/replay_light_attack_test.gd's: the player walks from its spawn point to about 2 m of
# the dummy, and the two trade lights on the same tick, each landing one. Then the player clicks
# again in the hitstun of the hit it took. The summary must count what the session had: the
# clicks, one swing each, a hit on the other, the trade on one tick, the click lost in the stun
# and the lowest health the live run saw. Recorded in a temporary folder, in about a second.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")
const ReplayRun := preload("res://tools/replay_run.gd")
const ReplaySummary := preload("res://tools/replay_summary.gd")

## netfox's clock on the first tick, and the loops of the session with their sizes, in turn: frames
## at 60, 30 and 20 fps.
const FIRST_TICK := 4000
const LOOPS := 90
const LOOP_SIZES: Array[int] = [1, 2, 1, 3]
## The spawn points' yaws (arena.tscn): SpawnA looks down -Z at the dummy, SpawnB back. The player
## walks down -Z until its feet pass STOP_Z, and coasts to about 2 m from the dummy, within the
## reach of 2,43 m (combate.md, "A lâmina e o contato").
const YAWS: Array[float] = [0.0, PI]
const STOP_Z := 1.4
## The loop both fighters click the light on, counted from the loop the player stopped walking.
const TRADE := 10
const LIGHT := FighterCommand.LIGHT_ATTACK


# What the live run saw of each fighter, loop by loop.
class Session:
	var text: String
	var hits_taken: Array[int] = [0, 0]
	var lowest_health: Array[int] = []
	## The tick, counted from the first, of the player's click in its hitstun; -1 before it.
	var stun_click := -1


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


func test_the_summary_of_a_recorded_session_counts_its_clicks_swings_hits_and_health() -> void:
	var folder := OS.get_temp_dir().path_join("jogo-acrobatico-summary-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder.path_join("summary.replay")
	var session := await _record(path)
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(folder)
	var replay := ReplayFile.parse(session.text)
	replay.judge(ReplayFile.this_build())
	assert_array(replay.messages(false)).is_empty()
	# The precondition: the live run had the trade, a hit on each, and the click in the stun.
	assert_array(session.hits_taken).is_equal([1, 1])
	assert_int(session.stun_click).is_greater(0)
	var result := await ReplayRun.new().play(self, replay, replay.movement_data())
	assert_bool(result.checked).is_true()
	assert_int(result.first_apart).is_equal(-1)
	var tickrate := replay.header["tickrate"].to_int()
	var summary := ReplaySummary.new(
		MovementConfig.create(result.movement_data, tickrate),
		CombatConfig.create(result.combat_data, tickrate),
	)
	summary.feed(replay, result.trace)
	summary.finish()
	assert_int(summary.fighter_count()).is_equal(2)
	for fighter: int in 2:
		var report := summary.fighter(fighter)
		assert_int(report.ticks).is_equal(replay.tick_count())
		assert_int(report.swings.size()).is_equal(1)
		var swing := report.swings[0]
		assert_str(swing.move).is_equal(LIGHT)
		assert_str(swing.result).is_equal(ReplaySummary.HIT)
		assert_int(swing.target).is_equal(1 - fighter)
		assert_float(swing.first_active_distance).is_less(summary.reach())
		assert_int(report.lowest_health).is_equal(session.lowest_health[fighter])
	# The trade: both swings fired on one tick and landed on one tick.
	var mine := summary.fighter(0).swings[0]
	var theirs := summary.fighter(1).swings[0]
	assert_int(mine.fire_tick).is_equal(theirs.fire_tick)
	assert_int(mine.contact_tick).is_equal(theirs.contact_tick)
	# The clicks: the dummy's one, which fired; the player's two, the second lost in the stun.
	assert_int(summary.fighter(1).presses.size()).is_equal(1)
	var clicks := summary.fighter(0).presses
	assert_int(clicks.size()).is_equal(2)
	assert_int(clicks[0].fired_tick).is_equal(mine.fire_tick)
	assert_int(clicks[1].tick).is_equal(session.stun_click)
	assert_int(clicks[1].fired_tick).is_equal(-1)
	assert_str(clicks[1].reason).is_equal(ReplaySummary.STUN)
	var ticks := ReplaySummary.whole(replay.tick_count())
	assert_str(summary.lines()[0]).starts_with("%s ticks a %d por segundo" % [ticks, tickrate])
	# Every line of the trace, the combat's fields in it, reads back into the same line.
	var apart := 0
	for line: String in result.trace.lines():
		var row := StateTrace.parse_line(line)
		var again := ""
		if row != null:
			again = StateTrace.line_from(
				row.tick,
				row.fighter,
				row.position,
				row.velocity,
				row.state,
				0,
			)
		apart += 0 if again == line else 1
	assert_int(apart).is_equal(0)


func _record(path: String) -> Session:
	NetfoxTicks.reset()
	NetfoxTicks.set_tick(FIRST_TICK)
	var stage := SubViewport.new()
	stage.own_world_3d = true
	add_child(stage)
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match := node as Match
	stage.add_child(game_match)
	var fighters: Array[Fighter] = []
	for slot: int in YAWS.size():
		fighters.append(game_match.spawn_fighter(slot, multiplayer.get_unique_id()))
	var recorder := ReplayRecorder.new()
	stage.add_child(recorder)
	assert(recorder.start(game_match, fighters, path) == OK, "cannot record to %s" % path)
	var session := Session.new()
	var hurt: Array[int] = []
	for fighter: Fighter in fighters:
		hurt.append(fighter.state.hurt_tick)
		session.lowest_health.append(fighter.state.health)
	await get_tree().process_frame
	await get_tree().physics_frame
	var stopped := -1
	for loop: int in LOOPS:
		if stopped < 0 and fighters[0].position.z <= STOP_Z:
			stopped = loop
		for slot: int in fighters.size():
			var input := fighters[slot].input
			var walking := slot == 0 and stopped < 0
			input.sample_frame(Vector2(0, 1) if walking else Vector2.ZERO, YAWS[slot])
			if stopped >= 0 and loop - stopped == TRADE:
				input.press_light_attack()
		# The player, hit in the trade, clicks again on the next loop: deep in its hitstun.
		if session.hits_taken[0] == 1 and session.stun_click < 0:
			fighters[0].input.press_light_attack()
			session.stun_click = NetworkTime.tick - FIRST_TICK
		NetfoxTicks.run_loop(LOOP_SIZES[loop % LOOP_SIZES.size()])
		for slot: int in fighters.size():
			var state := fighters[slot].state
			if state.hurt_tick != hurt[slot]:
				hurt[slot] = state.hurt_tick
				session.hits_taken[slot] += 1
			session.lowest_health[slot] = mini(session.lowest_health[slot], state.health)
	recorder.close()
	stage.free()
	NetfoxTicks.reset()
	session.text = FileAccess.get_file_as_string(path)
	return session
