# TASK-12.2 (partida.md, "O boneco que ataca"): Sozinho's dummy presses a light every 3 s, 180
# ticks at 60, turned toward whoever plays, and only through its input box: it does not walk, and
# its swings come out of the same core as anyone's. The real Match runs in Sozinho with netfox's
# ticks advanced by hand (test/support/netfox_ticks.gd; DEC-0027 §3).
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

## partida.md, "O boneco que ataca": "um leve a cada 3 s, 180 ticks".
const PERIOD_TICKS := 180
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


# Over two periods the dummy swings twice, turned toward the player, and never moves: it presses
# the light through its input box, the core fires it, and the swing's direction is the yaw toward
# the player's feet.
func test_it_swings_a_light_toward_the_player_every_period_without_walking() -> void:
	var game_match := await _match()
	var player := game_match.fighter_at(Match.PLAYER_SLOT)
	var dummy := game_match.fighter_at(Match.DUMMY_SLOT)
	var spawn := dummy.position
	var toward := AttackingDummy.yaw_toward(
		dummy.global_position,
		player.global_position,
		dummy.state.facing_yaw,
	)
	var swings: Array[int] = []
	var was_swinging := false
	for _loop: int in 2 * PERIOD_TICKS + 2:
		player.input.sample_frame(Vector2.ZERO, player.state.facing_yaw)
		NetfoxTicks.run_loop()
		var windup := dummy.state.action == FighterState.Action.WINDUP
		if windup and not was_swinging:
			swings.append(dummy.state.action_since - game_match.attacking_dummy.start_tick)
			assert_float(angle_difference(dummy.state.action_yaw, toward)).is_equal_approx(
				0.0,
				HAIR,
			)
		was_swinging = dummy.state.action != FighterState.Action.NONE
	assert_array(swings).is_equal([PERIOD_TICKS, 2 * PERIOD_TICKS])
	assert_vector(dummy.position).is_equal_approx(spawn, Vector3.ONE * HAIR)


# The yaw toward a point follows the core's convention: yaw 0 looks down -Z, a positive yaw turns
# left (Blade.direction); on one axis the dummy keeps its own.
func test_the_yaw_toward_a_point_looks_at_it() -> void:
	var from := Vector3(1, 0, 1)
	for to: Vector3 in [Vector3(1, 0, -5), Vector3(-3, 2, 1), Vector3(4, 0, 5)]:
		var yaw := AttackingDummy.yaw_toward(from, to, 0.0)
		var flat := Vector3(to.x - from.x, 0.0, to.z - from.z).normalized()
		assert_vector(Blade.direction(yaw)).is_equal_approx(flat, Vector3.ONE * HAIR)
	assert_float(AttackingDummy.yaw_toward(from, from + Vector3.UP, 0.7)).is_equal(0.7)
