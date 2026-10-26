# Criteria 3 to 6 of TASK-10.6: the grapple (movimento.md, "Gancho"), the first rule that asks
# the scenery from inside the tick (DEC-0044): a legal press in the slot sets MovePlan.aim_request,
# the engine answers in the MoveFacts after the move, after_move fires when the hit is 3 to 25 m
# from the point O (TASK-10.11; DEC-0045: the feet after the move, plus 1,6 m up, plus 0,8 m to
# the right of the tick's yaw), the cable flies 100 ms, and the pull, a committed mode
# (DEC-0041), takes the feet to the point at 18 m/s until one of three releases, with the
# cooldown of 6 s counted from
# the release and the single slot of the buffer (DEC-0039; movimento.md, "Perdão"). Through the
# public interface of core/fighter, with the engine's slice of the tick played by MovementRig: the
# test sets what the ray would find (visao-geral.md, "O tick por dentro: o sanduíche"). Every
# number comes from docs/design/movimento.md, cited by section; ticks by hand from the ms, nearest
# tick with ties up (visao-geral.md, "O tempo e a física no estado").
extends GdUnitTestSuite

const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)

# movimento.md, "Gancho".
const GRAPPLE_RANGE_M := 25.0 # "Alcance", measured from the point O along the aim (DEC-0045)
const GRAPPLE_MIN_RANGE_M := 3.0 # "Alcance mínimo": closer to O is a miss
# "De onde sai a mira": O is 1,6 m above the feet ("Câmera": "Altura do pivô") and 0,8 m to the
# right of the yaw ("Câmera": "Ombro").
const AIM_HEIGHT_M := 1.6
const AIM_SIDE_M := 0.8
const GRAPPLE_ATTACH_MS := 100 # "Tempo até prender": the cable's flight
const GRAPPLE_PULL_SPEED_MPS := 18.0 # "Velocidade da puxada"
const GRAPPLE_RELEASE_DISTANCE_M := 1.5 # "Como solta": the feet 1,5 m from the point
const GRAPPLE_BLOCK_PCT := 50.0 # "Trava": below 50 % of the pull
const GRAPPLE_BLOCK_SPEED_MPS := 9.0 # "Trava": 9 m/s, the half of 18
const GRAPPLE_COOLDOWN_MS := 6000 # "Recarga": 6 s from the release
# Just outside the range, both ends: TASK-10.6, criterion 3 ("a 2,99 m, a 25,01 m"), and a hair
# outside, TASK-10.11 plan ("2,999 m and 25,001 m from O do not"): arithmetic on the limits.
const JUST_BELOW_MIN_M := 2.99
const JUST_ABOVE_RANGE_M := 25.01
const A_HAIR_BELOW_MIN_M := 2.999
const A_HAIR_ABOVE_RANGE_M := 25.001
# A point straight ahead of the shoulder, 25 m off, is 25,0128 m from O (sqrt(25² + 0,8²)), out
# of reach; one 2,9 m ahead of the shoulder is 3,0083 m from O, in reach (TASK-10.11 plan).
const AHEAD_OF_THE_SHOULDER_OUT_M := 25.0
const AHEAD_OF_THE_SHOULDER_IN_M := 2.9
# A move on the fire tick that tells the feet before and after apart: the run's 7 m/s moves
# 0,117 m at 60 ticks and 0,233 at 30 (movimento.md, "Chão"), so a point this far past a limit
# at the start of the tick is on the other side of it after the move. Arithmetic.
const MOVE_MARGIN_M := 0.05

# movimento.md, "Pulo e ar", "Perdão", "Dash" and "Corrida na parede", as the other suites read
# them.
const COYOTE_MS := 100 # "Perdão": "Coyote time"
const DOUBLE_JUMP_COST := 10.0 # "Pulo e ar": "Custo do pulo duplo"
const WALL_RUN_SPEED_MPS := 8.0 # "Corrida na parede": "Velocidade na parede"

# The grapple times by hand (movimento.md, "Gancho"): 100 ms of cable is 3 ticks at 30 and 6 at
# 60, exact; 6 s of cooldown is 180 and 360, exact. 150 ms of buffer is 4.5 -> 5 at 30 (tie up)
# and 9 at 60, inclusive ("Perdão"; DEC-0039); 100 ms of coyote is 3 and 6; the dash of 200 ms is
# 6 and 12 ("Dash").
const ATTACH_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
const COOLDOWN_TICKS: Dictionary[int, int] = { 30: 180, 60: 360 }
const BUFFER_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }
const COYOTE_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
const DASH_TICKS: Dictionary[int, int] = { 30: 6, 60: 12 }

# The geometry of the rig, not design numbers. From the feet at rest, the point up and ahead is
# 10 m away (6 up, 8 ahead) and 9,17 m from O (sqrt(0,8² + 4,4² + 8²)), well inside 3 to 25 m;
# the point along the floor is 20 m ahead, 20,08 m from O.
const POINT_UP_AHEAD := Vector3(0.0, 6.0, -8.0)
const POINT_ALONG_FLOOR := Vector3(0.0, 0.0, -20.0)
const START_HEIGHT_M := 10.0 # the air starts, far above the floor
const PULL_AHEAD_M := 12.0 # the horizontal pull of the wall cases, 12 m ahead
const BLOCKER_Z := -3.0 # the stopping wall, 3 m ahead of the air start
const SLIDER_Z := -1.0 # the sliding faces, 1 m ahead of the air start
const SHORT_FACE_M := 0.6 # how far along the 60° face runs past the first contact
const RELEASE_BELOW_FEET_M := 1.45 # a point under the feet: 1,45 m down, 3,15 m from O
const NUDGE := Vector3(1.0, 0.0, 0.0) # the engine moved the body sideways during the pull
# The sliding faces: the slide keeps 18 sin² θ m/s toward the point, so 40° leaves 7,4 m/s, below
# the 9 of the block, and 60° leaves 13,5, above it (arithmetic on the design's 18 and 50 %).
const SLIDE_BELOW_BLOCK_DEG := 40.0
const SLIDE_ABOVE_BLOCK_DEG := 60.0
# The wall run's approach, as in movement_wall_test.gd.
const APPROACH_M := 0.9
const APPROACH_SPEED_MPS := 2.0
const FALLING_VERTICAL_MPS := -6.0
const WALL_A := &"ParedeA" # ids as the adapter reports them: node paths relative to the Arena
const BLOCKER := &"Bloqueio"
const FORWARD := Vector2(0, 1) # move.y goes forward: yaw 0 looks down -Z (TASK-9 plan)
const RIGHT := Vector2(1, 0)
const BACK_LEFT := Vector2(-0.7071, -0.7071)

const HAIR := 1e-6 # floating-point slack, not a design number
# A Vector3 holds 32-bit floats: a normalized direction times 18 carries that error.
const GEOMETRY_HAIR := 1e-4
const HALF_TICK_IN_MS_TIMES_RATE := 500 # |ticks * 1000 - ms * rate| <= 500 is half a tick


# One grapple from the fire tick on: the cable ticks, the pull ticks (each with the plan, the
# feet and the velocity the tick started with) and the release tick.
class GrappleRecord:
	var fire_tick := 0
	var cable_ticks := 0 # ticks between the fire and the first pull tick
	var pull_start_tick := 0 # the first tick whose plan is GRAPPLE; 0 if the pull never started
	var plans: Array[MovePlan] = [] # the pull ticks
	var starts: Array[Vector3] = [] # the feet at the start of each pull tick
	var incomings: Array[Vector3] = [] # the velocity at the start of each pull tick
	var release_tick := 0
	var release_plan: MovePlan
	var release_start := Vector3.ZERO
	var release_incoming := Vector3.ZERO


	func pull_ticks() -> int:
		return plans.size()


func _rig(tickrate: int) -> MovementRig:
	var rig := MovementRig.new(MovementRig.load_config(tickrate), FIRST_TICK)
	rig.aim_hit = false
	rig.aim_point = Vector3.ZERO
	return rig


# A rig with no floor at all: the body never lands.
func _air_rig(tickrate: int) -> MovementRig:
	var rig := _rig(tickrate)
	rig.floor_on = false
	return rig


# The point O the reach is measured from (movimento.md, "Gancho": "De onde sai a mira";
# DEC-0045 §2): the feet, plus 1,6 m up, plus 0,8 m to the right of the yaw. By hand, not through
# Aim.origin, so the fire rule is checked against the paper: for yaw θ the right is
# (cos θ, 0, -sin θ), the +X the move's Basis(UP, yaw) turns (TASK-9 plan; TASK-10.11 plan).
func _origin_of(feet: Vector3, yaw := 0.0) -> Vector3:
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	return feet + Vector3.UP * AIM_HEIGHT_M + right * AIM_SIDE_M


# The shoulder the ray used to leave (DEC-0044 §2, superseded by DEC-0045): 1,6 m above the feet,
# O with no side. Only for the cases that tell O and the shoulder apart.
func _shoulder_of(feet: Vector3) -> Vector3:
	return feet + Vector3.UP * AIM_HEIGHT_M


# The point this far from O, straight ahead (-Z), for a body at rest with yaw 0 on the fire tick:
# only z differs from O, so the distance is exact in 32-bit floats even at the inclusive limits.
func _point_ahead(rig: MovementRig, distance_from_origin: float) -> Vector3:
	return _origin_of(rig.position) + Vector3.FORWARD * distance_from_origin


# A copy of movement_v0.tres with another aim side, as a config: the shoulder (0) or the left
# one (negative), to prove the rule reads the number instead of knowing it.
func _config_with_aim_side(side_m: float, tickrate: int) -> MovementConfig:
	var resource: Resource = load(MovementRig.MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MovementRig.MOVEMENT_V0)
	var copy: Resource = (resource as MovementData).duplicate()
	assert(copy is MovementData, "a duplicate must still be a MovementData")
	var data := copy as MovementData
	data.aim_side_m = side_m
	assert_array(data.validate()).override_failure_message("a side of %s must pass" % side_m) \
			.is_empty()
	return MovementConfig.create(data, tickrate)


func _aim_at(rig: MovementRig, point: Vector3) -> void:
	rig.aim_hit = true
	rig.aim_point = point


func _aim_at_the_sky(rig: MovementRig) -> void:
	rig.aim_hit = false
	rig.aim_point = Vector3.ZERO


# Presses the grapple now with the aim on this point; asserts the plan asked and the hook bit on
# this tick. Returns the fire tick.
func _fire(rig: MovementRig, point: Vector3) -> int:
	_aim_at(rig, point)
	var fire_tick := rig.tick
	var plan := rig.step(MovementRig.press_grapple())
	assert_bool(plan.aim_request).override_failure_message("the plan did not ask for the aim") \
			.is_true()
	_assert_fired(rig.state, fire_tick, point)
	return fire_tick


