# Criteria 1 and 2 of TASK-10.10: the turn on the wall jump (movimento.md, "Corrida na parede":
# "A volta no pulo da parede"; F-131; F-136; Q-36). On the tick the wall jump fires, a stick
# with a component along the wall against the run's direction flips the sign of the velocity
# along the wall and keeps its speed; the push out of the wall and the height do not change; no
# stick, a forward stick or a stick pointing only out of (or into) the wall leave the jump as it
# was; the rule holds for a buffered jump too. In a corridor of 3,5 m the turned jump lands the
# body on the facing wall running back the way it came (movimento.md, "Métricas de nível": "A
# parede longa e o corredor", "Corredor estreito"). Through the public interface of
# core/fighter, with the engine's slice of the tick played by MovementRig against fake walls
# (visao-geral.md, "O tick por dentro: o sanduíche"; rede.md §4). Every number comes from
# docs/design/movimento.md, cited by section; ticks by hand from the ms, nearest tick with ties
# up (visao-geral.md, "O tempo e a física no estado"). The helpers are copies of those in
# movement_wall_test.gd, which is locked (TASK-10.5).
extends GdUnitTestSuite

const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)

# movimento.md, "Corrida na parede".
const WALL_ENTRY_SPEED_MPS := 4.0 # "Velocidade mínima para entrar", along the wall
const WALL_RUN_SPEED_MPS := 8.0 # "Velocidade na parede"
const WALL_JUMP_HEIGHT_M := 1.2 # "Pulo da parede": 1,2 m de altura
const WALL_JUMP_PUSH_MPS := 5.0 # "Pulo da parede": 5 m/s para fora da parede
# "Velocidade na parede: quem entra mais rápido conserva a velocidade de entrada": 10 m/s is a
# test speed inside the band of 8 to 12, as in movement_wall_test.gd, not a design number.
const FASTER_ENTRY_MPS := 10.0

# movimento.md, "Perdão" and "Pulo e ar".
const BUFFER_MS := 150 # "Perdão": "Buffer de input"
const HEIGHT_TOLERANCE_M := 0.01 # 1 cm (criterion 1; visao-geral.md, "O tempo e a física")
# 150 ms of buffer is 4.5 -> 5 at 30 (tie up) and 9 at 60, inclusive: the press counts while
# tick - stamp <= window (movimento.md, "Perdão"; DEC-0039).
const BUFFER_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }
# The full jump's rise by hand: 350 ms is 10.5 -> 11 ticks at 30 (tie up) and 21 at 60
# (movimento.md, "Pulo e ar": "Tempo de subida"): the wall jump is the same parabola.
const RISE_TICKS: Dictionary[int, int] = { 30: 11, 60: 21 }
const HALF_TICK_IN_MS_TIMES_RATE := 500 # |ticks * 1000 - ms * rate| <= 500 is half a tick

# The corridor (movimento.md, "Métricas de nível": "A parede longa e o corredor": "O corredor
# tem 3,5 m de vão interno: a 5 m/s para fora, 2,8 m de centro a centro levam 0,56 s"; "O
# corpo": "Raio da cápsula: 0,35"). The rig moves a point, so its two planes stand where the
# capsule's centre stops: the inner gap minus two radii.
const CAPSULE_RADIUS_M := 0.35
const CORRIDOR_INNER_GAP_M := 3.5
const CORRIDOR_CENTRE_GAP_M := CORRIDOR_INNER_GAP_M - 2.0 * CAPSULE_RADIUS_M # 2,8 m
const CROSSING_S := 0.56 # "2,8 m de centro a centro levam 0,56 s"
# The crossing in ticks is the design's 0,56 s rounded, give or take the probe's 5 cm and the
# tick the jump itself moves the body: two ticks of slack, not a design number.
const CROSSING_SLACK_TICKS := 2

# The geometry of the rig, not design numbers (movement_wall_test.gd): the body approaches the
# wall from APPROACH_M in front of it at APPROACH_SPEED_MPS into it, falling, with the floor far
# below; it runs RUN_TICKS_BEFORE_THE_JUMP ticks before the press.
const APPROACH_M := 0.9
const APPROACH_SPEED_MPS := 2.0
const START_HEIGHT_M := 10.0
const FALLING_VERTICAL_MPS := -6.0
const RUN_TICKS_BEFORE_THE_JUMP := 2
const COMMITTED_FLIGHT_TICKS := 30 # ticks of flight watched after the turn, not a design number
const HOLD_BACK_SECONDS := 3 # a generous budget for the "does not cross" case (criterion 2)
const WALL_A := &"ParedeA" # ids as the adapter reports them: node paths relative to the Arena
const WALL_B := &"ParedeB"

