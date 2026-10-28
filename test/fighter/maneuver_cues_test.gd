# Criterion 5 of TASK-10.4: the double jump and the dash each play one visual cue, once per key
# (fighter, kind, stamp), when they first show in the displayed state, and never again when a
# rollback runs their tick again (DEC-0031 §6); TASK-10.5 adds the wall jump's mark, and
# TASK-10.10 the short trail of a wall run (movimento.md, "O que se vê na parede"), and
# TASK-10.6 the grapple's cable and the short trail of its pull (visual-e-audio.md, "O gancho na
# tela"). The real Match runs in Sozinho with netfox's ticks by hand
# (test/support/netfox_ticks.gd; DEC-0027 §3); the SyncTest checks the same count under the
# forced rollback of every tick (fighter_sync_test.gd, the dash, pulo duplo, parede and gancho
# scenarios). TASK-10.7 adds the same short trail on a slide off another fighter's head
# (visual-e-audio.md, "A cabeça do outro na tela"; the SyncTest's cabeca scenario). TASK-12.1 adds
# the light's two cues, the arc's trail once per swing and the white flash once per hit, the hit
# first showing on the tick after its contact (visual-e-audio.md, "O leve na tela"; the
# SyncTest of test/fighter/light_attack_sync_test.gd).
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")
const AimAt := preload("res://test/support/aim_at.gd")

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


# A wall_jump_tick that stays after the wall jump shows no mark: on the floor, or in a flight that
# began later, the event is gone; during the flight the wall jump began, it shows by its stamp.
func test_the_wall_jump_shows_only_during_the_flight_it_began() -> void:
	await _start()
	var state := _fighter.state
	state.wall_jump_tick = 50
	state.mode = FighterState.Mode.GROUND
	state.mode_since = 60
	assert_array(ManeuverCues.shown_events(_fighter)).is_empty()
	state.mode = FighterState.Mode.AIR
	assert_array(ManeuverCues.shown_events(_fighter)).is_empty()
	state.mode_since = 50
	var shown := ManeuverCues.shown_events(_fighter)
	assert_int(shown.size()).is_equal(1)
	assert_int(shown[0].kind).is_equal(ManeuverCues.Kind.WALL_JUMP)
	assert_int(shown[0].stamp).is_equal(50)


# A Match with one fighter in the air beside a wall of the test's own, 8 m tall, in a corner of
# the arena away from its shapes: the face at x = -30, the fighter flying into it and north along
# it, set before netfox records the first state. Returns once the fighter is on its wall run.
func _start_beside_a_wall(cues_draw: bool) -> ManeuverCues:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	_match = auto_free(node)
	add_child(_match)
	var wall := StaticBody3D.new()
	wall.name = "ParedeDoSinal"
	wall.position = Vector3(-30.5, 4, 20)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1, 8, 12)
	collision.shape = box
	wall.add_child(collision)
	_match.arena.add_child(wall)
	_fighter = _match.spawn_fighter(0, multiplayer.get_unique_id())
	_fighter.position = Vector3(-29.5, 2, 16)
	_fighter.state.on_floor = false
	_fighter.state.mode = FighterState.Mode.AIR
	_fighter.velocity = Vector3(-2, 0, 8)
	_first_tick = NetworkTime.tick
	await get_tree().process_frame
	await get_tree().physics_frame
	var cues := ManeuverCues.new(_match.config, cues_draw)
	_match.add_child(cues)
	cues.watch(_fighter)
	for _tick: int in 30:
		if _fighter.state.mode == FighterState.Mode.WALL_RUN:
			break
		_stand(1)
	assert_int(_fighter.state.mode).is_equal(FighterState.Mode.WALL_RUN)
	assert_str(String(_fighter.state.wall_id)).is_equal("ParedeDoSinal")
	return cues


