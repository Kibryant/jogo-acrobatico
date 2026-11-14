# Criterion 6 of TASK-12.14: the sword on the crosshair under the permanent SyncTest (rede.md §4;
# DEC-0025; DEC-0027 §3), modelled on test/fighter/charged_sync_test.gd. The real Match runs in
# Sozinho with netfox's ticks advanced by hand (test/support/netfox_ticks.gd), and on every loop
# netfox is told to roll back 7 ticks, the depth of a 220 ms ping at 60 ticks; the observer
# (test/support/sync_observer.gd) compares every resimulation of a fighter at a tick with the
# first result of that tick, the whole state. The scenario, convergência: the target stands still
# with its axis on the attacker's final aim line, 1,84 m centre to centre. The attacker charges
# with the camera elsewhere and turns it through the windup until the crosshair is on the target:
# the swing's direction and the body follow, 23,578° to the right of the camera (combate.md, "A
# espada na mira"; DEC-0057), and the cut lands for 30 with no compensation. The camera then turns
# away through the rest of the active and the recovery, and neither the direction nor the body
# moves. A light does the same and lands for 12. Nothing may diverge; every cue once per event.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const SyncObserver := preload("res://test/support/sync_observer.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

## Ticks netfox rolls back on every loop: the depth of a 220 ms ping at 60 ticks (rede.md §4).
const DEPTH := 7

const SHOULDER_M := 0.8 # movimento.md, "Câmera": "Ombro", 0,8 m to the right
const CONVERGENCE_M := 2.0 # combate.md, "A lâmina e o contato": "Convergência", 2,0 m
# Arthur's median charged began 1,84 m centre to centre (DEC-0057, "Contexto"), inside the windows
# of the charged, 1,11 to 2,40 m, and of the light, 0,80 to 2,42 m (combate.md, "A espada na
# mira": "Onde pega").
const APART_M := 1.84
# The attacker on the flat floor west of the platform (charged_sync_test.gd); its camera ends on
# FINAL_YAW, and the target's axis is on the aim line of that yaw: 0,8 m to the right of the
# attacker's axis and sqrt(1,84² − 0,8²) m ahead, turned by the yaw (TASK-12.14 plan).
const ATTACKER_FEET := Vector3(-6.0, 0.0, 6.0)
const FINAL_YAW := 0.35 # rad, arithmetic
const TARGET_YAW := PI # the target looks toward +Z; where it looks changes nothing here
# The camera of the attacker, by loop. The charged is pressed on the 10th loop with the camera
# 0,6 rad to the left of the final yaw; its windup is 42 ticks (combate.md, "As fases do
# carregado"), and the camera turns evenly to the final yaw by the 40th loop, well inside the
# windup, and stays on it to the 62nd: the cut touches on an early active tick, around the 53rd.
# From the 62nd the camera turns away 0,03 rad per loop, through the freeze of the hit and the
# recovery. On the 200th it waits 0,3 rad to the left; the light is pressed on the 220th, its
# windup is 15 ticks ("O leve no tick": "As fases"), the camera is on the final yaw from the 230th
# to the 246th, past the light's active, and turns away again to the 270th.
const CHARGED_AT := 10
const CHARGED_ON_TARGET := 40
const CHARGED_AWAY := 62
const LIGHT_READY := 200
const LIGHT_AT := 220
const LIGHT_ON_TARGET := 230
const LIGHT_AWAY := 246
const LIGHT_DONE := 270
const CHARGED_SWEEP := 0.6 # rad, arithmetic
const LIGHT_SWEEP := 0.3 # rad, arithmetic
const AWAY_STEP := 0.03 # rad per loop, arithmetic
const LOOPS := 300