# The stick at yaw 0, which looks down -Z (TASK-9 plan): move.x goes right (+X, out of WALL_A)
# and move.y forward (-Z, the run's direction on WALL_A). "Along the wall" is the Z axis here,
# "out of the wall" the X axis.
const NO_STICK := Vector2.ZERO
const FORWARD := Vector2(0, 1)
const BACKWARD := Vector2(0, -1)
const OUTWARD := Vector2(1, 0)
const INTO_THE_WALL := Vector2(-1, 0)
const HALF_BACKWARD := Vector2(0, -0.5) # the stick half way: still a contrary component
const BACK_AND_OUT := Vector2(0.7071, -0.7071) # a unit stick, 45° back and out
const BACK_AND_IN := Vector2(-0.7071, -0.7071) # a unit stick, 45° back and in
# The limit: a stick almost perpendicular to the wall, with a 5 % component along it. The rule
# reads the sign of the component along the wall, not its size (movimento.md, "A volta no pulo
# da parede": "se a tecla tem componente ao longo da parede contrária ao sentido da corrida");
# 5 % is a test size, not a design number. Literal components, because a method call is not a
# constant expression in GDScript: each stick has length 1 to four decimals, never above it.
const BARELY_BACK := Vector2(0.9987, -0.0499) # a unit stick, 5 % back
const BARELY_FORWARD := Vector2(0.9987, 0.0499) # a unit stick, 5 % forward
# The camera turned around (yaw PI): "forward" on the stick is world +Z, against the run. This
# is how Arthur asked for it: "eu viro a câmera 360 e quero continuar andando na parede, só que
# voltando" (F-131).
const CAMERA_TURNED := PI

const HAIR := 1e-6 # floating-point slack, not a design number
# A Vector3 holds 32-bit floats: a few ticks of flight carry that error.
const GEOMETRY_HAIR := 1e-4


func _rig(tickrate: int) -> MovementRig:
	return MovementRig.new(MovementRig.load_config(tickrate), FIRST_TICK)


# A rig with no floor at all: the body never lands, the walls are the only contact.
func _air_rig(tickrate: int) -> MovementRig:
	var rig := _rig(tickrate)
	rig.floor_on = false
	return rig


func _horizontal(velocity: Vector3) -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)


# The velocity along the wall: the horizontal velocity projected on the plane of the flattened
# normal (movimento.md, "Corrida na parede": "O que decide a entrada").
func _along(velocity: Vector3, normal: Vector3) -> Vector3:
	var flat := Vector3(normal.x, 0.0, normal.z).normalized()
	var horizontal := _horizontal(velocity)
	return horizontal - flat * horizontal.dot(flat)


# The wall at x = 0 facing +X: the body runs along -Z beside it.
func _wall_a(rig: MovementRig) -> MovementRig.FakeWall:
	return rig.add_wall(Vector3.RIGHT, 0.0, WALL_A)


# The corridor: WALL_A and, facing it from x = CORRIDOR_CENTRE_GAP_M, WALL_B with its normal
# toward -X. The body lives between the two planes.
func _corridor(rig: MovementRig) -> void:
	_wall_a(rig)
	rig.add_wall(Vector3.LEFT, -CORRIDOR_CENTRE_GAP_M, WALL_B)


# Puts the body in the air APPROACH_M in front of the plane x = 0, flying into it at
# APPROACH_SPEED_MPS while running -Z at along_speed, falling.
func _approach_wall_a(rig: MovementRig, along_speed: float) -> void:
	rig.airborne(
		Vector3(APPROACH_M, START_HEIGHT_M, 0.0),
		Vector3(-APPROACH_SPEED_MPS, FALLING_VERTICAL_MPS, -along_speed),
	)


# Idles until the core starts a wall run; returns the entry tick, or fails.
func _fly_until_wall_run(rig: MovementRig, limit: int) -> int:
	for _step: int in limit:
		rig.step(MovementRig.idle())
		if rig.state.mode == FighterState.Mode.WALL_RUN:
			return rig.tick - 1
	fail("never started a wall run within %d ticks (at %d ticks)" % [limit, rig.config.tickrate])
	return -1


