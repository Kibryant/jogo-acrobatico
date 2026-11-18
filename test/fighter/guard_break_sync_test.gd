# Criterion 7 of TASK-12.4: the guard break, the grab and the tech under the permanent SyncTest
# (rede.md §4; DEC-0025; DEC-0027 §3), modelled on test/fighter/charged_sync_test.gd. The real
# Match runs in Sozinho with netfox's ticks advanced by hand (test/support/netfox_ticks.gd), and on
# every loop netfox is told to roll back 7 ticks, the depth of a 220 ms ping at 60 ticks; the
# observer (test/support/sync_observer.gd) compares every resimulation of a fighter at a tick with
# the first result of that tick, the whole state, the two new stamps of the grab included, found by
# reflection. The scenario, quebra: two fighters 1,05 m apart, facing each other. Fighter 0 breaks
# the guard of fighter 1, which answers with the tech: both are held, and both let go, fighter 1
# two ticks ahead. Then fighter 0 breaks it again and fighter 1 does not answer: fighter 0 lets go
# after the hold and its charged lands for 30 while fighter 1 is still GRABBED, its guard held and
# unable to rise. Nothing may diverge; every cue once per event; and with the grab's stamp, or the
# tech's, out of what netfox records, the test must diverge, or it has lost its teeth.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const SyncObserver := preload("res://test/support/sync_observer.gd")
const GrabRig := preload("res://test/core/fighter/grab_rig.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

## Ticks netfox rolls back on every loop: the depth of a 220 ms ping at 60 ticks (rede.md §4).
const DEPTH := 7

# Quebra: the two fighters on the flat floor west of the platform (fighter_sync_test.gd), 1,05 m
# apart along Z: the one at z = 6 sends its hand down -Z (yaw 0) at the one at z = 4,95, which
# looks back at it (yaw pi). combate.md, "A mão": straight along the hand, a target 1,05 m away is
# first touched by the 4th slice (0,8 m, 0,25 m from its axis; the 3rd ends 0,45 m from it), so
# the contact comes 21 + 3 ticks after the press. The capsules, 0,35 m of radius each, do not
# touch.
const STARTS: Array[Vector3] = [Vector3(-6, 0, 6), Vector3(-6, 0, 4.95)]
const YAWS: Array[float] = [0.0, PI]
const APART_M := 1.05
# movimento.md, "Câmera": the shoulder; combate.md, "A lâmina e o contato": "Convergência: 2,0 na
# espada; 1,2 na quebra". Each camera looks asin(shoulder / convergence) to the left of the move it
# sends at the other (DEC-0057; DEC-0058 §2).
const HAND_CONVERGENCE_M := 1.2
const SWORD_CONVERGENCE_M := 2.0
# The scripts, by loop: "break" (the guard break's key, which is the tech's too), "charged",
# "sword" (the camera turns to the sword's aim), "down" (the guard button goes down and stays
# held) and "up" (released).
# Fighter 0 breaks on the 10th loop: the contact comes around the 34th, and both are held to its
# + 23. Fighter 1 presses the same key on the 45th, some 11 ticks after the contact, inside the
# hold: the tech. It is free on the contact + 24, fighter 0 on + 26, by the 60th.
# Fighter 0 breaks again on the 100th: the contact comes around the 124th, and fighter 1 does not
# answer. Fighter 0 is free on that contact + 24, the 148th, and charges on the 150th, inside the
# contact + 24 to + 33 of the guaranteed punish: its cut comes down from the 192nd, before fighter
# 1 could act again on the contact + 76, the 200th ("O tech": "começado até C + 33, ainda pega
# antes de C + 76"). Fighter 1 holds the guard from the 130th: it cannot rise while GRABBED, and
# the cut lands for 30. It lets the guard go on the 260th.
const SCRIPTS: Array[Dictionary] = [
	{ 10: "break", 100: "break", 126: "sword", 150: "charged" },
	{ 45: "break", 130: "down", 260: "up" },
]
# The hit lands around the 192nd loop and its refill comes 120 ticks later (partida.md, "A vida
# sem partida"), around the 313th; 340 loops see it.
const LOOPS := 340
# The self-tests need the first grab and its tech: around the 34th and the 45th loops.
const SELF_TEST_LOOPS := 70

# What the scenario must have done: two guard breaks, each paid 15 on its fire tick; two grabs, so
# two fighters GRABBED and two GRABBING and two grab stamps; one tech, free; one hit, of 30, and
# no block; one refill.
const GUARD_BREAKS := 2
const GRABS := 2
const TECHS := 1
const HITS := 1
const REFILLS := 1
# combate.md, "Os golpes e as defesas": the guard break costs 15 and takes no health; the charged
# takes 30; partida.md, "A vida sem partida": vida 100.
const GUARD_BREAK_COST := 15.0
const CHARGED_DAMAGE := 30
const MAX_HEALTH := 100
const LOWEST_HEALTH := 70 # fighter 1: 100 - 30 before its refill, arithmetic
# combate.md, "O hitstop e o tremor": "Quebra pega: os dois, 4 ticks"; "Carregado acerta: os dois,
# 7 ticks". The freezes: two per grab and two for the charged that lands.
const GRAB_HITSTOP_TICKS := 4
const CHARGED_HITSTOP_TICKS := 7
const FREEZES := 2 * GRABS + 2
const FROZEN_TICKS := 2 * GRABS * GRAB_HITSTOP_TICKS + 2 * CHARGED_HITSTOP_TICKS
# combate.md, "O agarrão" and "O tech", with C the contact: whoever grabbed is GRABBING from C + 2
# to C + 25 with a tech, 24 ticks, and from C + 2 to C + 23 without one, 22 ticks. Whoever was
# grabbed is GRABBED from C + 1 to C + 23 with a tech, 23 ticks, and without one until the hit
# takes the place of the grab, the tick after the cut's contact, C + 75 at the latest.
const GRABBING_TICKS := 24 + 22
const GRABBED_TICKS_WITH_A_TECH := 23
const GRABBED_TICKS_AT_MOST := GRABBED_TICKS_WITH_A_TECH + 75
# The charged swings once and lands once: at least a cue for each (DEC-0031 §6).
const CUES_AT_LEAST := 2
const HAIR := 1e-3 # m: a millimetre of slack on the spawn distance, not a design number

var _first_tick := 0
var _first_state_tick := 0


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	if NetworkRollback.before_loop.is_connected(_force_rollback):
		NetworkRollback.before_loop.disconnect(_force_rollback)
	NetfoxTicks.reset()


func test_the_guard_break_scenario_resimulates_with_zero_divergence() -> void:
	var observer := await _quebra(LOOPS)
	var message := "%s diverged:\n%s" % [observer.scenario, "\n".join(observer.shown)]
	assert_int(observer.mismatches).override_failure_message(message).is_equal(0)
	assert_int(observer.paths["unknown_actions"]) \
			.override_failure_message("FighterInput has no press_guard_break()") \
			.is_equal(0)
	assert_int(observer.paths["guard_breaks"]).is_equal(GUARD_BREAKS)
	assert_int(observer.paths["guard_breaks_of_15"]).is_equal(GUARD_BREAKS)
	assert_int(observer.paths["grab_stamps"]).is_equal(GRABS)
	assert_int(observer.paths["grabbed"]).is_equal(GRABS)
	assert_int(observer.paths["grabbing"]).is_equal(GRABS)
	assert_int(observer.paths["techs"]).is_equal(TECHS)
	assert_int(observer.paths["free_techs"]).is_equal(TECHS)
	assert_int(observer.paths["hits"]).is_equal(HITS)
	assert_int(observer.paths["hits_of_30"]).is_equal(HITS)
	assert_int(observer.paths["blocks"]).is_equal(0)
	assert_int(observer.paths["refills"]).is_equal(REFILLS)
	assert_int(observer.paths["lowest_health"]).is_equal(LOWEST_HEALTH)
	assert_int(observer.paths["final_health"]).is_equal(2 * MAX_HEALTH)
	# The freezes: one start per fighter per grab, and per fighter for the charged that lands.
	assert_int(observer.paths["freezes"]).is_equal(FREEZES)
	assert_int(observer.paths["frozen_ticks"]).is_equal(FROZEN_TICKS)
	# The holds, counted on the fresh ticks.
	assert_int(observer.paths["grabbing_ticks"]).is_equal(GRABBING_TICKS)
	assert_int(observer.paths["grabbed_ticks"]).is_greater(GRABBED_TICKS_WITH_A_TECH)
	assert_int(observer.paths["grabbed_ticks"]).is_less_equal(GRABBED_TICKS_AT_MOST)
	assert_int(observer.paths["bots_done"]).is_equal(STARTS.size())
	# Both stayed on the floor: grabs, techs and freezes move nobody.
	assert_int(observer.takeoffs).is_equal(0)
	# Every cue once per event, never again in the resimulations (DEC-0031 §6).
	_assert_cues(observer, CUES_AT_LEAST)


# The poison of criterion 7: with the grab's stamp out of what netfox records, a rollback across
# the contact restores the rest and keeps the present stamp, so the resimulated ticks before the
# grab carry a grab that had not happened, and the test must diverge; the tech's stamp too.
func test_the_grab_stamps_netfox_does_not_record_make_the_sync_test_diverge(
	hidden: String,
	_test_parameters := [[":state:grabbed_tick"], [":state:tech_tick"]],
) -> void:
	var observer := await _quebra(SELF_TEST_LOOPS, hidden)
	assert_int(observer.paths["not_recorded"]) \
			.override_failure_message("%s is not among what netfox records" % hidden) \
			.is_equal(0)
	assert_int(observer.paths["grab_stamps"]).is_greater(0)
	assert_int(observer.paths["techs"]).is_greater(0)
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


func _quebra(loops: int, hidden := "") -> SyncObserver:
	var missing: Array[String] = []
	var game_match := await _match_with(STARTS, hidden, missing)
	var fighters := game_match.fighters
	var side := game_match.config.aim_side
	var bots: Array[BreakBot] = []
	var grabs: Array[Grabs] = []
	for slot: int in fighters.size():
		var script: Dictionary[int, String] = { }
		var scripted: Dictionary = SCRIPTS[slot]
		for loop: int in scripted:
			var actions: String = scripted[loop]
			script[loop] = actions
		bots.append(
			BreakBot.new(
				fighters[slot],
				GrabRig.camera_for(YAWS[slot], side, HAND_CONVERGENCE_M),
				GrabRig.camera_for(YAWS[slot], side, SWORD_CONVERGENCE_M),
				script,
			),
		)
		grabs.append(Grabs.new(fighters[slot]))
		assert_int(fighters[slot].state.health).override_failure_message("spawned without health") \
				.is_equal(MAX_HEALTH)
	var apart := fighters[0].position.distance_to(fighters[1].position)
	assert_float(apart).override_failure_message("not within reach").is_equal_approx(APART_M, HAIR)
	var observer := _start(
		game_match,
		"quebra" if hidden.is_empty() else "quebra without " + hidden,
	)
	for _loop: int in loops:
		for bot: BreakBot in bots:
			bot.drive()
		NetfoxTicks.run_loop()
		for path: Grabs in grabs:
			path.observe()
	for path: Grabs in grabs:
		path.add_to(observer.paths)
	observer.paths["lowest_health"] = mini(grabs[0].lowest_health, grabs[1].lowest_health)
	observer.paths["final_health"] = fighters[0].state.health + fighters[1].state.health
	observer.paths["bots_done"] = 0
	observer.paths["unknown_actions"] = 0
	for bot: BreakBot in bots:
		observer.paths["bots_done"] += 1 if bot.done() else 0
		observer.paths["unknown_actions"] += bot.unknown
	observer.paths["not_recorded"] = missing.size()
	observer.paths["cues_presented"] = game_match.cues.presented
	observer.paths["cue_events"] = game_match.cues.events
	return _finish(observer, game_match)


# A Match in the tree with a fighter of each slot standing at its start, placed before netfox
# records its first state: the RollbackSynchronizer registers with call_deferred. The ticks then
# run inside a physics frame (test/support/netfox_ticks.gd). hidden, when not empty, is a state
# property taken out of what netfox records, for the self-tests; a property netfox does not record
# to begin with is added to `missing`.
func _match_with(starts: Array[Vector3], hidden: String, missing: Array[String]) -> Match:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match := node as Match
	add_child(game_match)
	for slot: int in starts.size():
		var fighter := game_match.spawn_fighter(slot, multiplayer.get_unique_id())
		fighter.position = starts[slot]
		if not hidden.is_empty() and not _stop_recording(fighter, hidden):
			missing.append(hidden)
	await get_tree().process_frame
	await get_tree().physics_frame
	return game_match


# Takes a property out of what netfox records for this fighter, before its synchronizer processes
# its settings; the production scene stays untouched. False when netfox did not record it.
func _stop_recording(fighter: Fighter, property: String) -> bool:
	var synchronizer := _synchronizer(fighter)
	var kept: Array[String] = []
	for recorded: String in synchronizer.state_properties:
		if recorded != property:
			kept.append(recorded)
	if kept.size() == synchronizer.state_properties.size():
		return false
	synchronizer.state_properties = kept
	return true


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


# A scripted player standing still, the camera held so its hand goes at the other fighter (DEC-0058
# §2) until "sword" turns it to the sword's aim (DEC-0057), who presses the guard break and the
# charged through the calls the keys use too (FighterInput.press_guard_break, by the name of the
# touch, TickInput.guard_break, as press_charged_attack is to charged_attack), and works the guard
# button as the right mouse button does.
class BreakBot:
	const PRESS_GUARD_BREAK := &"press_guard_break"

	var fighter: Fighter
	var yaw: float
	var sword_yaw: float
	var moves: Dictionary[int, String]
	var loop := 0
	## Presses the fighter's input had no call for.
	var unknown := 0


	func _init(
		played: Fighter,
		hand_camera: float,
		sword_camera: float,
		scripted: Dictionary[int, String],
	) -> void:
		fighter = played
		yaw = hand_camera
		sword_yaw = sword_camera
		moves = scripted


	func drive() -> void:
		if moves.has(loop) and moves[loop].split(" ", false).has("sword"):
			yaw = sword_yaw
		fighter.input.sample_frame(Vector2.ZERO, yaw)
		if moves.has(loop):
			for action: String in moves[loop].split(" ", false):
				match action:
					"break":
						if fighter.input.has_method(PRESS_GUARD_BREAK):
							fighter.input.call(PRESS_GUARD_BREAK)
						else:
							unknown += 1
					"charged":
						fighter.input.press_charged_attack()
					"sword":
						pass
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


# The paths of one fighter through the grabs, read on the fresh tick of every loop, from the state
# on screen, every event counted by the state entering it against the tick before (F-187): guard
# breaks whose windup began and those that cost exactly 15, grab stamps moved, fighters entering
# GRABBED and GRABBING, techs (the tech stamp moved) and those that cost nothing, hits (the hurt
# stamp moved) and hits of exactly 30, blocks, freezes begun and ticks frozen, ticks held, refills
# to the max, and the lowest health seen.
class Grabs:
	var guard_breaks := 0
	var guard_breaks_of_15 := 0
	var grab_stamps := 0
	var grabbed := 0
	var grabbing := 0
	var techs := 0
	var free_techs := 0
	var hits := 0
	var hits_of_30 := 0
	var blocks := 0
	var freezes := 0
	var frozen_ticks := 0
	var grabbed_ticks := 0
	var grabbing_ticks := 0
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
		var breaking := (
			state.action == FighterState.Action.WINDUP and state.action_move == GrabRig.GUARD_BREAK
		)
		var was_breaking := (
			_before.action == FighterState.Action.WINDUP
			and _before.action_move == GrabRig.GUARD_BREAK
		)
		if breaking and not was_breaking:
			guard_breaks += 1
			if absf(paid - GUARD_BREAK_COST) < 1e-6:
				guard_breaks_of_15 += 1
		if GrabRig.grabbed_tick(state) != GrabRig.grabbed_tick(_before):
			grab_stamps += 1
		if GrabRig.is_grabbed(state) and not GrabRig.is_grabbed(_before):
			grabbed += 1
		if GrabRig.is_grabbing(state) and not GrabRig.is_grabbing(_before):
			grabbing += 1
		if GrabRig.tech_tick(state) != GrabRig.tech_tick(_before):
			techs += 1
			if absf(paid) < 1e-6:
				free_techs += 1
		if state.hurt_tick != _before.hurt_tick:
			hits += 1
			if _before.health - state.health == CHARGED_DAMAGE:
				hits_of_30 += 1
		if state.block_tick != _before.block_tick:
			blocks += 1
		if state.frozen_until_tick > _before.frozen_until_tick:
			freezes += 1
		if tick <= state.frozen_until_tick:
			frozen_ticks += 1
		if GrabRig.is_grabbed(state):
			grabbed_ticks += 1
		if GrabRig.is_grabbing(state):
			grabbing_ticks += 1
		if state.health == MAX_HEALTH and _before.health < MAX_HEALTH:
			refills += 1
		lowest_health = mini(lowest_health, state.health)
		_before = state.copy()


	# Adds this fighter's counters to a scenario's paths, summed over its fighters.
	func add_to(paths: Dictionary[String, int]) -> void:
		var mine: Dictionary[String, int] = {
			"guard_breaks": guard_breaks,
			"guard_breaks_of_15": guard_breaks_of_15,
			"grab_stamps": grab_stamps,
			"grabbed": grabbed,
			"grabbing": grabbing,
			"techs": techs,
			"free_techs": free_techs,
			"hits": hits,
			"hits_of_30": hits_of_30,
			"blocks": blocks,
			"freezes": freezes,
			"frozen_ticks": frozen_ticks,
			"grabbed_ticks": grabbed_ticks,
			"grabbing_ticks": grabbing_ticks,
			"refills": refills,
		}
		for path: String in mine:
			if not paths.has(path):
				paths[path] = 0
			paths[path] += mine[path]
