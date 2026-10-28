# Criterion 8 of TASK-12.2: the guard, the block, the stun and the hitstop under the permanent
# SyncTest (rede.md §4; DEC-0025; DEC-0027 §3), modelled on test/fighter/light_attack_sync_test.gd.
# The real Match runs in Sozinho with netfox's ticks advanced by hand (test/support/
# netfox_ticks.gd), and on every loop netfox is told to roll back 7 ticks, the depth of a 220 ms
# ping at 60 ticks; the
# observer (test/support/sync_observer.gd) compares every resimulation of a fighter at a tick with
# the first result of that tick, the whole state, the new fields of the guard included, found by
# reflection. The scenario, guarda: two fighters 2,0 m apart, facing each other, trade four lights:
# the first into a guard held before it, blocked; the second after the guard is released, a hit; the
# third back at the first, a hit; the fourth into a guard raised again, blocked. Each block costs 5
# and freezes both for 2 ticks, one tick apart; each hit takes 12 and freezes both for 4
# (combate.md, "O hitstop e o tremor"); the hitstun of 24 and the blockstun of 15 count from the
# contact, plus the hitstop ("O tranco e a vantagem"). Nothing may diverge; and with the freeze's
# field out of what netfox records, the test must diverge, or it has lost its teeth.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const SyncObserver := preload("res://test/support/sync_observer.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

## Ticks netfox rolls back on every loop: the depth of a 220 ms ping at 60 ticks (rede.md §4).
const DEPTH := 7

# Guarda: the two fighters on the flat floor west of the platform (fighter_sync_test.gd), 2,0 m
# apart along Z: the one at z = 6 looks down -Z (yaw 0) at the one at z = 4, which looks back
# (yaw pi); each is dead ahead of the other, in the front half of its guard (DEC-0054 §2).
const GUARD_STARTS: Array[Vector3] = [Vector3(-6, 0, 6), Vector3(-6, 0, 4)]
const GUARD_YAWS: Array[float] = [0.0, PI]
const APART_M := 2.0
# The loops each fighter holds (true) or releases (false) the guard on, and presses the light on.
# Fighter 1 holds from the 1st loop: its guard is up 6 ticks later (combate.md, "O bloqueio, a
# guarda andando e a stamina"), long before fighter 0's first light, pressed on the 10th, lands,
# some 17 ticks later (combat_contact_test.gd): the block. Fighter 1 releases on the 70th, and
# fighter 0's second light, on the 80th, hits. Fighter 1's light on the 150th hits fighter 0, who
# has no guard. Fighter 0 holds from the 220th, and fighter 1's light on the 230th is blocked.
# Every swing of 33 ticks and every stun of up to 28 are over before the next press.
const GUARD_HOLDS: Array[Dictionary] = [{ 220: true }, { 1: true, 70: false }]
const GUARD_PRESSES: Array[Array] = [[10, 80], [150, 230]]
# The last hit lands around the 167th loop, its refill 120 ticks later (partida.md, "A vida sem
# partida"), before the 300th; 330 loops see both refills and the last block's stun.
const GUARD_LOOPS := 330
# The self-tests need the first block and the first hit: around the 27th and the 97th loops.
const GUARD_SELF_TEST_LOOPS := 110

# What the scenario must have done: four swings and four contacts, two blocks and two hits.
const SWINGS := 4
const BLOCKS := 2
const HITS := 2
const REFILLS := 2
# combate.md, "Os golpes e as defesas": 12 de dano; "Bloqueio": 5 por leve bloqueado;
# partida.md, "A vida sem partida": vida 100.
const LIGHT_DAMAGE := 12
const BLOCK_COST := 5.0
const MAX_HEALTH := 100
const LOWEST_HEALTH := 88 # one hit each: 100 - 12, arithmetic
# combate.md, "O hitstop e o tremor": "Leve acerta: 67 ms, 4 ticks"; "Leve bloqueado: 33 ms, 2
# ticks"; both fighters freeze that many ticks (DEC-0055 §4): 2 · 4 per hit and 2 · 2 per block.
const HITSTOP_HIT_TICKS := 4
const HITSTOP_BLOCK_TICKS := 2
const FROZEN_TICKS := HITS * 2 * HITSTOP_HIT_TICKS + BLOCKS * 2 * HITSTOP_BLOCK_TICKS
const FREEZES := 2 * (HITS + BLOCKS) # one freeze start per fighter per outcome
# combate.md, "O tranco e a vantagem": the hitstun of 24 ticks and the blockstun of 15, from the
# contact, plus the hitstop (TASK-12.2 plan): the stun holds from the tick after the contact to
# contact + 24 + 4 - 1 (27 ticks) or contact + 15 + 2 - 1 (16 ticks).
const HITSTUN_TICKS := 24
const BLOCKSTUN_TICKS := 15
const HITSTUN_TICKS_SEEN := HITS * (HITSTUN_TICKS + HITSTOP_HIT_TICKS - 1)
const BLOCKSTUN_TICKS_SEEN := BLOCKS * (BLOCKSTUN_TICKS + HITSTOP_BLOCK_TICKS - 1)
const HAIR := 1e-3 # m: a millimetre of slack on the spawn distance, not a design number

