# Criterion 1 of TASK-10.7: another fighter's head is never floor for the rules (movimento.md, "O
# corpo": "A cabeça do outro"; glossario.md, "Escorregar da cabeça" and "Em pé e no chão"; F-151;
# F-152; Q-16), through the public interface of core/fighter with the engine's slice played by
# MovementRig: the head is a fact the adapter reports (MoveFacts.floor_is_fighter and
# fighter_away), the engine's on_floor stays its verdict (DEC-0025 §2; DEC-0037), and the rules
# ask Movement.stands instead. Whoever lands on a head stays in the air for the rules: no floor
# jump, no dash, no renewal of the jumps, the double jump or the last wall, no coyote, the air's
# gravity; the double jump still held and the grapple fire as in the air; and the body slides off
# at 3 m/s away from the other's axis, from an exactly centred landing toward the back of where
# the body faces, leaving the 0,495 m of the dome within 12 ticks at 60 counted from the tick
# after the landing. Every number comes from docs/design/movimento.md, cited by row; ticks by
# hand from the ms, nearest tick with ties up (visao-geral.md, "O tempo e a física no estado").
# Side bumps are the engine's push of TASK-9 and are not modelled here.
extends GdUnitTestSuite

const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)

# movimento.md, "O corpo".
const CAPSULE_HEIGHT_M := 1.8 # "Altura da cápsula": the feet of whoever stands on it rest there
const CAPSULE_RADIUS_M := 0.35 # "Raio da cápsula"
const MAX_SLOPE_DEG := 45.0 # "Rampa máxima": above it, it is not floor
const HEAD_SLIDE_SPEED_MPS := 3.0 # "Escorregar da cabeça"
# "Escorregar da cabeça": "o domo deixa de ser chão além de 45°, a 0,495 m do eixo", two radii of
# 0,35 m times sin 45°.
const HEAD_RADIUS_M := 0.495
# Criterion 1: "saindo da cabeça em até 12 ticks a 60 contados do tick seguinte ao pouso"; the
# same 200 ms are 6 ticks at 30. "Escorregar da cabeça": "do centro, 10 ticks a 60": 0,495 m at
# 0,05 m per tick (3 m/s over 60), and 5 ticks at 30 (0,1 m per tick).
const EXIT_WITHIN_TICKS: Dictionary[int, int] = { 30: 6, 60: 12 }
const EXIT_FROM_CENTRE_TICKS: Dictionary[int, int] = { 30: 5, 60: 10 }

# The windows by hand: 100 ms of coyote is 3 ticks at 30 and 6 at 60; 150 ms of buffer is
# 4.5 -> 5 at 30 (tie up) and 9 at 60 (movimento.md, "Perdão"). 100 ms of cable is 3 and 6
# ("Gancho": "Tempo até prender"); 200 ms of dash is 6 and 12 ("Dash": "Duração").
const COYOTE_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
const BUFFER_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }
const ATTACH_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
const DASH_TICKS: Dictionary[int, int] = { 30: 6, 60: 12 }
const DASH_DISTANCE_M := 4.0 # movimento.md, "Dash": "Distância"
const DASH_SPEED_MPS := 20.0 # movimento.md, "Dash": "Deriva a velocidade: 20 m/s"
const GRAPPLE_PULL_SPEED_MPS := 18.0 # movimento.md, "Gancho": "Velocidade da puxada"
const GRAPPLE_RELEASE_DISTANCE_M := 1.5 # movimento.md, "Gancho": "Como solta"

# The exact centre, as the plan states it: a flattened contact normal shorter than this is a
# landing on the very top, and the slide goes toward the back of the facing. A float threshold,
# not a design number.
const CENTRE_HAIR := 1e-6
# Offsets of the feet from the other's axis that give a flattened normal clearly below and
# clearly above CENTRE_HAIR (the rig divides the offset by the two radii, 0,7 m).
const TINY_OFFSET_M := 1e-7
const SMALL_OFFSET_M := 1e-4

# Rig geometry: not design numbers. The air start above a head, a gentle fall into it, a head
# whose top is the floor itself (the body slides from it straight onto the floor, with no fall
# in between), a point for the grapple and ids as the adapter reports them.
const START_ABOVE_M := 3.0
const FALL_SPEED_MPS := -2.0
const JUST_ABOVE_M := 0.01
const FLOOR_LEVEL_M := 0.0
const DOUBLE_JUMP_CATCH_M := 1.0 # a head top below the jump's 1,2 m apex catches the fall
const FASTER_THAN_SLIDE_MPS := 5.0
const SIDEWAYS_MPS := 2.0
const POINT_UP_AHEAD := Vector3(0.0, 5.0, -10.0)
const POINT_ALONG_FLOOR := Vector3(0.0, 0.0, -20.0)
const HEAD_AHEAD_OF_DASH := Vector3(0.0, 0.0, -1.0)
const HEAD_ALONG_PULL := Vector3(0.0, 0.0, -5.0)
const WALL_A := &"ParedeA"
const FORWARD := Vector2(0, 1) # move.y goes forward: yaw 0 looks down -Z (TASK-9 plan)

const HAIR := 1e-6 # floating-point slack, not a design number
const GEOMETRY_HAIR := 1e-4 # float32 vectors through a normalize and a few ticks


# One slide recorded from the tick after the landing: each tick's plan, the slide direction the
# tick started with, whether the head was still under the feet after it, and the exit tick, the
# first whose move ended off the head.
class SlideRecord:
	var plans: Array[MovePlan] = []
	var dirs_before: Array[Vector3] = []
	var on_head_after: Array[bool] = []
	var distances_after: Array[float] = []
	var exit_tick := 0


	func head_ticks() -> int:
		var count := 0
		for held: bool in on_head_after:
			if held:
				count += 1
		return count


# One pull recorded from the fire: the pull ticks with the feet they started from and whether a
# head was under the feet after each, and the release.
class PullRecord:
	var plans: Array[MovePlan] = []
	var starts: Array[Vector3] = []
	var on_head_after: Array[bool] = []
	var release_tick := 0
	var release_plan: MovePlan


	func head_ticks() -> int:
		var count := 0
		for held: bool in on_head_after:
			if held:
				count += 1
		return count


func _rig(tickrate: int) -> MovementRig:
	var rig := MovementRig.new(MovementRig.load_config(tickrate), FIRST_TICK)
	rig.aim_hit = false
	rig.aim_point = Vector3.ZERO
	return rig


