# Criterion 7 of TASK-10.6, the Q-35: entering a wall run clears the floor's coyote. A run that
# starts within the 100 ms after the floor and ends, by its time or by the face's edge, leaves the
# double jump for the next press in the air, never the full jump (movimento.md, "Corrida na
# parede": "O coyote do chão na entrada"; "Perdão": "Coyote time"; "Pulo e ar": "Aperto depois do
# coyote, sem ter pulado"). Through the public interface of core/fighter, with the engine's slice
# of the tick played by MovementRig: the body runs along a wall on the floor, the floor goes away,
# and the face begins a few ticks later (visao-geral.md, "O tick por dentro: o sanduíche"). Every
# number comes from docs/design/movimento.md, cited by section; ticks by hand from the ms, nearest
# tick with ties up (visao-geral.md, "O tempo e a física no estado").
extends GdUnitTestSuite

const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)

const COYOTE_MS := 100 # movimento.md, "Perdão": "Coyote time"
const RUN_SPEED_MPS := 7.0 # movimento.md, "Chão": "Velocidade de corrida", along the wall on entry
const WALL_ENTRY_SPEED_MPS := 4.0 # movimento.md, "Corrida na parede": "Velocidade mínima"
const WALL_RUN_SPEED_MPS := 8.0 # movimento.md, "Corrida na parede": "Velocidade na parede"
const WALL_RUN_MAX_MS := 2500 # movimento.md, "Corrida na parede": "Duração máxima"
# 100 ms of coyote is 3 ticks at 30 and 6 at 60, inclusive (movimento.md, "Perdão"); 2,5 s of
# run is 75 and 150 ("Corrida na parede").
const COYOTE_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
const WALL_RUN_MAX_TICKS: Dictionary[int, int] = { 30: 75, 60: 150 }

# The geometry of the rig, not design numbers: the body runs -Z beside the wall at x = 0 facing
# +X, within the adapter's probe distance, and the face begins where the body will be a few ticks
# after the ledge; a short face ends half a run tick later, so the run ends by its edge on the
# next tick.
const BESIDE_THE_WALL := Vector3(0.02, 0.0, 0.0)
const HALF_RUN_TICK := 0.5
const SETTLE_SECONDS := 1 # ticks of running before the ledge, far more than the 150 ms of accel
const WALL_A := &"ParedeA" # the id as the adapter reports it: a node path relative to the Arena
const FORWARD := Vector2(0, 1) # move.y goes forward: yaw 0 looks down -Z (TASK-9 plan)
const HAIR := 1e-6 # floating-point slack, not a design number
const FACE_HAIR := 1e-3 # the face begins a hair before the body's end position, never after it


func _rig(tickrate: int) -> MovementRig:
	return MovementRig.new(MovementRig.load_config(tickrate), FIRST_TICK)


# Runs -Z on the floor beside the plane x = 0 until the speed settles at 7 m/s. The face, when
# there is one, is still out of reach (along_min at +INF). Returns the wall, or null without one.
func _run_beside_the_wall(rig: MovementRig, with_wall: bool) -> MovementRig.FakeWall:
	var wall: MovementRig.FakeWall = null
	if with_wall:
		wall = rig.add_wall(Vector3.RIGHT, 0.0, WALL_A)
		wall.along_min = INF
	rig.position = BESIDE_THE_WALL
	for _step: int in SETTLE_SECONDS * rig.config.tickrate:
		rig.step(MovementRig.run(FORWARD))
	assert_float(rig.horizontal_speed()).is_equal_approx(RUN_SPEED_MPS, HAIR)
	assert_bool(rig.state.on_floor).is_true()
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GROUND)
	return wall


# The floor goes away under the running body: that tick's after_move stamps left_floor_tick.
# Returns the ledge tick.
func _leave_ledge_running(rig: MovementRig) -> int:
	var ledge_tick := rig.tick
	rig.floor_on = false
	rig.step(MovementRig.run(FORWARD))
	assert_bool(rig.state.on_floor).is_false()
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	assert_int(rig.state.left_floor_tick).override_failure_message("the ledge was not stamped") \
			.is_equal(ledge_tick)
	return ledge_tick


