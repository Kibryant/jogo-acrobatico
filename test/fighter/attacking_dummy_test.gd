# TASK-12.2 (partida.md, "O boneco que ataca"): Sozinho's dummy presses a light every 3 s, 180
# ticks at 60, turned toward whoever plays, and only through its input box: it does not walk, and
# its swings come out of the same core as anyone's. TASK-12.3 mixes the actions by a fixed hash of
# their number, 2 in 5 lights, 2 in 5 charged and 1 in 5 feints, the feint a charged cut by the
# guard button's press 24 ticks in and a light 4 ticks later (partida.md, "O boneco que ataca").
# The real Match runs in Sozinho with netfox's ticks advanced by hand (test/support/
# netfox_ticks.gd; DEC-0027 §3).
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

## partida.md, "O boneco que ataca": "um golpe a cada 3 s, 180 ticks".
const PERIOD_TICKS := 180
## partida.md, "O boneco que ataca": the feint's guard press 24 ticks into the charged's windup,
## the light 4 ticks after it; the feint lasts 12 (combate.md, "A finta").
const FEINT_PRESS_TICKS := 24
const LIGHT_AFTER_FEINT_TICKS := 4
const FEINT_TICKS := 12
const HAIR := 1e-4


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


# A match with the player and the dummy at their spawn points, the dummy attacking, netfox's
# deferred setup done.
func _match() -> Match:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match: Match = auto_free(node)
	add_child(game_match)
	var me := multiplayer.get_unique_id()
	var player := game_match.spawn_fighter(Match.PLAYER_SLOT, me)
	var dummy := game_match.spawn_fighter(Match.DUMMY_SLOT, me)
	game_match.let_dummy_attack(dummy, player)
	await get_tree().process_frame
	await get_tree().physics_frame
	return game_match


func test_the_period_is_180_ticks_at_60_and_90_at_30() -> void:
	var game_match := await _match()
	assert_int(game_match.attacking_dummy.period_ticks).is_equal(PERIOD_TICKS)
	var player := game_match.fighter_at(Match.PLAYER_SLOT)
	var dummy := game_match.fighter_at(Match.DUMMY_SLOT)
	var at_30 := AttackingDummy.new(dummy, player, 0, 30)
	assert_int(at_30.period_ticks).is_equal(PERIOD_TICKS / 2)
	at_30.free()


# The dummy presses on every period after its first tick, never on that tick, and on no other.
func test_it_presses_once_every_period_from_its_first_tick() -> void:
	var game_match := await _match()
	var attacking := game_match.attacking_dummy
	var start := attacking.start_tick
	var presses: Array[int] = []
	for tick: int in range(start, start + 3 * PERIOD_TICKS + 1):
		if attacking.presses_at(tick):
			presses.append(tick - start)
	assert_array(presses).is_equal([PERIOD_TICKS, 2 * PERIOD_TICKS, 3 * PERIOD_TICKS])


# Over four periods the dummy starts an action on each, turned toward the player, and never moves:
# a light or a charged by the hash of its number, a feint as a charged that becomes FEINT 24 ticks
# in and a light when the feint ends. It presses through its input box, and the core fires it.
func test_it_mixes_its_actions_toward_the_player_without_walking() -> void:
	var game_match := await _match()
	var player := game_match.fighter_at(Match.PLAYER_SLOT)
	var dummy := game_match.fighter_at(Match.DUMMY_SLOT)
	var attacking := game_match.attacking_dummy
	var spawn := dummy.position
	var toward := AttackingDummy.yaw_toward(
		dummy.global_position,
		player.global_position,
		dummy.state.facing_yaw,
	)
	var expected: Array[String] = []
	for k: int in range(1, 5):
		var at := k * PERIOD_TICKS
		match AttackingDummy.kind_of(k):
			AttackingDummy.Kind.LIGHT:
				expected.append("%d windup light_attack" % at)
			AttackingDummy.Kind.CHARGED:
				expected.append("%d windup charged_attack" % at)
			AttackingDummy.Kind.FEINT:
				expected.append("%d windup charged_attack" % at)
				expected.append("%d feint" % (at + FEINT_PRESS_TICKS))
				var light_at := at + FEINT_PRESS_TICKS + FEINT_TICKS
				expected.append("%d windup light_attack" % light_at)
	var seen: Array[String] = []
	var before := dummy.state.copy()
	for _loop: int in 4 * PERIOD_TICKS + 2:
		player.input.sample_frame(Vector2.ZERO, player.state.facing_yaw)
		NetfoxTicks.run_loop()
		var state := dummy.state
		var since := state.action_since - attacking.start_tick
		var began := state.action != before.action or state.action_since != before.action_since
		if began and state.action == FighterState.Action.WINDUP:
			seen.append("%d windup %s" % [since, state.action_move])
			assert_float(angle_difference(state.action_yaw, toward)).is_equal_approx(0.0, HAIR)
		elif began and state.action == FighterState.Action.FEINT:
			seen.append("%d feint" % since)
		before = state.copy()
	assert_array(seen).is_equal(expected)
	assert_vector(dummy.position).is_equal_approx(spawn, Vector3.ONE * HAIR)


