# The movement rules of the fighter: the two slices of bread of the tick sandwich (visao-geral.md,
# "O tick por dentro: o sanduíche"). before_move decides, the engine moves the body by
# plan.velocity / tickrate and collides, and after_move confers with what the engine reports.
# Both are pure: they read the state they receive and return a new one, so a rollback can run a
# tick again from a restored state (DEC-0004, rule 1; DEC-0022). Every number comes from the
# MovementConfig, already in ticks.
# The mode changes in two places (DEC-0041): by command in before_move, where the press comes out
# (GROUND to DASH), and by contact in after_move, where the engine's verdict comes in (GROUND and
# AIR). A committed mode, the dash, only ends by its own rule, in before_move.
class_name Movement
extends RefCounted


# Puts the presses in the slot and ends a dash whose ticks ran out; inside a dash nothing else
# happens. Otherwise it applies the acceleration and gravity, then fires the slot: the jump from
# the floor or the coyote, otherwise the double jump, or the dash from the floor. The position is
# unused until the grapple aims from it (DEC-0039; TASK-10.6).
static func before_move(
	state: FighterState,
	_position: Vector3,
	velocity: Vector3,
	input: TickInput,
	config: MovementConfig,
	tick: int,
) -> MovePlan:
	var next := state.copy()
	# The body looks where the camera looks (movimento.md, "Princípios").
	next.facing_yaw = input.yaw
	# One slot for every command: a new press takes it and the older one is gone (movimento.md,
	# "Perdão": "Um buffer só, para todo comando"; DEC-0039). The dash is written before the jump,
	# so a tie on one tick leaves the jump ("No mesmo tick, o pulo vence o dash"; DEC-0039 §4).
	if input.dash:
		_take_slot(next, FighterCommand.DASH, tick)
	if input.jump:
		_take_slot(next, FighterCommand.JUMP, tick)
	if not _within(next.buffered_tick, tick, config.buffer_ticks):
		# A press whose window closed never fires, so it leaves the slot (DEC-0039).
		_clear_slot(next)
	# On the floor the body rests on it; the engine keeps it there and slides it along ramps.
	var vertical := 0.0 if state.on_floor else _gravity(velocity.y, config)
	var current := Vector3(velocity.x, 0.0, velocity.z)
	var horizontal: Vector3
	if next.mode == FighterState.Mode.DASH:
		if tick - next.dash_tick < config.dash_ticks:
			# Committed (movimento.md, "Dash": "Comprometido"; DEC-0041): the fixed direction at
			# the dash speed whatever the input, a wall or a ledge, with gravity once off the floor.
			# A press keeps its place in the slot and waits for the end.
			return _plan(next, next.dash_direction * config.dash_speed, vertical)
		# The designed exit (DEC-0041 §2): the run speed in the dash's direction, and the mode of
		# the contact the dash ends on; the slot may fire on this same tick.
		current = next.dash_direction * config.dash_exit_speed
		horizontal = current
		next.mode = FighterState.Mode.GROUND if state.on_floor else FighterState.Mode.AIR
		next.mode_since = tick
	else:
		horizontal = _horizontal(current, input, state, config)
	if next.buffered_command == FighterCommand.JUMP:
		if _can_jump(next, tick, config):
			# Always a full jump, from the floor or off a ledge: it replaces the vertical speed.
			vertical = config.jump_speed
			next.jumps_used = 1
			_clear_slot(next)
		elif _can_double_jump(next, tick, config):
			# It replaces the vertical speed too, and the press tick is the first of its rise.
			vertical = config.double_jump_speed
			horizontal = _turn(current, input)
			next.jumps_used = 2
			next.double_jump_tick = tick
			Stamina.spend(next, config, tick, config.double_jump_cost)
			_clear_slot(next)
		# Otherwise the press waits in the slot while its window lives: the double jump spent or
		# the bar short, it becomes the jump of the landing (movimento.md, "Pulo e ar" and
		# "Perdão").
	elif next.buffered_command == FighterCommand.DASH:
		if _can_dash(next, tick, config):
			# The command changes the mode (DEC-0041 §1), and the press tick already moves at the
			# dash speed: it replaces the run speed, never adds to it. On the floor, so vertical 0.
			next.mode = FighterState.Mode.DASH
			next.mode_since = tick
			next.dash_tick = tick
			next.dash_direction = _dash_direction(input, next.facing_yaw)
			Stamina.spend(next, config, tick, config.dash_cost)
			_clear_slot(next)
			horizontal = next.dash_direction * config.dash_speed
		# Otherwise the press waits in the slot while its window lives: in the air, in the
		# cooldown or with the bar short, it dashes on the first tick it can (movimento.md, "Dash"
		# and "Perdão").
	return _plan(next, horizontal, vertical)