# Places the face so that the body, still running -Z at 7 m/s, first ends a tick on it
# ticks_after_ledge ticks after the ledge tick (the ledge tick already stepped). With `short`, the
# face ends half a run tick later: the run ends by its edge on the tick after the entry.
func _place_face(
	rig: MovementRig,
	wall: MovementRig.FakeWall,
	ticks_after: int,
	short: bool,
) -> void:
	var per_tick := RUN_SPEED_MPS / rig.config.tickrate
	var entry_end := rig.position + Vector3.FORWARD * (per_tick * ticks_after)
	wall.along_min = wall.along_of(entry_end) - FACE_HAIR
	if short:
		wall.along_max = wall.along_min + HALF_RUN_TICK * WALL_RUN_SPEED_MPS / rig.config.tickrate


func _assert_double_jumped(rig: MovementRig, plan: MovePlan, press_tick: int) -> void:
	assert_float(plan.velocity.y).override_failure_message("not the double jump speed") \
			.is_equal_approx(rig.config.double_jump_speed, HAIR)
	var full := "the full jump came out: %.4f m/s" % plan.velocity.y
	assert_float(absf(plan.velocity.y - rig.config.jump_speed)).override_failure_message(full) \
			.is_greater(HAIR)
	assert_int(plan.state.jumps_used).override_failure_message("not the second jump").is_equal(2)
	assert_int(plan.state.double_jump_tick).is_equal(press_tick)
	assert_int(plan.state.stamina_spent_tick).is_equal(press_tick)


func _assert_full_jump(rig: MovementRig, plan: MovePlan) -> void:
	assert_float(plan.velocity.y).override_failure_message("not the full jump") \
			.is_equal_approx(rig.config.jump_speed, HAIR)
	assert_int(plan.state.jumps_used).override_failure_message("not the first jump").is_equal(1)
	assert_int(plan.state.stamina_spent_tick).is_equal(FighterState.NEVER)


