# Criteria 2 to 6 of TASK-10.5, plus the "wall jump height follows the Resource" half of
# criterion 7: the wall run and the wall jump (movimento.md, "Corrida na parede"), a committed
# mode entered by contact in after_move and left by command in before_move (DEC-0041), with the
# wall facts of DEC-0042 (MoveFacts.wall_normal and wall_id), through the public interface of
# core/fighter, with the engine's slice of the tick played by MovementRig against fake walls
# (visao-geral.md, "O tick por dentro: o sanduíche"; rede.md §4, "A sonda A da parede"). Every
# number comes from docs/design/movimento.md, cited by section; ticks by hand from the ms,
# nearest tick with ties up (visao-geral.md, "O tempo e a física no estado").
extends GdUnitTestSuite

const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)

# movimento.md, "Corrida na parede".
const WALL_MIN_INCLINE_DEG := 80.0 # "Inclinação mínima da parede"
const WALL_MAX_NORMAL_Y := 0.1736 # "Parede válida": |normal.y| ≤ cos 80° (0,1736)
const WALL_ENTRY_SPEED_MPS := 4.0 # "Velocidade mínima para entrar", along the wall
const WALL_RUN_SPEED_MPS := 8.0 # "Velocidade na parede"
const WALL_MAX_SPEED_MPS := 12.0 # "Teto de velocidade na parede"
const WALL_RUN_MAX_MS := 2500 # "Duração máxima": 2,5 s
const WALL_HOLD_MS := 1500 # "Altura": mantida por 1,5 s
const WALL_SLIDE_GRAVITY_PCT := 10.0 # "Altura": 10% da gravidade de subida
const WALL_JUMP_HEIGHT_M := 1.2 # "Pulo da parede": 1,2 m de altura
const WALL_JUMP_PUSH_MPS := 5.0 # "Pulo da parede": 5 m/s para fora da parede
const WALL_SAME_FACE_DEG := 10.0 # "Mesma parede, em números": até 10°, inclusive

# movimento.md, "Chão", "Pulo e ar" and "Perdão".
const RUN_SPEED_MPS := 7.0 # "Chão": "Velocidade de corrida"
const JUMP_HEIGHT_M := 1.2 # "Pulo e ar": "Altura do pulo"
const DOUBLE_JUMP_HEIGHT_M := 1.0 # "Pulo e ar": "Altura do pulo duplo"
const AIR_ACCEL_PER_TICK_AT_60 := 0.194 # "Pulo e ar": "Controle no ar": 0,194 m/s por tick a 60
const HEIGHT_TOLERANCE_M := 0.01 # 1 cm (criteria 3 and 5; visao-geral.md, "O tempo e a física")

# The wall times by hand (movimento.md, "Corrida na parede"): 1,5 s of held height is 45 ticks
# at 30 and 90 at 60; 2,5 s of run is 75 and 150, exact. The slide fills the rest: 30 and 60
# ticks, the k-th at -k · 10 % of the rise gravity per tick, applied before the move, which
# loses 0,922 m at 30 and 0,996 m at 60 ("Descida, tick a tick"). The rise gravity per tick is
# 2 · 1,2 m · tickrate / rise_ticks²: 0,595 m/s per tick at 30 (11 ticks) and 0,327 at 60 (21),
# so 10 % is 0,0595 and 0,0327 (criterion 3).
const WALL_HOLD_TICKS: Dictionary[int, int] = { 30: 45, 60: 90 }
const WALL_RUN_MAX_TICKS: Dictionary[int, int] = { 30: 75, 60: 150 }
const SLIDE_TICKS: Dictionary[int, int] = { 30: 30, 60: 60 }
const SLIDE_DROP_M: Dictionary[int, float] = { 30: 0.922, 60: 0.996 }
const SLIDE_GRAVITY_PER_TICK: Dictionary[int, float] = { 30: 0.0595, 60: 0.0327 }
const SLIDE_GRAVITY_TOLERANCE := 1e-4 # the design rounds to four decimals, not a design number
# 150 ms of buffer is 4.5 -> 5 at 30 (tie up) and 9 at 60, inclusive: the press counts while
# tick - stamp <= window (movimento.md, "Perdão"; DEC-0039).
const BUFFER_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }
# The full jump's rise by hand: 350 ms is 10.5 -> 11 ticks at 30 (tie up) and 21 at 60
# (movimento.md, "Pulo e ar"): one tick later the body sits at the apex.
const RISE_TICKS: Dictionary[int, int] = { 30: 11, 60: 21 }

# Criterion 2: the speeds along the wall that decide the entry and the run. 3,9 m/s is refused;
# 4 enters and runs at 8; 8 keeps 8; 10 keeps 10; 12 is the ceiling; 14 is capped at 12.
const BELOW_ENTRY_SPEED_MPS := 3.9
const ENTRY_TO_RUN_SPEED: Dictionary[float, float] = {
	4.0: 8.0,
	8.0: 8.0,
	10.0: 10.0,
	12.0: 12.0,
	14.0: 12.0,
}

# The geometry of the rig, not design numbers. The body approaches the wall from APPROACH_M in
# front of it at APPROACH_SPEED_MPS into it, which touches after about 0,43 s at both rates: room
# for a press a full buffer window before the touch. START_HEIGHT_M keeps the floor far below.
const APPROACH_M := 0.9
const APPROACH_SPEED_MPS := 2.0
const START_HEIGHT_M := 10.0
const RISING_VERTICAL_MPS := 12.0 # still going up at the touch, after the approach
const FALLING_VERTICAL_MPS := -6.0
const LOW_START_HEIGHT_M := 0.5 # the slide reaches the floor before the run's time is up
const EDGE_M := 8.0 # where a face ends, in the run's direction, ahead of the touch
const FAR_M := 17.0 # a seam or a corner after the held height, before the run's time is up
const SEAM_NEAR_M := 5.0 # a seam the body passes while away from the wall after the wall jump
const AWAY_TICKS := 6 # ticks idled away from the wall after the wall jump, before coming back
const CORRIDOR_GAP_M := 2.8 # the planned corridor, centre to centre (TASK-10.5, "Números v0")
const CORNER_DEG := 45.0 # a face well beyond the 10° of the same face
const THROWN_BACK_MPS := 5.0 # the push of the wall jump, reversed by hand
const WALL_A := &"ParedeA" # ids as the adapter reports them: node paths relative to the Arena
const WALL_B := &"ParedeB"
const WALL_A2 := &"ParedeA2" # a second block in the plane of WALL_A (F-129)
const BOX := &"Caixa" # one collider with several faces
const FORWARD := Vector2(0, 1) # move.y goes forward: yaw 0 looks down -Z (TASK-9 plan)

const HAIR := 1e-6 # floating-point slack, not a design number
# A Vector3 holds 32-bit floats: on a tilted plane the clamp and the slide carry that error.
const GEOMETRY_HAIR := 1e-4
# An angle one step inside its limit, so that the float32 normal of the Vector3 still falls on
# the inclusive side of a cosine computed in 64 bits: 80,0001° is a wall of at least 80° and
# 9,9999° is the same face, to the precision the engine's normals carry.
const LIMIT_STEP_DEG := 0.0001
const HALF_TICK_IN_MS_TIMES_RATE := 500 # |ticks * 1000 - ms * rate| <= 500 is half a tick


# The ticks of one run from the entry, each with the plan the core made in before_move (its
# state is the one before the engine moved), the position after the move and the state after
# after_move (the one the next tick starts from).
class RunRecord:
	var entry_tick := 0
	var entry_height := 0.0 # position.y after the entry tick
	var plans: Array[MovePlan] = [] # tick entry_tick + 1 first
	var positions: Array[Vector3] = []
	var states: Array[FighterState] = []


	func plan_at(ticks_after_entry: int) -> MovePlan:
		return plans[ticks_after_entry - 1]


	func height_at(ticks_after_entry: int) -> float:
		return positions[ticks_after_entry - 1].y


	func state_at(ticks_after_entry: int) -> FighterState:
		return states[ticks_after_entry - 1]


	func wall_run_ticks() -> int:
		var count := 1 # the entry tick's state is already WALL_RUN
		for plan: MovePlan in plans:
			if plan.state.mode == FighterState.Mode.WALL_RUN:
				count += 1
		return count


