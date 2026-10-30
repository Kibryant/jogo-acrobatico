# TASK-12.1 (visual-e-audio.md, "O leve na tela"; DEC-0030 §4): the block sword's pose is a
# function of the displayed state and tick, never of a clock of its own. In the active it lies on
# the very blade the rule tests (Blade.segment), at the end of the tick's slice, and wears the
# vermilion; at rest and in the windup it wears no colour; the windup takes it back and the
# recovery brings it to rest. The same state and tick always give the same pose, as after a
# rollback. No physics and no tick loop: the pose is a pure function. TASK-12.3 adds the charged,
# the parry, the feint, the parried one and the armor (visual-e-audio.md, "O carregado, o parry e a
# finta na tela").
extends GdUnitTestSuite

const CombatRig := preload("res://test/core/fighter/combat_rig.gd")

const LIGHT := &"light_attack"
const SINCE := 2000 # any tick: the pose reads the gap to the stamp
const HAIR := 1e-4 # m: the pose's floats against the rule's


func _combat() -> CombatConfig:
	return CombatRig.load_combat(60)


func _swinging(action: FighterState.Action, yaw: float) -> FighterState:
	var state := FighterState.new()
	state.action = action
	state.action_since = SINCE
	state.action_move = LIGHT
	state.action_yaw = yaw
	state.facing_yaw = yaw
	return state


# In the active, the k-th tick's pose is the rule's blade at the end of the k-th slice: the hand
# and the tip where Blade.segment puts them, from the feet, along the swing's direction.
func test_in_the_active_the_sword_is_the_rules_blade_at_the_end_of_the_ticks_slice(
	yaw: float,
	_test_parameters := [[0.0], [1.2], [-2.5]],
) -> void:
	var combat := _combat()
	var light: AttackConfig = combat.attacks[LIGHT]
	var state := _swinging(FighterState.Action.ACTIVE, yaw)
	for k: int in range(1, light.active_ticks + 1):
		var pose := Sword.pose(state, SINCE + k - 1, combat)
		var theta := Blade.slice_of(light, k).y
		var blade := Blade.segment(Vector3.ZERO, yaw, theta, combat)
		var where := "tick %d of the active at yaw %.2f" % [k, yaw]
		assert_vector(pose.origin).override_failure_message(where) \
				.is_equal_approx(blade[0], Vector3.ONE * HAIR)
		assert_vector(Sword.tip_of(pose, combat)).override_failure_message(where) \
				.is_equal_approx(blade[1], Vector3.ONE * HAIR)
	assert_bool(Sword.lit(state)).is_true()


# Out of the active the blade wears no colour; the windup's last tick holds it back, behind the
# shoulder; the recovery's last tick is back at rest; and the rest's tip stays above the floor.
func test_the_windup_takes_it_back_and_the_recovery_brings_it_to_rest() -> void:
	var combat := _combat()
	var light: AttackConfig = combat.attacks[LIGHT]
	var rest := Sword.pose(FighterState.new(), SINCE, combat)
	assert_bool(Sword.lit(FighterState.new())).is_false()
	assert_float(Sword.tip_of(rest, combat).y).is_greater(0.0)
	var windup := _swinging(FighterState.Action.WINDUP, 0.0)
	assert_bool(Sword.lit(windup)).is_false()
	var back := Sword.pose(windup, SINCE + light.windup_ticks - 1, combat)
	# Yaw 0 looks down -Z: the tip behind the body is at +Z.
	assert_float(Sword.tip_of(back, combat).z).is_greater(0.0)
	var recovery := _swinging(FighterState.Action.RECOVERY, 0.0)
	assert_bool(Sword.lit(recovery)).is_false()
	var done := Sword.pose(recovery, SINCE + light.recovery_ticks - 1, combat)
	assert_vector(done.origin).is_equal_approx(rest.origin, Vector3.ONE * HAIR)
	assert_vector(Sword.tip_of(done, combat)).is_equal_approx(
		Sword.tip_of(rest, combat),
		Vector3.ONE * HAIR,
	)


# The same state and tick give the same pose: nothing of the sword is kept between two calls.
func test_the_pose_is_a_function_of_the_state_and_the_tick() -> void:
	var combat := _combat()
	var state := _swinging(FighterState.Action.WINDUP, 0.7)
	var first := Sword.pose(state, SINCE + 5, combat)
	Sword.pose(state, SINCE + 20, combat)
	assert_bool(Sword.pose(state, SINCE + 5, combat).is_equal_approx(first)).is_true()


