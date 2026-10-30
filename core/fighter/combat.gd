# The combat's step of the tick sandwich (DEC-0051 §2; visao-geral.md, "O tick por dentro"): pure,
# it runs before Movement.before_move on the state the last tick left, against the photo of the
# tick (TickPhoto), and returns a new state. A fighter writes only its own state and reads the
# others only in the photo, so the order of the nodes never changes the result (DEC-0026 §3): the
# attacker stamps the contact on its own state, and the target resolves it on the next tick, the
# first whose photo shows it. The order inside the step (DEC-0051 §2; DEC-0055; DEC-0056):
# 1. the contacts the photo shows against this fighter, stamped on the tick before, resolved on its
#    own state as the contact tick left it, in this order: parried, a parryable move in the stance's
#    window with the attacker in front, which stamps parry_tick and nothing else; blocked, with the
#    guard up, the attacker in front and the stamina to pay; armored, a move that does not break
#    armor against the windup of a move with armor, the damage and the hurt stamp with no stun and
#    no freeze; or taken; a block or a hit is a stun and a hitstop from the contact (DEC-0055 §3).
#    Then the attacker's side: the photo shows the result of its own contact of two ticks ago, a
#    parry, a hit or a block, and it freezes from now for that result's hitstop: a hit or a block
#    moves its swing's clock forward by as much (DEC-0055 §4); a parry ends the swing and makes it
#    PARRIED, frozen alone (DEC-0056 §4);
# 2. the refill to the max, when the configuration turns it on, health_refill_ticks after
#    hurt_tick (partida.md, "A vida sem partida");
# 3. on a frozen tick, only the presses into the slot, and nothing else (DEC-0055 §5);
# 4. the phase of the swing, advanced by the move's ticks, a move that pays on release paying on its
#    first active tick; the end of the parry's stance and of the feint; and the end of a stun;
# 5. the feint: the guard button going down in the windup of a move that can be feinted, from the
#    tick after its fire to feint_until_ticks, with the bar to pay, cuts it into FEINT
#    (DEC-0056 §5);
# 6. the guard, held standing on the floor with no swing, stance or stun (DEC-0055 §2);
# 7. the light's, the charged's and the parry's presses into the slot, in that order, then the
#    movement's (Movement.take_presses), so the parry beats the charged, which beats the light, and
#    any movement key beats the three on one tick (DEC-0051 §4; DEC-0056 §6); the move or the parry
#    in the slot fires standing on the floor, from rest or from the guard, which drops, with the bar
#    able to pay: the light pays on its fire, the charged needs its cost and pays nothing yet, the
#    parry pays on its fire;
# 8. the swing's direction follows the camera on every tick of the windup;
# 9. on an active tick, the slice of that tick, flat or vertical, against every other fighter of the
#    photo, in name order, until the swing has its one contact (Q-26).
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
	_advance(next, combat, config, tick)
	_end_stance(next, combat, tick)
	_end_stun(next, input, combat, tick)
	_feint(next, input, combat, config, tick)
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


## Whether the fighter is in a stun, a hit's, a block's or a parried one's (combate.md, "O tranco e
## o corpo"; "O corpo na postura, na finta e em quem foi aparado"): no input of movement nor of
## action, the presses wait in the slot.
static func stunned(state: FighterState) -> bool:
	return (
		state.action == FighterState.Action.HITSTUN or state.action == FighterState.Action.BLOCKSTUN
		or state.action == FighterState.Action.PARRIED
	)


## Whether the fighter is in the parry's stance or the feint's recovery: the commands wait in the
## slot and the body walks slowly, as in the guard (combate.md, "O corpo na postura, na finta e em
## quem foi aparado").
static func in_stance(state: FighterState) -> bool:
	return state.action == FighterState.Action.PARRY or state.action == FighterState.Action.FEINT


