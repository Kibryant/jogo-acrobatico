# The movement rules of the fighter: the two slices of bread of the tick sandwich (visao-geral.md,
# "O tick por dentro: o sanduíche"). before_move decides, the engine moves the body by
# plan.velocity / tickrate and collides, and after_move confers with what the engine reports.
# Both are pure: they read the state they receive and return a new one, so a rollback can run a
# tick again from a restored state (DEC-0004, rule 1; DEC-0022). Every number comes from the
# MovementConfig, already in ticks.
# The mode changes in two places (DEC-0041): by command in before_move, where the press comes out
# (GROUND to DASH, the wall jump from WALL_RUN to AIR), and by contact in after_move, where the
# engine's verdict comes in (GROUND, AIR and the entry into WALL_RUN). A committed mode only ends
# by its own rule: the dash in before_move; the wall run by its time or the wall jump in
# before_move, and by the contact it loses in after_move (movimento.md, "Corrida na parede"); the
# grapple's pull by its releases in before_move (movimento.md, "Gancho").
# The grapple is the one rule that asks the scenery (DEC-0044): while a press that can fire waits
# in the slot, before_move sets MovePlan.aim_request, the node casts the aim's ray after the move,
# and after_move fires on the answer in MoveFacts.
class_name Movement
extends RefCounted

# Floating-point slack of the wall jump's turn, against the unit run direction: a stick turned by
# the camera exactly across the wall reads ~1e-7 along it. Not a design number.
const TURN_HAIR := 1e-4


# Puts the presses in the slot. A grapple whose cable has flown pulls, or releases and leaves a
# free tick. A dash whose ticks ran out ends; inside a dash nothing else happens. A wall run runs
# on its wall, or ends by its time. Otherwise it applies the acceleration and gravity, then fires
# the slot: the jump from the floor or the coyote, otherwise the double jump, or the dash from the
# floor; a grapple that can fire asks for the aim (DEC-0039; DEC-0044).
static func before_move(
	state: FighterState,
	position: Vector3,
	velocity: Vector3,
	input: TickInput,
	config: MovementConfig,
	tick: int,
) -> MovePlan:
	var next := state.copy()
	# The body looks where the camera looks (movimento.md, "Princípios").
	next.facing_yaw = input.yaw
	# One slot for every command: a new press takes it and the older one is gone (movimento.md,
	# "Perdão": "Um buffer só, para todo comando"; DEC-0039). The grapple is written first and the
	# jump last, so a tie on one tick leaves the jump, then the dash, then the grapple ("No mesmo
	# tick, o pulo vence o dash, que vence o gancho"; DEC-0039 §4).
	if input.grapple:
		_take_slot(next, FighterCommand.GRAPPLE, tick)
	if input.dash:
		_take_slot(next, FighterCommand.DASH, tick)
	if input.jump:
		_take_slot(next, FighterCommand.JUMP, tick)
	if not _within(next.buffered_tick, tick, config.buffer_ticks):
		# A press whose window closed never fires, so it leaves the slot (DEC-0039).
		_clear_slot(next)
	if next.grapple_fired_tick != FighterState.NEVER:
		var pull_from := next.grapple_fired_tick + config.grapple_attach_ticks
		if tick >= pull_from:
			# The cable has flown (movimento.md, "Gancho": "Tempo até prender"): the pull is a
			# committed mode that ends whatever mode the body was in (DEC-0041).
			if next.mode != FighterState.Mode.GRAPPLE:
				next.mode = FighterState.Mode.GRAPPLE
				next.mode_since = tick
			if not _releases(next, position, velocity, config, tick):
				return _pull(next, position, config)
			# The release ("Como solta"): the end stamped for the cooldown, no cable in the air, the
			# mode of the floor's verdict, and this tick runs free on the incoming velocity.
			next.grapple_end_tick = tick
			next.grapple_fired_tick = FighterState.NEVER
			next.mode = FighterState.Mode.GROUND if state.on_floor else FighterState.Mode.AIR
			next.mode_since = tick
	if next.mode == FighterState.Mode.WALL_RUN:
		if tick - next.mode_since < config.wall_run_max_ticks:
			return _wall_run(next, velocity, input, config, tick)
		# The end by time (movimento.md, "Corrida na parede": "Duração máxima"): from this tick
		# the body is in the air with the double jump the entry renewed, and the wall has no
		# coyote, so a press now is the double jump ("Pulo da parede no voo").
		next.mode = FighterState.Mode.AIR
		next.mode_since = tick
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
	return _asking(_plan(next, horizontal, vertical), config, tick)