func _rig(tickrate: int) -> MovementRig:
	return MovementRig.new(MovementRig.load_config(tickrate), FIRST_TICK)


# A rig with no floor at all: the body never lands, the wall is the only contact.
func _air_rig(tickrate: int) -> MovementRig:
	var rig := _rig(tickrate)
	rig.floor_on = false
	return rig


func _v0_copy() -> MovementData:
	var resource: Resource = load(MovementRig.MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MovementRig.MOVEMENT_V0)
	var copy: Resource = resource.duplicate()
	assert(copy is MovementData, "a duplicate must still be a MovementData")
	return copy as MovementData


func _horizontal(velocity: Vector3) -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)


# The speed along the wall: the horizontal velocity projected on the plane of the flattened
# normal (movimento.md, "Corrida na parede": "O que decide a entrada").
func _along(velocity: Vector3, normal: Vector3) -> Vector3:
	var flat := Vector3(normal.x, 0.0, normal.z).normalized()
	var horizontal := _horizontal(velocity)
	return horizontal - flat * horizontal.dot(flat)


# The wall at x = 0 facing +X: the body runs along -Z beside it, and the face's "along"
# coordinate grows toward -Z (UP × +X).
func _wall_a(rig: MovementRig) -> MovementRig.FakeWall:
	return rig.add_wall(Vector3.RIGHT, 0.0, WALL_A)


# A wall whose normal leans incline_deg from the horizontal: 90° is vertical, 80° the limit.
# The plane passes through (0, START_HEIGHT_M, 0), so the body approaches it like WALL_A.
func _inclined_normal(incline_deg: float) -> Vector3:
	var a := deg_to_rad(incline_deg)
	return Vector3(sin(a), cos(a), 0.0)


# The normal of +X turned about the vertical by degrees: the faces of one box.
func _turned_normal(degrees: float) -> Vector3:
	return Basis(Vector3.UP, deg_to_rad(degrees)) * Vector3.RIGHT


# Puts the body in the air APPROACH_M in front of the plane x = 0, flying into it at
# APPROACH_SPEED_MPS while running -Z at along_speed, with this vertical speed.
func _approach_wall_a(rig: MovementRig, along_speed: float, vertical: float) -> void:
	rig.airborne(
		Vector3(APPROACH_M, START_HEIGHT_M, 0.0),
		Vector3(-APPROACH_SPEED_MPS, vertical, -along_speed),
	)


# Idles until the core starts a wall run; returns the entry tick, or fails.
func _fly_until_wall_run(rig: MovementRig, limit: int) -> int:
	for _step: int in limit:
		rig.step(MovementRig.idle())
		if rig.state.mode == FighterState.Mode.WALL_RUN:
			return rig.tick - 1
	fail("never started a wall run within %d ticks (at %d ticks)" % [limit, rig.config.tickrate])
	return -1


# Idles up to limit ticks and asserts no wall run ever starts; returns true if the wall was in
# contact on at least one tick, so a refusal is proven against a touch and not against air.
func _fly_without_wall_run(rig: MovementRig, limit: int, wall: StringName) -> bool:
	var touched := false
	var violations: Array[String] = []
	for _step: int in limit:
		var plan := rig.step(MovementRig.idle())
		if rig.last_facts.wall_id == wall:
			touched = true
		if plan.state.mode == FighterState.Mode.WALL_RUN \
				or rig.state.mode == FighterState.Mode.WALL_RUN:
			violations.append("tick %d: started a wall run" % (rig.tick - 1))
	assert_array(violations).override_failure_message("a wall run started: %s" % [violations]) \
			.is_empty()
	return touched


# Approaches WALL_A and records the run from the entry tick, feeding `during` in a cycle after
# the entry (idle when empty), for `ticks` ticks.
func _record_run(rig: MovementRig, ticks: int, during: Array[TickInput] = []) -> RunRecord:
	var record := RunRecord.new()
	record.entry_tick = _fly_until_wall_run(rig, 2 * rig.config.tickrate)
	record.entry_height = rig.position.y
	for step: int in range(1, ticks + 1):
		var input := MovementRig.idle() if during.is_empty() else during[(step - 1) % during.size()]
		record.plans.append(rig.step(input))
		record.positions.append(rig.position)
		record.states.append(rig.state)
	return record


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


func _assert_facts_wall(facts: MoveFacts, wall: StringName) -> void:
	var message := "the facts report wall %s, expected %s" % [facts.wall_id, wall]
	assert_str(String(facts.wall_id)).override_failure_message(message).is_equal(String(wall))


# The entry as the plan says it (TASK-10.5 plan; DEC-0042): WALL_RUN since the entry tick, the
# wall's id and flattened normal in the state, and the double jump renewed.
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


# The wall jump as the plan says it (TASK-10.5 plan; DEC-0041): on the press tick the vertical
# is the wall jump's exit speed, the velocity gains wall_jump_push along the wall's normal and
# keeps the part along the wall; it is the first jump of the flight, stamped, the mode is AIR
# since now, the double jump is untouched and the slot is consumed.
func _assert_wall_jumped(
	rig: MovementRig,
	plan: MovePlan,
	press_tick: int,
	normal: Vector3,
	along: Vector3,
) -> void:
	assert_int(plan.state.mode).override_failure_message("still on the wall").is_equal(
		FighterState.Mode.AIR
	)
	assert_int(plan.state.mode_since).is_equal(press_tick)
	assert_int(plan.state.wall_jump_tick).is_equal(press_tick)
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
	var message := "%s along the wall after the jump, expected %s kept" % [kept, along]
	assert_vector(kept).override_failure_message(message).is_equal_approx(along, Vector3.ONE * HAIR)


func _assert_double_jumped(rig: MovementRig, plan: MovePlan, press_tick: int) -> void:
	assert_float(plan.velocity.y).override_failure_message("not the double jump speed") \
			.is_equal_approx(rig.config.double_jump_speed, HAIR)
	assert_int(plan.state.jumps_used).override_failure_message("not the second jump").is_equal(2)
	assert_int(plan.state.double_jump_tick).is_equal(press_tick)
	_assert_slot(plan.state, FighterCommand.NONE, FighterState.NEVER)


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


# None: a fresh state has no wall, and the mode, the fields and the facts exist under the agreed
# names (TASK-10.5 plan: State, Facts; DEC-0042).
func test_a_fresh_state_has_no_wall_and_the_agreed_names_exist() -> void:
	var state := FighterState.new()
	assert_vector(state.wall_normal).is_equal(Vector3.ZERO)
	assert_str(String(state.wall_id)).is_equal("")
	assert_int(state.wall_jump_tick).is_equal(FighterState.NEVER)
	assert_int(FighterState.Mode.WALL_RUN).is_equal(3)
	assert_int(FighterState.Mode.WALL_RUN).is_not_equal(FighterState.Mode.GROUND)
	assert_int(FighterState.Mode.WALL_RUN).is_not_equal(FighterState.Mode.AIR)
	assert_int(FighterState.Mode.WALL_RUN).is_not_equal(FighterState.Mode.DASH)
	var facts := MoveFacts.new()
	assert_vector(facts.wall_normal).is_equal(Vector3.ZERO)
	assert_str(String(facts.wall_id)).is_equal("")


# The three wall fields travel with copy(): a field left out would come back as its default
# after a rollback (visao-geral.md).
func test_fighter_state_copy_carries_the_wall_fields() -> void:
	var original := _rig(60).state
	original.mode = FighterState.Mode.WALL_RUN
	original.wall_normal = Vector3(0.6, 0.0, -0.8)
	original.wall_id = WALL_A
	original.wall_jump_tick = 1234
	var copy := original.copy()
	assert_int(copy.mode).is_equal(FighterState.Mode.WALL_RUN)
	assert_vector(copy.wall_normal).is_equal(Vector3(0.6, 0.0, -0.8))
	_assert_wall_id(copy, WALL_A)
	assert_int(copy.wall_jump_tick).is_equal(1234)
	copy.wall_normal = Vector3.ZERO
	copy.wall_id = &""
	copy.wall_jump_tick = FighterState.NEVER
	copy.mode = FighterState.Mode.AIR
	assert_vector(original.wall_normal).is_equal(Vector3(0.6, 0.0, -0.8))
	_assert_wall_id(original, WALL_A)
	assert_int(original.wall_jump_tick).is_equal(1234)
	assert_int(original.mode).is_equal(FighterState.Mode.WALL_RUN)


