# Criterion 10 of TASK-12.1: the light attack under the permanent SyncTest (rede.md §4; DEC-0025;
# DEC-0027 §3), modelled on test/fighter/fighter_sync_test.gd. The real Match runs in Sozinho with
# netfox's ticks advanced by hand (test/support/netfox_ticks.gd), and on every loop netfox is told
# to roll back 7 ticks, the depth of a 220 ms ping at 60 ticks; the observer
# (test/support/sync_observer.gd) compares every resimulation of a fighter at a tick with the first
# result of that tick, the whole state, the new fields of the combat included, found by reflection.
# The scenario, leve: two fighters 2,0 m apart, within the reach of 2,43 m (combate.md, "A lâmina e
# o contato"), facing each other, swing four lights: both on the same tick, the trade (criterion 8),
# then one each; each hit takes 12, the health goes down to 76 and back to 100 two seconds after
# the last hit (partida.md, "A vida sem partida"). The two cues of the light, the arc's trail once
# per swing and the white flash once per hit, must be presented as many times as swings plus hits
# (visual-e-audio.md, "O leve na tela"; DEC-0031 §6). The poison: with the action, or the health,
# out of what netfox records, the test must diverge, or it has lost its teeth.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const SyncObserver := preload("res://test/support/sync_observer.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

## Ticks netfox rolls back on every loop: the depth of a 220 ms ping at 60 ticks (rede.md §4).
const DEPTH := 7

# Leve: the two fighters on the flat floor west of the platform, where the empurrão pushes
# (fighter_sync_test.gd), 2,0 m apart along Z: the one at z = 6 looks down -Z (yaw 0) at the one
# at z = 4, which looks back (yaw pi). The axis of each is under the other's tip at theta 0.
const LEVE_STARTS: Array[Vector3] = [Vector3(-6, 0, 6), Vector3(-6, 0, 4)]
const LEVE_YAWS: Array[float] = [0.0, PI]
const APART_M := 2.0
# The loops each fighter presses the light on: both on the 3rd, the trade; the first alone on the
# 60th and the second alone on the 120th, each well after its own swing of 33 ticks is over
# (15 / 6 / 12 at 60: combate.md, "Os golpes e as defesas"; DEC-0052).
const LEVE_PRESSES: Array[Array] = [[3, 60], [3, 120]]
# The last hit lands on the 120th loop's swing, about 17 ticks in; its refill comes 120 ticks later,
# before loop 260: 290 loops see both refills.
const LEVE_LOOPS := 290
# The self-tests need only the first swing and its hits: the trade is applied around the 21st loop.
const LEVE_SELF_TEST_LOOPS := 60

# What the scenario must have done: four swings, four contacts, four hits, one trade, two refills.
const SWINGS := 4
const HITS := 4
const TRADES := 1
const REFILLS := 2
# combate.md, "Os golpes e as defesas": 12 de dano; partida.md, "A vida sem partida": vida 100.
const LIGHT_DAMAGE := 12
const MAX_HEALTH := 100
const LOWEST_HEALTH := 76 # two hits each: 100 - 2 · 12, arithmetic
const HAIR := 1e-3 # m: a millimetre of slack on the spawn distance, not a design number

var _first_tick := 0
var _first_state_tick := 0


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	if NetworkRollback.before_loop.is_connected(_force_rollback):
		NetworkRollback.before_loop.disconnect(_force_rollback)
	NetfoxTicks.reset()


