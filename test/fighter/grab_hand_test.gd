# TASK-12.4 (visual-e-audio.md, "A quebra na cápsula"; F-211; F-212): the guard break on the
# capsule. Its hand is a vermilion sphere whose place is a pure function of the displayed state and
# tick, as the sword's pose is, so a rollback never moves it twice: on the body's axis at 1,3 m from
# the windup's first tick; in the active out along the swing, 0,2 m a tick up to 1,2 m, at the far
# end of the rule's own hand (Blade.hand_slice, Blade.hand_segment); back to the axis through the
# recovery, and gone at its end; on the other's chest, its axis at 1,3 m, while whoever grabbed
# holds. Both fighters glow vermilion, pulsing, while held, and the stun after the hold does not
# glow. The real Match runs with netfox's ticks advanced by hand (test/support/netfox_ticks.gd;
# DEC-0027 §3).
extends GdUnitTestSuite

const CombatRig := preload("res://test/core/fighter/combat_rig.gd")
const GrabRig := preload("res://test/core/fighter/grab_rig.gd")
const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")
const TOKENS_V0 := "res://data/tokens_v0.tres"

const GUARD_BREAK := &"guard_break"
const LIGHT := &"light_attack"
const SINCE := 2000 # any tick: the hand reads the gap to the stamp
const HAIR := 1e-4 # m: the hand's floats against the rule's
## visual-e-audio.md, "A quebra na cápsula": "uma esfera de 0,1 m de raio", "no eixo do corpo, a
## 1,3 m de altura", "0,2 m por tick, até 1,2 m".
const RADIUS_M := 0.1
const HAND_HEIGHT_M := 1.3
const STEP_M := 0.2
const REACH_M := 1.2
## combate.md, "O agarrão" and "O tech": held from the contact + 1 up to the contact + 23, the hold
## ending on the contact + 24; without the tech, unable to act up to the contact + 75.
const HOLD_END := 24
const VICTIM_FREE := 76
## The flat floor west of the platform (attacking_dummy_test.gd): the other fighter, and the
## grabber 1,05 m in front of it, down -Z, whose hand first touches it on its 4th active tick
## (combate.md, "A mão"): the contact comes 21 + 3 ticks after the press.
const OTHER_FEET := Vector3(-6.0, 0.0, 6.0)
const GRABBER_FEET := Vector3(-6.0, 0.0, 4.95)
const GRAB_CONTACT_AFTER := 24
## movimento.md, "Câmera": the shoulder; combate.md, "A lâmina e o contato": "Convergência: 1,2 na
## quebra".
const SHOULDER_M := 0.8
const HAND_CONVERGENCE_M := 1.2


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


func _combat() -> CombatConfig:
	return CombatRig.load_combat(60)


func _tokens() -> TokensData:
	var resource: Resource = load(TOKENS_V0)
	assert(resource is TokensData, "%s must load as a TokensData" % TOKENS_V0)
	return resource as TokensData


func _breaking(action: FighterState.Action, yaw: float) -> FighterState:
	var state := FighterState.new()
	state.action = action
	state.action_since = SINCE
	state.action_move = GUARD_BREAK
	state.action_yaw = yaw
	state.facing_yaw = yaw
	return state


# The hand's distance from the body's axis, on the floor's plane.
func _out(place: Vector3) -> float:
	return Vector2(place.x, place.z).length()


# In the windup the hand shows on the body's axis, 1,3 m above the feet, from the windup's first
# tick to its last, whatever the swing's direction: it does not wait for the windup to fill.
func test_in_the_windup_the_hand_shows_on_the_axis_at_1_3_m_from_its_first_tick() -> void:
	var combat := _combat()
	var guard_break: AttackConfig = combat.attacks[GUARD_BREAK]
	assert_float(combat.hand_height).is_equal_approx(HAND_HEIGHT_M, HAIR)
	var windup := _breaking(FighterState.Action.WINDUP, 0.7)
	assert_bool(GrabHand.shows(windup, combat)).is_true()
	for into: int in guard_break.windup_ticks:
		var place := GrabHand.place(windup, SINCE + into, combat, Vector3.ZERO)
		assert_vector(place).override_failure_message("tick %d of the windup" % into) \
				.is_equal_approx(Vector3.UP * HAND_HEIGHT_M, Vector3.ONE * HAIR)


