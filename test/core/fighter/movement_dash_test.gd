# Criteria 1 to 4 of TASK-10.4: the dash, the maneuver of the floor (movimento.md, "Dash"), a
# committed mode that only ends by its own rule (DEC-0041), paid in stamina, with one cooldown
# and the single slot of the buffer (DEC-0039; movimento.md, "Perdão" and "Stamina"), through the
# public interface of core/fighter, with the engine's slice of the tick played by MovementRig on
# a flat floor, off a ledge, down a 45° ramp and against a wall (visao-geral.md, "O tick por
# dentro: o sanduíche"). Every number comes from docs/design/movimento.md, cited by section;
# ticks by hand from the ms, nearest tick with ties up (visao-geral.md, "O tempo e a física no
# estado").
extends GdUnitTestSuite

const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)

const DASH_DISTANCE_M := 4.0 # movimento.md, "Dash": "Distância"
const DASH_MS := 200 # movimento.md, "Dash": "Duração"
const DASH_SPEED_MPS := 20.0 # movimento.md, "Dash": "Deriva a velocidade: 20 m/s"
const DASH_EXIT_SPEED_MPS := 7.0 # movimento.md, "Dash": "Velocidade na saída"
const DASH_COOLDOWN_MS := 400 # movimento.md, "Dash": "Recarga", counted from the end
const DASH_COST := 15.0 # movimento.md, "Dash": "Custo"
const STAMINA_MAX := 100.0 # movimento.md, "Stamina": "Máximo"
const BELOW_COST := 14.5 # TASK-10.4, criterion 2: a bar of 14.5 cannot pay the cost of 15
const DISTANCE_TOLERANCE_M := 0.01 # 1 cm (criterion 1)

# The dash by hand (movimento.md, "Dash"): 200 ms is 6 ticks at 30 and 12 at 60, exact; 400 ms
# of cooldown is 12 at 30 and 24 at 60, exact; the speed is 4 m over those ticks, 20 m/s at both
# rates. The next dash may start dash_ticks + cooldown_ticks after the start of the last one:
# 18 ticks at 30, 36 at 60.
const DASH_TICKS: Dictionary[int, int] = { 30: 6, 60: 12 }
const COOLDOWN_TICKS: Dictionary[int, int] = { 30: 12, 60: 24 }
const PERIOD_TICKS: Dictionary[int, int] = { 30: 18, 60: 36 }
# 150 ms of buffer is 4.5 -> 5 at 30 (tie up) and 9 at 60, inclusive: the press counts while
# tick - stamp <= window (movimento.md, "Perdão"; DEC-0039).
const BUFFER_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }
# 800 ms of wait is 24 ticks at 30 and 48 at 60; 30 points per second is 1.0 per tick at 30 and
# 0.5 at 60 (movimento.md, "Stamina"). From 14.5, the first tick after the wait reads 15.5 at 30
# and 15.0 at 60: the first tick that can pay the cost of 15.
const STAMINA_WAIT_TICKS: Dictionary[int, int] = { 30: 24, 60: 48 }
const REGEN_PER_TICK: Dictionary[int, float] = { 30: 1.0, 60: 0.5 }

const FORWARD := Vector2(0, 1) # move.y goes forward: yaw 0 looks down -Z (TASK-9 plan)
const RIGHT := Vector2(1, 0)
const WALL_X := 1.0 # a wall 1 m ahead of the start: an arbitrary distance, not a design number

const HAIR := 1e-6 # floating-point slack, not a design number
const HALF_TICK_IN_MS_TIMES_RATE := 500 # |ticks * 1000 - ms * rate| <= 500 is half a tick


# One dash recorded from a press. The press tick is the first of the dash_ticks ticks of the
# dash, because the body already moves during it (TASK-9 plan); the exit tick comes right after.
class DashRecord:
	var press_tick := 0
	var start := Vector3.ZERO # position when the press tick began
	var plans: Array[MovePlan] = [] # the dash ticks, the press first
	var positions: Array[Vector3] = [] # position after each dash tick
	var on_floor: Array[bool] = [] # the engine's verdict after each dash tick
	var exit_tick := 0
	var exit_plan: MovePlan


	func horizontal_displacement() -> Vector3:
		var moved := positions[positions.size() - 1] - start
		return Vector3(moved.x, 0.0, moved.z)


	func dash_mode_ticks() -> int:
		var count := 0
		for plan: MovePlan in plans:
			if plan.state.mode == FighterState.Mode.DASH:
				count += 1
		return count


func _rig(tickrate: int) -> MovementRig:
	return MovementRig.new(MovementRig.load_config(tickrate), FIRST_TICK)


func _v0_copy() -> MovementData:
	var resource: Resource = load(MovementRig.MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MovementRig.MOVEMENT_V0)
	var copy: Resource = resource.duplicate()
	assert(copy is MovementData, "a duplicate must still be a MovementData")
	return copy as MovementData


# The world direction of a move (TASK-9 plan): yaw 0 looks down -Z, move.x goes right and
# move.y goes forward.
func _world_direction(move: Vector2, yaw: float) -> Vector3:
	return (Basis(Vector3.UP, yaw) * Vector3(move.x, 0.0, -move.y)).normalized()


# Where the body looks with that yaw: the forward of the camera, horizontal (movimento.md,
# "Princípios": the body looks where the camera looks).
func _facing(yaw: float) -> Vector3:
	return -Basis(Vector3.UP, yaw).z


func _horizontal(velocity: Vector3) -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)


# Presses now and plays the dash_ticks ticks of the dash plus the exit tick, feeding `during`
# in a cycle after the press (idle when empty).
func _dash(rig: MovementRig, press: TickInput, during: Array[TickInput] = []) -> DashRecord:
	var record := DashRecord.new()
	record.press_tick = rig.tick
	record.start = rig.position
	var ticks := rig.config.dash_ticks
	for step: int in ticks:
		var input := press if step == 0 else _cycled(during, step)
		record.plans.append(rig.step(input))
		record.positions.append(rig.position)
		record.on_floor.append(rig.state.on_floor)
	record.exit_tick = rig.tick
	record.exit_plan = rig.step(_cycled(during, ticks))
	return record


func _cycled(inputs: Array[TickInput], step: int) -> TickInput:
	if inputs.is_empty():
		return MovementRig.idle()
	return inputs[(step - 1) % inputs.size()]


# Idles until the fighter lands; returns the landing tick, or fails.
func _idle_until_landed(rig: MovementRig) -> int:
	for _step: int in range(1, 5 * rig.config.tickrate + 1):
		rig.step(MovementRig.idle())
		if rig.state.on_floor:
			return rig.tick - 1
	fail("never landed at %d ticks" % rig.config.tickrate)
	return 0


# The landing tick of a plain jump pressed at FIRST_TICK, to place presses relative to it.
func _landing_tick_of_a_jump(tickrate: int) -> int:
	var rig := _rig(tickrate)
	rig.step(MovementRig.press_jump())
	return _idle_until_landed(rig)


# The landing tick of a jump at FIRST_TICK whose double jump was spent on the next tick.
func _landing_tick_with_the_double_jump_spent(tickrate: int) -> int:
	var rig := _rig(tickrate)
	rig.step(MovementRig.press_jump())
	_spend_double_jump(rig)
	return _idle_until_landed(rig)


func _spend_double_jump(rig: MovementRig) -> void:
	var plan := rig.step(MovementRig.press_jump())
	assert_int(plan.state.jumps_used).override_failure_message("not spent").is_equal(2)