# With a screen, a wall jump leaves a mark on the wall: a disc in the fighter's tone standing on
# the face, its axis along the wall's normal, which goes away by itself. The run before it played
# its own trail, so the mark is the second cue.
func test_with_a_screen_a_wall_jump_leaves_a_mark_on_the_wall_that_goes_away() -> void:
	var cues := await _start_beside_a_wall(true)
	_fighter.input.press_jump()
	_stand(1)
	assert_int(_fighter.state.wall_jump_tick).is_equal(NetworkTime.tick - 1)
	var marks := cues.find_children("WallJumpMark*", "MeshInstance3D", false, false)
	assert_int(marks.size()).is_equal(1)
	assert_int(cues.presented).is_equal(2)
	assert_str(_tone_of(marks[0])).is_equal(str(Color(_fighter.tone, ManeuverCues.OPACITY)))
	assert(marks[0] is Node3D, "a mark is a Node3D")
	var axis := (marks[0] as Node3D).global_transform.basis.y.normalized()
	assert_vector(axis).is_equal_approx(Vector3.RIGHT, Vector3.ONE * 1e-4)
	# It lasts the jump's rise, 350 ms, like the puff (movimento.md, "Pulo e ar").
	await get_tree().create_timer(0.6).timeout
	assert_int(cues.get_child_count()).is_equal(0)
	cues.free()


# Criterion 5 of TASK-10.10: a wall run plays one short trail, by the key of the tick it began,
# in the fighter's tone; it follows the body along the wall without growing past the path of the
# dash's duration, the trail's own length (Claude's v0 reading of "um rastro curto"), and once
# the run ends it fades and goes away by itself (movimento.md, "O que se vê na parede").
func test_with_a_screen_a_wall_run_draws_one_short_trail_that_goes_away() -> void:
	var cues := await _start_beside_a_wall(true)
	var trails := cues.find_children("WallRunTrail*", "MeshInstance3D", false, false)
	assert_int(trails.size()).is_equal(1)
	assert_int(cues.presented).is_equal(1)
	assert_str(_tone_of(trails[0])).is_equal(str(Color(_fighter.tone, ManeuverCues.OPACITY)))
	assert(trails[0] is Node3D, "a trail is a Node3D")
	var trail := trails[0] as Node3D
	var config := _match.config
	# The path of the dash's duration along the wall: 8 m/s for 200 ms, 1,6 m.
	var short_m := config.wall_run_speed * config.dash_ticks / config.tickrate
	# One tick, then one displayed frame, twenty times: a third of a second along the wall.
	for _frame: int in 20:
		await get_tree().physics_frame
		_stand(1)
		await get_tree().process_frame
	await get_tree().physics_frame
	assert_int(_fighter.state.mode).is_equal(FighterState.Mode.WALL_RUN)
	var length := trail.global_transform.basis.z.length()
	var message := "the trail is %.3f m, the dash's duration covers %.3f m" % [length, short_m]
	assert_float(length).override_failure_message(message).is_greater(0.0)
	# A frame of a test is not a tick: two ticks of path as slack on top of the dash's duration.
	var tick_m := config.wall_run_speed / config.tickrate
	assert_float(length).override_failure_message(message).is_less_equal(short_m + 2.0 * tick_m)
	trails = cues.find_children("WallRunTrail*", "MeshInstance3D", false, false)
	assert_int(trails.size()).is_equal(1)
	_fighter.input.press_jump()
	_stand(1)
	assert_int(_fighter.state.mode).is_equal(FighterState.Mode.AIR)
	await get_tree().create_timer(0.6).timeout
	trails = cues.find_children("WallRunTrail*", "MeshInstance3D", false, false)
	assert_int(trails.size()).is_equal(0)
	cues.free()


# With netfox rolling back DEPTH ticks on every loop, the tick the run began is simulated again
# and again, and the run still plays one trail: one key, one cue. Then the wall jump: two cues
# (DEC-0031 §6).
func test_a_rollback_that_runs_the_wall_run_again_plays_its_trail_once() -> void:
	var cues := await _start_beside_a_wall(false)
	var entry := _fighter.state.mode_since
	NetworkRollback.before_loop.connect(_force_rollback)
	var entries := EntryCounter.new(_fighter, entry)
	NetworkRollback.after_process_tick.connect(entries.note)
	_stand(DEPTH + 2)
	NetworkRollback.after_process_tick.disconnect(entries.note)
	assert_int(_fighter.state.mode).is_equal(FighterState.Mode.WALL_RUN)
	assert_int(_fighter.state.mode_since).is_equal(entry)
	assert_int(entries.again).override_failure_message("the rollback did not rerun the entry") \
			.is_greater(0)
	assert_int(cues.presented).is_equal(1)
	_fighter.input.press_jump()
	_stand(DEPTH)
	NetworkRollback.before_loop.disconnect(_force_rollback)
	assert_int(cues.presented).is_equal(2)