# The mix (partida.md, "O boneco que ataca"): the kind of the k-th action is a pure function of k,
# 2 in 5 lights, 2 in 5 charged and 1 in 5 feints over many actions, within a tenth of each share,
# and the first four already hold all three, so a session of a minute meets them all.
func test_the_mix_is_two_lights_two_charged_and_one_feint_in_five_by_a_fixed_hash() -> void:
	var counts: Dictionary[AttackingDummy.Kind, int] = {
		AttackingDummy.Kind.LIGHT: 0,
		AttackingDummy.Kind.CHARGED: 0,
		AttackingDummy.Kind.FEINT: 0,
	}
	var actions := 1000
	for k: int in range(1, actions + 1):
		var kind := AttackingDummy.kind_of(k)
		assert_int(AttackingDummy.kind_of(k)).override_failure_message("k %d changed" % k) \
				.is_equal(kind)
		counts[kind] += 1
	var shares: Dictionary[AttackingDummy.Kind, float] = {
		AttackingDummy.Kind.LIGHT: 0.4,
		AttackingDummy.Kind.CHARGED: 0.4,
		AttackingDummy.Kind.FEINT: 0.2,
	}
	for kind: AttackingDummy.Kind in shares:
		var expected := shares[kind] * actions
		var message := "%s: %d of %d" % [AttackingDummy.Kind.find_key(kind), counts[kind], actions]
		assert_float(float(counts[kind])).override_failure_message(message).is_between(
			expected * 0.9,
			expected * 1.1,
		)
	var first: Array[AttackingDummy.Kind] = []
	for k: int in range(1, 5):
		if not first.has(AttackingDummy.kind_of(k)):
			first.append(AttackingDummy.kind_of(k))
	assert_int(first.size()).override_failure_message("the first four lack a kind").is_equal(3)


# What each kind presses over its period: the light or the charged on the period's tick; the feint
# the charged there, the guard's press 24 ticks later and the light 4 after that; nothing else.
func test_each_kind_presses_its_commands_on_their_ticks() -> void:
	var game_match := await _match()
	var attacking := game_match.attacking_dummy
	var start := attacking.start_tick
	assert_int(attacking.feint_press_ticks).is_equal(FEINT_PRESS_TICKS)
	assert_int(attacking.light_after_feint_ticks).is_equal(LIGHT_AFTER_FEINT_TICKS)
	var found: Dictionary[AttackingDummy.Kind, bool] = { }
	for k: int in range(1, 30):
		var kind := AttackingDummy.kind_of(k)
		found[kind] = true
		var expected: Dictionary[int, Array] = { }
		match kind:
			AttackingDummy.Kind.LIGHT:
				expected[0] = [FighterCommand.LIGHT_ATTACK]
			AttackingDummy.Kind.CHARGED:
				expected[0] = [FighterCommand.CHARGED_ATTACK]
			AttackingDummy.Kind.FEINT:
				expected[0] = [FighterCommand.CHARGED_ATTACK]
				expected[FEINT_PRESS_TICKS] = [&"guard"]
				expected[FEINT_PRESS_TICKS + LIGHT_AFTER_FEINT_TICKS] = [
					FighterCommand.LIGHT_ATTACK
				]
		for into: int in PERIOD_TICKS:
			var pressed := attacking.presses(start + k * PERIOD_TICKS + into)
			var wanted: Array = expected[into] if expected.has(into) else []
			var message := "action %d, tick %d into it: %s" % [k, into, pressed]
			assert_array(pressed).override_failure_message(message).is_equal(wanted)
	assert_int(found.size()).is_equal(3)
	assert_array(attacking.presses(start)).is_empty()


# The yaw toward a point follows the core's convention: yaw 0 looks down -Z, a positive yaw turns
# left (Blade.direction); on one axis the dummy keeps its own.
func test_the_yaw_toward_a_point_looks_at_it() -> void:
	var from := Vector3(1, 0, 1)
	for to: Vector3 in [Vector3(1, 0, -5), Vector3(-3, 2, 1), Vector3(4, 0, 5)]:
		var yaw := AttackingDummy.yaw_toward(from, to, 0.0)
		var flat := Vector3(to.x - from.x, 0.0, to.z - from.z).normalized()
		assert_vector(Blade.direction(yaw)).is_equal_approx(flat, Vector3.ONE * HAIR)
	assert_float(AttackingDummy.yaw_toward(from, from + Vector3.UP, 0.7)).is_equal(0.7)
