# Criteria 1 to 4 of TASK-10.13: the same wall accepts a new run again, with the entry rules of
# every run, and that run does not renew the double jump; only the floor or a run on another wall
# renew it, and another fighter's head changes neither (DEC-0047 §1 to §3; DEC-0046 §1). The
# limit: going back and forth on one wall with the double jump, pressing the jump whenever it
# can, the feet never pass 3,5 m above the first run (TASK-10.13, "Números v0": +2,2 m at the
# re-entry, +1,2 m with the next wall jump, about +3,4 m, measured with 10 cm of slack). Through
# the public interface of core/fighter, with the engine's slice of the tick played by MovementRig
# against fake walls and heads (visao-geral.md, "O tick por dentro: o sanduíche"; rede.md §4).
# Every number comes from docs/design/movimento.md or the task, cited by section; ticks by hand
# from the ms, nearest tick with ties up (visao-geral.md, "O tempo e a física no estado").
extends GdUnitTestSuite

const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)

# movimento.md, "Corrida na parede".
const WALL_ENTRY_SPEED_MPS := 4.0 # "Velocidade mínima para entrar", along the wall
const WALL_RUN_SPEED_MPS := 8.0 # "Velocidade na parede"
const WALL_MAX_SPEED_MPS := 12.0 # "Teto de velocidade na parede"
const WALL_RUN_MAX_MS := 2500 # "Duração máxima": 2,5 s
const WALL_HOLD_MS := 1500 # "Altura": mantida por 1,5 s
const WALL_JUMP_HEIGHT_M := 1.2 # "Pulo da parede": 1,2 m de altura
const WALL_JUMP_PUSH_MPS := 5.0 # "Pulo da parede": 5 m/s para fora da parede

# movimento.md, "Pulo e ar".
const DOUBLE_JUMP_HEIGHT_M := 1.0 # "Altura do pulo duplo"
const HEIGHT_TOLERANCE_M := 0.01 # 1 cm (visao-geral.md, "O tempo e a física no estado")

# TASK-10.13, "Números v0": "os pés nunca passam de 3,5 m acima da primeira corrida", the paper
# +3,4 m (1,2 + 1,0 at the re-entry, 1,2 with the next wall jump) with 10 cm of slack.
const LADDER_LIMIT_M := 3.5
# What one wall gave before this rule: the wall jump and the double jump, +2,2 m (DEC-0047,
# "Opções consideradas" 1: "o mais alto passa de +2,2 m para +3,4 m, uma vez").
const OLD_CLIMB_M := WALL_JUMP_HEIGHT_M + DOUBLE_JUMP_HEIGHT_M

# The wall times by hand (movimento.md, "Corrida na parede"): 1,5 s of held height is 45 ticks
# at 30 and 90 at 60; 2,5 s of run is 75 and 150, exact.
const WALL_HOLD_TICKS: Dictionary[int, int] = { 30: 45, 60: 90 }
const WALL_RUN_MAX_TICKS: Dictionary[int, int] = { 30: 75, 60: 150 }
# 150 ms of buffer is 4.5 -> 5 at 30 (tie up) and 9 at 60, inclusive (movimento.md, "Perdão";
# DEC-0039).
const BUFFER_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }
const HALF_TICK_IN_MS_TIMES_RATE := 500 # |ticks * 1000 - ms * rate| <= 500 is half a tick

# Criterion 1: the speeds along the wall at the re-entry, as at any entry (movimento.md, "Corrida
# na parede": "Velocidade na parede", "Teto de velocidade na parede"): 4 runs at 8, 10 keeps 10,
# 14 is capped at 12. 3,9 m/s and head-on (0 along) are refused.
const ENTRY_TO_RUN_SPEED: Dictionary[float, float] = {
	WALL_ENTRY_SPEED_MPS: WALL_RUN_SPEED_MPS,
	10.0: 10.0,
	14.0: WALL_MAX_SPEED_MPS,
}
const BELOW_ENTRY_SPEED_MPS := 3.9
const HEAD_ON_MPS := 0.0

# The geometry of the rig, not design numbers (as in movement_wall_test.gd). The body approaches
# the wall from APPROACH_M in front of it at APPROACH_SPEED_MPS into it; START_HEIGHT_M keeps
# the floor far below in the rigs that have one switched off.
const APPROACH_M := 0.9
const APPROACH_SPEED_MPS := 2.0
const START_HEIGHT_M := 10.0
const FALLING_VERTICAL_MPS := -6.0
const LOW_START_HEIGHT_M := 0.5 # with the floor on: the run starts just above it
const AWAY_TICKS := 6 # ticks idled away from the wall after the wall jump, before coming back
const THROWN_BACK_MPS := 5.0 # the push of the wall jump, reversed by hand
const RUN_TICKS_BEFORE_THE_JUMP := 2
const AIR_TICKS_BEFORE_THE_PRESS := 3
const CORRIDOR_GAP_M := 2.8 # the planned corridor, centre to centre (TASK-10.5, "Números v0")
const HEAD_BELOW_M := 0.5 # a head placed under the feet, this far below, catches the fall
const LADDER_CYCLES := 3 # wall jump, back to the same wall, three times over
const GREEDY_SECONDS := 6
const RETURN_LIMIT_S := 3 # the body must find the wall again within this
# The stick into the wall, measured from the run's direction: 45° shares the speed between
# "into" and "along"; 25° keeps more along and reaches the wall later, nearer the apex.
const INTO_45 := 45.0
const INTO_25 := 25.0
const WALL_A := &"ParedeA" # ids as the adapter reports them: node paths relative to the Arena
const WALL_B := &"ParedeB"