# The wall run's event lasts while the run does, by the tick it began; once in the air it is gone
# (movimento.md, "O que se vê na parede").
func test_the_wall_run_shows_only_while_it_lasts() -> void:
	await _start()
	var state := _fighter.state
	state.mode = FighterState.Mode.WALL_RUN
	state.mode_since = 40
	var shown := ManeuverCues.shown_events(_fighter)
	assert_int(shown.size()).is_equal(1)
	assert_int(shown[0].kind).is_equal(ManeuverCues.Kind.WALL_RUN)
	assert_int(shown[0].stamp).is_equal(40)
	state.mode = FighterState.Mode.AIR
	assert_array(ManeuverCues.shown_events(_fighter)).is_empty()


# The grapple's cues (TASK-10.6; visual-e-audio.md, "O gancho na tela"): a target of the test's
# own in the arena's empty south-east, away from its shapes: a wall 16 m wide and 10 m tall whose
# face looks south at z = 20, and the fighter standing 12 m south of it. The aim goes from the
# point O to TARGET_POINT, 12,2 m off: within the reach (DEC-0045 §2).
const TARGET_FACE_Z := 20.0
const TARGET_START := Vector3(28, 0, 32)
const TARGET_POINT := Vector3(28, 4, 20)


func _start_before_a_target(cues_draw: bool) -> ManeuverCues:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	_match = auto_free(node)
	add_child(_match)
	var wall := StaticBody3D.new()
	wall.name = "AlvoDoGancho"
	wall.position = Vector3(TARGET_POINT.x, 5, TARGET_FACE_Z - 0.5)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(16, 10, 1)
	collision.shape = box
	wall.add_child(collision)
	_match.arena.add_child(wall)
	_fighter = _match.spawn_fighter(0, multiplayer.get_unique_id())
	_fighter.position = TARGET_START
	_first_tick = NetworkTime.tick
	await get_tree().process_frame
	await get_tree().physics_frame
	var cues := ManeuverCues.new(_match.config, cues_draw)
	_match.add_child(cues)
	cues.watch(_fighter)
	return cues


# Aims from the point O at TARGET_POINT (test/support/aim_at.gd) and presses the grapple on the
# next tick: it fires there.
func _fire_at_the_target() -> int:
	var feet := _fighter.global_position
	var yaw := AimAt.yaw_to(feet, TARGET_POINT, _match.config)
	var pitch := AimAt.pitch_to(feet, TARGET_POINT, _match.config)
	_fighter.input.sample_frame(Vector2.ZERO, yaw, pitch)
	_fighter.input.press_grapple()
	var fire_tick := NetworkTime.tick
	NetfoxTicks.run_loop()
	assert_int(_fighter.state.grapple_fired_tick).override_failure_message("no fire").is_equal(
		fire_tick
	)
	return fire_tick


# Stands until the state shows mode, or fails after limit ticks.
func _stand_until_mode(mode: FighterState.Mode, limit: int) -> void:
	for _tick: int in limit:
		if _fighter.state.mode == mode:
			return
		_stand(1)
	assert_int(_fighter.state.mode).is_equal(mode)


func _only_cable(cues: ManeuverCues) -> ManeuverCues.Cable:
	var cables := cues.find_children("GrappleCable*", "MeshInstance3D", false, false)
	assert_int(cables.size()).is_equal(1)
	assert(cables[0] is ManeuverCues.Cable, "the grapple's cable is a Cable")
	return cables[0] as ManeuverCues.Cable


# The cable is in the air while grapple_fired_tick is, by that stamp; the pull while the mode is
# GRAPPLE, by the tick it began; after the release, neither (TASK-10.6 notes, "Cues").
func test_the_grapple_shows_its_cable_while_out_and_its_pull_while_it_lasts() -> void:
	await _start()
	var state := _fighter.state
	assert_array(ManeuverCues.shown_events(_fighter)).is_empty()
	state.grapple_fired_tick = 70
	state.mode = FighterState.Mode.AIR
	var shown := ManeuverCues.shown_events(_fighter)
	assert_int(shown.size()).is_equal(1)
	assert_int(shown[0].kind).is_equal(ManeuverCues.Kind.GRAPPLE_CABLE)
	assert_int(shown[0].stamp).is_equal(70)
	state.mode = FighterState.Mode.GRAPPLE
	state.mode_since = 76
	shown = ManeuverCues.shown_events(_fighter)
	assert_int(shown.size()).is_equal(2)
	assert_int(shown[1].kind).is_equal(ManeuverCues.Kind.GRAPPLE_PULL)
	assert_int(shown[1].stamp).is_equal(76)
	state.grapple_fired_tick = FighterState.NEVER
	state.grapple_end_tick = 90
	state.mode = FighterState.Mode.AIR
	state.mode_since = 90
	assert_array(ManeuverCues.shown_events(_fighter)).is_empty()