# Idles from right after the fire (or feeds `during` on the pull ticks, cycled) and records the
# cable, the pull and the release, or fails after `limit` ticks.
func _record_grapple(
	rig: MovementRig,
	fire_tick: int,
	limit: int,
	during: Array[TickInput] = [],
) -> GrappleRecord:
	var record := GrappleRecord.new()
	record.fire_tick = fire_tick
	var end_before := rig.state.grapple_end_tick
	for _step: int in limit:
		var start := rig.position
		var incoming := rig.velocity
		var input := MovementRig.idle()
		if not during.is_empty() and record.pull_start_tick != 0:
			input = during[record.plans.size() % during.size()]
		var plan := rig.step(input)
		if plan.state.mode == FighterState.Mode.GRAPPLE:
			if record.pull_start_tick == 0:
				record.pull_start_tick = rig.tick - 1
			record.plans.append(plan)
			record.starts.append(start)
			record.incomings.append(incoming)
		elif plan.state.grapple_end_tick != end_before:
			record.release_tick = rig.tick - 1
			record.release_plan = plan
			record.release_start = start
			record.release_incoming = incoming
			return record
		else:
			record.cable_ticks += 1
	fail("no release within %d ticks after the fire (at %d ticks)" % [limit, rig.config.tickrate])
	return record


# Fires from rest on the floor at the point up and ahead and records the whole grapple.
func _grapple_from_rest(rig: MovementRig, during: Array[TickInput] = []) -> GrappleRecord:
	var fire_tick := _fire(rig, POINT_UP_AHEAD)
	return _record_grapple(rig, fire_tick, 5 * rig.config.tickrate, during)


# Idles until the plan's mode is GRAPPLE; returns the first pull tick, or fails.
func _idle_until_pull(rig: MovementRig, limit: int) -> int:
	for _step: int in limit:
		var plan := rig.step(MovementRig.idle())
		if plan.state.mode == FighterState.Mode.GRAPPLE:
			return rig.tick - 1
	fail("the pull never started within %d ticks (at %d ticks)" % [limit, rig.config.tickrate])
	return -1


# Idles until the fighter lands; returns the landing tick, or fails.
func _idle_until_landed(rig: MovementRig) -> int:
	for _step: int in range(1, 5 * rig.config.tickrate + 1):
		rig.step(MovementRig.idle())
		if rig.state.on_floor:
			return rig.tick - 1
	fail("never landed at %d ticks" % rig.config.tickrate)
	return 0


func _spend_double_jump(rig: MovementRig) -> void:
	var plan := rig.step(MovementRig.press_jump())
	assert_int(plan.state.jumps_used).override_failure_message("not spent").is_equal(2)


# Idles up to (not including) `until`, pressing `press` on press_tick, with the aim set; asserts
# no plan asks for the aim and no grapple fires in between.
func _idle_until_with_press(
	rig: MovementRig,
	until: int,
	press_tick: int,
	press: TickInput,
) -> void:
	var violations: Array[String] = []
	while rig.tick < until:
		var input := press if rig.tick == press_tick else MovementRig.idle()
		var plan := rig.step(input)
		if plan.aim_request:
			violations.append("tick %d: asked for the aim" % (rig.tick - 1))
		if rig.state.grapple_fired_tick != FighterState.NEVER:
			violations.append("tick %d: fired" % (rig.tick - 1))
	assert_array(violations).override_failure_message("before tick %d: %s" % [until, violations]) \
			.is_empty()


# The wall of the wall run at x = 0 facing +X; the body approaches it in the air, running -Z.
func _run_on_wall_a(rig: MovementRig) -> int:
	rig.add_wall(Vector3.RIGHT, 0.0, WALL_A)
	rig.airborne(
		Vector3(APPROACH_M, START_HEIGHT_M, 0.0),
		Vector3(-APPROACH_SPEED_MPS, FALLING_VERTICAL_MPS, -WALL_RUN_SPEED_MPS),
	)
	for _step: int in 2 * rig.config.tickrate:
		rig.step(MovementRig.idle())
		if rig.state.mode == FighterState.Mode.WALL_RUN:
			return rig.tick - 1
	fail("never started a wall run (at %d ticks)" % rig.config.tickrate)
	return -1


# A vertical face whose normal is turned `degrees` about the vertical from +Z toward +X, through
# the point (0, START_HEIGHT_M, z): the body flying -Z from x = 0 meets it at that z.
func _add_turned_face(
	rig: MovementRig,
	degrees: float,
	z: float,
	id: StringName,
) \
-> MovementRig.FakeWall:
	var normal := Vector3(sin(deg_to_rad(degrees)), 0.0, cos(deg_to_rad(degrees)))
	var through := Vector3(0.0, START_HEIGHT_M, z)
	return rig.add_wall(normal, normal.dot(through), id)


# The largest change a free tick may make to the velocity: gravity (rise or fall) plus the air
# control in the air, or the stop and the acceleration on the floor. A kept velocity stays within
# it; a pull (18 m/s) or a zeroed one does not.
func _free_tick_slack(rig: MovementRig) -> float:
	var air := maxf(rig.config.rise_gravity_per_tick, rig.config.fall_gravity_per_tick)
	air += rig.config.air_accel_per_tick
	var ground := rig.config.stop_decel_per_tick + rig.config.ground_accel_per_tick
	return maxf(air, ground) + HAIR


# The value is not this one, beyond floating-point slack: gdUnit4 has no is_not_equal_approx.
func _assert_not_about(actual: float, unwanted: float, why: String) -> void:
	var message := "%s: %.6f is %.6f" % [why, actual, unwanted]
	assert_float(absf(actual - unwanted)).override_failure_message(message).is_greater(HAIR)


func _direction_to(point: Vector3, feet: Vector3) -> Vector3:
	return (point - feet).normalized()


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


# The fire as the plan says it (TASK-10.6 notes): the hook bit on this tick, the point fixed, the
# slot cleared.
func _assert_fired(state: FighterState, fire_tick: int, point: Vector3) -> void:
	var stamp := "grapple_fired_tick is %d, expected %d" % [state.grapple_fired_tick, fire_tick]
	assert_int(state.grapple_fired_tick).override_failure_message(stamp).is_equal(fire_tick)
	var fixed := "grapple_point is %s, expected %s" % [state.grapple_point, point]
	assert_vector(state.grapple_point).override_failure_message(fixed).is_equal_approx(
		point,
		Vector3.ONE * HAIR,
	)
	_assert_slot(state, FighterCommand.NONE, FighterState.NEVER)


func _assert_not_fired(state: FighterState) -> void:
	assert_int(state.grapple_fired_tick).override_failure_message("a grapple fired").is_equal(
		FighterState.NEVER
	)


# A tick of the pull: GRAPPLE, and the velocity the unit vector from the feet at the start of the
# tick to the point, times 18 m/s: no gravity, no input (movimento.md, "Gancho": "Velocidade da
# puxada").
func _assert_pull_tick(plan: MovePlan, feet: Vector3, point: Vector3) -> void:
	assert_int(plan.state.mode).override_failure_message("not in GRAPPLE").is_equal(
		FighterState.Mode.GRAPPLE
	)
	var expected := _direction_to(point, feet) * GRAPPLE_PULL_SPEED_MPS
	var message := "pull velocity %s, expected %s" % [plan.velocity, expected]
	assert_vector(plan.velocity).override_failure_message(message).is_equal_approx(
		expected,
		Vector3.ONE * GEOMETRY_HAIR,
	)
	assert_float(plan.velocity.length()).is_equal_approx(GRAPPLE_PULL_SPEED_MPS, GEOMETRY_HAIR)


# The release as the plan says it (TASK-10.6 notes): the mode back by the floor's verdict since
# this tick, the end stamped, no cable in the air.
func _assert_released(plan: MovePlan, release_tick: int, mode: FighterState.Mode) -> void:
	assert_int(plan.state.mode).override_failure_message("still in GRAPPLE").is_not_equal(
		FighterState.Mode.GRAPPLE
	)
	assert_int(plan.state.mode).is_equal(mode)
	assert_int(plan.state.mode_since).is_equal(release_tick)
	assert_int(plan.state.grapple_end_tick).override_failure_message("the end was not stamped") \
			.is_equal(release_tick)
	assert_int(plan.state.grapple_fired_tick).override_failure_message("the cable is still out") \
			.is_equal(FighterState.NEVER)


# The release tick runs as a free tick on the incoming velocity: within one tick of gravity and
# control of it, never the pull's 18 m/s again and never zeroed (movimento.md, "Gancho": "Como
# solta": "Conserva a velocidade").
func _assert_velocity_kept(rig: MovementRig, plan: MovePlan, incoming: Vector3) -> void:
	var slack := _free_tick_slack(rig)
	var message := "release velocity %s, expected the incoming %s within %.3f m/s" % [
		plan.velocity,
		incoming,
		slack,
	]
	assert_vector(plan.velocity).override_failure_message(message).is_equal_approx(
		incoming,
		Vector3.ONE * slack,
	)


# The full jump as the other suites read it: the jump's exit speed, the first jump of the flight,
# the slot consumed; the mode is the contact's business (after_move), not asserted here.
func _assert_full_jump(rig: MovementRig, plan: MovePlan) -> void:
	assert_float(plan.velocity.y).override_failure_message("not the full jump") \
			.is_equal_approx(rig.config.jump_speed, HAIR)
	assert_int(plan.state.jumps_used).is_equal(1)
	assert_int(plan.state.mode).is_not_equal(FighterState.Mode.GRAPPLE)
	assert_int(plan.state.mode).is_not_equal(FighterState.Mode.DASH)
	_assert_slot(plan.state, FighterCommand.NONE, FighterState.NEVER)


func _assert_double_jumped(rig: MovementRig, plan: MovePlan, press_tick: int) -> void:
	assert_float(plan.velocity.y).override_failure_message("not the double jump speed") \
			.is_equal_approx(rig.config.double_jump_speed, HAIR)
	_assert_not_about(plan.velocity.y, rig.config.jump_speed, "the full jump came out")
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


# None: a fresh state has no grapple, and the mode, the command, the input, the plan and the facts
# exist under the agreed names (TASK-10.6 notes: State, Input, Plan and facts).
func test_a_fresh_state_has_no_grapple_and_the_agreed_names_exist() -> void:
	var state := FighterState.new()
	assert_int(state.grapple_fired_tick).is_equal(FighterState.NEVER)
	assert_vector(state.grapple_point).is_equal(Vector3.ZERO)
	assert_int(state.grapple_end_tick).is_equal(FighterState.NEVER)
	assert_int(FighterState.Mode.GRAPPLE).is_equal(4)
	assert_int(FighterState.Mode.GRAPPLE).is_not_equal(FighterState.Mode.GROUND)
	assert_int(FighterState.Mode.GRAPPLE).is_not_equal(FighterState.Mode.AIR)
	assert_int(FighterState.Mode.GRAPPLE).is_not_equal(FighterState.Mode.DASH)
	assert_int(FighterState.Mode.GRAPPLE).is_not_equal(FighterState.Mode.WALL_RUN)
	assert_str(String(FighterCommand.GRAPPLE)).is_equal("grapple")
	assert_str(String(FighterCommand.GRAPPLE)).is_not_equal(String(FighterCommand.JUMP))
	assert_str(String(FighterCommand.GRAPPLE)).is_not_equal(String(FighterCommand.DASH))
	var input := TickInput.new()
	assert_float(input.pitch).is_equal(0.0)
	assert_bool(input.grapple).is_false()
	var plan := MovePlan.new()
	assert_bool(plan.aim_request).is_false()
	var facts := MoveFacts.new()
	assert_vector(facts.position).is_equal(Vector3.ZERO)
	assert_bool(facts.aim_hit).is_false()
	assert_vector(facts.aim_point).is_equal(Vector3.ZERO)


