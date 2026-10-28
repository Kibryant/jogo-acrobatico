# TASK-12.2 (testes-e-entrega.md §4; DEC-0027 §5; DEC-0055): a Sozinho session with the guard, the
# player walking from its spawn point to the dummy's, the dummy holding the guard toward it and
# blocking a light, then letting go and taking the next, recorded by the real ReplayRecorder, plays
# again through the headless player (tools/replay_run.gd) with the same state trace, byte for
# byte: the guard column, the guard's and the light's new numbers in the header, and the new state
# fields, the stun's end, the block's stamp and the freeze's end, all come by reflection. A file
# without the guard column, as recorded before TASK-12.2, is refused naming it, and plays only
# with --force, with the guard let go on every tick, so the block becomes a hit. The session is
# recorded once for the suite, in a temporary folder.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")
const ReplayRun := preload("res://tools/replay_run.gd")

## netfox's clock on the first tick, and the loops of the session with their sizes, in turn: frames
## at 60, 30 and 20 fps.
const FIRST_TICK := 6000
const LOOPS := 200
const LOOP_SIZES: Array[int] = [1, 2, 1, 3]
## The spawn points, where a replay starts its fighters too: SpawnA at z = 9 looking down -Z, and
## SpawnB at z = -1 looking back (arena.tscn). The player walks down -Z until its feet pass
## STOP_Z, and coasts to about 2 m from the dummy, within the reach of 2,43 m (combate.md, "A
## lâmina e o contato"), as in test/replay/replay_light_attack_test.gd.
const YAWS: Array[float] = [0.0, PI]
const STOP_Z := 1.4
## Counted from the loop the player stopped walking: the dummy holds the guard from the start and
## lets it go on the 50th; the player presses the light on the 10th, blocked, and on the 70th, a
## hit, each after the swing and the stun before it are over (combate.md, "O tranco e a vantagem").
const GUARD_UNTIL := 50
const PRESSES: Array[int] = [10, 70]
const MAX_HEALTH := 100 # partida.md, "A vida sem partida"
const LIGHT_DAMAGE := 12 # combate.md, "Os golpes e as defesas"

var _folder := ""
var _session: Session


# What the recording made: the file's text and the live trace.
class Session:
	var text: String
	var trace: StateTrace
	## The dummy's blocks and hits, by its stamps moving, and the loops that ended on a frozen
	## tick of either fighter.
	var blocks := 0
	var hits := 0
	var frozen_ticks := 0


func before() -> void:
	_folder = OS.get_temp_dir().path_join("jogo-acrobatico-guard-%d" % Time.get_ticks_usec())
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
		_session = await _record(_folder.path_join("guard.replay"))
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
	var dummy := fighters[1]
	var hurt := dummy.state.hurt_tick
	var blocked := dummy.state.block_tick
	await get_tree().process_frame
	await get_tree().physics_frame
	var stopped := -1
	for loop: int in LOOPS:
		if stopped < 0 and fighters[0].position.z <= STOP_Z:
			stopped = loop
		var walking := stopped < 0
		fighters[0].input.sample_frame(Vector2(0, 1) if walking else Vector2.ZERO, YAWS[0])
		dummy.input.sample_frame(Vector2.ZERO, YAWS[1])
		dummy.input.hold_guard(walking or loop - stopped < GUARD_UNTIL)
		if not walking and PRESSES.has(loop - stopped):
			fighters[0].input.press_light_attack()
		NetfoxTicks.run_loop(LOOP_SIZES[loop % LOOP_SIZES.size()])
		# The state on screen is the end of the loop's last tick: frozen when that tick was.
		for fighter: Fighter in fighters:
			if fighter.state.frozen_until_tick >= NetworkTime.tick - 1:
				session.frozen_ticks += 1
		if dummy.state.block_tick != blocked:
			blocked = dummy.state.block_tick
			session.blocks += 1
		if dummy.state.hurt_tick != hurt:
			hurt = dummy.state.hurt_tick
			session.hits += 1
	session.trace.stop()
	recorder.close()
	stage.free()
	NetfoxTicks.reset()
	session.text = FileAccess.get_file_as_string(path)
	print(
		"Guard session: %d blocks, %d hits, %d frozen ticks seen, %d bytes"
		% [session.blocks, session.hits, session.frozen_ticks, session.text.length()]
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


# The text without the guard column: the header's columns line without it, and each row without
# its cell, as a file recorded before TASK-12.2 would hold them.
static func _without_guard(text: String) -> String:
	var lines := text.split("\n")
	var separator := lines.find(ReplayFile.SEPARATOR)
	var index := -1
	for at: int in separator:
		if lines[at].begins_with("columns="):
			var columns := lines[at].trim_prefix("columns=").split(",")
			index = columns.find("guard:bool")
			columns.remove_at(index)
			lines[at] = "columns=" + ",".join(columns)
	assert(index >= 0, "no guard column in the file")
	for at: int in range(separator + 1, lines.size()):
		if lines[at].is_empty():
			continue
		var cells := lines[at].split(ReplayFile.CELL_SEPARATOR)
		cells.remove_at(index)
		lines[at] = ReplayFile.CELL_SEPARATOR.join(cells)
	return "\n".join(lines)


func test_a_session_with_the_guard_plays_again_byte_for_byte() -> void:
	var session := await _recorded()
	var replay := _judged(session.text)
	assert_array(replay.messages(false)).is_empty()
	# The precondition: the file holds the guard and the presses, and the run held one block, one
	# hit, and the freezes of both.
	var guarded := 0
	var presses := 0
	for row: ReplayFile.Row in replay.rows:
		guarded += 1 if row.input.guard else 0
		presses += 1 if row.input.light_attack else 0
	assert_int(guarded).override_failure_message("no guard in the file").is_greater(0)
	assert_int(presses).is_equal(PRESSES.size())
	assert_int(session.blocks).override_failure_message("no block in the session").is_equal(1)
	assert_int(session.hits).override_failure_message("no hit in the session").is_equal(1)
	assert_int(session.frozen_ticks).override_failure_message("nobody froze").is_greater(0)
	for field: String in ["stun_until_tick", "block_tick", "frozen_until_tick"]:
		assert_bool(StateTrace.header().contains(field)).override_failure_message(field).is_true()
	assert_int(replay.combat_data().guard_raise_ms).is_equal(100)
	assert_int(replay.combat_data().light_attack.hitstop_hit_ms).is_equal(67)
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


# A file without the guard column is another build: refused, naming the column; with --force it
# plays with the guard let go on every tick, so the dummy takes the light it had blocked, and the
# check column says where the replay left the recording.
func test_a_file_without_the_guard_column_plays_only_with_force() -> void:
	var session := await _recorded()
	var replay := _judged(_without_guard(session.text))
	var message := "%s" % [replay.messages(false)]
	assert_array(replay.errors).override_failure_message(message).is_empty()
	assert_bool(_mentions(replay.refusals, "column guard")).override_failure_message(message) \
			.is_true()
	assert_bool(replay.playable(false)).is_false()
	assert_bool(replay.playable(true)).is_true()
	for row: ReplayFile.Row in replay.rows:
		assert_bool(row.input.guard).is_false()
	var result := await ReplayRun.new().play(self, replay, replay.movement_data())
	var difference := StateTrace.first_difference(session.trace.text(), result.trace.text())
	assert_object(difference).override_failure_message("the guard changed nothing").is_not_null()
	assert_int(result.first_apart).is_greater(-1)
