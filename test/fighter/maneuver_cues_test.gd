# Criterion 5 of TASK-10.4: the double jump and the dash each play one visual cue, once per key
# (fighter, kind, stamp), when they first show in the displayed state, and never again when a
# rollback runs their tick again (DEC-0031 §6). The real Match runs in Sozinho with netfox's ticks
# by hand (test/support/netfox_ticks.gd; DEC-0027 §3); the SyncTest checks the same count under
# the forced rollback of every tick (fighter_sync_test.gd, the dash and pulo duplo scenarios).
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

## Ticks netfox rolls back on every loop in the rollback test: the SyncTest's depth (rede.md §4).
const DEPTH := 7
## Ticks the fighter stands before a press, so its first state is recorded.
const STAND_TICKS := 3

var _match: Match
var _fighter: Fighter
var _first_tick := 0


func before_test() -> void:
	NetfoxTicks.reset()


# A Match in the tree with one fighter, netfox's deferred setup done; the ticks then run inside a
# physics frame (test/support/netfox_ticks.gd).
func _start() -> void:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	_match = auto_free(node)
	add_child(_match)
	_fighter = _match.spawn_fighter(0, multiplayer.get_unique_id())
	_first_tick = NetworkTime.tick
	await get_tree().process_frame
	await get_tree().physics_frame


func after_test() -> void:
	if NetworkRollback.before_loop.is_connected(_force_rollback):
		NetworkRollback.before_loop.disconnect(_force_rollback)
	NetfoxTicks.reset()


func _stand(ticks: int) -> void:
	for _tick: int in ticks:
		_fighter.input.sample_frame(Vector2.ZERO, _fighter.state.facing_yaw)
		NetfoxTicks.run_loop()


func _force_rollback() -> void:
	NetworkRollback.notify_resimulation_start(maxi(NetworkTime.tick - DEPTH, _first_tick))


# Jumps, and presses again on the jump's first tick in the air: the double jump.
func _double_jump() -> void:
	_fighter.input.press_jump()
	_stand(1)
	_fighter.input.press_jump()
	_stand(1)
	assert_int(_fighter.state.jumps_used).is_equal(2)


func test_a_match_has_cues_that_draw_nothing_without_a_screen() -> void:
	await _start()
	assert_object(_match.cues).is_not_null()
	assert_object(_match.cues.get_parent()).is_same(_match)
	_stand(STAND_TICKS)
	_fighter.input.press_dash()
	_stand(2)
	assert_int(_match.cues.presented).is_equal(1)
	assert_int(_match.cues.get_child_count()).is_equal(0)


# One dash is one cue and one event, through its 12 ticks and after them; the next dash is
# another key, and so is the double jump.
func test_each_dash_and_each_double_jump_play_one_cue_once() -> void:
	await _start()
	var cues := _match.cues
	_stand(STAND_TICKS)
	assert_int(cues.presented).is_equal(0)
	_fighter.input.press_dash()
	_stand(_match.config.dash_ticks + 1)
	assert_int(cues.presented).is_equal(1)
	assert_int(cues.events).is_equal(1)
	_stand(_match.config.dash_cooldown_ticks)
	_fighter.input.press_dash()
	_stand(_match.config.dash_ticks + 1)
	assert_int(cues.presented).is_equal(2)
	_double_jump()
	assert_int(cues.presented).is_equal(3)
	assert_int(cues.events).is_equal(3)
	# Still in the air, the stamp still shows: nothing more plays.
	_stand(5)
	assert_int(cues.presented).is_equal(3)


# With netfox rolling back DEPTH ticks on every loop, the dash and the double jump are simulated
# up to DEPTH + 1 times each, and still play once: the key already played.
func test_a_rollback_that_runs_the_tick_again_plays_nothing_again() -> void:
	await _start()
	var cues := _match.cues
	_stand(STAND_TICKS)
	NetworkRollback.before_loop.connect(_force_rollback)
	var simulated := Counter.new(_fighter)
	NetworkRollback.after_process_tick.connect(simulated.note)
	_fighter.input.press_dash()
	_stand(_match.config.dash_ticks + DEPTH)
	_stand(_match.config.dash_cooldown_ticks)
	_double_jump()
	_stand(DEPTH)
	NetworkRollback.after_process_tick.disconnect(simulated.note)
	NetworkRollback.before_loop.disconnect(_force_rollback)
	assert_int(simulated.starts).override_failure_message("the rollback did not rerun them") \
			.is_greater(2)
	assert_int(cues.presented).is_equal(2)
	assert_int(cues.events).is_equal(2)


# A dash_tick that stays after the dash shows no trail: a fighter first seen long after its dash
# plays nothing old.
func test_an_old_dash_stamp_plays_no_cue() -> void:
	await _start()
	var cues := ManeuverCues.new(_match.config, false)
	_fighter.state.dash_tick = 7
	_fighter.state.mode = FighterState.Mode.GROUND
	_match.add_child(cues)
	cues.watch(_fighter)
	NetfoxTicks.run_loop()
	assert_int(cues.presented).is_equal(0)
	cues.free()


# With a screen, the dash leaves a trail in the fighter's tone and the double jump a puff; each
# goes away by itself after it fades.
func test_with_a_screen_the_cues_draw_a_trail_and_a_puff_that_go_away() -> void:
	await _start()
	var cues := ManeuverCues.new(_match.config, true)
	_match.add_child(cues)
	cues.watch(_fighter)
	_stand(STAND_TICKS)
	_fighter.input.press_dash()
	_stand(1)
	var trails := cues.find_children("DashTrail*", "MeshInstance3D", false, false)
	assert_int(trails.size()).is_equal(1)
	assert_str(_tone_of(trails[0])).is_equal(str(Color(_fighter.tone, ManeuverCues.OPACITY)))
	_stand(_match.config.dash_ticks + _match.config.dash_cooldown_ticks)
	_double_jump()
	var puffs := cues.find_children("DoubleJumpPuff*", "MeshInstance3D", false, false)
	assert_int(puffs.size()).is_equal(1)
	assert_int(cues.presented).is_equal(2)
	# The longest cue is the puff, over the jump's rise: 350 ms (movimento.md, "Pulo e ar").
	await get_tree().create_timer(0.6).timeout
	assert_int(cues.get_child_count()).is_equal(0)
	cues.free()


# The colour a cue's mesh wears, as text.
func _tone_of(cue: Node) -> String:
	assert(cue is MeshInstance3D, "a cue is a MeshInstance3D")
	var mesh := (cue as MeshInstance3D).mesh
	assert(mesh is PrimitiveMesh, "a cue's mesh is a primitive")
	var material := (mesh as PrimitiveMesh).material
	assert(material is StandardMaterial3D, "a cue's material is a StandardMaterial3D")
	return str((material as StandardMaterial3D).albedo_color)


# Counts the dash starts netfox simulates, fresh or again.
class Counter:
	var starts := 0

	var _fighter: Fighter


	func _init(fighter: Fighter) -> void:
		_fighter = fighter


	func note(tick: int) -> void:
		var state := _fighter.state
		if state.mode == FighterState.Mode.DASH and state.dash_tick == tick:
			starts += 1