func test_the_light_scenario_resimulates_with_zero_divergence() -> void:
	var observer := await _leve(LEVE_LOOPS)
	var message := "%s diverged:\n%s" % [observer.scenario, "\n".join(observer.shown)]
	assert_int(observer.mismatches).override_failure_message(message).is_equal(0)
	# Four lights, each a contact and a hit of 12; the first two on the same tick, the trade; both
	# fighters down to 76 and back to 100 by the end.
	assert_int(observer.paths["swings"]).is_equal(SWINGS)
	assert_int(observer.paths["contacts"]).is_equal(HITS)
	assert_int(observer.paths["hits"]).is_equal(HITS)
	assert_int(observer.paths["hits_of_12"]).is_equal(HITS)
	assert_int(observer.paths["trades"]).is_equal(TRADES)
	assert_int(observer.paths["refills"]).is_equal(REFILLS)
	assert_int(observer.paths["lowest_health"]).is_equal(LOWEST_HEALTH)
	assert_int(observer.paths["final_health"]).is_equal(2 * MAX_HEALTH)
	assert_int(observer.paths["bots_done"]).is_equal(LEVE_STARTS.size())
	# Both stayed on the floor: the lights move nobody.
	assert_int(observer.takeoffs).is_equal(0)
	# One cue per swing and one per hit, never again in the resimulations (DEC-0031 §6).
	_assert_cues(observer, SWINGS + HITS)


# The poison of criterion 10: with the action out of what netfox records, a rollback restores the
# rest and keeps the present action, so the resimulated ticks of the first swing come out different.
func test_the_action_netfox_does_not_record_makes_the_sync_test_diverge() -> void:
	var observer := await _leve(LEVE_SELF_TEST_LOOPS, ":state:action")
	assert_int(observer.mismatches).is_greater(0)


# The health too: out of the recording, the ticks before the trade's damage come back at 88.
func test_the_health_netfox_does_not_record_makes_the_sync_test_diverge() -> void:
	var observer := await _leve(LEVE_SELF_TEST_LOOPS, ":state:health")
	assert_int(observer.mismatches).is_greater(0)


# As many cues as events, and as many events as swings plus hits; the cues are read before the
# match goes.
func _assert_cues(observer: SyncObserver, expected: int) -> void:
	var cues := "%s: %d cues presented, %d events, %d swings plus hits" % [
		observer.scenario,
		observer.paths["cues_presented"],
		observer.paths["cue_events"],
		expected,
	]
	assert_int(observer.paths["cues_presented"]).override_failure_message(cues).is_equal(
		observer.paths["cue_events"]
	)
	assert_int(observer.paths["cue_events"]).override_failure_message(cues).is_equal(expected)


func _leve(loops: int, hidden := "") -> SyncObserver:
	var game_match := await _match_with(LEVE_STARTS, hidden)
	var fighters := game_match.fighters
	var bots: Array[LightBot] = []
	var lights: Array[Lights] = []
	for slot: int in fighters.size():
		var press_loops: Array[int] = []
		press_loops.assign(LEVE_PRESSES[slot])
		bots.append(LightBot.new(fighters[slot], LEVE_YAWS[slot], press_loops))
		lights.append(Lights.new(fighters[slot]))
		assert_int(fighters[slot].state.health).override_failure_message("spawned without health") \
				.is_equal(MAX_HEALTH)
	var apart := fighters[0].position.distance_to(fighters[1].position)
	assert_float(apart).override_failure_message("not within reach").is_equal_approx(APART_M, HAIR)
	var observer := _start(game_match, "leve" if hidden.is_empty() else "leve without " + hidden)
	var trades := 0
	for _loop: int in loops:
		for bot: LightBot in bots:
			bot.drive()
		NetfoxTicks.run_loop()
		for path: Lights in lights:
			path.observe()
		var both_hit := lights[0].hit_now and lights[1].hit_now
		if both_hit and fighters[0].state.hurt_tick == fighters[1].state.hurt_tick:
			trades += 1
	for path: Lights in lights:
		path.add_to(observer.paths)
	observer.paths["trades"] = trades
	observer.paths["lowest_health"] = mini(lights[0].lowest_health, lights[1].lowest_health)
	observer.paths["final_health"] = fighters[0].state.health + fighters[1].state.health
	observer.paths["bots_done"] = 0
	for bot: LightBot in bots:
		observer.paths["bots_done"] += 1 if bot.done() else 0
	_add_cues(observer, game_match)
	return _finish(observer, game_match)


func _add_cues(observer: SyncObserver, game_match: Match) -> void:
	observer.paths["cues_presented"] = game_match.cues.presented
	observer.paths["cue_events"] = game_match.cues.events


