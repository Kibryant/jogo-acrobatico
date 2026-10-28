# Criteria 4 and 6 of TASK-10.3 (DEC-0027 §5; F-042 §3): a session the real ReplayRecorder wrote
# (replay_session.gd) plays again through the headless player (tools/replay_run.gd) with the same
# state trace, byte for byte, and twice with the same sha256. The session is the hard case: a yaw
# with many digits, moves that are the mean of 2 or 3 frames, loops of 2 and 3 ticks, double
# jumps, dashes (TASK-10.4, criterion 6), a wall run with a wall jump (TASK-10.5, criterion 7),
# and a pitch on every loop with grapples that fire and pull (TASK-10.6, criteria 2 and 8); the
# test proves that before it compares. The check
# column says the first tick a replay leaves the live game, the player plays the movement numbers
# of the header, a jump of netfox's clock plays as the same jump, and the box of every tick is the
# row, as recorded.
# Criterion 2 of TASK-10.6: a new recording keeps the pitch and the grapple, and a file recorded
# before them, as TASK-10.3 wrote it, still plays with --force, the missing columns at their
# defaults.
# The session is recorded once for the suite, in a temporary folder; the time is printed.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")
const ReplayRun := preload("res://tools/replay_run.gd")
const ReplaySession := preload("res://test/replay/replay_session.gd")

## The loop before which the clock jumps, in the session of the jump, and its ticks.
const JUMP_BEFORE_LOOP := 60
const JUMP_SESSION_TICKS := 200
## The jump height a tuned header asks for, against the 1.2 m of movement_v0.tres.
const TUNED_JUMP_M := 0.6
## A file as TASK-10.3 recorded it (01dd005, the commit that closed it): no dash, no pitch and no
## grapple column, and only the 18 numbers its MovementData had, up to the stamina's.
const TASK_10_3_COLUMNS := (
	"tick:int,loop:int,fighter:int,move.x:f64,move.y:f64,yaw:f64,jump:bool,check:hex8"
)
const TASK_10_3_CONFIG: Array[String] = [
	"capsule_height_m",
	"capsule_radius_m",
	"max_slope_deg",
	"run_speed_mps",
	"accel_time_ms",
	"stop_time_ms",
	"jump_height_m",
	"jump_rise_ms",
	"jump_fall_ms",
	"air_control_pct",
	"max_fall_speed_mps",
	"coyote_ms",
	"buffer_ms",
	"double_jump_height_m",
	"double_jump_cost",
	"stamina_max",
	"stamina_wait_ms",
	"stamina_regen_per_s",
]
## The aim's session (TASK-10.6, criterion 2): its ticks, one per loop, from its first tick; every
## AIM_PRESS_EVERY loops, from loop AIM_PRESS_FROM, a press of the grapple.
const AIM_TICKS := 40
const AIM_FIRST_TICK := 3000
const AIM_PRESS_EVERY := 7
const AIM_PRESS_FROM := 3
## rad: the aim's session looks AIM_PITCH_FROM down on its first loop and turns up by
## AIM_PITCH_STEP on each: a mouse never stops on a round angle, and 40 loops stay within the
## camera's 80 degrees.
const AIM_PITCH_FROM := -0.6
const AIM_PITCH_STEP := 0.0234567891

var _folder := ""
var _session: ReplaySession.Result