## Whether a standing body walks slowly (movimento.md, "Chão": "Andar devagar"): with the guard, in
## the parry's stance or the feint, and through the three phases of the charged (combate.md, "A
## direção e o corpo"; DEC-0052). The movement reads it with no CombatConfig, so the charged is
## known by its ID, the one the state carries.
static func walks_slowly(state: FighterState) -> bool:
	if state.action == FighterState.Action.BLOCK or in_stance(state):
		return true
	return swinging(state) and state.action_move == FighterCommand.CHARGED_ATTACK


## Whether tick falls in the parry's window of a stance in progress: its first parry_window_ticks.
static func in_parry_window(state: FighterState, tick: int, combat: CombatConfig) -> bool:
	if state.action != FighterState.Action.PARRY:
		return false
	var into := tick - state.action_since
	return into >= 0 and into < combat.parry_window_ticks


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
# fighter of the photo (combate.md, "O leve no tick": "Quem levou"), in name order, each parried,
# blocked, armored or taken, in that order (DEC-0056 §3 and §4). Two attackers on the same tick
# both count: a block leaves the guard up for the next, a hit leaves none.
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
		if _parries(next, feet, entry.feet, attack, combat, contact):
			next.parry_tick = contact
		elif _blocks(next, feet, entry.feet, attack, combat, config, contact):
			_block(next, attack, config, contact)
		elif _armored(next, attack, combat):
			_armor(next, attack, contact)
		else:
			_hit(next, attack, contact)


# The parry holds when the move can be parried, the stance was up on the contact tick with the
# contact in its window, P to P + parry_window_ticks - 1, and the attacker in the front half,
# measured as the guard's (combate.md, "O parry certo"; DEC-0054 §2). Parried, the defender only
# stamps the contact: no damage, no stun, no freeze, and the stance ends parry_recovery_ticks after
# it (_end_stance).
static func _parries(
	next: FighterState,
	feet: Vector3,
	attacker_feet: Vector3,
	attack: AttackConfig,
	combat: CombatConfig,
	contact: int,
) -> bool:
	if not attack.parryable or not in_parry_window(next, contact, combat):
		return false
	return _in_front(next, feet, attacker_feet, combat)


# The armor (combate.md, "A armadura do carregado"; DEC-0056 §3): a move that does not break armor
# against the windup of a move with armor, on the state the contact tick left.
static func _armored(next: FighterState, attack: AttackConfig, combat: CombatConfig) -> bool:
	if attack.breaks_armor or next.action != FighterState.Action.WINDUP:
		return false
	if not combat.attacks.has(next.action_move):
		return false
	var own: AttackConfig = combat.attacks[next.action_move]
	return own.armor


# The armored hit: the damage, never below 0, and the hurt stamp, the flash's key and what the
# attacker reads; no stun and no freeze, so the windup goes on and comes down on its usual tick.
static func _armor(next: FighterState, attack: AttackConfig, contact: int) -> void:
	next.health = maxi(0, next.health - attack.damage)
	next.hurt_tick = contact


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
	if not up or not _in_front(next, feet, attacker_feet, combat):
		return false
	return Stamina.at(next, config, contact) >= attack.block_stamina_cost