# In the active the k-th tick's hand is the rule's hand at the end of the k-th slice, the very point
# the touch tests (Blade.hand_segment over Blade.hand_slice): along the swing at 1,3 m, 0,2 m a tick
# at 60, 1,2 m on the last tick.
func test_in_the_active_the_hand_is_the_rules_hand_at_the_end_of_the_ticks_slice(
	yaw: float,
	_test_parameters := [[0.0], [1.2], [-2.5]],
) -> void:
	var combat := _combat()
	var guard_break: AttackConfig = combat.attacks[GUARD_BREAK]
	var active := _breaking(FighterState.Action.ACTIVE, yaw)
	assert_bool(GrabHand.shows(active, combat)).is_true()
	for k: int in range(1, guard_break.active_ticks + 1):
		var place := GrabHand.place(active, SINCE + k - 1, combat, Vector3.ZERO)
		var reach := Blade.hand_slice(guard_break, k).y
		var rule := Blade.hand_segment(Vector3.ZERO, yaw, 0.0, reach, combat)
		var where := "tick %d of the active at yaw %.2f" % [k, yaw]
		assert_vector(place).override_failure_message(where) \
				.is_equal_approx(rule[1], Vector3.ONE * HAIR)
		assert_float(_out(place)).override_failure_message(where).is_equal_approx(k * STEP_M, HAIR)
		var along := Blade.direction(yaw) * k * STEP_M + Vector3.UP * HAND_HEIGHT_M
		assert_vector(place).override_failure_message(where) \
				.is_equal_approx(along, Vector3.ONE * HAIR)
	var last := GrabHand.place(active, SINCE + guard_break.active_ticks - 1, combat, Vector3.ZERO)
	assert_float(_out(last)).is_equal_approx(REACH_M, HAIR)


# The recovery brings the hand back along the swing's line, nearer the body on every tick, to the
# axis on its last tick; once the recovery is over the hand is gone.
func test_the_recovery_brings_the_hand_back_to_the_axis_and_it_goes_at_its_end(
	yaw: float,
	_test_parameters := [[0.0], [-2.5]],
) -> void:
	var combat := _combat()
	var guard_break: AttackConfig = combat.attacks[GUARD_BREAK]
	var recovery := _breaking(FighterState.Action.RECOVERY, yaw)
	assert_bool(GrabHand.shows(recovery, combat)).is_true()
	var before := REACH_M
	for into: int in guard_break.recovery_ticks:
		var place := GrabHand.place(recovery, SINCE + into, combat, Vector3.ZERO)
		var out := _out(place)
		var where := "tick %d of the recovery at yaw %.2f: %.3f m out" % [into, yaw, out]
		assert_float(out).override_failure_message(where).is_less(before)
		var on_line := Blade.direction(yaw) * out + Vector3.UP * HAND_HEIGHT_M
		assert_vector(place).override_failure_message(where) \
				.is_equal_approx(on_line, Vector3.ONE * HAIR)
		before = out
	var done := GrabHand.place(
		recovery,
		SINCE + guard_break.recovery_ticks - 1,
		combat,
		Vector3.ZERO,
	)
	assert_vector(done).is_equal_approx(Vector3.UP * HAND_HEIGHT_M, Vector3.ONE * HAIR)
	var standing := FighterState.new()
	standing.action_since = SINCE + guard_break.recovery_ticks
	assert_bool(GrabHand.shows(standing, combat)).override_failure_message("the hand stays") \
			.is_false()


# Whoever grabbed holds the hand on the other's chest, the other's axis at 1,3 m, on every tick of
# the hold, wherever the other stands.
func test_whoever_grabbed_holds_the_hand_on_the_others_chest() -> void:
	var combat := _combat()
	var holding := FighterState.new()
	holding.action = FighterState.Action.GRABBING
	holding.action_since = SINCE
	holding.action_move = GUARD_BREAK
	assert_bool(GrabHand.shows(holding, combat)).is_true()
	for to_other: Vector3 in [Vector3(0.0, 0.0, -1.05), Vector3(0.6, 0.2, 0.9)]:
		for into: int in HOLD_END:
			var place := GrabHand.place(holding, SINCE + into, combat, to_other)
			assert_vector(place).override_failure_message("tick %d, %s" % [into, to_other]) \
					.is_equal_approx(to_other + Vector3.UP * HAND_HEIGHT_M, Vector3.ONE * HAIR)


# No other state shows the hand: standing, every phase of a light, whoever was grabbed, the hit
# reaction.
func test_no_hand_out_of_the_guard_break_and_the_hold() -> void:
	var combat := _combat()
	var states: Array[FighterState] = [FighterState.new()]
	for action: FighterState.Action in [
		FighterState.Action.WINDUP,
		FighterState.Action.ACTIVE,
		FighterState.Action.RECOVERY,
	]:
		var light := _breaking(action, 0.0)
		light.action_move = LIGHT
		states.append(light)
	for action: FighterState.Action in [FighterState.Action.GRABBED, FighterState.Action.HITSTUN]:
		var other := FighterState.new()
		other.action = action
		other.action_since = SINCE
		states.append(other)
	for state: FighterState in states:
		var where := "%s of %s" % [FighterState.Action.keys()[state.action], state.action_move]
		assert_bool(GrabHand.shows(state, combat)).override_failure_message(where).is_false()