# What the scenario must have done: two swings that reach their active, two contacts, two hits,
# one of 30 and one of 12 (combate.md, "Os golpes e as defesas").
const SWINGS := 2
const CONTACTS := 2
const HITS := 2
const CHARGED_DAMAGE := 30
const LIGHT_DAMAGE := 12
# The windup ticks on which the camera, and so the swing, turned: the 30 loops of the charged's
# sweep and the 10 of the light's, give or take the tick the press takes to fire: at least 35.
const TURNING_WINDUP_TICKS_AT_LEAST := 35
const HAIR := 1e-3 # m: a millimetre of slack on the spawn distance, not a design number
const YAW_HAIR := 1e-4 # rad of slack on a yaw read on screen, as in attacking_dummy_test.gd

var _first_tick := 0
var _first_state_tick := 0


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	if NetworkRollback.before_loop.is_connected(_force_rollback):
		NetworkRollback.before_loop.disconnect(_force_rollback)
	NetfoxTicks.reset()


func test_a_camera_turning_through_the_windup_resimulates_with_zero_divergence() -> void:
	var game_match := await _match_with([ATTACKER_FEET, _target_feet()])
	var attacker := game_match.fighters[0]
	var target := game_match.fighters[1]
	var apart := attacker.position.distance_to(target.position)
	assert_float(apart).override_failure_message("%.4f m apart" % apart) \
			.is_equal_approx(APART_M, HAIR)
	assert_float(attacker.config.aim_side).is_equal_approx(SHOULDER_M, 1e-6)
	var swings := SwingWatch.new(attacker)
	var hits := HitWatch.new(target)
	var observer := _start(game_match, "convergência")
	for loop: int in LOOPS:
		attacker.input.sample_frame(Vector2.ZERO, camera_yaw(loop))
		if loop == CHARGED_AT:
			attacker.input.press_charged_attack()
		if loop == LIGHT_AT:
			attacker.input.press_light_attack()
		target.input.sample_frame(Vector2.ZERO, TARGET_YAW)
		NetfoxTicks.run_loop()
		swings.observe(camera_yaw(loop))
		hits.observe()
	observer.paths["swings"] = swings.swings
	observer.paths["contacts"] = swings.contacts
	observer.paths["turning_windup_ticks"] = swings.turning_windup_ticks
	observer.paths["hits"] = hits.hits
	observer.paths["hits_of_30"] = hits.hits_of_30
	observer.paths["hits_of_12"] = hits.hits_of_12
	observer.paths["cues_presented"] = game_match.cues.presented
	observer.paths["cue_events"] = game_match.cues.events
	_finish(observer, game_match)
	var message := "%s diverged:\n%s" % [observer.scenario, "\n".join(observer.shown)]
	assert_int(observer.mismatches).override_failure_message(message).is_equal(0)
	# The scenario went where it says: both swings turned through their windups and landed.
	assert_int(swings.swings).is_equal(SWINGS)
	assert_int(swings.contacts) \
			.override_failure_message("%d contacts: the swing did not land on the crosshair"
	% swings.contacts) \
			.is_equal(CONTACTS)
	assert_int(hits.hits).is_equal(HITS)
	assert_int(hits.hits_of_30).is_equal(1)
	assert_int(hits.hits_of_12).is_equal(1)
	assert_int(swings.turning_windup_ticks).is_greater_equal(TURNING_WINDUP_TICKS_AT_LEAST)
	# The direction on the first active tick of each swing: the final yaw minus the turn.
	var expected := FINAL_YAW - asin(SHOULDER_M / CONVERGENCE_M)
	assert_int(swings.active_yaws.size()).is_equal(SWINGS)
	for yaw: float in swings.active_yaws:
		var went := "the swing went to %.4f, expected %.4f" % [yaw, expected]
		assert_float(angle_difference(yaw, expected)).override_failure_message(went) \
				.is_equal_approx(0.0, YAW_HAIR)
	# The body looked along the swing on every tick of it, and from the first active tick on the
	# direction never moved, with the camera turning away.
	assert_array(swings.violations).override_failure_message("\n".join(swings.violations)) \
			.is_empty()
	assert_int(swings.fixed_ticks_with_the_camera_elsewhere).is_greater(0)
	# Both stayed on the floor.
	assert_int(observer.takeoffs).is_equal(0)
	# Every cue once per event, never again in the resimulations (DEC-0031 §6), and at least one
	# per swing and one per hit.
	var cues := "%d cues presented, %d events" % [
		observer.paths["cues_presented"],
		observer.paths["cue_events"],
	]
	assert_int(observer.paths["cues_presented"]).override_failure_message(cues).is_equal(
		observer.paths["cue_events"]
	)
	assert_int(observer.paths["cue_events"]).override_failure_message(cues).is_greater_equal(
		SWINGS + HITS
	)


