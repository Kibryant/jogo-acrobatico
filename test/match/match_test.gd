# Criterion 6 of TASK-9: the Match in Sozinho, Godot's offline peer, where this PC is its own
# server (DEC-0026 §5). Ticks run by hand through netfox's real loop (test/support/netfox_ticks.gd;
# DEC-0027 §3), so two seconds of game take a few milliseconds and the same ticks every run.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

const HAIR := 1e-4 # m: a tenth of a millimetre, far below the SyncTest's 1 mm (rede.md §4)
const FORWARD := Vector2(0, 1)
const SPAWN_A := Vector3(-6, 0, 9) # arena.tscn: SpawnA, its feet on the floor
const SPAWN_A_YAW := 0.0 # it looks down -Z, toward SpawnB


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


# A match in the tree, with netfox's deferred setup of its fighters done.
func _match_with_fighters(count: int) -> Match:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match: Match = auto_free(node)
	add_child(game_match)
	for slot: int in count:
		game_match.spawn_fighter(slot, multiplayer.get_unique_id())
	# The RollbackSynchronizer registers its properties with call_deferred; the ticks then run
	# inside a physics frame (test/support/netfox_ticks.gd).
	await get_tree().process_frame
	await get_tree().physics_frame
	return game_match


func test_the_match_runs_on_netfox_tickrate_with_the_movement_data() -> void:
	var game_match := await _match_with_fighters(0)
	assert_int(game_match.config.tickrate).is_equal(NetworkTime.tickrate)
	assert_int(game_match.config.coyote_ticks).is_equal(6) # 100 ms at 60 (visao-geral.md)
	assert_object(game_match.camera_data).is_not_null()
	assert_int(game_match.arena.spawn_point_count()).is_equal(2)


# The fighter spawns standing at SpawnA and, with no input, stays there: no jump, no slide.
func test_in_sozinho_the_fighter_rests_on_the_floor_at_its_spawn() -> void:
	var game_match := await _match_with_fighters(1)
	var fighter := game_match.fighters[0]
	game_match.watch(fighter)
	assert_vector(fighter.position).is_equal_approx(SPAWN_A, Vector3.ONE * HAIR)
	assert_float(fighter.state.facing_yaw).is_equal_approx(SPAWN_A_YAW, HAIR)
	var start_tick := NetworkTime.tick
	var violations: Array[String] = []
	for step: int in range(1, 2 * NetworkTime.tickrate + 1):
		NetfoxTicks.run_loop()
		if fighter.position.distance_to(SPAWN_A) > HAIR:
			violations.append("tick %d: slid to %s" % [step, fighter.position])
		if not fighter.state.on_floor or fighter.state.mode != FighterState.Mode.GROUND:
			violations.append("tick %d: left the floor" % step)
		if fighter.state.jumps_used != 0:
			violations.append("tick %d: jumped" % step)
		if fighter.velocity.length() > HAIR:
			violations.append("tick %d: moving at %s" % [step, fighter.velocity])
	assert_array(violations).is_empty()
	assert_int(NetworkTime.tick - start_tick).is_equal(2 * NetworkTime.tickrate)
	# The ticks did simulate this fighter: pushed forward, it runs away from the spawn.
	for _step: int in 10:
		fighter.input.sample_frame(FORWARD, SPAWN_A_YAW)
		NetfoxTicks.run_loop()
	assert_float(fighter.position.z).is_less(SPAWN_A.z - 0.5)


# A frame that runs two ticks to catch netfox's clock must move the fighter as much as two
# frames of one tick: no tick of Sozinho is lost (Match._simulate_every_tick_of_the_loop).
func test_two_ticks_in_one_frame_move_as_far_as_two_frames() -> void:
	var game_match := await _match_with_fighters(1)
	var fighter := game_match.fighters[0]
	for _frame: int in 30:
		fighter.input.sample_frame(FORWARD, SPAWN_A_YAW)
		NetfoxTicks.run_loop()
	var one_tick_frames := fighter.position
	game_match.free()
	NetfoxTicks.reset()

	game_match = await _match_with_fighters(1)
	fighter = game_match.fighters[0]
	for _frame: int in 15:
		fighter.input.sample_frame(FORWARD, SPAWN_A_YAW)
		NetfoxTicks.run_loop(2)
	assert_vector(fighter.position).is_equal_approx(one_tick_frames, Vector3.ONE * HAIR)
	assert_float(fighter.position.z).is_less(SPAWN_A.z - 1.0)


# The camera follows its own fighter only, and the fighter's input reads this PC's devices.
func test_watch_gives_the_fighter_a_camera() -> void:
	var game_match := await _match_with_fighters(2)
	var rig := game_match.watch(game_match.fighters[0])
	assert_object(game_match.camera_rig).is_same(rig)
	assert_float(rig.yaw).is_equal_approx(SPAWN_A_YAW, HAIR)


# The two spawn points: 10 m apart, each looking at the other (TASK-9, "Números v0 do Claude").
func test_the_two_fighters_spawn_10_m_apart_facing_each_other() -> void:
	var game_match := await _match_with_fighters(2)
	var first := game_match.fighters[0]
	var second := game_match.fighters[1]
	assert_float(first.position.distance_to(second.position)).is_equal_approx(10.0, HAIR)
	var first_forward := Basis(Vector3.UP, first.state.facing_yaw) * Vector3.FORWARD
	var second_forward := Basis(Vector3.UP, second.state.facing_yaw) * Vector3.FORWARD
	var first_to_second := (second.position - first.position).normalized()
	assert_vector(first_forward).is_equal_approx(first_to_second, Vector3.ONE * HAIR)
	assert_vector(second_forward).is_equal_approx(-first_to_second, Vector3.ONE * HAIR)
	assert_float(first.position.y).is_equal_approx(0.0, HAIR)
	assert_float(second.position.y).is_equal_approx(0.0, HAIR)