# Every armed fighter carries its hand: a sphere of 0,1 m in the guard break windup token's
# vermilion, hidden at rest, and placed by its state when it shows.
func test_an_armed_fighter_carries_a_vermilion_hand_that_its_state_places() -> void:
	var game_match := await _match()
	var fighter := game_match.fighter_at(Match.PLAYER_SLOT)
	var hand := fighter.hand
	assert_object(hand).override_failure_message("no hand").is_not_null()
	assert(hand.mesh is SphereMesh, "the hand is a sphere")
	var sphere := hand.mesh as SphereMesh
	assert_float(sphere.radius).is_equal_approx(RADIUS_M, HAIR)
	assert_float(sphere.height).is_equal_approx(2.0 * RADIUS_M, HAIR)
	assert_bool(hand.colour().is_equal_approx(_tokens().guard_break_windup.color)).is_true()
	assert_bool(hand.colour().is_equal_approx(Sword.ACTIVE_COLOUR)).is_true()
	hand.show_hand(fighter.state, SINCE, Vector3.ZERO)
	assert_bool(hand.visible).override_failure_message("a hand at rest").is_false()
	var active := _breaking(FighterState.Action.ACTIVE, 0.0)
	hand.show_hand(active, SINCE + 2, Vector3.ZERO)
	assert_bool(hand.visible).is_true()
	var expected := GrabHand.place(active, SINCE + 2, game_match.combat, Vector3.ZERO)
	assert_vector(hand.position).is_equal_approx(expected, Vector3.ONE * HAIR)


# The glow (visual-e-audio.md, "A quebra na cápsula": "os dois lutadores acendem em vermelhão,
# pulsando, enquanto estão presos"): whoever grabbed glows while GRABBING, whoever was grabbed from
# the contact + 1 to the contact + 23, the hold; from the hold's end the stun, still GRABBED, does
# not glow. On every tick both glow alike, and the light rises and falls over the hold.
func test_the_glow_lights_both_fighters_only_while_held_and_pulses_together() -> void:
	var combat := _combat()
	var contact := SINCE
	var grabber := FighterState.new()
	grabber.action = FighterState.Action.GRABBING
	grabber.action_since = contact + 2
	grabber.contact_tick = contact
	var grabbed := FighterState.new()
	grabbed.action = FighterState.Action.GRABBED
	grabbed.action_since = contact + 1
	grabbed.grabbed_tick = contact
	grabbed.stun_until_tick = contact + VICTIM_FREE
	var lowest := INF
	var highest := -INF
	for after: int in range(1, HOLD_END):
		var level := Fighter.glow_level(grabbed, contact + after, combat)
		assert_float(level).override_failure_message("contact + %d: no glow" % after).is_greater(
			0.0
		)
		assert_float(level).is_between(Fighter.GLOW_LOW, Fighter.GLOW_HIGH)
		lowest = minf(lowest, level)
		highest = maxf(highest, level)
		if after >= 2:
			assert_float(Fighter.glow_level(grabber, contact + after, combat)) \
					.override_failure_message("contact + %d: out of step" % after) \
					.is_equal_approx(level, HAIR)
	assert_float(highest - lowest).override_failure_message("the glow does not pulse") \
			.is_greater(0.5 * (Fighter.GLOW_HIGH - Fighter.GLOW_LOW))
	for after: int in range(HOLD_END, VICTIM_FREE):
		assert_float(Fighter.glow_level(grabbed, contact + after, combat)) \
				.override_failure_message("the stun glows on the contact + %d" % after) \
				.is_equal(0.0)
	var others: Array[FighterState] = [
		FighterState.new(),
		_breaking(FighterState.Action.WINDUP, 0.0),
	]
	var hit := FighterState.new()
	hit.action = FighterState.Action.HITSTUN
	hit.action_since = contact
	others.append(hit)
	for other: FighterState in others:
		assert_float(Fighter.glow_level(other, contact + 5, combat)).is_equal(0.0)


