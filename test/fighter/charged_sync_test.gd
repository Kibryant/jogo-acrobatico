# Criterion 7 of TASK-12.3: the charged attack, the armor, the parry and the feint under the
# permanent SyncTest (rede.md §4; DEC-0025; DEC-0027 §3), modelled on test/fighter/
# guard_sync_test.gd. The real Match runs in Sozinho with netfox's ticks advanced by hand (test/
# support/netfox_ticks.gd), and on every loop netfox is told to roll back 7 ticks, the depth of a
# 220 ms ping at 60 ticks; the observer (test/support/sync_observer.gd) compares every
# resimulation of a fighter at a tick with the first result of that tick, the whole state, the new
# stamps of the parry included, found by reflection. The scenario, carregado: two fighters 2,0 m
# apart, facing each other. Fighter 0 charges and fighter 1 parries it: fighter 0 is PARRIED,
# frozen 9 ticks alone, and fighter 1 punishes with a charged that lands for 30 before fighter 0's
# guard, held through the stun, could rise. Then fighter 0 charges again and fighter 1's light
# lands in its windup: the armor takes 12 without a stun, fighter 1 freezes 4 reading it, and the
# charged comes down for 30. Then fighter 1 charges and feints with the guard button: FEINT for 12
# ticks, 15 paid, the 25 never. Nothing may diverge; every cue once per event; and with the
# parry's stamp out of what netfox records, the test must diverge, or it has lost its teeth.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const SyncObserver := preload("res://test/support/sync_observer.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

## Ticks netfox rolls back on every loop: the depth of a 220 ms ping at 60 ticks (rede.md §4).
const DEPTH := 7

# Carregado: the two fighters on the flat floor west of the platform (fighter_sync_test.gd), 2,0 m
# apart along Z: the one at z = 6 looks down -Z (yaw 0) at the one at z = 4, which looks back
# (yaw pi); each is dead ahead of the other, in the front half (DEC-0054 §2; DEC-0056).
const STARTS: Array[Vector3] = [Vector3(-6, 0, 6), Vector3(-6, 0, 4)]
const YAWS: Array[float] = [0.0, PI]
const APART_M := 2.0
# The scripts, by loop: "charged", "parry", "light", "down" (the button goes down and stays
# held) and "up" (released), space-separated when several fall on one loop.
# Fighter 0 charges on the 10th loop: its windup is 42 ticks, its cut touches 2,0 m ahead on an
# early active tick, around the 53rd (combate.md, "As fases do carregado" and "O toque do
# carregado"). Fighter 1 presses the parry on the 45th: its window of 12 ticks, 45 to 56, holds the
# contact wherever in the first active ticks it falls ("A postura do parry"). Fighter 1 is free 12
# ticks after the contact, by the 66th, and charges on the 70th: its cut lands around the 113th,
# while fighter 0 is PARRIED until contact + 54 + 9, around the 116th ("Quem foi aparado"), its
# guard held since the 60th and unable to rise before the stun ends: the guaranteed punish.
# Fighter 0 releases the guard on the 180th and charges on the 200th; fighter 1's light on the
# 210th lands 17 ticks later, in fighter 0's windup of 200 to 241: the armor ("A armadura").
# Fighter 0's cut lands around the 243rd on fighter 1, free since its light. Fighter 1 charges on
# the 320th and presses the guard on the 330th, the 10th tick of the windup, within the 27: the
# feint; it releases on the 360th ("A finta").
const SCRIPTS: Array[Dictionary] = [
	{ 10: "charged", 60: "down", 180: "up", 200: "charged" },
	{ 45: "parry", 70: "charged", 210: "light", 320: "charged", 330: "down", 360: "up" },
]
# The last hit lands around the 243rd loop and its refill comes 120 ticks later (partida.md, "A
# vida sem partida"), before the 370th; 400 loops see both refills and the feint's end.
const LOOPS := 400
# The self-tests need the parry and the PARRIED: around the 53rd and 55th loops.
const SELF_TEST_LOOPS := 80