# Idles up to (not including) tick, pressing `press` on press_tick, and asserts no dash starts
# in between: dash_tick stays at `dash_tick_before` and the mode never reads DASH.
func _idle_until_with_press(
	rig: MovementRig,
	tick: int,
	press_tick: int,
	press: TickInput,
	dash_tick_before: int,
) -> void:
	var violations: Array[String] = []
	while rig.tick < tick:
		var input := press if rig.tick == press_tick else MovementRig.idle()
		var plan := rig.step(input)
		if plan.state.mode == FighterState.Mode.DASH or plan.state.dash_tick != dash_tick_before:
			violations.append(
				"tick %d: dashed (dash_tick %d)" % [rig.tick - 1, plan.state.dash_tick]
			)
	assert_array(violations).override_failure_message("dashed before tick %d" % tick).is_empty()


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


# The press tick of a dash as the plan says it (TASK-10.4 plan; DEC-0041): the mode DASH since
# now, the stamp, the direction fixed as a horizontal unit vector, the cost paid now, the slot
# consumed, and the body already at the dash speed in that direction.
func _assert_dash_started(
	rig: MovementRig,
	plan: MovePlan,
	press_tick: int,
	direction: Vector3,
) -> void:
	assert_int(plan.state.mode).override_failure_message("not in DASH").is_equal(
		FighterState.Mode.DASH
	)
	assert_int(plan.state.mode_since).is_equal(press_tick)
	assert_int(plan.state.dash_tick).is_equal(press_tick)
	var fixed := "dash_direction %s, expected %s" % [plan.state.dash_direction, direction]
	assert_vector(plan.state.dash_direction).override_failure_message(fixed).is_equal_approx(
		direction,
		Vector3.ONE * HAIR,
	)
	assert_float(plan.state.dash_direction.length()).is_equal_approx(1.0, HAIR)
	assert_float(plan.state.dash_direction.y).is_equal(0.0)
	assert_int(plan.state.stamina_spent_tick).override_failure_message("cost not paid now") \
			.is_equal(press_tick)
	_assert_slot(plan.state, FighterCommand.NONE, FighterState.NEVER)
	_assert_dash_tick(rig, plan, direction, true)


# Any tick of the dash: the mode DASH and the horizontal velocity direction * dash_speed; on
# the floor the vertical is 0 (TASK-10.4 plan).
func _assert_dash_tick(
	rig: MovementRig,
	plan: MovePlan,
	direction: Vector3,
	on_floor: bool,
) -> void:
	assert_int(plan.state.mode).override_failure_message("not in DASH").is_equal(
		FighterState.Mode.DASH
	)
	var expected := direction * rig.config.dash_speed
	var message := "horizontal velocity %s, expected %s" % [_horizontal(plan.velocity), expected]
	assert_vector(_horizontal(plan.velocity)).override_failure_message(message).is_equal_approx(
		expected,
		Vector3.ONE * HAIR,
	)
	if on_floor:
		assert_float(plan.velocity.y).override_failure_message("vertical on the floor").is_equal(
			0.0
		)


# The exit tick: the horizontal set to direction * dash_exit_speed, the mode back by contact
# (GROUND on the floor, AIR otherwise) since this tick, and the stamp kept for the cooldown.
func _assert_dash_exit(
	rig: MovementRig,
	record: DashRecord,
	direction: Vector3,
	mode: FighterState.Mode,
) -> void:
	var plan := record.exit_plan
	assert_int(plan.state.mode).override_failure_message("still in DASH at the exit tick") \
			.is_equal(mode)
	assert_int(plan.state.mode_since).is_equal(record.exit_tick)
	assert_int(plan.state.dash_tick).is_equal(record.press_tick)
	var expected := direction * rig.config.dash_exit_speed
	var message := "exit velocity %s, expected %s" % [_horizontal(plan.velocity), expected]
	assert_vector(_horizontal(plan.velocity)).override_failure_message(message).is_equal_approx(
		expected,
		Vector3.ONE * HAIR,
	)


func _assert_distance(record: DashRecord, direction: Vector3, distance_m: float) -> void:
	var moved := record.horizontal_displacement()
	var message := "moved %s (%.4f m), the design says %.2f m along %s within %.2f m" % [
		moved,
		moved.length(),
		distance_m,
		direction,
		DISTANCE_TOLERANCE_M,
	]
	assert_vector(moved).override_failure_message(message).is_equal_approx(
		direction * distance_m,
		Vector3.ONE * DISTANCE_TOLERANCE_M,
	)


func _assert_no_dash(plan: MovePlan, dash_tick: int) -> void:
	assert_int(plan.state.mode).override_failure_message("dashed").is_not_equal(
		FighterState.Mode.DASH
	)
	assert_int(plan.state.dash_tick).is_equal(dash_tick)


func _assert_full_jump(rig: MovementRig, plan: MovePlan) -> void:
	assert_float(plan.velocity.y).override_failure_message("not the full jump") \
			.is_equal_approx(rig.config.jump_speed, HAIR)
	assert_int(plan.state.jumps_used).is_equal(1)
	_assert_slot(plan.state, FighterCommand.NONE, FighterState.NEVER)


# None: a fresh state has no dash, the mode and the command exist under the agreed names, and a
# fresh input presses nothing (TASK-10.4 plan).
func test_a_fresh_state_has_no_dash_and_a_fresh_input_presses_none() -> void:
	var state := FighterState.new()
	assert_int(state.dash_tick).is_equal(FighterState.NEVER)
	assert_vector(state.dash_direction).is_equal(Vector3.ZERO)
	assert_int(state.mode).is_equal(FighterState.Mode.GROUND)
	assert_int(FighterState.Mode.DASH).is_equal(2)
	assert_int(FighterState.Mode.DASH).is_not_equal(FighterState.Mode.GROUND)
	assert_int(FighterState.Mode.DASH).is_not_equal(FighterState.Mode.AIR)
	assert_str(String(FighterCommand.DASH)).is_equal("dash")
	assert_bool(TickInput.new().dash).is_false()
	assert_bool(MovementRig.idle().dash).is_false()
	assert_bool(MovementRig.press_jump().dash).is_false()
	assert_bool(MovementRig.press_dash().dash).is_true()
	assert_bool(MovementRig.press_dash().jump).is_false()