# With a screen, a grapple draws its cable: opaque, 3 cm thick, unlit, in the fighter's tone, from
# the displayed shoulder, not from O, the aim's parallax shown (DEC-0045 §5); its tip goes from the
# shoulder to the point over the cable's ticks, counted in netfox's ticks, and stays there through
# the pull, which plays the short trail; on the release the cable goes at once and the trail fades
# in 200 ms (visual-e-audio.md, "O gancho na tela").
func test_with_a_screen_the_grapple_draws_its_cable_and_the_pull_its_trail() -> void:
	var cues := await _start_before_a_target(true)
	_stand(STAND_TICKS)
	var fire_tick := _fire_at_the_target()
	var config := _match.config
	var cable := _only_cable(cues)
	assert(cable.mesh is PrimitiveMesh, "the cable's mesh is a primitive")
	var primitive := cable.mesh as PrimitiveMesh
	assert(primitive.material is StandardMaterial3D, "the cable wears a StandardMaterial3D")
	var material := primitive.material as StandardMaterial3D
	assert_str(str(material.albedo_color)).is_equal(str(Color(_fighter.tone, 1.0)))
	assert_int(material.transparency).is_equal(BaseMaterial3D.TRANSPARENCY_DISABLED)
	assert_int(material.shading_mode).is_equal(BaseMaterial3D.SHADING_MODE_UNSHADED)
	var shoulder := _fighter.global_position + Vector3.UP * config.aim_height
	assert_vector(cable.shoulder()).is_equal_approx(shoulder, Vector3.ONE * 1e-4)
	assert_float(cable.reach()).is_equal(0.0)
	for flown: int in range(1, config.grapple_attach_ticks + 1):
		_stand(1)
		var expected := float(flown) / config.grapple_attach_ticks
		assert_float(cable.reach()).is_equal_approx(expected, 1e-6)
	assert_int(_fighter.state.mode).is_equal(FighterState.Mode.GRAPPLE)
	assert_int(_fighter.state.mode_since).is_equal(fire_tick + config.grapple_attach_ticks)
	assert_vector(cable.tip()).is_equal_approx(_fighter.state.grapple_point, Vector3.ONE * 1e-4)
	# A frame's process_frame comes before its _process: the second one has drawn the cable.
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(cable.visible).is_true()
	var thickness := cable.global_transform.basis.x.length()
	assert_float(thickness).is_equal_approx(ManeuverCues.CABLE_THICKNESS, 1e-4)
	await get_tree().physics_frame
	var trails := cues.find_children("GrapplePullTrail*", "MeshInstance3D", false, false)
	assert_int(trails.size()).is_equal(1)
	assert_str(_tone_of(trails[0])).is_equal(str(Color(_fighter.tone, ManeuverCues.OPACITY)))
	assert_int(cues.presented).is_equal(2)
	for _tick: int in 2 * config.tickrate:
		if _fighter.state.grapple_fired_tick == FighterState.NEVER:
			break
		_stand(1)
	assert_int(_fighter.state.grapple_fired_tick).override_failure_message("never released") \
			.is_equal(FighterState.NEVER)
	await get_tree().process_frame
	await get_tree().process_frame
	var cables := cues.find_children("GrappleCable*", "MeshInstance3D", false, false)
	assert_int(cables.size()).override_failure_message("the cable stayed after the release") \
			.is_equal(0)
	# The trail fades over 200 ms, the dash's duration.
	await get_tree().create_timer(0.5).timeout
	assert_int(cues.get_child_count()).is_equal(0)
	assert_int(cues.presented).is_equal(2)
	cues.free()