# The hand numbers above against the config they must match (movement_v0.tres at load): the two
# wall times become ticks by the rule of Ticks.from_ms, within half a tick (DEC-0004, rule 3).
func test_the_config_carries_the_wall_times_of_the_design(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var config := MovementRig.load_config(tickrate)
	assert_int(config.wall_hold_ticks).is_equal(WALL_HOLD_TICKS[tickrate])
	assert_int(config.wall_hold_ticks).is_equal(Ticks.from_ms(WALL_HOLD_MS, tickrate))
	assert_int(absi(config.wall_hold_ticks * 1000 - WALL_HOLD_MS * tickrate)).is_less_equal(
		HALF_TICK_IN_MS_TIMES_RATE
	)
	assert_int(config.wall_run_max_ticks).is_equal(WALL_RUN_MAX_TICKS[tickrate])
	assert_int(config.wall_run_max_ticks).is_equal(Ticks.from_ms(WALL_RUN_MAX_MS, tickrate))
	assert_int(absi(config.wall_run_max_ticks * 1000 - WALL_RUN_MAX_MS * tickrate)) \
			.is_less_equal(HALF_TICK_IN_MS_TIMES_RATE)
	assert_int(config.wall_run_max_ticks - config.wall_hold_ticks).is_equal(SLIDE_TICKS[tickrate])
	assert_int(config.buffer_ticks).is_equal(BUFFER_TICKS[tickrate])
	assert_float(config.wall_entry_speed).is_equal_approx(WALL_ENTRY_SPEED_MPS, HAIR)
	assert_float(config.wall_run_speed).is_equal_approx(WALL_RUN_SPEED_MPS, HAIR)
	assert_float(config.wall_max_speed).is_equal_approx(WALL_MAX_SPEED_MPS, HAIR)
	assert_float(config.wall_jump_push).is_equal_approx(WALL_JUMP_PUSH_MPS, HAIR)
	assert_float(config.wall_max_normal_y).is_equal_approx(
		cos(deg_to_rad(WALL_MIN_INCLINE_DEG)),
		HAIR,
	)
	assert_float(config.wall_same_face_cos).is_equal_approx(
		cos(deg_to_rad(WALL_SAME_FACE_DEG)),
		HAIR,
	)


# None: with no wall around, a flight never becomes a wall run and the facts carry no wall.
func test_a_flight_with_no_wall_never_wall_runs(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	var violations: Array[String] = []
	for step: int in range(1, 2 * tickrate + 1):
		var input := MovementRig.run(FORWARD) if step % 2 == 0 else MovementRig.idle()
		var plan := rig.step(input)
		if plan.state.mode == FighterState.Mode.WALL_RUN:
			violations.append("step %d: wall run" % step)
		if not rig.last_facts.wall_id.is_empty() or rig.last_facts.wall_normal != Vector3.ZERO:
			violations.append("step %d: a wall in the facts" % step)
	assert_array(violations).is_empty()
	assert_str(String(rig.state.wall_id)).is_equal("")
	assert_vector(rig.state.wall_normal).is_equal(Vector3.ZERO)
	assert_int(rig.state.wall_jump_tick).is_equal(FighterState.NEVER)


# The slice is pure: the entry happens in the copy, never in the state received (DEC-0004,
# rule 1).
func test_after_move_leaves_the_state_it_receives_untouched_when_the_wall_run_starts() -> void:
	var rig := _air_rig(60)
	rig.airborne(Vector3(0.0, START_HEIGHT_M, 0.0), Vector3(0.0, 0.0, -WALL_RUN_SPEED_MPS))
	var given := rig.state
	var facts := MoveFacts.new()
	facts.on_floor = false
	facts.velocity = Vector3(0.0, FALLING_VERTICAL_MPS, -WALL_RUN_SPEED_MPS)
	facts.wall_normal = Vector3.RIGHT
	facts.wall_id = WALL_A
	var next := Movement.after_move(given, facts, rig.config, FIRST_TICK)
	_assert_wall_run_started(next, FIRST_TICK, WALL_A, Vector3.RIGHT)
	assert_int(given.mode).is_equal(FighterState.Mode.AIR)
	assert_str(String(given.wall_id)).is_equal("")
	assert_vector(given.wall_normal).is_equal(Vector3.ZERO)


# Criterion 2: in the air, touching a vertical wall with 4 m/s along it starts the run on that
# tick: the wall's id and normal in the state, the double jump renewed, and from the next tick
# the body runs at 8 m/s in the entry's direction with the vertical at 0 (movimento.md,
# "Corrida na parede": "Como entra", "Velocidade mínima para entrar", "O que decide a entrada").
func test_touching_a_vertical_wall_in_the_air_with_4_mps_along_it_starts_the_wall_run(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, WALL_ENTRY_SPEED_MPS, FALLING_VERTICAL_MPS)
	var entry_tick := _fly_until_wall_run(rig, 2 * tickrate)
	_assert_wall_run_started(rig.state, entry_tick, WALL_A, Vector3.RIGHT)
	_assert_facts_wall(rig.last_facts, WALL_A)
	assert_float(rig.position.x).override_failure_message("not beside the wall").is_between(
		-HAIR,
		MovementRig.WALL_PROBE_DISTANCE + HAIR,
	)
	var entry_height := rig.position.y
	var first := rig.step(MovementRig.idle())
	_assert_run_tick(first, Vector3.FORWARD, WALL_RUN_SPEED_MPS, 0.0)
	assert_float(rig.position.y).is_equal_approx(entry_height, HAIR)
	_assert_wall_run_started(rig.state, entry_tick, WALL_A, Vector3.RIGHT)
	var second := rig.step(MovementRig.idle())
	_assert_run_tick(second, Vector3.FORWARD, WALL_RUN_SPEED_MPS, 0.0)
	assert_int(rig.state.mode_since).is_equal(entry_tick)


# Starting a wall run renews the double jump (movimento.md, "Princípios"; "Pulo e ar":
# "Renovação do pulo duplo"): spent in this flight, it is available again on the entry tick.
func test_the_entry_renews_the_double_jump(tickrate: int, _test_parameters := [[30], [60]]) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	rig.state.jumps_used = 2
	rig.state.double_jump_tick = rig.tick - 1
	var entry_tick := _fly_until_wall_run(rig, 2 * tickrate)
	var before := rig.last_plan.state
	assert_int(before.jumps_used).override_failure_message("renewed before the touch").is_equal(2)
	_assert_wall_run_started(rig.state, entry_tick, WALL_A, Vector3.RIGHT)


# The run speed is 8 m/s, or the entry speed up to the ceiling of 12: 4 runs at 8, 8 at 8, 10 at
# 10, 12 at 12 and 14 at 12, in the entry's direction, on every tick of the held height
# (movimento.md, "Corrida na parede": "Velocidade na parede", "Teto de velocidade na parede").
func test_the_run_keeps_the_entry_speed_from_8_up_to_the_ceiling_of_12(
	tickrate: int,
	entry_speed: float,
	_test_parameters := [
		[30, 4.0],
		[60, 4.0],
		[30, 8.0],
		[60, 8.0],
		[30, 10.0],
		[60, 10.0],
		[30, 12.0],
		[60, 12.0],
		[30, 14.0],
		[60, 14.0],
	],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, entry_speed, FALLING_VERTICAL_MPS)
	var run_speed: float = ENTRY_TO_RUN_SPEED[entry_speed]
	var record := _record_run(rig, 10)
	for step: int in range(1, 11):
		_assert_run_tick(record.plan_at(step), Vector3.FORWARD, run_speed, 0.0)
	var moved := record.positions[9] - record.positions[0]
	assert_vector(moved).is_equal_approx(
		Vector3.FORWARD * run_speed * 9 / tickrate,
		Vector3.ONE * GEOMETRY_HAIR,
	)


# The vertical is zeroed at the entry whatever it was: rising fast or falling, the first run
# tick has a vertical of 0 and the height of the entry tick holds (movimento.md, "Corrida na
# parede": "O que decide a entrada": "a vertical zera"; criterion 3: "qualquer que fosse a
# vertical na entrada").
func test_the_entry_zeroes_the_vertical_whatever_it_was(
	tickrate: int,
	vertical: float,
	_test_parameters := [
		[30, RISING_VERTICAL_MPS],
		[60, RISING_VERTICAL_MPS],
		[30, FALLING_VERTICAL_MPS],
		[60, FALLING_VERTICAL_MPS],
	],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, vertical)
	var record := _record_run(rig, WALL_HOLD_TICKS[tickrate] - 1)
	var entry_vertical := record.plan_at(1).velocity.y
	assert_float(entry_vertical).is_equal(0.0)
	var violations: Array[String] = []
	for step: int in range(1, WALL_HOLD_TICKS[tickrate]):
		if absf(record.plan_at(step).velocity.y) > HAIR:
			violations.append("tick +%d: vertical %.4f" % [step, record.plan_at(step).velocity.y])
		if absf(record.height_at(step) - record.entry_height) > HEIGHT_TOLERANCE_M:
			violations.append(
				"tick +%d: height %.4f, entry %.4f"
				% [step, record.height_at(step), record.entry_height]
			)
	assert_array(violations).override_failure_message("%s" % [violations]).is_empty()
	assert_int(record.wall_run_ticks()).is_equal(WALL_HOLD_TICKS[tickrate])


# At the entry the body still had its vertical: the precondition of the test above, proven
# against the facts of the entry tick, so the rising case did rise and the falling one fell.
func test_the_body_still_rises_or_falls_on_the_entry_tick(
	tickrate: int,
	vertical: float,
	_test_parameters := [
		[30, RISING_VERTICAL_MPS],
		[60, RISING_VERTICAL_MPS],
		[30, FALLING_VERTICAL_MPS],
		[60, FALLING_VERTICAL_MPS],
	],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, vertical)
	_fly_until_wall_run(rig, 2 * tickrate)
	if vertical > 0.0:
		assert_float(rig.last_facts.velocity.y).override_failure_message("not rising").is_greater(
			HAIR
		)
	else:
		assert_float(rig.last_facts.velocity.y).override_failure_message("not falling").is_less(
			-HAIR
		)


# Failure: with 3,9 m/s along the wall the touch starts nothing, at both rates (movimento.md,
# "Corrida na parede": "Velocidade mínima para entrar: 4").
func test_with_3_9_mps_along_the_wall_the_touch_starts_no_run(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, BELOW_ENTRY_SPEED_MPS, FALLING_VERTICAL_MPS)
	var touched := _fly_without_wall_run(rig, 2 * tickrate, WALL_A)
	assert_bool(touched).override_failure_message("the wall was never touched").is_true()
	assert_str(String(rig.state.wall_id)).is_equal("")
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)


# Head-on the speed along the wall is zero, whatever the speed into it: no run (movimento.md,
# "Corrida na parede": "De frente para a parede não entra").
func test_head_on_into_the_wall_the_touch_starts_no_run(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	rig.airborne(
		Vector3(APPROACH_M, START_HEIGHT_M, 0.0),
		Vector3(-WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS, 0.0),
	)
	var touched := _fly_without_wall_run(rig, 2 * tickrate, WALL_A)
	assert_bool(touched).override_failure_message("the wall was never touched").is_true()
	assert_float(rig.velocity.x).override_failure_message("passed through the wall").is_equal(0.0)


# A wall of at least 80° accepts the run and a lower one refuses it: 90° (vertical), 85° and the
# limit enter; 79,999°, 79° and 45° (a ramp, not a wall) do not (movimento.md, "Corrida na
# parede": "Inclinação mínima da parede: 80"; "Parede válida: |normal.y| ≤ cos 80°").
func test_a_wall_of_at_least_80_degrees_accepts_the_run_and_a_lower_one_refuses_it(
	tickrate: int,
	incline_deg: float,
	accepts: bool,
	_test_parameters := [
		[60, 90.0, true],
		[30, 90.0, true],
		[60, 85.0, true],
		[60, WALL_MIN_INCLINE_DEG + LIMIT_STEP_DEG, true],
		[30, WALL_MIN_INCLINE_DEG + LIMIT_STEP_DEG, true],
		[60, WALL_MIN_INCLINE_DEG - 0.001, false],
		[60, 79.0, false],
		[30, 79.0, false],
		[60, 45.0, false],
	],
) -> void:
	var rig := _air_rig(tickrate)
	var normal := _inclined_normal(incline_deg)
	var anchor := Vector3(0.0, START_HEIGHT_M, 0.0)
	rig.add_wall(normal, normal.dot(anchor), WALL_A)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	if accepts:
		var entry_tick := _fly_until_wall_run(rig, 2 * tickrate)
		assert_int(rig.state.mode_since).is_equal(entry_tick)
		_assert_wall_id(rig.state, WALL_A)
		assert_float(absf(rig.state.wall_normal.y)).is_less_equal(HAIR)
	else:
		var touched := _fly_without_wall_run(rig, tickrate, WALL_A)
		assert_bool(touched).override_failure_message("the wall was never touched").is_true()
		assert_str(String(rig.state.wall_id)).is_equal("")


# The design's threshold for the normal: cos 80° is 0,1736 (movimento.md, "Parede válida").
func test_the_valid_wall_threshold_is_cos_80_degrees() -> void:
	assert_float(cos(deg_to_rad(WALL_MIN_INCLINE_DEG))).is_equal_approx(WALL_MAX_NORMAL_Y, 1e-4)
	# The limit normals of the entry test sit on either side of the exact cosine, not of the
	# design's four-decimal rounding (F-130).
	var exact := cos(deg_to_rad(WALL_MIN_INCLINE_DEG))
	assert_float(absf(_inclined_normal(WALL_MIN_INCLINE_DEG + LIMIT_STEP_DEG).y)).is_less(exact)
	assert_float(absf(_inclined_normal(WALL_MIN_INCLINE_DEG - 0.001).y)).is_greater(exact)


# From the floor the wall starts nothing: running beside it at 7 m/s, in contact every tick,
# the mode stays GROUND (movimento.md, "Corrida na parede": "Como entra: no ar").
func test_from_the_floor_the_wall_starts_no_run(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_wall_a(rig)
	rig.position = Vector3(MovementRig.WALL_PROBE_DISTANCE / 2.0, 0.0, 0.0)
	var touched := 0
	var violations: Array[String] = []
	for step: int in range(1, tickrate + 1):
		var plan := rig.step(MovementRig.run(FORWARD))
		if rig.last_facts.wall_id == WALL_A:
			touched += 1
		if plan.state.mode != FighterState.Mode.GROUND or not rig.state.on_floor:
			violations.append("step %d: left the ground (mode %d)" % [step, plan.state.mode])
	assert_array(violations).is_empty()
	assert_int(touched).override_failure_message("the wall was never in contact").is_equal(tickrate)
	assert_float(rig.horizontal_speed()).is_equal_approx(RUN_SPEED_MPS, HAIR)
	assert_str(String(rig.state.wall_id)).is_equal("")


# The direction input neither turns nor brakes the run, nor does the camera: the body follows
# the same path as with no input at all, backwards input included (movimento.md, "Corrida na
# parede": "O input não vira nem freia").
func test_the_direction_input_neither_turns_nor_brakes_the_run(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var quiet := _air_rig(tickrate)
	var noisy := _air_rig(tickrate)
	_wall_a(quiet)
	_wall_a(noisy)
	_approach_wall_a(quiet, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	_approach_wall_a(noisy, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	var noise: Array[TickInput] = [
		MovementRig.run(Vector2(0, -1), 0.0), # backwards: against the run
		MovementRig.run(Vector2(-1, 0), PI), # into the wall, camera turned
		MovementRig.run(Vector2(1, 1), 0.3),
		MovementRig.run(Vector2(0, 1), 0.0), # along the run: no gain either
	]
	var ticks := WALL_RUN_MAX_TICKS[tickrate] - 1
	var expected := _record_run(quiet, ticks)
	var record := _record_run(noisy, ticks, noise)
	assert_int(record.entry_tick).is_equal(expected.entry_tick)
	var violations: Array[String] = []
	for index: int in ticks:
		if not record.positions[index].is_equal_approx(expected.positions[index]):
			violations.append(
				"tick +%d: moved to %s with input, %s without"
				% [index + 1, record.positions[index], expected.positions[index]]
			)
		if not record.plans[index].velocity.is_equal_approx(expected.plans[index].velocity):
			violations.append(
				"tick +%d: velocity %s with input, %s without"
				% [index + 1, record.plans[index].velocity, expected.plans[index].velocity]
			)
	assert_array(violations).override_failure_message("%s" % [violations]).is_empty()
	assert_int(record.wall_run_ticks()).is_equal(WALL_RUN_MAX_TICKS[tickrate])
	assert_float(noisy.horizontal_speed()).is_equal_approx(WALL_RUN_SPEED_MPS, HAIR)


# Criterion 3: the height holds for 1,5 s after the entry, within 1 cm; then on the k-th slide
# tick the vertical is -k · 10 % of the rise gravity per tick, applied before the move (the
# first slide tick already drops by that much), and by the end of the run, at 2,5 s, the body
# has lost 0,996 m at 60 ticks and 0,922 m at 30, within 1 cm; the tick after, the run is over
# (movimento.md, "Corrida na parede": "Altura", "Descida, tick a tick", "Duração máxima").
func test_the_height_holds_1_5_s_then_the_slide_loses_0_996_m_at_60_and_0_922_m_at_30(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	var hold := WALL_HOLD_TICKS[tickrate]
	var max_ticks := WALL_RUN_MAX_TICKS[tickrate]
	var record := _record_run(rig, max_ticks)
	var slide_gravity := rig.config.wall_slide_gravity_per_tick
	assert_float(slide_gravity).is_equal_approx(
		SLIDE_GRAVITY_PER_TICK[tickrate],
		SLIDE_GRAVITY_TOLERANCE,
	)
	var violations: Array[String] = []
	for step: int in range(1, hold):
		if absf(record.plan_at(step).velocity.y) > HAIR:
			violations.append(
				"hold tick +%d: vertical %.5f" % [step, record.plan_at(step).velocity.y]
			)
		if absf(record.height_at(step) - record.entry_height) > HEIGHT_TOLERANCE_M:
			violations.append(
				"hold tick +%d: height %.4f, entry %.4f"
				% [step, record.height_at(step), record.entry_height]
			)
	for step: int in range(hold, max_ticks):
		var k := step - hold + 1
		var expected := -k * slide_gravity
		if absf(record.plan_at(step).velocity.y - expected) > HAIR:
			violations.append(
				"slide tick %d (+%d): vertical %.5f, expected %.5f"
				% [k, step, record.plan_at(step).velocity.y, expected]
			)
	assert_array(violations).override_failure_message("%s" % [violations]).is_empty()
	var first_drop := record.height_at(hold - 1) - record.height_at(hold)
	var drop_message := "the first slide tick dropped %.6f m, expected %.6f (before the move)" % [
		first_drop,
		slide_gravity / tickrate,
	]
	assert_float(first_drop).override_failure_message(drop_message).is_equal_approx(
		slide_gravity / tickrate,
		1e-5,
	)
	_assert_height(
		record.entry_height - record.height_at(max_ticks - 1),
		SLIDE_DROP_M[tickrate],
		"lost by the end of the run at %d ticks" % tickrate,
	)
	assert_int(record.wall_run_ticks()).is_equal(max_ticks)
	var after := record.plan_at(max_ticks)
	assert_int(after.state.mode).override_failure_message("still on the wall after 2,5 s") \
			.is_equal(FighterState.Mode.AIR)
	assert_int(after.state.mode_since).is_equal(record.entry_tick + max_ticks)


# The slide's gravity per tick is 10 % of the rise gravity per tick of the jump: 0,0327 m/s at
# 60 and 0,0595 at 30 (criterion 3; movimento.md, "Corrida na parede": "Altura").
func test_the_slide_gravity_is_10_percent_of_the_rise_gravity_per_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var config := MovementRig.load_config(tickrate)
	assert_float(config.wall_slide_gravity_per_tick).is_equal_approx(
		config.rise_gravity_per_tick * WALL_SLIDE_GRAVITY_PCT / 100.0,
		HAIR,
	)
	assert_float(config.wall_slide_gravity_per_tick).is_equal_approx(
		SLIDE_GRAVITY_PER_TICK[tickrate],
		SLIDE_GRAVITY_TOLERANCE,
	)


# Criterion 4: after the end by time the body falls in the air with the double jump available,
# and there is no coyote of the wall: a press right after is the double jump, 1,0 m up, not the
# full jump (movimento.md, "Corrida na parede": "Fins da corrida", "Pulo da parede no voo").
func test_after_the_end_by_time_the_body_falls_with_the_double_jump_available(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	var record := _record_run(rig, WALL_RUN_MAX_TICKS[tickrate])
	var ended := record.plan_at(WALL_RUN_MAX_TICKS[tickrate]).state
	assert_int(ended.mode).is_equal(FighterState.Mode.AIR)
	assert_int(ended.jumps_used).is_equal(0)
	assert_int(ended.double_jump_tick).is_equal(FighterState.NEVER)
	_assert_wall_id(ended, WALL_A)
	assert_bool(rig.state.on_floor).is_false()
	var press_tick := rig.tick
	var press_height := rig.position.y
	var plan := rig.step(MovementRig.press_jump())
	_assert_double_jumped(rig, plan, press_tick)
	assert_float(plan.velocity.y).override_failure_message("the full jump: a coyote of the wall") \
			.is_less(rig.config.jump_speed - HAIR)
	_assert_height(_apex(rig, 2 * tickrate) - press_height, DOUBLE_JUMP_HEIGHT_M, "double jump")


# Criterion 4: the run ends on the tick the wall ends: the first tick the body is past the
# face's end is already in AIR since that tick, before the run's time is up; the state keeps
# the wall as the last one, and the double jump is available.
func test_the_run_ends_the_same_tick_the_wall_ends(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	var wall := _wall_a(rig)
	wall.along_max = wall.along_of(Vector3(0.0, 0.0, -EDGE_M))
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	var entry_tick := _fly_until_wall_run(rig, 2 * tickrate)
	var end_tick := -1
	var before_end := Vector3.ZERO
	for _step: int in WALL_RUN_MAX_TICKS[tickrate]:
		var previous := rig.position
		rig.step(MovementRig.idle())
		if rig.state.mode != FighterState.Mode.WALL_RUN:
			end_tick = rig.tick - 1
			before_end = previous
			break
	assert_int(end_tick).override_failure_message("the run never ended").is_greater(entry_tick)
	assert_int(end_tick - entry_tick).is_less(WALL_HOLD_TICKS[tickrate])
	assert_float(wall.along_of(before_end)).override_failure_message("ended before the edge") \
			.is_less_equal(wall.along_max + HAIR)
	assert_float(wall.along_of(rig.position)).override_failure_message("ended after the edge") \
			.is_greater(wall.along_max)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	assert_int(rig.state.mode_since).is_equal(end_tick)
	assert_int(rig.state.jumps_used).is_equal(0)
	assert_int(rig.state.double_jump_tick).is_equal(FighterState.NEVER)
	_assert_wall_id(rig.state, WALL_A)
	assert_str(String(rig.last_facts.wall_id)).is_equal("")
	var press_tick := rig.tick
	_assert_double_jumped(rig, rig.step(MovementRig.press_jump()), press_tick)


# Criterion 4: the run ends on the tick the body touches the floor, in GROUND since that tick;
# the floor clears the wall from the state, and the same wall accepts a run again after it
# (movimento.md, "Corrida na parede": "Fins da corrida"; "Mesma parede").
func test_the_run_ends_the_same_tick_the_body_touches_the_floor_and_the_floor_clears_the_wall(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_wall_a(rig)
	rig.airborne(
		Vector3(MovementRig.WALL_PROBE_DISTANCE / 2.0, LOW_START_HEIGHT_M, 0.0),
		Vector3(0.0, 0.0, -WALL_RUN_SPEED_MPS),
	)
	var entry_tick := _fly_until_wall_run(rig, 2)
	var landing_tick := -1
	for _step: int in WALL_RUN_MAX_TICKS[tickrate]:
		var was_running := rig.state.mode == FighterState.Mode.WALL_RUN
		rig.step(MovementRig.idle())
		if rig.state.on_floor:
			landing_tick = rig.tick - 1
			assert_bool(was_running).override_failure_message("left the wall before the floor") \
					.is_true()
			break
	assert_int(landing_tick).override_failure_message("never landed").is_greater(entry_tick)
	assert_int(landing_tick - entry_tick).is_greater(WALL_HOLD_TICKS[tickrate])
	assert_int(landing_tick - entry_tick).is_less(WALL_RUN_MAX_TICKS[tickrate])
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GROUND)
	assert_int(rig.state.mode_since).is_equal(landing_tick)
	assert_float(rig.position.y).is_equal(0.0)
	rig.step(MovementRig.idle())
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GROUND)
	assert_str(String(rig.state.wall_id)).override_failure_message("the floor kept the wall") \
			.is_equal("")
	assert_vector(rig.state.wall_normal).is_equal(Vector3.ZERO)
	rig.airborne(
		Vector3(MovementRig.WALL_PROBE_DISTANCE / 2.0, START_HEIGHT_M, 0.0),
		Vector3(0.0, 0.0, -WALL_RUN_SPEED_MPS),
	)
	var again := _fly_until_wall_run(rig, 2)
	_assert_wall_run_started(rig.state, again, WALL_A, Vector3.RIGHT)


# Criterion 4: an obstacle that drops the speed along the wall below 4 m/s ends the run on that
# tick: a wall across the way stops the body, the speed along falls to 0, and the state is AIR
# since that tick (movimento.md, "Corrida na parede": "Fins da corrida: trava abaixo de 4 m/s").
func test_the_run_ends_the_same_tick_an_obstacle_drops_the_speed_along_below_4_mps(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	rig.add_wall(Vector3.BACK, -EDGE_M, WALL_B) # the plane z = -EDGE_M, across the run
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	var entry_tick := _fly_until_wall_run(rig, 2 * tickrate)
	var end_tick := -1
	for _step: int in WALL_RUN_MAX_TICKS[tickrate]:
		rig.step(MovementRig.idle())
		if rig.state.mode != FighterState.Mode.WALL_RUN:
			end_tick = rig.tick - 1
			break
	assert_int(end_tick).override_failure_message("the run never ended").is_greater(entry_tick)
	assert_int(end_tick - entry_tick).is_less(WALL_HOLD_TICKS[tickrate])
	assert_float(rig.position.z).override_failure_message("passed the obstacle").is_equal_approx(
		-EDGE_M,
		GEOMETRY_HAIR,
	)
	assert_float(_along(rig.last_facts.velocity, Vector3.RIGHT).length()).is_less(
		WALL_ENTRY_SPEED_MPS
	)
	_assert_facts_wall(rig.last_facts, WALL_A)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	assert_int(rig.state.mode_since).is_equal(end_tick)
	assert_int(rig.state.jumps_used).is_equal(0)


# Criterion 5: a jump pressed during the run is the wall jump on that tick: 1,2 m up within
# 1 cm, 5 m/s out of the wall, the speed along kept, the first jump of the flight, with the
# double jump still available (movimento.md, "Corrida na parede": "Pulo da parede", "Pulo da
# parede no voo").
func test_a_jump_pressed_during_the_run_is_the_wall_jump_1_2_m_up_and_5_mps_out(
	tickrate: int,
	ticks_after_entry: int,
	_test_parameters := [[30, 1], [60, 1], [30, 5], [60, 5], [30, 44], [60, 89]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	_record_run(rig, ticks_after_entry - 1)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.WALL_RUN)
	var press_tick := rig.tick
	var press_height := rig.position.y
	var plan := rig.step(MovementRig.press_jump())
	_assert_wall_jumped(rig, plan, press_tick, Vector3.RIGHT, Vector3.FORWARD * WALL_RUN_SPEED_MPS)
	assert_vector(plan.velocity).is_equal_approx(
		Vector3(WALL_JUMP_PUSH_MPS, rig.config.wall_jump_speed, -WALL_RUN_SPEED_MPS),
		Vector3.ONE * HAIR,
	)
	_assert_height(_apex(rig, 2 * tickrate) - press_height, WALL_JUMP_HEIGHT_M, "wall jump")
	assert_int(rig.state.jumps_used).is_equal(1)
	assert_int(rig.state.wall_jump_tick).is_equal(press_tick)
	_assert_wall_id(rig.state, WALL_A)


# The apex of the wall jump comes rise_ticks after the press, like the full jump's: the same
# 1,2 m parabola (movimento.md, "Pulo e ar": "Tempo de subida"; "Corrida na parede": "Pulo da
# parede").
func test_the_wall_jump_tops_out_rise_ticks_after_the_press(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	_record_run(rig, 3)
	var press_height := rig.position.y
	rig.step(MovementRig.press_jump())
	var apex_step := 1
	var apex := rig.position.y
	for step: int in range(2, 2 * tickrate + 1):
		rig.step(MovementRig.idle())
		if rig.position.y > apex + HAIR:
			apex = rig.position.y
			apex_step = step
	assert_int(apex_step).is_equal(RISE_TICKS[tickrate])
	_assert_height(apex - press_height, WALL_JUMP_HEIGHT_M, "wall jump")


# The wall jump keeps a faster speed along the wall too: entered at 10, it leaves at 10 along
# and 5 out (movimento.md, "Corrida na parede": "Pulo da parede: mantém a velocidade ao longo").
func test_the_wall_jump_keeps_a_faster_speed_along_the_wall(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, 10.0, FALLING_VERTICAL_MPS)
	_record_run(rig, 2)
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_jump())
	_assert_wall_jumped(rig, plan, press_tick, Vector3.RIGHT, Vector3.FORWARD * 10.0)


# After the wall jump the double jump is still there: pressed a few ticks later it is the
# second jump of the flight, 1,0 m up within 1 cm (movimento.md, "Corrida na parede": "Pulo da
# parede no voo: conta como o primeiro pulo").
func test_the_double_jump_is_still_available_after_the_wall_jump(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	_record_run(rig, 2)
	var wall_jump_tick := rig.tick
	rig.step(MovementRig.press_jump())
	rig.rest(4)
	assert_int(rig.state.jumps_used).is_equal(1)
	var press_tick := rig.tick
	var press_height := rig.position.y
	var plan := rig.step(MovementRig.press_jump())
	_assert_double_jumped(rig, plan, press_tick)
	assert_int(plan.state.wall_jump_tick).is_equal(wall_jump_tick)
	_assert_height(_apex(rig, 2 * tickrate) - press_height, DOUBLE_JUMP_HEIGHT_M, "double jump")
	var third := rig.step(MovementRig.press_jump())
	assert_int(third.state.jumps_used).override_failure_message("a third jump").is_equal(2)
	assert_float(third.velocity.y).is_less(plan.velocity.y)


# Criterion 5: a jump pressed up to 150 ms before the touch waits in the slot (the double jump
# is spent, so it cannot fire in the air) and comes out as the wall jump on the first run tick,
# the one after the touch: pressed one tick before it and at the limit of the window, 9 ticks
# at 60 and 5 at 30 (movimento.md, "Corrida na parede": "Pulo da parede no voo: um pulo
# guardado até 150 ms antes de encostar sai no primeiro tick da corrida"; "Perdão"; DEC-0039).
func test_a_jump_pressed_up_to_150_ms_before_the_touch_fires_on_the_first_run_tick(
	tickrate: int,
	ticks_before_the_first_run_tick: int,
	_test_parameters := [[30, 1], [30, 5], [60, 1], [60, 9]],
) -> void:
	var probe := _air_rig(tickrate)
	_wall_a(probe)
	_approach_wall_a(probe, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	probe.state.jumps_used = 2
	probe.state.double_jump_tick = probe.tick - 1
	var entry_tick := _fly_until_wall_run(probe, 2 * tickrate)
	var first_run_tick := entry_tick + 1
	var press_tick := first_run_tick - ticks_before_the_first_run_tick
	assert_int(press_tick).is_greater_equal(FIRST_TICK)
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
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
	var plan := rig.step(MovementRig.idle())
	_assert_wall_jumped(
		rig,
		plan,
		first_run_tick,
		Vector3.RIGHT,
		Vector3.FORWARD * WALL_RUN_SPEED_MPS,
	)


func test_a_jump_pressed_one_tick_past_the_buffer_before_the_touch_does_not_fire(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var probe := _air_rig(tickrate)
	_wall_a(probe)
	_approach_wall_a(probe, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	probe.state.jumps_used = 2
	probe.state.double_jump_tick = probe.tick - 1
	var entry_tick := _fly_until_wall_run(probe, 2 * tickrate)
	var press_tick := entry_tick + 1 - BUFFER_TICKS[tickrate] - 1
	assert_int(press_tick).is_greater_equal(FIRST_TICK)
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	rig.state.jumps_used = 2
	rig.state.double_jump_tick = rig.tick - 1
	while rig.tick <= entry_tick:
		rig.step(MovementRig.press_jump() if rig.tick == press_tick else MovementRig.idle())
	_assert_wall_run_started(rig.state, entry_tick, WALL_A, Vector3.RIGHT)
	var violations: Array[String] = []
	for step: int in range(1, 2 * BUFFER_TICKS[tickrate] + 1):
		var plan := rig.step(MovementRig.idle())
		if (
			plan.state.mode != FighterState.Mode.WALL_RUN
			or plan.state.wall_jump_tick != FighterState.NEVER
		):
			violations.append(
				"tick +%d: left the wall (wall_jump_tick %d)" % [step, plan.state.wall_jump_tick]
			)
	assert_array(violations).override_failure_message("%s" % [violations]).is_empty()
	_assert_slot(rig.state, FighterCommand.NONE, FighterState.NEVER)


# Criterion 5, the momentum after the wall jump: at 9,43 m/s (8 along and 5 out), above the run
# speed of 7, an input along the velocity keeps it whole until the landing would come: the
# excess is never cut (movimento.md, "Pulo e ar": "Controle no ar"; "Princípios": "a velocidade
# se conserva entre manobras"; F-127, Q-07). The rest of the momentum rule is in
# movement_momentum_test.gd.
func test_the_speed_of_the_wall_jump_is_not_cut_by_an_input_along_it(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	_record_run(rig, 2)
	var plan := rig.step(MovementRig.press_jump())
	var launched := _horizontal(plan.velocity)
	var speed := launched.length()
	assert_float(speed).is_greater(RUN_SPEED_MPS + 1.0)
	# move.x goes right (+X) and move.y forward (-Z) at yaw 0: the stick pointed along the flight.
	var along := Vector2(launched.x, -launched.z).normalized()
	var violations: Array[String] = []
	for step: int in range(1, tickrate + 1):
		var next := rig.step(MovementRig.run(along))
		if absf(_horizontal(next.velocity).length() - speed) > 1e-4:
			violations.append(
				"tick +%d: %.4f m/s, launched at %.4f"
				% [step, _horizontal(next.velocity).length(), speed]
			)
	assert_array(violations).override_failure_message("%s" % [violations]).is_empty()


# Criterion 7, the Resource half (DEC-0004, rule 3): the apex of the wall jump follows
# wall_jump_height_m of a duplicated MovementData, without touching code. 0.5 and 2.0 m are
# arbitrary heights, not design numbers.
func test_the_wall_jump_height_follows_the_duplicated_resource(
	tickrate: int,
	height_m: float,
	_test_parameters := [[30, 0.5], [30, 2.0], [60, 0.5], [60, 2.0]],
) -> void:
	var data := _v0_copy()
	data.wall_jump_height_m = height_m
	assert_array(data.validate()).is_empty()
	var rig := MovementRig.new(MovementConfig.create(data, tickrate), FIRST_TICK)
	rig.floor_on = false
	_wall_a(rig)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	_record_run(rig, 2)
	var press_height := rig.position.y
	var plan := rig.step(MovementRig.press_jump())
	assert_int(plan.state.jumps_used).is_equal(1)
	assert_float(plan.velocity.y).is_equal_approx(rig.config.wall_jump_speed, HAIR)
	_assert_height(
		_apex(rig, 3 * tickrate) - press_height,
		height_m,
		"wall jump of %.1f m" % height_m,
	)


# The wall jump's exit speed for 1,2 m is the jump's own: the same parabola on the ticks
# (movimento.md, "Pulo e ar", "No tick"; "Corrida na parede": "Pulo da parede: 1,2 m").
func test_the_wall_jump_speed_equals_the_jump_speed_for_the_same_height(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var config := MovementRig.load_config(tickrate)
	assert_float(WALL_JUMP_HEIGHT_M).is_equal(JUMP_HEIGHT_M)
	assert_float(config.wall_jump_speed).is_equal_approx(config.jump_speed, HAIR)


# Criterion 6: back on the same wall after the wall jump, without the floor or another wall in
# between, the touch starts no run: the body slides along it and keeps falling, the state keeps
# the wall as the last one and the jump count of the flight (movimento.md, "Corrida na parede":
# "Mesma parede: só vale de novo depois de tocar o chão ou outra parede").
func test_the_same_wall_refuses_a_new_run_after_the_wall_jump(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	_record_run(rig, 2)
	rig.step(MovementRig.press_jump())
	rig.rest(AWAY_TICKS)
	assert_float(rig.position.x).is_greater(MovementRig.WALL_PROBE_DISTANCE)
	# Thrown back at the wall by hand, with the push of the jump reversed.
	rig.velocity = Vector3(-THROWN_BACK_MPS, rig.velocity.y, rig.velocity.z)
	var touched := _fly_without_wall_run(rig, tickrate, WALL_A)
	assert_bool(touched).override_failure_message("never came back to the wall").is_true()
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	_assert_wall_id(rig.state, WALL_A)
	assert_int(rig.state.jumps_used).is_equal(1)
	assert_float(rig.velocity.x).override_failure_message("passed through the wall").is_equal(0.0)
	assert_float(rig.horizontal_speed()).is_equal_approx(WALL_RUN_SPEED_MPS, HAIR)


# Another wall in the same plane is another wall: back from the jump onto a second block of
# the same plane, with its own id, the run starts (criterion 6: "outra parede aceita, mesmo no
# mesmo plano"; DEC-0042 §2: the id is the collider's path).
func test_another_wall_in_the_same_plane_accepts_a_run_after_the_wall_jump(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	var first := _wall_a(rig)
	first.along_max = first.along_of(Vector3(0.0, 0.0, -SEAM_NEAR_M))
	var second := rig.add_wall(Vector3.RIGHT, 0.0, WALL_A2)
	second.along_min = first.along_max
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	_record_run(rig, 1)
	_assert_wall_id(rig.state, WALL_A)
	assert_float(rig.position.z).override_failure_message("past the seam before the jump") \
			.is_greater(-SEAM_NEAR_M)
	rig.step(MovementRig.press_jump())
	rig.rest(AWAY_TICKS)
	rig.velocity = Vector3(-THROWN_BACK_MPS, rig.velocity.y, rig.velocity.z)
	var entry_tick := _fly_until_wall_run(rig, tickrate)
	assert_float(rig.position.z).override_failure_message("came back before the seam").is_less(
		-SEAM_NEAR_M
	)
	_assert_wall_run_started(rig.state, entry_tick, WALL_A2, Vector3.RIGHT)


# The same wall in numbers: the same collider with the normal within 10°, inclusive, is the
# same wall and refuses; beyond 10°, the same collider is another face and accepts: 0°, 5° and
# the limit refuse; just past the limit, 15° and 90° (the next face of a box) accept
# (movimento.md, "Corrida na parede": "Mesma parede, em números"; DEC-0042 §3).
func test_the_same_collider_within_10_degrees_is_the_same_wall_and_beyond_it_is_another(
	tickrate: int,
	turned_deg: float,
	accepts: bool,
	_test_parameters := [
		[60, 0.0, false],
		[30, 0.0, false],
		[60, 5.0, false],
		[60, WALL_SAME_FACE_DEG - LIMIT_STEP_DEG, false],
		[30, WALL_SAME_FACE_DEG - LIMIT_STEP_DEG, false],
		[60, WALL_SAME_FACE_DEG + 0.001, true],
		[60, 15.0, true],
		[30, 15.0, true],
		[60, 90.0, true],
	],
) -> void:
	var rig := _air_rig(tickrate)
	var normal := _turned_normal(turned_deg)
	var anchor := Vector3(0.0, START_HEIGHT_M, 0.0)
	rig.add_wall(normal, normal.dot(anchor), BOX)
	# As after a wall jump from the +X face of the box: the last wall in the state, one jump used.
	var tangent := Vector3.UP.cross(normal).normalized()
	rig.airborne(
		anchor + normal * APPROACH_M,
		-normal * APPROACH_SPEED_MPS + tangent * WALL_RUN_SPEED_MPS
		+ Vector3.UP * FALLING_VERTICAL_MPS,
	)
	rig.state.wall_id = BOX
	rig.state.wall_normal = Vector3.RIGHT
	rig.state.jumps_used = 1
	rig.state.wall_jump_tick = rig.tick - 1
	if accepts:
		var entry_tick := _fly_until_wall_run(rig, 2 * tickrate)
		_assert_wall_run_started(rig.state, entry_tick, BOX, normal)
	else:
		var touched := _fly_without_wall_run(rig, 2 * tickrate, BOX)
		assert_bool(touched).override_failure_message("the wall was never touched").is_true()
		_assert_wall_id(rig.state, BOX)
		assert_int(rig.state.jumps_used).is_equal(1)


# The corridor is climbed by alternating the walls: wall jump from A, run on B, wall jump from
# B, run on A again (another wall in between, so A accepts), each entry higher than the last
# (criterion 6; TASK-10.5, "Números v0": the corridor; movimento.md, "Princípios": the maneuvers
# chain).
func test_the_corridor_is_climbed_by_alternating_the_walls(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	rig.add_wall(Vector3.LEFT, -CORRIDOR_GAP_M, WALL_B) # the plane x = CORRIDOR_GAP_M, facing -X
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	var expected_walls: Array[StringName] = [WALL_A, WALL_B, WALL_A, WALL_B]
	var heights: Array[float] = []
	for hop: int in expected_walls.size():
		var entry_tick := _fly_until_wall_run(rig, 2 * tickrate)
		var normal := Vector3.RIGHT if expected_walls[hop] == WALL_A else Vector3.LEFT
		_assert_wall_run_started(rig.state, entry_tick, expected_walls[hop], normal)
		heights.append(rig.position.y)
		var press_tick := rig.tick
		var plan := rig.step(MovementRig.press_jump())
		_assert_wall_jumped(rig, plan, press_tick, normal, Vector3.FORWARD * WALL_RUN_SPEED_MPS)
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


# The seam (F-129; movimento.md, "Corrida na parede": "Emenda"): a new collider in the same
# plane, met during the run without losing contact, continues the run: the id and the normal
# pass to the new block, mode_since stays, the slide keeps counting, the double jump is not
# renewed again, and the run still ends by time counted from the first entry.
func test_a_new_collider_in_the_same_plane_during_the_run_continues_it(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	var first := _wall_a(rig)
	first.along_max = first.along_of(Vector3(0.0, 0.0, -FAR_M))
	var second := rig.add_wall(Vector3.RIGHT, 0.0, WALL_A2)
	second.along_min = first.along_max
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	var hold := WALL_HOLD_TICKS[tickrate]
	var max_ticks := WALL_RUN_MAX_TICKS[tickrate]
	var record := _record_run(rig, max_ticks)
	# The seam tick: the first whose after_move saw the second block.
	var seam_step := -1
	for step: int in range(1, max_ticks):
		if record.state_at(step).wall_id == WALL_A2:
			seam_step = step
			break
	assert_int(seam_step).override_failure_message("the seam was never crossed").is_greater(hold)
	assert_int(seam_step).is_less(max_ticks - 2)
	var at_seam := record.state_at(seam_step)
	_assert_wall_id(record.state_at(seam_step - 1), WALL_A)
	assert_int(at_seam.mode).is_equal(FighterState.Mode.WALL_RUN)
	assert_int(at_seam.mode_since).override_failure_message("the seam restarted the run") \
			.is_equal(record.entry_tick)
	assert_vector(at_seam.wall_normal).is_equal_approx(Vector3.RIGHT, Vector3.ONE * HAIR)
	assert_int(at_seam.jumps_used).is_equal(0)
	assert_int(at_seam.double_jump_tick).is_equal(FighterState.NEVER)
	# The vertical keeps the slide's count across the seam: the plan of the seam tick was made
	# on the first block at -k times the gravity, the next one on the second block at -(k + 1).
	var slide_gravity := rig.config.wall_slide_gravity_per_tick
	var k_at_seam := seam_step - hold + 1
	assert_float(record.plan_at(seam_step).velocity.y).is_equal_approx(
		-k_at_seam * slide_gravity,
		HAIR,
	)
	assert_float(record.plan_at(seam_step + 1).velocity.y).is_equal_approx(
		-(k_at_seam + 1) * slide_gravity,
		HAIR,
	)
	_assert_wall_id(record.state_at(seam_step + 1), WALL_A2)
	assert_int(record.wall_run_ticks()).is_equal(max_ticks)
	_assert_height(
		record.entry_height - record.height_at(max_ticks - 1),
		SLIDE_DROP_M[tickrate],
		"lost by the end of the run across the seam",
	)
	var after := record.plan_at(max_ticks).state
	assert_int(after.mode).is_equal(FighterState.Mode.AIR)
	assert_int(after.mode_since).is_equal(record.entry_tick + max_ticks)
	_assert_wall_id(after, WALL_A2)


# A new collider beyond 10° during the run is another face: it ends the run on that tick, and
# a new run starts the same tick if it qualifies: a 45° bend keeps 5,66 m/s along the new face,
# so the run restarts there, mode_since on that tick, the vertical zeroed again and the speed
# brought back to 8 (seam rule, F-129; movimento.md, "Corrida na parede": "Fins da corrida").
func test_a_new_collider_beyond_10_degrees_during_the_run_ends_it_and_a_new_run_may_start(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	var first := _wall_a(rig)
	first.along_max = first.along_of(Vector3(0.0, 0.0, -FAR_M))
	var corner := Vector3(0.0, 0.0, -FAR_M)
	var bend := Vector3(sin(deg_to_rad(CORNER_DEG)), 0.0, cos(deg_to_rad(CORNER_DEG)))
	rig.add_wall(bend, bend.dot(corner), WALL_B)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS, FALLING_VERTICAL_MPS)
	var hold := WALL_HOLD_TICKS[tickrate]
	var max_ticks := WALL_RUN_MAX_TICKS[tickrate]
	var record := _record_run(rig, max_ticks)
	# The corner tick: the first whose after_move saw the bend.
	var corner_step := -1
	for step: int in range(1, max_ticks):
		if record.state_at(step).wall_id == WALL_B:
			corner_step = step
			break
	assert_int(corner_step).override_failure_message("the corner was never reached") \
			.is_greater(hold)
	assert_int(corner_step).is_less(max_ticks - 2)
	var at_corner := record.state_at(corner_step)
	_assert_wall_id(record.state_at(corner_step - 1), WALL_A)
	assert_float(record.plan_at(corner_step).velocity.y).is_less(-HAIR) # was sliding on A
	var corner_tick := record.entry_tick + corner_step
	_assert_wall_run_started(at_corner, corner_tick, WALL_B, bend)
	var next := record.plan_at(corner_step + 1)
	var tangent := Vector3.UP.cross(bend).normalized()
	assert_int(next.state.mode).is_equal(FighterState.Mode.WALL_RUN)
	assert_int(next.state.mode_since).is_equal(corner_tick)
	assert_float(next.velocity.y).override_failure_message("the new run kept the vertical") \
			.is_equal(0.0)
	assert_vector(_horizontal(next.velocity)).is_equal_approx(
		tangent * WALL_RUN_SPEED_MPS,
		Vector3.ONE * GEOMETRY_HAIR,
	)
	# The new run has its own clock: it outlives the first run's 2,5 s.
	var last := record.plan_at(max_ticks).state
	assert_int(last.mode).override_failure_message("the new run ended on the old clock") \
			.is_equal(FighterState.Mode.WALL_RUN)
	assert_int(last.mode_since).is_equal(corner_tick)