# What the scenario must have done: four swings that reach their active (the parried charged, the
# punish, the light and the armored charged; the feinted one never does), four contacts, one parry
# and one PARRIED, three hits (two of 30, one of 12), one of them on the armor, one feint.
const SWINGS := 4
const CONTACTS := 4
const PARRIES := 1
const HITS := 3
const HITS_OF_30 := 2
const HITS_OF_12 := 1
const ARMOR_HITS := 1
const FEINTS := 1
const REFILLS := 2
# combate.md, "Os golpes e as defesas": the charged's 30 and the light's 12 of damage; the parry's
# and the feint's 15 of stamina; partida.md, "A vida sem partida": vida 100.
const CHARGED_DAMAGE := 30
const LIGHT_DAMAGE := 12
const PARRY_COST := 15.0
const FEINT_COST := 15.0
const MAX_HEALTH := 100
const LOWEST_HEALTH := 58 # fighter 0: 100 - 30 - 12 before its refill, arithmetic
# combate.md, "O hitstop e o tremor": "Carregado acerta: 7 ticks", both; "Leve acerta: 4 ticks",
# both; "Parry: só quem foi aparado, 9 ticks"; "A armadura": whoever carries does not freeze, the
# light's attacker freezes the 4 of a hit. The freezes: the PARRIED one (9), the punish (7 + 7),
# the light on the armor (4, the attacker alone), the charged after it (7 + 7).
const CHARGED_HITSTOP_TICKS := 7
const LIGHT_HITSTOP_TICKS := 4
const PARRIED_HITSTOP_TICKS := 9
const FREEZES := 1 + 2 + 1 + 2
const FROZEN_TICKS := (
	PARRIED_HITSTOP_TICKS + 2 * CHARGED_HITSTOP_TICKS
	+ LIGHT_HITSTOP_TICKS + 2 * CHARGED_HITSTOP_TICKS
)
# combate.md, "O tranco e a vantagem": the charged's hitstun of 42 ticks from the contact, plus the
# hitstop (TASK-12.2 plan): the stun holds from the tick after the contact to contact + 42 + 7 - 1,
# 48 ticks, for each of the two charged that landed; the armor gives no hitstun.
const CHARGED_HITSTUN_TICKS := 42
const HITSTUN_TICKS_SEEN := HITS_OF_30 * (CHARGED_HITSTUN_TICKS + CHARGED_HITSTOP_TICKS - 1)
# combate.md, "O tranco e a vantagem", the row "Carregado aparado": "900 ms, 54 ticks, mais 9
# ticks de hitstop": the PARRIED holds from contact + 2 to contact + 54 + 9 - 1 at most, 61 ticks,
# cut short by the punish's hit.
const PARRIED_STUN_TICKS := 54
const PARRIED_TICKS_AT_MOST := PARRIED_STUN_TICKS + PARRIED_HITSTOP_TICKS - 2
# combate.md, "Os golpes e as defesas", the row "Parry": the window of 12 ticks, the stance over 12
# ticks after the contact when it parried, 39 ticks in all when it did not; here it parried, so the
# stance lasts at least the window and less than the whiff.
const PARRY_WINDOW_TICKS := 12
const PARRY_WHIFF_STANCE_TICKS := 39
# combate.md, "A finta": "FEINT desde esse tick, por 12 ticks".
const FEINT_TICKS := 12
const HAIR := 1e-3 # m: a millimetre of slack on the spawn distance, not a design number

var _first_tick := 0
var _first_state_tick := 0


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	if NetworkRollback.before_loop.is_connected(_force_rollback):
		NetworkRollback.before_loop.disconnect(_force_rollback)
	NetfoxTicks.reset()


