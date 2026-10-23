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


# TASK-10.3: a replay played in a window gets a camera that only follows its fighter, looking where
# it looks, and leaves the mouse free: the replay's rows drive the fighter, not this PC's devices.
func test_view_gives_a_replayed_fighter_a_camera_that_only_follows() -> void:
	var game_match := await _match_with_fighters(1)
	var rig := game_match.view(game_match.fighters[0])
	assert_object(game_match.camera_rig).is_same(rig)
	assert_bool(rig.takes_mouse).is_false()
	assert_float(rig.yaw).is_equal_approx(SPAWN_A_YAW, HAIR)
	assert_int(Input.mouse_mode).is_not_equal(Input.MOUSE_MODE_CAPTURED)


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


# TASK-9, part 2: the server names each new fighter in the order they spawn, never twice in a
# match, so a player who joins where another left never meets the leaving node's route in netfox
# (Match.spawn_fighter). The leaving fighter frees its seat at once and its node when the frame
# ends.
func test_fighters_are_named_in_spawn_order_and_never_twice() -> void:
	var game_match := await _match_with_fighters(2)
	assert_str(game_match.fighters[0].name).is_equal("Fighter0")
	assert_str(game_match.fighters[1].name).is_equal("Fighter1")
	var leaving := game_match.fighter_at(1)
	game_match.remove_fighter(1)
	assert_object(game_match.fighter_at(1)).is_null()
	assert_array(game_match.fighters).is_equal([game_match.fighter_at(0)])
	game_match.remove_fighter(1) # a free seat: nothing to remove
	assert_array(game_match.fighters).is_equal([game_match.fighter_at(0)])
	var newcomer := game_match.spawn_fighter(1, multiplayer.get_unique_id())
	assert_str(newcomer.name).is_equal("Fighter2")
	assert_object(game_match.fighter_at(1)).is_same(newcomer)
	await get_tree().process_frame
	assert_bool(is_instance_valid(leaving)).is_false()


# TASK-9, round C2: a fighter exists from its first tick on (Fighter._rollback_spawn). Pushed
# forward before it, it stays at its spawn point, and from it, it runs: netfox neither simulates nor
# records it earlier, so a client whose clock lags the server's starts it where the server does.
func test_a_fighter_is_not_simulated_before_its_first_tick() -> void:
	var game_match := await _match_with_fighters(0)
	var late := 5
	var fighter := game_match.spawn_fighter(0, multiplayer.get_unique_id(), NetworkTime.tick + late)
	await get_tree().process_frame
	await get_tree().physics_frame
	assert_int(fighter.synchronizer.spawn_tick).is_equal(NetworkTime.tick + late)
	for _loop: int in late:
		fighter.input.sample_frame(FORWARD, SPAWN_A_YAW)
		NetfoxTicks.run_loop()
	assert_vector(fighter.position).is_equal_approx(SPAWN_A, Vector3.ONE * HAIR)
	fighter.input.sample_frame(FORWARD, SPAWN_A_YAW)
	NetfoxTicks.run_loop()
	assert_float(fighter.position.z).is_less(SPAWN_A.z - HAIR)


# Without a first tick, a fighter starts on the clock's tick, the next one the loop runs.
func test_a_fighter_starts_on_the_clocks_tick_by_default() -> void:
	var game_match := await _match_with_fighters(1)
	assert_int(game_match.fighters[0].synchronizer.spawn_tick).is_equal(NetworkTime.tick)


# A client mirrors a fighter under the server's name, with netfox's history starting at the
# clock's tick: right after the clock syncs no tick loop has run, and netfox's own guess, the tick
# after its last rollback, would be 1 (Main._add_fighter).
func test_a_mirrored_fighter_takes_the_servers_name_and_the_clocks_tick() -> void:
	var game_match := await _match_with_fighters(0)
	var other_peer := 1450222694
	var fighter := game_match.spawn_fighter(1, other_peer, NetworkTime.tick, "Fighter7")
	assert_str(fighter.name).is_equal("Fighter7")
	assert_int(fighter.synchronizer.spawn_tick).is_equal(NetworkTime.tick)
	assert_int(fighter.input.get_multiplayer_authority()).is_equal(other_peer)
	assert_object(game_match.fighter_at(1)).is_same(fighter)


func test_removing_the_watched_fighter_takes_its_camera_away() -> void:
	var game_match := await _match_with_fighters(1)
	var rig := game_match.watch(game_match.fighters[0])
	game_match.remove_fighter(0)
	assert_object(game_match.camera_rig).is_null()
	await get_tree().process_frame
	assert_bool(is_instance_valid(rig)).is_false()


# TASK-9, part 2: the bot plays from the clock's tick with a camera that leaves the mouse alone, and
# leaves the match with its fighter, as the camera does.
func test_the_bot_plays_from_the_clocks_tick_and_leaves_with_its_fighter() -> void:
	var game_match := await _match_with_fighters(1)
	var bot := game_match.let_bot_play(game_match.fighters[0])
	var rig := game_match.camera_rig
	assert_int(bot.start_tick).is_equal(NetworkTime.tick)
	assert_bool(rig.takes_mouse).is_false()
	assert_float(rig.yaw).is_equal_approx(SPAWN_A_YAW, HAIR)
	game_match.remove_fighter(0)
	assert_object(game_match.bot).is_null()
	assert_object(game_match.camera_rig).is_null()
	await get_tree().process_frame
	assert_bool(is_instance_valid(bot)).is_false()
	assert_bool(is_instance_valid(rig)).is_false()
