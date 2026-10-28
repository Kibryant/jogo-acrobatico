# The combat's step of the tick sandwich (DEC-0051 §2; visao-geral.md, "O tick por dentro"): pure,
# it runs before Movement.before_move on the state the last tick left, against the photo of the
# tick (TickPhoto), and returns a new state. A fighter writes only its own state and reads the
# others only in the photo, so the order of the nodes never changes the result (DEC-0026 §3): the
# attacker stamps the contact on its own state, and the target resolves it on the next tick, the
# first whose photo shows it. The order inside the step (DEC-0051 §2; DEC-0055):
# 1. the contacts the photo shows against this fighter, stamped on the tick before, resolved on its
#    own state as the contact tick left it: blocked, with the guard up, the attacker in front and
#    the stamina to pay, or taken; each a stun and a hitstop from the contact (DEC-0055 §3). Then
#    the attacker's side: the photo shows the result of its own contact of two ticks ago, and it
#    freezes from now for that result's hitstop, its swing's clock moved forward by as much
#    (DEC-0055 §4);
# 2. the refill to the max, when the configuration turns it on, health_refill_ticks after
#    hurt_tick (partida.md, "A vida sem partida");
# 3. on a frozen tick, only the presses into the slot, and nothing else (DEC-0055 §5);
# 4. the phase of the swing, advanced by the move's ticks, and the end of a stun;
# 5. the guard, held standing on the floor with no swing and no stun (DEC-0055 §2);
# 6. the light's press into the slot, then the movement's presses (Movement.take_presses), so any
#    movement key beats the light on one tick, and the light fires when the slot holds it, standing
#    on the floor, with no swing or stun in progress and the stamina to pay (DEC-0051 §4); it fires
#    from the guard too, and drops it;
# 7. the swing's direction follows the camera on every tick of the windup;
# 8. on an active tick, the slice of that tick against every other fighter of the photo, in name
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
	_take_contacts(next, me, feet, photo, combat, config, tick)
	_learn_result(next, photo, combat, tick)
	_refill(next, combat, tick)
	if frozen(next, tick):
		_write_presses(next, input, config, tick)
		return next
	_advance(next, combat, tick)
	_end_stun(next, input, combat, tick)
	_guard(next, input, tick)
	_take_press(next, input, combat, config, tick)
	if next.action == FighterState.Action.WINDUP:
		next.action_yaw = input.yaw
	_touch(next, me, feet, photo, combat, config, tick)
	return next


## Whether tick is a frozen tick of the hitstop: up to and including frozen_until_tick (DEC-0055
## §5). The movement reads it too, and the node skips the engine on it.
static func frozen(state: FighterState, tick: int) -> bool:
	return tick <= state.frozen_until_tick


## Whether the fighter is in a stun, a hit's or a block's (combate.md, "O tranco e o corpo"): no
## input of movement nor of action, the presses wait in the slot.
static func stunned(state: FighterState) -> bool:
	return (
		state.action == FighterState.Action.HITSTUN or state.action == FighterState.Action.BLOCKSTUN
	)


## Whether a swing is in progress: its windup, its active or its recovery.
static func swinging(state: FighterState) -> bool:
	return (
		state.action == FighterState.Action.WINDUP or state.action == FighterState.Action.ACTIVE
		or state.action == FighterState.Action.RECOVERY
	)


## The tick the active in progress began before any hitstop moved its clock: the key its cue plays
## by, the same on every tick of the active (DEC-0031 §6). The attacker's freeze is the only one
## inside a swing (a hit taken ends it), and it moves action_since forward by the hitstop h,
## stamping frozen_until_tick at contact + 1 + h; a freeze of an older swing or stun ended before
## this swing began, so it never reaches action_since.
static func active_began(state: FighterState) -> int:
	if _shifted_by_freeze(state):
		return state.action_since - (state.frozen_until_tick - state.contact_tick - 1)
	return state.action_since


## The tick a pose of the swing reads: on a frozen tick, the last tick of the freeze, which with
## the clock moved forward is the pose of the tick before the freeze, so the screen holds the
## impact's pose; any other tick, itself.
static func posed_tick(state: FighterState, tick: int) -> int:
	return maxi(tick, state.frozen_until_tick)