func test_the_charged_scenario_resimulates_with_zero_divergence() -> void:
	var observer := await _carregado(LOOPS)
	var message := "%s diverged:\n%s" % [observer.scenario, "\n".join(observer.shown)]
	assert_int(observer.mismatches).override_failure_message(message).is_equal(0)
	assert_int(observer.paths["swings"]).is_equal(SWINGS)
	assert_int(observer.paths["contacts"]).is_equal(CONTACTS)
	assert_int(observer.paths["parries"]).is_equal(PARRIES)
	assert_int(observer.paths["parries_of_15"]).is_equal(PARRIES)
	assert_int(observer.paths["parried"]).is_equal(PARRIES)
	assert_int(observer.paths["hits"]).is_equal(HITS)
	assert_int(observer.paths["hits_of_30"]).is_equal(HITS_OF_30)
	assert_int(observer.paths["hits_of_12"]).is_equal(HITS_OF_12)
	assert_int(observer.paths["armor_hits"]).is_equal(ARMOR_HITS)
	assert_int(observer.paths["feints"]).is_equal(FEINTS)
	assert_int(observer.paths["feints_of_15"]).is_equal(FEINTS)
	assert_int(observer.paths["feint_ticks"]).is_equal(FEINT_TICKS)
	assert_int(observer.paths["refills"]).is_equal(REFILLS)
	assert_int(observer.paths["lowest_health"]).is_equal(LOWEST_HEALTH)
	assert_int(observer.paths["final_health"]).is_equal(2 * MAX_HEALTH)
	# The freezes: one start per fighter per outcome, the PARRIED one alone, the carrier of the
	# armor never.
	assert_int(observer.paths["freezes"]).is_equal(FREEZES)
	assert_int(observer.paths["frozen_ticks"]).is_equal(FROZEN_TICKS)
	# The stuns, counted on the fresh ticks.
	assert_int(observer.paths["hitstun_ticks"]).is_equal(HITSTUN_TICKS_SEEN)
	assert_int(observer.paths["parried_ticks"]).is_greater(0)
	assert_int(observer.paths["parried_ticks"]).is_less_equal(PARRIED_TICKS_AT_MOST)
	assert_int(observer.paths["parry_ticks"]).is_greater_equal(PARRY_WINDOW_TICKS)
	assert_int(observer.paths["parry_ticks"]).is_less(PARRY_WHIFF_STANCE_TICKS)
	assert_int(observer.paths["bots_done"]).is_equal(STARTS.size())
	# Both stayed on the floor: charged, parries, feints and freezes move nobody.
	assert_int(observer.takeoffs).is_equal(0)
	# Every cue once per event, never again in the resimulations (DEC-0031 §6), and at least one
	# per swing and one per hit.
	_assert_cues(observer, SWINGS + HITS)


# The poison of criterion 7: with the parry's stamp out of what netfox records, a rollback across
# the parry restores the rest and keeps the present stamp, so the resimulated ticks before the
# contact carry a parry that had not happened, and the test must diverge; the parried one's stamp
# too.
func test_the_parry_stamps_netfox_does_not_record_make_the_sync_test_diverge(
	hidden: String,
	_test_parameters := [[":state:parry_tick"], [":state:parried_tick"]],
) -> void:
	var observer := await _carregado(SELF_TEST_LOOPS, hidden)
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


func _carregado(loops: int, hidden := "") -> SyncObserver:
	var game_match := await _match_with(STARTS, hidden)
	var fighters := game_match.fighters
	var bots: Array[ChargedBot] = []
	var exchanges: Array[Exchanges] = []
	for slot: int in fighters.size():
		var script: Dictionary[int, String] = { }
		var scripted: Dictionary = SCRIPTS[slot]
		for loop: int in scripted:
			var actions: String = scripted[loop]
			script[loop] = actions
		bots.append(ChargedBot.new(fighters[slot], YAWS[slot], script))
		exchanges.append(Exchanges.new(fighters[slot]))
		assert_int(fighters[slot].state.health).override_failure_message("spawned without health") \
				.is_equal(MAX_HEALTH)
	var apart := fighters[0].position.distance_to(fighters[1].position)
	assert_float(apart).override_failure_message("not within reach").is_equal_approx(APART_M, HAIR)
	var observer := _start(
		game_match,
		"carregado" if hidden.is_empty() else "carregado without " + hidden,
	)
	for _loop: int in loops:
		for bot: ChargedBot in bots:
			bot.drive()
		NetfoxTicks.run_loop()
		for path: Exchanges in exchanges:
			path.observe()
	for path: Exchanges in exchanges:
		path.add_to(observer.paths)
	observer.paths["lowest_health"] = mini(exchanges[0].lowest_health, exchanges[1].lowest_health)
	observer.paths["final_health"] = fighters[0].state.health + fighters[1].state.health
	observer.paths["bots_done"] = 0
	for bot: ChargedBot in bots:
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


# A scripted player standing still, the camera held on the other fighter, who presses the charged,
# the parry and the light through the calls the keys use too (FighterInput.press_charged_attack,
# press_parry, press_light_attack), and works the guard button as the right mouse button does: the
# press (FighterInput.press_guard) together with the hold (hold_guard) when it goes down, the hold
# released when it goes up (TASK-12.3 plan; DEC-0056 §1).
class ChargedBot:
	var fighter: Fighter
	var yaw: float
	var moves: Dictionary[int, String]
	var loop := 0


	func _init(played: Fighter, camera_yaw: float, scripted: Dictionary[int, String]) -> void:
		fighter = played
		yaw = camera_yaw
		moves = scripted


	func drive() -> void:
		fighter.input.sample_frame(Vector2.ZERO, yaw)
		if moves.has(loop):
			for action: String in moves[loop].split(" ", false):
				match action:
					"charged":
						fighter.input.press_charged_attack()
					"parry":
						fighter.input.press_parry()
					"light":
						fighter.input.press_light_attack()
					"down":
						fighter.input.press_guard()
						fighter.input.hold_guard(true)
					"up":
						fighter.input.hold_guard(false)
					_:
						assert(false, "unknown action %s" % action)
		loop += 1


	# Every action of the script was made.
	func done() -> bool:
		var last := 0
		for scripted_loop: int in moves:
			last = maxi(last, scripted_loop)
		return loop > last