# Reads the engine's verdict: the floor renews the jump and the double jump, and leaving the floor
# stamps the tick the coyote counts from. The contact changes the mode between GROUND and AIR, but
# never ends a committed mode: the dash goes on off a ledge (DEC-0041 §3).
static func after_move(
	state: FighterState,
	facts: MoveFacts,
	_config: MovementConfig,
	tick: int,
) -> FighterState:
	var next := state.copy()
	var by_contact := state.mode != FighterState.Mode.DASH
	if facts.on_floor:
		# Touching the floor renews the double jump (movimento.md, "Pulo e ar").
		next.jumps_used = 0
		next.double_jump_tick = FighterState.NEVER
		if not state.on_floor and by_contact:
			next.mode = FighterState.Mode.GROUND
			next.mode_since = tick
	elif state.on_floor:
		if by_contact:
			next.mode = FighterState.Mode.AIR
			next.mode_since = tick
		next.left_floor_tick = tick
	next.on_floor = facts.on_floor
	return next


# The jump of the floor, before any jump of the flight: standing on the floor, or within the
# coyote window after leaving a ledge without jumping (movimento.md, "Perdão"). A press on the
# floor fires on its own tick; one made in the air fires on the first tick that starts on the
# floor, while its window lives.
static func _can_jump(state: FighterState, tick: int, config: MovementConfig) -> bool:
	if state.jumps_used != 0:
		return false
	if state.mode == FighterState.Mode.GROUND and state.on_floor:
		return true
	return _within(state.left_floor_tick, tick, config.coyote_ticks)


# The double jump, one per flight (movimento.md, "Pulo e ar"): after the jump, or in the air past
# the coyote without having jumped ("Aperto depois do coyote, sem ter pulado: é o pulo duplo"),
# and only when the bar can pay its cost ("Stamina": "Sem stamina suficiente, a manobra não
# sai"; nothing is paid then).
static func _can_double_jump(state: FighterState, tick: int, config: MovementConfig) -> bool:
	if state.on_floor:
		return false
	var past_coyote := not _within(state.left_floor_tick, tick, config.coyote_ticks)
	var in_flight := state.jumps_used == 1 or (state.jumps_used == 0 and past_coyote)
	return in_flight and Stamina.at(state, config, tick) >= config.double_jump_cost


# The dash starts only on the floor (movimento.md, "Dash": "Onde: só no chão"; the coyote forgives
# the jump, not the dash), once the cooldown after the last dash's end has passed ("Recarga"),
# and when the bar can pay its cost ("Stamina": nothing is paid otherwise). The cooldown reads
# the stamp: the last dash started dash_ticks + dash_cooldown_ticks ago or earlier, and NEVER is
# far enough in the past to count as free.
static func _can_dash(state: FighterState, tick: int, config: MovementConfig) -> bool:
	if state.mode != FighterState.Mode.GROUND or not state.on_floor:
		return false
	if tick - state.dash_tick < config.dash_ticks + config.dash_cooldown_ticks:
		return false
	return Stamina.at(state, config, tick) >= config.dash_cost


# Where the dash goes, fixed on its first tick (movimento.md, "Dash": "Direção"): the pointed
# direction, relative to the camera, whatever the stick's length; without one, where the body
# looks. A horizontal unit vector.
static func _dash_direction(input: TickInput, facing_yaw: float) -> Vector3:
	var direction := -Basis(Vector3.UP, facing_yaw).z
	if input.move != Vector2.ZERO:
		direction = _world(input.move, input.yaw)
	return Vector3(direction.x, 0.0, direction.z).normalized()


static func _take_slot(state: FighterState, command: StringName, tick: int) -> void:
	state.buffered_command = command
	state.buffered_tick = tick


static func _clear_slot(state: FighterState) -> void:
	state.buffered_command = FighterCommand.NONE
	state.buffered_tick = FighterState.NEVER


static func _plan(next: FighterState, horizontal: Vector3, vertical: float) -> MovePlan:
	var plan := MovePlan.new()
	plan.state = next
	plan.velocity = Vector3(horizontal.x, vertical, horizontal.z)
	return plan


# A window counts whole ticks since its stamp, inclusive: open while tick - stamp <= window
# (DEC-0039).
static func _within(stamp: int, tick: int, window: int) -> bool:
	var age := tick - stamp
	return age >= 0 and age <= window


# The input turned by the camera: yaw 0 looks down -Z, move.x goes right and move.y forward.
static func _world(move: Vector2, yaw: float) -> Vector3:
	return Basis(Vector3.UP, yaw) * Vector3(move.x, 0.0, -move.y)


# The target is run_speed along the input, turned by the yaw. The speed moves toward it by a
# fixed amount per tick (movimento.md, "Chão"). Without input the floor stops the body and the
# air keeps its speed (movimento.md, "Princípios": speed carries between maneuvers).
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
	var gain := config.ground_accel_per_tick if state.on_floor else config.air_accel_per_tick
	return current.move_toward(_world(move, input.yaw) * config.run_speed, gain)


# The double jump turns the whole horizontal velocity to the pointed direction, relative to the
# camera, with the same magnitude; without a direction it keeps it. The air control adds nothing
# on that tick (movimento.md, "Pulo e ar": "Mantém a velocidade horizontal, sem ganhar").
static func _turn(current: Vector3, input: TickInput) -> Vector3:
	if input.move == Vector2.ZERO:
		return current
	return _world(input.move, input.yaw).normalized() * current.length()


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
