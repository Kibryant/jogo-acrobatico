# Criterion 6 of TASK-9 and DEC-0026 §6: the Main reads how the game was opened. With no argument
# it plays Sozinho: netfox's clock starts on Godot's offline peer, then a match with this PC's
# fighter and its camera. An argument it does not know is refused (F-056). Ending the session
# stops the clock before the match goes, the clean exit the probe lacked (F-026 §4).
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MAIN_SCENE := preload("res://main/main.tscn")
const SPAWN_A := Vector3(-6, 0, 9) # arena.tscn: SpawnA
const HAIR := 1e-4


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()
	get_tree().auto_accept_quit = true


func test_no_argument_means_sozinho() -> void:
	assert_array(Main.unknown_arguments(PackedStringArray())).is_empty()


func test_every_argument_this_build_does_not_know_is_refused() -> void:
	var arguments := PackedStringArray(["--servr", "--port=7777", "--connect=127.0.0.1:7777"])
	assert_array(Main.unknown_arguments(arguments)).is_equal(arguments)


func test_an_unknown_argument_exits_with_a_code_other_than_zero() -> void:
	assert_int(Main.EXIT_USAGE).is_not_equal(0)


# The test runner passes no argument after "--", so the Main opens as the game does with none.
func test_with_no_argument_the_main_plays_sozinho() -> void:
	var node: Node = auto_free(MAIN_SCENE.instantiate())
	assert(node is Main, "main.tscn must have a Main at its root")
	var main := node as Main
	add_child(main)
	await get_tree().process_frame
	assert_bool(multiplayer.multiplayer_peer is OfflineMultiplayerPeer).is_true()
	assert_bool(NetworkTime.is_initial_sync_done()).is_true()
	assert_object(main.current_match).is_not_null()
	assert_int(main.current_match.fighters.size()).is_equal(1)
	var fighter := main.current_match.fighters[0]
	assert_vector(fighter.position).is_equal_approx(SPAWN_A, Vector3.ONE * HAIR)
	assert_object(main.current_match.camera_rig).is_not_null()
	# Closing the window must come to the Main first (DEC-0026 §6).
	assert_bool(get_tree().auto_accept_quit).is_false()


func test_ending_the_session_stops_the_clock_and_frees_the_match() -> void:
	var node: Node = auto_free(MAIN_SCENE.instantiate())
	assert(node is Main, "main.tscn must have a Main at its root")
	var main := node as Main
	add_child(main)
	await get_tree().process_frame
	var game_match := main.current_match
	main.end_session()
	assert_bool(NetworkTime.is_initial_sync_done()).is_false()
	assert_object(main.current_match).is_null()
	await get_tree().process_frame
	assert_bool(is_instance_valid(game_match)).is_false()
