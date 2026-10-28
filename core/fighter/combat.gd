# The combat's step of the tick sandwich (DEC-0051 §2; visao-geral.md, "O tick por dentro"): pure,
# it runs before Movement.before_move on the state the last tick left, against the photo of the
# tick (TickPhoto), and returns a new state. A fighter writes only its own state and reads the
# others only in the photo, so the order of the nodes never changes the result (DEC-0026 §3): the
# attacker stamps the contact on its own state, and the target applies it on the next tick, the
# first whose photo shows it. The order inside the step:
# 1. the contacts the photo shows against this fighter, stamped on the tick before: the move's
#    damage, never below 0, and hurt_tick on the contact's tick;
# 2. the refill to the max, when the configuration turns it on, health_refill_ticks after
#    hurt_tick (partida.md, "A vida sem partida");
# 3. the phase of the swing, advanced by the move's ticks;
# 4. the light's press into the slot, then the movement's presses (Movement.take_presses), so any
#    movement key beats the light on one tick, and the light fires when the slot holds it, standing
#    on the floor, with no swing in progress and the stamina to pay (DEC-0051 §4);
# 5. the swing's direction follows the camera on every tick of the windup;
# 6. on an active tick, the slice of that tick against every other fighter of the photo, in name
#    order, until the swing has its one contact (Q-26).
class_name Combat
extends RefCounted


static func step(
	state: FighterState,
	me: StringName,
	feet: Vector3,
	photo: TickPhoto,
	input: TickInput,
	combat: CombatConfig,
	config: MovementConfig,
	tick: int,
) -> FighterState:
	var next := state.copy()
	_take_contacts(next, me, photo, combat, tick)
	_refill(next, combat, tick)
	_advance(next, combat, tick)
	_take_press(next, input, combat, config, tick)
	if next.action == FighterState.Action.WINDUP:
		next.action_yaw = input.yaw
	_touch(next, me, feet, photo, combat, config, tick)
	return next


# Step 1: every contact stamped against me on the tick before, by any fighter of the photo
# (combate.md, "O leve no tick": "Quem levou"). Two attackers on the same tick both count.
static func _take_contacts(
	next: FighterState,
	me: StringName,
	photo: TickPhoto,
	combat: CombatConfig,
	tick: int,
) -> void:
	for entry: TickPhoto.Entry in photo.entries():
		if entry.name == me:
			continue
		var other := entry.state
		if other.contact_target != me or other.contact_tick != tick - 1:
			continue
		if not combat.attacks.has(other.contact_move):
			continue
		var attack: AttackConfig = combat.attacks[other.contact_move]
		next.health = maxi(0, next.health - attack.damage)
		next.hurt_tick = other.contact_tick


# Step 2: the health back at the max once the last hit is old enough; a fighter never hurt, whose
# hurt_tick is NEVER, refills at once.
static func _refill(next: FighterState, combat: CombatConfig, tick: int) -> void:
	if combat.health_refill_ticks <= 0 or next.health >= combat.max_health:
		return
	if tick - next.hurt_tick >= combat.health_refill_ticks:
		next.health = combat.max_health


# Step 3: each phase lasts its ticks from the tick it began; a phase of 0 ticks passes at once.
# Fired at F, the light is WINDUP from F, ACTIVE from F + 24, RECOVERY from F + 30 and NONE from
# F + 45 at 60 ticks (combate.md, "O leve no tick": "As fases").
static func _advance(next: FighterState, combat: CombatConfig, tick: int) -> void:
	if next.action == FighterState.Action.NONE:
		return
	if not combat.attacks.has(next.action_move):
		_end_swing(next, tick)
		return
	var attack: AttackConfig = combat.attacks[next.action_move]
	while next.action != FighterState.Action.NONE:
		var length := _phase_ticks(next.action, attack)
		if tick - next.action_since < length:
			return
		var began := next.action_since + length
		match next.action:
			FighterState.Action.WINDUP:
				next.action = FighterState.Action.ACTIVE
			FighterState.Action.ACTIVE:
				next.action = FighterState.Action.RECOVERY
			_:
				_end_swing(next, began)
				return
		next.action_since = began


static func _phase_ticks(action: FighterState.Action, attack: AttackConfig) -> int:
	match action:
		FighterState.Action.WINDUP:
			return attack.windup_ticks
		FighterState.Action.ACTIVE:
			return attack.active_ticks
	return attack.recovery_ticks


static func _end_swing(next: FighterState, tick: int) -> void:
	next.action = FighterState.Action.NONE
	next.action_since = tick
	next.action_move = &""


# Step 4: the slot of the buffer, shared with the movement (DEC-0039; DEC-0051 §4). The light is
# written first, then the movement's presses over it, and the slot's expiry; the light fires only
# from the slot, so a press refused now waits there for its 150 ms.
static func _take_press(
	next: FighterState,
	input: TickInput,
	combat: CombatConfig,
	config: MovementConfig,
	tick: int,
) -> void:
	if input.light_attack:
		next.buffered_command = FighterCommand.LIGHT_ATTACK
		next.buffered_tick = tick
	Movement.take_presses(next, input, tick, config)
	if next.buffered_command != FighterCommand.LIGHT_ATTACK:
		return
	var attack: AttackConfig = combat.attacks[FighterCommand.LIGHT_ATTACK]
	if not _can_swing(next, attack, config, tick):
		return
	next.action = FighterState.Action.WINDUP
	next.action_since = tick
	next.action_move = FighterCommand.LIGHT_ATTACK
	Stamina.spend(next, config, tick, attack.stamina_cost)
	next.buffered_command = FighterCommand.NONE
	next.buffered_tick = FighterState.NEVER


# Standing on a floor of its own (GROUND, off any head; Movement.stands), with no swing in
# progress and the bar able to pay (combate.md, "O leve no tick": "Quando o leve sai").
static func _can_swing(
	next: FighterState,
	attack: AttackConfig,
	config: MovementConfig,
	tick: int,
) -> bool:
	if next.mode != FighterState.Mode.GROUND or not Movement.stands(next):
		return false
	if next.action != FighterState.Action.NONE:
		return false
	return Stamina.at(next, config, tick) >= attack.stamina_cost


# Step 6: the slice of the k-th active tick, k from 1, against the others of the photo in name
# order; the first it touches takes the swing's one contact, stamped on this state.
static func _touch(
	next: FighterState,
	me: StringName,
	feet: Vector3,
	photo: TickPhoto,
	combat: CombatConfig,
	config: MovementConfig,
	tick: int,
) -> void:
	if next.action != FighterState.Action.ACTIVE:
		return
	if next.contact_tick != FighterState.NEVER and next.contact_tick >= next.action_since:
		return
	var attack: AttackConfig = combat.attacks[next.action_move]
	var slice := Blade.slice_of(attack, tick - next.action_since + 1)
	for entry: TickPhoto.Entry in photo.entries():
		if entry.name == me:
			continue
		var touched := Blade.slice_touches(
			feet,
			next.action_yaw,
			slice.x,
			slice.y,
			entry.feet,
			combat,
			config,
		)
		if touched:
			next.contact_tick = tick
			next.contact_target = entry.name
			next.contact_move = next.action_move
			return
