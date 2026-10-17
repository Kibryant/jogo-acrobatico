# Criterion 3 of TASK-9: the rules of the ground and the air, as a table written from
# docs/design/movimento.md before the code (DEC-0004, rule 4). The engine's slice of the tick is
# played by MovementRig on a flat floor; only the public interface of core/fighter is used.
# Ticks by hand from the ms: nearest tick, ties up (visao-geral.md, "O tempo e a física no
# estado").
extends GdUnitTestSuite

const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)

const RUN_SPEED_MPS := 7.0 # movimento.md, "Chão": the same forward, sideways and back
const ACCEL_MS := 150 # movimento.md, "Chão": time until full speed
const STOP_MS := 100 # movimento.md, "Chão": time until stopped, without input
const AIR_CONTROL := 0.25 # movimento.md, "Pulo e ar": 25 % of the ground acceleration
const MAX_FALL_SPEED_MPS := 30.0 # movimento.md, "Pulo e ar"

# 150 ms until full speed by hand: 4.5 -> 5 ticks at 30 (tie up), 9 at 60 (movimento.md, "Chão";
# visao-geral.md, "O tempo e a física no estado"). The acceleration is constant ("Deriva a
# aceleração"), derived for the tick: each tick of full input adds run_speed / accel_ticks.
const ACCEL_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }

# Forward, right, left, back and a diagonal of length 1 (movimento.md, "Chão").
const DIRECTIONS: Array[Vector2] = [
	Vector2(0, 1),
	Vector2(1, 0),
	Vector2(-1, 0),
	Vector2(0, -1),
	Vector2(0.7071067811865476, 0.7071067811865476), # 1 / sqrt(2) each: length 1
]

const SPEED_HAIR := 1e-6 # floating-point slack in m/s, not a design number
const HALF_TICK := 0.5


func _rig(tickrate: int) -> MovementRig:
	return MovementRig.new(MovementRig.load_config(tickrate), FIRST_TICK)


# A design time in ticks of the given rate, unrounded: what the half-tick tolerance is measured
# against (150 ms is 4.5 ticks at 30).
func _design_ticks(ms: int, tickrate: int) -> float:
	return ms * tickrate / 1000.0


# The world direction of a move, the convention the tests rely on (TASK-9 plan): yaw 0 looks
# down -Z, move.x goes right and move.y goes forward.
func _world_direction(move: Vector2, yaw: float) -> Vector3:
	return Basis(Vector3.UP, yaw) * Vector3(move.x, 0.0, -move.y)


# Steps of full input from rest until the horizontal speed first reaches run_speed; 0 if never.
func _steps_to_full_speed(rig: MovementRig, move: Vector2, max_steps: int) -> int:
	for step: int in range(1, max_steps + 1):
		rig.step(MovementRig.run(move))
		if rig.horizontal_speed() >= RUN_SPEED_MPS - SPEED_HAIR:
			return step
	return 0


func test_full_input_from_rest_reaches_7_mps_in_150_ms_within_half_a_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var steps := _steps_to_full_speed(rig, Vector2(0, 1), tickrate)
	var expected := _design_ticks(ACCEL_MS, tickrate)
	var never := "never reached 7 m/s within a second at %d ticks" % tickrate
	assert_bool(steps > 0).override_failure_message(never).is_true()
	var message := (
		"7 m/s first reached at step %d, the design says %.1f ticks (150 ms at %d ticks)"
		% [steps, expected, tickrate]
	)
	assert_float(absf(steps - expected)).override_failure_message(message).is_less_equal(HALF_TICK)
	assert_float(rig.horizontal_speed()).is_equal_approx(RUN_SPEED_MPS, SPEED_HAIR)