# Approaches WALL_A, enters the run and runs `ticks` ticks on it, proving each one goes -Z at
# this speed: the direction the turn must reverse. Returns the entry tick.
func _run_on_wall_a(rig: MovementRig, along_speed: float, ticks: int) -> int:
	_approach_wall_a(rig, along_speed)
	var entry_tick := _fly_until_wall_run(rig, 2 * rig.config.tickrate)
	_assert_wall_run_started(rig.state, entry_tick, WALL_A, Vector3.RIGHT)
	for _step: int in ticks:
		_assert_run_tick(rig.step(MovementRig.idle()), Vector3.FORWARD, along_speed, 0.0)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.WALL_RUN)
	return entry_tick


# Idles until the body stops rising; returns the highest position.y seen, or fails.
func _apex(rig: MovementRig, limit: int) -> float:
	var apex := rig.position.y
	for _step: int in limit:
		rig.step(MovementRig.idle())
		if rig.position.y > apex + HAIR:
			apex = rig.position.y
		elif rig.velocity.y <= 0.0:
			return apex
	fail("still rising after %d ticks" % limit)
	return apex


func _assert_slot(state: FighterState, command: StringName, buffered_tick: int) -> void:
	var slot := "slot holds (%s, %d), expected (%s, %d)" % [
		state.buffered_command,
		state.buffered_tick,
		command,
		buffered_tick,
	]
	assert_str(String(state.buffered_command)).override_failure_message(slot).is_equal(
		String(command)
	)
	assert_int(state.buffered_tick).override_failure_message(slot).is_equal(buffered_tick)


func _assert_wall_id(state: FighterState, wall: StringName) -> void:
	var message := "wall_id is %s, expected %s" % [state.wall_id, wall]
	assert_str(String(state.wall_id)).override_failure_message(message).is_equal(String(wall))


# The entry as the TASK-10.5 plan says it (DEC-0042): WALL_RUN since the entry tick, the wall's
# id and flattened normal in the state, and the double jump renewed.
func _assert_wall_run_started(
	state: FighterState,
	entry_tick: int,
	wall: StringName,
	normal: Vector3,
) -> void:
	assert_int(state.mode).override_failure_message("not in WALL_RUN").is_equal(
		FighterState.Mode.WALL_RUN
	)
	assert_int(state.mode_since).is_equal(entry_tick)
	_assert_wall_id(state, wall)
	var flat := Vector3(normal.x, 0.0, normal.z).normalized()
	var message := "wall_normal %s, expected the flattened %s" % [state.wall_normal, flat]
	assert_vector(state.wall_normal).override_failure_message(message).is_equal_approx(
		flat,
		Vector3.ONE * GEOMETRY_HAIR,
	)
	assert_int(state.jumps_used).override_failure_message("the double jump was not renewed") \
			.is_equal(0)
	assert_int(state.double_jump_tick).is_equal(FighterState.NEVER)


# A tick of the run: WALL_RUN, the horizontal velocity along the wall at this speed, and the
# vertical as given (0 while the height holds).
func _assert_run_tick(plan: MovePlan, direction: Vector3, speed: float, vertical: float) -> void:
	assert_int(plan.state.mode).override_failure_message("not in WALL_RUN").is_equal(
		FighterState.Mode.WALL_RUN
	)
	var expected := direction * speed
	var message := "horizontal velocity %s, expected %s" % [_horizontal(plan.velocity), expected]
	assert_vector(_horizontal(plan.velocity)).override_failure_message(message).is_equal_approx(
		expected,
		Vector3.ONE * HAIR,
	)
	var vertical_message := "vertical %.6f, expected %.6f" % [plan.velocity.y, vertical]
	assert_float(plan.velocity.y).override_failure_message(vertical_message).is_equal_approx(
		vertical,
		HAIR,
	)