const TOKENS_V0 := "res://data/tokens_v0.tres"


func _tokens() -> TokensData:
	var resource: Resource = load(TOKENS_V0)
	assert(resource is TokensData, "%s must load as a TokensData" % TOKENS_V0)
	return resource as TokensData


# TASK-12.2 (visual-e-audio.md, "A guarda e o tranco na tela"): the guard's token names the upright
# pose: from the rest, the blade rises over the guard's ticks to nearly vertical in front of the
# body, its tip above the hand and ahead of the feet, and stays there in the blockstun; it wears no
# colour, the token's none.
func test_the_guard_raises_the_blade_upright_in_front_without_colour() -> void:
	var combat := _combat()
	var tokens := _tokens()
	var guard := FighterState.new()
	guard.action = FighterState.Action.BLOCK
	guard.action_since = SINCE
	assert_str(String(Sword.pose_name(guard, tokens))).is_equal(String(tokens.guard.pose))
	var rising := Sword.pose(guard, SINCE, combat, tokens)
	var up := Sword.pose(guard, SINCE + combat.guard_raise_ticks - 1, combat, tokens)
	var tip := Sword.tip_of(up, combat)
	assert_float(tip.y - up.origin.y).is_greater(0.9 * combat.blade_length)
	assert_float(tip.z).override_failure_message("the guard is not in front").is_less(0.0)
	assert_float(Sword.tip_of(rising, combat).y).is_less(tip.y)
	var stunned := guard.copy()
	stunned.action = FighterState.Action.BLOCKSTUN
	assert_bool(Sword.pose(stunned, SINCE, combat, tokens).is_equal_approx(up)).is_true()
	assert_float(Sword.blade_colour(guard, tokens).a).is_equal(0.0)


# The active wears the token's vermilion; the reaction's white is the body's flash, never the
# blade's, and its pose throws the blade down.
func test_the_tokens_paint_the_active_and_leave_the_reaction_to_the_body() -> void:
	var combat := _combat()
	var tokens := _tokens()
	var active := _swinging(FighterState.Action.ACTIVE, 0.0)
	assert_bool(Sword.blade_colour(active, tokens).is_equal_approx(Sword.ACTIVE_COLOUR)).is_true()
	var hit := FighterState.new()
	hit.action = FighterState.Action.HITSTUN
	hit.action_since = SINCE
	assert_float(Sword.blade_colour(hit, tokens).a).is_equal(0.0)
	assert_str(String(Sword.pose_name(hit, tokens))).is_equal(String(tokens.reaction.pose))
	var recoil := Sword.pose(hit, SINCE, combat, tokens)
	assert_float(Sword.tip_of(recoil, combat).y).is_less(recoil.origin.y)


# On a frozen tick of the hitstop the sword holds the impact's pose (Combat.posed_tick): the
# attacker's clock moved forward by the freeze, and every frozen tick shows the slice of the tick
# before the freeze.
func test_a_frozen_swing_holds_the_pose_of_the_impact() -> void:
	var combat := _combat()
	var state := _swinging(FighterState.Action.ACTIVE, 0.0)
	var before := Sword.pose(state, SINCE + 3, combat)
	var hitstop := 4
	state.action_since = SINCE + hitstop
	state.contact_tick = SINCE + 2
	state.frozen_until_tick = SINCE + 2 + 1 + hitstop
	for tick: int in range(SINCE + 4, state.frozen_until_tick + 1):
		var frozen := Sword.pose(state, tick, combat)
		assert_bool(frozen.is_equal_approx(before)).override_failure_message("tick %d" % tick) \
				.is_true()


const CHARGED := &"charged_attack"


func _charged(action: FighterState.Action, yaw: float) -> FighterState:
	var state := _swinging(action, yaw)
	state.action_move = CHARGED
	return state