# Step 1, the defender's side: every contact stamped against me on the tick before, by any
# fighter of the photo (combate.md, "O leve no tick": "Quem levou"), in name order. Two attackers
# on the same tick both count: a block leaves the guard up for the next, a hit leaves none.
static func _take_contacts(
	next: FighterState,
	me: StringName,
	feet: Vector3,
	photo: TickPhoto,
	combat: CombatConfig,
	config: MovementConfig,
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
		var contact := other.contact_tick
		if _blocks(next, feet, entry.feet, attack, combat, config, contact):
			_block(next, attack, config, contact)
		else:
			_hit(next, attack, contact)


# The block holds when the guard was up on the contact tick: BLOCK risen for its ticks, or a
# blockstun, which keeps it up; the attacker's feet within the half angle of where the body
# looked, on the floor's plane, from axis to axis (DEC-0054 §2); and the bar can pay the cost
# (combate.md, "Sem stamina para o custo, a guarda cai no golpe"). The state is the one the
# contact tick left: the start of this tick (DEC-0055 §3).
static func _blocks(
	next: FighterState,
	feet: Vector3,
	attacker_feet: Vector3,
	attack: AttackConfig,
	combat: CombatConfig,
	config: MovementConfig,
	contact: int,
) -> bool:
	var up := next.action == FighterState.Action.BLOCKSTUN
	if next.action == FighterState.Action.BLOCK:
		up = contact - next.action_since >= combat.guard_raise_ticks
	if not up:
		return false
	var toward := Vector3(attacker_feet.x - feet.x, 0.0, attacker_feet.z - feet.z)
	# On the same axis there is no side to come from: the front covers it.
	if not toward.is_zero_approx():
		if Blade.direction(next.facing_yaw).angle_to(toward) > combat.guard_half_angle:
			return false
	return Stamina.at(next, config, contact) >= attack.block_stamina_cost


# The block: the cost paid on the contact, the blockstun and its hitstop from it, and the block's
# stamp, which the attacker reads (DEC-0055 §3 and §4). A block in the blockstun restarts it.
static func _block(
	next: FighterState,
	attack: AttackConfig,
	config: MovementConfig,
	contact: int,
) -> void:
	Stamina.spend(next, config, contact, attack.block_stamina_cost)
	next.action = FighterState.Action.BLOCKSTUN
	next.action_since = contact
	next.action_move = &""
	next.block_tick = contact
	next.stun_until_tick = contact + attack.blockstun_ticks + attack.hitstop_block_ticks
	next.frozen_until_tick = contact + attack.hitstop_block_ticks


# The hit: the damage, never below 0, the hitstun and its hitstop from the contact, and the hurt
# stamp; the swing in progress, if any, ends here (combate.md, "O tranco no tick"). A hit in the
# stun restarts it from the new contact.
static func _hit(next: FighterState, attack: AttackConfig, contact: int) -> void:
	next.health = maxi(0, next.health - attack.damage)
	next.hurt_tick = contact
	next.action = FighterState.Action.HITSTUN
	next.action_since = contact
	next.action_move = &""
	next.stun_until_tick = contact + attack.hitstun_ticks + attack.hitstop_hit_ticks
	next.frozen_until_tick = contact + attack.hitstop_hit_ticks


# Step 1, the attacker's side (DEC-0055 §4): the target resolved my contact on the tick after it,
# so this photo, two ticks after it, is the first to show the result. A hit or a block freezes me
# from this tick for its hitstop, and moves my swing's clock forward as much, so my recovery ends
# that much later and the advantage stays; a contact with no result freezes nobody. Only the swing
# that made the contact freezes: a fighter whose swing a hit ended is frozen as a target already.
static func _learn_result(
	next: FighterState,
	photo: TickPhoto,
	combat: CombatConfig,
	tick: int,
) -> void:
	if next.contact_tick == FighterState.NEVER or next.contact_tick != tick - 2:
		return
	if not swinging(next) or not combat.attacks.has(next.contact_move):
		return
	var target := photo.find(next.contact_target)
	if target == null:
		return
	var attack: AttackConfig = combat.attacks[next.contact_move]
	var hitstop: int
	if target.state.hurt_tick == next.contact_tick:
		hitstop = attack.hitstop_hit_ticks
	elif target.state.block_tick == next.contact_tick:
		hitstop = attack.hitstop_block_ticks
	else:
		return
	next.frozen_until_tick = tick + hitstop - 1
	next.action_since += hitstop


# Step 2: the health back at the max once the last hit is old enough; a fighter never hurt, whose
# hurt_tick is NEVER, refills at once.
static func _refill(next: FighterState, combat: CombatConfig, tick: int) -> void:
	if combat.health_refill_ticks <= 0 or next.health >= combat.max_health:
		return
	if tick - next.hurt_tick >= combat.health_refill_ticks:
		next.health = combat.max_health


# Step 3: a frozen tick keeps the presses, which wait in the slot for their window like in a
# swing, and changes nothing else (DEC-0055 §5).
static func _write_presses(
	next: FighterState,
	input: TickInput,
	config: MovementConfig,
	tick: int,
) -> void:
	if input.light_attack:
		next.buffered_command = FighterCommand.LIGHT_ATTACK
		next.buffered_tick = tick
	Movement.take_presses(next, input, tick, config)


# Step 4: each phase of a swing lasts its ticks from the tick it began; a phase of 0 ticks passes
# at once. Fired at F, the light is WINDUP from F, ACTIVE from F + 15, RECOVERY from F + 21 and NONE
# from F + 33 at 60 ticks (combate.md, "O leve no tick": "As fases"; DEC-0052), each later by the
# hitstop when the swing's contact had a result (DEC-0055 §5).
static func _advance(next: FighterState, combat: CombatConfig, tick: int) -> void:
	if not swinging(next):
		return
	if not combat.attacks.has(next.action_move):
		_end_swing(next, tick)
		return
	var attack: AttackConfig = combat.attacks[next.action_move]
	while swinging(next):
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


# Step 4, the stun's end: on stun_until_tick the fighter acts again (combate.md, "O tranco no
# tick"). After a blockstun with the button still held, the guard is already up, as if it had
# risen for its ticks; otherwise the action is NONE, and the guard, held, rises from here.
static func _end_stun(
	next: FighterState,
	input: TickInput,
	combat: CombatConfig,
	tick: int,
) -> void:
	if not stunned(next) or tick < next.stun_until_tick:
		return
	var blocked := next.action == FighterState.Action.BLOCKSTUN
	next.action = FighterState.Action.NONE
	next.action_since = next.stun_until_tick
	if blocked and input.guard and _can_guard(next):
		next.action = FighterState.Action.BLOCK
		next.action_since = tick - combat.guard_raise_ticks


# Step 5, the guard (DEC-0055 §2; combate.md, "A guarda andando"): held, standing on a floor of its
# own with no cable in the air, and with no swing nor stun, the action is BLOCK from the tick the
# rise began; let go, or off the floor, it drops on that tick.
static func _guard(next: FighterState, input: TickInput, tick: int) -> void:
	var can := input.guard and _can_guard(next)
	if next.action == FighterState.Action.BLOCK and not can:
		next.action = FighterState.Action.NONE
		next.action_since = tick
	elif next.action == FighterState.Action.NONE and can:
		next.action = FighterState.Action.BLOCK
		next.action_since = tick


# In the air there is no guard, nor on another fighter's head, nor in a dash, a wall run or with
# the grapple's cable out (combate.md, "No ar não há guarda").
static func _can_guard(next: FighterState) -> bool:
	if next.mode != FighterState.Mode.GROUND or not Movement.stands(next):
		return false
	return next.grapple_fired_tick == FighterState.NEVER


# Step 6: the slot of the buffer, shared with the movement (DEC-0039; DEC-0051 §4). The light is
# written first, then the movement's presses over it, and the slot's expiry; the light fires only
# from the slot, so a press refused now waits there for its 150 ms.
static func _take_press(
	next: FighterState,
	input: TickInput,
	combat: CombatConfig,
	config: MovementConfig,
	tick: int,
) -> void:
	_write_presses(next, input, config, tick)
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


# Standing on a floor of its own (GROUND, off any head; Movement.stands), with no swing nor stun in
# progress, the guard being no obstacle, and the bar able to pay (combate.md, "O leve no tick":
# "Quando o leve sai"; DEC-0055 §2: "O leve sai da guarda").
static func _can_swing(
	next: FighterState,
	attack: AttackConfig,
	config: MovementConfig,
	tick: int,
) -> bool:
	if next.mode != FighterState.Mode.GROUND or not Movement.stands(next):
		return false
	var free := next.action == FighterState.Action.NONE
	if not free and next.action != FighterState.Action.BLOCK:
		return false
	return Stamina.at(next, config, tick) >= attack.stamina_cost


# Step 8: the slice of the k-th active tick, k from 1, against the others of the photo in name
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
	if _touched(next):
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


# Whether the active in progress already has its contact (Q-26): stamped since the active began,
# or a freeze of this swing, which only a contact of it starts, moved the active's clock past the
# stamp (DEC-0055 §5).
static func _touched(next: FighterState) -> bool:
	if next.contact_tick == FighterState.NEVER:
		return false
	return next.contact_tick >= next.action_since or _shifted_by_freeze(next)


# In the active, the attacker's freeze of this swing stamps frozen_until_tick past the moved
# action_since: at contact + 1 + h against at most contact + h. Any older freeze ended before the
# swing fired, so before its active began.
static func _shifted_by_freeze(state: FighterState) -> bool:
	if state.action != FighterState.Action.ACTIVE:
		return false
	if state.contact_tick == FighterState.NEVER:
		return false
	return state.frozen_until_tick >= state.action_since