func _horizontal(velocity: Vector3) -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)


# The back of where the body faces, by hand from the paper: yaw 0 looks down -Z, so the back is
# +Z, and Basis(UP, yaw) turns +Z into (sin yaw, 0, cos yaw) (TASK-9 plan; movimento.md, "O
# corpo": "num pouso exato no centro, para as costas de onde o corpo olha").
func _back_of(yaw: float) -> Vector3:
	return Vector3(sin(yaw), 0.0, cos(yaw))


# A head whose top is a capsule's height above the floor: the other fighter standing on it.
func _standing_head(rig: MovementRig, axis: Vector3) -> MovementRig.FakeHead:
	return rig.add_head(axis, CAPSULE_HEIGHT_M)


# Drops the body onto the head from START_ABOVE_M over its top, the feet this offset from the
# axis, looking at this yaw, and idles until the rig says the head is under the feet. Returns
# the landing tick, the first whose move ended on the head.
func _fall_onto(rig: MovementRig, head: MovementRig.FakeHead, offset: Vector3, yaw := 0.0) -> int:
	var at := Vector3(head.axis.x + offset.x, head.top_y + START_ABOVE_M, head.axis.z + offset.z)
	rig.airborne(at, Vector3(0.0, FALL_SPEED_MPS, 0.0))
	return _idle_until_on_head(rig, yaw)


# Idles (looking at this yaw) until the rig's facts say the head is under the feet; returns that
# tick, or fails.
func _idle_until_on_head(rig: MovementRig, yaw := 0.0) -> int:
	for _step: int in range(1, 5 * rig.config.tickrate + 1):
		rig.step(MovementRig.run(Vector2.ZERO, yaw))
		if rig.last_facts.floor_is_fighter:
			return rig.tick - 1
	fail("never landed on the head at %d ticks" % rig.config.tickrate)
	return 0


# Idles from the tick after the landing until the move ends off the head, recording each tick,
# or fails after `limit` ticks.
func _slide_off(rig: MovementRig, limit: int) -> SlideRecord:
	var record := SlideRecord.new()
	var head := _head_under_feet(rig)
	for _step: int in limit:
		record.dirs_before.append(rig.state.slide_off_dir)
		record.plans.append(rig.step(MovementRig.idle()))
		record.on_head_after.append(rig.last_facts.floor_is_fighter)
		record.distances_after.append(head.offset_of(rig.position).length())
		if not rig.last_facts.floor_is_fighter:
			record.exit_tick = rig.tick - 1
			return record
	fail("still on the head after %d ticks (at %d ticks)" % [limit, rig.config.tickrate])
	return record


# The head the rig's last facts came from: the one that covers the feet now.
func _head_under_feet(rig: MovementRig) -> MovementRig.FakeHead:
	for head: MovementRig.FakeHead in rig.heads:
		if head.covers(rig.position) and is_equal_approx(rig.position.y, head.top_y):
			return head
	fail("no head under the feet at %s" % rig.position)
	return null


# Idles until the fighter stands on the real floor; returns the first tick that starts there.
func _idle_until_on_floor(rig: MovementRig) -> int:
	for _step: int in range(1, 5 * rig.config.tickrate + 1):
		rig.step(MovementRig.idle())
		if rig.state.mode == FighterState.Mode.GROUND and not rig.last_facts.floor_is_fighter:
			return rig.tick
	fail("never reached the floor at %d ticks" % rig.config.tickrate)
	return 0


# Jumps from rest, spends the double jump on the next tick and lands on a head whose top is the
# floor itself, right under the start: an exactly centred landing with both jumps used. Returns
# the landing tick.
func _jump_spend_and_land_on_a_floor_level_head(rig: MovementRig) -> int:
	rig.step(MovementRig.press_jump())
	_spend_double_jump(rig)
	rig.add_head(Vector3.ZERO, FLOOR_LEVEL_M)
	return _idle_until_on_head(rig)


func _spend_double_jump(rig: MovementRig) -> void:
	var plan := rig.step(MovementRig.press_jump())
	assert_int(plan.state.jumps_used).override_failure_message("not spent").is_equal(2)


# Plays the same flight as _jump_spend_and_land_on_a_floor_level_head, the fall onto the head and
# the slide after it, with `press` on press_tick, up to (not including) `until`, asserting
# nothing fires meanwhile: no jump, no dash, nothing paid beyond the double jump of the flight.
# Returns the landing tick.
func _land_on_the_floor_level_head_and_press(
	rig: MovementRig,
	press_tick: int,
	press: TickInput,
	until: int,
) -> int:
	rig.step(MovementRig.press_jump())
	_spend_double_jump(rig)
	rig.add_head(Vector3.ZERO, FLOOR_LEVEL_M)
	var landing_tick := 0
	var violations: Array[String] = []
	while rig.tick < until:
		var input := press if rig.tick == press_tick else MovementRig.idle()
		var plan := rig.step(input)
		if rig.last_facts.floor_is_fighter and landing_tick == 0:
			landing_tick = rig.tick - 1
		if plan.state.jumps_used != 2:
			violations.append("tick %d: a jump fired" % (rig.tick - 1))
		if plan.state.mode == FighterState.Mode.DASH or plan.state.dash_tick != FighterState.NEVER:
			violations.append("tick %d: a dash fired" % (rig.tick - 1))
		if plan.state.stamina_spent_tick != FIRST_TICK + 1:
			violations.append("tick %d: something was paid" % (rig.tick - 1))
	assert_int(landing_tick).override_failure_message("never landed on the head").is_greater(0)
	assert_array(violations).override_failure_message("fired on a head: %s" % [violations]) \
			.is_empty()
	return landing_tick


func _aim_at(rig: MovementRig, point: Vector3) -> void:
	rig.aim_hit = true
	rig.aim_point = point


# Presses the grapple now with the aim on this point; asserts the plan asked and the hook bit
# on this tick. Returns the fire tick.
func _fire(rig: MovementRig, point: Vector3) -> int:
	_aim_at(rig, point)
	var fire_tick := rig.tick
	var plan := rig.step(MovementRig.press_grapple())
	assert_bool(plan.aim_request).override_failure_message("the plan did not ask for the aim") \
			.is_true()
	var stamp := "grapple_fired_tick is %d, expected %d" % [rig.state.grapple_fired_tick, fire_tick]
	assert_int(rig.state.grapple_fired_tick).override_failure_message(stamp).is_equal(fire_tick)
	assert_vector(rig.state.grapple_point).is_equal_approx(point, Vector3.ONE * HAIR)
	_assert_slot(rig.state, FighterCommand.NONE, FighterState.NEVER)
	return fire_tick