func before() -> void:
	_folder = OS.get_temp_dir().path_join("jogo-acrobatico-round-trip-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(_folder)


func after() -> void:
	for file: String in DirAccess.get_files_at(_folder):
		DirAccess.remove_absolute(_folder.path_join(file))
	DirAccess.remove_absolute(_folder)


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


# The session, recorded the first time a test asks for it.
func _recorded() -> ReplaySession.Result:
	if _session == null:
		var path := _folder.path_join("session.replay")
		_session = await ReplaySession.new().record(self, path)
		print(
			"Replay session: %d ticks in %d loops recorded in %.0f ms, %d bytes"
			% [
				_session.ticks,
				_session.loops,
				_session.record_usec / 1000.0,
				_session.text.length(),
			]
		)
	return _session


static func _judged(text: String) -> ReplayFile:
	var replay := ReplayFile.parse(text)
	replay.judge(ReplayFile.this_build())
	return replay


static func _mentions(messages: PackedStringArray, words: String) -> bool:
	for message: String in messages:
		if message.contains(words):
			return true
	return false


# The text of a file this build recorded, as TASK-10.3 would have written it: its columns and its
# configuration lines only, and each row's cells in those columns.
static func _as_task_10_3(text: String) -> String:
	var old_columns := TASK_10_3_COLUMNS.split(ReplayFile.CELL_SEPARATOR)
	var kept: Array[int] = []
	var columns := ReplayFile.default_columns()
	for index: int in columns.size():
		if old_columns.has(columns[index].declared()):
			kept.append(index)
	var lines := text.split("\n")
	var separator := lines.find(ReplayFile.SEPARATOR)
	var written := PackedStringArray()
	for index: int in lines.size():
		var line := lines[index]
		if index < separator and line.begins_with("columns="):
			line = "columns=" + TASK_10_3_COLUMNS
		elif index < separator and line.begins_with(ReplayFile.CONFIG_PREFIX):
			var field := line.trim_prefix(ReplayFile.CONFIG_PREFIX).get_slice(":", 0)
			if not TASK_10_3_CONFIG.has(field):
				continue
		elif index < separator and line.begins_with(ReplayFile.COMBAT):
			# The combat's numbers came with TASK-12.1.
			continue
		elif index > separator and not line.is_empty():
			var cells := line.split(ReplayFile.CELL_SEPARATOR)
			var old_cells := PackedStringArray()
			for at: int in kept:
				old_cells.append(cells[at])
			line = ReplayFile.CELL_SEPARATOR.join(old_cells)
		written.append(line)
	return "\n".join(written)


static func _difference(expected: StateTrace, played: StateTrace) -> String:
	var difference := StateTrace.first_difference(expected.text(), played.text())
	return "equal" if difference == null else difference.describe()


func test_a_recorded_session_plays_again_byte_for_byte() -> void:
	# A setting another test left behind would move every tick (move_and_slide scales by it).
	assert_float(Engine.time_scale).override_failure_message("Engine.time_scale is not 1").is_equal(
		1.0
	)
	var session := await _recorded()
	assert_bool(session.text.contains("\r")).override_failure_message("a CR in the file").is_false()
	var replay := _judged(session.text)
	assert_array(replay.messages(false)).is_empty()
	# The precondition first: the session holds what makes a replay hard.
	var turned := 0
	var fractional := 0
	var longest := 0
	var presses := 0
	var dash_presses := 0
	var pitched := 0
	var grapple_presses := 0
	for row: ReplayFile.Row in replay.rows:
		if row.input.yaw != 0.0:
			turned += 1
		if row.input.pitch != 0.0:
			pitched += 1
		grapple_presses += 1 if row.input.grapple else 0
		for part: float in [row.input.move.x, row.input.move.y]:
			if part not in [-1.0, 0.0, 1.0]:
				fractional += 1
		longest = maxi(longest, row.loop)
		presses += 1 if row.input.jump else 0
		dash_presses += 1 if row.input.dash else 0
	assert_int(turned).override_failure_message("no tick with a yaw other than 0").is_greater(0)
	assert_int(fractional).override_failure_message("no move outside -1, 0 and 1").is_greater(0)
	assert_int(longest).override_failure_message("no loop of 2 ticks or more").is_greater(1)
	assert_int(presses).is_greater(1)
	assert_int(session.double_jumps).override_failure_message("no double jump").is_greater(0)
	assert_int(dash_presses).override_failure_message("no dash in the file").is_greater(0)
	assert_int(session.dashes).override_failure_message("no dash came out").is_greater(0)
	assert_int(session.wall_runs).override_failure_message("no wall run").is_greater(0)
	assert_int(session.wall_jumps).override_failure_message("no wall jump").is_greater(0)
	assert_int(pitched).override_failure_message("no tick with a pitch other than 0").is_greater(0)
	assert_int(grapple_presses).override_failure_message("no grapple in the file").is_greater(0)
	assert_int(session.grapples).override_failure_message("no grapple fired").is_greater(0)
	assert_int(replay.first_tick()).is_equal(ReplaySession.FIRST_TICK)
	assert_int(replay.tick_count()).is_equal(ReplaySession.TICKS)
	assert_str(replay.header["config"]).is_equal(Match.MOVEMENT_DATA_PATH)
	# Then the replay, twice.
	var started := Time.get_ticks_msec()
	var once := await ReplayRun.new().play(self, replay, replay.movement_data())
	var twice := await ReplayRun.new().play(self, replay, replay.movement_data())
	print(
		(
			"Replay round trip: %s; twice in %d ms with the setup; turned=%d fractional=%d"
			% [once.describe(), Time.get_ticks_msec() - started, turned, fractional]
			+ " longest_loop=%d double_jumps=%d" % [longest, session.double_jumps]
			+ " dashes=%d wall_runs=%d" % [session.dashes, session.wall_runs]
			+ " wall_jumps=%d pitched=%d" % [session.wall_jumps, pitched]
			+ " grapple_presses=%d grapples=%d" % [grapple_presses, session.grapples]
		)
	)
	var message := "the replay left the recording: %s" % _difference(session.trace, once.trace)
	assert_str(once.trace.text()).override_failure_message(message).is_equal(session.trace.text())
	assert_str(twice.trace.sha256()).is_equal(once.trace.sha256())
	assert_int(once.ticks).is_equal(ReplaySession.TICKS)
	assert_bool(once.checked).is_true()
	assert_int(once.first_apart).is_equal(-1)


# Criteria 4 and 6: a header tuned to another jump height plays with it, and the check column says
# the replay leaves the live game on the tick of the first jump, where the height first counts.
func test_the_check_column_says_the_first_tick_a_replay_leaves_the_live_game() -> void:
	var session := await _recorded()
	var key := "%sjump_height_m:f64=" % ReplayFile.CONFIG_PREFIX
	var lines := session.text.split("\n")
	for index: int in lines.size():
		if lines[index].begins_with(key):
			lines[index] = key + ReplayFile.f64_cell(TUNED_JUMP_M)
	var replay := _judged("\n".join(lines))
	assert_bool(replay.playable(false)).is_true()
	var first_jump := -1
	for row: ReplayFile.Row in replay.rows:
		if row.input.jump:
			first_jump = row.tick - replay.first_tick()
			break
	assert_int(first_jump).is_greater(0)
	var result := await ReplayRun.new().play(self, replay, replay.movement_data())
	assert_float(result.movement_data.jump_height_m).is_equal(TUNED_JUMP_M)
	assert_int(result.first_apart).is_equal(first_jump)
	assert_int(result.first_apart_fighter).is_equal(0)
	var difference := StateTrace.first_difference(session.trace.text(), result.trace.text())
	assert_int(difference.tick).is_equal(first_jump)


# Criterion 7: netfox's clock jumps after a stall of over a second; the player makes the same jump,
# and the trace comes out equal.
func test_a_jump_of_netfox_clock_plays_as_the_same_jump() -> void:
	var path := _folder.path_join("jump.replay")
	var session := await ReplaySession.new().record(
		self,
		path,
		JUMP_SESSION_TICKS,
		JUMP_BEFORE_LOOP,
	)
	var replay := _judged(session.text)
	assert_array(replay.messages(false)).is_empty()
	assert_int(replay.jumps).is_equal(1)
	var result := await ReplayRun.new().play(self, replay, replay.movement_data())
	var message := "the replay left the recording: %s" % _difference(session.trace, result.trace)
	assert_str(result.trace.text()).override_failure_message(message).is_equal(session.trace.text())
	assert_int(result.jumps).is_equal(1)
	assert_int(result.first_apart).is_equal(-1)


# Criterion 5, the --watch's machinery without a window: ReplayWatch plays the rows in order from
# its own first tick, traces the state counted from it and notes the size of every loop it ran.
# Driven here by hand, inside a physics frame like the headless player, from another tick and in
# loops of 1 tick where the recording had loops of 1 to 3, it gives the recording's trace byte for
# byte: inside a physics frame the size of the loop does not move the body (rede.md §2).
func test_the_watch_plays_the_rows_in_order_from_its_own_first_tick() -> void:
	const WATCH_FIRST := 37
	var session := await _recorded()
	var replay := _judged(session.text)
	NetfoxTicks.set_tick(WATCH_FIRST)
	var stage := SubViewport.new()
	stage.own_world_3d = true
	add_child(stage)
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match := node as Match
	game_match.movement_data = replay.movement_data()
	stage.add_child(game_match)
	var fighter := game_match.spawn_fighter(0, multiplayer.get_unique_id())
	fighter.input.play_rows(ReplaySource.in_order(replay, 0, WATCH_FIRST))
	var fighters: Array[Fighter] = [fighter]
	var watch := ReplayWatch.new(replay, fighters, WATCH_FIRST)
	stage.add_child(watch)
	var finished := [false]
	watch.finished.connect(
		func() -> void:
			finished[0] = true,
	)
	await get_tree().process_frame
	await get_tree().physics_frame
	for _tick: int in ReplaySession.TICKS + 2:
		NetfoxTicks.run_loop()
	var played := watch.trace.text()
	var message := "the watch left the recording: %s" % _difference(session.trace, watch.trace)
	var sizes := watch.loop_sizes.values()
	var summary := watch.summary()
	var done := watch.done
	var ticks_played := watch.ticks_played
	var first_apart := watch.first_apart
	stage.free()
	assert_str(played).override_failure_message(message).is_equal(session.trace.text())
	assert_bool(done).is_true()
	assert_bool(finished[0]).is_true()
	assert_int(ticks_played).is_equal(ReplaySession.TICKS)
	assert_int(first_apart).is_equal(-1)
	assert_int(sizes.size()).is_equal(ReplaySession.TICKS)
	assert_array(
		sizes.filter(
			func(size: int) -> bool:
				return size != 1,
		)
	).is_empty()
	assert_str("\n".join(summary)).contains("equal on every tick")


# The box of every tick is its row exactly: no sampler mean and no limit_length, even for a move
# longer than 1, which the rules clamp themselves; frames sampled meanwhile are left out, and a tick
# without a row has the neutral input.
func test_the_box_of_every_tick_is_the_row() -> void:
	const FIRST := 700
	const LOOPS: Array[int] = [1, 3, 2, 1, 3]
	var source := ReplaySource.new()
	var rows: Array[TickInput] = []
	for step: int in 10:
		var row := TickInput.new()
		row.move = Vector2(0.9, 0.9) if step % 2 == 0 else Vector2(1.0 / 3.0, -2.0 / 3.0)
		row.yaw = -2.9876543210123457 + step * 0.0123456789
		row.jump = step % 4 == 1
		source.add(FIRST + step, row)
		rows.append(row)
	NetfoxTicks.set_tick(FIRST)
	var stage := SubViewport.new()
	stage.own_world_3d = true
	add_child(stage)
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match := node as Match
	stage.add_child(game_match)
	var fighter := game_match.spawn_fighter(0, multiplayer.get_unique_id(), FIRST)
	fighter.input.play_rows(source)
	var boxes: Dictionary[int, TickInput] = { }
	var keep := func(tick: int) -> void:
		boxes[tick] = fighter.input.to_tick_input()
	NetworkRollback.after_process_tick.connect(keep)
	await get_tree().process_frame
	await get_tree().physics_frame
	for size: int in LOOPS:
		fighter.input.sample_frame(Vector2(-1, 0), 1.0)
		fighter.input.press_jump()
		NetfoxTicks.run_loop(size)
	NetfoxTicks.run_loop()
	NetworkRollback.after_process_tick.disconnect(keep)
	stage.free()
	for step: int in rows.size():
		var box := boxes[FIRST + step]
		var row := rows[step]
		var message := "tick %d: box %s, %s, %s" % [step, box.move, box.yaw, box.jump]
		assert_bool(var_to_bytes(box.move) == var_to_bytes(row.move)) \
				.override_failure_message(message) \
				.is_true()
		assert_bool(var_to_bytes(box.yaw) == var_to_bytes(row.yaw)) \
				.override_failure_message(message) \
				.is_true()
		assert_bool(box.jump).override_failure_message(message).is_equal(row.jump)
	var after := boxes[FIRST + rows.size()]
	var neutral := TickInput.new()
	assert_vector(after.move).is_equal(neutral.move)
	assert_float(after.yaw).is_equal(neutral.yaw)
	assert_bool(after.jump).is_equal(neutral.jump)


# Criterion 2 of TASK-10.6 (DEC-0027 §5): the recorded session, turned into a file of TASK-10.3,
# without the dash, pitch and grapple columns and the numbers that came after it, is another build:
# refused without --force, with a message naming each column and number it lacks. With --force it
# plays every recorded tick, the missing columns at TickInput's defaults and the missing numbers
# from movement_v0.tres; the move, the yaw and the jump are the recording's, bit for bit.
func test_a_file_of_task_10_3_plays_only_with_force_the_new_columns_at_their_defaults() -> void:
	var session := await _recorded()
	var replay := _judged(_as_task_10_3(session.text))
	var message := "%s" % [replay.messages(false)]
	assert_array(replay.errors).override_failure_message(message).is_empty()
	var lacking: Array[String] = [
		"column pitch",
		"column grapple",
		"column dash",
		"config field grapple_range_m",
		"config field aim_height_m",
		"config field dash_ms",
		"config field wall_run_max_ms",
		"column light_attack",
		"combat numbers",
	]
	for words: String in lacking:
		var unnamed := "no refusal names %s: %s" % [words, message]
		assert_bool(_mentions(replay.refusals, words)).override_failure_message(unnamed).is_true()
	assert_bool(replay.playable(false)).is_false()
	assert_bool(replay.playable(true)).is_true()
	assert_bool(_mentions(replay.messages(true), "played anyway (--force)")).is_true()
	var recorded := _judged(session.text)
	var neutral := TickInput.new()
	assert_int(replay.rows.size()).is_equal(recorded.rows.size())
	for index: int in replay.rows.size():
		var old := replay.rows[index].input
		var now := recorded.rows[index].input
		assert_float(old.pitch).is_equal(neutral.pitch)
		assert_bool(old.grapple).is_equal(neutral.grapple)
		assert_bool(old.dash).is_equal(neutral.dash)
		assert_bool(var_to_bytes(old.yaw) == var_to_bytes(now.yaw)).is_true()
		assert_bool(var_to_bytes(old.move) == var_to_bytes(now.move)).is_true()
		assert_bool(old.jump).is_equal(now.jump)
	var resource: Resource = load(Match.MOVEMENT_DATA_PATH)
	assert(resource is MovementData, "%s must load as a MovementData" % Match.MOVEMENT_DATA_PATH)
	var v0 := resource as MovementData
	var data := replay.movement_data()
	assert_float(data.grapple_range_m).is_equal(v0.grapple_range_m)
	assert_float(data.aim_height_m).is_equal(v0.aim_height_m)
	assert_float(data.jump_height_m).is_equal(v0.jump_height_m)
	var result := await ReplayRun.new().play(self, replay, data)
	print("Replay of a TASK-10.3 file with --force: %s" % result.describe())
	assert_int(result.ticks).is_equal(ReplaySession.TICKS)
	assert_int(result.loops).is_equal(replay.loops.size())


# Criterion 2 of TASK-10.6: a new recording keeps the aim. A short Sozinho session, recorded by the
# real ReplayRecorder, samples a pitch off every round number on each loop and presses the grapple
# on some; the rows hold the box the live game applied on each tick, the pitch bit for bit, and
# played again, the box of every tick is its row.
func test_a_new_recording_round_trips_the_pitch_and_the_grapple() -> void:
	var path := _folder.path_join("aim.replay")
	NetfoxTicks.set_tick(AIM_FIRST_TICK)
	var stage := SubViewport.new()
	stage.own_world_3d = true
	add_child(stage)
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match := node as Match
	stage.add_child(game_match)
	var fighter := game_match.spawn_fighter(0, multiplayer.get_unique_id())
	var recorder := ReplayRecorder.new()
	stage.add_child(recorder)
	assert_int(recorder.start(game_match, [fighter], path)).is_equal(OK)
	var live: Dictionary[int, TickInput] = { }
	var keep := func(tick: int) -> void:
		live[tick] = fighter.input.to_tick_input()
	NetworkRollback.after_process_tick.connect(keep)
	await get_tree().process_frame
	await get_tree().physics_frame
	var pressed := 0
	for loop: int in AIM_TICKS:
		fighter.input.sample_frame(Vector2.ZERO, 0.0, AIM_PITCH_FROM + loop * AIM_PITCH_STEP)
		if loop % AIM_PRESS_EVERY == AIM_PRESS_FROM:
			fighter.input.press_grapple()
			pressed += 1
		NetfoxTicks.run_loop()
	NetworkRollback.after_process_tick.disconnect(keep)
	recorder.close()
	stage.free()
	NetfoxTicks.reset()
	var replay := _judged(FileAccess.get_file_as_string(path))
	assert_array(replay.messages(false)).is_empty()
	assert_int(replay.tick_count()).is_equal(AIM_TICKS)
	var grapples := 0
	for row: ReplayFile.Row in replay.rows:
		var box := live[row.tick]
		var message := "tick %d: pitch %s in the box, %s in the file" % [
			row.tick,
			box.pitch,
			row.input.pitch,
		]
		assert_bool(var_to_bytes(row.input.pitch) == var_to_bytes(box.pitch)) \
				.override_failure_message(message) \
				.is_true()
		assert_bool(row.input.grapple).is_equal(box.grapple)
		grapples += 1 if row.input.grapple else 0
	# The precondition: each press is one tick's grapple, and the pitch moved on every tick.
	assert_int(pressed).is_greater(1)
	assert_int(grapples).is_equal(pressed)
	assert_float(replay.rows[0].input.pitch).is_not_equal(replay.rows[1].input.pitch)
	var played := await _boxes_played(replay)
	for row: ReplayFile.Row in replay.rows:
		var box := played[row.tick]
		assert_bool(var_to_bytes(box.pitch) == var_to_bytes(row.input.pitch)).is_true()
		assert_bool(box.grapple).is_equal(row.input.grapple)


# The box of every tick when replay plays in a match of its own, by tick, as the headless player
# plays it (tools/replay_run.gd).
func _boxes_played(replay: ReplayFile) -> Dictionary[int, TickInput]:
	NetfoxTicks.set_tick(replay.first_tick())
	var stage := SubViewport.new()
	stage.own_world_3d = true
	add_child(stage)
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match := node as Match
	game_match.movement_data = replay.movement_data()
	stage.add_child(game_match)
	var fighter := game_match.spawn_fighter(0, multiplayer.get_unique_id(), replay.first_tick())
	fighter.input.play_rows(ReplaySource.by_tick(replay, 0))
	var boxes: Dictionary[int, TickInput] = { }
	var keep := func(tick: int) -> void:
		boxes[tick] = fighter.input.to_tick_input()
	NetworkRollback.after_process_tick.connect(keep)
	await get_tree().process_frame
	await get_tree().physics_frame
	for loop: ReplayFile.Loop in replay.loops:
		NetfoxTicks.run_loop(loop.size)
	NetworkRollback.after_process_tick.disconnect(keep)
	stage.free()
	NetfoxTicks.reset()
	return boxes
