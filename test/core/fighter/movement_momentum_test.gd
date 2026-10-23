# The momentum half of criterion 5 of TASK-10.5 (movimento.md, "Pulo e ar": "Controle no ar";
# "Princípios": "a velocidade se conserva entre manobras ... no ar, o input não corta o
# excesso"; F-127; the Q-07 Arthur judges by playing): in the air above the run speed of 7 m/s,
# the direction input turns and brakes the velocity only by the air acceleration, 0,194 m/s per
# tick at 60, and never cuts the excess at once; on the ground, the excess decays by the ground
# acceleration. Below the run speed nothing changes: the jump, the double jump and the air
# control of TASK-9 and TASK-10.1 behave as before (the regression guard). Through the public
# interface of core/fighter, with the engine's slice of the tick played by MovementRig
# (visao-geral.md, "O tick por dentro: o sanduíche"). Every number comes from
# docs/design/movimento.md, cited by section.
extends GdUnitTestSuite

const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)

const RUN_SPEED_MPS := 7.0 # movimento.md, "Chão": "Velocidade de corrida"
const ACCEL_TIME_MS := 150 # movimento.md, "Chão": "Tempo até a velocidade máxima"
const AIR_CONTROL_PCT := 25.0 # movimento.md, "Pulo e ar": "Controle no ar: 25 % da aceleração"
const AIR_ACCEL_PER_TICK_AT_60 := 0.194 # movimento.md, "Pulo e ar": "0,194 m/s por tick a 60"
const AIR_ACCEL_TOLERANCE := 5e-4 # the design rounds to three decimals, not a design number
# 150 ms until full speed is 4.5 -> 5 ticks at 30 (tie up) and 9 at 60: the ground acceleration
# is 7 / 5 = 1,4 m/s per tick at 30 and 7 / 9 = 0,778 at 60; a quarter of it in the air.
const ACCEL_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }

# Speeds above the run speed, as a wall jump leaves them (8 along and 5 out is 9,43 m/s;
# movimento.md, "Corrida na parede"): arbitrary test speeds, not design numbers.
const EXCESS_SPEED_MPS := 10.0
const WALL_JUMP_SPEED_MPS := 9.43
const BELOW_RUN_SPEED_MPS := 3.0
const START_HEIGHT_M := 10.0 # the floor far below; the air tests switch it off anyway
# Ticks of turning or braking input watched from 10 m/s: at 30 ticks the air acceleration is
# 0,35 per tick, so eight ticks brake to 7,2 m/s, still above the run speed.
const TURN_TICKS := 8

const FORWARD := Vector2(0, 1) # move.y goes forward: yaw 0 looks down -Z (TASK-9 plan)
const BACKWARD := Vector2(0, -1)
const RIGHT := Vector2(1, 0)

const HAIR := 1e-6 # floating-point slack, not a design number
const DRIFT := 1e-4 # the drift of float32 vectors over many ticks, not a design number


func _rig(tickrate: int) -> MovementRig:
	return MovementRig.new(MovementRig.load_config(tickrate), FIRST_TICK)


# A rig in the air with no floor, flying at this horizontal velocity, by hand (as after a wall
# jump: the wall tests make the real one, movement_wall_test.gd).
func _flying(tickrate: int, horizontal: Vector3) -> MovementRig:
	var rig := _rig(tickrate)
	rig.floor_on = false
	rig.airborne(Vector3(0.0, START_HEIGHT_M, 0.0), horizontal)
	return rig


# The world direction of a move (TASK-9 plan): yaw 0 looks down -Z, move.x goes right and
# move.y goes forward.
func _world_direction(move: Vector2, yaw: float) -> Vector3:
	return (Basis(Vector3.UP, yaw) * Vector3(move.x, 0.0, -move.y)).normalized()


func _horizontal(velocity: Vector3) -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)