# TASK-12.3 (visual-e-audio.md, "O carregado, o parry e a finta na tela"): from the windup's first
# tick the charged holds the sword above the head, its tip above the capsule's 1,8 m, in the token's
# sky blue; the pose does not wait for the windup to fill.
func test_the_charged_windup_holds_the_sword_overhead_in_blue_from_its_first_tick() -> void:
	var combat := _combat()
	var tokens := _tokens()
	var charged: AttackConfig = combat.attacks[CHARGED]
	var windup := _charged(FighterState.Action.WINDUP, 0.0)
	assert_str(String(Sword.pose_name(windup, tokens))).is_equal(String(tokens.charged_windup.pose))
	assert_str(String(Sword.pose_name(windup))).is_equal(String(Sword.POSE_OVERHEAD))
	var first := Sword.pose(windup, SINCE, combat, tokens)
	var last := Sword.pose(windup, SINCE + charged.windup_ticks - 1, combat, tokens)
	assert_bool(first.is_equal_approx(last)).override_failure_message("the pose waits").is_true()
	assert_float(Sword.tip_of(first, combat).y).is_greater(1.8)
	assert_float(first.origin.y).is_greater(combat.hand_height)
	var blue := Sword.blade_colour(windup, tokens, SINCE, combat)
	assert_bool(blue.is_equal_approx(tokens.charged_windup.color)).is_true()
	assert_float(blue.a).is_equal(1.0)
	# The light's windup keeps its own pose and no colour.
	var light := _swinging(FighterState.Action.WINDUP, 0.0)
	assert_str(String(Sword.pose_name(light, tokens))).is_equal(String(tokens.light_windup.pose))
	assert_float(Sword.blade_colour(light, tokens, SINCE, combat).a).is_equal(0.0)


# In the charged's active, the k-th tick's pose is the rule's vertical blade at the end of the k-th
# slice (Blade.cut_segment), in vermilion; the recovery starts where the cut ended and its last
# tick is back at rest.
func test_the_charged_active_is_the_rules_vertical_blade_and_the_recovery_rests(
	yaw: float,
	_test_parameters := [[0.0], [1.2], [-2.5]],
) -> void:
	var combat := _combat()
	var tokens := _tokens()
	var charged: AttackConfig = combat.attacks[CHARGED]
	var state := _charged(FighterState.Action.ACTIVE, yaw)
	for k: int in range(1, charged.active_ticks + 1):
		var pose := Sword.pose(state, SINCE + k - 1, combat, tokens)
		var phi := Blade.slice_of(charged, k).y
		var blade := Blade.cut_segment(Vector3.ZERO, yaw, phi, combat)
		var where := "tick %d of the cut at yaw %.2f" % [k, yaw]
		assert_vector(pose.origin).override_failure_message(where) \
				.is_equal_approx(blade[0], Vector3.ONE * HAIR)
		assert_vector(Sword.tip_of(pose, combat)).override_failure_message(where) \
				.is_equal_approx(blade[1], Vector3.ONE * HAIR)
	var lit := Sword.blade_colour(state, tokens, SINCE, combat)
	assert_bool(lit.is_equal_approx(Sword.ACTIVE_COLOUR)).is_true()
	var rest := Sword.pose(FighterState.new(), SINCE, combat)
	var recovery := _charged(FighterState.Action.RECOVERY, 0.0)
	var done := Sword.pose(recovery, SINCE + charged.recovery_ticks - 1, combat, tokens)
	assert_vector(done.origin).is_equal_approx(rest.origin, Vector3.ONE * HAIR)
	assert_vector(Sword.tip_of(done, combat)).is_equal_approx(
		Sword.tip_of(rest, combat),
		Vector3.ONE * HAIR,
	)
	var first := Sword.pose(recovery, SINCE, combat, tokens)
	var cut_end := Blade.cut_segment(Vector3.ZERO, 0.0, charged.arc_to, combat)
	assert_float(first.origin.distance_to(cut_end[0])).override_failure_message("a jump") \
			.is_less(0.1)