# The camera's yaw of the attacker on a loop: see the constants.
static func camera_yaw(loop: int) -> float:
	if loop < CHARGED_AT:
		return FINAL_YAW + CHARGED_SWEEP
	if loop < CHARGED_ON_TARGET:
		var done := float(loop - CHARGED_AT) / float(CHARGED_ON_TARGET - CHARGED_AT)
		return FINAL_YAW + CHARGED_SWEEP * (1.0 - done)
	if loop < CHARGED_AWAY:
		return FINAL_YAW
	if loop < LIGHT_READY:
		return FINAL_YAW - AWAY_STEP * (loop - CHARGED_AWAY)
	if loop < LIGHT_AT:
		return FINAL_YAW + LIGHT_SWEEP
	if loop < LIGHT_ON_TARGET:
		var done := float(loop - LIGHT_AT) / float(LIGHT_ON_TARGET - LIGHT_AT)
		return FINAL_YAW + LIGHT_SWEEP * (1.0 - done)
	if loop < LIGHT_AWAY:
		return FINAL_YAW
	if loop < LIGHT_DONE:
		return FINAL_YAW - AWAY_STEP * (loop - LIGHT_AWAY)
	return FINAL_YAW


# The target's feet: its axis on the aim line of the attacker's final yaw, APART_M centre to
# centre.
func _target_feet() -> Vector3:
	var ahead := sqrt(APART_M * APART_M - SHOULDER_M * SHOULDER_M)
	return ATTACKER_FEET + Basis(Vector3.UP, FINAL_YAW) * Vector3(SHOULDER_M, 0.0, -ahead)


# A Match in the tree with a fighter of each slot standing at its start, placed before netfox
# records its first state: the RollbackSynchronizer registers with call_deferred. The ticks then
# run inside a physics frame (test/support/netfox_ticks.gd).
func _match_with(starts: Array[Vector3]) -> Match:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match := node as Match
	add_child(game_match)
	for slot: int in starts.size():
		var fighter := game_match.spawn_fighter(slot, multiplayer.get_unique_id())
		fighter.position = starts[slot]
	await get_tree().process_frame
	await get_tree().physics_frame
	return game_match


func _synchronizer(fighter: Fighter) -> RollbackSynchronizer:
	var node := fighter.get_node(^"RollbackSynchronizer")
	assert(node is RollbackSynchronizer, "the fighter must have a RollbackSynchronizer")
	return node as RollbackSynchronizer


# From the next loop on, netfox rolls back DEPTH ticks on every loop, watched by an observer.
func _start(game_match: Match, scenario: String) -> SyncObserver:
	_first_tick = NetworkTime.tick
	# netfox seeds a fighter's history at its synchronizer's spawn tick; nothing older can be
	# restored, so the forced rollback never asks for it.
	_first_state_tick = _first_tick
	for fighter: Fighter in game_match.fighters:
		var spawn_tick: int = _synchronizer(fighter).spawn_tick
		_first_state_tick = maxi(_first_state_tick, spawn_tick)
	NetworkRollback.before_loop.connect(_force_rollback)
	return SyncObserver.new(scenario, game_match.fighters)


# Ends the run: prints its summary, checks that netfox resimulated every tick the forced rollback
# owed, and frees the match.
func _finish(observer: SyncObserver, game_match: Match) -> void:
	NetworkRollback.before_loop.disconnect(_force_rollback)
	observer.stop()
	print(observer.summary())
	var owed := _owed_resimulations(NetworkTime.tick)
	var resimulated := observer.resimulated_ticks
	var message := "%s: %d ticks resimulated, %d owed" % [observer.scenario, resimulated, owed]
	assert_int(resimulated).override_failure_message(message).is_equal(owed)
	game_match.free()
	NetfoxTicks.reset()


