# The movement rules of the fighter: the two slices of bread of the tick sandwich (visao-geral.md,
# "O tick por dentro: o sanduíche"). before_move decides, the engine moves the body by
# plan.velocity / tickrate and collides, and after_move confers with what the engine reports.
# Both are pure: they read the state they receive and return a new one, so a rollback can run a
# tick again from a restored state (DEC-0004, rule 1; DEC-0022). Every number comes from the
# MovementConfig, already in ticks.
class_name Movement
extends RefCounted


# Stamps the press, then applies the buffer, the coyote, the jump, the acceleration and gravity.
static func before_move(
	state: FighterState,
	velocity: Vector3,
	input: TickInput,
	config: MovementConfig,
	tick: int,
) -> MovePlan:
	var next := state.copy()
	# The body looks where the camera looks (movimento.md, "Princípios").
	next.facing_yaw = input.yaw
	if input.jump:
		next.jump_pressed_tick = tick
	var horizontal := _horizontal(Vector3(velocity.x, 0.0, velocity.z), input, state, config)
	# On the floor the body rests on it; the engine keeps it there and slides it along ramps.
	var vertical := 0.0 if state.on_floor else _gravity(velocity.y, config)
	if _can_jump(next, tick, config):
		# Always a full jump, from the floor or off a ledge: it replaces the vertical speed.
		vertical = config.jump_speed
		next.jumps_used += 1
		next.jump_pressed_tick = FighterState.NEVER
	var plan := MovePlan.new()
	plan.state = next
	plan.velocity = Vector3(horizontal.x, vertical, horizontal.z)
	return plan


# Reads the engine's verdict: landing renews the jump, and leaving the floor stamps the tick the
# coyote counts from.
static func after_move(
	state: FighterState,
	facts: MoveFacts,
	_config: MovementConfig,
	tick: int,
) -> FighterState:
	var next := state.copy()
	if facts.on_floor:
		next.jumps_used = 0
		if not state.on_floor:
			next.mode = FighterState.Mode.GROUND
			next.mode_since = tick
	elif state.on_floor:
		next.mode = FighterState.Mode.AIR
		next.mode_since = tick
		next.left_floor_tick = tick
	next.on_floor = facts.on_floor
	return next


# A live press jumps from the floor, or within the coyote window after leaving a ledge without
# jumping (movimento.md, "Perdão"). A press on the floor is live on its own tick; one made in the
# air stays live for the buffer window and fires on the first tick that starts on the floor. In
# the air outside the coyote nothing happens: the double jump is phase 1.
static func _can_jump(state: FighterState, tick: int, config: MovementConfig) -> bool:
	if not _within(state.jump_pressed_tick, tick, config.buffer_ticks):
		return false
	if state.on_floor:
		return true
	return state.jumps_used == 0 and _within(state.left_floor_tick, tick, config.coyote_ticks)


# A window counts whole ticks since its stamp, inclusive: open while tick - stamp <= window.
static func _within(stamp: int, tick: int, window: int) -> bool:
	var age := tick - stamp
	return age >= 0 and age <= window


# The target is run_speed along the input, turned by the yaw: yaw 0 looks down -Z, move.x goes
# right and move.y forward. The speed moves toward it by a fixed amount per tick (movimento.md,
# "Chão"). Without input the floor stops the body and the air keeps its speed (movimento.md,
# "Princípios": speed carries between maneuvers).
static func _horizontal(
	current: Vector3,
	input: TickInput,
	state: FighterState,
	config: MovementConfig,
) -> Vector3:
	var move := input.move.limit_length(1.0)
	if move == Vector2.ZERO:
		if state.on_floor:
			return current.move_toward(Vector3.ZERO, config.stop_decel_per_tick)
		return current
	var direction := Basis(Vector3.UP, input.yaw) * Vector3(move.x, 0.0, -move.y)
	var gain := config.ground_accel_per_tick if state.on_floor else config.air_accel_per_tick
	return current.move_toward(direction * config.run_speed, gain)


# The rise gravity pulls while velocity.y > 0 and the fall gravity in the rest, capped at the
# fall speed (movimento.md, "Pulo e ar"). The velocity of a tick is its mean over the tick, so
# the tick that crosses the apex spends the share vertical / rise rising and the rest falling;
# that is what lands the jump fall_ticks after the apex instead of hovering a tick there.
static func _gravity(vertical: float, config: MovementConfig) -> float:
	var rise := config.rise_gravity_per_tick
	var fall := config.fall_gravity_per_tick
	var next: float
	if vertical >= rise:
		next = vertical - rise
	elif vertical > 0.0:
		next = -fall * (1.0 - vertical / rise)
	else:
		next = vertical - fall
	return maxf(next, -config.max_fall_speed)