# Idles from right after the fire and records the pull and the release, or fails after `limit`.
func _record_pull(rig: MovementRig, limit: int) -> PullRecord:
	var record := PullRecord.new()
	for _step: int in limit:
		var start := rig.position
		var plan := rig.step(MovementRig.idle())
		if plan.state.mode == FighterState.Mode.GRAPPLE:
			record.plans.append(plan)
			record.starts.append(start)
			record.on_head_after.append(rig.last_facts.floor_is_fighter)
		elif plan.state.grapple_end_tick != FighterState.NEVER:
			record.release_tick = rig.tick - 1
			record.release_plan = plan
			return record
	fail("no release within %d ticks (at %d ticks)" % [limit, rig.config.tickrate])
	return record


# The gravity of one tick in the air from a vertical of 0, as the existing air rule gives it:
# the reference the head's ticks must match.
func _air_gravity_from_rest(tickrate: int) -> float:
	var rig := _rig(tickrate)
	rig.floor_on = false
	rig.airborne(Vector3(0.0, START_ABOVE_M, 0.0), Vector3.ZERO)
	var plan := rig.step(MovementRig.idle())
	assert_float(plan.velocity.y).override_failure_message("no gravity in the air").is_less(0.0)
	return plan.velocity.y


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


# On a head, as the plan states it: AIR for the rules, the engine's floor kept, the slide
# direction a horizontal unit vector, the landing stamped, and stands() false.
func _assert_on_head(state: FighterState, landing_tick: int, direction: Vector3) -> void:
	assert_int(state.mode).override_failure_message("the head counted as GROUND").is_equal(
		FighterState.Mode.AIR
	)
	assert_bool(state.on_floor).override_failure_message("on_floor is the engine's verdict") \
			.is_true()
	var slide := "slide_off_dir is %s, expected %s" % [state.slide_off_dir, direction]
	assert_vector(state.slide_off_dir).override_failure_message(slide).is_equal_approx(
		direction,
		Vector3.ONE * GEOMETRY_HAIR,
	)
	assert_float(state.slide_off_dir.length()).is_equal_approx(1.0, GEOMETRY_HAIR)
	assert_float(state.slide_off_dir.y).is_equal(0.0)
	var stamp := "head_landing_tick is %d, expected %d" % [state.head_landing_tick, landing_tick]
	assert_int(state.head_landing_tick).override_failure_message(stamp).is_equal(landing_tick)
	assert_bool(Movement.stands(state)).override_failure_message("stands on a head").is_false()


func _assert_off_head(state: FighterState) -> void:
	assert_vector(state.slide_off_dir).override_failure_message("still sliding").is_equal(
		Vector3.ZERO
	)
	assert_int(state.head_landing_tick).override_failure_message("the landing stayed stamped") \
			.is_equal(FighterState.NEVER)


func _assert_no_jump(plan: MovePlan, jumps_used_before: int) -> void:
	assert_float(plan.velocity.y).override_failure_message("it jumped").is_less_equal(HAIR)
	assert_int(plan.state.jumps_used).override_failure_message("a jump was counted").is_equal(
		jumps_used_before
	)


func _assert_full_jump(rig: MovementRig, plan: MovePlan) -> void:
	assert_float(plan.velocity.y).override_failure_message("not the full jump") \
			.is_equal_approx(rig.config.jump_speed, HAIR)
	assert_int(plan.state.jumps_used).is_equal(1)
	_assert_slot(plan.state, FighterCommand.NONE, FighterState.NEVER)


# The double jump as the other suites read it: its own exit speed (not the full jump's), the
# second jump of the flight, its stamp, the cost paid now and the slot consumed.
func _assert_double_jumped(rig: MovementRig, plan: MovePlan, press_tick: int) -> void:
	assert_float(plan.velocity.y).override_failure_message("not the double jump speed") \
			.is_equal_approx(rig.config.double_jump_speed, HAIR)
	var full := "the full jump came out: %.4f" % plan.velocity.y
	assert_float(absf(plan.velocity.y - rig.config.jump_speed)).override_failure_message(full) \
			.is_greater(HAIR)
	assert_int(plan.state.jumps_used).override_failure_message("not the second jump").is_equal(2)
	assert_int(plan.state.double_jump_tick).is_equal(press_tick)
	assert_int(plan.state.stamina_spent_tick).override_failure_message("the cost was not paid") \
			.is_equal(press_tick)
	_assert_slot(plan.state, FighterCommand.NONE, FighterState.NEVER)


func _assert_no_dash(plan: MovePlan) -> void:
	assert_int(plan.state.mode).override_failure_message("dashed").is_not_equal(
		FighterState.Mode.DASH
	)
	assert_int(plan.state.dash_tick).is_equal(FighterState.NEVER)


func _assert_pull_tick(plan: MovePlan, feet: Vector3, point: Vector3) -> void:
	assert_int(plan.state.mode).override_failure_message("not in GRAPPLE").is_equal(
		FighterState.Mode.GRAPPLE
	)
	var expected := (point - feet).normalized() * GRAPPLE_PULL_SPEED_MPS
	var message := "pull velocity %s, expected %s" % [plan.velocity, expected]
	assert_vector(plan.velocity).override_failure_message(message).is_equal_approx(
		expected,
		Vector3.ONE * GEOMETRY_HAIR,
	)


# None: a fresh state is off a head, the facts report no head, stands() is true at a spawn
# point, and the config carries the slide speed of the design (TASK-10.7 plan: State, Facts,
# Helper and Config).
func test_a_fresh_state_is_off_a_head_and_the_agreed_names_exist() -> void:
	var state := FighterState.new()
	assert_vector(state.slide_off_dir).is_equal(Vector3.ZERO)
	assert_int(state.head_landing_tick).is_equal(FighterState.NEVER)
	assert_bool(Movement.stands(state)).is_true()
	var facts := MoveFacts.new()
	assert_bool(facts.floor_is_fighter).is_false()
	assert_vector(facts.fighter_away).is_equal(Vector3.ZERO)
	var config := MovementRig.load_config(60)
	assert_float(config.head_slide_speed).is_equal_approx(HEAD_SLIDE_SPEED_MPS, HAIR)
	assert_float(MovementRig.HEAD_RADIUS_M).is_equal_approx(HEAD_RADIUS_M, HAIR)
	assert_float(HEAD_RADIUS_M).is_equal_approx(
		2.0 * CAPSULE_RADIUS_M * sin(deg_to_rad(MAX_SLOPE_DEG)),
		GEOMETRY_HAIR,
	)