func test_each_tick_of_full_input_adds_the_same_speed(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var gain_per_tick := RUN_SPEED_MPS / ACCEL_TICKS[tickrate]
	var violations: Array[String] = []
	for step: int in range(1, ACCEL_TICKS[tickrate] + 1):
		rig.step(MovementRig.run(Vector2(0, 1)))
		var expected := gain_per_tick * step
		if absf(rig.horizontal_speed() - expected) > SPEED_HAIR:
			violations.append(
				"step %d: %.6f m/s, expected %.6f" % [step, rig.horizontal_speed(), expected]
			)
	assert_array(violations).is_empty()


func test_running_never_exceeds_7_mps(tickrate: int, _test_parameters := [[30], [60]]) -> void:
	var rig := _rig(tickrate)
	var violations: Array[String] = []
	for step: int in range(1, 2 * tickrate + 1):
		rig.step(MovementRig.run(Vector2(0, 1)))
		if rig.horizontal_speed() > RUN_SPEED_MPS + SPEED_HAIR:
			violations.append("step %d: %.6f m/s" % [step, rig.horizontal_speed()])
	assert_array(violations).is_empty()
	assert_float(rig.horizontal_speed()).is_equal_approx(RUN_SPEED_MPS, SPEED_HAIR)


# The same 7 m/s, reached in the same time, forward, to the right, to the left, back and on a
# diagonal of length 1, each in its world direction (movimento.md, "Chão").
func test_the_run_is_the_same_in_every_direction(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var expected_steps := _design_ticks(ACCEL_MS, tickrate)
	for move: Vector2 in DIRECTIONS:
		var rig := _rig(tickrate)
		var steps := _steps_to_full_speed(rig, move, tickrate)
		var message := "move %s: 7 m/s at step %d, the design says %.1f" % [
			move,
			steps,
			expected_steps,
		]
		assert_float(absf(steps - expected_steps)).override_failure_message(message).is_less_equal(
			HALF_TICK
		)
		var expected := RUN_SPEED_MPS * _world_direction(move, 0.0)
		assert_vector(rig.velocity) \
				.override_failure_message("move %s must run along %s, found %s"
		% [move, expected, rig.velocity]) \
				.is_equal_approx(expected, Vector3.ONE * SPEED_HAIR)


# yaw 0 looks down -Z, so forward runs along -Z and right along +X; a quarter turn to the left
# (yaw +90°) puts forward along -X (TASK-9 plan, the Basis convention).
func test_the_run_follows_the_yaw(tickrate: int, _test_parameters := [[30], [60]]) -> void:
	var forward := _rig(tickrate)
	for _step: int in tickrate:
		forward.step(MovementRig.run(Vector2(0, 1), 0.0))
	assert_vector(forward.velocity).is_equal_approx(
		Vector3(0.0, 0.0, -RUN_SPEED_MPS),
		Vector3.ONE * SPEED_HAIR,
	)
	var right := _rig(tickrate)
	for _step: int in tickrate:
		right.step(MovementRig.run(Vector2(1, 0), 0.0))
	assert_vector(right.velocity).is_equal_approx(
		Vector3(RUN_SPEED_MPS, 0.0, 0.0),
		Vector3.ONE * SPEED_HAIR,
	)
	var turned := _rig(tickrate)
	for _step: int in tickrate:
		turned.step(MovementRig.run(Vector2(0, 1), PI / 2))
	assert_vector(turned.velocity).is_equal_approx(
		Vector3(-RUN_SPEED_MPS, 0.0, 0.0),
		Vector3.ONE * SPEED_HAIR,
	)
	assert_vector(turned.velocity).is_equal_approx(
		RUN_SPEED_MPS * _world_direction(Vector2(0, 1), PI / 2),
		Vector3.ONE * SPEED_HAIR,
	)


func test_without_input_the_fighter_stops_from_7_mps_in_100_ms_within_half_a_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var forward := Vector2(0, 1)
	for _step: int in tickrate:
		rig.step(MovementRig.run(forward))
	assert_float(rig.horizontal_speed()).is_equal_approx(RUN_SPEED_MPS, SPEED_HAIR)
	var run_direction := _world_direction(forward, 0.0)
	var stop_step := 0
	var previous := rig.horizontal_speed()
	var violations: Array[String] = []
	for step: int in range(1, tickrate + 1):
		rig.step(MovementRig.idle())
		var speed := rig.horizontal_speed()
		if speed > previous + SPEED_HAIR:
			violations.append("step %d: sped up from %.6f to %.6f m/s" % [step, previous, speed])
		if rig.velocity.dot(run_direction) < -SPEED_HAIR:
			violations.append("step %d: reversed instead of stopping" % step)
		if stop_step == 0 and speed <= SPEED_HAIR:
			stop_step = step
		previous = speed
	assert_array(violations).is_empty()
	assert_bool(stop_step > 0).override_failure_message("never stopped within a second").is_true()
	var expected := _design_ticks(STOP_MS, tickrate)
	var message := (
		"stopped at step %d, the design says %.1f ticks (100 ms at %d ticks)"
		% [stop_step, expected, tickrate]
	)
	assert_float(absf(stop_step - expected)).override_failure_message(message).is_less_equal(
		HALF_TICK
	)
	assert_float(rig.horizontal_speed()).is_equal_approx(0.0, SPEED_HAIR)


func test_a_fighter_at_rest_without_input_stays_at_rest(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var violations: Array[String] = []
	for step: int in range(1, tickrate + 1):
		rig.step(MovementRig.idle())
		if rig.velocity.length() > SPEED_HAIR or rig.position != Vector3.ZERO:
			violations.append("step %d: moved to %s at %s" % [step, rig.position, rig.velocity])
		if not rig.state.on_floor or rig.state.mode != FighterState.Mode.GROUND:
			violations.append("step %d: left the ground" % step)
	assert_array(violations).is_empty()


# In the air, a tick of full input adds 25 % of what it adds on the ground (movimento.md, "Pulo
# e ar": "Controle no ar, 25 % da aceleração do chão").
func test_air_control_is_a_quarter_of_the_ground_acceleration(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var ground := _rig(tickrate)
	ground.step(MovementRig.run(Vector2(0, 1)))
	var ground_gain := ground.horizontal_speed()
	assert_float(ground_gain).is_equal_approx(RUN_SPEED_MPS / ACCEL_TICKS[tickrate], SPEED_HAIR)
	var air := _rig(tickrate)
	air.floor_on = false # off a ledge: this tick leaves the floor
	air.step(MovementRig.idle())
	assert_bool(air.state.on_floor).is_false()
	air.step(MovementRig.run(Vector2(0, 1)))
	assert_float(air.horizontal_speed()).is_equal_approx(AIR_CONTROL * ground_gain, SPEED_HAIR)


# The run speed is the ceiling in the air too (movimento.md, "Chão"; "Princípios": speed is
# kept between maneuvers "dentro dos tetos").
func test_air_control_never_pushes_past_7_mps(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.floor_on = false
	var violations: Array[String] = []
	for step: int in range(1, 3 * tickrate + 1):
		rig.step(MovementRig.run(Vector2(0, 1)))
		if rig.horizontal_speed() > RUN_SPEED_MPS + SPEED_HAIR:
			violations.append("step %d: %.6f m/s in the air" % [step, rig.horizontal_speed()])
	assert_array(violations).is_empty()
	assert_float(rig.horizontal_speed()).is_equal_approx(RUN_SPEED_MPS, SPEED_HAIR)


func test_falling_never_exceeds_30_mps(tickrate: int, _test_parameters := [[30], [60]]) -> void:
	var rig := _rig(tickrate)
	rig.floor_on = false
	var violations: Array[String] = []
	for step: int in range(1, 4 * tickrate + 1):
		rig.step(MovementRig.idle())
		if rig.velocity.y < -MAX_FALL_SPEED_MPS - SPEED_HAIR:
			violations.append("step %d: falling at %.6f m/s" % [step, -rig.velocity.y])
	assert_array(violations).is_empty()
	# Four seconds of falling are enough to hit the cap: it must be active, not just unreached.
	assert_float(rig.velocity.y).is_equal_approx(-MAX_FALL_SPEED_MPS, SPEED_HAIR)


# The body looks where the camera looks (movimento.md, "Princípios"): facing_yaw copies the
# input's yaw every tick (TASK-9 plan).
func test_facing_yaw_copies_the_input_yaw() -> void:
	var rig := _rig(60)
	rig.step(MovementRig.idle())
	assert_float(rig.state.facing_yaw).is_equal(0.0)
	rig.step(MovementRig.run(Vector2.ZERO, 1.25))
	assert_float(rig.state.facing_yaw).is_equal(1.25)
	rig.step(MovementRig.run(Vector2(0, 1), -2.5))
	assert_float(rig.state.facing_yaw).is_equal(-2.5)
	var plan := rig.step(MovementRig.run(Vector2.ZERO, 3.0))
	assert_float(plan.state.facing_yaw).is_equal(3.0)


# The engine judges the slope with the config's 45° (movimento.md, "O corpo"); the core only
# reads facts.on_floor (TASK-9 plan): a ramp the engine rejects is air for the core, and one it
# accepts is ground.
func test_the_core_takes_the_floor_verdict_from_the_engine() -> void:
	var rig := _rig(60)
	rig.floor_on = false # a ramp steeper than 45°: the engine says it is not floor
	rig.step(MovementRig.idle())
	assert_bool(rig.state.on_floor).is_false()
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	rig.floor_on = true # a ramp of 45° or less, or flat ground
	rig.step(MovementRig.idle())
	assert_bool(rig.state.on_floor).is_true()
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GROUND)