const HAIR := 1e-6 # floating-point slack, not a design number
const GEOMETRY_HAIR := 1e-4 # a Vector3 holds 32-bit floats: a tilted clamp carries that error


# What a stretch of flight did, step by step: the highest the feet got, the entries on the wall
# (the state going into WALL_RUN), the distinct wall jumps and double jumps by their stamps.
class Climb:
	var first_run_height := 0.0
	var max_height := -INF
	var entries := 0
	var entry_heights: Array[float] = []
	var wall_jump_ticks: Array[int] = []
	var double_jump_ticks: Array[int] = []


	func climbed() -> float:
		return max_height - first_run_height


func _rig(tickrate: int) -> MovementRig:
	return MovementRig.new(MovementRig.load_config(tickrate), FIRST_TICK)


# A rig with no floor at all: the body never lands, the wall is the only contact.
func _air_rig(tickrate: int) -> MovementRig:
	var rig := _rig(tickrate)
	rig.floor_on = false
	return rig


func _horizontal(velocity: Vector3) -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)


# The wall at x = 0 facing +X: the body runs along -Z beside it.
func _wall_a(rig: MovementRig) -> MovementRig.FakeWall:
	return rig.add_wall(Vector3.RIGHT, 0.0, WALL_A)


# The facing wall of the corridor: the plane x = CORRIDOR_GAP_M, facing -X.
func _wall_b(rig: MovementRig) -> MovementRig.FakeWall:
	return rig.add_wall(Vector3.LEFT, -CORRIDOR_GAP_M, WALL_B)


# The stick pointed into WALL_A and along the run: move.x goes right (+X) and move.y forward
# (-Z) at yaw 0 (TASK-9 plan), so (-sin, cos) points -X by sin and -Z by cos.
func _into_the_wall(angle_deg: float) -> Vector2:
	var a := deg_to_rad(angle_deg)
	return Vector2(-sin(a), cos(a))


# Puts the body in the air APPROACH_M in front of the plane x = 0, flying into it at
# APPROACH_SPEED_MPS while running -Z at along_speed, falling.
func _approach_wall_a(rig: MovementRig, along_speed: float) -> void:
	rig.airborne(
		Vector3(APPROACH_M, START_HEIGHT_M, 0.0),
		Vector3(-APPROACH_SPEED_MPS, FALLING_VERTICAL_MPS, -along_speed),
	)


# Steps with this input until the core starts a wall run; returns the entry tick, or fails and
# returns -1 (the callers stop there instead of pressing in the void).
func _fly_until_wall_run(rig: MovementRig, limit: int, input: TickInput = null) -> int:
	for _step: int in limit:
		rig.step(MovementRig.idle() if input == null else input)
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


# Approaches WALL_A at 8 m/s along it and runs RUN_TICKS_BEFORE_THE_JUMP ticks on it; returns
# the entry tick.
func _run_on_wall_a(rig: MovementRig) -> int:
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS)
	var entry_tick := _fly_until_wall_run(rig, 2 * rig.config.tickrate)
	rig.rest(RUN_TICKS_BEFORE_THE_JUMP)
	assert_int(rig.state.mode).override_failure_message("left the wall").is_equal(
		FighterState.Mode.WALL_RUN
	)
	return entry_tick


# Presses the jump now on the wall, with the stick as given; asserts the wall jump as the plan
# says it (movimento.md, "Corrida na parede": "Pulo da parede"): the exit speed of 1,2 m, 5 m/s
# out of the wall, AIR since now and the stamp. Returns the press tick.
func _wall_jump(rig: MovementRig, move := Vector2.ZERO) -> int:
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_jump_toward(move))
	assert_int(plan.state.mode).override_failure_message("still on the wall").is_equal(
		FighterState.Mode.AIR
	)
	assert_int(plan.state.mode_since).is_equal(press_tick)
	assert_int(plan.state.wall_jump_tick).is_equal(press_tick)
	assert_float(plan.velocity.y).override_failure_message("not the wall jump's exit speed") \
			.is_equal_approx(rig.config.wall_jump_speed, HAIR)
	var out := _horizontal(plan.velocity).dot(Vector3.RIGHT)
	assert_float(out).override_failure_message("%.4f m/s out of the wall" % out).is_equal_approx(
		WALL_JUMP_PUSH_MPS,
		HAIR,
	)
	return press_tick


# Idles AWAY_TICKS after the wall jump, then throws the body back at WALL_A by hand with the
# push reversed and this speed along the wall (the way movement_wall_test.gd comes back).
func _throw_back(rig: MovementRig, along_speed := WALL_RUN_SPEED_MPS) -> void:
	rig.rest(AWAY_TICKS)
	assert_float(rig.position.x).override_failure_message("still beside the wall").is_greater(
		MovementRig.WALL_PROBE_DISTANCE
	)
	rig.velocity = Vector3(-THROWN_BACK_MPS, rig.velocity.y, -along_speed)


# The double jump spent by hand in the air, the way movement_wall_test.gd spends it: used on the
# tick before now. Returns its stamp.
func _spend_by_hand(rig: MovementRig) -> int:
	rig.state.jumps_used = 2
	rig.state.double_jump_tick = rig.tick - 1
	return rig.state.double_jump_tick