# The two fields travel with the state through rollback: copy() carries them, independently
# (DEC-0022; rede.md §8: ":state:slide_off_dir" is a poisoned path of criterion 3).
func test_fighter_state_copy_carries_the_head_fields() -> void:
	var original := _rig(60).state
	original.slide_off_dir = Vector3(0.6, 0.0, -0.8)
	original.head_landing_tick = 1234
	var copy := original.copy()
	assert_vector(copy.slide_off_dir).is_equal(Vector3(0.6, 0.0, -0.8))
	assert_int(copy.head_landing_tick).is_equal(1234)
	copy.slide_off_dir = Vector3.ZERO
	copy.head_landing_tick = FighterState.NEVER
	assert_vector(original.slide_off_dir).is_equal(Vector3(0.6, 0.0, -0.8))
	assert_int(original.head_landing_tick).is_equal(1234)


# Two different questions (glossario.md, "Em pé e no chão"): on the floor is the engine's verdict,
# standing is the rule, on the floor and not on a head.
func test_stands_is_the_floor_without_a_head_under_the_feet() -> void:
	var floor_state := FighterState.new()
	floor_state.on_floor = true
	floor_state.slide_off_dir = Vector3.ZERO
	assert_bool(Movement.stands(floor_state)).override_failure_message("the floor").is_true()
	var head_state := FighterState.new()
	head_state.on_floor = true
	head_state.slide_off_dir = Vector3.RIGHT
	assert_bool(Movement.stands(head_state)).override_failure_message("a head").is_false()
	var air_state := FighterState.new()
	air_state.on_floor = false
	air_state.slide_off_dir = Vector3.ZERO
	assert_bool(Movement.stands(air_state)).override_failure_message("the air").is_false()
	var leaving_state := FighterState.new()
	leaving_state.on_floor = false
	leaving_state.slide_off_dir = Vector3.RIGHT
	assert_bool(Movement.stands(leaving_state)).override_failure_message("off a head").is_false()