# The wall jump as the TASK-10.5 plan says it (DEC-0041), turned or not: on the tick it fires
# the vertical is the wall jump's exit speed, the velocity gains wall_jump_push along the wall's
# normal and carries `along` along the wall (the run's own, or its reverse); it is the first
# jump of the flight, stamped, the mode is AIR since now, the double jump is untouched and the
# slot is consumed.
func _assert_wall_jumped(
	rig: MovementRig,
	plan: MovePlan,
	jump_tick: int,
	normal: Vector3,
	along: Vector3,
) -> void:
	assert_int(plan.state.mode).override_failure_message("still on the wall").is_equal(
		FighterState.Mode.AIR
	)
	assert_int(plan.state.mode_since).is_equal(jump_tick)
	assert_int(plan.state.wall_jump_tick).is_equal(jump_tick)
	assert_int(plan.state.jumps_used).override_failure_message("not the first jump").is_equal(1)
	assert_int(plan.state.double_jump_tick).is_equal(FighterState.NEVER)
	_assert_slot(plan.state, FighterCommand.NONE, FighterState.NEVER)
	assert_float(plan.velocity.y).override_failure_message("not the wall jump's exit speed") \
			.is_equal_approx(rig.config.wall_jump_speed, HAIR)
	var out := _horizontal(plan.velocity).dot(normal)
	assert_float(out) \
			.override_failure_message("%.4f m/s out of the wall, expected %.1f"
	% [out, WALL_JUMP_PUSH_MPS]) \
			.is_equal_approx(WALL_JUMP_PUSH_MPS, HAIR)
	var kept := _along(plan.velocity, normal)
	var message := "%s along the wall after the jump, expected %s" % [kept, along]
	assert_vector(kept).override_failure_message(message).is_equal_approx(along, Vector3.ONE * HAIR)


func _assert_height(actual: float, expected: float, what: String) -> void:
	var message := "%s: %.4f m, the design says %.3f m within %.2f m" % [
		what,
		actual,
		expected,
		HEIGHT_TOLERANCE_M,
	]
	assert_float(actual).override_failure_message(message).is_equal_approx(
		expected,
		HEIGHT_TOLERANCE_M,
	)