# Idles AWAY_TICKS after the wall jump, throws the body back at WALL_A by hand as _throw_back
# does, and flies until the core starts a wall run, pressing the jump on press_tick wherever it
# falls in that flight (NEVER presses nothing). Returns the entry tick, or fails and returns -1.
func _come_back_pressing_at(rig: MovementRig, press_tick: int) -> int:
	for _step: int in AWAY_TICKS:
		rig.step(MovementRig.press_jump() if rig.tick == press_tick else MovementRig.idle())
	assert_float(rig.position.x).override_failure_message("still beside the wall").is_greater(
		MovementRig.WALL_PROBE_DISTANCE
	)
	rig.velocity = Vector3(-THROWN_BACK_MPS, rig.velocity.y, -WALL_RUN_SPEED_MPS)
	for _step: int in rig.config.tickrate:
		rig.step(MovementRig.press_jump() if rig.tick == press_tick else MovementRig.idle())
		if rig.state.mode == FighterState.Mode.WALL_RUN:
			return rig.tick - 1
	fail("never came back to a wall run (at %d ticks)" % rig.config.tickrate)
	return -1


# Presses the jump in the air with the stick into the wall; asserts the double jump as the plan
# says it (TASK-10.1 plan): its own exit speed, the second jump, the stamp, the cost paid now.
# Returns the press tick.
func _double_jump_into_the_wall(rig: MovementRig) -> int:
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_jump_toward(_into_the_wall(INTO_45)))
	_assert_double_jumped(rig, plan, press_tick)
	var into := _horizontal(plan.velocity).dot(Vector3.LEFT)
	assert_float(into).override_failure_message("not turned into the wall").is_greater(
		WALL_ENTRY_SPEED_MPS
	)
	return press_tick


# Steps with this input until the body stops rising (the rig's velocity after the move is no
# longer upward); returns the highest position.y seen, or fails.
func _rise_to_apex(rig: MovementRig, limit: int, input: TickInput = null) -> float:
	var apex := rig.position.y
	for _step: int in limit:
		if rig.velocity.y <= 0.0:
			return apex
		rig.step(MovementRig.idle() if input == null else input)
		apex = maxf(apex, rig.position.y)
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