# Reads the engine's verdict: the floor renews the jump and the double jump, clears the last wall
# and ends a wall run, and leaving the floor stamps the tick the coyote counts from. The contact
# changes the mode between GROUND and AIR, but never ends the dash or the grapple's pull: the dash
# goes on off a ledge, and the pull along or off the floor (DEC-0041 §3). In the air, the wall
# facts start, carry on or end a wall run. Last, a grapple that asked for the aim fires on the
# answer (DEC-0044).
static func after_move(
	state: FighterState,
	facts: MoveFacts,
	config: MovementConfig,
	tick: int,
) -> FighterState:
	var next := state.copy()
	var pulled := state.mode == FighterState.Mode.GRAPPLE
	var by_contact := state.mode != FighterState.Mode.DASH and not pulled
	if facts.on_floor:
		# Touching the floor renews the double jump (movimento.md, "Pulo e ar"), and the same wall
		# accepts a run again ("Corrida na parede": "Mesma parede").
		next.jumps_used = 0
		next.double_jump_tick = FighterState.NEVER
		next.wall_normal = Vector3.ZERO
		next.wall_id = &""
		if not state.on_floor and by_contact:
			next.mode = FighterState.Mode.GROUND
			next.mode_since = tick
	elif state.on_floor:
		if by_contact:
			next.mode = FighterState.Mode.AIR
			next.mode_since = tick
		# The pull has no coyote (movimento.md, "Gancho": "Coyote do gancho": "não existe"):
		# leaving the floor pulled stamps nothing, so after the release the first press in the air
		# is the double jump.
		if not pulled:
			next.left_floor_tick = tick
	next.on_floor = facts.on_floor
	if by_contact and not facts.on_floor:
		_read_wall(next, facts, config, tick)
	if _hooks(state, facts, config, tick):
		_fire(next, facts.aim_point, tick)
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
# far enough in the past to count as free. With a grapple's cable in the air the dash waits in the
# slot: one committed mode at a time ("Gancho": "Tempo até prender"; DEC-0041).
static func _can_dash(state: FighterState, tick: int, config: MovementConfig) -> bool:
	if state.mode != FighterState.Mode.GROUND or not state.on_floor:
		return false
	if state.grapple_fired_tick != FighterState.NEVER:
		return false
	if tick - state.dash_tick < config.dash_ticks + config.dash_cooldown_ticks:
		return false
	return Stamina.at(state, config, tick) >= config.dash_cost


# The grapple may fire from the floor, the air and a wall run, never in the dash nor with another
# cable in the air, flying or pulling, and only once its cooldown after the last release has passed
# (movimento.md, "Gancho": "De onde dispara", "Recarga"). The cooldown reads the stamp, as the
# dash's does: NEVER is far enough in the past to count as free. Public, so the reticle on screen
# reads the same rule (visual-e-audio.md, "O gancho na tela").
static func can_grapple(state: FighterState, tick: int, config: MovementConfig) -> bool:
	if state.mode == FighterState.Mode.DASH or state.mode == FighterState.Mode.GRAPPLE:
		return false
	if state.grapple_fired_tick != FighterState.NEVER:
		return false
	return tick - state.grapple_end_tick >= config.grapple_cooldown_ticks


# The aim request (DEC-0044 §1): a grapple press that can fire waits in the slot of the plan, so
# the node casts the ray after the move, on every tick of its window until it hooks (movimento.md,
# "Gancho": "O erro": the aim is cast again on every tick, with that tick's direction).
static func _asking(plan: MovePlan, config: MovementConfig, tick: int) -> MovePlan:
	var waiting := plan.state.buffered_command == FighterCommand.GRAPPLE
	plan.aim_request = waiting and can_grapple(plan.state, tick, config)
	return plan


# The fire (movimento.md, "Gancho": "Alcance", "Alcance mínimo", "O erro"): the plan asked, and the
# ray found the scenery from grapple_min_range to grapple_range off the point O of the feet after
# the move and of the tick's yaw, which before_move copied into facing_yaw (DEC-0045 §2), both
# limits inclusive. Otherwise nothing happens: the press keeps waiting while its window lives, and
# the cooldown does not count.
static func _hooks(
	state: FighterState,
	facts: MoveFacts,
	config: MovementConfig,
	tick: int,
) -> bool:
	if state.buffered_command != FighterCommand.GRAPPLE or not facts.aim_hit:
		return false
	if not can_grapple(state, tick, config):
		return false
	return in_reach(facts.aim_point, facts.position, state.facing_yaw, config)