# With netfox rolling back DEPTH ticks on every loop, the fire and the pull's start are simulated
# again and again, the ray cast again on each, and each still plays once: one cable, one trail
# (DEC-0031 §6).
func test_a_rollback_that_runs_the_grapple_again_plays_its_cues_once() -> void:
	var cues := await _start_before_a_target(false)
	_stand(STAND_TICKS)
	NetworkRollback.before_loop.connect(_force_rollback)
	var fire_tick := _fire_at_the_target()
	_stand_until_mode(FighterState.Mode.GRAPPLE, _match.config.grapple_attach_ticks + 1)
	_stand(DEPTH + 2)
	NetworkRollback.before_loop.disconnect(_force_rollback)
	assert_int(_fighter.state.grapple_fired_tick).is_equal(fire_tick)
	assert_int(cues.presented).is_equal(2)
	assert_int(cues.events).is_equal(2)
	cues.free()


# The colour a cue's mesh wears, as text.
# The slide off a head shows while it lasts, by the tick the contact with that head began; off
# the head it is gone (visual-e-audio.md, "A cabeça do outro na tela"; TASK-10.7, criterion 7).
func test_the_head_slide_shows_only_while_it_lasts() -> void:
	await _start()
	var state := _fighter.state
	state.mode = FighterState.Mode.AIR
	state.slide_off_dir = Vector3.RIGHT
	state.head_landing_tick = 40
	var shown := ManeuverCues.shown_events(_fighter)
	assert_int(shown.size()).is_equal(1)
	assert_int(shown[0].kind).is_equal(ManeuverCues.Kind.HEAD_SLIDE)
	assert_int(shown[0].stamp).is_equal(40)
	state.slide_off_dir = Vector3.ZERO
	state.head_landing_tick = FighterState.NEVER
	assert_array(ManeuverCues.shown_events(_fighter)).is_empty()


# The head of the test: a second fighter standing in the arena's empty north-west, away from its
# shapes, and the first one dropped onto it 10 cm off its axis, so it slides off toward +X.
const HEAD_AXIS := Vector3(-28, 0, -26)
const DROP_FROM := Vector3(-27.9, 2.4, -26)


# Criterion 7 of TASK-10.7: a slide off a head draws one short trail in the fighter's tone, by the
# key of its landing; it lasts while the body is on the head and goes away by itself 200 ms after
# it leaves (visual-e-audio.md, "A cabeça do outro na tela").
func test_with_a_screen_a_slide_off_a_head_draws_one_short_trail_that_goes_away() -> void:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	_match = auto_free(node)
	add_child(_match)
	_fighter = _match.spawn_fighter(0, multiplayer.get_unique_id())
	var below := _match.spawn_fighter(1, multiplayer.get_unique_id())
	below.position = HEAD_AXIS
	_fighter.position = DROP_FROM
	_fighter.state.on_floor = false
	_fighter.state.mode = FighterState.Mode.AIR
	_first_tick = NetworkTime.tick
	await get_tree().process_frame
	await get_tree().physics_frame
	var cues := ManeuverCues.new(_match.config, true)
	_match.add_child(cues)
	cues.watch(_fighter)
	for _tick: int in 60:
		if _fighter.state.slide_off_dir != Vector3.ZERO:
			break
		_stand(1)
	assert_vector(_fighter.state.slide_off_dir).override_failure_message("never on the head") \
			.is_not_equal(Vector3.ZERO)
	var landing := _fighter.state.head_landing_tick
	var trails := cues.find_children("HeadSlideTrail*", "MeshInstance3D", false, false)
	assert_int(trails.size()).is_equal(1)
	assert_int(cues.presented).is_equal(1)
	assert_str(_tone_of(trails[0])).is_equal(str(Color(_fighter.tone, ManeuverCues.OPACITY)))
	for _tick: int in 60:
		if _fighter.state.slide_off_dir == Vector3.ZERO:
			break
		await get_tree().physics_frame
		_stand(1)
		await get_tree().process_frame
		assert_int(_fighter.state.head_landing_tick).is_in([landing, FighterState.NEVER])
	assert_vector(_fighter.state.slide_off_dir).override_failure_message("still on the head") \
			.is_equal(Vector3.ZERO)
	trails = cues.find_children("HeadSlideTrail*", "MeshInstance3D", false, false)
	assert_int(trails.size()).is_equal(1)
	assert_int(cues.presented).is_equal(1)
	# The trail fades over the dash's duration, 200 ms, once the body is off the head.
	await get_tree().create_timer(0.6).timeout
	trails = cues.find_children("HeadSlideTrail*", "MeshInstance3D", false, false)
	assert_int(trails.size()).is_equal(0)
	cues.free()