# The parry's stance crosses the blade in front of the body, its tip to the left of the hand, in
# yellow only while the window lasts: on its last tick yellow, on the next the steel, the pose kept.
func test_the_parry_stance_crosses_the_blade_in_front_yellow_only_in_the_window() -> void:
	var combat := _combat()
	var tokens := _tokens()
	var stance := FighterState.new()
	stance.action = FighterState.Action.PARRY
	stance.action_since = SINCE
	var last := SINCE + combat.parry_window_ticks - 1
	assert_str(String(Sword.pose_name(stance, tokens, SINCE, combat))).is_equal(
		String(tokens.parry.pose)
	)
	var yellow := Sword.blade_colour(stance, tokens, last, combat)
	assert_bool(yellow.is_equal_approx(tokens.parry.color)).is_true()
	assert_float(Sword.blade_colour(stance, tokens, last + 1, combat).a).is_equal(0.0)
	var inside := Sword.pose(stance, last, combat, tokens)
	var after := Sword.pose(stance, last + 1, combat, tokens)
	assert_bool(inside.is_equal_approx(after)).override_failure_message("the pose moved").is_true()
	# Yaw 0 looks down -Z: in front is -Z, and the left is -X.
	var tip := Sword.tip_of(inside, combat)
	assert_float(inside.origin.z).override_failure_message("the hand is not in front").is_less(0.0)
	assert_float(tip.x).override_failure_message("the blade does not cross").is_less(
		inside.origin.x - 0.5 * combat.blade_length
	)


# The feint snaps the pose from overhead back to rest in SNAP_TICKS, a jolt; whoever was parried
# holds the blade thrown up and back, its tip behind and above the hand, through the stun.
func test_the_feint_snaps_to_rest_and_the_parried_blade_is_thrown_up_and_back() -> void:
	var combat := _combat()
	var tokens := _tokens()
	var rest := Sword.pose(FighterState.new(), SINCE, combat)
	var feint := FighterState.new()
	feint.action = FighterState.Action.FEINT
	feint.action_since = SINCE
	assert_str(String(Sword.pose_name(feint, tokens))).is_equal(String(tokens.feint.pose))
	var snapped := Sword.pose(feint, SINCE + Sword.SNAP_TICKS - 1, combat, tokens)
	assert_bool(snapped.is_equal_approx(rest)).override_failure_message("no snap to rest").is_true()
	var parried := FighterState.new()
	parried.action = FighterState.Action.PARRIED
	parried.action_since = SINCE
	assert_str(String(Sword.pose_name(parried, tokens))).is_equal(String(tokens.parried.pose))
	var thrown := Sword.pose(parried, SINCE, combat, tokens)
	var later := Sword.pose(parried, SINCE + 40, combat, tokens)
	assert_bool(thrown.is_equal_approx(later)).override_failure_message("not held").is_true()
	var tip := Sword.tip_of(thrown, combat)
	assert_float(tip.y).is_greater(thrown.origin.y)
	assert_float(tip.z).override_failure_message("the blade is not thrown back").is_greater(0.0)


# The armor (visual-e-audio.md, "Armadura": "só um tremor"): a light that meets the charged's
# windup, first shown the tick after its contact, makes the overhead sword jolt to one side and
# the other for TREMOR_TICKS, with no recoil: the hand's height and the blade's turn stay; then it
# is still again. The same state and tick give the same jolt, as after a rollback.
func test_the_armor_makes_the_overhead_sword_tremble_without_recoil() -> void:
	var combat := _combat()
	var tokens := _tokens()
	var windup := _charged(FighterState.Action.WINDUP, 0.0)
	var still := Sword.pose(windup, SINCE + 10, combat, tokens)
	var armored := windup.copy()
	armored.hurt_tick = SINCE + 4
	var shown := armored.hurt_tick + 1
	assert_bool(Sword.pose(armored, shown - 1, combat, tokens).is_equal_approx(still)).is_true()
	var first := Sword.pose(armored, shown, combat, tokens)
	var second := Sword.pose(armored, shown + 1, combat, tokens)
	assert_bool(first.is_equal_approx(still)).override_failure_message("no tremor").is_false()
	var one_way := first.origin - still.origin
	var other_way := second.origin - still.origin
	assert_float(one_way.dot(other_way)).override_failure_message("not to and fro").is_less(0.0)
	assert_float(first.origin.y).is_equal_approx(still.origin.y, HAIR)
	assert_bool(first.basis.is_equal_approx(still.basis)).is_true()
	var over := Sword.pose(armored, shown + Sword.TREMOR_TICKS, combat, tokens)
	assert_bool(over.is_equal_approx(still)).override_failure_message("still trembling").is_true()
	assert_bool(Sword.pose(armored, shown, combat, tokens).is_equal_approx(first)).is_true()
	# A hurt stamp from before this windup trembles nothing.
	var old := windup.copy()
	old.hurt_tick = SINCE - 3
	assert_bool(Sword.pose(old, SINCE, combat, tokens).is_equal_approx(still)).is_true()