# A point the hook can bite from these feet and this yaw: from grapple_min_range to grapple_range
# off the point O, aim_height above the feet and aim_side to the right of the yaw (Aim.origin),
# both limits inclusive (movimento.md, "Gancho": "Alcance", "Alcance mínimo"; DEC-0045 §2).
# Public, so the reticle on screen reads the same rule, with the camera's yaw.
static func in_reach(point: Vector3, feet: Vector3, yaw: float, config: MovementConfig) -> bool:
	var origin := Aim.origin(feet, yaw, config.aim_height, config.aim_side)
	var distance := point.distance_to(origin)
	return distance >= config.grapple_min_range and distance <= config.grapple_range


# The hook bites: the cable flies from this tick toward the point, fixed now ("Tempo até
# prender"), and the press is spent. A wall run ends on the fire ("De onde dispara": "Na parede, a
# corrida acaba no disparo"); any other mode goes on until the pull starts.
static func _fire(next: FighterState, point: Vector3, tick: int) -> void:
	next.grapple_fired_tick = tick
	next.grapple_point = point
	_clear_slot(next)
	if next.mode == FighterState.Mode.WALL_RUN:
		_leave_wall(next, tick)


# The releases of the pull, checked at the start of every attached tick, its first included, in
# this order (movimento.md, "Gancho": "Como solta", "Trava", "O pulo na puxada"):
# (a) a jump pressed on or after the pull's first tick, spent here: no jump comes out, and the
#     next press in the air is the double jump. A jump pressed while the cable flew does not
#     release; it dies with its window;
# (b) the feet within the release distance of the point;
# (c) from the pull's second tick, the incoming velocity toward the point below the block speed:
#     a wall or a slide ate more than half of the pull.
static func _releases(
	next: FighterState,
	position: Vector3,
	velocity: Vector3,
	config: MovementConfig,
	tick: int,
) -> bool:
	var pull_from := next.grapple_fired_tick + config.grapple_attach_ticks
	var jumped := next.buffered_command == FighterCommand.JUMP
	if jumped and next.buffered_tick >= pull_from:
		_clear_slot(next)
		return true
	if position.distance_to(next.grapple_point) <= config.grapple_release_distance:
		return true
	if tick - pull_from < 1:
		return false
	var toward := (next.grapple_point - position).normalized()
	return velocity.dot(toward) < config.grapple_block_speed


# A tick of the pull (movimento.md, "Gancho": "Velocidade da puxada", "O que a puxada leva ao
# ponto"): the feet go toward the point at the pull's speed, the direction taken again from where
# they are on every tick, with no gravity and no input.
static func _pull(next: FighterState, position: Vector3, config: MovementConfig) -> MovePlan:
	var plan := MovePlan.new()
	plan.state = next
	plan.velocity = (next.grapple_point - position).normalized() * config.grapple_pull_speed
	return plan


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
# air keeps its speed (movimento.md, "Princípios": speed carries between maneuvers). In the air
# the target keeps the speed the body has when it is above run_speed, so the input turns and
# brakes it only by the air acceleration and never cuts the excess; on the floor the excess falls
# by the ground acceleration (movimento.md, "Pulo e ar": "Controle no ar"; F-127).
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
	if state.on_floor:
		return current.move_toward(
			_world(move, input.yaw) * config.run_speed,
			config.ground_accel_per_tick,
		)
	var speed := maxf(config.run_speed, current.length())
	return current.move_toward(_world(move, input.yaw) * speed, config.air_accel_per_tick)


# A tick of the wall run (movimento.md, "Corrida na parede"), committed: the input neither turns
# nor brakes it. The speed along the wall is brought to wall_run_speed, or kept from a faster
# entry up to wall_max_speed, in the direction it has along the wall's plane. The height holds
# while the run is younger than wall_hold_ticks; then on the k-th slide tick the vertical is
# -k times wall_slide_gravity_per_tick, set before the move ("Descida, tick a tick"). A jump in
# the slot is the wall jump: the jump's parabola for its own height, the push out of the wall
# along its normal, the speed along kept; it is the first jump of the flight, the double jump
# stays, and the body is in the air from this tick ("Pulo da parede"; DEC-0041). A press made up
# to the buffer before the touch fires here, on the first tick of the run (DEC-0039). The stick of
# the tick the jump fires on may turn it back along the wall ("A volta no pulo da parede").
static func _wall_run(
	next: FighterState,
	velocity: Vector3,
	input: TickInput,
	config: MovementConfig,
	tick: int,
) -> MovePlan:
	var along := _along_wall(Vector3(velocity.x, 0.0, velocity.z), next.wall_normal)
	var speed := clampf(along.length(), config.wall_run_speed, config.wall_max_speed)
	var horizontal := along.normalized() * speed
	var age := tick - next.mode_since
	var vertical := 0.0
	if age >= config.wall_hold_ticks:
		vertical = -(age - config.wall_hold_ticks + 1) * config.wall_slide_gravity_per_tick
	if next.buffered_command == FighterCommand.JUMP:
		vertical = config.wall_jump_speed
		if _points_back(input, along):
			horizontal = -horizontal
		horizontal += next.wall_normal * config.wall_jump_push
		next.jumps_used = 1
		next.wall_jump_tick = tick
		next.mode = FighterState.Mode.AIR
		next.mode_since = tick
		_clear_slot(next)
	return _asking(_plan(next, horizontal, vertical), config, tick)