# The hand numbers above against the config (movement_v0.tres at load).
func test_the_config_carries_the_coyote_and_the_run_of_the_design(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var config := MovementRig.load_config(tickrate)
	assert_int(config.coyote_ticks).is_equal(COYOTE_TICKS[tickrate])
	assert_int(config.coyote_ticks).is_equal(Ticks.from_ms(COYOTE_MS, tickrate))
	assert_int(config.wall_run_max_ticks).is_equal(WALL_RUN_MAX_TICKS[tickrate])
	assert_int(config.wall_run_max_ticks).is_equal(Ticks.from_ms(WALL_RUN_MAX_MS, tickrate))
	assert_float(config.run_speed).is_equal_approx(RUN_SPEED_MPS, HAIR)
	assert_float(config.wall_entry_speed).is_equal_approx(WALL_ENTRY_SPEED_MPS, HAIR)
	assert_float(config.wall_run_speed).is_equal_approx(WALL_RUN_SPEED_MPS, HAIR)
	assert_float(RUN_SPEED_MPS).is_greater_equal(WALL_ENTRY_SPEED_MPS)


# The control: with no wall, the same press inside the coyote window is the full jump, and keeps
# the double jump (movimento.md, "Perdão"; "Pulo e ar"). It proves the timing of the cases below
# is inside the window, so only the wall run can take the full jump away.
func test_without_a_wall_the_press_inside_the_coyote_window_is_the_full_jump(
	tickrate: int,
	ticks_after_ledge: int,
	_test_parameters := [[30, 3], [60, 3], [60, 6]],
) -> void:
	var rig := _rig(tickrate)
	_run_beside_the_wall(rig, false)
	var ledge_tick := _leave_ledge_running(rig)
	var press_tick := ledge_tick + ticks_after_ledge
	assert_int(press_tick - ledge_tick).is_less_equal(COYOTE_TICKS[tickrate])
	while rig.tick < press_tick:
		rig.step(MovementRig.run(FORWARD))
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	_assert_full_jump(rig, rig.step(MovementRig.press_jump()))


# Criterion 7: a run that starts ticks_after_ledge ticks after the floor, inside the coyote,
# clears left_floor_tick on the entry; it ends by the face's edge on the next tick, and the press
# right after, still inside the 100 ms of the ledge, is the double jump, not the full jump
# (movimento.md, "Corrida na parede": "O coyote do chão na entrada"; Q-35).
func test_a_wall_run_inside_the_coyote_that_ends_by_the_edge_leaves_the_double_jump(
	tickrate: int,
	ticks_after_ledge: int,
	_test_parameters := [[30, 1], [60, 1], [60, 4]],
) -> void:
	var rig := _rig(tickrate)
	var wall := _run_beside_the_wall(rig, true)
	var ledge_tick := _leave_ledge_running(rig)
	_place_face(rig, wall, ticks_after_ledge, true)
	var entry_tick := ledge_tick + ticks_after_ledge
	while rig.tick < entry_tick:
		rig.step(MovementRig.run(FORWARD))
		assert_int(rig.state.mode).override_failure_message("entered the wall early").is_equal(
			FighterState.Mode.AIR
		)
	rig.step(MovementRig.run(FORWARD))
	assert_int(rig.state.mode).override_failure_message("no wall run on tick %d" % entry_tick) \
			.is_equal(FighterState.Mode.WALL_RUN)
	assert_int(rig.state.mode_since).is_equal(entry_tick)
	assert_int(rig.state.left_floor_tick).override_failure_message("the entry kept the coyote") \
			.is_equal(FighterState.NEVER)
	assert_int(rig.state.jumps_used).is_equal(0)
	var edge_tick := rig.tick
	rig.step(MovementRig.run(FORWARD))
	assert_int(rig.state.mode).override_failure_message("the run did not end at the edge") \
			.is_equal(FighterState.Mode.AIR)
	assert_int(rig.state.mode_since).is_equal(edge_tick)
	assert_int(rig.state.left_floor_tick).is_equal(FighterState.NEVER)
	var press_tick := rig.tick
	var inside := "press %d ticks after the ledge, the coyote is %d" % [
		press_tick - ledge_tick,
		COYOTE_TICKS[tickrate],
	]
	assert_int(press_tick - ledge_tick).override_failure_message(inside).is_less_equal(
		COYOTE_TICKS[tickrate]
	)
	var plan := rig.step(MovementRig.press_jump())
	_assert_double_jumped(rig, plan, press_tick)


# The same run on an endless face ends by its time, 2,5 s later: the coyote stayed cleared all
# along, and the first press in the air is the double jump.
func test_a_wall_run_inside_the_coyote_that_ends_by_time_leaves_the_double_jump(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var wall := _run_beside_the_wall(rig, true)
	var ledge_tick := _leave_ledge_running(rig)
	_place_face(rig, wall, 1, false)
	var entry_tick := ledge_tick + 1
	rig.step(MovementRig.run(FORWARD))
	assert_int(rig.state.mode).is_equal(FighterState.Mode.WALL_RUN)
	assert_int(rig.state.mode_since).is_equal(entry_tick)
	assert_int(rig.state.left_floor_tick).is_equal(FighterState.NEVER)
	var run_ticks := 0
	var limit: int = WALL_RUN_MAX_TICKS[tickrate]
	while rig.state.mode == FighterState.Mode.WALL_RUN and run_ticks <= limit:
		rig.step(MovementRig.idle())
		run_ticks += 1
		assert_int(rig.state.left_floor_tick).is_equal(FighterState.NEVER)
	assert_int(rig.state.mode).override_failure_message("the run never ended").is_equal(
		FighterState.Mode.AIR
	)
	var press_tick := rig.tick
	_assert_double_jumped(rig, rig.step(MovementRig.press_jump()), press_tick)