# The entry as the plan says it (TASK-10.5 plan; DEC-0042), without a word on the double jump:
# WALL_RUN since the entry tick, the wall's id and flattened normal in the state.
func _assert_wall_run_entered(
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


# The entry on another wall, or after the floor: the double jump renewed (movimento.md, "Pulo e
# ar": "Renovação do pulo duplo"; DEC-0047 §2: "Só o chão ou uma corrida em outra parede o
# devolvem").
func _assert_wall_run_renewed(
	state: FighterState,
	entry_tick: int,
	wall: StringName,
	normal: Vector3,
) -> void:
	_assert_wall_run_entered(state, entry_tick, wall, normal)
	assert_int(state.jumps_used).override_failure_message("the double jump was not renewed") \
			.is_equal(0)
	assert_int(state.double_jump_tick).is_equal(FighterState.NEVER)


# The entry on the same wall: the run starts, and the double jump is as it was (DEC-0047 §2:
# "Gasto, ele segue gasto; disponível, segue disponível").
func _assert_same_wall_run_kept(
	state: FighterState,
	entry_tick: int,
	jumps_used: int,
	double_jump_tick: int,
) -> void:
	_assert_wall_run_entered(state, entry_tick, WALL_A, Vector3.RIGHT)
	var message := "jumps_used %d and double_jump_tick %d at the re-entry, expected %d and %d" % [
		state.jumps_used,
		state.double_jump_tick,
		jumps_used,
		double_jump_tick,
	]
	assert_int(state.jumps_used).override_failure_message(message).is_equal(jumps_used)
	assert_int(state.double_jump_tick).override_failure_message(message).is_equal(double_jump_tick)


# A tick of the run: WALL_RUN, the horizontal velocity along -Z at this speed, the vertical 0.
func _assert_run_tick(plan: MovePlan, speed: float) -> void:
	assert_int(plan.state.mode).override_failure_message("not in WALL_RUN").is_equal(
		FighterState.Mode.WALL_RUN
	)
	var expected := Vector3.FORWARD * speed
	var message := "horizontal velocity %s, expected %s" % [_horizontal(plan.velocity), expected]
	assert_vector(_horizontal(plan.velocity)).override_failure_message(message).is_equal_approx(
		expected,
		Vector3.ONE * HAIR,
	)
	assert_float(plan.velocity.y).override_failure_message("the vertical was not zeroed") \
			.is_equal_approx(0.0, HAIR)


func _assert_double_jumped(rig: MovementRig, plan: MovePlan, press_tick: int) -> void:
	assert_float(plan.velocity.y).override_failure_message("not the double jump speed") \
			.is_equal_approx(rig.config.double_jump_speed, HAIR)
	assert_int(plan.state.jumps_used).override_failure_message("not the second jump").is_equal(2)
	assert_int(plan.state.double_jump_tick).is_equal(press_tick)
	assert_int(plan.state.stamina_spent_tick).override_failure_message("the cost was not paid") \
			.is_equal(press_tick)
	_assert_slot(plan.state, FighterCommand.NONE, FighterState.NEVER)


# A press that finds no double jump: no impulse (the vertical only falls by gravity), the stamp
# and the bar untouched, and the press waiting in the slot as any press the air cannot serve
# (movimento.md, "Perdão": "um aperto que ainda não pode sair espera na vaga").
func _assert_double_jump_refused(
	plan: MovePlan,
	press_tick: int,
	double_jump_tick: int,
	vertical_before: float,
) -> void:
	assert_float(plan.velocity.y).override_failure_message("a double jump came out") \
			.is_less_equal(vertical_before + HAIR)
	assert_int(plan.state.double_jump_tick).override_failure_message("restamped").is_equal(
		double_jump_tick
	)
	assert_int(plan.state.stamina_spent_tick).override_failure_message("something was paid") \
			.is_equal(double_jump_tick)
	_assert_slot(plan.state, FighterCommand.JUMP, press_tick)


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


# One step of a climb: moves and records the height, the entries and the stamps.
func _climb_step(rig: MovementRig, input: TickInput, climb: Climb) -> MovePlan:
	var was_running := rig.state.mode == FighterState.Mode.WALL_RUN
	var plan := rig.step(input)
	climb.max_height = maxf(climb.max_height, rig.position.y)
	if rig.state.mode == FighterState.Mode.WALL_RUN and not was_running:
		climb.entries += 1
		climb.entry_heights.append(rig.position.y)
	var wall_jump := rig.state.wall_jump_tick
	if wall_jump != FighterState.NEVER and not climb.wall_jump_ticks.has(wall_jump):
		climb.wall_jump_ticks.append(wall_jump)
	var double_jump := rig.state.double_jump_tick
	if double_jump != FighterState.NEVER and not climb.double_jump_ticks.has(double_jump):
		climb.double_jump_ticks.append(double_jump)
	return plan


# Criterion 1: back on the same wall after the wall jump, without the floor or another wall in
# between, the touch starts a new run on that tick, as any entry: WALL_RUN since the re-entry,
# the wall's id and normal, the vertical zeroed and the run at 8 m/s from the next tick
# (DEC-0047 §1; movimento.md, "Corrida na parede": "Como entra", "O que decide a entrada").
func test_back_on_the_same_wall_after_the_wall_jump_a_new_run_starts(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	var first_entry := _run_on_wall_a(rig)
	_wall_jump(rig)
	# The way back is long enough for the touch to come while falling at both rates (F-168 §2):
	# idle to the apex of the wall jump, by the rig's own predicate (the velocity after the move
	# no longer rises), then thrown back at the wall by hand with the push of the jump reversed.
	_rise_to_apex(rig, 2 * tickrate)
	assert_float(rig.position.x).override_failure_message("still beside the wall").is_greater(
		MovementRig.WALL_PROBE_DISTANCE
	)
	rig.velocity = Vector3(-THROWN_BACK_MPS, rig.velocity.y, -WALL_RUN_SPEED_MPS)
	var entry_tick := _fly_until_wall_run(rig, tickrate)
	assert_int(entry_tick).is_greater(first_entry)
	assert_float(rig.last_facts.velocity.y).override_failure_message("not falling at the touch") \
			.is_less(-HAIR)
	_assert_wall_run_entered(rig.state, entry_tick, WALL_A, Vector3.RIGHT)
	assert_str(String(rig.last_facts.wall_id)).is_equal(String(WALL_A))
	assert_float(rig.position.x).override_failure_message("not beside the wall").is_between(
		-HAIR,
		MovementRig.WALL_PROBE_DISTANCE + HAIR,
	)
	var entry_height := rig.position.y
	var first := rig.step(MovementRig.idle())
	_assert_run_tick(first, WALL_RUN_SPEED_MPS)
	assert_float(rig.position.y).is_equal_approx(entry_height, HAIR)
	var second := rig.step(MovementRig.idle())
	_assert_run_tick(second, WALL_RUN_SPEED_MPS)
	assert_int(rig.state.mode_since).is_equal(entry_tick)


# Criterion 1: the re-entry obeys the speed rule of every entry: 4 m/s along the wall runs at 8,
# 10 keeps 10, 14 is capped at 12 (movimento.md, "Corrida na parede": "Velocidade na parede",
# "Teto de velocidade na parede").
func test_the_re_entry_on_the_same_wall_keeps_the_entry_speed_from_8_up_to_12(
	tickrate: int,
	along_speed: float,
	_test_parameters := [[30, 4.0], [60, 4.0], [30, 10.0], [60, 10.0], [30, 14.0], [60, 14.0]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_run_on_wall_a(rig)
	_wall_jump(rig)
	_throw_back(rig, along_speed)
	var entry_tick := _fly_until_wall_run(rig, tickrate)
	_assert_wall_run_entered(rig.state, entry_tick, WALL_A, Vector3.RIGHT)
	var run_speed: float = ENTRY_TO_RUN_SPEED[along_speed]
	for _step: int in 3:
		_assert_run_tick(rig.step(MovementRig.idle()), run_speed)


# Failure: the re-entry is refused as any entry would be: below 4 m/s along the wall, or head-on,
# the touch starts nothing, the body slides along it, the state keeps the wall as the last one
# and the jump count of the flight (movimento.md, "Corrida na parede": "Velocidade mínima para
# entrar: 4"; "De frente para a parede não entra").
func test_back_on_the_same_wall_too_slow_along_it_or_head_on_the_touch_starts_no_run(
	tickrate: int,
	along_speed: float,
	_test_parameters := [
		[30, BELOW_ENTRY_SPEED_MPS],
		[60, BELOW_ENTRY_SPEED_MPS],
		[30, HEAD_ON_MPS],
		[60, HEAD_ON_MPS],
	],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_run_on_wall_a(rig)
	_wall_jump(rig)
	_throw_back(rig, along_speed)
	var touched := _fly_without_wall_run(rig, tickrate, WALL_A)
	assert_bool(touched).override_failure_message("never came back to the wall").is_true()
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	_assert_wall_id(rig.state, WALL_A)
	assert_int(rig.state.jumps_used).is_equal(1)
	assert_float(rig.velocity.x).override_failure_message("passed through the wall").is_equal(0.0)


# Criterion 1: the new run has its own clock, counted from the re-entry: the height holds 1,5 s
# and the run ends by time 2,5 s after it, not after the first entry (movimento.md, "Corrida na
# parede": "Altura", "Duração máxima"). The ms become ticks by the rule of Ticks.from_ms, within
# half a tick (DEC-0004, rule 3): 90 and 150 at 60, 45 and 75 at 30.
func test_the_run_on_the_same_wall_has_its_own_clock_from_the_re_entry(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_run_on_wall_a(rig)
	_wall_jump(rig)
	_throw_back(rig)
	var entry_tick := _fly_until_wall_run(rig, tickrate)
	var entry_height := rig.position.y
	var hold := WALL_HOLD_TICKS[tickrate]
	var max_ticks := WALL_RUN_MAX_TICKS[tickrate]
	assert_int(rig.config.wall_hold_ticks).is_equal(hold)
	assert_int(rig.config.wall_hold_ticks).is_equal(Ticks.from_ms(WALL_HOLD_MS, tickrate))
	assert_int(absi(hold * 1000 - WALL_HOLD_MS * tickrate)).is_less_equal(
		HALF_TICK_IN_MS_TIMES_RATE
	)
	assert_int(rig.config.wall_run_max_ticks).is_equal(max_ticks)
	assert_int(rig.config.wall_run_max_ticks).is_equal(Ticks.from_ms(WALL_RUN_MAX_MS, tickrate))
	assert_int(absi(max_ticks * 1000 - WALL_RUN_MAX_MS * tickrate)).is_less_equal(
		HALF_TICK_IN_MS_TIMES_RATE
	)
	var violations: Array[String] = []
	for step: int in range(1, max_ticks):
		var plan := rig.step(MovementRig.idle())
		if plan.state.mode != FighterState.Mode.WALL_RUN or plan.state.mode_since != entry_tick:
			violations.append("tick +%d: not the run since %d" % [step, entry_tick])
		if step < hold and absf(rig.position.y - entry_height) > HEIGHT_TOLERANCE_M:
			violations.append(
				"tick +%d: height %.4f, entry %.4f" % [step, rig.position.y, entry_height]
			)
		if step >= hold and plan.velocity.y > -HAIR:
			violations.append("tick +%d: not sliding (%.5f)" % [step, plan.velocity.y])
	assert_array(violations).override_failure_message("%s" % [violations]).is_empty()
	var after := rig.step(MovementRig.idle())
	assert_int(after.state.mode).override_failure_message("still on the wall after 2,5 s") \
			.is_equal(FighterState.Mode.AIR)
	assert_int(after.state.mode_since).is_equal(entry_tick + max_ticks)


# Criterion 1: a jump kept in the slot up to 150 ms before the re-entry comes out as the wall
# jump on its first run tick, as at any entry; the double jump is spent so the press waits in
# the air (movimento.md, "Corrida na parede": "Pulo da parede no voo: um pulo guardado até 150 ms
# antes de encostar sai no primeiro tick da corrida"; DEC-0039). The double jump is spent by
# hand after the wall jump, as movement_wall_test.gd does, and the body is thrown back by hand:
# the probe finds the re-entry tick, and the rig presses at the limit of the window before its
# first run tick, while still away from the wall.
func test_a_jump_kept_in_the_slot_before_the_re_entry_fires_on_its_first_run_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var probe := _air_rig(tickrate)
	_wall_a(probe)
	_run_on_wall_a(probe)
	var wall_jump_tick := _wall_jump(probe)
	var double_jump_tick := _spend_by_hand(probe)
	var entry_tick := _come_back_pressing_at(probe, FighterState.NEVER)
	var press_tick := entry_tick + 1 - BUFFER_TICKS[tickrate]
	assert_int(press_tick).override_failure_message("the press must come after the wall jump") \
			.is_greater(wall_jump_tick)
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_run_on_wall_a(rig)
	assert_int(_wall_jump(rig)).is_equal(wall_jump_tick)
	assert_int(_spend_by_hand(rig)).is_equal(double_jump_tick)
	assert_int(_come_back_pressing_at(rig, press_tick)).is_equal(entry_tick)
	assert_int(rig.state.wall_jump_tick).override_failure_message("jumped in the air").is_equal(
		wall_jump_tick
	)
	_assert_same_wall_run_kept(rig.state, entry_tick, 2, double_jump_tick)
	_assert_slot(rig.state, FighterCommand.JUMP, press_tick)
	var first_run_tick := rig.tick
	var plan := rig.step(MovementRig.idle())
	assert_int(plan.state.wall_jump_tick).override_failure_message("the kept jump did not fire") \
			.is_equal(first_run_tick)
	assert_float(plan.velocity.y).is_equal_approx(rig.config.wall_jump_speed, HAIR)
	_assert_slot(plan.state, FighterCommand.NONE, FighterState.NEVER)
	assert_int(plan.state.double_jump_tick).is_equal(double_jump_tick)


# Criterion 2, spent: the double jump used to turn back into the same wall stays spent through
# the re-entry, through the second wall jump, and a press after that one finds no double jump:
# the body only gets the wall jump's 1,2 m (DEC-0047 §2: "Gasto, ele segue gasto"; movimento.md,
# "Pulo e ar": "Pulo duplo: um por voo").
func test_the_re_entry_on_the_same_wall_leaves_a_spent_double_jump_spent(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_run_on_wall_a(rig)
	_wall_jump(rig)
	rig.rest(AIR_TICKS_BEFORE_THE_PRESS)
	var double_jump_tick := _double_jump_into_the_wall(rig)
	var entry_tick := _fly_until_wall_run(rig, tickrate)
	var before := rig.last_plan.state
	assert_int(before.jumps_used).is_equal(2)
	_assert_same_wall_run_kept(rig.state, entry_tick, 2, double_jump_tick)
	_assert_run_tick(rig.step(MovementRig.idle()), WALL_RUN_SPEED_MPS)
	_assert_same_wall_run_kept(rig.state, entry_tick, 2, double_jump_tick)
	var press_height := rig.position.y
	var second_wall_jump := _wall_jump(rig)
	assert_int(rig.state.double_jump_tick).override_failure_message("the wall jump renewed it") \
			.is_equal(double_jump_tick)
	rig.rest(AIR_TICKS_BEFORE_THE_PRESS)
	var vertical_before := rig.velocity.y
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_jump())
	_assert_double_jump_refused(plan, press_tick, double_jump_tick, vertical_before)
	assert_int(plan.state.wall_jump_tick).is_equal(second_wall_jump)
	var apex := _rise_to_apex(rig, 2 * tickrate)
	_assert_height(apex - press_height, WALL_JUMP_HEIGHT_M, "the second wall jump alone")


# Criterion 2, available: back on the same wall without having used the double jump, the
# re-entry leaves it available as it was, neither spent nor restarted: the second wall jump is
# again the first jump of the flight, and a press after it is the double jump, 1,0 m up within
# 1 cm (DEC-0047 §2: "disponível, segue disponível"; movimento.md, "Corrida na parede": "Pulo da
# parede no voo").
func test_the_re_entry_on_the_same_wall_leaves_an_available_double_jump_available(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_run_on_wall_a(rig)
	_wall_jump(rig)
	_throw_back(rig)
	var entry_tick := _fly_until_wall_run(rig, tickrate)
	var before := rig.last_plan.state
	assert_int(before.jumps_used).is_equal(1)
	assert_int(before.double_jump_tick).is_equal(FighterState.NEVER)
	_assert_same_wall_run_kept(rig.state, entry_tick, 1, FighterState.NEVER)
	rig.rest(RUN_TICKS_BEFORE_THE_JUMP)
	var second_wall_jump := _wall_jump(rig)
	assert_int(rig.state.jumps_used).override_failure_message("not the first jump").is_equal(1)
	assert_int(rig.state.double_jump_tick).is_equal(FighterState.NEVER)
	rig.rest(AIR_TICKS_BEFORE_THE_PRESS)
	var press_tick := rig.tick
	var press_height := rig.position.y
	var plan := rig.step(MovementRig.press_jump())
	_assert_double_jumped(rig, plan, press_tick)
	assert_int(plan.state.wall_jump_tick).is_equal(second_wall_jump)
	_assert_height(
		_rise_to_apex(rig, 2 * tickrate) - press_height,
		DOUBLE_JUMP_HEIGHT_M,
		"double jump after the second wall jump",
	)


# Many: three re-entries on the same wall in a row, each after a wall jump, and the spent double
# jump stays spent at every one of them; the press at the end still finds none (DEC-0047 §2).
func test_the_double_jump_stays_spent_through_three_re_entries_on_the_same_wall(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_run_on_wall_a(rig)
	_wall_jump(rig)
	rig.rest(AIR_TICKS_BEFORE_THE_PRESS)
	var double_jump_tick := _double_jump_into_the_wall(rig)
	var entries: Array[int] = []
	for _again: int in 3:
		var entry_tick := _fly_until_wall_run(rig, RETURN_LIMIT_S * tickrate)
		if entry_tick < 0:
			return
		entries.append(entry_tick)
		_assert_same_wall_run_kept(rig.state, entry_tick, 2, double_jump_tick)
		rig.rest(RUN_TICKS_BEFORE_THE_JUMP)
		_wall_jump(rig)
		assert_int(rig.state.double_jump_tick).is_equal(double_jump_tick)
		_throw_back(rig)
	assert_int(entries.size()).is_equal(3)
	var vertical_before := rig.velocity.y
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_jump())
	_assert_double_jump_refused(plan, press_tick, double_jump_tick, vertical_before)


# Criterion 3: a run on another wall still renews the double jump, and from then on the first
# wall is another wall again: from the same wall (spent kept) the wall jump crosses the corridor
# to WALL_B, which renews; the jump back lands on WALL_A, which renews too (DEC-0047 §2 and §3;
# movimento.md, "Pulo e ar": "Renovação do pulo duplo").
func test_a_run_on_another_wall_after_the_same_wall_renews_the_double_jump(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_wall_b(rig)
	_run_on_wall_a(rig)
	_wall_jump(rig)
	rig.rest(AIR_TICKS_BEFORE_THE_PRESS)
	var double_jump_tick := _double_jump_into_the_wall(rig)
	var same_entry := _fly_until_wall_run(rig, tickrate)
	_assert_same_wall_run_kept(rig.state, same_entry, 2, double_jump_tick)
	rig.rest(RUN_TICKS_BEFORE_THE_JUMP)
	_wall_jump(rig)
	var other_entry := _fly_until_wall_run(rig, tickrate)
	_assert_wall_run_renewed(rig.state, other_entry, WALL_B, Vector3.LEFT)
	rig.rest(RUN_TICKS_BEFORE_THE_JUMP)
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_jump())
	assert_int(plan.state.wall_jump_tick).is_equal(press_tick)
	assert_float(_horizontal(plan.velocity).dot(Vector3.LEFT)).is_equal_approx(
		WALL_JUMP_PUSH_MPS,
		HAIR,
	)
	var back_entry := _fly_until_wall_run(rig, tickrate)
	_assert_wall_run_renewed(rig.state, back_entry, WALL_A, Vector3.RIGHT)


# Criterion 3: the floor still renews the double jump and clears the last wall, so the same wall
# accepts the next run with the renewal (DEC-0047 §2 and §3; movimento.md, "Pulo e ar":
# "Renovação do pulo duplo: ao tocar o chão").
func test_the_floor_after_the_same_wall_renews_the_double_jump_and_clears_the_last_wall(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_wall_a(rig)
	rig.airborne(
		Vector3(MovementRig.WALL_PROBE_DISTANCE / 2.0, LOW_START_HEIGHT_M, 0.0),
		Vector3(0.0, 0.0, -WALL_RUN_SPEED_MPS),
	)
	_fly_until_wall_run(rig, 2)
	rig.rest(RUN_TICKS_BEFORE_THE_JUMP)
	_wall_jump(rig)
	rig.rest(AIR_TICKS_BEFORE_THE_PRESS)
	var double_jump_tick := _double_jump_into_the_wall(rig)
	var same_entry := _fly_until_wall_run(rig, tickrate)
	_assert_same_wall_run_kept(rig.state, same_entry, 2, double_jump_tick)
	rig.rest(RUN_TICKS_BEFORE_THE_JUMP)
	_wall_jump(rig)
	var landing_tick := -1
	for _step: int in 3 * tickrate:
		rig.step(MovementRig.idle())
		if rig.state.on_floor:
			landing_tick = rig.tick - 1
			break
	assert_int(landing_tick).override_failure_message("never landed").is_greater(same_entry)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GROUND)
	rig.step(MovementRig.idle())
	assert_int(rig.state.jumps_used).override_failure_message("the floor did not renew").is_equal(0)
	assert_int(rig.state.double_jump_tick).is_equal(FighterState.NEVER)
	assert_str(String(rig.state.wall_id)).override_failure_message("the floor kept the wall") \
			.is_equal("")
	assert_vector(rig.state.wall_normal).is_equal(Vector3.ZERO)
	rig.airborne(
		Vector3(MovementRig.WALL_PROBE_DISTANCE / 2.0, START_HEIGHT_M, 0.0),
		Vector3(0.0, 0.0, -WALL_RUN_SPEED_MPS),
	)
	rig.state.jumps_used = 2
	rig.state.double_jump_tick = rig.tick - 1
	var again := _fly_until_wall_run(rig, 2)
	_assert_wall_run_renewed(rig.state, again, WALL_A, Vector3.RIGHT)


# Criterion 3: another fighter's head changes neither the last wall nor the double jump: landed
# on a head after the second wall jump, the state keeps WALL_A and the spent double jump, and
# back on WALL_A after sliding off, the run is still on the same wall, without the renewal
# (DEC-0047 §3; DEC-0046 §1; movimento.md, "O corpo": "A cabeça do outro").
func test_landing_on_another_fighters_head_after_the_same_wall_does_not_change_the_last_wall(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_run_on_wall_a(rig)
	_wall_jump(rig)
	rig.rest(AIR_TICKS_BEFORE_THE_PRESS)
	var double_jump_tick := _double_jump_into_the_wall(rig)
	var same_entry := _fly_until_wall_run(rig, tickrate)
	_assert_same_wall_run_kept(rig.state, same_entry, 2, double_jump_tick)
	rig.rest(RUN_TICKS_BEFORE_THE_JUMP)
	_wall_jump(rig)
	_rise_to_apex(rig, 2 * tickrate)
	# The other fighter right under the feet at the apex; the body drops straight onto the head.
	rig.velocity = Vector3.ZERO
	rig.add_head(Vector3(rig.position.x, 0.0, rig.position.z), rig.position.y - HEAD_BELOW_M)
	var landing_tick := -1
	for _step: int in tickrate:
		rig.step(MovementRig.idle())
		if rig.last_facts.floor_is_fighter:
			landing_tick = rig.tick - 1
			break
	assert_int(landing_tick).override_failure_message("never landed on the head").is_greater(0)
	assert_int(rig.state.head_landing_tick).is_equal(landing_tick)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	_assert_wall_id(rig.state, WALL_A)
	assert_vector(rig.state.wall_normal).is_equal_approx(Vector3.RIGHT, Vector3.ONE * HAIR)
	assert_int(rig.state.jumps_used).override_failure_message("the head renewed the jumps") \
			.is_equal(2)
	assert_int(rig.state.double_jump_tick).is_equal(double_jump_tick)
	for _step: int in tickrate:
		rig.step(MovementRig.idle())
		if not rig.last_facts.floor_is_fighter:
			break
	assert_bool(rig.last_facts.floor_is_fighter).override_failure_message("still on the head") \
			.is_false()
	_assert_wall_id(rig.state, WALL_A)
	rig.velocity = Vector3(-THROWN_BACK_MPS, rig.velocity.y, -WALL_RUN_SPEED_MPS)
	var back_entry := _fly_until_wall_run(rig, tickrate)
	_assert_same_wall_run_kept(rig.state, back_entry, 2, double_jump_tick)


# Criterion 4, pressing whenever it can: from the first run on, the jump pressed on every tick
# with the stick into the wall. The first run gives the wall jump and, at once, the double jump
# back into the wall; the re-entry gives the wall jump again and nothing more, and every return
# after that is lower. Over six seconds the wall is entered again and again, the double jump
# comes out once, and the feet never pass 3,5 m above the first run (DEC-0047; TASK-10.13,
# "Números v0").
func test_pressing_jump_every_tick_back_and_forth_on_the_same_wall_finds_one_double_jump(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS)
	var first_entry := _fly_until_wall_run(rig, 2 * tickrate)
	assert_int(first_entry).override_failure_message("never ran on the wall").is_greater(0)
	var climb := Climb.new()
	climb.entries = 1
	climb.first_run_height = rig.position.y
	climb.entry_heights.append(rig.position.y)
	climb.max_height = rig.position.y
	var input := MovementRig.press_jump_toward(_into_the_wall(INTO_45))
	for _step: int in GREEDY_SECONDS * tickrate:
		_climb_step(rig, input, climb)
	var summary := "entries %d at %s, wall jumps %s, double jumps %s, climbed %.3f m" % [
		climb.entries,
		climb.entry_heights,
		climb.wall_jump_ticks,
		climb.double_jump_ticks,
		climb.climbed(),
	]
	assert_int(climb.entries).override_failure_message(summary).is_greater_equal(3)
	assert_int(climb.wall_jump_ticks.size()).override_failure_message(summary) \
			.is_greater_equal(3)
	assert_int(climb.double_jump_ticks.size()).override_failure_message(summary).is_equal(1)
	assert_float(climb.climbed()).override_failure_message(summary).is_less_equal(LADDER_LIMIT_M)


# Criterion 4, the limit: the ladder played for height. Wall jump; at its apex the double jump
# back into the wall; the re-entry on the same wall, higher, and the wall jump again at once; at
# that apex a press finds no double jump, the stick brings the body back lower, and the next
# cycles only fall. The climb happens once, above the +2,2 m one wall gave before (DEC-0047:
# "o mais alto passa de +2,2 m para +3,4 m, uma vez"), and the feet never pass 3,5 m above the
# first run, at both angles of return (DEC-0047; TASK-10.13, "Números v0").
func test_the_ladder_on_one_wall_climbs_once_and_never_more_than_3_5_m_above_the_first_run(
	tickrate: int,
	into_deg: float,
	_test_parameters := [[30, INTO_45], [60, INTO_45], [30, INTO_25], [60, INTO_25]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	var into := MovementRig.run(_into_the_wall(into_deg))
	var press_into := MovementRig.press_jump_toward(_into_the_wall(into_deg))
	var climb := Climb.new()
	_approach_wall_a(rig, WALL_RUN_SPEED_MPS)
	var first_entry := _fly_until_wall_run(rig, 2 * tickrate)
	assert_int(first_entry).is_greater(0)
	climb.entries = 1
	climb.first_run_height = rig.position.y
	climb.entry_heights.append(rig.position.y)
	climb.max_height = rig.position.y
	var apexes: Array[float] = []
	for cycle: int in LADDER_CYCLES:
		# The wall jump, on the first run tick.
		var wall_jump := _climb_step(rig, press_into, climb)
		assert_int(wall_jump.state.wall_jump_tick) \
				.override_failure_message("cycle %d: no wall jump" % cycle) \
				.is_equal(rig.tick - 1)
		# Rising with the stick into the wall, to the apex.
		var apex := rig.position.y
		for _step: int in 2 * tickrate:
			if rig.velocity.y <= 0.0 or rig.state.mode == FighterState.Mode.WALL_RUN:
				break
			_climb_step(rig, into, climb)
			apex = maxf(apex, rig.position.y)
		apexes.append(apex)
		if rig.state.mode != FighterState.Mode.WALL_RUN:
			# At the apex, the press: the double jump the first time, nothing after.
			_climb_step(rig, press_into, climb)
			# Back to the wall with the stick into it.
			var returned := false
			for _step: int in RETURN_LIMIT_S * tickrate:
				_climb_step(rig, into, climb)
				if rig.state.mode == FighterState.Mode.WALL_RUN:
					returned = true
					break
			if not returned:
				fail("cycle %d: never came back to the wall" % cycle)
				return
	var summary := "entries at %s, apexes %s, double jumps %s, climbed %.3f m above %.3f" % [
		climb.entry_heights,
		apexes,
		climb.double_jump_ticks,
		climb.climbed(),
		climb.first_run_height,
	]
	assert_int(climb.entries).override_failure_message(summary).is_equal(LADDER_CYCLES + 1)
	assert_int(climb.double_jump_ticks.size()).override_failure_message(summary).is_equal(1)
	assert_float(climb.climbed()).override_failure_message(summary).is_greater(OLD_CLIMB_M)
	assert_float(climb.climbed()).override_failure_message(summary).is_less_equal(LADDER_LIMIT_M)
	# The second re-entry (after the wall jump with no double jump) is below the first.
	assert_float(climb.entry_heights[2]).override_failure_message(summary).is_less(
		climb.entry_heights[1]
	)