func _tone_of(cue: Node) -> String:
	assert(cue is MeshInstance3D, "a cue is a MeshInstance3D")
	var mesh := (cue as MeshInstance3D).mesh
	assert(mesh is PrimitiveMesh, "a cue's mesh is a primitive")
	var material := (mesh as PrimitiveMesh).material
	assert(material is StandardMaterial3D, "a cue's material is a StandardMaterial3D")
	return str((material as StandardMaterial3D).albedo_color)


# TASK-12.1: a light that lands draws the arc's trail in vermilion once, keyed by the tick its
# active began, and flashes the target white for 100 ms once, keyed by the contact's tick, though
# the hit first shows in the target's state on the next tick; the counts of the match's own cues,
# which draw nothing headless, agree: one swing and one hit, two events, two cues.
func test_with_a_screen_a_light_draws_its_trail_and_flashes_the_target_once() -> void:
	await _start()
	var target := _match.spawn_fighter(Match.DUMMY_SLOT, multiplayer.get_unique_id())
	# 2,0 m dead ahead of the fighter, which looks down -Z: under the blade's tip.
	target.position = _fighter.position + Vector3(0.0, 0.0, -2.0)
	await get_tree().process_frame
	await get_tree().physics_frame
	var cues := ManeuverCues.new(_match.config, true)
	_match.add_child(cues)
	cues.watch(_fighter)
	cues.watch(target)
	_stand(STAND_TICKS)
	_fighter.input.press_light_attack()
	var light: AttackConfig = _match.combat.attacks[&"light_attack"]
	var swing := light.windup_ticks + light.active_ticks + light.recovery_ticks
	var flashed := 0
	for _tick: int in swing:
		_fighter.input.sample_frame(Vector2.ZERO, _fighter.state.facing_yaw)
		target.input.sample_frame(Vector2.ZERO, target.state.facing_yaw)
		NetfoxTicks.run_loop()
		flashed += 1 if target.flashing() else 0
	assert_int(target.state.health).is_equal(_match.combat.max_health - light.damage)
	assert_int(flashed).override_failure_message("the target never flashed").is_greater(0)
	var trails := cues.find_children("SwingTrail*", "MeshInstance3D", false, false)
	assert_int(trails.size()).is_equal(1)
	assert(trails[0] is MeshInstance3D, "a cue is a MeshInstance3D")
	var trail_material := (trails[0] as MeshInstance3D).material_override
	assert(trail_material is StandardMaterial3D, "the trail wears a StandardMaterial3D")
	assert_str(str((trail_material as StandardMaterial3D).albedo_color)).is_equal(
		str(Color(ManeuverCues.SWING_COLOUR, ManeuverCues.OPACITY))
	)
	assert_int(cues.presented).is_equal(2)
	assert_int(_match.cues.presented).is_equal(2)
	assert_int(_match.cues.events).is_equal(2)
	# The hit's event: the contact's stamp, first shown one tick later.
	var hits := ManeuverCues.shown_events(target).filter(
		func(event: ManeuverCues.Event) -> bool:
			return event.kind == ManeuverCues.Kind.HIT,
	)
	assert_int(hits.size()).is_equal(1)
	var hit: ManeuverCues.Event = hits[0]
	assert_int(hit.stamp).is_equal(target.state.hurt_tick)
	assert_int(hit.shows).is_equal(target.state.hurt_tick + 1)
	# The flash lasts 100 ms on screen, and the trail fades: both go away by themselves.
	await get_tree().create_timer(0.4).timeout
	assert_bool(target.flashing()).is_false()
	assert_int(cues.get_child_count()).is_equal(0)
	cues.free()


# Counts the times netfox simulates the tick a wall run began: the fresh one and every
# resimulation of the entry.
class EntryCounter:
	var again := 0

	var _entry: int
	var _fighter: Fighter


	func _init(fighter: Fighter, entry: int) -> void:
		_fighter = fighter
		_entry = entry


	func note(tick: int) -> void:
		if tick != _entry:
			return
		var state := _fighter.state
		if state.mode == FighterState.Mode.WALL_RUN and state.mode_since == _entry:
			again += 1


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