# The ms of the buffer become ticks by the rule of Ticks.from_ms, within half a tick: 5 at 30
# (4.5, tie up) and 9 at 60 (DEC-0004, rule 3; movimento.md, "Perdão"). The buffered half of
# criterion 1 leans on this window.
func test_the_buffer_window_of_150_ms_is_5_ticks_at_30_and_9_at_60(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var config := MovementRig.load_config(tickrate)
	assert_int(config.buffer_ticks).is_equal(BUFFER_TICKS[tickrate])
	assert_int(config.buffer_ticks).is_equal(Ticks.from_ms(BUFFER_MS, tickrate))
	assert_int(absi(config.buffer_ticks * 1000 - BUFFER_MS * tickrate)).is_less_equal(
		HALF_TICK_IN_MS_TIMES_RATE
	)
	assert_float(config.wall_run_speed).is_equal_approx(WALL_RUN_SPEED_MPS, HAIR)
	assert_float(config.wall_jump_push).is_equal_approx(WALL_JUMP_PUSH_MPS, HAIR)


# Criterion 1, the matrix of the stick on the tick of the press: a stick with a component along
# the wall against the run (straight back, half back, back and out, back and in, barely back,
# or forward with the camera turned around) flips the velocity along the wall to +Z at the same
# 8 m/s; no stick, forward, only out, only into the wall, barely forward, or back with the
# camera turned around leave it at -Z, as today. In every case the push is 5 m/s out, the rise
# is 1,2 m within 1 cm, and the flight's bookkeeping is the wall jump's (movimento.md, "Corrida
# na parede": "A volta no pulo da parede", "Pulo da parede"; F-131).
func test_the_wall_jump_turns_only_when_the_stick_has_a_component_against_the_run(
	tickrate: int,
	move: Vector2,
	yaw: float,
	turns: bool,
	_test_parameters := [
		[30, NO_STICK, 0.0, false],
		[60, NO_STICK, 0.0, false],
		[30, FORWARD, 0.0, false],
		[60, FORWARD, 0.0, false],
		[30, OUTWARD, 0.0, false],
		[60, OUTWARD, 0.0, false],
		[30, INTO_THE_WALL, 0.0, false],
		[60, INTO_THE_WALL, 0.0, false],
		[60, BARELY_FORWARD, 0.0, false],
		[60, BACKWARD, CAMERA_TURNED, false],
		[30, BACKWARD, 0.0, true],
		[60, BACKWARD, 0.0, true],
		[60, HALF_BACKWARD, 0.0, true],
		[30, BACK_AND_OUT, 0.0, true],
		[60, BACK_AND_OUT, 0.0, true],
		[60, BACK_AND_IN, 0.0, true],
		[30, BARELY_BACK, 0.0, true],
		[60, BARELY_BACK, 0.0, true],
		[30, FORWARD, CAMERA_TURNED, true],
		[60, FORWARD, CAMERA_TURNED, true],
	],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_run_on_wall_a(rig, WALL_RUN_SPEED_MPS, RUN_TICKS_BEFORE_THE_JUMP)
	var press_tick := rig.tick
	var press_height := rig.position.y
	var plan := rig.step(MovementRig.press_jump_toward(move, yaw))
	var direction := Vector3.BACK if turns else Vector3.FORWARD
	_assert_wall_jumped(rig, plan, press_tick, Vector3.RIGHT, direction * WALL_RUN_SPEED_MPS)
	var expected := Vector3(WALL_JUMP_PUSH_MPS, rig.config.wall_jump_speed, 0.0) \
			+ direction * WALL_RUN_SPEED_MPS
	var message := "jumped at %s with the stick %s at yaw %.2f, expected %s" % [
		plan.velocity,
		move,
		yaw,
		expected,
	]
	assert_vector(plan.velocity).override_failure_message(message).is_equal_approx(
		expected,
		Vector3.ONE * HAIR,
	)
	_assert_height(_apex(rig, 2 * tickrate) - press_height, WALL_JUMP_HEIGHT_M, "wall jump")
	assert_int(rig.state.jumps_used).is_equal(1)
	assert_int(rig.state.wall_jump_tick).is_equal(press_tick)
	_assert_wall_id(rig.state, WALL_A)


# The turn keeps a faster speed too: entered at 10, the turned jump leaves at 10 along the wall
# the other way, with the same 5 m/s out (movimento.md, "A volta no pulo da parede": "troca de
# sinal com a mesma rapidez"; "Velocidade na parede: quem entra mais rápido conserva").
func test_the_turned_wall_jump_keeps_a_faster_speed_along_the_wall(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_run_on_wall_a(rig, FASTER_ENTRY_MPS, RUN_TICKS_BEFORE_THE_JUMP)
	var press_tick := rig.tick
	var press_height := rig.position.y
	var plan := rig.step(MovementRig.press_jump_toward(BACKWARD))
	_assert_wall_jumped(rig, plan, press_tick, Vector3.RIGHT, Vector3.BACK * FASTER_ENTRY_MPS)
	assert_vector(plan.velocity).is_equal_approx(
		Vector3(WALL_JUMP_PUSH_MPS, rig.config.wall_jump_speed, FASTER_ENTRY_MPS),
		Vector3.ONE * HAIR,
	)
	_assert_height(_apex(rig, 2 * tickrate) - press_height, WALL_JUMP_HEIGHT_M, "turned wall jump")


# The turned flight is committed like any wall jump: with the stick released the velocity stays
# at 5 m/s out and 8 m/s back along the wall, tick after tick, the body moves +Z, and the apex
# comes rise_ticks after the press as the full jump's does (F-136: "O voo segue comprometido";
# movimento.md, "Pulo e ar": "Tempo de subida"; "Princípios": the speed is kept between moves).
func test_after_the_turn_the_flight_keeps_going_back_along_the_wall(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_run_on_wall_a(rig, WALL_RUN_SPEED_MPS, RUN_TICKS_BEFORE_THE_JUMP)
	var press_height := rig.position.y
	rig.step(MovementRig.press_jump_toward(BACKWARD))
	var launched := Vector3(WALL_JUMP_PUSH_MPS, 0.0, WALL_RUN_SPEED_MPS)
	var z_before := rig.position.z
	var apex_step := 1
	var apex := rig.position.y
	var violations: Array[String] = []
	for step: int in range(2, COMMITTED_FLIGHT_TICKS + 1):
		var plan := rig.step(MovementRig.idle())
		if not _horizontal(plan.velocity).is_equal_approx(launched):
			violations.append("tick +%d: horizontal %s" % [step, _horizontal(plan.velocity)])
		if plan.state.mode != FighterState.Mode.AIR:
			violations.append("tick +%d: mode %d" % [step, plan.state.mode])
		if rig.position.z <= z_before:
			violations.append("tick +%d: did not move +Z (%.4f)" % [step, rig.position.z])
		z_before = rig.position.z
		if rig.position.y > apex + HAIR:
			apex = rig.position.y
			apex_step = step
	assert_array(violations).override_failure_message("%s" % [violations]).is_empty()
	assert_int(apex_step).is_equal(RISE_TICKS[tickrate])
	_assert_height(apex - press_height, WALL_JUMP_HEIGHT_M, "turned wall jump")


# The slice is pure: the turn happens in the plan's copy, never in the state received
# (DEC-0004, rule 1).
func test_before_move_leaves_the_state_it_receives_untouched_when_the_jump_turns() -> void:
	var rig := _air_rig(60)
	_wall_a(rig)
	_run_on_wall_a(rig, WALL_RUN_SPEED_MPS, RUN_TICKS_BEFORE_THE_JUMP)
	var given := rig.state
	var plan := rig.step(MovementRig.press_jump_toward(BACKWARD))
	assert_int(plan.state.mode).is_equal(FighterState.Mode.AIR)
	assert_int(given.mode).is_equal(FighterState.Mode.WALL_RUN)
	assert_int(given.wall_jump_tick).is_equal(FighterState.NEVER)
	assert_int(given.jumps_used).is_equal(0)


# Criterion 1, the buffered jump: a press up to 150 ms before the touch (one tick before the
# first run tick, and at the limit of the window: 5 ticks at 30, 9 at 60) fires on the first
# run tick, and the stick of THAT tick decides the turn: held back then, the jump turns, with
# the same push and height. The design reads "No tick do pulo" and gives the buffered dash the
# same rule, "sai na direção do tick em que sai" (movimento.md, "A volta no pulo da parede":
# "vale para o pulo guardado"; "Dash": "Dash guardado"; "Pulo da parede no voo"; DEC-0016;
# DEC-0039). The double jump is spent so the press cannot fire in the air.
func test_a_buffered_jump_turns_with_the_stick_of_the_tick_it_fires(
	tickrate: int,
	ticks_before_the_first_run_tick: int,
	_test_parameters := [[30, 1], [30, 5], [60, 1], [60, 9]],
) -> void:
	var probe := _air_rig(tickrate)
	_wall_a(probe)
	_approach_wall_a(probe, WALL_RUN_SPEED_MPS)
	probe.state.jumps_used = 2
	probe.state.double_jump_tick = probe.tick - 1
	var entry_tick := _fly_until_wall_run(probe, 2 * tickrate)
	var first_run_tick := entry_tick + 1
	var press_tick := first_run_tick - ticks_before_the_first_run_tick
	assert_int(first_run_tick - press_tick).is_less_equal(BUFFER_TICKS[tickrate])
	assert_int(press_tick).is_greater_equal(FIRST_TICK)
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS)
	rig.state.jumps_used = 2
	rig.state.double_jump_tick = rig.tick - 1
	while rig.tick <= entry_tick:
		var input := MovementRig.press_jump() if rig.tick == press_tick else MovementRig.idle()
		var plan := rig.step(input)
		assert_int(plan.state.wall_jump_tick).override_failure_message("jumped before the run") \
				.is_equal(FighterState.NEVER)
		assert_int(plan.state.jumps_used).override_failure_message("jumped in the air").is_equal(2)
	_assert_wall_run_started(rig.state, entry_tick, WALL_A, Vector3.RIGHT)
	_assert_slot(rig.state, FighterCommand.JUMP, press_tick)
	var fire_height := rig.position.y
	var plan := rig.step(MovementRig.run(BACKWARD))
	_assert_wall_jumped(rig, plan, first_run_tick, Vector3.RIGHT, Vector3.BACK * WALL_RUN_SPEED_MPS)
	assert_vector(plan.velocity).is_equal_approx(
		Vector3(WALL_JUMP_PUSH_MPS, rig.config.wall_jump_speed, WALL_RUN_SPEED_MPS),
		Vector3.ONE * HAIR,
	)
	_assert_height(_apex(rig, 2 * tickrate) - fire_height, WALL_JUMP_HEIGHT_M, "buffered turn")


# The other half of the same rule: the stick of the press tick does not decide. Pressed in the
# air with the stick held back, and released by the first run tick, the buffered jump fires as
# today, along the run. The body enters at 10 m/s so that the one tick of air braking at the
# press (movimento.md, "Pulo e ar": "Controle no ar") leaves it inside the band of 8 to 12 the
# run conserves; the jump then keeps exactly the velocity along the wall the entry's facts
# reported (movimento.md, "Dash": "Dash guardado: sai na direção do tick em que sai").
func test_a_buffered_jump_ignores_the_stick_of_the_press_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var probe := _air_rig(tickrate)
	_wall_a(probe)
	_approach_wall_a(probe, FASTER_ENTRY_MPS)
	probe.state.jumps_used = 2
	probe.state.double_jump_tick = probe.tick - 1
	var press_tick := _fly_until_wall_run(probe, 2 * tickrate) # one tick before the first run tick
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, FASTER_ENTRY_MPS)
	rig.state.jumps_used = 2
	rig.state.double_jump_tick = rig.tick - 1
	var entry_tick := -1
	var entry_along := Vector3.ZERO
	for _step: int in 2 * tickrate:
		var input := MovementRig.press_jump_toward(BACKWARD) if rig.tick == press_tick \
				else MovementRig.idle()
		var plan := rig.step(input)
		assert_int(plan.state.wall_jump_tick).override_failure_message("jumped before the run") \
				.is_equal(FighterState.NEVER)
		if rig.state.mode == FighterState.Mode.WALL_RUN:
			entry_tick = rig.tick - 1
			entry_along = _along(rig.last_facts.velocity, Vector3.RIGHT)
			break
	assert_int(entry_tick).override_failure_message("never started a wall run") \
			.is_greater_equal(press_tick)
	assert_int(entry_tick + 1 - press_tick).is_less_equal(BUFFER_TICKS[tickrate])
	_assert_wall_run_started(rig.state, entry_tick, WALL_A, Vector3.RIGHT)
	_assert_slot(rig.state, FighterCommand.JUMP, press_tick)
	assert_float(entry_along.z).override_failure_message("the entry was not along -Z").is_less(
		-WALL_RUN_SPEED_MPS
	)
	var plan := rig.step(MovementRig.idle())
	_assert_wall_jumped(rig, plan, entry_tick + 1, Vector3.RIGHT, entry_along)
	assert_float(plan.velocity.z).override_failure_message("the press tick's stick turned it") \
			.is_less(0.0)


# Criterion 2: in the corridor of 3,5 m (2,8 m from centre to centre), the turned jump from
# WALL_A with the stick released in the air reaches WALL_B in about 0,56 s, higher than it
# left, and starts a run there going +Z: back the way the first run came (movimento.md,
# "Métricas de nível": "A parede longa e o corredor", "Corredor estreito"; F-131; F-135).
func test_the_turned_jump_crosses_the_corridor_and_runs_back_on_the_facing_wall(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_corridor(rig)
	_run_on_wall_a(rig, WALL_RUN_SPEED_MPS, RUN_TICKS_BEFORE_THE_JUMP)
	var press_tick := rig.tick
	var press_height := rig.position.y
	var plan := rig.step(MovementRig.press_jump_toward(BACKWARD))
	_assert_wall_jumped(rig, plan, press_tick, Vector3.RIGHT, Vector3.BACK * WALL_RUN_SPEED_MPS)
	var entry_tick := _fly_until_wall_run(rig, 2 * tickrate)
	_assert_wall_run_started(rig.state, entry_tick, WALL_B, Vector3.LEFT)
	assert_float(rig.position.x).override_failure_message("not beside WALL_B").is_between(
		CORRIDOR_CENTRE_GAP_M - MovementRig.WALL_PROBE_DISTANCE - HAIR,
		CORRIDOR_CENTRE_GAP_M + HAIR,
	)
	var crossing_ticks := entry_tick - press_tick
	var expected_ticks := roundi(CROSSING_S * tickrate)
	var timing := "crossed in %d ticks at %d, the design says %.2f s (%d ticks)" % [
		crossing_ticks,
		tickrate,
		CROSSING_S,
		expected_ticks,
	]
	assert_int(absi(crossing_ticks - expected_ticks)).override_failure_message(timing) \
			.is_less_equal(CROSSING_SLACK_TICKS)
	var climb := "entered WALL_B at %.3f m, left WALL_A at %.3f m: no elevator" % [
		rig.position.y,
		press_height,
	]
	assert_float(rig.position.y).override_failure_message(climb).is_greater(
		press_height + HEIGHT_TOLERANCE_M
	)
	var first := rig.step(MovementRig.idle())
	_assert_run_tick(first, Vector3.BACK, WALL_RUN_SPEED_MPS, 0.0)
	var second := rig.step(MovementRig.idle())
	_assert_run_tick(second, Vector3.BACK, WALL_RUN_SPEED_MPS, 0.0)
	_assert_wall_id(rig.state, WALL_B)
	assert_int(rig.state.mode_since).is_equal(entry_tick)


# Criterion 2, the failure that is not an error: with the stick held straight back along the
# wall for the whole flight, the air control turns the velocity toward +Z by the air
# acceleration alone (0,194 m/s per tick at 60; movimento.md, "Pulo e ar": "Controle no ar"),
# so the 5 m/s out of the wall die within about a metre and the body never reaches WALL_B: it
# stays in the air, in no wall run, with WALL_A still the last wall, for three seconds.
func test_holding_straight_back_in_the_air_does_not_reach_the_facing_wall(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_corridor(rig)
	_run_on_wall_a(rig, WALL_RUN_SPEED_MPS, RUN_TICKS_BEFORE_THE_JUMP)
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_jump_toward(BACKWARD))
	_assert_wall_jumped(rig, plan, press_tick, Vector3.RIGHT, Vector3.BACK * WALL_RUN_SPEED_MPS)
	var farthest_x := rig.position.x
	var violations: Array[String] = []
	for step: int in range(1, HOLD_BACK_SECONDS * tickrate + 1):
		var next := rig.step(MovementRig.run(BACKWARD))
		farthest_x = maxf(farthest_x, rig.position.x)
		if next.state.mode != FighterState.Mode.AIR or rig.state.mode != FighterState.Mode.AIR:
			violations.append("tick +%d: mode %d" % [step, rig.state.mode])
		if rig.last_facts.wall_id == WALL_B or rig.state.wall_id == WALL_B:
			violations.append("tick +%d: touched WALL_B" % step)
	assert_array(violations).override_failure_message("%s" % [violations]).is_empty()
	assert_float(farthest_x).override_failure_message("got within reach of WALL_B") \
			.is_less(CORRIDOR_CENTRE_GAP_M - MovementRig.WALL_PROBE_DISTANCE)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	_assert_wall_id(rig.state, WALL_A)
	assert_int(rig.state.jumps_used).is_equal(1)
	assert_int(rig.state.wall_jump_tick).is_equal(press_tick)


# Many: going back and forth, the corridor is an elevator. Four turned jumps alternate the walls
# and the directions, A going -Z, B going +Z, A going -Z, B going +Z, each entry higher than the
# last; the stick points against the current run each time, so it flips with the wall. The map
# limits the climb, not a rule (movimento.md, "Métricas de nível": "Corredor estreito"; F-135).
func test_turned_jumps_climb_the_corridor_going_back_and_forth(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_corridor(rig)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS)
	var expected_walls: Array[StringName] = [WALL_A, WALL_B, WALL_A, WALL_B]
	var heights: Array[float] = []
	for hop: int in expected_walls.size():
		var entry_tick := _fly_until_wall_run(rig, 2 * tickrate)
		var on_a := expected_walls[hop] == WALL_A
		var normal := Vector3.RIGHT if on_a else Vector3.LEFT
		var direction := Vector3.FORWARD if on_a else Vector3.BACK
		_assert_wall_run_started(rig.state, entry_tick, expected_walls[hop], normal)
		heights.append(rig.position.y)
		_assert_run_tick(rig.step(MovementRig.idle()), direction, WALL_RUN_SPEED_MPS, 0.0)
		# Against the current run: back on the stick while running -Z, forward while running +Z.
		var against := BACKWARD if on_a else FORWARD
		var press_tick := rig.tick
		var plan := rig.step(MovementRig.press_jump_toward(against))
		_assert_wall_jumped(rig, plan, press_tick, normal, -direction * WALL_RUN_SPEED_MPS)
	for hop: int in range(1, heights.size()):
		var message := "hop %d entered at %.3f m, below or at the previous %.3f m: %s" % [
			hop,
			heights[hop],
			heights[hop - 1],
			heights,
		]
		assert_float(heights[hop]).override_failure_message(message).is_greater(
			heights[hop - 1] + HEIGHT_TOLERANCE_M
		)