var _first_tick := 0
var _first_state_tick := 0


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	if NetworkRollback.before_loop.is_connected(_force_rollback):
		NetworkRollback.before_loop.disconnect(_force_rollback)
	NetfoxTicks.reset()


func test_the_guard_scenario_resimulates_with_zero_divergence() -> void:
	var observer := await _guarda(GUARD_LOOPS)
	var message := "%s diverged:\n%s" % [observer.scenario, "\n".join(observer.shown)]
	assert_int(observer.mismatches).override_failure_message(message).is_equal(0)
	# Four lights: two blocked, two hits of 12; both fighters down to 88 and back to 100.
	assert_int(observer.paths["swings"]).is_equal(SWINGS)
	assert_int(observer.paths["contacts"]).is_equal(SWINGS)
	assert_int(observer.paths["blocks"]).is_equal(BLOCKS)
	assert_int(observer.paths["hits"]).is_equal(HITS)
	assert_int(observer.paths["hits_of_12"]).is_equal(HITS)
	assert_int(observer.paths["blocks_of_5"]).is_equal(BLOCKS)
	assert_int(observer.paths["refills"]).is_equal(REFILLS)
	assert_int(observer.paths["lowest_health"]).is_equal(LOWEST_HEALTH)
	assert_int(observer.paths["final_health"]).is_equal(2 * MAX_HEALTH)
	# The freezes: one start per fighter per outcome, 4 ticks per hit and 2 per block for each.
	assert_int(observer.paths["freezes"]).is_equal(FREEZES)
	assert_int(observer.paths["frozen_ticks"]).is_equal(FROZEN_TICKS)
	# The stuns, counted on the fresh ticks.
	assert_int(observer.paths["hitstun_ticks"]).is_equal(HITSTUN_TICKS_SEEN)
	assert_int(observer.paths["blockstun_ticks"]).is_equal(BLOCKSTUN_TICKS_SEEN)
	assert_int(observer.paths["guard_ticks"]).is_greater(0)
	assert_int(observer.paths["bots_done"]).is_equal(GUARD_STARTS.size())
	# Both stayed on the floor: lights, blocks and freezes move nobody.
	assert_int(observer.takeoffs).is_equal(0)
	# Every cue once per event, never again in the resimulations (DEC-0031 §6), and at least the
	# arc's trail per swing and the flash per hit of TASK-12.1.
	_assert_cues(observer, SWINGS + HITS)


# The poison of criterion 8: with the freeze's field out of what netfox records, a rollback across
# a freeze restores the rest and keeps the present freeze, so the resimulated ticks come out frozen
# when the fresh ones were not, and the test must diverge.
func test_the_freeze_netfox_does_not_record_makes_the_sync_test_diverge() -> void:
	var observer := await _guarda(GUARD_SELF_TEST_LOOPS, ":state:frozen_until_tick")
	assert_int(observer.mismatches).is_greater(0)


# The stun's end and the block's stamp too: out of the recording, the ticks before the contact
# come back with the stamps of after it.
func test_the_stun_and_the_block_stamp_netfox_does_not_record_make_the_sync_test_diverge(
	hidden: String,
	_test_parameters := [[":state:stun_until_tick"], [":state:block_tick"]],
) -> void:
	var observer := await _guarda(GUARD_SELF_TEST_LOOPS, hidden)
	assert_int(observer.mismatches).is_greater(0)


# As many cues as events, and at least as many events as `at_least`; the cues are read before the
# match goes.
func _assert_cues(observer: SyncObserver, at_least: int) -> void:
	var cues := "%s: %d cues presented, %d events, at least %d expected" % [
		observer.scenario,
		observer.paths["cues_presented"],
		observer.paths["cue_events"],
		at_least,
	]
	assert_int(observer.paths["cues_presented"]).override_failure_message(cues).is_equal(
		observer.paths["cue_events"]
	)
	assert_int(observer.paths["cue_events"]).override_failure_message(cues).is_greater_equal(
		at_least
	)