# The attacker's feet within the half angle of where the body looked, on the floor's plane, from
# axis to axis (DEC-0054 §2): the guard's front, and the parry's (DEC-0056 §4).
static func _in_front(
	next: FighterState,
	feet: Vector3,
	attacker_feet: Vector3,
	combat: CombatConfig,
) -> bool:
	var toward := Vector3(attacker_feet.x - feet.x, 0.0, attacker_feet.z - feet.z)
	# On the same axis there is no side to come from: the front covers it.
	if toward.is_zero_approx():
		return true
	return Blade.direction(next.facing_yaw).angle_to(toward) <= combat.guard_half_angle


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
# so this photo, two ticks after it, is the first to show the result. A parry ends my swing: I am
# PARRIED from this tick, frozen alone for parried_hitstop_ticks, and act again at the contact plus
# the parried stun plus that hitstop (DEC-0056 §4). A hit, the armor's included, or a block freezes
# me from this tick for its hitstop, and moves my swing's clock forward as much, so my recovery
# ends that much later and the advantage stays; a contact with no result freezes nobody. Only the
# swing that made the contact freezes: a fighter whose swing a hit ended is frozen as a target
# already.
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
	var contact := next.contact_tick
	# Only a move that can be parried reads the stamp: a light that touched the same parrier on the
	# same tick learns its own result, the hit (combate.md, "O leve não se apara").
	if attack.parryable and target.state.parry_tick == contact:
		next.action = FighterState.Action.PARRIED
		next.action_since = tick
		next.action_move = &""
		next.parried_tick = contact
		next.stun_until_tick = contact + combat.parried_stun_ticks + combat.parried_hitstop_ticks
		next.frozen_until_tick = tick + combat.parried_hitstop_ticks - 1
		return
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
# swing, and changes nothing else (DEC-0055 §5). The light first, then the charged, then the parry,
# then the movement's, each over the one before: on one tick the last written wins (DEC-0056 §6).
static func _write_presses(
	next: FighterState,
	input: TickInput,
	config: MovementConfig,
	tick: int,
) -> void:
	if input.light_attack:
		next.buffered_command = FighterCommand.LIGHT_ATTACK
		next.buffered_tick = tick
	if input.charged_attack:
		next.buffered_command = FighterCommand.CHARGED_ATTACK
		next.buffered_tick = tick
	if input.parry:
		next.buffered_command = FighterCommand.PARRY
		next.buffered_tick = tick
	Movement.take_presses(next, input, tick, config)


# Step 4: each phase of a swing lasts its ticks from the tick it began; a phase of 0 ticks passes
# at once. Fired at F, the light is WINDUP from F, ACTIVE from F + 15, RECOVERY from F + 21 and NONE
# from F + 33 at 60 ticks (combate.md, "O leve no tick": "As fases"; DEC-0052), each later by the
# hitstop when the swing's contact had a result (DEC-0055 §5). The charged is WINDUP from F, ACTIVE
# from F + 42, RECOVERY from F + 49 and NONE from F + 76, and pays its cost on the first active
# tick, the release (combate.md, "As fases do carregado"; DEC-0056 §2).
static func _advance(
	next: FighterState,
	combat: CombatConfig,
	config: MovementConfig,
	tick: int,
) -> void:
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
				if attack.pays_on_release:
					Stamina.spend(next, config, began, attack.stamina_cost)
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


# Step 4, the end of the parry's stance and of the feint (combate.md, "O carregado, o parry e a
# finta no tick"): a stance that parried a charged ends parry_recovery_ticks after the contact, one
# that parried nothing after its window and parry_whiff_recovery_ticks more, P + 39 at 60; the
# feint ends feint_recovery_ticks after it began. The guard, held, rises from here (step 6).
static func _end_stance(next: FighterState, combat: CombatConfig, tick: int) -> void:
	var end := FighterState.NEVER
	if next.action == FighterState.Action.PARRY:
		end = next.action_since + combat.parry_window_ticks + combat.parry_whiff_recovery_ticks
		if next.parry_tick >= next.action_since:
			end = next.parry_tick + combat.parry_recovery_ticks
	elif next.action == FighterState.Action.FEINT:
		end = next.action_since + combat.feint_recovery_ticks
	else:
		return
	if tick < end:
		return
	next.action = FighterState.Action.NONE
	next.action_since = end


# Step 4, the stun's end: on stun_until_tick the fighter acts again (combate.md, "O tranco no
# tick"). After a blockstun with the button still held, the guard is already up, as if it had
# risen for its ticks; otherwise, after a hit or a parry, the action is NONE, and the guard, held,
# rises from here.
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