# On netfox's before_loop. notify_resimulation_start keeps the oldest tick asked for, so the
# Match's own request, the first tick of the loop, composes with this one.
func _force_rollback() -> void:
	NetworkRollback.notify_resimulation_start(maxi(NetworkTime.tick - DEPTH, _first_state_tick))


# The resimulations netfox owes the run up to the loop that ends at `present`: the loop of a fresh
# tick t restores the state of max(t + 1 - DEPTH, first state) and simulates from there to t.
func _owed_resimulations(present: int) -> int:
	var owed := 0
	for tick: int in range(_first_tick, present):
		var from := mini(tick, maxi(tick + 1 - DEPTH, _first_state_tick))
		owed += tick - from
	return owed


# The attacker's swings, read on the fresh tick of every loop from the state on screen, every
# event counted by the state entering it against the loop before (F-187): swings whose active
# began, with the direction they began with; contacts stamped; windup ticks on which the direction
# turned; and, as violations, a tick of a swing on which the body does not look along it, or a
# tick from the first active one on which the direction moved.
class SwingWatch:
	var swings := 0
	var contacts := 0
	var turning_windup_ticks := 0
	var fixed_ticks_with_the_camera_elsewhere := 0
	var active_yaws: Array[float] = []
	var violations: Array[String] = []

	var _fighter: Fighter
	var _before: FighterState
	var _loop := 0


	func _init(watched: Fighter) -> void:
		_fighter = watched
		_before = watched.state.copy()


	func observe(camera: float) -> void:
		var state := _fighter.state
		var action := state.action
		var swinging := (
			action == FighterState.Action.WINDUP or action == FighterState.Action.ACTIVE
			or action == FighterState.Action.RECOVERY
		)
		var fixed := (
			action == FighterState.Action.ACTIVE or action == FighterState.Action.RECOVERY
		)
		if action == FighterState.Action.ACTIVE and _before.action != FighterState.Action.ACTIVE:
			swings += 1
			active_yaws.append(state.action_yaw)
		if state.contact_tick != _before.contact_tick and state.contact_tick != FighterState.NEVER:
			contacts += 1
		var turned := absf(angle_difference(state.action_yaw, _before.action_yaw)) > YAW_HAIR
		if (
			action == FighterState.Action.WINDUP
			and _before.action == FighterState.Action.WINDUP and turned
		):
			turning_windup_ticks += 1
		if swinging and absf(angle_difference(state.facing_yaw, state.action_yaw)) > YAW_HAIR:
			violations.append(
				"loop %d: facing %.4f, swing %.4f" % [_loop, state.facing_yaw, state.action_yaw]
			)
		if fixed and turned:
			violations.append(
				"loop %d: the direction moved from %.4f to %.4f after the windup"
				% [_loop, _before.action_yaw, state.action_yaw]
			)
		if fixed and absf(angle_difference(camera, FINAL_YAW)) > YAW_HAIR:
			fixed_ticks_with_the_camera_elsewhere += 1
		_before = state.copy()
		_loop += 1


# The target's hits, counted by the hurt stamp moving against the loop before (F-187), with the
# damage each took.
class HitWatch:
	var hits := 0
	var hits_of_30 := 0
	var hits_of_12 := 0

	var _fighter: Fighter
	var _before: FighterState


	func _init(watched: Fighter) -> void:
		_fighter = watched
		_before = watched.state.copy()


	func observe() -> void:
		var state := _fighter.state
		if state.hurt_tick != _before.hurt_tick:
			hits += 1
			var damage := _before.health - state.health
			if damage == CHARGED_DAMAGE:
				hits_of_30 += 1
			elif damage == LIGHT_DAMAGE:
				hits_of_12 += 1
		_before = state.copy()
