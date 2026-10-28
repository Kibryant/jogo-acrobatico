# TASK-12.1 (visual-e-audio.md, "O leve na tela"; DEC-0030 §4): the block sword's pose is a
# function of the displayed state and tick, never of a clock of its own. In the active it lies on
# the very blade the rule tests (Blade.segment), at the end of the tick's slice, and wears the
# vermilion; at rest and in the windup it wears no colour; the windup takes it back and the
# recovery brings it to rest. The same state and tick always give the same pose, as after a
# rollback. No physics and no tick loop: the pose is a pure function.
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