# The three grapple fields travel with copy(): a field left out would come back as its default
# after a rollback (visao-geral.md).
func test_fighter_state_copy_carries_the_grapple_fields() -> void:
	var original := _rig(60).state
	original.mode = FighterState.Mode.GRAPPLE
	original.grapple_fired_tick = 1234
	original.grapple_point = Vector3(1.0, 2.0, -3.0)
	original.grapple_end_tick = 1200
	var copy := original.copy()
	assert_int(copy.mode).is_equal(FighterState.Mode.GRAPPLE)
	assert_int(copy.grapple_fired_tick).is_equal(1234)
	assert_vector(copy.grapple_point).is_equal(Vector3(1.0, 2.0, -3.0))
	assert_int(copy.grapple_end_tick).is_equal(1200)
	copy.grapple_fired_tick = FighterState.NEVER
	copy.grapple_point = Vector3.ZERO
	copy.grapple_end_tick = FighterState.NEVER
	copy.mode = FighterState.Mode.AIR
	assert_int(original.grapple_fired_tick).is_equal(1234)
	assert_vector(original.grapple_point).is_equal(Vector3(1.0, 2.0, -3.0))
	assert_int(original.grapple_end_tick).is_equal(1200)
	assert_int(original.mode).is_equal(FighterState.Mode.GRAPPLE)


# The hand numbers above against the config they must match (movement_v0.tres at load): the two
# grapple times become ticks by the rule of Ticks.from_ms, within half a tick (DEC-0004, rule 3),
# and the block speed is 50 % of the pull.
func test_the_config_carries_the_grapple_numbers_of_the_design(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var config := MovementRig.load_config(tickrate)
	assert_int(config.grapple_attach_ticks).is_equal(ATTACH_TICKS[tickrate])
	assert_int(config.grapple_attach_ticks).is_equal(Ticks.from_ms(GRAPPLE_ATTACH_MS, tickrate))
	assert_int(absi(config.grapple_attach_ticks * 1000 - GRAPPLE_ATTACH_MS * tickrate)) \
			.is_less_equal(HALF_TICK_IN_MS_TIMES_RATE)
	assert_int(config.grapple_cooldown_ticks).is_equal(COOLDOWN_TICKS[tickrate])
	assert_int(config.grapple_cooldown_ticks).is_equal(Ticks.from_ms(GRAPPLE_COOLDOWN_MS, tickrate))
	assert_int(absi(config.grapple_cooldown_ticks * 1000 - GRAPPLE_COOLDOWN_MS * tickrate)) \
			.is_less_equal(HALF_TICK_IN_MS_TIMES_RATE)
	assert_int(config.buffer_ticks).is_equal(BUFFER_TICKS[tickrate])
	assert_int(config.coyote_ticks).is_equal(COYOTE_TICKS[tickrate])
	assert_int(config.coyote_ticks).is_equal(Ticks.from_ms(COYOTE_MS, tickrate))
	assert_int(config.dash_ticks).is_equal(DASH_TICKS[tickrate])
	assert_float(config.grapple_range).is_equal_approx(GRAPPLE_RANGE_M, HAIR)
	assert_float(config.grapple_min_range).is_equal_approx(GRAPPLE_MIN_RANGE_M, HAIR)
	assert_float(config.grapple_pull_speed).is_equal_approx(GRAPPLE_PULL_SPEED_MPS, HAIR)
	assert_float(config.grapple_release_distance).is_equal_approx(GRAPPLE_RELEASE_DISTANCE_M, HAIR)
	assert_float(config.grapple_block_speed).is_equal_approx(GRAPPLE_BLOCK_SPEED_MPS, HAIR)
	assert_float(config.grapple_block_speed).is_equal_approx(
		GRAPPLE_PULL_SPEED_MPS * GRAPPLE_BLOCK_PCT / 100.0,
		HAIR,
	)
	assert_float(config.aim_height).is_equal_approx(AIM_HEIGHT_M, HAIR)
	assert_float(config.aim_side).is_equal_approx(AIM_SIDE_M, HAIR)
	assert_float(config.double_jump_cost).is_equal_approx(DOUBLE_JUMP_COST, HAIR)


# The rig's half of the contract (TASK-10.6 notes: "Who tests what"): with no press, the plan
# does not ask, and the facts carry no hit even when the scenery would answer, while the position
# after the move is always there.
func test_the_facts_carry_the_aim_only_when_the_plan_asked(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_aim_at(rig, _point_ahead(rig, 10.0))
	var plan := rig.step(MovementRig.run(FORWARD))
	assert_bool(plan.aim_request).is_false()
	assert_bool(rig.last_facts.aim_hit).is_false()
	assert_vector(rig.last_facts.aim_point).is_equal(Vector3.ZERO)
	assert_vector(rig.last_facts.position).is_equal(rig.position)
	assert_vector(rig.last_facts.position).is_not_equal(Vector3.ZERO)
	_assert_not_fired(rig.state)


# The slice is pure: the fire happens in the copy, never in the state after_move receives
# (DEC-0004, rule 1). The slot holds the press of this tick, as the plan that asked left it.
func test_after_move_leaves_the_state_it_receives_untouched_when_the_grapple_fires() -> void:
	var rig := _rig(60)
	var given := rig.state
	given.buffered_command = FighterCommand.GRAPPLE
	given.buffered_tick = FIRST_TICK
	var facts := MoveFacts.new()
	facts.on_floor = true
	facts.velocity = Vector3.ZERO
	facts.position = Vector3.ZERO
	facts.aim_hit = true
	facts.aim_point = POINT_UP_AHEAD
	var next := Movement.after_move(given, facts, rig.config, FIRST_TICK)
	_assert_fired(next, FIRST_TICK, POINT_UP_AHEAD)
	assert_int(given.grapple_fired_tick).is_equal(FighterState.NEVER)
	assert_vector(given.grapple_point).is_equal(Vector3.ZERO)
	_assert_slot(given, FighterCommand.GRAPPLE, FIRST_TICK)


# Criterion 3: a legal press asks for the aim on its own tick, and with no hit (the sky) nothing
# fires, the press waits in the slot and the next tick asks again (movimento.md, "Gancho": "O
# erro"; DEC-0044).
func test_a_legal_press_asks_for_the_aim_on_its_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_aim_at_the_sky(rig)
	var idle := rig.step(MovementRig.idle())
	assert_bool(idle.aim_request).override_failure_message("asked with no press").is_false()
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_grapple())
	assert_bool(plan.aim_request).override_failure_message("the press did not ask").is_true()
	_assert_slot(plan.state, FighterCommand.GRAPPLE, press_tick)
	_assert_not_fired(rig.state)
	_assert_slot(rig.state, FighterCommand.GRAPPLE, press_tick)
	var again := rig.step(MovementRig.idle())
	assert_bool(again.aim_request).override_failure_message("did not ask again").is_true()
	_assert_not_fired(rig.state)


# Criterion 3 of TASK-10.6, the range, measured from O since TASK-10.11 (DEC-0045 §2): a hit
# exactly 3 m and exactly 25 m from O fires (the limits are inclusive); 2,99 m, 25,01 m and even
# 2,999 m and 25,001 m do not, and the press stays in the slot asking again (movimento.md,
# "Gancho": "Alcance", "Alcance mínimo", "O erro").
func test_a_hit_at_the_range_limits_fires_and_just_outside_does_not(
	tickrate: int,
	distance_m: float,
	fires: bool,
	_test_parameters := [
		[30, GRAPPLE_MIN_RANGE_M, true],
		[60, GRAPPLE_MIN_RANGE_M, true],
		[30, GRAPPLE_RANGE_M, true],
		[60, GRAPPLE_RANGE_M, true],
		[30, JUST_BELOW_MIN_M, false],
		[60, JUST_BELOW_MIN_M, false],
		[30, JUST_ABOVE_RANGE_M, false],
		[60, JUST_ABOVE_RANGE_M, false],
		[30, A_HAIR_BELOW_MIN_M, false],
		[60, A_HAIR_BELOW_MIN_M, false],
		[30, A_HAIR_ABOVE_RANGE_M, false],
		[60, A_HAIR_ABOVE_RANGE_M, false],
		[30, 10.0, true],
		[60, 10.0, true],
	],
) -> void:
	var rig := _rig(tickrate)
	var point := _point_ahead(rig, distance_m)
	_aim_at(rig, point)
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_grapple())
	assert_bool(plan.aim_request).is_true()
	assert_vector(rig.last_facts.position).is_equal_approx(Vector3.ZERO, Vector3.ONE * HAIR)
	var origin_distance := point.distance_to(_origin_of(rig.last_facts.position))
	assert_float(origin_distance).override_failure_message("the rig's geometry drifted") \
			.is_equal_approx(distance_m, GEOMETRY_HAIR)
	if fires:
		_assert_fired(rig.state, press_tick, point)
	else:
		_assert_not_fired(rig.state)
		_assert_slot(rig.state, FighterCommand.GRAPPLE, press_tick)
		var again := rig.step(MovementRig.idle())
		assert_bool(again.aim_request).override_failure_message("did not ask again").is_true()
		_assert_not_fired(rig.state)
	assert_int(rig.state.grapple_end_tick).is_equal(FighterState.NEVER)


# Criterion 2 of TASK-10.11: the reach is measured from O, not from the shoulder (DEC-0045 §2).
# A point straight ahead of the shoulder, exactly 25 m from it, is 25,0128 m from O and does not
# fire; one 2,9 m ahead of the shoulder, under the old minimum, is 3,0083 m from O and fires.
func test_the_reach_is_measured_from_o_and_not_from_the_shoulder(
	tickrate: int,
	ahead_of_the_shoulder_m: float,
	fires: bool,
	_test_parameters := [
		[30, AHEAD_OF_THE_SHOULDER_OUT_M, false],
		[60, AHEAD_OF_THE_SHOULDER_OUT_M, false],
		[30, AHEAD_OF_THE_SHOULDER_IN_M, true],
		[60, AHEAD_OF_THE_SHOULDER_IN_M, true],
	],
) -> void:
	var rig := _rig(tickrate)
	var point := _shoulder_of(rig.position) + Vector3.FORWARD * ahead_of_the_shoulder_m
	_aim_at(rig, point)
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_grapple())
	assert_bool(plan.aim_request).is_true()
	var feet := rig.last_facts.position
	assert_vector(feet).is_equal_approx(Vector3.ZERO, Vector3.ONE * HAIR)
	assert_float(point.distance_to(_shoulder_of(feet))).is_equal_approx(
		ahead_of_the_shoulder_m,
		GEOMETRY_HAIR,
	)
	var from_origin := point.distance_to(_origin_of(feet))
	var expected := sqrt(
		ahead_of_the_shoulder_m * ahead_of_the_shoulder_m + AIM_SIDE_M * AIM_SIDE_M
	)
	assert_float(from_origin).override_failure_message("the rig's geometry drifted") \
			.is_equal_approx(expected, GEOMETRY_HAIR)
	if fires:
		assert_float(from_origin).is_between(GRAPPLE_MIN_RANGE_M, GRAPPLE_RANGE_M)
		_assert_fired(rig.state, press_tick, point)
	else:
		assert_float(from_origin).is_greater(GRAPPLE_RANGE_M)
		_assert_not_fired(rig.state)
		_assert_slot(rig.state, FighterCommand.GRAPPLE, press_tick)