# The capsule wears the glow while held and its tone again after the hold; a white flash shows over
# the glow while it lasts.
func test_the_capsule_wears_the_glow_while_held_and_its_tone_after() -> void:
	var game_match := await _match()
	var fighter := game_match.fighter_at(Match.PLAYER_SLOT)
	var contact := SINCE
	fighter.state.action = FighterState.Action.GRABBED
	fighter.state.action_since = contact + 1
	fighter.state.grabbed_tick = contact
	fighter.state.stun_until_tick = contact + VICTIM_FREE
	fighter.show_glow(contact + 3)
	assert_float(fighter.glow_shown()).is_equal_approx(
		Fighter.glow_level(fighter.state, contact + 3, game_match.combat),
		HAIR,
	)
	assert_float(fighter.glow_shown()).is_greater(0.0)
	fighter.show_glow(contact + HOLD_END)
	assert_float(fighter.glow_shown()).is_equal(0.0)
	_assert_wears_its_tone(fighter)
	fighter.flash(10.0)
	fighter.show_glow(contact + 3)
	assert_bool(fighter.flashing()).is_true()
	assert_float(fighter.glow_shown()).override_failure_message("the glow hid the flash") \
			.is_equal(0.0)


# In a real grab, from the tick each side learns it: the grabber's hand rests on the other's chest
# and both capsules glow alike, the other's hand hidden; past the hold the grabber's hand is gone
# and neither glows, though whoever was grabbed is still in its stun.
func test_in_a_real_grab_the_hand_rests_on_the_chest_and_both_glow_through_the_hold() -> void:
	var game_match := await _match(true)
	var grabber := game_match.fighter_at(Match.PLAYER_SLOT)
	var other := game_match.fighter_at(Match.DUMMY_SLOT)
	var press := NetworkTime.tick + 10
	var contact := press + GRAB_CONTACT_AFTER
	var hand := GrabRig.camera_for(PI, SHOULDER_M, HAND_CONVERGENCE_M)
	_play_until(grabber, hand, press, contact + 8)
	await _process_once()
	var held := GrabRig.line(other.state)
	assert_int(GrabRig.grabbed_tick(other.state)).override_failure_message(held) \
			.is_equal(contact)
	assert_int(grabber.state.action).is_equal(FighterState.Action.GRABBING)
	assert_bool(grabber.hand.visible).override_failure_message("no hand on the chest").is_true()
	var chest := other.global_position + Vector3.UP * HAND_HEIGHT_M
	assert_vector(grabber.hand.global_position).is_equal_approx(chest, Vector3.ONE * HAIR)
	assert_bool(other.hand.visible).override_failure_message("the grabbed one's hand").is_false()
	assert_float(grabber.glow_shown()).is_greater(0.0)
	assert_float(other.glow_shown()).is_equal_approx(grabber.glow_shown(), HAIR)
	await get_tree().physics_frame
	_play_until(grabber, hand, press, contact + HOLD_END + 3)
	await _process_once()
	assert_bool(GrabRig.is_grabbed(other.state)).override_failure_message("the stun is over") \
			.is_true()
	assert_int(grabber.state.action).is_not_equal(FighterState.Action.GRABBING)
	assert_bool(grabber.hand.visible).override_failure_message("the hand stayed").is_false()
	assert_float(grabber.glow_shown()).is_equal(0.0)
	assert_float(other.glow_shown()).override_failure_message("the stun glows").is_equal(0.0)
	_assert_wears_its_tone(other)


# A match with the player and the dummy standing, no one attacking, netfox's deferred setup done;
# with close, the player 1,05 m in front of the dummy, on the flat floor.
func _match(close := false) -> Match:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match: Match = auto_free(node)
	add_child(game_match)
	var me := multiplayer.get_unique_id()
	var player := game_match.spawn_fighter(Match.PLAYER_SLOT, me)
	var dummy := game_match.spawn_fighter(Match.DUMMY_SLOT, me)
	if close:
		player.position = GRABBER_FEET
		dummy.position = OTHER_FEET
	await get_tree().process_frame
	await get_tree().physics_frame
	return game_match


# Lets every node run its _process once: the tree emits process_frame before the nodes process,
# so the second one comes after a whole pass.
func _process_once() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


# Runs loops until netfox's clock shows `last`, the grabber aiming along hand and pressing the guard
# break on press.
func _play_until(grabber: Fighter, hand: float, press: int, last: int) -> void:
	while NetworkTime.tick <= last:
		grabber.input.sample_frame(Vector2.ZERO, hand)
		if NetworkTime.tick == press:
			grabber.input.press_guard_break()
		NetfoxTicks.run_loop()


func _assert_wears_its_tone(fighter: Fighter) -> void:
	var material := fighter.body_mesh.material_override
	assert(material is StandardMaterial3D, "the capsule wears a StandardMaterial3D")
	var albedo := (material as StandardMaterial3D).albedo_color
	assert_bool(albedo.is_equal_approx(fighter.tone)) \
			.override_failure_message("%s is not its tone %s" % [albedo, fighter.tone]) \
			.is_true()