func _guarda(loops: int, hidden := "") -> SyncObserver:
	var game_match := await _match_with(GUARD_STARTS, hidden)
	var fighters := game_match.fighters
	var bots: Array[GuardBot] = []
	var exchanges: Array[Exchanges] = []
	for slot: int in fighters.size():
		var press_loops: Array[int] = []
		press_loops.assign(GUARD_PRESSES[slot])
		var holds: Dictionary[int, bool] = { }
		var scripted: Dictionary = GUARD_HOLDS[slot]
		for hold_loop: int in scripted:
			var held: bool = scripted[hold_loop]
			holds[hold_loop] = held
		bots.append(GuardBot.new(fighters[slot], GUARD_YAWS[slot], press_loops, holds))
		exchanges.append(Exchanges.new(fighters[slot]))
		assert_int(fighters[slot].state.health).override_failure_message("spawned without health") \
				.is_equal(MAX_HEALTH)
	var apart := fighters[0].position.distance_to(fighters[1].position)
	assert_float(apart).override_failure_message("not within reach").is_equal_approx(APART_M, HAIR)
	var observer := _start(
		game_match,
		"guarda" if hidden.is_empty() else "guarda without " + hidden,
	)
	for _loop: int in loops:
		for bot: GuardBot in bots:
			bot.drive()
		NetfoxTicks.run_loop()
		for path: Exchanges in exchanges:
			path.observe()
	for path: Exchanges in exchanges:
		path.add_to(observer.paths)
	observer.paths["lowest_health"] = mini(exchanges[0].lowest_health, exchanges[1].lowest_health)
	observer.paths["final_health"] = fighters[0].state.health + fighters[1].state.health
	observer.paths["bots_done"] = 0
	for bot: GuardBot in bots:
		observer.paths["bots_done"] += 1 if bot.done() else 0
	observer.paths["cues_presented"] = game_match.cues.presented
	observer.paths["cue_events"] = game_match.cues.events
	return _finish(observer, game_match)


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


# A scripted player standing still, the camera held on the other fighter, who holds or releases
# the guard button on the loops of its script, the way the right mouse button does
# (FighterInput.hold_guard; TASK-12.2 plan), and presses the light on others
# (FighterInput.press_light_attack).
class GuardBot:
	var fighter: Fighter
	var yaw: float
	var presses: Array[int]
	var holds: Dictionary[int, bool]
	var loop := 0


	func _init(
		played: Fighter,
		camera_yaw: float,
		press_loops: Array[int],
		hold_loops: Dictionary[int, bool],
	) -> void:
		fighter = played
		yaw = camera_yaw
		presses = press_loops
		holds = hold_loops


	func drive() -> void:
		fighter.input.sample_frame(Vector2.ZERO, yaw)
		if holds.has(loop):
			fighter.input.hold_guard(holds[loop])
		if presses.has(loop):
			fighter.input.press_light_attack()
		loop += 1


	# Every press and every hold of the script was made.
	func done() -> bool:
		var last := 0
		for press: int in presses:
			last = maxi(last, press)
		for hold: int in holds:
			last = maxi(last, hold)
		return loop > last


# The paths of one fighter through the exchanges, read on the fresh tick of every loop, from the
# state on screen: swings begun, contacts stamped, hits taken (the hurt stamp moved) and hits of
# exactly 12, blocks (the block stamp moved) and blocks that cost exactly 5, freezes begun (the
# freeze's end moved) and ticks frozen, ticks in each stun and with the guard, refills to the max,
# and the lowest health seen.
class Exchanges:
	var swings := 0
	var contacts := 0
	var hits := 0
	var hits_of_12 := 0
	var blocks := 0
	var blocks_of_5 := 0
	var freezes := 0
	var frozen_ticks := 0
	var hitstun_ticks := 0
	var blockstun_ticks := 0
	var guard_ticks := 0
	var refills := 0
	var lowest_health := MAX_HEALTH

	var _fighter: Fighter
	var _before: FighterState
	var _config: MovementConfig


	func _init(watched: Fighter) -> void:
		_fighter = watched
		_before = watched.state.copy()
		_config = watched.config


	func observe() -> void:
		var state := _fighter.state
		var tick := NetworkTime.tick - 1
		if state.action == FighterState.Action.ACTIVE and state.action_since == tick:
			swings += 1
		if state.contact_tick == tick:
			contacts += 1
		if state.hurt_tick != _before.hurt_tick:
			hits += 1
			if _before.health - state.health == LIGHT_DAMAGE:
				hits_of_12 += 1
		if state.block_tick != _before.block_tick:
			blocks += 1
			var paid := Stamina.at(_before, _config, tick) - Stamina.at(state, _config, tick)
			if absf(paid - BLOCK_COST) < 1e-6:
				blocks_of_5 += 1
		if state.frozen_until_tick > _before.frozen_until_tick:
			freezes += 1
		if tick <= state.frozen_until_tick:
			frozen_ticks += 1
		match state.action:
			FighterState.Action.HITSTUN:
				hitstun_ticks += 1
			FighterState.Action.BLOCKSTUN:
				blockstun_ticks += 1
			FighterState.Action.BLOCK:
				guard_ticks += 1
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
			"blocks": blocks,
			"blocks_of_5": blocks_of_5,
			"freezes": freezes,
			"frozen_ticks": frozen_ticks,
			"hitstun_ticks": hitstun_ticks,
			"blockstun_ticks": blockstun_ticks,
			"guard_ticks": guard_ticks,
			"refills": refills,
		}
		for path: String in mine:
			if not paths.has(path):
				paths[path] = 0
			paths[path] += mine[path]