# O turns with the yaw of the tick (before_move copies the input's yaw into facing_yaw, and the
# fire rule measures from it; DEC-0045 §2): the same world point, 3 m straight ahead of O at yaw
# 0, is 2,34 m from O at yaw +90° (O moved to (0, 1,6, -0,8)) and out of reach; the point 25 m
# ahead of O at yaw 0 is 25,05 m from O at yaw 180° (O at (-0,8, 1,6, 0)) and out of reach.
func test_o_turns_with_the_yaw_of_the_tick_at_both_limits(
	tickrate: int,
	limit_m: float,
	yaw_deg: float,
	fires: bool,
	_test_parameters := [
		[30, GRAPPLE_MIN_RANGE_M, 0.0, true],
		[60, GRAPPLE_MIN_RANGE_M, 0.0, true],
		[30, GRAPPLE_MIN_RANGE_M, 90.0, false],
		[60, GRAPPLE_MIN_RANGE_M, 90.0, false],
		[30, GRAPPLE_RANGE_M, 0.0, true],
		[60, GRAPPLE_RANGE_M, 0.0, true],
		[30, GRAPPLE_RANGE_M, 180.0, false],
		[60, GRAPPLE_RANGE_M, 180.0, false],
	],
) -> void:
	var rig := _rig(tickrate)
	var point := _origin_of(rig.position, 0.0) + Vector3.FORWARD * limit_m
	var yaw := deg_to_rad(yaw_deg)
	_aim_at(rig, point)
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_grapple(yaw))
	assert_bool(plan.aim_request).is_true()
	assert_float(plan.state.facing_yaw).is_equal_approx(yaw, HAIR)
	var feet := rig.last_facts.position
	assert_vector(feet).is_equal_approx(Vector3.ZERO, Vector3.ONE * HAIR)
	var from_origin := point.distance_to(_origin_of(feet, yaw))
	var message := "the point is %.4f m from O at yaw %.0f°" % [from_origin, yaw_deg]
	if fires:
		assert_float(from_origin).override_failure_message(message).is_between(
			GRAPPLE_MIN_RANGE_M,
			GRAPPLE_RANGE_M,
		)
		_assert_fired(rig.state, press_tick, point)
	else:
		var outside := from_origin < GRAPPLE_MIN_RANGE_M or from_origin > GRAPPLE_RANGE_M
		assert_bool(outside).override_failure_message(message).is_true()
		_assert_not_fired(rig.state)
		_assert_slot(rig.state, FighterCommand.GRAPPLE, press_tick)


# One press, two yaws: pressed at yaw +90° on the point 3 m ahead of O at yaw 0, nothing fires
# (2,34 m from that tick's O); the press waits in the slot, and the next tick, aimed at yaw 0,
# brings O within reach of the same world point and fires there (movimento.md, "Gancho": "O
# erro": "a mira é refeita a cada tick, com a direção daquele tick").
func test_the_same_press_fires_on_the_tick_whose_yaw_brings_o_within_reach(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var point := _origin_of(rig.position, 0.0) + Vector3.FORWARD * GRAPPLE_MIN_RANGE_M
	_aim_at(rig, point)
	var press_tick := rig.tick
	var turned := rig.step(MovementRig.press_grapple(deg_to_rad(90.0)))
	assert_bool(turned.aim_request).is_true()
	_assert_not_fired(rig.state)
	_assert_slot(rig.state, FighterCommand.GRAPPLE, press_tick)
	var straight := rig.step(MovementRig.run(Vector2.ZERO, 0.0))
	assert_bool(straight.aim_request).override_failure_message("did not ask again").is_true()
	_assert_fired(rig.state, press_tick + 1, point)


# The fire rule measures from the feet after the move, MoveFacts.position, as before (DEC-0044
# §1; DEC-0045 §2): running forward at 7 m/s, a point 25,05 m ahead of O at the start of the tick
# is out of reach there and within 25 m of O after the tick's move (0,12 m at 60, 0,23 at 30), so
# it fires; a point 3,05 m ahead is in reach at the start and under 3 m after the move, so it does
# not.
func test_the_reach_is_measured_from_o_at_the_feet_after_the_move(
	tickrate: int,
	ahead_m: float,
	fires: bool,
	_test_parameters := [
		[30, GRAPPLE_RANGE_M + MOVE_MARGIN_M, true],
		[60, GRAPPLE_RANGE_M + MOVE_MARGIN_M, true],
		[30, GRAPPLE_MIN_RANGE_M + MOVE_MARGIN_M, false],
		[60, GRAPPLE_MIN_RANGE_M + MOVE_MARGIN_M, false],
	],
) -> void:
	var rig := _rig(tickrate)
	for _step: int in 2 * rig.config.accel_ticks:
		rig.step(MovementRig.run(FORWARD))
	var start := rig.position
	var point := _origin_of(start) + Vector3.FORWARD * ahead_m
	_aim_at(rig, point)
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_grapple_toward(FORWARD))
	assert_bool(plan.aim_request).is_true()
	var feet := rig.last_facts.position
	var moved := feet.distance_to(start)
	assert_float(moved).override_failure_message("the body moved %.3f m on the fire tick" % moved) \
			.is_between(MOVE_MARGIN_M + GEOMETRY_HAIR, 1.0)
	var from_start := point.distance_to(_origin_of(start))
	var from_end := point.distance_to(_origin_of(feet))
	var where := "%.4f m from O at the start, %.4f m after the move" % [from_start, from_end]
	if fires:
		assert_float(from_start).override_failure_message(where).is_greater(GRAPPLE_RANGE_M)
		assert_float(from_end).override_failure_message(where).is_between(
			GRAPPLE_MIN_RANGE_M,
			GRAPPLE_RANGE_M,
		)
		_assert_fired(rig.state, press_tick, point)
	else:
		assert_float(from_start).override_failure_message(where).is_between(
			GRAPPLE_MIN_RANGE_M,
			GRAPPLE_RANGE_M,
		)
		assert_float(from_end).override_failure_message(where).is_less(GRAPPLE_MIN_RANGE_M)
		_assert_not_fired(rig.state)
		_assert_slot(rig.state, FighterCommand.GRAPPLE, press_tick)


# Movement.in_reach itself (TASK-10.11 plan): the distance from O, the feet plus the aim's height
# and side turned by the yaw, from 3 to 25 m inclusive. The exact limits sit straight ahead of O
# at yaw 0, where only one coordinate differs; the turned yaws use points with a margin.
func test_in_reach_measures_from_o_with_the_yaw_inclusive_at_both_limits(
	yaw_deg: float,
	offset_from_origin: Vector3,
	expected: bool,
	_test_parameters := [
		[0.0, Vector3(0.0, 0.0, -GRAPPLE_MIN_RANGE_M), true],
		[0.0, Vector3(0.0, 0.0, -GRAPPLE_RANGE_M), true],
		[0.0, Vector3(0.0, 0.0, -A_HAIR_BELOW_MIN_M), false],
		[0.0, Vector3(0.0, 0.0, -A_HAIR_ABOVE_RANGE_M), false],
		[0.0, Vector3(0.0, 10.0, 0.0), true],
		[0.0, Vector3(0.0, -10.0, 0.0), true],
		[0.0, Vector3.ZERO, false],
		[90.0, Vector3(-10.0, 0.0, 0.0), true],
		[90.0, Vector3(-JUST_BELOW_MIN_M, 0.0, 0.0), false],
		[180.0, Vector3(0.0, 0.0, JUST_ABOVE_RANGE_M), false],
		[-90.0, Vector3(JUST_ABOVE_RANGE_M - 0.02, 0.0, 0.0), true],
	],
) -> void:
	var feet := Vector3(3.0, 1.0, -2.0)
	var yaw := deg_to_rad(yaw_deg)
	var point := _origin_of(feet, yaw) + offset_from_origin
	for tickrate: int in [30, 60]:
		var config := MovementRig.load_config(tickrate)
		var message := "in_reach for %s at yaw %.0f° (%.4f m from O) at %d ticks" % [
			offset_from_origin,
			yaw_deg,
			offset_from_origin.length(),
			tickrate,
		]
		assert_bool(Movement.in_reach(point, feet, yaw, config)).override_failure_message(message) \
				.is_equal(expected)


