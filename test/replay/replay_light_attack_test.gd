# Criterion 11 of TASK-12.1 (testes-e-entrega.md §4; DEC-0027 §5; DEC-0051 §6): a Sozinho session
# with light attacks, the player walking from its spawn point to the dummy's and the two trading
# and landing hits, recorded by the real
# ReplayRecorder, plays again through the headless player (tools/replay_run.gd) with the same state
# trace, byte for byte: the light_attack column and the combat's state fields come by reflection,
# and the player plays the combat numbers of the header, the light attack's included. A header
# tuned to another damage plays with it, and the check column says the first tick it leaves the
# live game, the first hit's. A file without the combat numbers, as recorded before TASK-12.1, is
# refused naming them, and plays only with --force, with combat_v0.tres's. The session is recorded
# once for the suite, in a temporary folder.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")
const ReplayRun := preload("res://tools/replay_run.gd")

## netfox's clock on the first tick, and the loops of the session with their sizes, in turn: frames
## at 60, 30 and 20 fps.
const FIRST_TICK := 4000
const LOOPS := 240
const LOOP_SIZES: Array[int] = [1, 2, 1, 3]
## The spawn points, where a replay starts its fighters too: SpawnA at z = 9 looking down -Z, and
## SpawnB at z = -1 looking back (arena.tscn). The player walks down -Z until its feet pass
## STOP_Z, and coasts to about 2 m from the dummy, within the reach of 2,43 m (combate.md, "A
## lâmina e o contato").
const YAWS: Array[float] = [0.0, PI]
const STOP_Z := 1.4
## The loops each fighter presses the light on, counted from the loop the player stopped walking:
## both on the 10th, the trade, then one each, after its own swing of 45 ticks is over.
const PRESSES: Array[Array] = [[10, 70], [10, 120]]
## The damage a tuned header asks for, against the 12 of combat_v0.tres.
const TUNED_DAMAGE := 30
## combate.md, "Os golpes e as defesas": 12 de dano; partida.md: vida 100.
const LIGHT_DAMAGE := 12
const MAX_HEALTH := 100

var _folder := ""
var _session: Session


# What the recording made: the file's text and the live trace.
class Session:
	var text: String
	var trace: StateTrace
	## The hits each fighter took, by its hurt stamp moving, and the lowest health seen.
	var hits := 0
	var lowest_health := MAX_HEALTH
	var bytes_per_row := 0.0