# The design's air acceleration per tick: a quarter of the ground's, 7 m/s over 9 ticks at 60
# (0,194 m/s per tick) and over 5 at 30 (0,35) (movimento.md, "Chão" and "Pulo e ar").
func test_the_air_acceleration_is_a_quarter_of_the_ground_acceleration_0_194_per_tick_at_60(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var config := MovementRig.load_config(tickrate)
	assert_int(config.accel_ticks).is_equal(ACCEL_TICKS[tickrate])
	assert_int(config.accel_ticks).is_equal(Ticks.from_ms(ACCEL_TIME_MS, tickrate))
	assert_float(config.ground_accel_per_tick).is_equal_approx(
		RUN_SPEED_MPS / ACCEL_TICKS[tickrate],
		HAIR,
	)
	assert_float(config.air_accel_per_tick).is_equal_approx(
		config.ground_accel_per_tick * AIR_CONTROL_PCT / 100.0,
		HAIR,
	)
	if tickrate == 60:
		assert_float(config.air_accel_per_tick).is_equal_approx(
			AIR_ACCEL_PER_TICK_AT_60,
			AIR_ACCEL_TOLERANCE,
		)


# Above the run speed, an input along the velocity keeps it whole, tick after tick: the excess
# is never cut to 7 (movimento.md, "Pulo e ar": "sem cortar o excesso").
func test_in_the_air_above_the_run_speed_an_input_along_the_velocity_keeps_it(
	tickrate: int,
	speed: float,
	_test_parameters := [
		[30, EXCESS_SPEED_MPS],
		[60, EXCESS_SPEED_MPS],
		[30, WALL_JUMP_SPEED_MPS],
		[60, WALL_JUMP_SPEED_MPS],
	],
) -> void:
	var rig := _flying(tickrate, Vector3.FORWARD * speed)
	var violations: Array[String] = []
	for step: int in range(1, 2 * tickrate + 1):
		var plan := rig.step(MovementRig.run(FORWARD))
		if not _horizontal(plan.velocity).is_equal_approx(Vector3.FORWARD * speed):
			violations.append(
				"tick %d: %s, launched at %.2f m/s" % [step, _horizontal(plan.velocity), speed]
			)
	assert_array(violations).override_failure_message("%s" % [violations]).is_empty()
	assert_float(rig.horizontal_speed()).is_equal_approx(speed, DRIFT)


# Without input the excess is kept too, as before.
func test_in_the_air_without_input_the_excess_is_kept(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _flying(tickrate, Vector3.FORWARD * EXCESS_SPEED_MPS)
	rig.rest(tickrate)
	assert_vector(rig.horizontal_velocity()).is_equal_approx(
		Vector3.FORWARD * EXCESS_SPEED_MPS,
		Vector3.ONE * HAIR,
	)


# A sideways input turns the velocity only by the air acceleration: each tick the horizontal
# velocity moves at most air_accel_per_tick toward the pointed direction at its own speed, so
# the speed never drops by more than that in a tick, and nothing is cut: at 10 m/s, eight ticks
# of input to the right leave it above 7 (movimento.md, "Pulo e ar": "o input só gira e
# freia pela aceleração do ar"; TASK-10.5 plan: the target is the direction at
# max(run_speed, |v|)).
func test_in_the_air_above_the_run_speed_a_sideways_input_turns_by_the_air_acceleration_only(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _flying(tickrate, Vector3.FORWARD * EXCESS_SPEED_MPS)
	var accel := rig.config.air_accel_per_tick
	var pointed := _world_direction(RIGHT, 0.0)
	var violations: Array[String] = []
	for step: int in range(1, TURN_TICKS + 1):
		var before := rig.horizontal_velocity()
		var plan := rig.step(MovementRig.run(RIGHT))
		var after := _horizontal(plan.velocity)
		var expected := before.move_toward(pointed * maxf(RUN_SPEED_MPS, before.length()), accel)
		if not after.is_equal_approx(expected):
			violations.append("tick %d: %s, expected %s from %s" % [step, after, expected, before])
		if (after - before).length() > accel + HAIR:
			violations.append(
				"tick %d: changed by %.4f, more than %.4f"
				% [step, (after - before).length(), accel]
			)
		if after.length() < before.length() - accel - HAIR:
			violations.append(
				"tick %d: cut from %.4f to %.4f" % [step, before.length(), after.length()]
			)
	assert_array(violations).override_failure_message("%s" % [violations]).is_empty()
	assert_float(rig.horizontal_speed()).override_failure_message("cut to the run speed") \
			.is_greater(RUN_SPEED_MPS + HAIR)
	assert_float(rig.horizontal_velocity().x).override_failure_message("did not turn").is_greater(
		HAIR
	)


# The opposite input brakes only by the air acceleration: exactly air_accel_per_tick less
# each tick, in the same direction, and still above 7 after eight ticks at 10 m/s
# (movimento.md, "Pulo e ar": "o input contrário freia só por ela").
func test_in_the_air_above_the_run_speed_the_opposite_input_brakes_by_the_air_acceleration_only(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _flying(tickrate, Vector3.FORWARD * EXCESS_SPEED_MPS)
	var accel := rig.config.air_accel_per_tick
	var violations: Array[String] = []
	for step: int in range(1, TURN_TICKS + 1):
		var plan := rig.step(MovementRig.run(BACKWARD))
		var expected := EXCESS_SPEED_MPS - step * accel
		var after := _horizontal(plan.velocity)
		if not after.is_equal_approx(Vector3.FORWARD * expected):
			violations.append("tick %d: %s, expected %.4f m/s forward" % [step, after, expected])
	assert_array(violations).override_failure_message("%s" % [violations]).is_empty()
	assert_float(rig.horizontal_speed()).is_greater(RUN_SPEED_MPS)


# On the ground the excess decays by the ground acceleration: landed at 10 m/s with the input
# held forward, each tick takes ground_accel_per_tick off until exactly 7, never below
# (movimento.md, "Pulo e ar": "no chão, o excesso cai pela aceleração do chão"; "Chão").
func test_on_the_ground_the_excess_decays_by_the_ground_acceleration_down_to_7(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.velocity = Vector3.FORWARD * EXCESS_SPEED_MPS # as the landing tick leaves it
	var accel := rig.config.ground_accel_per_tick
	var violations: Array[String] = []
	for step: int in range(1, 2 * ACCEL_TICKS[tickrate] + 1):
		var plan := rig.step(MovementRig.run(FORWARD))
		var expected := maxf(RUN_SPEED_MPS, EXCESS_SPEED_MPS - step * accel)
		var after := _horizontal(plan.velocity)
		if not after.is_equal_approx(Vector3.FORWARD * expected):
			violations.append("tick %d: %s, expected %.4f m/s forward" % [step, after, expected])
		if not rig.state.on_floor:
			violations.append("tick %d: left the floor" % step)
	assert_array(violations).override_failure_message("%s" % [violations]).is_empty()
	assert_float(rig.horizontal_speed()).is_equal_approx(RUN_SPEED_MPS, HAIR)


# Regression guard: below the run speed the air control still adds a quarter of the ground
# acceleration per tick and caps at 7 (movimento.md, "Pulo e ar": "Controle no ar"; "Chão").
func test_below_the_run_speed_the_air_control_still_adds_the_quarter_and_caps_at_7(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _flying(tickrate, Vector3.FORWARD * BELOW_RUN_SPEED_MPS)
	var accel := rig.config.air_accel_per_tick
	var violations: Array[String] = []
	for step: int in range(1, 2 * tickrate + 1):
		var plan := rig.step(MovementRig.run(FORWARD))
		var expected := minf(RUN_SPEED_MPS, BELOW_RUN_SPEED_MPS + step * accel)
		var after := _horizontal(plan.velocity)
		if not after.is_equal_approx(Vector3.FORWARD * expected):
			violations.append("tick %d: %s, expected %.4f m/s forward" % [step, after, expected])
	assert_array(violations).override_failure_message("%s" % [violations]).is_empty()
	assert_float(rig.horizontal_speed()).is_equal_approx(RUN_SPEED_MPS, HAIR)


# Regression guard: at exactly the run speed, an input along the velocity changes nothing, and
# a sideways one turns it by the air acceleration toward the direction at 7, as before.
func test_at_the_run_speed_the_air_control_behaves_as_before(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _flying(tickrate, Vector3.FORWARD * RUN_SPEED_MPS)
	var accel := rig.config.air_accel_per_tick
	var kept := rig.step(MovementRig.run(FORWARD))
	assert_vector(_horizontal(kept.velocity)).is_equal_approx(
		Vector3.FORWARD * RUN_SPEED_MPS,
		Vector3.ONE * HAIR,
	)
	var before := rig.horizontal_velocity()
	var turned := rig.step(MovementRig.run(RIGHT))
	var expected := before.move_toward(_world_direction(RIGHT, 0.0) * RUN_SPEED_MPS, accel)
	assert_vector(_horizontal(turned.velocity)).is_equal_approx(expected, Vector3.ONE * HAIR)
	assert_float(_horizontal(turned.velocity).length()).is_less_equal(RUN_SPEED_MPS + HAIR)


# Regression guard: the jump from a full run keeps 7 m/s for the whole flight with the input
# held forward, and the double jump turns it to the pointed direction at the same 7 m/s, as
# TASK-10.1 settled (movimento.md, "Pulo e ar": "Direção do pulo duplo").
func test_a_jump_from_a_full_run_still_holds_7_mps_with_the_input_held(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	for _step: int in tickrate:
		rig.step(MovementRig.run(FORWARD))
	assert_float(rig.horizontal_speed()).is_equal_approx(RUN_SPEED_MPS, HAIR)
	rig.step(MovementRig.press_jump_toward(FORWARD))
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	var violations: Array[String] = []
	var landed := false
	for step: int in range(1, 3 * tickrate + 1):
		var plan := rig.step(MovementRig.run(FORWARD))
		if not _horizontal(plan.velocity).is_equal_approx(Vector3.FORWARD * RUN_SPEED_MPS):
			violations.append("tick %d: %s" % [step, _horizontal(plan.velocity)])
		if rig.state.on_floor:
			landed = true
			break
	assert_array(violations).override_failure_message("%s" % [violations]).is_empty()
	assert_bool(landed).override_failure_message("never landed").is_true()
	var again := _rig(tickrate)
	for _step: int in tickrate:
		again.step(MovementRig.run(FORWARD))
	again.step(MovementRig.press_jump_toward(FORWARD))
	again.rest(2)
	var plan := again.step(MovementRig.press_jump_toward(RIGHT))
	assert_int(plan.state.jumps_used).is_equal(2)
	assert_vector(_horizontal(plan.velocity)).is_equal_approx(
		_world_direction(RIGHT, 0.0) * RUN_SPEED_MPS,
		Vector3.ONE * HAIR,
	)