# in_reach reads the side from the config: with a side of 0 O is the shoulder, and the point 25 m
# straight ahead of it is in reach; with the right shoulder it is 25,0128 m off and out; with the
# left shoulder (-0,8) the mirror point, ahead of the left O, is in reach and the right one's out.
func test_in_reach_follows_the_aim_side_of_the_config(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var feet := Vector3(3.0, 1.0, -2.0)
	var ahead_of_the_shoulder := _shoulder_of(feet) + Vector3.FORWARD * GRAPPLE_RANGE_M
	var right := MovementRig.load_config(tickrate)
	var centre := _config_with_aim_side(0.0, tickrate)
	var left := _config_with_aim_side(-AIM_SIDE_M, tickrate)
	assert_float(centre.aim_side).is_equal_approx(0.0, HAIR)
	assert_float(left.aim_side).is_equal_approx(-AIM_SIDE_M, HAIR)
	assert_bool(Movement.in_reach(ahead_of_the_shoulder, feet, 0.0, right)) \
			.override_failure_message("the right shoulder reached the shoulder's own 25 m") \
			.is_false()
	assert_bool(Movement.in_reach(ahead_of_the_shoulder, feet, 0.0, centre)) \
			.override_failure_message("a side of 0 did not measure from the shoulder") \
			.is_true()
	var ahead_of_the_left := _shoulder_of(feet) - Vector3.RIGHT * AIM_SIDE_M \
			+ Vector3.FORWARD * GRAPPLE_RANGE_M
	assert_bool(Movement.in_reach(ahead_of_the_left, feet, 0.0, left)) \
			.override_failure_message("the left shoulder did not measure from the left O") \
			.is_true()
	assert_bool(Movement.in_reach(ahead_of_the_left, feet, 0.0, right)) \
			.override_failure_message("the right shoulder reached the left O's 25 m") \
			.is_false()


# Criterion 3, the miss: against the sky the press waits in the slot and the aim is cast again on
# every tick of the inclusive 150 ms window (5 ticks at 30, 9 at 60); one tick later the slot is
# empty, nothing asks, nothing fired, and the cooldown never counted (movimento.md, "Gancho": "O
# erro"; "Perdão": "Buffer de input"; DEC-0039).
func test_a_miss_keeps_the_press_asking_every_tick_until_the_window_closes(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_aim_at_the_sky(rig)
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_grapple())
	assert_bool(plan.aim_request).is_true()
	_assert_slot(plan.state, FighterCommand.GRAPPLE, press_tick)
	for _step: int in BUFFER_TICKS[tickrate]:
		var waiting := rig.step(MovementRig.idle())
		var tick := rig.tick - 1
		assert_bool(waiting.aim_request).override_failure_message("tick %d did not ask" % tick) \
				.is_true()
		_assert_slot(waiting.state, FighterCommand.GRAPPLE, press_tick)
		_assert_not_fired(rig.state)
	var expired := rig.step(MovementRig.idle())
	assert_int(rig.tick - 1).is_equal(press_tick + BUFFER_TICKS[tickrate] + 1)
	assert_bool(expired.aim_request).override_failure_message("asked past the window").is_false()
	_assert_slot(expired.state, FighterCommand.NONE, FighterState.NEVER)
	_assert_not_fired(rig.state)
	assert_int(rig.state.grapple_end_tick).override_failure_message("the cooldown counted") \
			.is_equal(FighterState.NEVER)


# A hit that appears on the last tick of the window fires there, with that tick's point; one tick
# later the press is gone and the same hit fires nothing.
func test_a_hit_that_appears_later_in_the_window_fires_and_one_tick_past_it_does_not(
	tickrate: int,
	ticks_after_press: int,
	fires: bool,
	_test_parameters := [
		[30, 1, true],
		[60, 1, true],
		[30, BUFFER_TICKS[30], true],
		[60, BUFFER_TICKS[60], true],
		[30, BUFFER_TICKS[30] + 1, false],
		[60, BUFFER_TICKS[60] + 1, false],
	],
) -> void:
	var rig := _rig(tickrate)
	_aim_at_the_sky(rig)
	var press_tick := rig.tick
	rig.step(MovementRig.press_grapple())
	rig.rest(ticks_after_press - 1)
	_assert_not_fired(rig.state)
	var point := _point_ahead(rig, 10.0)
	_aim_at(rig, point)
	var hit_tick := rig.tick
	assert_int(hit_tick).is_equal(press_tick + ticks_after_press)
	var plan := rig.step(MovementRig.idle())
	if fires:
		assert_bool(plan.aim_request).is_true()
		_assert_fired(rig.state, hit_tick, point)
	else:
		assert_bool(plan.aim_request).is_false()
		_assert_not_fired(rig.state)
		_assert_slot(rig.state, FighterCommand.NONE, FighterState.NEVER)


# A miss costs nothing: after a whole window against the sky, a press with a hit fires at once.
func test_a_miss_does_not_start_the_cooldown(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_aim_at_the_sky(rig)
	rig.step(MovementRig.press_grapple())
	rig.rest(BUFFER_TICKS[tickrate] + 1)
	_assert_not_fired(rig.state)
	assert_int(rig.state.grapple_end_tick).is_equal(FighterState.NEVER)
	_fire(rig, POINT_UP_AHEAD)


# The point is fixed on the fire tick: the aim moving afterwards, during the cable and the pull,
# changes nothing (movimento.md, "Gancho": "Tempo até prender": "O ponto fica fixo no disparo").
func test_the_point_stays_fixed_while_the_aim_moves_afterwards(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var fire_tick := _fire(rig, POINT_UP_AHEAD)
	for step: int in ATTACH_TICKS[tickrate] + 3:
		_aim_at(rig, POINT_UP_AHEAD + Vector3(step + 1.0, 0.0, -step))
		rig.step(MovementRig.idle())
		_assert_fired_point_kept(rig.state, fire_tick)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GRAPPLE)
	_aim_at_the_sky(rig)
	rig.step(MovementRig.idle())
	_assert_fired_point_kept(rig.state, fire_tick)


func _assert_fired_point_kept(state: FighterState, fire_tick: int) -> void:
	assert_int(state.grapple_fired_tick).is_equal(fire_tick)
	assert_vector(state.grapple_point).override_failure_message("the point moved") \
			.is_equal_approx(POINT_UP_AHEAD, Vector3.ONE * HAIR)


# Criterion 3, the cable: it flies 100 ms, 3 ticks at 30 and 6 at 60. From rest on the floor the
# body stays put meanwhile (its mode's rules), and the pull starts on the first tick with
# tick - fire >= attach ticks: GRAPPLE since then, 18 m/s toward the point.
func test_the_cable_flies_100_ms_before_the_pull_starts(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var fire_tick := _fire(rig, POINT_UP_AHEAD)
	for step: int in range(1, ATTACH_TICKS[tickrate]):
		var plan := rig.step(MovementRig.idle())
		assert_int(rig.tick - 1).is_equal(fire_tick + step)
		assert_int(plan.state.mode).override_failure_message("pulled before the cable bit") \
				.is_equal(FighterState.Mode.GROUND)
		assert_vector(plan.velocity).is_equal_approx(Vector3.ZERO, Vector3.ONE * HAIR)
		assert_int(rig.state.mode).is_equal(FighterState.Mode.GROUND)
		assert_int(rig.state.grapple_fired_tick).is_equal(fire_tick)
	var pull_start := rig.tick
	assert_int(pull_start).is_equal(fire_tick + ATTACH_TICKS[tickrate])
	var feet := rig.position
	var first := rig.step(MovementRig.idle())
	_assert_pull_tick(first, feet, POINT_UP_AHEAD)
	assert_int(first.state.mode_since).is_equal(pull_start)
	assert_int(first.state.grapple_fired_tick).is_equal(fire_tick)


# Criterion 6: the grapple fires from the air, and the pull starts after the same cable.
func test_the_grapple_fires_from_the_air(tickrate: int, _test_parameters := [[30], [60]]) -> void:
	var rig := _air_rig(tickrate)
	rig.airborne(Vector3(0.0, START_HEIGHT_M, 0.0), Vector3(0.0, -2.0, 0.0))
	var point := rig.position + POINT_UP_AHEAD
	var fire_tick := _fire(rig, point)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	var pull_start := _idle_until_pull(rig, ATTACH_TICKS[tickrate] + 1)
	assert_int(pull_start).is_equal(fire_tick + ATTACH_TICKS[tickrate])
	var feet := rig.position - rig.last_plan.velocity / float(tickrate)
	_assert_pull_tick(rig.last_plan, feet, point)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GRAPPLE)
	assert_int(rig.state.mode_since).is_equal(pull_start)


# Criterion 6: the grapple fires from a wall run, and the run ends on the fire tick: AIR since
# then, the cable flies in the air and the pull starts after it (movimento.md, "Gancho": "De
# onde dispara": "Na parede, a corrida acaba no disparo").
func test_the_grapple_fires_from_a_wall_run_and_the_run_ends_on_the_fire_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	var entry_tick := _run_on_wall_a(rig)
	rig.rest(2)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.WALL_RUN)
	assert_int(rig.state.mode_since).is_equal(entry_tick)
	var point := rig.position + Vector3(0.0, 5.0, -10.0)
	_aim_at(rig, point)
	var fire_tick := rig.tick
	var plan := rig.step(MovementRig.press_grapple())
	assert_bool(plan.aim_request).override_failure_message("the wall run did not ask").is_true()
	assert_int(plan.state.mode).override_failure_message("the plan left the wall early") \
			.is_equal(FighterState.Mode.WALL_RUN)
	_assert_fired(rig.state, fire_tick, point)
	assert_int(rig.state.mode).override_failure_message("the run did not end on the fire") \
			.is_equal(FighterState.Mode.AIR)
	assert_int(rig.state.mode_since).is_equal(fire_tick)
	for _step: int in ATTACH_TICKS[tickrate] - 1:
		var cable := rig.step(MovementRig.idle())
		assert_int(cable.state.mode).is_equal(FighterState.Mode.AIR)
		assert_int(rig.state.mode).is_not_equal(FighterState.Mode.WALL_RUN)
	var feet := rig.position
	var first := rig.step(MovementRig.idle())
	assert_int(rig.tick - 1).is_equal(fire_tick + ATTACH_TICKS[tickrate])
	_assert_pull_tick(first, feet, point)


# Criterion 4: on every pull tick the velocity is the unit vector from the feet to the point
# times 18 m/s, the direction input changes nothing, and nothing pulls the body down: each tick
# brings the feet exactly 18 / tickrate m closer along the line (movimento.md, "Gancho":
# "Velocidade da puxada", "O que a puxada leva ao ponto").
func test_the_pull_takes_the_feet_toward_the_point_at_18_mps_without_gravity_or_input(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var during: Array[TickInput] = [
		MovementRig.run(FORWARD),
		MovementRig.run(RIGHT),
		MovementRig.run(BACK_LEFT, PI / 3.0),
	]
	var record := _grapple_from_rest(rig, during)
	assert_int(record.pull_ticks()).is_greater_equal(10)
	var step_m := GRAPPLE_PULL_SPEED_MPS / tickrate
	var direction := _direction_to(POINT_UP_AHEAD, Vector3.ZERO)
	for index: int in record.pull_ticks():
		_assert_pull_tick(record.plans[index], record.starts[index], POINT_UP_AHEAD)
		var expected_feet := Vector3.ZERO + direction * (step_m * index)
		var drift := "tick %d of the pull: the feet at %s, expected %s on the line" % [
			index + 1,
			record.starts[index],
			expected_feet,
		]
		assert_vector(record.starts[index]).override_failure_message(drift).is_equal_approx(
			expected_feet,
			Vector3.ONE * GEOMETRY_HAIR,
		)
		assert_float(record.plans[index].velocity.y).override_failure_message("gravity acted") \
				.is_equal_approx(direction.y * GRAPPLE_PULL_SPEED_MPS, GEOMETRY_HAIR)


# The direction is recomputed from the feet on every tick: when the engine moves the body off the
# line (here by hand, one metre sideways), the next tick aims from where the feet are.
func test_the_pull_direction_is_recomputed_from_the_feet_every_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var fire_tick := _fire(rig, POINT_UP_AHEAD)
	_idle_until_pull(rig, ATTACH_TICKS[tickrate] + 1)
	rig.rest(2)
	rig.position += NUDGE
	var feet := rig.position
	var plan := rig.step(MovementRig.idle())
	_assert_pull_tick(plan, feet, POINT_UP_AHEAD)
	assert_float(plan.velocity.x).override_failure_message("still aiming from the old line") \
			.is_less(-HAIR)
	assert_int(plan.state.grapple_fired_tick).is_equal(fire_tick)


# Criterion 4, the release by distance: the pull ends on the first tick that starts with the feet
# within 1,5 m of the point, that tick runs free on the incoming velocity, the body in the air
# (movimento.md, "Gancho": "Como solta": "Conserva a velocidade. Os 1,5 m contam dos pés").
func test_the_pull_releases_when_the_feet_come_within_1_5_m_and_keeps_the_velocity(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var record := _grapple_from_rest(rig)
	var last := record.pull_ticks() - 1
	var before := record.starts[last].distance_to(POINT_UP_AHEAD)
	var at_release := record.release_start.distance_to(POINT_UP_AHEAD)
	assert_float(before).override_failure_message("the pull went on within 1,5 m") \
			.is_greater(GRAPPLE_RELEASE_DISTANCE_M)
	assert_float(at_release).override_failure_message("released farther than 1,5 m") \
			.is_less_equal(GRAPPLE_RELEASE_DISTANCE_M)
	_assert_released(record.release_plan, record.release_tick, FighterState.Mode.AIR)
	_assert_velocity_kept(rig, record.release_plan, record.release_incoming)
	assert_float(record.release_incoming.length()).is_equal_approx(
		GRAPPLE_PULL_SPEED_MPS,
		GEOMETRY_HAIR,
	)
	assert_float(record.release_plan.velocity.length()).is_greater(GRAPPLE_BLOCK_SPEED_MPS)
	_assert_slot(record.release_plan.state, FighterCommand.NONE, FighterState.NEVER)


# A pull along the floor keeps the feet on it: the contact never changes the mode during the
# pull, and the release by distance lands on GROUND (TASK-10.6 notes: by_contact is false for
# GRAPPLE; the release reads on_floor).
func test_a_pull_along_the_floor_stays_in_the_pull_and_releases_on_the_ground(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var fire_tick := _fire(rig, POINT_ALONG_FLOOR)
	var record := _record_grapple(rig, fire_tick, 5 * tickrate)
	assert_int(record.pull_ticks()).is_greater_equal(20)
	for index: int in record.pull_ticks():
		_assert_pull_tick(record.plans[index], record.starts[index], POINT_ALONG_FLOOR)
		assert_bool(record.plans[index].state.on_floor) \
				.override_failure_message("tick %d of the pull left the floor" % (index + 1)) \
				.is_true()
	assert_float(record.release_start.distance_to(POINT_ALONG_FLOOR)).is_less_equal(
		GRAPPLE_RELEASE_DISTANCE_M
	)
	_assert_released(record.release_plan, record.release_tick, FighterState.Mode.GROUND)
	_assert_velocity_kept(rig, record.release_plan, record.release_incoming)


# Criterion 4, the block does not apply on the pull's first tick: from rest the incoming velocity
# is 0, below 9 m/s, and the pull still starts (movimento.md, "Gancho": "Trava": "A partir do
# segundo tick da puxada").
func test_the_block_does_not_apply_on_the_first_pull_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var record := _grapple_from_rest(rig)
	assert_int(record.pull_start_tick).is_equal(record.fire_tick + ATTACH_TICKS[tickrate])
	assert_vector(record.incomings[0]).is_equal_approx(Vector3.ZERO, Vector3.ONE * HAIR)
	_assert_pull_tick(record.plans[0], record.starts[0], POINT_UP_AHEAD)
	assert_int(record.pull_ticks()).is_greater_equal(2)


# Criterion 4, the block: a wall across the pull stops the body (the engine slides the velocity
# to 0), and the next tick, the second or later of the pull, sees the incoming velocity toward the
# point below 9 m/s and releases, far from the point, keeping that velocity (movimento.md,
# "Gancho": "Trava").
func test_a_wall_that_stops_the_body_releases_the_grapple_on_the_next_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	rig.airborne(Vector3(0.0, START_HEIGHT_M, 0.0), Vector3.ZERO)
	rig.add_wall(Vector3.BACK, BLOCKER_Z, BLOCKER)
	var point := Vector3(0.0, START_HEIGHT_M, -PULL_AHEAD_M)
	var fire_tick := _fire(rig, point)
	var record := _record_grapple(rig, fire_tick, 5 * tickrate)
	var contact := _first_contact_index(rig, record, BLOCKER)
	assert_int(contact).override_failure_message("the pull never met the wall").is_greater_equal(1)
	assert_int(record.pull_ticks()).override_failure_message("the pull went on past the stop") \
			.is_equal(contact + 1)
	# The wall takes the whole horizontal; the cable's fall left a small vertical part.
	var toward := record.release_incoming.dot(_direction_to(point, record.release_start))
	var left := "the stop left %.3f m/s toward the point" % toward
	assert_float(toward).override_failure_message(left).is_between(-HAIR, 1.0)
	assert_vector(Vector3(record.release_incoming.x, 0.0, record.release_incoming.z)) \
			.is_equal_approx(Vector3.ZERO, Vector3.ONE * GEOMETRY_HAIR)
	assert_float(record.release_start.distance_to(point)).is_greater(GRAPPLE_RELEASE_DISTANCE_M)
	_assert_released(record.release_plan, record.release_tick, FighterState.Mode.AIR)
	_assert_velocity_kept(rig, record.release_plan, record.release_incoming)
	assert_int(record.release_plan.state.mode).is_not_equal(FighterState.Mode.WALL_RUN)


# The index of the first pull tick that ended on this wall's plane, where the engine clamped the
# move and slid the velocity; -1 without one. The end of pull tick i is the start of the next
# tick, the release tick's included.
func _first_contact_index(rig: MovementRig, record: GrappleRecord, id: StringName) -> int:
	var wall: MovementRig.FakeWall = null
	for candidate: MovementRig.FakeWall in rig.walls:
		if candidate.id == id:
			wall = candidate
	assert_object(wall).is_not_null()
	var last := record.pull_ticks() - 1
	for index: int in record.pull_ticks():
		var end := record.release_start if index == last else record.starts[index + 1]
		# On the plane itself, where the rig clamped a move that crossed it: a tick ending a hair
		# short of the wall (the pull tilts up after the fall while the cable flies) is no contact
		# (F-143).
		if absf(wall.distance(end)) <= MovementRig.LANDING_HAIR:
			return index
	return -1


# A face at 40° to the pull slides the velocity to 18 sin² 40° = 7,4 m/s toward the point, below
# the 9 of the block: the next tick releases.
func test_a_slide_that_leaves_less_than_9_mps_toward_the_point_releases(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	rig.airborne(Vector3(0.0, START_HEIGHT_M, 0.0), Vector3.ZERO)
	_add_turned_face(rig, SLIDE_BELOW_BLOCK_DEG, SLIDER_Z, BLOCKER)
	var point := Vector3(0.0, START_HEIGHT_M, -PULL_AHEAD_M)
	var fire_tick := _fire(rig, point)
	var record := _record_grapple(rig, fire_tick, 5 * tickrate)
	var contact := _first_contact_index(rig, record, BLOCKER)
	assert_int(contact).override_failure_message("the pull never met the face").is_greater_equal(1)
	assert_int(record.pull_ticks()).override_failure_message("the pull went on after the slide") \
			.is_equal(contact + 1)
	var toward := record.release_incoming.dot(_direction_to(point, record.release_start))
	assert_float(toward).override_failure_message("%.3f m/s toward the point" % toward).is_between(
		HAIR,
		GRAPPLE_BLOCK_SPEED_MPS - HAIR,
	)
	assert_float(record.release_start.distance_to(point)).is_greater(GRAPPLE_RELEASE_DISTANCE_M)
	_assert_released(record.release_plan, record.release_tick, FighterState.Mode.AIR)
	_assert_velocity_kept(rig, record.release_plan, record.release_incoming)


# A short face at 60° slides the velocity to 18 sin² 60° = 13,5 m/s toward the point, at or above
# the 9 of the block: the pull goes on along the face, never a wall run, and once past its end it
# finishes by distance.
func test_a_slide_that_keeps_9_mps_or_more_toward_the_point_does_not_release(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	rig.airborne(Vector3(0.0, START_HEIGHT_M, 0.0), Vector3.ZERO)
	var face := _add_turned_face(rig, SLIDE_ABOVE_BLOCK_DEG, SLIDER_Z, BLOCKER)
	face.along_max = face.along_of(Vector3(0.0, START_HEIGHT_M, SLIDER_Z)) + SHORT_FACE_M
	var point := Vector3(0.0, START_HEIGHT_M, -PULL_AHEAD_M)
	var fire_tick := _fire(rig, point)
	var record := _record_grapple(rig, fire_tick, 5 * tickrate)
	var contact := _first_contact_index(rig, record, BLOCKER)
	assert_int(contact).override_failure_message("the pull never met the face").is_greater_equal(1)
	var toward := record.incomings[contact].dot(_direction_to(point, record.starts[contact]))
	assert_float(toward).override_failure_message("the slide left %.3f m/s" % toward) \
			.is_greater_equal(GRAPPLE_BLOCK_SPEED_MPS)
	assert_int(record.pull_ticks()).override_failure_message("released on the slide") \
			.is_greater(contact + 1)
	for plan: MovePlan in record.plans:
		assert_int(plan.state.mode).is_not_equal(FighterState.Mode.WALL_RUN)
	assert_float(record.release_start.distance_to(point)) \
			.override_failure_message("not a release by distance") \
			.is_less_equal(GRAPPLE_RELEASE_DISTANCE_M)
	_assert_released(record.release_plan, record.release_tick, FighterState.Mode.AIR)


# Limit: the feet already within 1,5 m of the point when the pull would start release it on that
# tick, with no pull tick at all: a body falling onto a point just below its feet.
func test_feet_already_within_1_5_m_when_the_pull_would_start_release_at_once(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _air_rig(tickrate)
	rig.airborne(Vector3(0.0, START_HEIGHT_M, 0.0), Vector3.ZERO)
	var point := Vector3(0.0, START_HEIGHT_M - RELEASE_BELOW_FEET_M, 0.0)
	var fire_tick := _fire(rig, point)
	var origin_distance := point.distance_to(_origin_of(rig.last_facts.position))
	assert_float(origin_distance).override_failure_message("the fire was out of range") \
			.is_greater_equal(GRAPPLE_MIN_RANGE_M)
	var record := _record_grapple(rig, fire_tick, ATTACH_TICKS[tickrate] + 2)
	assert_int(record.release_tick).is_equal(fire_tick + ATTACH_TICKS[tickrate])
	assert_float(record.release_start.distance_to(point)) \
			.override_failure_message("the feet were not within 1,5 m") \
			.is_less_equal(GRAPPLE_RELEASE_DISTANCE_M)
	assert_int(record.pull_ticks()).override_failure_message("a pull tick ran").is_equal(0)
	_assert_released(record.release_plan, record.release_tick, FighterState.Mode.AIR)
	_assert_velocity_kept(rig, record.release_plan, record.release_incoming)
	assert_float(record.release_plan.velocity.length()).is_less(GRAPPLE_BLOCK_SPEED_MPS)


# Criterion 5: a jump pressed during the pull only releases: the velocity is kept, no jump speed,
# no cost, the press spent; the next press in the air is the double jump, paid (movimento.md,
# "Gancho": "O pulo na puxada").
func test_a_jump_during_the_pull_releases_without_a_jump_and_the_next_press_is_the_double_jump(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_fire(rig, POINT_UP_AHEAD)
	var pull_start := _idle_until_pull(rig, ATTACH_TICKS[tickrate] + 1)
	rig.rest(2)
	var incoming := rig.velocity
	var jump_tick := rig.tick
	assert_int(jump_tick).is_greater(pull_start)
	var release := rig.step(MovementRig.press_jump())
	_assert_released(release, jump_tick, FighterState.Mode.AIR)
	_assert_velocity_kept(rig, release, incoming)
	_assert_not_about(release.velocity.y, rig.config.jump_speed, "the jump came out")
	_assert_not_about(release.velocity.y, rig.config.double_jump_speed, "the double jump came out")
	assert_int(release.state.jumps_used).override_failure_message("a jump was counted").is_equal(0)
	assert_int(release.state.stamina_spent_tick).override_failure_message("a cost was paid") \
			.is_equal(FighterState.NEVER)
	_assert_slot(release.state, FighterCommand.NONE, FighterState.NEVER)
	rig.rest(2)
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_jump())
	_assert_double_jumped(rig, plan, press_tick)
	assert_float(Stamina.at(plan.state, rig.config, press_tick)).is_equal_approx(
		rig.config.stamina_max - DOUBLE_JUMP_COST,
		HAIR,
	)


# A jump pressed on the pull's first tick (buffered_tick == mode_since) releases at once: no pull
# tick runs, the body keeps the velocity it had, on the floor it stays on the floor.
func test_a_jump_on_the_pull_first_tick_releases_at_once_without_a_pull_tick(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var fire_tick := _fire(rig, POINT_UP_AHEAD)
	rig.rest(ATTACH_TICKS[tickrate] - 1)
	var pull_start := rig.tick
	assert_int(pull_start).is_equal(fire_tick + ATTACH_TICKS[tickrate])
	assert_int(rig.state.mode).is_equal(FighterState.Mode.GROUND)
	var plan := rig.step(MovementRig.press_jump())
	_assert_released(plan, pull_start, FighterState.Mode.GROUND)
	assert_float(plan.velocity.length()).override_failure_message("a pull tick ran") \
			.is_less(GRAPPLE_BLOCK_SPEED_MPS)
	_assert_not_about(plan.velocity.y, rig.config.jump_speed, "the jump came out")
	assert_int(plan.state.jumps_used).is_equal(0)
	assert_bool(rig.state.on_floor).is_true()


# Criterion 5: a jump pressed while the cable flies follows the mode's rules: from the floor the
# full jump comes out, the grapple goes on, and the pull starts on time from where the feet are.
func test_a_jump_while_the_cable_flies_comes_out_from_the_floor_and_the_grapple_goes_on(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var fire_tick := _fire(rig, POINT_UP_AHEAD)
	var jump_tick := rig.tick
	var jump := rig.step(MovementRig.press_jump())
	_assert_full_jump(rig, jump)
	assert_int(jump.state.grapple_fired_tick).override_failure_message("the jump released") \
			.is_equal(fire_tick)
	assert_int(rig.state.grapple_fired_tick).is_equal(fire_tick)
	rig.rest(ATTACH_TICKS[tickrate] - 2)
	var pull_start := rig.tick
	assert_int(pull_start).is_equal(fire_tick + ATTACH_TICKS[tickrate])
	var feet := rig.position
	assert_float(feet.y).override_failure_message("the jump did not lift the body").is_greater(0.0)
	var first := rig.step(MovementRig.idle())
	_assert_pull_tick(first, feet, POINT_UP_AHEAD)
	assert_int(first.state.mode_since).is_equal(pull_start)
	assert_int(first.state.jumps_used).is_equal(1)


# A jump that cannot fire while the cable flies (the double jump spent) waits in the slot, and at
# the pull's start it does not release: it was pressed before the pull, so it dies with its
# window while the pull goes on (TASK-10.6 notes: release (a) needs buffered_tick >= mode_since).
func test_a_jump_that_cannot_fire_while_the_cable_flies_waits_and_does_not_release_the_pull(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.step(MovementRig.press_jump())
	_spend_double_jump(rig)
	rig.rest(1)
	var point := rig.position + Vector3(0.0, 8.0, -12.0)
	var fire_tick := _fire(rig, point)
	var press_tick := rig.tick
	var velocity_y_before := rig.velocity.y
	var waiting := rig.step(MovementRig.press_jump())
	_assert_slot(waiting.state, FighterCommand.JUMP, press_tick)
	assert_float(waiting.velocity.y).override_failure_message("a jump came out") \
			.is_less_equal(velocity_y_before + HAIR)
	assert_int(waiting.state.jumps_used).is_equal(2)
	var pull_start := _idle_until_pull(rig, ATTACH_TICKS[tickrate])
	assert_int(pull_start).is_equal(fire_tick + ATTACH_TICKS[tickrate])
	_assert_slot(rig.last_plan.state, FighterCommand.JUMP, press_tick)
	var window_end := press_tick + BUFFER_TICKS[tickrate]
	while rig.tick <= window_end + 1:
		var plan := rig.step(MovementRig.idle())
		var tick := rig.tick - 1
		assert_int(plan.state.mode).override_failure_message("tick %d released" % tick).is_equal(
			FighterState.Mode.GRAPPLE
		)
		if tick <= window_end:
			_assert_slot(plan.state, FighterCommand.JUMP, press_tick)
		else:
			_assert_slot(plan.state, FighterCommand.NONE, FighterState.NEVER)
	assert_int(rig.state.grapple_end_tick).is_equal(FighterState.NEVER)


# Criterion 5, the tie on the floor: jump, dash and grapple on one tick is the jump; the dash is
# lost and nothing is paid, the grapple is lost and no aim is asked (movimento.md, "Perdão": "No
# mesmo tick, o pulo vence o dash, que vence o gancho"; DEC-0039 §4).
func test_jump_dash_and_grapple_on_one_tick_on_the_floor_is_the_jump(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_aim_at(rig, POINT_UP_AHEAD)
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_together(true, true, true, FORWARD))
	_assert_full_jump(rig, plan)
	_assert_no_dash(plan)
	assert_int(plan.state.stamina_spent_tick).is_equal(FighterState.NEVER)
	assert_bool(plan.aim_request).override_failure_message("the grapple asked").is_false()
	_assert_not_fired(rig.state)
	_idle_until_landed(rig)
	rig.rest(2 * BUFFER_TICKS[tickrate])
	_assert_no_dash(rig.last_plan)
	_assert_not_fired(rig.state)


# Dash and grapple on one tick on the floor is the dash; the grapple is lost: no aim asked then
# or after the dash.
func test_dash_and_grapple_on_one_tick_on_the_floor_is_the_dash(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_aim_at(rig, POINT_UP_AHEAD)
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_together(false, true, true, FORWARD))
	assert_int(plan.state.mode).override_failure_message("not in DASH").is_equal(
		FighterState.Mode.DASH
	)
	assert_int(plan.state.dash_tick).is_equal(press_tick)
	assert_bool(plan.aim_request).override_failure_message("the grapple asked").is_false()
	_assert_slot(plan.state, FighterCommand.NONE, FighterState.NEVER)
	_assert_not_fired(rig.state)
	_idle_until_with_press(
		rig,
		press_tick + DASH_TICKS[tickrate] + BUFFER_TICKS[tickrate] + 2,
		FighterState.NEVER,
		MovementRig.idle(),
	)


# In the air with the double jump spent, jump and grapple on one tick keep the jump in the slot:
# the grapple, which could fire, asks nothing.
func test_jump_and_grapple_on_one_tick_in_the_air_with_the_double_jump_spent_keep_the_jump(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	rig.step(MovementRig.press_jump())
	_spend_double_jump(rig)
	rig.rest(1)
	_aim_at(rig, rig.position + POINT_UP_AHEAD)
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_together(true, false, true))
	_assert_slot(plan.state, FighterCommand.JUMP, press_tick)
	assert_bool(plan.aim_request).override_failure_message("the grapple asked").is_false()
	_assert_not_fired(rig.state)
	var alone := rig.step(MovementRig.press_grapple())
	assert_bool(alone.aim_request).override_failure_message("a grapple alone must ask").is_true()
	_assert_fired(rig.state, press_tick + 1, rig.aim_point)


# Criterion 5, the tie in the slot: during the dash none of the three can fire; pressed together
# late in the dash, the slot keeps the jump, which fires at the exit; the dash is not chained and
# the grapple asks nothing.
func test_during_the_dash_jump_dash_and_grapple_on_one_tick_leave_the_jump_in_the_slot(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_aim_at(rig, POINT_UP_AHEAD)
	var dash_tick := rig.tick
	rig.step(MovementRig.press_dash_toward(FORWARD))
	var press_tick := dash_tick + DASH_TICKS[tickrate] - 2
	rig.rest(press_tick - rig.tick)
	var plan := rig.step(MovementRig.press_together(true, true, true))
	assert_int(plan.state.mode).is_equal(FighterState.Mode.DASH)
	_assert_slot(plan.state, FighterCommand.JUMP, press_tick)
	assert_bool(plan.aim_request).is_false()
	rig.rest(1)
	var exit_tick := rig.tick
	assert_int(exit_tick).is_equal(dash_tick + DASH_TICKS[tickrate])
	var exit := rig.step(MovementRig.idle())
	_assert_full_jump(rig, exit)
	assert_int(exit.state.dash_tick).is_equal(dash_tick)
	assert_bool(exit.aim_request).is_false()
	_assert_not_fired(rig.state)


# Dash and grapple together during the dash leave the dash in the slot; at the exit the dash is in
# its cooldown and waits, and no grapple asks.
func test_during_the_dash_dash_and_grapple_on_one_tick_leave_the_dash_in_the_slot(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_aim_at(rig, POINT_UP_AHEAD)
	var dash_tick := rig.tick
	rig.step(MovementRig.press_dash_toward(FORWARD))
	var press_tick := dash_tick + DASH_TICKS[tickrate] - 2
	rig.rest(press_tick - rig.tick)
	var plan := rig.step(MovementRig.press_together(false, true, true))
	_assert_slot(plan.state, FighterCommand.DASH, press_tick)
	assert_bool(plan.aim_request).is_false()
	rig.rest(1)
	var exit := rig.step(MovementRig.idle())
	assert_int(exit.state.mode).is_equal(FighterState.Mode.GROUND)
	assert_int(exit.state.dash_tick).is_equal(dash_tick)
	_assert_slot(exit.state, FighterCommand.DASH, press_tick)
	assert_bool(exit.aim_request).is_false()
	_assert_not_fired(rig.state)


# A later press replaces the kept one (one slot, DEC-0039): a jump then a grapple during the dash
# leaves the grapple, which asks and fires at the exit with no jump; a grapple then a jump leaves
# the jump, which fires with no aim asked.
func test_a_later_press_during_the_dash_replaces_the_kept_one(
	tickrate: int,
	first: StringName,
	_test_parameters := [
		[30, FighterCommand.JUMP],
		[60, FighterCommand.JUMP],
		[30, FighterCommand.GRAPPLE],
		[60, FighterCommand.GRAPPLE],
	],
) -> void:
	var rig := _rig(tickrate)
	var dash_tick := rig.tick
	rig.step(MovementRig.press_dash_toward(FORWARD))
	var second: StringName = FighterCommand.GRAPPLE if first == FighterCommand.JUMP \
			else FighterCommand.JUMP
	var first_tick := dash_tick + DASH_TICKS[tickrate] - 3
	var second_tick := first_tick + 1
	rig.rest(first_tick - rig.tick)
	_assert_slot(rig.step(_press_of(first)).state, first, first_tick)
	var replaced := rig.step(_press_of(second))
	_assert_slot(replaced.state, second, second_tick)
	assert_bool(replaced.aim_request).is_false()
	rig.rest(1)
	var exit_tick := rig.tick
	assert_int(exit_tick).is_equal(dash_tick + DASH_TICKS[tickrate])
	_aim_at(rig, rig.position + POINT_UP_AHEAD)
	var exit := rig.step(MovementRig.idle())
	if second == FighterCommand.GRAPPLE:
		assert_bool(exit.aim_request).override_failure_message("the kept grapple did not ask") \
				.is_true()
		_assert_fired(rig.state, exit_tick, rig.aim_point)
		assert_int(exit.state.jumps_used).override_failure_message("the replaced jump came out") \
				.is_equal(0)
		assert_float(exit.velocity.y).is_equal_approx(0.0, HAIR)
	else:
		_assert_full_jump(rig, exit)
		assert_bool(exit.aim_request).override_failure_message("the replaced grapple asked") \
				.is_false()
		_assert_not_fired(rig.state)


func _press_of(command: StringName) -> TickInput:
	if command == FighterCommand.JUMP:
		return MovementRig.press_jump()
	return MovementRig.press_grapple()


# Criterion 6, the cooldown: after a release at E the next grapple fires only when
# tick - E >= cooldown ticks (180 at 30, 360 at 60). A press one tick early waits in the slot
# without asking and fires on the first legal tick; a press exactly on it fires at once
# (movimento.md, "Gancho": "Recarga": "Conta da soltura").
func test_the_next_grapple_fires_only_6_s_after_the_release(
	tickrate: int,
	ticks_early: int,
	_test_parameters := [[30, 1], [60, 1], [30, 0], [60, 0]],
) -> void:
	var rig := _rig(tickrate)
	var record := _grapple_from_rest(rig)
	var release_tick := record.release_tick
	var legal_tick := release_tick + COOLDOWN_TICKS[tickrate]
	var press_tick := legal_tick - ticks_early
	_idle_until_with_press(rig, press_tick, FighterState.NEVER, MovementRig.idle())
	assert_bool(rig.state.on_floor).override_failure_message("still in the air after 6 s") \
			.is_true()
	_aim_at(rig, rig.position + POINT_UP_AHEAD)
	var plan := rig.step(MovementRig.press_grapple())
	if ticks_early > 0:
		assert_bool(plan.aim_request).override_failure_message("asked inside the cooldown") \
				.is_false()
		_assert_slot(plan.state, FighterCommand.GRAPPLE, press_tick)
		_assert_not_fired(rig.state)
		assert_int(rig.state.grapple_end_tick).is_equal(release_tick)
		rig.rest(ticks_early - 1)
		_aim_at(rig, rig.position + POINT_UP_AHEAD)
		plan = rig.step(MovementRig.idle())
	assert_int(rig.tick - 1).is_equal(legal_tick)
	assert_bool(plan.aim_request).override_failure_message("did not ask when the cooldown ended") \
			.is_true()
	_assert_fired(rig.state, legal_tick, rig.aim_point)
	assert_int(rig.state.grapple_end_tick).is_equal(release_tick)


# A press in the cooldown waits the whole 150 ms: pressed so that the window's last tick is the
# first legal one, it asks nothing meanwhile and fires there.
func test_a_press_in_the_cooldown_waits_in_the_slot_and_fires_when_the_cooldown_ends_in_its_window(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var record := _grapple_from_rest(rig)
	var legal_tick := record.release_tick + COOLDOWN_TICKS[tickrate]
	var press_tick := legal_tick - BUFFER_TICKS[tickrate]
	_idle_until_with_press(rig, press_tick, FighterState.NEVER, MovementRig.idle())
	_aim_at(rig, rig.position + POINT_UP_AHEAD)
	var plan := rig.step(MovementRig.press_grapple())
	assert_bool(plan.aim_request).is_false()
	_assert_slot(plan.state, FighterCommand.GRAPPLE, press_tick)
	while rig.tick < legal_tick:
		var waiting := rig.step(MovementRig.idle())
		assert_bool(waiting.aim_request).override_failure_message("asked inside the cooldown") \
				.is_false()
		_assert_slot(waiting.state, FighterCommand.GRAPPLE, press_tick)
		_assert_not_fired(rig.state)
	var legal := rig.step(MovementRig.idle())
	assert_bool(legal.aim_request).is_true()
	_assert_fired(rig.state, legal_tick, rig.aim_point)


# A press whose window closes one tick before the cooldown ends asks nothing and dies: no fire
# when the cooldown ends.
func test_a_press_in_the_cooldown_whose_window_closes_before_the_cooldown_ends_dies(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var record := _grapple_from_rest(rig)
	var legal_tick := record.release_tick + COOLDOWN_TICKS[tickrate]
	var press_tick := legal_tick - BUFFER_TICKS[tickrate] - 1
	_aim_at(rig, POINT_UP_AHEAD)
	_idle_until_with_press(rig, legal_tick + 2, press_tick, MovementRig.press_grapple())
	_assert_slot(rig.state, FighterCommand.NONE, FighterState.NEVER)
	_assert_not_fired(rig.state)
	assert_int(rig.state.grapple_end_tick).is_equal(record.release_tick)


# Criterion 6: no aim is asked during the dash; a press on its last tick waits and fires on the
# exit tick, inside its window (movimento.md, "Gancho": "De onde dispara": "Não dispara no dash").
func test_no_aim_request_during_the_dash_and_a_late_press_fires_after_it(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_aim_at(rig, POINT_UP_AHEAD)
	var dash_tick := rig.tick
	rig.step(MovementRig.press_dash_toward(FORWARD))
	var press_tick := dash_tick + DASH_TICKS[tickrate] - 1
	rig.rest(press_tick - rig.tick)
	var plan := rig.step(MovementRig.press_grapple())
	assert_int(plan.state.mode).is_equal(FighterState.Mode.DASH)
	assert_bool(plan.aim_request).override_failure_message("asked during the dash").is_false()
	_assert_slot(plan.state, FighterCommand.GRAPPLE, press_tick)
	_assert_not_fired(rig.state)
	var exit_tick := rig.tick
	assert_int(exit_tick).is_equal(dash_tick + DASH_TICKS[tickrate])
	_aim_at(rig, rig.position + POINT_UP_AHEAD)
	var exit := rig.step(MovementRig.idle())
	assert_bool(exit.aim_request).override_failure_message("did not ask after the dash").is_true()
	_assert_fired(rig.state, exit_tick, rig.aim_point)


# At 60 ticks the dash (12 ticks) outlasts the window (9): a press on its second tick dies before
# the exit, asking nothing. At 30 the dash (6) and the window (5) make the press of the dash's
# own tick the only one that dies: the tie, tested above.
func test_a_press_early_in_the_dash_dies_before_the_dash_ends_at_60_ticks() -> void:
	var rig := _rig(60)
	_aim_at(rig, POINT_UP_AHEAD)
	var dash_tick := rig.tick
	rig.step(MovementRig.press_dash_toward(FORWARD))
	var press_tick := dash_tick + 1
	assert_int(press_tick + BUFFER_TICKS[60]).is_less(dash_tick + DASH_TICKS[60])
	_idle_until_with_press(
		rig,
		dash_tick + DASH_TICKS[60] + 2,
		press_tick,
		MovementRig.press_grapple(),
	)
	_assert_slot(rig.state, FighterCommand.NONE, FighterState.NEVER)
	_assert_not_fired(rig.state)


# Criterion 6: no aim is asked while the cable flies or during the pull: a second press waits and
# a second grapple never fires while the first is out (movimento.md, "Gancho": "De onde dispara":
# "nem com outro gancho no ar, voando ou puxando").
func test_no_aim_request_while_the_cable_flies_or_during_the_pull(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var fire_tick := _fire(rig, POINT_UP_AHEAD)
	var cable_press := rig.tick
	var cable := rig.step(MovementRig.press_grapple())
	assert_bool(cable.aim_request).override_failure_message("asked while the cable flew") \
			.is_false()
	_assert_slot(cable.state, FighterCommand.GRAPPLE, cable_press)
	assert_int(rig.state.grapple_fired_tick).is_equal(fire_tick)
	_idle_until_pull(rig, ATTACH_TICKS[tickrate])
	var pull_press := rig.tick
	var pull := rig.step(MovementRig.press_grapple())
	assert_int(pull.state.mode).is_equal(FighterState.Mode.GRAPPLE)
	assert_bool(pull.aim_request).override_failure_message("asked during the pull").is_false()
	_assert_slot(pull.state, FighterCommand.GRAPPLE, pull_press)
	assert_int(rig.state.grapple_fired_tick).is_equal(fire_tick)
	var record := _record_grapple(rig, fire_tick, 5 * tickrate)
	assert_int(record.pull_start_tick).is_equal(rig.tick - 1 - record.pull_ticks())
	for plan: MovePlan in record.plans:
		assert_bool(plan.aim_request).is_false()
	_assert_released(record.release_plan, record.release_tick, FighterState.Mode.AIR)


# Criterion 6: a dash pressed on the floor while the cable flies does not dash: it waits in the
# slot, the pull starts on time, and no dash ever comes out (movimento.md, "Gancho": "Tempo até
# prender": "o dash espera na vaga"; DEC-0041).
func test_a_dash_press_on_the_floor_while_the_cable_flies_does_not_dash(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	var fire_tick := _fire(rig, POINT_UP_AHEAD)
	var press_tick := rig.tick
	var plan := rig.step(MovementRig.press_dash_toward(FORWARD))
	assert_int(plan.state.mode).override_failure_message("dashed with the cable out").is_equal(
		FighterState.Mode.GROUND
	)
	_assert_no_dash(plan)
	_assert_slot(plan.state, FighterCommand.DASH, press_tick)
	assert_int(plan.state.stamina_spent_tick).is_equal(FighterState.NEVER)
	assert_bool(rig.state.on_floor).is_true()
	var pull_start := _idle_until_pull(rig, ATTACH_TICKS[tickrate])
	assert_int(pull_start).is_equal(fire_tick + ATTACH_TICKS[tickrate])
	_assert_no_dash(rig.last_plan)
	rig.rest(BUFFER_TICKS[tickrate] + 1)
	_assert_no_dash(rig.last_plan)
	assert_int(rig.state.stamina_spent_tick).is_equal(FighterState.NEVER)


# Criterion 6, the coyote: leaving the floor pulled stamps no left_floor_tick, so after a release
# within 100 ms of the floor the first press in the air is the double jump, never the full one
# (movimento.md, "Gancho": "Coyote do gancho": "não existe").
func test_leaving_the_floor_pulled_opens_no_coyote(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var rig := _rig(tickrate)
	_fire(rig, POINT_UP_AHEAD)
	var pull_start := _idle_until_pull(rig, ATTACH_TICKS[tickrate] + 1)
	assert_bool(rig.state.on_floor).override_failure_message("the pull did not lift the body") \
			.is_false()
	assert_int(rig.state.left_floor_tick).override_failure_message("the pull opened the coyote") \
			.is_equal(FighterState.NEVER)
	var release := rig.step(MovementRig.press_jump())
	_assert_released(release, pull_start + 1, FighterState.Mode.AIR)
	assert_int(rig.state.left_floor_tick).is_equal(FighterState.NEVER)
	var press_tick := rig.tick
	assert_int(press_tick - pull_start).is_less_equal(COYOTE_TICKS[tickrate])
	var plan := rig.step(MovementRig.press_jump())
	_assert_double_jumped(rig, plan, press_tick)