func test_stands_follows_the_rig_onto_a_head_and_back_to_the_floor(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.rest(2)
	assert_bool(Movement.stands(rig.state)).override_failure_message("at rest").is_true()
	var head := _standing_head(rig, Vector3.ZERO)
	_fall_onto(rig, head, Vector3.ZERO)
	assert_bool(rig.state.on_floor).is_true()
	assert_bool(Movement.stands(rig.state)).override_failure_message("on the head").is_false()
	_slide_off(rig, EXIT_WITHIN_TICKS[tickrate])
	assert_bool(Movement.stands(rig.state)).override_failure_message("off the head").is_false()
	_idle_until_on_floor(rig)
	assert_bool(Movement.stands(rig.state)).override_failure_message("on the floor").is_true()


# One: landing on a head from the air keeps AIR, since the tick it began, with the engine's
# floor, the slide away from the other's axis along the flattened contact normal, the landing
# stamped and no coyote (movimento.md, "O corpo": "A cabeça do outro", "Escorregar da cabeça").
func test_landing_on_a_head_from_the_air_keeps_air_and_slides_away_from_the_axis(
	tickrate: int,
	offset: Vector3,
	_test_parameters := [
		[60, Vector3(0.2, 0.0, 0.0)],
		[60, Vector3(0.0, 0.0, -0.3)],
		[60, Vector3(-0.1, 0.0, 0.1)],
		[30, Vector3(0.2, 0.0, 0.0)],
		[30, Vector3(-0.1, 0.0, 0.1)],
	],
) -> void:
	var rig := _rig(tickrate)
	var head := _standing_head(rig, Vector3(1.0, 0.0, -2.0))
	# The air by hand begins on the tick before the drop (MovementRig.airborne).
	var since := rig.tick - 1
	var landing_tick := _fall_onto(rig, head, offset)
	_assert_on_head(rig.state, landing_tick, offset.normalized())
	assert_int(rig.state.mode_since).override_failure_message("AIR restarted on the head") \
			.is_equal(since)
	assert_int(rig.state.left_floor_tick).is_equal(FighterState.NEVER)
	assert_int(rig.state.jumps_used).is_equal(0)
	assert_bool(rig.last_facts.floor_is_fighter).is_true()
	assert_vector(rig.last_facts.fighter_away.normalized()).is_equal_approx(
		offset.normalized(),
		Vector3.ONE * GEOMETRY_HAIR,
	)
	assert_float(rig.position.y).is_equal_approx(CAPSULE_HEIGHT_M, HAIR)


# From the ground: a head under the feet puts the fighter in the air for the rules since that
# tick, without the coyote stamp, and a press right after is the double jump, never the full
# jump (movimento.md, "Perdão": "A cabeça de outro lutador nunca abre o coyote, nem ao sair do
# chão para ela"; "Pulo e ar": "Aperto depois do coyote, sem ter pulado: é o pulo duplo").
func test_leaving_the_floor_onto_a_head_opens_no_coyote_and_a_press_is_the_double_jump(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.rest(3)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GROUND)
	rig.add_head(rig.position, FLOOR_LEVEL_M)
	var onto_tick := rig.tick
	rig.step(MovementRig.idle())
	assert_bool(rig.last_facts.floor_is_fighter).override_failure_message("no head").is_true()
	_assert_on_head(rig.state, onto_tick, _back_of(0.0))
	assert_int(rig.state.mode_since).override_failure_message("AIR must begin on this tick") \
			.is_equal(onto_tick)
	assert_int(rig.state.left_floor_tick).override_failure_message("the coyote opened") \
			.is_equal(FighterState.NEVER)
	var press_tick := rig.tick
	assert_int(press_tick - onto_tick).is_less_equal(COYOTE_TICKS[tickrate])
	var plan := rig.step(MovementRig.press_jump())
	_assert_double_jumped(rig, plan, press_tick)
	assert_int(rig.state.left_floor_tick).is_equal(FighterState.NEVER)


# An exactly centred landing has no normal to flatten: the slide goes toward the back of where
# the body faces, at the yaw of the landing tick, and the next tick already moves at 3 m/s that
# way (movimento.md, "O corpo": "Escorregar da cabeça": "num pouso exato no centro, para as
# costas de onde o corpo olha").
func test_an_exactly_centred_landing_slides_toward_the_back_of_the_facing(
	tickrate: int,
	yaw: float,
	_test_parameters := [
		[60, 0.0],
		[60, PI / 2.0],
		[60, PI],
		[60, -PI / 4.0],
		[60, 2.3],
		[30, 2.3],
		[30, -PI / 2.0],
	],
) -> void:
	var rig := _rig(tickrate)
	var head := _standing_head(rig, Vector3(-3.0, 0.0, 4.0))
	var landing_tick := _fall_onto(rig, head, Vector3.ZERO, yaw)
	assert_vector(rig.last_facts.fighter_away).is_equal(Vector3.ZERO)
	_assert_on_head(rig.state, landing_tick, _back_of(yaw))
	var plan := rig.step(MovementRig.run(Vector2.ZERO, yaw))
	var expected := _back_of(yaw) * HEAD_SLIDE_SPEED_MPS
	var message := "slide velocity %s, expected %s" % [_horizontal(plan.velocity), expected]
	assert_vector(_horizontal(plan.velocity)).override_failure_message(message).is_equal_approx(
		expected,
		Vector3.ONE * GEOMETRY_HAIR,
	)


# Limit: a flattened normal shorter than 1e-6 is the centre and slides toward the back; one
# longer than that is a direction of its own (TASK-10.7 plan: "shorter than 1e-6"). The two
# offsets lie on the facing's line, so the two answers point opposite ways.
func test_a_flattened_normal_shorter_than_1e_6_is_the_centre_and_a_longer_one_is_not(
	tickrate: int,
	offset_m: float,
	toward_the_back: bool,
	_test_parameters := [
		[60, TINY_OFFSET_M, true],
		[60, SMALL_OFFSET_M, false],
		[30, TINY_OFFSET_M, true],
		[30, SMALL_OFFSET_M, false],
	],
) -> void:
	var rig := _rig(tickrate)
	var head := _standing_head(rig, Vector3.ZERO)
	var offset := Vector3(0.0, 0.0, -offset_m)
	var landing_tick := _fall_onto(rig, head, offset)
	var away := rig.last_facts.fighter_away
	if toward_the_back:
		assert_float(away.length()).override_failure_message("the rig's fact is not tiny") \
				.is_less(CENTRE_HAIR)
		_assert_on_head(rig.state, landing_tick, _back_of(0.0))
	else:
		assert_float(away.length()).override_failure_message("the rig's fact is tiny") \
				.is_greater(CENTRE_HAIR)
		_assert_on_head(rig.state, landing_tick, Vector3(0.0, 0.0, -1.0))


# The landing is stamped once: the stamp stays through the ticks on the head, and off the head
# both fields go back to their "not on a head" values.
func test_the_head_landing_tick_is_stamped_once_and_cleared_off_the_head(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var head := _standing_head(rig, Vector3.ZERO)
	var landing_tick := _fall_onto(rig, head, Vector3.ZERO)
	for _step: int in 3:
		rig.step(MovementRig.idle())
		assert_bool(rig.last_facts.floor_is_fighter).is_true()
		assert_int(rig.state.head_landing_tick).override_failure_message("restamped") \
				.is_equal(landing_tick)
		assert_vector(rig.state.slide_off_dir).is_equal_approx(
			_back_of(0.0),
			Vector3.ONE * GEOMETRY_HAIR,
		)
	var record := _slide_off(rig, EXIT_WITHIN_TICKS[tickrate])
	assert_int(record.exit_tick).is_greater(landing_tick)
	_assert_off_head(rig.state)
	assert_bool(rig.state.on_floor).override_failure_message("still on something").is_false()
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	rig.step(MovementRig.idle())
	_assert_off_head(rig.state)


# Many: a second landing stamps its own tick, after the first was cleared by the floor.
func test_a_second_landing_stamps_a_new_head_landing_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var head := _standing_head(rig, Vector3.ZERO)
	var first := _fall_onto(rig, head, Vector3.ZERO)
	assert_int(rig.state.head_landing_tick).is_equal(first)
	_slide_off(rig, EXIT_WITHIN_TICKS[tickrate])
	_idle_until_on_floor(rig)
	_assert_off_head(rig.state)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GROUND)
	var second := _fall_onto(rig, head, Vector3(0.1, 0.0, 0.0))
	assert_int(second).is_greater(first)
	_assert_on_head(rig.state, second, Vector3.RIGHT)


# A floor jump never fires on a head: with the double jump spent, the press waits in the slot,
# the slide goes on, and the jump fires on the first tick that starts on the real floor if it is
# still within the 150 ms window, by today's rules (movimento.md, "O corpo": "Sem pulo do chão";
# "Perdão": "Buffer de input").
func test_a_jump_press_on_a_head_waits_in_the_slot_and_fires_on_the_real_floor_in_the_window(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var probe := _rig(tickrate)
	var landing_tick := _jump_spend_and_land_on_a_floor_level_head(probe)
	var first_floor_tick := _idle_until_on_floor(probe)
	assert_int(first_floor_tick - landing_tick).is_less_equal(EXIT_WITHIN_TICKS[tickrate] + 1)
	var press_tick := first_floor_tick - BUFFER_TICKS[tickrate]
	assert_int(press_tick).override_failure_message("the press must come on the head") \
			.is_greater(landing_tick)
	var rig := _rig(tickrate)
	var landed := _land_on_the_floor_level_head_and_press(
		rig,
		press_tick,
		MovementRig.press_jump(),
		first_floor_tick,
	)
	assert_int(landed).is_equal(landing_tick)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GROUND)
	_assert_off_head(rig.state)
	_assert_slot(rig.state, FighterCommand.JUMP, press_tick)
	var plan := rig.step(MovementRig.idle())
	_assert_full_jump(rig, plan)


func test_a_jump_press_on_a_head_one_tick_past_the_window_does_not_fire_on_the_real_floor(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var probe := _rig(tickrate)
	var landing_tick := _jump_spend_and_land_on_a_floor_level_head(probe)
	var first_floor_tick := _idle_until_on_floor(probe)
	# One tick before the window: on the head at 60 (the tick after the landing), and on the
	# landing tick itself at 30, pressed in the air a hair before the head.
	var press_tick := first_floor_tick - BUFFER_TICKS[tickrate] - 1
	assert_int(press_tick).is_greater_equal(landing_tick)
	var rig := _rig(tickrate)
	var landed := _land_on_the_floor_level_head_and_press(
		rig,
		press_tick,
		MovementRig.press_jump(),
		first_floor_tick,
	)
	assert_int(landed).is_equal(landing_tick)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GROUND)
	var plan := rig.step(MovementRig.idle())
	_assert_no_jump(plan, 0)
	_assert_slot(plan.state, FighterCommand.NONE, FighterState.NEVER)


# On the press tick itself, on the head: nothing rises, both jumps stay used, the slot holds the
# press and the slide goes on at 3 m/s.
func test_a_jump_press_on_a_head_with_the_double_jump_spent_does_not_jump_there(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var landing_tick := _jump_spend_and_land_on_a_floor_level_head(rig)
	rig.step(MovementRig.idle())
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_jump())
	_assert_no_jump(plan, 2)
	_assert_slot(plan.state, FighterCommand.JUMP, press_tick)
	assert_int(plan.state.mode).is_equal(FighterState.Mode.AIR)
	assert_float(_horizontal(plan.velocity).dot(_back_of(0.0))).is_greater_equal(
		HEAD_SLIDE_SPEED_MPS - HAIR
	)
	assert_int(rig.state.head_landing_tick).is_equal(landing_tick)


# The double jump still held fires on a head, as in the air (F-151: "Com o pulo duplo ainda
# guardado, você consegue dar o pulo duplo"): a jump from the floor lands on a head with one
# jump used, nothing is renewed, and the press is the double jump at its own speed.
func test_a_double_jump_still_held_fires_on_a_head(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.step(MovementRig.press_jump())
	assert_int(rig.state.jumps_used).is_equal(1)
	rig.add_head(Vector3.ZERO, DOUBLE_JUMP_CATCH_M)
	var landing_tick := _idle_until_on_head(rig)
	_assert_on_head(rig.state, landing_tick, _back_of(0.0))
	assert_int(rig.state.jumps_used).override_failure_message("the head renewed the jump") \
			.is_equal(1)
	assert_int(rig.state.double_jump_tick).is_equal(FighterState.NEVER)
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_jump())
	_assert_double_jumped(rig, plan, press_tick)
	assert_bool(rig.last_facts.floor_is_fighter).override_failure_message("still on the head") \
			.is_false()
	_assert_off_head(rig.state)


# Landing on a head renews neither the jumps, nor the double jump, nor the last wall, which the
# real floor then renews by today's rules (movimento.md, "Pulo e ar": "Renovação do pulo duplo:
# ao tocar o chão"; "Corrida na parede": "Mesma parede: só vale de novo depois de tocar o chão").
func test_landing_on_a_head_renews_neither_the_jumps_nor_the_double_jump_nor_the_last_wall(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.step(MovementRig.press_jump())
	_spend_double_jump(rig)
	var double_jump_tick := rig.state.double_jump_tick
	assert_int(double_jump_tick).is_equal(FIRST_TICK + 1)
	# The last wall by hand, as a run that ended would leave it (DEC-0042 §2).
	rig.state.wall_normal = Vector3.RIGHT
	rig.state.wall_id = WALL_A
	rig.add_head(Vector3.ZERO, DOUBLE_JUMP_CATCH_M)
	var landing_tick := _idle_until_on_head(rig)
	_assert_on_head(rig.state, landing_tick, _back_of(0.0))
	assert_int(rig.state.jumps_used).override_failure_message("the head renewed the jumps") \
			.is_equal(2)
	assert_int(rig.state.double_jump_tick).override_failure_message("the head cleared it") \
			.is_equal(double_jump_tick)
	assert_str(String(rig.state.wall_id)).override_failure_message("the head cleared the wall") \
			.is_equal(String(WALL_A))
	assert_vector(rig.state.wall_normal).is_equal(Vector3.RIGHT)
	for _step: int in 2:
		rig.step(MovementRig.idle())
		assert_int(rig.state.jumps_used).is_equal(2)
		assert_int(rig.state.double_jump_tick).is_equal(double_jump_tick)
		assert_str(String(rig.state.wall_id)).is_equal(String(WALL_A))
	_slide_off(rig, EXIT_WITHIN_TICKS[tickrate])
	_idle_until_on_floor(rig)
	assert_int(rig.state.jumps_used).override_failure_message("the floor did not renew") \
			.is_equal(0)
	assert_int(rig.state.double_jump_tick).is_equal(FighterState.NEVER)
	assert_str(String(rig.state.wall_id)).is_equal("")
	assert_vector(rig.state.wall_normal).is_equal(Vector3.ZERO)


# A dash never starts on a head (movimento.md, "Dash": "Onde: só no chão"; "O corpo": "Sem pulo
# do chão nem dash"): the press pays nothing, waits in the slot and dashes on the first tick that
# starts on the real floor, within the window, by today's rules.
func test_a_dash_press_on_a_head_does_not_dash_and_waits_for_the_real_floor(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var probe := _rig(tickrate)
	var landing_tick := _jump_spend_and_land_on_a_floor_level_head(probe)
	var first_floor_tick := _idle_until_on_floor(probe)
	var press_tick := first_floor_tick - BUFFER_TICKS[tickrate]
	assert_int(press_tick).override_failure_message("the press must come on the head") \
			.is_greater(landing_tick)
	var rig := _rig(tickrate)
	var landed := _land_on_the_floor_level_head_and_press(
		rig,
		press_tick,
		MovementRig.press_dash(),
		first_floor_tick,
	)
	assert_int(landed).is_equal(landing_tick)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GROUND)
	_assert_slot(rig.state, FighterCommand.DASH, press_tick)
	assert_int(rig.state.dash_tick).is_equal(FighterState.NEVER)
	var plan := rig.step(MovementRig.idle())
	assert_int(plan.state.mode).override_failure_message("no dash on the floor").is_equal(
		FighterState.Mode.DASH
	)
	assert_int(plan.state.dash_tick).is_equal(first_floor_tick)
	assert_int(plan.state.stamina_spent_tick).is_equal(first_floor_tick)
	_assert_slot(plan.state, FighterCommand.NONE, FighterState.NEVER)


func test_a_dash_press_on_a_head_does_not_dash_there(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var head := _standing_head(rig, Vector3.ZERO)
	_fall_onto(rig, head, Vector3(0.1, 0.0, 0.0))
	var stamina_before := rig.stamina()
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_dash_toward(FORWARD))
	_assert_no_dash(plan)
	assert_int(plan.state.mode).is_equal(FighterState.Mode.AIR)
	_assert_slot(plan.state, FighterCommand.DASH, press_tick)
	assert_int(plan.state.stamina_spent_tick).is_equal(FighterState.NEVER)
	assert_float(rig.stamina()).is_equal_approx(stamina_before, HAIR)
	assert_float(_horizontal(plan.velocity).length()).override_failure_message("dash speed") \
			.is_less(DASH_SPEED_MPS)
	assert_float(_horizontal(plan.velocity).dot(Vector3.RIGHT)).is_greater_equal(
		HEAD_SLIDE_SPEED_MPS - HAIR
	)


# Sliding off a head opens no coyote (movimento.md, "Perdão": "nem ao escorregar dela"): off the
# head the body is in the air with no ledge stamp, and a press inside what would be the window is
# the double jump, never the full jump.
func test_sliding_off_a_head_opens_no_coyote(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var head := _standing_head(rig, Vector3.ZERO)
	_fall_onto(rig, head, Vector3.ZERO)
	var record := _slide_off(rig, EXIT_WITHIN_TICKS[tickrate])
	assert_bool(rig.state.on_floor).is_false()
	assert_int(rig.state.left_floor_tick).override_failure_message("the slide opened the coyote") \
			.is_equal(FighterState.NEVER)
	var press_tick := rig.tick
	assert_int(press_tick - record.exit_tick).is_less_equal(COYOTE_TICKS[tickrate])
	var plan := rig.step(MovementRig.press_jump())
	_assert_double_jumped(rig, plan, press_tick)


# The air's gravity pulls on every tick on a head: from a vertical of 0, the plan's vertical is
# the same as one tick in the air, while on the real floor it is none (movimento.md, "O corpo":
# "com a gravidade do ar").
func test_the_air_gravity_pulls_on_every_tick_on_a_head(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var gravity := _air_gravity_from_rest(tickrate)
	var rig := _rig(tickrate)
	rig.rest(2)
	assert_float(rig.last_plan.velocity.y).override_failure_message("gravity on the floor") \
			.is_equal_approx(0.0, HAIR)
	var head := _standing_head(rig, Vector3.ZERO)
	_fall_onto(rig, head, Vector3.ZERO)
	var record := _slide_off(rig, EXIT_WITHIN_TICKS[tickrate])
	assert_int(record.head_ticks()).is_greater_equal(3)
	for index: int in record.plans.size():
		var message := "tick %d on the head: vertical %.4f, the air gives %.4f" % [
			index + 1,
			record.plans[index].velocity.y,
			gravity,
		]
		assert_float(record.plans[index].velocity.y).override_failure_message(message) \
				.is_equal_approx(gravity, HAIR)


# On every tick on the head the horizontal component along the slide direction is at least
# 3 m/s, and with no input it is exactly that (movimento.md, "O corpo": "Escorregar da cabeça":
# 3,0 m/s).
func test_the_slide_is_at_least_3_mps_along_its_direction_on_every_tick_on_the_head(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var head := _standing_head(rig, Vector3(2.0, 0.0, 1.0))
	_fall_onto(rig, head, Vector3.ZERO)
	var record := _slide_off(rig, EXIT_WITHIN_TICKS[tickrate])
	assert_int(record.plans.size()).is_greater_equal(3)
	for index: int in record.plans.size():
		var along := _horizontal(record.plans[index].velocity).dot(record.dirs_before[index])
		var message := "tick %d on the head: %.4f m/s along %s" % [
			index + 1,
			along,
			record.dirs_before[index],
		]
		assert_float(along).override_failure_message(message).is_greater_equal(
			HEAD_SLIDE_SPEED_MPS - HAIR
		)
		assert_float(_horizontal(record.plans[index].velocity).length()) \
				.override_failure_message(message) \
				.is_equal_approx(HEAD_SLIDE_SPEED_MPS, GEOMETRY_HAIR)


# A faster component along the slide direction is kept, and the component across it is not
# touched (TASK-10.7 plan: "raised to at least head_slide_speed (a faster component is kept)").
func test_a_faster_component_along_the_slide_is_kept_and_the_one_across_it_is_not_touched(
	tickrate: int,
	incoming: Vector3,
	expected: Vector3,
	_test_parameters := [
		[60, Vector3(FASTER_THAN_SLIDE_MPS, 0.0, 0.0), Vector3(FASTER_THAN_SLIDE_MPS, 0.0, 0.0)],
		[30, Vector3(FASTER_THAN_SLIDE_MPS, 0.0, 0.0), Vector3(FASTER_THAN_SLIDE_MPS, 0.0, 0.0)],
		[60, Vector3(0.0, 0.0, SIDEWAYS_MPS), Vector3(HEAD_SLIDE_SPEED_MPS, 0.0, SIDEWAYS_MPS)],
		[30, Vector3(0.0, 0.0, SIDEWAYS_MPS), Vector3(HEAD_SLIDE_SPEED_MPS, 0.0, SIDEWAYS_MPS)],
		[60, Vector3(-FASTER_THAN_SLIDE_MPS, 0.0, 0.0), Vector3(HEAD_SLIDE_SPEED_MPS, 0.0, 0.0)],
		[30, Vector3(-FASTER_THAN_SLIDE_MPS, 0.0, 0.0), Vector3(HEAD_SLIDE_SPEED_MPS, 0.0, 0.0)],
	],
) -> void:
	var rig := _rig(tickrate)
	var head := _standing_head(rig, Vector3.ZERO)
	# A hair above the top, placed so that the next tick's move lands the feet 10 cm off the axis
	# toward +X, whatever the incoming horizontal: the slide direction is then +X exactly.
	var landing_feet := Vector3(0.1, CAPSULE_HEIGHT_M, 0.0)
	var one_tick := Vector3(incoming.x, 0.0, incoming.z) / float(tickrate)
	rig.airborne(
		landing_feet - one_tick + Vector3.UP * JUST_ABOVE_M,
		Vector3(incoming.x, FALL_SPEED_MPS, incoming.z),
	)
	var landing_tick := rig.tick
	rig.step(MovementRig.idle())
	assert_bool(rig.last_facts.floor_is_fighter).override_failure_message("missed the head") \
			.is_true()
	assert_vector(rig.position).is_equal_approx(landing_feet, Vector3.ONE * GEOMETRY_HAIR)
	assert_float(head.offset_of(rig.position).length()).is_less(HEAD_RADIUS_M)
	_assert_on_head(rig.state, landing_tick, Vector3.RIGHT)
	var plan := rig.step(MovementRig.idle())
	var message := "first slide tick: %s, expected %s" % [_horizontal(plan.velocity), expected]
	assert_vector(_horizontal(plan.velocity)).override_failure_message(message).is_equal_approx(
		expected,
		Vector3.ONE * GEOMETRY_HAIR,
	)
	while rig.last_facts.floor_is_fighter:
		var dir := rig.state.slide_off_dir
		var next := rig.step(MovementRig.idle())
		assert_float(_horizontal(next.velocity).dot(dir)).is_greater_equal(
			HEAD_SLIDE_SPEED_MPS - HAIR
		)


# Limit: from an exactly centred landing the feet leave the dome's floor radius within 12 ticks
# at 60 and 6 at 30, counted from the tick after the landing, and with no input in exactly the
# 10 and 5 of the design (criterion 1; movimento.md, "O corpo": "Escorregar da cabeça": "do
# centro, 10 ticks a 60, uns 0,2 s"). The exit is the rig's own predicate: the head no longer
# holds the feet.
func test_from_the_exact_centre_the_feet_leave_the_head_within_12_ticks_at_60_and_6_at_30(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var head := _standing_head(rig, Vector3(5.0, 0.0, -5.0))
	var landing_tick := _fall_onto(rig, head, Vector3.ZERO)
	assert_float(head.offset_of(rig.position).length()).is_less_equal(HAIR)
	var record := _slide_off(rig, EXIT_WITHIN_TICKS[tickrate] + 1)
	var ticks := record.exit_tick - landing_tick
	var message := "left the head %d ticks after the landing at %d ticks, at most %d" % [
		ticks,
		tickrate,
		EXIT_WITHIN_TICKS[tickrate],
	]
	assert_int(ticks).override_failure_message(message).is_less_equal(EXIT_WITHIN_TICKS[tickrate])
	assert_int(ticks).override_failure_message(message).is_equal(EXIT_FROM_CENTRE_TICKS[tickrate])
	var last := record.distances_after.size() - 1
	assert_float(record.distances_after[last]).is_greater_equal(HEAD_RADIUS_M)
	assert_float(record.distances_after[last - 1]).is_less(HEAD_RADIUS_M)
	_assert_off_head(rig.state)


# The grapple fires from a head as from the air (movimento.md, "Gancho": "De onde dispara";
# "O corpo": "o pulo duplo guardado e o gancho saem como no ar"): the plan asks for the aim, the
# hook bites, and the pull starts after the cable's 100 ms while the body is still sliding.
func test_the_grapple_fires_from_a_head_and_the_pull_starts_after_the_cable(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var head := _standing_head(rig, Vector3.ZERO)
	_fall_onto(rig, head, Vector3.ZERO)
	rig.step(MovementRig.idle())
	assert_bool(rig.last_facts.floor_is_fighter).is_true()
	var point := rig.position + POINT_UP_AHEAD
	var fire_tick := _fire(rig, point)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	assert_bool(rig.last_facts.floor_is_fighter).override_failure_message("left the head") \
			.is_true()
	for _step: int in ATTACH_TICKS[tickrate] - 1:
		var cable := rig.step(MovementRig.idle())
		assert_int(cable.state.mode).is_equal(FighterState.Mode.AIR)
	var feet := rig.position
	var first := rig.step(MovementRig.idle())
	assert_int(rig.tick - 1).is_equal(fire_tick + ATTACH_TICKS[tickrate])
	_assert_pull_tick(first, feet, point)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GRAPPLE)


# A committed dash is not cut by a head under the feet (DEC-0041): the dash from the floor runs
# over a head at floor level with its mode, its speed and its 4 m intact, and exits on the ground
# past it (movimento.md, "Dash": "Comprometido").
func test_a_committed_dash_runs_over_a_head_without_being_cut(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.add_head(HEAD_AHEAD_OF_DASH, FLOOR_LEVEL_M)
	var press_tick := rig.tick
	var start := rig.position
	var head_ticks := 0
	var direction := Vector3.FORWARD
	for step: int in DASH_TICKS[tickrate]:
		var input := MovementRig.press_dash_toward(FORWARD) if step == 0 else MovementRig.idle()
		var plan := rig.step(input)
		assert_int(plan.state.mode).override_failure_message("tick %d left DASH" % step) \
				.is_equal(FighterState.Mode.DASH)
		assert_int(plan.state.dash_tick).is_equal(press_tick)
		assert_vector(_horizontal(plan.velocity)).is_equal_approx(
			direction * DASH_SPEED_MPS,
			Vector3.ONE * GEOMETRY_HAIR,
		)
		if rig.last_facts.floor_is_fighter:
			head_ticks += 1
	assert_int(head_ticks).override_failure_message("the dash never crossed the head") \
			.is_greater_equal(1)
	var moved := rig.position - start
	assert_vector(moved).is_equal_approx(
		direction * DASH_DISTANCE_M,
		Vector3.ONE * 0.01, # 1 cm, the dash's own tolerance (TASK-10.4, criterion 1)
	)
	var exit := rig.step(MovementRig.idle())
	assert_int(exit.state.mode).is_not_equal(FighterState.Mode.DASH)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GROUND)
	_assert_off_head(rig.state)


# A committed pull is not cut by a head under the feet either (DEC-0041): a pull along the floor
# over a head at floor level keeps the pull's velocity on every tick, with the head under the feet
# on some of them, and releases on the ground as before.
func test_a_committed_pull_runs_over_a_head_without_being_cut(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.add_head(HEAD_ALONG_PULL, FLOOR_LEVEL_M)
	_fire(rig, POINT_ALONG_FLOOR)
	var record := _record_pull(rig, 5 * tickrate)
	assert_int(record.plans.size()).is_greater_equal(20)
	assert_int(record.head_ticks()).override_failure_message("the pull never crossed the head") \
			.is_greater_equal(1)
	for index: int in record.plans.size():
		_assert_pull_tick(record.plans[index], record.starts[index], POINT_ALONG_FLOOR)
		assert_bool(record.plans[index].state.on_floor).is_true()
	assert_int(record.release_plan.state.mode).is_equal(FighterState.Mode.GROUND)
	assert_int(record.release_plan.state.mode_since).is_equal(record.release_tick)
	assert_float(rig.position.distance_to(POINT_ALONG_FLOOR)).is_less(
		GRAPPLE_RELEASE_DISTANCE_M + GRAPPLE_PULL_SPEED_MPS / float(tickrate)
	)
	_assert_off_head(rig.state)