# The turn of the wall jump (movimento.md, "Corrida na parede": "A volta no pulo da parede";
# F-131; F-136): the stick of this tick, turned by the camera like every direction, has a
# component along the wall against the run. Only its sign counts, never its size; no stick, a
# forward one or one only out of or into the wall keep the run's direction. TURN_HAIR keeps a
# stick exactly across the wall, read through a turned camera, from turning by rounding.
static func _points_back(input: TickInput, along: Vector3) -> bool:
	if input.move == Vector2.ZERO:
		return false
	var pointed := _world(input.move.limit_length(1.0), input.yaw)
	return pointed.dot(along.normalized()) < -TURN_HAIR


# The wall facts of a tick in the air (DEC-0042): they end, carry on or start a wall run. A run
# ends when the wall is lost, at its edge; when the body is slowed below the entry speed along
# it, by an obstacle; or when another collider beyond the same-face angle takes over, another
# face, where a new run may start on the same tick. Another collider within that angle, met
# without losing contact, is a seam: the same run goes on the next block, with its clock and
# without a new double jump (F-129). The same collider carries the run on whatever its normal
# reads, as on the rounded edge before a corner, and the state keeps the face's normal. Out of a
# run, a wall starts one ("Como entra").
static func _read_wall(
	next: FighterState,
	facts: MoveFacts,
	config: MovementConfig,
	tick: int,
) -> void:
	var touching := not facts.wall_id.is_empty()
	touching = touching and absf(facts.wall_normal.y) <= config.wall_max_normal_y
	var normal := _flat(facts.wall_normal)
	if next.mode == FighterState.Mode.WALL_RUN:
		if not touching:
			_leave_wall(next, tick)
			return
		if facts.wall_id != next.wall_id:
			if normal.dot(next.wall_normal) < config.wall_same_face_cos:
				_leave_wall(next, tick)
				_enter_wall(next, facts, normal, config, tick)
				return
			next.wall_id = facts.wall_id
			next.wall_normal = normal
		var horizontal := Vector3(facts.velocity.x, 0.0, facts.velocity.z)
		if _along_wall(horizontal, next.wall_normal).length() < config.wall_entry_speed:
			_leave_wall(next, tick)
		return
	if next.mode == FighterState.Mode.AIR and touching:
		_enter_wall(next, facts, normal, config, tick)


# The entry (movimento.md, "Corrida na parede": "Como entra", "O que decide a entrada", "Mesma
# parede"): a wall that is not the last one, the same collider within the same-face angle, with
# the speed along its plane at least the entry speed. It renews the double jump and clears the
# floor's coyote, so a run that starts and ends within 100 ms of the floor leaves the double jump,
# never the full one ("O coyote do chão na entrada"; Q-35); the next tick zeroes the vertical and
# sets the speed (_wall_run).
static func _enter_wall(
	next: FighterState,
	facts: MoveFacts,
	normal: Vector3,
	config: MovementConfig,
	tick: int,
) -> void:
	var same := facts.wall_id == next.wall_id
	if same and normal.dot(next.wall_normal) >= config.wall_same_face_cos:
		return
	var horizontal := Vector3(facts.velocity.x, 0.0, facts.velocity.z)
	if _along_wall(horizontal, normal).length() < config.wall_entry_speed:
		return
	next.mode = FighterState.Mode.WALL_RUN
	next.mode_since = tick
	next.jumps_used = 0
	next.double_jump_tick = FighterState.NEVER
	next.left_floor_tick = FighterState.NEVER
	next.wall_id = facts.wall_id
	next.wall_normal = normal


static func _leave_wall(next: FighterState, tick: int) -> void:
	next.mode = FighterState.Mode.AIR
	next.mode_since = tick


# The horizontal velocity along a wall: its part on the plane of the flattened normal.
static func _along_wall(horizontal: Vector3, normal: Vector3) -> Vector3:
	var flat := _flat(normal)
	return horizontal - flat * horizontal.dot(flat)


# A normal laid flat: the horizontal unit vector the wall faces.
static func _flat(normal: Vector3) -> Vector3:
	return Vector3(normal.x, 0.0, normal.z).normalized()


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