# The paths of one fighter through the exchanges, read on the fresh tick of every loop, from the
# state on screen, every event counted by the state entering it against the tick before (F-187):
# swings whose active began, contacts stamped, parries (the parry stamp moved) and parries that
# cost exactly 15, PARRIED (the parried stamp moved), hits (the hurt stamp moved), hits of exactly
# 30 and of 12, hits taken on the armor (the hurt stamp moved with no stun), feints begun and
# feints that cost exactly 15, freezes begun and ticks frozen, ticks in each stance and stun,
# refills to the max, and the lowest health seen.
class Exchanges:
	var swings := 0
	var contacts := 0
	var parries := 0
	var parries_of_15 := 0
	var parried := 0
	var hits := 0
	var hits_of_30 := 0
	var hits_of_12 := 0
	var armor_hits := 0
	var feints := 0
	var feints_of_15 := 0
	var freezes := 0
	var frozen_ticks := 0
	var hitstun_ticks := 0
	var parried_ticks := 0
	var parry_ticks := 0
	var feint_ticks := 0
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
		var paid := Stamina.at(_before, _config, tick) - Stamina.at(state, _config, tick)
		if (
			state.action == FighterState.Action.ACTIVE
			and _before.action != FighterState.Action.ACTIVE
		):
			swings += 1
		if state.contact_tick == tick:
			contacts += 1
		if state.parry_tick != _before.parry_tick:
			parries += 1
		if (
			state.action == FighterState.Action.PARRY
			and _before.action != FighterState.Action.PARRY and absf(paid - PARRY_COST) < 1e-6
		):
			parries_of_15 += 1
		if state.parried_tick != _before.parried_tick:
			parried += 1
		if state.hurt_tick != _before.hurt_tick:
			hits += 1
			var damage := _before.health - state.health
			if damage == CHARGED_DAMAGE:
				hits_of_30 += 1
			elif damage == LIGHT_DAMAGE:
				hits_of_12 += 1
			if not Combat.stunned(state):
				armor_hits += 1
		if (
			state.action == FighterState.Action.FEINT
			and _before.action != FighterState.Action.FEINT
		):
			feints += 1
			if absf(paid - FEINT_COST) < 1e-6:
				feints_of_15 += 1
		if state.frozen_until_tick > _before.frozen_until_tick:
			freezes += 1
		if tick <= state.frozen_until_tick:
			frozen_ticks += 1
		match state.action:
			FighterState.Action.HITSTUN:
				hitstun_ticks += 1
			FighterState.Action.PARRIED:
				parried_ticks += 1
			FighterState.Action.PARRY:
				parry_ticks += 1
			FighterState.Action.FEINT:
				feint_ticks += 1
		if state.health == MAX_HEALTH and _before.health < MAX_HEALTH:
			refills += 1
		lowest_health = mini(lowest_health, state.health)
		_before = state.copy()


	# Adds this fighter's counters to a scenario's paths, summed over its fighters.
	func add_to(paths: Dictionary[String, int]) -> void:
		var mine: Dictionary[String, int] = {
			"swings": swings,
			"contacts": contacts,
			"parries": parries,
			"parries_of_15": parries_of_15,
			"parried": parried,
			"hits": hits,
			"hits_of_30": hits_of_30,
			"hits_of_12": hits_of_12,
			"armor_hits": armor_hits,
			"feints": feints,
			"feints_of_15": feints_of_15,
			"freezes": freezes,
			"frozen_ticks": frozen_ticks,
			"hitstun_ticks": hitstun_ticks,
			"parried_ticks": parried_ticks,
			"parry_ticks": parry_ticks,
			"feint_ticks": feint_ticks,
			"refills": refills,
		}
		for path: String in mine:
			if not paths.has(path):
				paths[path] = 0
			paths[path] += mine[path]