func before() -> void:
	_folder = OS.get_temp_dir().path_join("jogo-acrobatico-light-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(_folder)


func after() -> void:
	for file: String in DirAccess.get_files_at(_folder):
		DirAccess.remove_absolute(_folder.path_join(file))
	DirAccess.remove_absolute(_folder)


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


func _recorded() -> Session:
	if _session == null:
		_session = await _record(_folder.path_join("light.replay"))
	return _session


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
	session.trace = StateTrace.new(FIRST_TICK)
	session.trace.observe(fighters)
	var hurt: Array[int] = [FighterState.NEVER, FighterState.NEVER]
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
			if stopped >= 0 and PRESSES[slot].has(loop - stopped):
				input.press_light_attack()
		NetfoxTicks.run_loop(LOOP_SIZES[loop % LOOP_SIZES.size()])
		for slot: int in fighters.size():
			var state := fighters[slot].state
			if state.hurt_tick != hurt[slot]:
				hurt[slot] = state.hurt_tick
				session.hits += 1
			session.lowest_health = mini(session.lowest_health, state.health)
	session.trace.stop()
	recorder.close()
	var rows := recorder.rows_written
	stage.free()
	NetfoxTicks.reset()
	session.text = FileAccess.get_file_as_string(path)
	var body := session.text.length() - session.text.find(ReplayFile.SEPARATOR)
	session.bytes_per_row = float(body) / maxi(1, rows)
	print(
		(
			"Light session: %d rows, %d hits, lowest health %d, %d bytes,"
			+ " %.1f bytes per tick and fighter"
		)
		% [rows, session.hits, session.lowest_health, session.text.length(), session.bytes_per_row]
	)
	return session


static func _judged(text: String) -> ReplayFile:
	var replay := ReplayFile.parse(text)
	replay.judge(ReplayFile.this_build())
	return replay


static func _mentions(messages: PackedStringArray, words: String) -> bool:
	for message: String in messages:
		if message.contains(words):
			return true
	return false


# The text without the combat's header lines: a file as recorded before TASK-12.1, but for its
# light_attack column, which a refusal of its own would name.
static func _without_combat(text: String) -> String:
	var lines := text.split("\n")
	var separator := lines.find(ReplayFile.SEPARATOR)
	var kept := PackedStringArray()
	for index: int in lines.size():
		var line := lines[index]
		var combat := line.begins_with(ReplayFile.COMBAT + "=")
		combat = combat or line.begins_with(ReplayFile.COMBAT_PREFIX)
		if index < separator and combat:
			continue
		kept.append(line)
	return "\n".join(kept)


func test_a_session_with_light_attacks_plays_again_byte_for_byte() -> void:
	var session := await _recorded()
	var replay := _judged(session.text)
	assert_array(replay.messages(false)).is_empty()
	# The precondition: the file holds the presses and the run held the hits, the trade included.
	var presses := 0
	for row: ReplayFile.Row in replay.rows:
		presses += 1 if row.input.light_attack else 0
	assert_int(presses).override_failure_message("no light attack in the file").is_equal(4)
	assert_int(session.hits).override_failure_message("no hit in the session").is_equal(4)
	assert_int(session.lowest_health).is_equal(MAX_HEALTH - 2 * LIGHT_DAMAGE)
	assert_str(session.trace.text()).contains(StateTrace.header())
	assert_bool(StateTrace.header().contains("health")).is_true()
	assert_str(replay.header[ReplayFile.COMBAT]).is_equal(Match.COMBAT_DATA_PATH)
	assert_int(replay.combat_data().light_attack.damage).is_equal(LIGHT_DAMAGE)
	var once := await ReplayRun.new().play(self, replay, replay.movement_data())
	var difference := StateTrace.first_difference(session.trace.text(), once.trace.text())
	var message := "the replay left the recording: %s" % [
		"equal" if difference == null else difference.describe()
	]
	# Compared as a whole, not by the string assert: its diff of two long traces runs out of memory.
	assert_bool(once.trace.text() == session.trace.text()).override_failure_message(message) \
			.is_true()
	assert_bool(once.checked).is_true()
	assert_int(once.first_apart).is_equal(-1)
	assert_int(once.combat_data.light_attack.damage).is_equal(LIGHT_DAMAGE)
	print("Light replay: %s" % once.describe())


# The player plays the combat numbers of the header: a damage of 30 leaves the live game on the
# first hit's tick, in the health, and the check column says so.
func test_the_player_plays_the_combat_numbers_of_the_header() -> void:
	var session := await _recorded()
	var key := "%slight_attack.damage:int=" % ReplayFile.COMBAT_PREFIX
	var lines := session.text.split("\n")
	var found := false
	for index: int in lines.size():
		if lines[index].begins_with(key):
			lines[index] = key + str(TUNED_DAMAGE)
			found = true
	assert_bool(found).override_failure_message("no %s line" % key).is_true()
	var replay := _judged("\n".join(lines))
	assert_bool(replay.playable(false)).is_true()
	var result := await ReplayRun.new().play(self, replay, replay.movement_data())
	assert_int(result.combat_data.light_attack.damage).is_equal(TUNED_DAMAGE)
	var difference := StateTrace.first_difference(session.trace.text(), result.trace.text())
	assert_object(difference).is_not_null()
	assert_str(difference.column).is_equal("health")
	assert_int(result.first_apart).is_equal(difference.tick)
	assert_int(result.trace.text().find("health")).is_greater(0)


# A file without the combat numbers is another build: refused, naming them, and with --force it
# plays combat_v0.tres's, the recording's own here, so the trace is the same.
func test_a_file_without_the_combat_numbers_plays_only_with_force() -> void:
	var session := await _recorded()
	var replay := _judged(_without_combat(session.text))
	var message := "%s" % [replay.messages(false)]
	assert_array(replay.errors).override_failure_message(message).is_empty()
	assert_bool(_mentions(replay.refusals, "combat numbers")).override_failure_message(message) \
			.is_true()
	assert_bool(replay.playable(false)).is_false()
	assert_bool(replay.playable(true)).is_true()
	var result := await ReplayRun.new().play(self, replay, replay.movement_data())
	assert_bool(result.trace.text() == session.trace.text()).is_true()


# One combat field missing, or of another type, is named: a refusal for the missing one, an error
# for the wrong type, as the movement's fields are.
func test_a_missing_or_mistyped_combat_field_is_named() -> void:
	var session := await _recorded()
	var missing := PackedStringArray()
	var mistyped := PackedStringArray()
	for line: String in session.text.split("\n"):
		if line.begins_with("%smax_health:" % ReplayFile.COMBAT_PREFIX):
			mistyped.append(
				"%smax_health:f64=%s" % [ReplayFile.COMBAT_PREFIX, ReplayFile.f64_cell(100.0)]
			)
			continue
		mistyped.append(line)
		if not line.begins_with("%slight_attack.active_ms:" % ReplayFile.COMBAT_PREFIX):
			missing.append(line)
	var without := _judged("\n".join(missing))
	assert_bool(_mentions(without.refusals, "combat field light_attack.active_ms")).is_true()
	assert_bool(without.playable(false)).is_false()
	assert_bool(without.playable(true)).is_true()
	var wrong := _judged("\n".join(mistyped))
	assert_bool(_mentions(wrong.errors, "combat field max_health")).is_true()
	assert_bool(wrong.playable(true)).is_false()