# Step 5, the feint (combate.md, "A finta"; DEC-0056 §5): the guard button going down in the
# windup of a move that can be feinted, from the tick after its fire to feint_until_ticks into it,
# with the bar able to pay, cuts the windup: FEINT from this tick, the feint's cost paid now, and
# the move's own cost, paid on release, never. On the fire tick itself the windup is not there yet
# when this runs: the press fires later in the step, so a guard press with it does not feint. Only
# the press counts: a guard held since before the windup never feints.
static func _feint(
	next: FighterState,
	input: TickInput,
	combat: CombatConfig,
	config: MovementConfig,
	tick: int,
) -> void:
	if not input.guard_press or next.action != FighterState.Action.WINDUP:
		return
	if not combat.attacks.has(next.action_move):
		return
	var attack: AttackConfig = combat.attacks[next.action_move]
	var into := tick - next.action_since
	if not attack.feintable or into < 1 or into > combat.feint_until_ticks:
		return
	if Stamina.at(next, config, tick) < combat.feint_stamina_cost:
		return
	next.action = FighterState.Action.FEINT
	next.action_since = tick
	next.action_move = &""
	Stamina.spend(next, config, tick, combat.feint_stamina_cost)


# Step 6, the guard (DEC-0055 §2; combate.md, "A guarda andando"): held, standing on a floor of its
# own with no cable in the air, and with no swing, stance nor stun, the action is BLOCK from the
# tick the rise began; let go, or off the floor, it drops on that tick.
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


# Step 7: the slot of the buffer, shared with the movement (DEC-0039; DEC-0051 §4; DEC-0056 §6).
# The light, the charged and the parry are written in that order, then the movement's presses over
# them, and the slot's expiry; a move or the parry fires only from the slot, so a press refused now
# waits there for its 150 ms.
static func _take_press(
	next: FighterState,
	input: TickInput,
	combat: CombatConfig,
	config: MovementConfig,
	tick: int,
) -> void:
	_write_presses(next, input, config, tick)
	var command := next.buffered_command
	if command == FighterCommand.PARRY:
		if not _can_start(next, combat.parry_stamina_cost, config, tick):
			return
		next.action = FighterState.Action.PARRY
		next.action_since = tick
		next.action_move = &""
		Stamina.spend(next, config, tick, combat.parry_stamina_cost)
	elif command == FighterCommand.LIGHT_ATTACK or command == FighterCommand.CHARGED_ATTACK:
		if not combat.attacks.has(command):
			return
		var attack: AttackConfig = combat.attacks[command]
		if not _can_start(next, attack.stamina_cost, config, tick):
			return
		next.action = FighterState.Action.WINDUP
		next.action_since = tick
		next.action_move = command
		if not attack.pays_on_release:
			Stamina.spend(next, config, tick, attack.stamina_cost)
	else:
		return
	next.buffered_command = FighterCommand.NONE
	next.buffered_tick = FighterState.NEVER


# Standing on a floor of its own (GROUND, off any head; Movement.stands), with no swing, stance nor
# stun in progress, the guard being no obstacle, and the bar holding cost (combate.md, "O leve no
# tick": "Quando o leve sai"; "Quando o carregado sai"; "Quando o parry sai"; DEC-0055 §2: "O leve
# sai da guarda"). The charged needs its cost on the bar to begin, though it pays on release.
static func _can_start(next: FighterState, cost: float, config: MovementConfig, tick: int) -> bool:
	if next.mode != FighterState.Mode.GROUND or not Movement.stands(next):
		return false
	var free := next.action == FighterState.Action.NONE
	if not free and next.action != FighterState.Action.BLOCK:
		return false
	return Stamina.at(next, config, tick) >= cost


# Step 9: the slice of the k-th active tick, k from 1, against the others of the photo in name
# order; the first it touches takes the swing's one contact, stamped on this state. A vertical cut
# tests its slice in the plane of the swing's direction (Blade.cut_touches).
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
		var touched := false
		if attack.vertical_cut:
			touched = Blade.cut_touches(
				feet,
				next.action_yaw,
				slice.x,
				slice.y,
				entry.feet,
				combat,
				config,
			)
		else:
			touched = Blade.slice_touches(
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