# A Match in the tree with a fighter of each slot standing at its start, placed before netfox
# records its first state: the RollbackSynchronizer registers with call_deferred. The ticks then
# run inside a physics frame (test/support/netfox_ticks.gd). hidden, when not empty, is a state
# property taken out of what netfox records, for the self-tests.
func _match_with(starts: Array[Vector3], hidden := "") -> Match:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match := node as Match
	add_child(game_match)
	for slot: int in starts.size():
		var fighter := game_match.spawn_fighter(slot, multiplayer.get_unique_id())
		fighter.position = starts[slot]
		if not hidden.is_empty():
			_stop_recording(fighter, hidden)
	await get_tree().process_frame
	await get_tree().physics_frame
	return game_match


# Takes a property out of what netfox records for this fighter, before its synchronizer processes
# its settings; the production scene stays untouched.
func _stop_recording(fighter: Fighter, property: String) -> void:
	var synchronizer := _synchronizer(fighter)
	var kept: Array[String] = []
	for recorded: String in synchronizer.state_properties:
		if recorded != property:
			kept.append(recorded)
	assert(kept.size() < synchronizer.state_properties.size(), "%s is not recorded" % property)
	synchronizer.state_properties = kept


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
func _finish(observer: SyncObserver, game_match: Match) -> SyncObserver:
	NetworkRollback.before_loop.disconnect(_force_rollback)
	observer.stop()
	print(observer.summary())
	var owed := _owed_resimulations(NetworkTime.tick)
	var resimulated := observer.resimulated_ticks
	var message := "%s: %d ticks resimulated, %d owed" % [observer.scenario, resimulated, owed]
	assert_int(resimulated).override_failure_message(message).is_equal(owed)
	game_match.free()
	NetfoxTicks.reset()
	return observer


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


# A scripted player standing still, the camera held on the other fighter, who presses the light on
# the loops of its script through the call the mouse button uses too
# (FighterInput.press_light_attack; TASK-12.1 plan).
class LightBot:
	var fighter: Fighter
	var yaw: float
	var presses: Array[int]
	var loop := 0


	func _init(played: Fighter, camera_yaw: float, press_loops: Array[int]) -> void:
		fighter = played
		yaw = camera_yaw
		presses = press_loops


	func drive() -> void:
		fighter.input.sample_frame(Vector2.ZERO, yaw)
		if presses.has(loop):
			fighter.input.press_light_attack()
		loop += 1


	# Every press of the script was made.
	func done() -> bool:
		return presses.is_empty() or loop > presses[presses.size() - 1]


# The paths of one fighter through the lights, read on the fresh tick of every loop, from the
# state on screen: swings begun, contacts stamped, hits taken (the hurt stamp moved), hits that
# took exactly 12, refills to the max, and the lowest health seen.
class Lights:
	var swings := 0
	var contacts := 0
	var hits := 0
	var hits_of_12 := 0
	var refills := 0
	var lowest_health := MAX_HEALTH
	## The hurt stamp moved on the tick just simulated.
	var hit_now := false

	var _fighter: Fighter
	var _before: FighterState


	func _init(watched: Fighter) -> void:
		_fighter = watched
		_before = watched.state.copy()


	func observe() -> void:
		var state := _fighter.state
		var tick := NetworkTime.tick - 1
		if state.action == FighterState.Action.ACTIVE and state.action_since == tick:
			swings += 1
		if state.contact_tick == tick:
			contacts += 1
		hit_now = state.hurt_tick != _before.hurt_tick
		if hit_now:
			hits += 1
			if _before.health - state.health == LIGHT_DAMAGE:
				hits_of_12 += 1
		if state.health == MAX_HEALTH and _before.health < MAX_HEALTH:
			refills += 1
		lowest_health = mini(lowest_health, state.health)
		_before = state.copy()


	# Adds this fighter's counters to a scenario's paths, summed over its fighters.
	func add_to(paths: Dictionary[String, int]) -> void:
		var mine: Dictionary[String, int] = {
			"swings": swings,
			"contacts": contacts,
			"hits": hits,
			"hits_of_12": hits_of_12,
			"refills": refills,
		}
		for path: String in mine:
			if not paths.has(path):
				paths[path] = 0
			paths[path] += mine[path]