# The hand numbers above against the config they must match (movement_v0.tres at load): the
# two times become ticks by the rule of Ticks.from_ms, within half a tick, and the speed is the
# distance over those ticks (DEC-0004, rule 3; TASK-10.4 plan).
func test_the_config_carries_the_dash_numbers_of_the_design(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var config := MovementRig.load_config(tickrate)
	assert_int(config.dash_ticks).is_equal(DASH_TICKS[tickrate])
	assert_int(config.dash_ticks).is_equal(Ticks.from_ms(DASH_MS, tickrate))
	assert_int(absi(config.dash_ticks * 1000 - DASH_MS * tickrate)).is_less_equal(
		HALF_TICK_IN_MS_TIMES_RATE
	)
	assert_int(config.dash_cooldown_ticks).is_equal(COOLDOWN_TICKS[tickrate])
	assert_int(config.dash_cooldown_ticks).is_equal(Ticks.from_ms(DASH_COOLDOWN_MS, tickrate))
	assert_int(absi(config.dash_cooldown_ticks * 1000 - DASH_COOLDOWN_MS * tickrate)) \
			.is_less_equal(HALF_TICK_IN_MS_TIMES_RATE)
	assert_float(config.dash_speed).is_equal_approx(DASH_SPEED_MPS, HAIR)
	assert_float(config.dash_speed).is_equal_approx(
		DASH_DISTANCE_M * tickrate / config.dash_ticks,
		HAIR,
	)
	assert_float(config.dash_exit_speed).is_equal_approx(DASH_EXIT_SPEED_MPS, HAIR)
	assert_float(config.dash_exit_speed).is_equal_approx(config.run_speed, HAIR)
	assert_float(config.dash_cost).is_equal_approx(DASH_COST, HAIR)
	assert_float(config.stamina_max).is_equal_approx(STAMINA_MAX, HAIR)
	assert_int(config.dash_ticks + config.dash_cooldown_ticks).is_equal(PERIOD_TICKS[tickrate])


func test_a_fighter_without_a_dash_press_never_dashes(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var violations: Array[String] = []
	for step: int in range(1, 2 * tickrate + 1):
		var input := MovementRig.run(FORWARD) if step % 2 == 0 else MovementRig.idle()
		var plan := rig.step(input)
		if plan.state.mode == FighterState.Mode.DASH or plan.state.dash_tick != FighterState.NEVER:
			violations.append("step %d: dashed" % step)
	assert_array(violations).is_empty()
	assert_float(rig.stamina()).is_equal_approx(rig.config.stamina_max, HAIR)
	assert_int(rig.state.stamina_spent_tick).is_equal(FighterState.NEVER)


# The two dash fields travel with copy(): a field left out would come back as its default after
# a rollback (visao-geral.md).
func test_fighter_state_copy_carries_the_dash_fields() -> void:
	var original := _rig(60).state
	original.mode = FighterState.Mode.DASH
	original.dash_tick = 1234
	original.dash_direction = Vector3(0.6, 0.0, -0.8)
	var copy := original.copy()
	assert_int(copy.mode).is_equal(FighterState.Mode.DASH)
	assert_int(copy.dash_tick).is_equal(1234)
	assert_vector(copy.dash_direction).is_equal(Vector3(0.6, 0.0, -0.8))
	copy.dash_tick = FighterState.NEVER
	copy.dash_direction = Vector3.ZERO
	copy.mode = FighterState.Mode.GROUND
	assert_int(original.dash_tick).is_equal(1234)
	assert_vector(original.dash_direction).is_equal(Vector3(0.6, 0.0, -0.8))
	assert_int(original.mode).is_equal(FighterState.Mode.DASH)


# The slice is pure: the dash starts in the copy, never in the state received (DEC-0004, rule 1).
func test_before_move_leaves_the_state_it_receives_untouched_when_the_dash_starts() -> void:
	var rig := _rig(60)
	var given := rig.state
	var plan := Movement.before_move(
		given,
		Vector3.ZERO,
		Vector3.ZERO,
		MovementRig.press_dash_toward(FORWARD),
		rig.config,
		FIRST_TICK,
	)
	assert_int(plan.state.mode).is_equal(FighterState.Mode.DASH)
	assert_int(given.mode).is_equal(FighterState.Mode.GROUND)
	assert_int(given.dash_tick).is_equal(FighterState.NEVER)
	assert_vector(given.dash_direction).is_equal(Vector3.ZERO)
	assert_int(given.stamina_spent_tick).is_equal(FighterState.NEVER)
	assert_str(String(given.buffered_command)).is_equal(String(FighterCommand.NONE))


# Criterion 1: on the floor, with the cooldown free and the bar full, the dash covers 4 m in
# 200 ms within 1 cm: 12 ticks at 60 and 6 at 30, every one of them in DASH at 20 m/s with the
# vertical at 0, the press tick included; the tick after is no longer a dash (movimento.md,
# "Dash": "Distância", "Duração").
func test_a_dash_on_the_floor_covers_4_m_in_200_ms_within_1_cm(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var direction := _world_direction(FORWARD, 0.0)
	var record := _dash(rig, MovementRig.press_dash_toward(FORWARD))
	_assert_dash_started(rig, record.plans[0], record.press_tick, direction)
	var first_step := record.positions[0] - record.start
	assert_vector(first_step).override_failure_message("the press tick must already move") \
			.is_equal_approx(direction * rig.config.dash_speed / tickrate, Vector3.ONE * HAIR)
	for plan: MovePlan in record.plans:
		_assert_dash_tick(rig, plan, direction, true)
	for on_floor: bool in record.on_floor:
		assert_bool(on_floor).override_failure_message("left the floor on the flat").is_true()
	assert_int(record.dash_mode_ticks()).is_equal(DASH_TICKS[tickrate])
	_assert_distance(record, direction, DASH_DISTANCE_M)
	assert_int(record.exit_plan.state.mode).is_not_equal(FighterState.Mode.DASH)


# At the end the fighter leaves at 7 m/s in the same direction, back on the ground by contact
# since the exit tick, and then stops by the ground rule, 100 ms without input (movimento.md,
# "Dash": "Velocidade na saída"; "Chão": "Tempo até parar").
func test_the_dash_exits_at_7_mps_in_the_same_direction(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var direction := _world_direction(FORWARD, 0.0)
	var record := _dash(rig, MovementRig.press_dash_toward(FORWARD))
	_assert_dash_exit(rig, record, direction, FighterState.Mode.GROUND)
	assert_float(record.exit_plan.velocity.y).is_equal(0.0)
	assert_float(record.exit_plan.velocity.length()).is_equal_approx(DASH_EXIT_SPEED_MPS, HAIR)
	assert_bool(rig.state.on_floor).is_true()
	rig.rest(rig.config.stop_ticks)
	assert_float(rig.horizontal_speed()).override_failure_message("still moving after the stop") \
			.is_less_equal(HAIR)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GROUND)


# The direction is the one pointed, relative to the camera (movimento.md, "Dash": "Direção"):
# right at yaw 0 (+X), forward at a quarter turn left (-X), back at yaw 0 (+Z), and a short
# diagonal, which only gives a direction: the dash is the full 4 m whatever the stick's length.
func test_the_dash_goes_where_the_player_points_relative_to_the_camera(
	tickrate: int,
	move: Vector2,
	yaw: float,
	_test_parameters := [
		[30, RIGHT, 0.0],
		[60, RIGHT, 0.0],
		[30, FORWARD, PI / 2],
		[60, FORWARD, PI / 2],
		[60, Vector2(0, -1), 0.0],
		[60, Vector2(0.5, 0.5), 0.0],
	],
) -> void:
	var rig := _rig(tickrate)
	var direction := _world_direction(move, yaw)
	var record := _dash(rig, MovementRig.press_dash_toward(move, yaw))
	_assert_dash_started(rig, record.plans[0], record.press_tick, direction)
	for plan: MovePlan in record.plans:
		_assert_dash_tick(rig, plan, direction, true)
	_assert_distance(record, direction, DASH_DISTANCE_M)
	_assert_dash_exit(rig, record, direction, FighterState.Mode.GROUND)


# Without a direction, the dash goes where the body looks: the camera's yaw, turned a few ticks
# before the press (movimento.md, "Dash": "Sem direção apontada, para onde o corpo olha";
# "Princípios": the body looks where the camera looks).
func test_without_a_direction_the_dash_goes_where_the_body_looks(
	tickrate: int,
	yaw: float,
	_test_parameters := [[30, 0.0], [60, 0.0], [30, PI / 2], [60, PI / 2], [60, -PI / 4]],
) -> void:
	var rig := _rig(tickrate)
	for _step: int in 3:
		rig.step(MovementRig.run(Vector2.ZERO, yaw))
	assert_float(rig.state.facing_yaw).is_equal(yaw)
	var direction := _facing(yaw)
	var record := _dash(rig, MovementRig.press_dash_toward(Vector2.ZERO, yaw))
	_assert_dash_started(rig, record.plans[0], record.press_tick, direction)
	_assert_distance(record, direction, DASH_DISTANCE_M)
	_assert_dash_exit(rig, record, direction, FighterState.Mode.GROUND)


# From a run at 7 m/s forward, a dash to the right is 20 m/s to the right on the press tick: the
# run speed is replaced, not added (movimento.md, "Dash": "Deriva a velocidade: 20 m/s").
func test_the_dash_replaces_the_run_speed_on_the_press_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	for _step: int in tickrate:
		rig.step(MovementRig.run(FORWARD))
	assert_float(rig.horizontal_speed()).is_equal_approx(rig.config.run_speed, HAIR)
	var direction := _world_direction(RIGHT, 0.0)
	var record := _dash(rig, MovementRig.press_dash_toward(RIGHT))
	_assert_dash_started(rig, record.plans[0], record.press_tick, direction)
	assert_vector(record.plans[0].velocity).is_equal_approx(
		direction * DASH_SPEED_MPS,
		Vector3.ONE * HAIR,
	)
	_assert_distance(record, direction, DASH_DISTANCE_M)
	_assert_dash_exit(rig, record, direction, FighterState.Mode.GROUND)


# Criterion 2: the dash costs 15, stamped on its start, and nothing more during it
# (movimento.md, "Dash": "Custo"; "Stamina": "Como se guarda").
func test_the_dash_costs_15_stamina_at_the_start(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var record := _dash(rig, MovementRig.press_dash_toward(FORWARD))
	var after_cost := rig.config.stamina_max - rig.config.dash_cost
	assert_float(rig.config.dash_cost).is_equal_approx(DASH_COST, HAIR)
	for plan: MovePlan in record.plans:
		assert_int(plan.state.stamina_spent_tick).is_equal(record.press_tick)
		assert_float(plan.state.stamina_at_spend).is_equal_approx(after_cost, HAIR)
	assert_int(record.exit_plan.state.stamina_spent_tick).is_equal(record.press_tick)
	assert_float(Stamina.at(rig.state, rig.config, record.exit_tick)).is_equal_approx(
		after_cost,
		HAIR,
	)


# Many: with the key held every tick, the dashes come exactly dash_ticks + cooldown_ticks apart,
# 36 ticks at 60 and 18 at 30 (the cooldown counts from the end: movimento.md, "Dash":
# "Recarga"), each one dash_ticks long and 15 points cheaper; nothing regains in between.
func test_the_next_dash_fires_only_400_ms_after_the_end(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var starts: Array[int] = []
	var dash_ticks := 0
	var last_stamp := FighterState.NEVER
	for _step: int in 2 * PERIOD_TICKS[tickrate] + DASH_TICKS[tickrate]:
		var tick := rig.tick
		var plan := rig.step(MovementRig.press_dash_toward(FORWARD))
		if plan.state.dash_tick != last_stamp:
			starts.append(tick)
			last_stamp = plan.state.dash_tick
			assert_int(plan.state.dash_tick).is_equal(tick)
		if plan.state.mode == FighterState.Mode.DASH:
			dash_ticks += 1
	var expected: Array[int] = [
		FIRST_TICK,
		FIRST_TICK + PERIOD_TICKS[tickrate],
		FIRST_TICK + 2 * PERIOD_TICKS[tickrate],
	]
	var message := "dashes at %s, expected %s" % [starts, expected]
	assert_array(starts).override_failure_message(message).is_equal(expected)
	assert_int(dash_ticks).is_equal(3 * DASH_TICKS[tickrate])
	assert_float(rig.stamina()).is_equal_approx(rig.config.stamina_max - 3 * DASH_COST, HAIR)


# A press in the cooldown waits in the slot and fires on the first legal tick: one tick before
# it, and at the limit of the 150 ms window, 9 ticks at 60 and 5 at 30 (movimento.md, "Perdão";
# DEC-0039).
func test_a_press_in_the_cooldown_waits_in_the_slot_and_fires_on_the_first_legal_tick(
	tickrate: int,
	ticks_before: int,
	_test_parameters := [[30, 1], [30, 5], [60, 1], [60, 9]],
) -> void:
	var rig := _rig(tickrate)
	var first := _dash(rig, MovementRig.press_dash_toward(FORWARD))
	var legal_tick := first.press_tick + PERIOD_TICKS[tickrate]
	var press_tick := legal_tick - ticks_before
	assert_int(press_tick).is_greater(first.exit_tick)
	_idle_until_with_press(rig, legal_tick, press_tick, MovementRig.press_dash(), first.press_tick)
	_assert_slot(rig.state, FighterCommand.DASH, press_tick)
	var plan := rig.step(MovementRig.idle())
	_assert_dash_started(rig, plan, legal_tick, _world_direction(FORWARD, 0.0))
	assert_float(plan.state.stamina_at_spend).is_equal_approx(
		rig.config.stamina_max - 2 * DASH_COST,
		HAIR,
	)


func test_a_press_one_tick_past_the_buffer_before_the_cooldown_ends_does_not_fire(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var first := _dash(rig, MovementRig.press_dash_toward(FORWARD))
	var legal_tick := first.press_tick + PERIOD_TICKS[tickrate]
	var press_tick := legal_tick - BUFFER_TICKS[tickrate] - 1
	assert_int(press_tick).is_greater(first.exit_tick)
	_idle_until_with_press(rig, legal_tick, press_tick, MovementRig.press_dash(), first.press_tick)
	_assert_no_dash(rig.step(MovementRig.idle()), first.press_tick)
	rig.rest(2 * BUFFER_TICKS[tickrate])
	_assert_no_dash(rig.last_plan, first.press_tick)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GROUND)
	assert_float(rig.state.stamina_at_spend).is_equal_approx(
		rig.config.stamina_max - DASH_COST,
		HAIR,
	)


# A dash pressed during the dash takes the slot, is still in the cooldown when its window
# closes, and never chains a second dash.
func test_a_press_during_the_dash_does_not_chain_a_second_dash(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var direction := _world_direction(FORWARD, 0.0)
	@warning_ignore("integer_division")
	var press_tick := FIRST_TICK + DASH_TICKS[tickrate] / 2
	var during: Array[TickInput] = []
	for step: int in range(1, DASH_TICKS[tickrate] + 1):
		var pressed := FIRST_TICK + step == press_tick
		during.append(MovementRig.press_dash_toward(FORWARD) if pressed else MovementRig.idle())
	var record := _dash(rig, MovementRig.press_dash_toward(FORWARD), during)
	_assert_slot(record.plans[DASH_TICKS[tickrate] - 1].state, FighterCommand.DASH, press_tick)
	for plan: MovePlan in record.plans:
		_assert_dash_tick(rig, plan, direction, true)
		assert_int(plan.state.dash_tick).is_equal(FIRST_TICK)
	_assert_dash_exit(rig, record, direction, FighterState.Mode.GROUND)
	rig.rest(PERIOD_TICKS[tickrate] + BUFFER_TICKS[tickrate])
	_assert_no_dash(rig.last_plan, FIRST_TICK)
	assert_float(rig.state.stamina_at_spend).is_equal_approx(
		rig.config.stamina_max - DASH_COST,
		HAIR,
	)


# Failure: with 14.5 the dash does not fire, nothing is paid and the press waits in the slot;
# the bar regains nothing inside the window (the wait is 800 ms), so it never fires
# (movimento.md, "Stamina": "Sem stamina suficiente").
func test_with_14_5_stamina_the_dash_is_refused_and_nothing_is_paid(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.rest(2)
	rig.state.stamina_at_spend = BELOW_COST
	rig.state.stamina_spent_tick = rig.tick
	var stamp := rig.state.stamina_spent_tick
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_dash())
	_assert_no_dash(plan, FighterState.NEVER)
	assert_int(plan.state.mode).is_equal(FighterState.Mode.GROUND)
	assert_vector(plan.velocity).override_failure_message("moved on a refused dash").is_equal(
		Vector3.ZERO
	)
	assert_float(plan.state.stamina_at_spend).is_equal_approx(BELOW_COST, HAIR)
	assert_int(plan.state.stamina_spent_tick).is_equal(stamp)
	_assert_slot(plan.state, FighterCommand.DASH, press_tick)
	rig.rest(2 * BUFFER_TICKS[tickrate])
	_assert_no_dash(rig.last_plan, FighterState.NEVER)
	assert_vector(rig.position).is_equal(Vector3.ZERO)
	assert_float(rig.state.stamina_at_spend).is_equal_approx(BELOW_COST, HAIR)


# Limit: exactly 15 fires and leaves the bar at 0.
func test_with_exactly_15_stamina_the_dash_fires_and_leaves_0(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.state.stamina_at_spend = DASH_COST
	rig.state.stamina_spent_tick = rig.tick
	var record := _dash(rig, MovementRig.press_dash_toward(FORWARD))
	_assert_dash_started(rig, record.plans[0], record.press_tick, _world_direction(FORWARD, 0.0))
	assert_float(record.plans[0].state.stamina_at_spend).is_equal_approx(0.0, HAIR)
	_assert_distance(record, _world_direction(FORWARD, 0.0), DASH_DISTANCE_M)


# A press without stamina waits in the slot and fires on the first tick the bar can pay: the
# bar left at 14.5 reaches 15 on the first tick after the 800 ms wait (0.5 per tick at 60, 1.0
# at 30; movimento.md, "Stamina"), one tick and the full window after the press.
func test_a_press_without_stamina_waits_in_the_slot_and_fires_when_the_bar_reaches_15(
	tickrate: int,
	ticks_before: int,
	_test_parameters := [[30, 1], [30, 5], [60, 1], [60, 9]],
) -> void:
	var rig := _rig(tickrate)
	rig.rest(2)
	var press_tick := rig.tick
	var legal_tick := press_tick + ticks_before
	rig.state.stamina_at_spend = BELOW_COST
	rig.state.stamina_spent_tick = legal_tick - STAMINA_WAIT_TICKS[tickrate] - 1
	assert_int(rig.config.stamina_wait_ticks).is_equal(STAMINA_WAIT_TICKS[tickrate])
	assert_float(Stamina.at(rig.state, rig.config, legal_tick - 1)).is_less(DASH_COST)
	assert_float(Stamina.at(rig.state, rig.config, legal_tick)).is_equal_approx(
		BELOW_COST + REGEN_PER_TICK[tickrate],
		HAIR,
	)
	_idle_until_with_press(
		rig,
		legal_tick,
		press_tick,
		MovementRig.press_dash(),
		FighterState.NEVER,
	)
	_assert_slot(rig.state, FighterCommand.DASH, press_tick)
	assert_vector(rig.position).override_failure_message("moved while refused").is_equal(
		Vector3.ZERO
	)
	var plan := rig.step(MovementRig.idle())
	_assert_dash_started(rig, plan, legal_tick, _world_direction(FORWARD, 0.0))
	assert_float(plan.state.stamina_at_spend).is_equal_approx(
		BELOW_COST + REGEN_PER_TICK[tickrate] - DASH_COST,
		HAIR,
	)


func test_a_press_without_stamina_one_tick_past_the_buffer_does_not_fire(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.rest(2)
	var press_tick := rig.tick
	var legal_tick := press_tick + BUFFER_TICKS[tickrate] + 1
	rig.state.stamina_at_spend = BELOW_COST
	rig.state.stamina_spent_tick = legal_tick - STAMINA_WAIT_TICKS[tickrate] - 1
	_idle_until_with_press(
		rig,
		legal_tick,
		press_tick,
		MovementRig.press_dash(),
		FighterState.NEVER,
	)
	_assert_no_dash(rig.step(MovementRig.idle()), FighterState.NEVER)
	rig.rest(2 * BUFFER_TICKS[tickrate])
	_assert_no_dash(rig.last_plan, FighterState.NEVER)
	assert_vector(rig.position).is_equal(Vector3.ZERO)
	assert_float(rig.state.stamina_at_spend).is_equal_approx(BELOW_COST, HAIR)


# A press in the air does not dash there (movimento.md, "Dash": "Onde: só no chão") and pays
# nothing: it waits in the slot and dashes on the first tick that starts on the floor, pressed
# at the limit of the window before the landing or on the landing tick itself.
func test_a_press_in_the_air_waits_in_the_slot_and_dashes_on_the_first_tick_on_the_floor(
	tickrate: int,
	ticks_before_the_first_floor_tick: int,
	_test_parameters := [[30, 1], [30, 5], [60, 1], [60, 9]],
) -> void:
	var landing_tick := _landing_tick_of_a_jump(tickrate)
	var rig := _rig(tickrate)
	rig.step(MovementRig.press_jump())
	var first_floor_tick := landing_tick + 1
	var press_tick := first_floor_tick - ticks_before_the_first_floor_tick
	assert_int(press_tick).is_greater(FIRST_TICK)
	_idle_until_with_press(
		rig,
		first_floor_tick,
		press_tick,
		MovementRig.press_dash(),
		FighterState.NEVER,
	)
	assert_bool(rig.state.on_floor).override_failure_message("not landed yet").is_true()
	assert_int(rig.state.jumps_used).is_equal(0)
	assert_int(rig.state.stamina_spent_tick).override_failure_message("paid in the air") \
			.is_equal(FighterState.NEVER)
	_assert_slot(rig.state, FighterCommand.DASH, press_tick)
	var record := _dash(rig, MovementRig.idle())
	_assert_dash_started(rig, record.plans[0], first_floor_tick, _world_direction(FORWARD, 0.0))
	_assert_distance(record, _world_direction(FORWARD, 0.0), DASH_DISTANCE_M)


func test_a_press_in_the_air_one_tick_past_the_buffer_does_not_dash_on_landing(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var landing_tick := _landing_tick_of_a_jump(tickrate)
	var rig := _rig(tickrate)
	rig.step(MovementRig.press_jump())
	var first_floor_tick := landing_tick + 1
	var press_tick := first_floor_tick - BUFFER_TICKS[tickrate] - 1
	_idle_until_with_press(
		rig,
		first_floor_tick,
		press_tick,
		MovementRig.press_dash(),
		FighterState.NEVER,
	)
	assert_bool(rig.state.on_floor).is_true()
	_assert_no_dash(rig.step(MovementRig.idle()), FighterState.NEVER)
	rig.rest(2 * BUFFER_TICKS[tickrate])
	_assert_no_dash(rig.last_plan, FighterState.NEVER)
	assert_int(rig.state.stamina_spent_tick).is_equal(FighterState.NEVER)


# Off a ledge without jumping, the coyote forgives the jump, not the dash: a press inside the
# coyote window does not dash (movimento.md, "Dash": "Onde: só no chão"; "Perdão").
func test_a_press_in_the_coyote_window_does_not_dash(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.rest(3)
	rig.floor_on = false
	rig.step(MovementRig.idle())
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_dash())
	_assert_no_dash(plan, FighterState.NEVER)
	assert_int(plan.state.mode).is_equal(FighterState.Mode.AIR)
	_assert_slot(plan.state, FighterCommand.DASH, press_tick)
	assert_int(plan.state.stamina_spent_tick).is_equal(FighterState.NEVER)
	rig.rest(2 * BUFFER_TICKS[tickrate])
	_assert_no_dash(rig.last_plan, FighterState.NEVER)
	assert_float(rig.horizontal_speed()).is_less_equal(HAIR)


# Criterion 3: the direction input changes nothing during the dash, nor does the camera: the
# body follows the same path as with no input at all, and the direction stays the one fixed at
# the start (movimento.md, "Dash": "fixada no início, e o input de direção não muda nada").
func test_the_direction_input_changes_nothing_during_the_dash(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var quiet := _rig(tickrate)
	var noisy := _rig(tickrate)
	var direction := _world_direction(FORWARD, 0.0)
	var noise: Array[TickInput] = [
		MovementRig.run(Vector2(-1, 0), PI),
		MovementRig.run(Vector2(0, -1), PI / 2),
		MovementRig.run(Vector2(1, 1), 0.3),
	]
	var during: Array[TickInput] = []
	for step: int in range(1, DASH_TICKS[tickrate]):
		during.append(noise[step % noise.size()])
	during.append(MovementRig.idle())
	var expected := _dash(quiet, MovementRig.press_dash_toward(FORWARD))
	var record := _dash(noisy, MovementRig.press_dash_toward(FORWARD), during)
	for index: int in record.plans.size():
		var message := "tick %d of the dash moved differently with input" % index
		assert_vector(record.positions[index]).override_failure_message(message).is_equal_approx(
			expected.positions[index],
			Vector3.ONE * HAIR,
		)
		assert_vector(record.plans[index].velocity).is_equal_approx(
			expected.plans[index].velocity,
			Vector3.ONE * HAIR,
		)
		assert_vector(record.plans[index].state.dash_direction).is_equal_approx(
			direction,
			Vector3.ONE * HAIR,
		)
	_assert_distance(record, direction, DASH_DISTANCE_M)
	_assert_dash_exit(noisy, record, direction, FighterState.Mode.GROUND)
	assert_vector(record.exit_plan.velocity).is_equal_approx(
		expected.exit_plan.velocity,
		Vector3.ONE * HAIR,
	)


# A jump pressed during the dash does not cut it: the dash runs its 4 m, the press waits in the
# slot, and the full jump leaves on the exit tick, the first after the end, with the exit speed
# as its horizontal, while tick - press <= buffer_ticks. Pressed at the limit (9 ticks before
# the exit at 60, 5 at 30) and on the last tick of the dash (movimento.md, "Dash":
# "Comprometido"; F-121; DEC-0041).
func test_a_jump_pressed_during_the_dash_fires_on_the_first_tick_after_the_end(
	tickrate: int,
	press_offset: int,
	_test_parameters := [[30, 1], [30, 5], [60, 3], [60, 11]],
) -> void:
	var rig := _rig(tickrate)
	var direction := _world_direction(FORWARD, 0.0)
	var press_tick := FIRST_TICK + press_offset
	var exit_tick := FIRST_TICK + DASH_TICKS[tickrate]
	assert_int(exit_tick - press_tick).is_less_equal(BUFFER_TICKS[tickrate])
	var during: Array[TickInput] = []
	for step: int in range(1, DASH_TICKS[tickrate] + 1):
		during.append(MovementRig.press_jump() if step == press_offset else MovementRig.idle())
	var record := _dash(rig, MovementRig.press_dash_toward(FORWARD), during)
	for index: int in record.plans.size():
		var plan := record.plans[index]
		_assert_dash_tick(rig, plan, direction, true)
		assert_int(plan.state.jumps_used).override_failure_message("jumped inside the dash") \
				.is_equal(0)
		if index >= press_offset:
			_assert_slot(plan.state, FighterCommand.JUMP, press_tick)
	assert_int(record.dash_mode_ticks()).is_equal(DASH_TICKS[tickrate])
	_assert_distance(record, direction, DASH_DISTANCE_M)
	assert_int(record.exit_tick).is_equal(exit_tick)
	_assert_full_jump(rig, record.exit_plan)
	assert_vector(_horizontal(record.exit_plan.velocity)).is_equal_approx(
		direction * rig.config.dash_exit_speed,
		Vector3.ONE * HAIR,
	)
	assert_int(record.exit_plan.state.dash_tick).is_equal(FIRST_TICK)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	assert_int(rig.state.mode_since).is_equal(exit_tick)
	assert_bool(rig.state.on_floor).is_false()


# One tick past the window the jump stays in the slot too long: at 60 the dash lasts 12 ticks
# and the window 9, so a press 2 ticks in is 10 ticks old at the exit and does not fire. At 30
# the dash is shorter than the window plus one: every press inside it fires.
func test_a_jump_pressed_during_the_dash_one_tick_past_the_buffer_does_not_fire_at_the_end(
	tickrate: int,
	press_offset: int,
	_test_parameters := [[60, 2]],
) -> void:
	var rig := _rig(tickrate)
	var direction := _world_direction(FORWARD, 0.0)
	assert_int(DASH_TICKS[tickrate] - press_offset).is_equal(BUFFER_TICKS[tickrate] + 1)
	var during: Array[TickInput] = []
	for step: int in range(1, DASH_TICKS[tickrate] + 1):
		during.append(MovementRig.press_jump() if step == press_offset else MovementRig.idle())
	var record := _dash(rig, MovementRig.press_dash_toward(FORWARD), during)
	_assert_distance(record, direction, DASH_DISTANCE_M)
	_assert_dash_exit(rig, record, direction, FighterState.Mode.GROUND)
	assert_float(record.exit_plan.velocity.y).override_failure_message("jumped late").is_equal(0.0)
	assert_int(record.exit_plan.state.jumps_used).is_equal(0)
	rig.rest(2 * BUFFER_TICKS[tickrate])
	assert_int(rig.state.jumps_used).is_equal(0)
	assert_bool(rig.state.on_floor).is_true()


# The tie: jump and dash on the same tick, on the floor, is the jump; the dash is lost, nothing
# is paid, and no dash comes out on the landing (movimento.md, "Perdão": "No mesmo tick, o pulo
# vence o dash"; DEC-0039 §4; DEC-0041 §4).
func test_when_jump_and_dash_arrive_on_the_same_tick_the_jump_wins(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var plan := rig.step(MovementRig.press_jump_and_dash(FORWARD))
	_assert_full_jump(rig, plan)
	_assert_no_dash(plan, FighterState.NEVER)
	assert_int(plan.state.mode).is_not_equal(FighterState.Mode.DASH)
	assert_int(plan.state.stamina_spent_tick).override_failure_message("the dash was paid") \
			.is_equal(FighterState.NEVER)
	assert_float(rig.stamina()).is_equal_approx(rig.config.stamina_max, HAIR)
	_idle_until_landed(rig)
	rig.rest(2 * BUFFER_TICKS[tickrate])
	_assert_no_dash(rig.last_plan, FighterState.NEVER)
	assert_int(rig.state.stamina_spent_tick).is_equal(FighterState.NEVER)


# The tie inside the slot: both pressed in the air with the double jump spent, the slot keeps
# the jump (the presses are written dash first, jump last: TASK-10.4 plan), and on the first
# tick on the floor the jump fires, not the dash.
func test_when_jump_and_dash_wait_in_the_slot_together_the_slot_keeps_the_jump(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var landing_tick := _landing_tick_with_the_double_jump_spent(tickrate)
	var rig := _rig(tickrate)
	rig.step(MovementRig.press_jump())
	_spend_double_jump(rig)
	var after_double_jump := rig.state.stamina_at_spend
	var double_jump_tick := rig.state.stamina_spent_tick
	var first_floor_tick := landing_tick + 1
	var press_tick := first_floor_tick - BUFFER_TICKS[tickrate]
	assert_int(press_tick).is_greater(rig.tick)
	while rig.tick < first_floor_tick:
		var input := (
			MovementRig.press_jump_and_dash(FORWARD)
			if rig.tick == press_tick
			else MovementRig.idle()
		)
		var plan := rig.step(input)
		if rig.tick > press_tick:
			_assert_slot(plan.state, FighterCommand.JUMP, press_tick)
	assert_bool(rig.state.on_floor).is_true()
	var plan := rig.step(MovementRig.idle())
	_assert_full_jump(rig, plan)
	_assert_no_dash(plan, FighterState.NEVER)
	assert_float(plan.state.stamina_at_spend).is_equal_approx(after_double_jump, HAIR)
	assert_int(plan.state.stamina_spent_tick).is_equal(double_jump_tick)


# A later press replaces the stored one (one slot, DEC-0039): a jump then a dash pressed during
# the dash leaves a dash in the slot, which is in the cooldown at the end, so nothing fires; a
# dash then a jump leaves the jump, which fires at the end.
func test_a_later_press_during_the_dash_replaces_the_stored_one(
	tickrate: int,
	first: StringName,
	_test_parameters := [
		[30, FighterCommand.JUMP],
		[60, FighterCommand.JUMP],
		[30, FighterCommand.DASH],
		[60, FighterCommand.DASH],
	],
) -> void:
	var rig := _rig(tickrate)
	var direction := _world_direction(FORWARD, 0.0)
	var dash_ticks := DASH_TICKS[tickrate]
	var first_offset := dash_ticks - 2
	var second_offset := dash_ticks - 1
	var second := _other_command(first)
	var during: Array[TickInput] = []
	for step: int in range(1, dash_ticks + 1):
		if step == first_offset:
			during.append(_press_of(first))
		elif step == second_offset:
			during.append(_press_of(second))
		else:
			during.append(MovementRig.idle())
	var record := _dash(rig, MovementRig.press_dash_toward(FORWARD), during)
	_assert_slot(record.plans[first_offset].state, first, FIRST_TICK + first_offset)
	_assert_slot(record.plans[second_offset].state, second, FIRST_TICK + second_offset)
	_assert_distance(record, direction, DASH_DISTANCE_M)
	assert_int(record.exit_plan.state.dash_tick).is_equal(FIRST_TICK)
	if second == FighterCommand.JUMP:
		_assert_full_jump(rig, record.exit_plan)
	else:
		assert_float(record.exit_plan.velocity.y).override_failure_message("jumped").is_equal(0.0)
		assert_int(record.exit_plan.state.jumps_used).is_equal(0)
		assert_int(record.exit_plan.state.mode).is_equal(FighterState.Mode.GROUND)
		_assert_slot(record.exit_plan.state, FighterCommand.DASH, FIRST_TICK + second_offset)


func _other_command(command: StringName) -> StringName:
	if command == FighterCommand.JUMP:
		return FighterCommand.DASH
	return FighterCommand.JUMP


func _press_of(command: StringName) -> TickInput:
	if command == FighterCommand.JUMP:
		return MovementRig.press_jump()
	return MovementRig.press_dash()


# Criterion 4, the ledge: the floor goes away halfway through the dash and the dash runs to the
# end of its ticks, at 20 m/s horizontally with gravity pulling from the first tick off the
# floor, the mode DASH throughout (the contact does not end it: DEC-0041 §3); at the exit the
# fighter is in the air at 7 m/s in the same direction (movimento.md, "Dash": "Saindo da
# beirada").
func test_a_dash_off_a_ledge_runs_to_the_end_with_gravity_and_exits_at_7_mps_in_the_air(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var direction := _world_direction(FORWARD, 0.0)
	var dash_ticks := DASH_TICKS[tickrate]
	@warning_ignore("integer_division")
	var floor_ticks := dash_ticks / 2
	var press_tick := rig.tick
	var record := DashRecord.new()
	record.press_tick = press_tick
	record.start = rig.position
	for step: int in dash_ticks:
		if step == floor_ticks:
			rig.floor_on = false
		var input := MovementRig.press_dash_toward(FORWARD) if step == 0 else MovementRig.idle()
		record.plans.append(rig.step(input))
		record.positions.append(rig.position)
		record.on_floor.append(rig.state.on_floor)
	record.exit_tick = rig.tick
	record.exit_plan = rig.step(MovementRig.idle())
	var ledge_tick := press_tick + floor_ticks
	_assert_dash_started(rig, record.plans[0], press_tick, direction)
	var previous_vertical := 0.0
	for index: int in record.plans.size():
		var plan := record.plans[index]
		var tick := press_tick + index
		_assert_dash_tick(rig, plan, direction, tick <= ledge_tick)
		assert_int(plan.state.dash_tick).is_equal(press_tick)
		assert_bool(record.on_floor[index]).is_equal(tick < ledge_tick)
		if tick > ledge_tick:
			var falling := "tick %d off the ledge: vertical %.4f after %.4f, no gravity" % [
				tick,
				plan.velocity.y,
				previous_vertical,
			]
			assert_float(plan.velocity.y).override_failure_message(falling).is_less(
				previous_vertical - HAIR
			)
			assert_float(record.positions[index].y).is_less(0.0)
		previous_vertical = plan.velocity.y
	assert_int(rig.state.left_floor_tick).is_equal(ledge_tick)
	assert_int(record.dash_mode_ticks()).is_equal(dash_ticks)
	_assert_distance(record, direction, DASH_DISTANCE_M)
	_assert_dash_exit(rig, record, direction, FighterState.Mode.AIR)
	assert_float(record.exit_plan.velocity.y).override_failure_message("stopped falling") \
			.is_less(previous_vertical - HAIR)
	assert_bool(record.exit_plan.state.on_floor).is_false()
	assert_int(record.exit_plan.state.jumps_used).is_equal(0)


# Criterion 4, the ramp: down the 45° ramp the fighter is on the floor on every tick of the
# dash, the vertical the core asks for is 0 and the body stays on the surface, 4 m along and
# 4 m down; at the exit it is on the ground at 7 m/s (movimento.md, "Dash": "Descendo a rampa
# de 45°"). The engine's snap is a fact here; the scene test of TASK-10.4 proves it.
func test_a_dash_down_the_45_degree_ramp_stays_on_the_floor_every_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.ramp_on = true
	rig.rest(3)
	assert_bool(rig.state.on_floor).override_failure_message("not at rest on the ramp").is_true()
	assert_vector(rig.position).is_equal(Vector3.ZERO)
	var direction := _world_direction(RIGHT, 0.0)
	var record := _dash(rig, MovementRig.press_dash_toward(RIGHT))
	_assert_dash_started(rig, record.plans[0], record.press_tick, direction)
	var air_ticks := 0
	for index: int in record.plans.size():
		var plan := record.plans[index]
		_assert_dash_tick(rig, plan, direction, true)
		assert_bool(plan.state.on_floor).is_true()
		if not record.on_floor[index]:
			air_ticks += 1
		var on_surface := "tick %d of the ramp dash at %s, off the surface" % [
			index,
			record.positions[index],
		]
		assert_float(record.positions[index].y).override_failure_message(on_surface) \
				.is_equal_approx(-record.positions[index].x, HAIR)
	assert_int(air_ticks).override_failure_message("%d ticks in the air on the ramp" % air_ticks) \
			.is_equal(0)
	assert_int(record.dash_mode_ticks()).is_equal(DASH_TICKS[tickrate])
	_assert_distance(record, direction, DASH_DISTANCE_M)
	assert_float(record.positions[record.positions.size() - 1].y).is_equal_approx(
		-DASH_DISTANCE_M,
		DISTANCE_TOLERANCE_M,
	)
	_assert_dash_exit(rig, record, direction, FighterState.Mode.GROUND)
	assert_bool(rig.state.on_floor).is_true()


# Criterion 4, the wall: a dash into a wall 1 m ahead keeps asking the engine for 20 m/s on
# every one of its ticks, the time runs to the end and the exit comes when it would have, with
# the cooldown counted from that same end (movimento.md, "Dash": "Contra uma parede").
func test_a_dash_into_a_wall_keeps_the_time_running(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.wall_x = WALL_X
	var direction := _world_direction(RIGHT, 0.0)
	var record := _dash(rig, MovementRig.press_dash_toward(RIGHT))
	_assert_dash_started(rig, record.plans[0], record.press_tick, direction)
	for index: int in record.plans.size():
		_assert_dash_tick(rig, record.plans[index], direction, true)
		assert_int(record.plans[index].state.dash_tick).is_equal(record.press_tick)
		assert_float(record.positions[index].x).is_less_equal(WALL_X + HAIR)
		assert_bool(record.on_floor[index]).is_true()
	assert_int(record.dash_mode_ticks()).is_equal(DASH_TICKS[tickrate])
	assert_float(record.horizontal_displacement().x).is_equal_approx(WALL_X, HAIR)
	_assert_dash_exit(rig, record, direction, FighterState.Mode.GROUND)
	var legal_tick := record.press_tick + PERIOD_TICKS[tickrate]
	while rig.tick < legal_tick:
		_assert_no_dash(rig.step(MovementRig.press_dash_toward(RIGHT)), record.press_tick)
	_assert_dash_started(rig, rig.step(MovementRig.press_dash_toward(RIGHT)), legal_tick, direction)


# Against the wall at an angle the engine slides: the core keeps the fixed direction, the wall
# takes the x and the z goes on at the dash speed's share, 4 m / sqrt(2) over the dash.
func test_a_dash_into_a_wall_at_an_angle_slides_along_it(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.wall_x = WALL_X
	var move := Vector2(1, 1)
	var direction := _world_direction(move, 0.0)
	var record := _dash(rig, MovementRig.press_dash_toward(move))
	_assert_dash_started(rig, record.plans[0], record.press_tick, direction)
	for plan: MovePlan in record.plans:
		_assert_dash_tick(rig, plan, direction, true)
	var moved := record.horizontal_displacement()
	assert_float(moved.x).is_equal_approx(WALL_X, HAIR)
	assert_float(moved.z).is_equal_approx(direction.z * DASH_DISTANCE_M, DISTANCE_TOLERANCE_M)
	_assert_dash_exit(rig, record, direction, FighterState.Mode.GROUND)


# DEC-0004, rule 3: the duration becomes the nearest tick, ties up, and the speed absorbs the
# rounding so the distance holds. The rows are arithmetic, not design numbers: 225 ms is
# 6.75 -> 7 ticks at 30 and 13.5 -> 14 at 60 (tie up); 190 ms is 5.7 -> 6 at 30 and 11.4 -> 11
# at 60. The distance stays 4 m within 1 cm at every one of them.
func test_the_duration_rounds_to_the_nearest_tick_and_the_speed_keeps_the_distance(
	tickrate: int,
	dash_ms: int,
	expected_ticks: int,
	_test_parameters := [[30, 225, 7], [60, 225, 14], [30, 190, 6], [60, 190, 11]],
) -> void:
	var data := _v0_copy()
	data.dash_ms = dash_ms
	assert_array(data.validate()).is_empty()
	var config := MovementConfig.create(data, tickrate)
	assert_int(config.dash_ticks).is_equal(expected_ticks)
	assert_int(config.dash_ticks).is_equal(Ticks.from_ms(dash_ms, tickrate))
	assert_float(config.dash_speed).is_equal_approx(
		DASH_DISTANCE_M * tickrate / expected_ticks,
		HAIR,
	)
	var rig := MovementRig.new(config, FIRST_TICK)
	var direction := _world_direction(FORWARD, 0.0)
	var record := _dash(rig, MovementRig.press_dash_toward(FORWARD))
	assert_int(record.dash_mode_ticks()).is_equal(expected_ticks)
	_assert_distance(record, direction, DASH_DISTANCE_M)
	_assert_dash_exit(rig, record, direction, FighterState.Mode.GROUND)


# The distance and the exit speed follow a duplicated MovementData, without touching code
# (DEC-0004, rule 3). 2 m, 6 m, 0 m/s and 3 m/s are arbitrary, not design numbers.
func test_the_distance_and_the_exit_speed_follow_a_duplicated_resource(
	tickrate: int,
	distance_m: float,
	exit_speed_mps: float,
	_test_parameters := [[30, 2.0, 0.0], [60, 2.0, 0.0], [30, 6.0, 3.0], [60, 6.0, 3.0]],
) -> void:
	var data := _v0_copy()
	data.dash_distance_m = distance_m
	data.dash_exit_speed_mps = exit_speed_mps
	assert_array(data.validate()).is_empty()
	var config := MovementConfig.create(data, tickrate)
	assert_float(config.dash_speed).is_equal_approx(distance_m * tickrate / config.dash_ticks, HAIR)
	assert_float(config.dash_exit_speed).is_equal_approx(exit_speed_mps, HAIR)
	var rig := MovementRig.new(config, FIRST_TICK)
	var direction := _world_direction(FORWARD, 0.0)
	var record := _dash(rig, MovementRig.press_dash_toward(FORWARD))
	_assert_dash_started(rig, record.plans[0], record.press_tick, direction)
	_assert_distance(record, direction, distance_m)
	_assert_dash_exit(rig, record, direction, FighterState.Mode.GROUND)


# With a cooldown of 0 ms (allowed: nothing divides by it) a held key chains the next dash on
# the exit tick itself, where the slot may fire the same tick (TASK-10.4 plan; DEC-0041 §2).
func test_with_a_cooldown_of_0_a_held_key_chains_the_next_dash_on_the_exit_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var data := _v0_copy()
	data.dash_cooldown_ms = 0
	assert_array(data.validate()).is_empty()
	var config := MovementConfig.create(data, tickrate)
	assert_int(config.dash_cooldown_ticks).is_equal(0)
	var rig := MovementRig.new(config, FIRST_TICK)
	var direction := _world_direction(FORWARD, 0.0)
	var starts: Array[int] = []
	var last_stamp := FighterState.NEVER
	for _step: int in 3 * DASH_TICKS[tickrate]:
		var tick := rig.tick
		var plan := rig.step(MovementRig.press_dash_toward(FORWARD))
		_assert_dash_tick(rig, plan, direction, true)
		if plan.state.dash_tick != last_stamp:
			starts.append(tick)
			last_stamp = plan.state.dash_tick
	var expected: Array[int] = [
		FIRST_TICK,
		FIRST_TICK + DASH_TICKS[tickrate],
		FIRST_TICK + 2 * DASH_TICKS[tickrate],
	]
	var message := "dashes at %s, expected %s" % [starts, expected]
	assert_array(starts).override_failure_message(message).is_equal(expected)
	assert_float(rig.stamina()).is_equal_approx(rig.config.stamina_max - 3 * DASH_COST, HAIR)
