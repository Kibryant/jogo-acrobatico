# Criterion 8 of TASK-9 and of TASK-10.1: the permanent SyncTest (rede.md §4; DEC-0025;
# DEC-0027 §3). The real Match runs in Sozinho, Godot's offline peer, with netfox's ticks advanced
# by hand, one tick per loop (test/support/netfox_ticks.gd), and on every loop netfox is told to
# roll back 7 ticks, the depth of a 220 ms ping at 60 ticks (rede.md §4): it restores the state of
# 7 ticks before the present and simulates those 7 ticks, 6 of them again and the newest for the
# first time. The observer (test/support/sync_observer.gd) compares every resimulation of a
# fighter at a tick with the first result of that tick, the whole state, so state the rollback
# forgets, a field netfox does not record or a flag the engine keeps, shows up as a divergence.
# Four scenarios go where the engine keeps state of its own (DEC-0025): the 45° ramp, the ledge,
# the landing and two fighters pushing each other on the ground; the fifth goes through the double
# jump and the stamina (TASK-10.1), and the sixth through the dash (TASK-10.4, criterion 6). Each
# prints a summary line that proves its paths ran. The pulo duplo and the dash also check the
# cues of the maneuvers: played once per event, as many as the events (DEC-0031 §6).
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const SyncObserver := preload("res://test/support/sync_observer.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

## Ticks netfox rolls back on every loop: the depth of a 220 ms ping at 60 ticks (rede.md §4).
const DEPTH := 7
## ms: the scenarios together on Arthur's PC (TASK-9, choice 6).
const BUDGET_MS := 5000
const FORWARD := Vector2(0, 1)

# The arena (arena.tscn): the floor's top is y = 0; the platform's top is y = 1, over x 0..6 and
# z -3..3, with the 1 m ledge on its -X side and the 45° ramp down from x = 6 to x = 7.
const PLATFORM_TOP := 1.0
# m: a body higher than this stands on the platform or flies near it; lower, it is on the floor.
const HALF_PLATFORM := 0.5

# Rampa: back and forth over the crest at full speed, between the floor east of the ramp and the
# platform, so it climbs the ramp twice and runs down it twice.
const RAMPA_START := Vector3(8.6, 0, 0)
const RAMPA_TURN_ON_PLATFORM_X := 4.5
const RAMPA_TURN_ON_FLOOR_X := 8.6
const RAMPA_LOOPS := 210

# Beirada: two fighters in lanes 3 m apart run off the platform's west ledge twice each and jump
# back onto it from the floor in between; one presses jump inside the coyote window on its first
# pass, the other on the last tick of the window on its second. The second pass starts from a
# landing on the platform, which leaves the body resting a hair higher than a spawn does.
const BEIRADA_STARTS: Array[Vector3] = [Vector3(2.5, 1, -1.5), Vector3(2.5, 1, 1.5)]
const BEIRADA_TURN_ON_FLOOR_X := -3.2
const BEIRADA_TURN_ON_PLATFORM_X := 1.5
const BEIRADA_LOOPS := 215
# A press age of NO_PRESS lets the body fall off the ledge without a jump.
const NO_PRESS := -1

# The jump onto the platform from the floor, running east at full speed: pressed here, the body
# is above the platform's top before it reaches the ledge and lands well inside it.
const CLIMB_FROM_X := -2.6
const CLIMB_TO_X := -1.9

# Pouso: a hop in place on the floor, a jump onto the platform and a hop in place on it. Each hop
# presses again at its apex, which spends the flight's double jump, and once more just before
# landing: with the double jump spent, that press waits in the slot of the buffer and becomes a
# jump on the first tick on the floor (movimento.md, "Pulo e ar" and "Perdão").
const POUSO_START := Vector3(-4.5, 0, 0)
const POUSO_LOOPS := 300
# m: a falling body this close above where it lands presses the buffered jump.
const BUFFER_PRESS_HEIGHT := 0.35
const REST_TICKS := 6

# Empurrão: the two fighters face each other 4 m apart, charge for 1.1 s and back off for 0.4 s,
# twice, never jumping (Q-16 is phase 1). Each pushes toward the other and partly to its own
# left, so they turn around each other while they push and the contact moves every tick: two
# bodies pressed still would collide in the same place restored or not.
const EMPURRAO_STARTS: Array[Vector3] = [Vector3(-6, 0, 6), Vector3(-6, 0, 2)]
const EMPURRAO_CYCLE_TICKS := 90
const EMPURRAO_CHARGE_TICKS := 66
const EMPURRAO_LOOPS := 180
# The sideways part of each push, against 1 toward the other: about 27° off the line between them.
const EMPURRAO_ASIDE := 0.5
# Moves that hit the other fighter, three quarters of a second's worth: the two charges give 70.
const EMPURRAO_MIN_CONTACTS := 45

# Pulo duplo: two fighters on a copy of movement_v0.tres whose bar holds 25 points and never
# regains (TASK-10.1, criterion 8), so with the cost of 10 each bar goes 25, 15, 5, and a third
# press is refused. The climber runs down -Z at Block2m (arena.tscn: x -2..2, z -14..-10, top
# y = 2), jumps, double-jumps at the apex and lands on the block, the climb of movimento.md,
# "Métricas de nível"; on the block it jumps and double-jumps on the next tick, then jumps and
# presses at the apex with 5 points: refused. The walker walks off the platform's west ledge
# without a jump and presses past the coyote: the double jump of a flight with no jump.
const PULO_DUPLO_STARTS: Array[Vector3] = [Vector3(-1, 0, -2), Vector3(2.5, 1, 2)]
const SHORT_BAR := 25.0
const NO_REGEN := 0.0
# Running down -Z at full speed, the climber jumps here: its apex comes about 2.2 m short of the
# block's face at z = -10, and the double jump carries its feet over the edge with about 15 cm
# to spare, up to about 2.2 m (movimento.md, "Métricas de nível").
const BLOCK_JUMP_Z := -5.3
# m: a body on the floor higher than this stands on Block2m, whose top is y = 2.
const HALF_BLOCK := 1.5
# Ticks past the last tick of the coyote window when the walker presses.
const PAST_COYOTE := 2
const PULO_DUPLO_LOOPS := 195

# Dash: two fighters on a copy of movement_v0.tres whose bar holds 20 points (TASK-10.4 plan), so
# a dash of 15 leaves at most 5 and the bar pays the next one only 68 ticks later, after the 48 of
# the wait and 20 of regen (movimento.md, "Stamina"): a refusal by the bar is easy, and the 36
# ticks of the cooldown always end first. The rampeiro starts on the platform and dashes east over
# the crest and down the ramp, runs back up, dashes west off the ledge, then hops and presses the
# dash just before landing: the dash waits in the slot and comes out on the first tick on the
# floor. The paredeiro dashes into Block2m's face (z = -10) and slides to a stop, presses during
# the cooldown and again with the bar short, both refused; then dashes on the plane with a jump
# pressed near the end, which comes out on the first tick after it; and once landed, presses the
# dash 3 ticks before the bar can pay, a press the slot keeps until it does (movimento.md, "Dash",
# "Perdão" and "Stamina").
const DASH_STARTS: Array[Vector3] = [Vector3(4.5, 1, 1.5), Vector3(-1, 0, -7)]
const DASH_BAR := 20.0
# The rampeiro dashes off the west ledge from where it stops once past this x on the platform.
const LEDGE_DASH_FROM_X := 1.8
# Ticks before the end of the dash the jump is pressed: inside the buffer, so it fires at the end.
const JUMP_BEFORE_EXIT := 3
# Ticks before the bar can pay that the paredeiro presses the dash it keeps in the slot.
const BAR_AHEAD := 3
const DASH_LOOPS := 300

# The self-tests need only the start of a scenario: the first hop of the pouso, the walker's
# double jump of the pulo duplo, the paredeiro's first dash.
const SELF_TEST_LOOPS := 90
const DOUBLE_JUMP_SELF_TEST_LOOPS := 60
const DASH_SELF_TEST_LOOPS := 40

# The first tick of the run and the tick of the fighters' first recorded state.
var _first_tick := 0
var _first_state_tick := 0


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	if NetworkRollback.before_loop.is_connected(_force_rollback):
		NetworkRollback.before_loop.disconnect(_force_rollback)
	NetfoxTicks.reset()


func test_the_six_scenarios_resimulate_with_zero_divergence() -> void:
	var started := Time.get_ticks_msec()
	var rampa := await _rampa()
	var beirada := await _beirada()
	var pouso := await _pouso(POUSO_LOOPS)
	var empurrao := await _empurrao()
	var pulo_duplo := await _pulo_duplo(PULO_DUPLO_LOOPS)
	var dash := await _dash(DASH_LOOPS)
	var spent := Time.get_ticks_msec() - started
	# The budget is for Arthur's PC at rest (TASK-9, choice 6): the gate prints the time on every
	# run, and the reviewer checks it on a quiet run. A busy PC took up to three times as long, so
	# a ceiling here would turn the gate red for nothing; Arthur chose to show it (F-087 §1).
	var budget := "budget %d ms on Arthur's PC at rest" % BUDGET_MS
	print("SyncTest, the six scenarios together: %d ms (%s)" % [spent, budget])

	for observer: SyncObserver in [rampa, beirada, pouso, empurrao, pulo_duplo, dash]:
		var message := "%s diverged:\n%s" % [observer.scenario, "\n".join(observer.shown)]
		assert_int(observer.mismatches).override_failure_message(message).is_equal(0)

	# On the floor over the crest both ways, at full speed.
	assert_int(rampa.ramp_ticks).is_greater(0)
	assert_int(rampa.paths["climbs"]).is_greater_equal(2)
	assert_int(rampa.paths["descents"]).is_greater_equal(2)
	assert_int(rampa.takeoffs).is_equal(0)

	assert_int(beirada.paths["ledge_takeoffs"]).is_equal(4)
	assert_int(beirada.paths["coyote_jumps"]).is_equal(2)

	assert_int(pouso.paths["floor_landings"]).is_greater_equal(2)
	assert_int(pouso.paths["platform_landings"]).is_greater_equal(2)
	assert_int(pouso.paths["buffered_jumps"]).is_equal(2)
	assert_int(pouso.paths["double_jumps"]).is_greater_equal(2)

	# They pushed each other for a while, and on the ground.
	assert_int(empurrao.collisions).is_greater_equal(EMPURRAO_MIN_CONTACTS)
	assert_int(empurrao.takeoffs).is_equal(0)

	# Two double jumps on the climber's bar and one on the walker's, the climb and the press on
	# the next tick among them; the third press of the climber refused.
	assert_int(pulo_duplo.paths["double_jumps"]).is_greater_equal(3)
	assert_int(pulo_duplo.paths["ledge_double_jumps"]).is_greater_equal(1)
	assert_int(pulo_duplo.paths["next_tick_double_jumps"]).is_greater_equal(1)
	assert_int(pulo_duplo.paths["refused_double_jumps"]).is_greater_equal(1)
	assert_int(pulo_duplo.paths["block_2m_climbs"]).is_greater_equal(1)
	assert_int(pulo_duplo.landings).is_greater_equal(3)
	# One cue per double jump, never again in the resimulations (DEC-0031 §6).
	_assert_cues(pulo_duplo, pulo_duplo.paths["double_jumps"])

	# Criterion 6 of TASK-10.4: the dash on the plane, down the ramp with no tick in the air, into
	# a wall, off the ledge, kept in the slot in the air and for the bar, refused in the cooldown
	# and by the bar, and a jump at its end; every bot went through its whole script.
	assert_int(dash.paths["dashes"]).is_greater_equal(5)
	assert_int(dash.paths["ramp_dash_ticks"]).is_greater(0)
	assert_int(dash.paths["ramp_dash_air_ticks"]).is_equal(0)
	assert_int(dash.paths["ledge_dashes"]).is_greater_equal(1)
	assert_int(dash.paths["blocked_dashes"]).is_greater_equal(1)
	assert_int(dash.paths["buffered_dashes"]).is_greater_equal(2)
	assert_int(dash.paths["refused_cooldown"]).is_greater_equal(1)
	assert_int(dash.paths["refused_stamina"]).is_greater_equal(1)
	assert_int(dash.paths["jumps_after_dash"]).is_greater_equal(1)
	assert_int(dash.paths["bots_done"]).is_equal(DASH_STARTS.size())
	_assert_cues(dash, dash.paths["dashes"])


# The SyncTest's own canary: with on_floor out of what netfox records for the fighter, a rollback
# restores everything but the floor verdict, and the takeoff and landing of the first hop come out
# different when resimulated. If this stops diverging, the SyncTest has lost its teeth.
func test_a_field_netfox_does_not_record_makes_the_sync_test_diverge() -> void:
	var observer := await _pouso(SELF_TEST_LOOPS, ":state:on_floor")
	assert_int(observer.mismatches).is_greater(0)


# The canaries of the whole-state compare (TASK-10.1, criterion 8): out of what netfox records, a
# field keeps its present value through a rollback. Across the walker's double jump, the bar
# after the spend comes back with a stamp from before it, and the resimulated state differs from
# the fresh one even where the body moves the same.
func test_the_stamina_netfox_does_not_record_makes_the_sync_test_diverge() -> void:
	var observer := await _pulo_duplo(DOUBLE_JUMP_SELF_TEST_LOOPS, ":state:stamina_at_spend")
	assert_int(observer.mismatches).is_greater(0)


# The double jump's stamp, the key its visual signal will play by (DEC-0031): out of the
# recording, a rollback across the double jump brings the stamp back on the ticks before it.
func test_the_double_jump_tick_netfox_does_not_record_makes_the_sync_test_diverge() -> void:
	var observer := await _pulo_duplo(DOUBLE_JUMP_SELF_TEST_LOOPS, ":state:double_jump_tick")
	assert_int(observer.mismatches).is_greater(0)


# As many cues as events, and as many events as maneuvers; the cues are read before the match goes.
func _assert_cues(observer: SyncObserver, maneuvers: int) -> void:
	var cues := "%s: %d cues presented, %d events, %d maneuvers" % [
		observer.scenario,
		observer.paths["cues_presented"],
		observer.paths["cue_events"],
		maneuvers,
	]
	assert_int(observer.paths["cues_presented"]).override_failure_message(cues).is_equal(
		observer.paths["cue_events"]
	)
	assert_int(observer.paths["cue_events"]).override_failure_message(cues).is_equal(maneuvers)


# The dash's stamp, the key its cue plays by and what its cooldown reads: out of the recording, a
# rollback across the dash brings the stamp back on the ticks before it (TASK-10.4, criterion 6).
func test_the_dash_tick_netfox_does_not_record_makes_the_sync_test_diverge() -> void:
	var observer := await _dash(DASH_SELF_TEST_LOOPS, ":state:dash_tick")
	assert_int(observer.mismatches).is_greater(0)


func _rampa() -> SyncObserver:
	var game_match := await _match_with([RAMPA_START])
	var bot := Bot.new(game_match.fighters[0])
	var observer := _start(game_match, "rampa")
	var heading := Vector3.LEFT
	var climbs := 0
	var descents := 0
	var crest := SyncObserver.RAMP_FROM_X
	for _loop: int in RAMPA_LOOPS:
		var x := bot.fighter.position.x
		if heading == Vector3.LEFT and x < RAMPA_TURN_ON_PLATFORM_X:
			heading = Vector3.RIGHT
		elif heading == Vector3.RIGHT and x > RAMPA_TURN_ON_FLOOR_X:
			heading = Vector3.LEFT
		bot.run(heading)
		NetfoxTicks.run_loop()
		var now := bot.fighter.position.x
		if bot.fighter.state.on_floor and x >= crest and now < crest:
			climbs += 1
		elif bot.fighter.state.on_floor and x < crest and now >= crest:
			descents += 1
	observer.paths["climbs"] = climbs
	observer.paths["descents"] = descents
	return _finish(observer, game_match)


func _beirada() -> SyncObserver:
	var game_match := await _match_with(BEIRADA_STARTS)
	var coyote_last := game_match.config.coyote_ticks
	var bots: Array[LedgeBot] = [
		LedgeBot.new(game_match.fighters[0], [NO_PRESS, coyote_last]),
		LedgeBot.new(game_match.fighters[1], [1, NO_PRESS]),
	]
	var observer := _start(game_match, "beirada")
	for _loop: int in BEIRADA_LOOPS:
		for bot: LedgeBot in bots:
			bot.drive()
		NetfoxTicks.run_loop()
	observer.paths["ledge_takeoffs"] = 0
	observer.paths["coyote_jumps"] = 0
	for bot: LedgeBot in bots:
		observer.paths["ledge_takeoffs"] += bot.ledge_takeoffs
		observer.paths["coyote_jumps"] += bot.coyote_jumps
	return _finish(observer, game_match)


func _pouso(loops: int, hidden := "") -> SyncObserver:
	var game_match := await _match_with([POUSO_START], hidden)
	var bot := HopBot.new(game_match.fighters[0])
	var flights := Flights.new(bot.fighter, game_match.config)
	var observer := _start(game_match, "pouso" if hidden.is_empty() else "pouso without " + hidden)
	for _loop: int in loops:
		bot.drive()
		NetfoxTicks.run_loop()
		flights.observe()
	observer.paths["floor_landings"] = bot.floor_landings
	observer.paths["platform_landings"] = bot.platform_landings
	observer.paths["buffered_jumps"] = bot.buffered_jumps
	flights.add_to(observer.paths)
	return _finish(observer, game_match)


func _empurrao() -> SyncObserver:
	var game_match := await _match_with(EMPURRAO_STARTS)
	var first := Bot.new(game_match.fighters[0])
	var second := Bot.new(game_match.fighters[1])
	var observer := _start(game_match, "empurrão")
	for loop: int in EMPURRAO_LOOPS:
		var gap := second.fighter.position - first.fighter.position
		var toward := Vector3(gap.x, 0, gap.z).normalized()
		# Each pushes toward the other and a little to its own left, so they turn around each
		# other while they push: the contact moves every tick.
		var aside := toward.rotated(Vector3.UP, PI / 2) * EMPURRAO_ASIDE
		var push := (toward + aside).normalized()
		if loop % EMPURRAO_CYCLE_TICKS >= EMPURRAO_CHARGE_TICKS:
			push = -toward
		first.run(push)
		second.run(-push)
		NetfoxTicks.run_loop()
	return _finish(observer, game_match)


func _pulo_duplo(loops: int, hidden := "") -> SyncObserver:
	var game_match := await _match_with(PULO_DUPLO_STARTS, hidden, _short_bar())
	var config := game_match.config
	var climber := ClimbBot.new(game_match.fighters[0])
	var walker := LedgeBot.new(game_match.fighters[1], [config.coyote_ticks + PAST_COYOTE])
	var flights: Array[Flights] = [
		Flights.new(climber.fighter, config),
		Flights.new(walker.fighter, config),
	]
	var scenario := "pulo duplo" if hidden.is_empty() else "pulo duplo without " + hidden
	var observer := _start(game_match, scenario)
	for _loop: int in loops:
		climber.drive()
		walker.drive()
		NetfoxTicks.run_loop()
		for flight: Flights in flights:
			flight.observe()
	for flight: Flights in flights:
		flight.add_to(observer.paths)
	observer.paths["block_2m_climbs"] = climber.block_climbs
	_add_cues(observer, game_match)
	return _finish(observer, game_match)


func _dash(loops: int, hidden := "") -> SyncObserver:
	var game_match := await _match_with(DASH_STARTS, hidden, _dash_bar())
	var config := game_match.config
	var bots: Array[DashBot] = [
		RampLedgeBot.new(game_match.fighters[0], config),
		WallBot.new(game_match.fighters[1], config),
	]
	var dashes: Array[Dashes] = []
	for fighter: Fighter in game_match.fighters:
		dashes.append(Dashes.new(fighter, config))
	var observer := _start(game_match, "dash" if hidden.is_empty() else "dash without " + hidden)
	for _loop: int in loops:
		for bot: DashBot in bots:
			bot.drive()
		NetfoxTicks.run_loop()
		for path: Dashes in dashes:
			path.observe()
	for path: Dashes in dashes:
		path.add_to(observer.paths)
	observer.paths["bots_done"] = 0
	for bot: DashBot in bots:
		observer.paths["bots_done"] += 1 if bot.done() else 0
	_add_cues(observer, game_match)
	return _finish(observer, game_match)


# The cues of the match, read before it goes.
func _add_cues(observer: SyncObserver, game_match: Match) -> void:
	observer.paths["cues_presented"] = game_match.cues.presented
	observer.paths["cue_events"] = game_match.cues.events


# The movement numbers of the pulo duplo: a copy of movement_v0.tres with a bar of SHORT_BAR points
# and no regen, checked like any design data. The loaded resource is shared by every load() and
# stays untouched (DEC-0004, rule 3).
func _short_bar() -> MovementData:
	var resource: Resource = load(Match.MOVEMENT_DATA_PATH)
	assert(resource is MovementData, "%s must load as a MovementData" % Match.MOVEMENT_DATA_PATH)
	var copy := resource.duplicate()
	assert(copy is MovementData, "a copy of a MovementData is a MovementData")
	var data := copy as MovementData
	data.stamina_max = SHORT_BAR
	data.stamina_regen_per_s = NO_REGEN
	assert_array(data.validate()).override_failure_message("the short bar").is_empty()
	return data


# The movement numbers of the dash: a copy of movement_v0.tres with a bar of DASH_BAR points,
# checked like any design data (TASK-10.4 plan).
func _dash_bar() -> MovementData:
	var resource: Resource = load(Match.MOVEMENT_DATA_PATH)
	assert(resource is MovementData, "%s must load as a MovementData" % Match.MOVEMENT_DATA_PATH)
	var copy := resource.duplicate()
	assert(copy is MovementData, "a copy of a MovementData is a MovementData")
	var data := copy as MovementData
	data.stamina_max = DASH_BAR
	assert_array(data.validate()).override_failure_message("the dash's bar").is_empty()
	return data


# A Match in the tree with a fighter of each slot standing at its start, placed before netfox
# records its first state: the RollbackSynchronizer registers with call_deferred. The ticks then
# run inside a physics frame (test/support/netfox_ticks.gd). hidden, when not empty, is a state
# property taken out of what netfox records, for the self-tests; data, when given, replaces
# movement_v0.tres, as the reference plays its frozen copy (test/reference/reference_run.gd).
func _match_with(starts: Array[Vector3], hidden := "", data: MovementData = null) -> Match:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match := node as Match
	game_match.movement_data = data
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


# A scripted player: before each tick loop it speaks for one fighter through the calls the
# keyboard uses too (FighterInput.sample_frame and press_jump), reading the state on screen.
class Bot:
	var fighter: Fighter


	func _init(played: Fighter) -> void:
		fighter = played


	# Full input along a horizontal world direction, the body looking where it runs; no direction
	# stands still, looking where it looked.
	func run(direction: Vector3) -> void:
		if direction == Vector3.ZERO:
			fighter.input.sample_frame(Vector2.ZERO, fighter.state.facing_yaw)
			return
		# yaw 0 looks down -Z, and forward turned by yaw is (-sin(yaw), 0, -cos(yaw)).
		fighter.input.sample_frame(FORWARD, atan2(-direction.x, -direction.z))


# Runs off the platform's west ledge once per entry of press_ages and jumps back onto it from the
# floor in between. An age of n presses jump n ticks after the tick the body left the ledge; an
# age of NO_PRESS lets it fall. A pass ends when the body lands on the floor below the ledge;
# after the last one it stands there.
class LedgeBot:
	extends Bot

	var press_ages: Array[int] = []
	var ledge_takeoffs := 0
	var coyote_jumps := 0

	var _pass := 0
	var _heading := Vector3.LEFT
	var _was_on_floor := true
	var _coyote_pressed := false


	func _init(played: Fighter, ages: Array[int]) -> void:
		super(played)
		press_ages = ages


	func drive() -> void:
		var state := fighter.state
		var where := fighter.position
		var high := where.y > HALF_PLATFORM
		if _coyote_pressed and state.jumps_used == 1 and not state.on_floor:
			coyote_jumps += 1
		_coyote_pressed = false
		if _was_on_floor and not state.on_floor and state.jumps_used == 0 and high:
			ledge_takeoffs += 1
		elif not _was_on_floor and state.on_floor and not high:
			_pass += 1
		_was_on_floor = state.on_floor
		if _pass >= press_ages.size():
			run(Vector3.ZERO)
			return
		if state.on_floor:
			if _heading == Vector3.LEFT and not high and where.x < BEIRADA_TURN_ON_FLOOR_X:
				_heading = Vector3.RIGHT
			elif _heading == Vector3.RIGHT and high and where.x > BEIRADA_TURN_ON_PLATFORM_X:
				_heading = Vector3.LEFT
			var climbing := where.x >= CLIMB_FROM_X and where.x < CLIMB_TO_X
			if _heading == Vector3.RIGHT and not high and climbing:
				fighter.input.press_jump()
		elif state.jumps_used == 0:
			# Off the ledge without a jump: the press of this pass comes at its age.
			if NetworkTime.tick - state.left_floor_tick == press_ages[_pass]:
				fighter.input.press_jump()
				_coyote_pressed = true
		run(_heading)


# Hops in place on the floor, runs east and jumps onto the platform, then hops in place on it;
# each hop presses again at its apex, the double jump, and just before landing, inside the buffer
# window.
class HopBot:
	extends Bot

	enum Step {
		FLOOR_HOP,
		CLIMB,
		PLATFORM_HOP,
		DONE,
	}

	var floor_landings := 0
	var platform_landings := 0
	var buffered_jumps := 0

	var _step := Step.FLOOR_HOP
	# Ticks on the floor since the last landing; it starts standing, which is no landing.
	var _floor_ticks := 1
	var _hopped := false
	var _double_jumped := false
	var _buffered := false


	func drive() -> void:
		var state := fighter.state
		var high := fighter.position.y > HALF_PLATFORM
		if state.on_floor:
			if _floor_ticks == 0:
				if high:
					platform_landings += 1
				else:
					floor_landings += 1
			_floor_ticks += 1
		else:
			# A jump on the first tick on the floor is the buffer's: no press came on the floor.
			if _floor_ticks == 1 and state.jumps_used == 1:
				buffered_jumps += 1
			_floor_ticks = 0
		match _step:
			Step.FLOOR_HOP:
				_hop(state, 0.0, Step.CLIMB)
			Step.CLIMB:
				run(Vector3.RIGHT)
				var x := fighter.position.x
				if state.on_floor and high:
					_step = Step.PLATFORM_HOP
				elif state.on_floor and x >= CLIMB_FROM_X and x < CLIMB_TO_X:
					fighter.input.press_jump()
			Step.PLATFORM_HOP:
				_hop(state, PLATFORM_TOP, Step.DONE)
			Step.DONE:
				run(Vector3.ZERO)


	# A hop in place: once the body rests, press; at the apex, press again for the double jump;
	# falling close to the surface, press once more, a press the slot keeps for the landing; after
	# the bounce, rest and go to the next step.
	func _hop(state: FighterState, surface: float, next: Step) -> void:
		run(Vector3.ZERO)
		if state.on_floor:
			if not _hopped and _floor_ticks > REST_TICKS:
				fighter.input.press_jump()
				_hopped = true
			elif _hopped and _buffered and _floor_ticks > REST_TICKS:
				_step = next
				_hopped = false
				_double_jumped = false
				_buffered = false
			return
		var falling := fighter.velocity.y < 0.0
		if falling and not _double_jumped:
			fighter.input.press_jump()
			_double_jumped = true
		elif falling and not _buffered and fighter.position.y - surface < BUFFER_PRESS_HEIGHT:
			fighter.input.press_jump()
			_buffered = true


# Runs down -Z at Block2m, jumps at BLOCK_JUMP_Z, double-jumps at the apex and lands on the block;
# there it hops in place twice: a jump with a press on the next tick, then a jump with a press at
# the apex.
class ClimbBot:
	extends Bot

	enum Step {
		RUN_UP,
		CLIMB,
		NEXT_TICK_HOP,
		APEX_HOP,
		DONE,
	}

	## Landings on Block2m from the climb.
	var block_climbs := 0

	var _step := Step.RUN_UP
	var _floor_ticks := 0
	var _hopped := false
	var _pressed_in_air := false


	func drive() -> void:
		var state := fighter.state
		var on_block := fighter.position.y > HALF_BLOCK
		if state.on_floor:
			_floor_ticks += 1
		else:
			_floor_ticks = 0
		match _step:
			Step.RUN_UP:
				run(Vector3.FORWARD)
				if state.on_floor and fighter.position.z <= BLOCK_JUMP_Z:
					fighter.input.press_jump()
					_step = Step.CLIMB
			Step.CLIMB:
				run(Vector3.FORWARD)
				if state.on_floor and on_block:
					block_climbs += 1
					_step = Step.NEXT_TICK_HOP
				elif not state.on_floor and state.jumps_used == 1 and fighter.velocity.y < 0.0:
					fighter.input.press_jump()
			Step.NEXT_TICK_HOP:
				# The jump's first tick in the air: the press on the next tick.
				_hop(state, true, Step.APEX_HOP)
			Step.APEX_HOP:
				_hop(state, fighter.velocity.y < 0.0, Step.DONE)
			Step.DONE:
				run(Vector3.ZERO)


	# A hop in place: once the body rests, jump; in the air, press once when `now` says so; after
	# the landing, rest and go to the next step.
	func _hop(state: FighterState, now: bool, next: Step) -> void:
		run(Vector3.ZERO)
		if state.on_floor:
			if not _hopped and _floor_ticks > REST_TICKS:
				fighter.input.press_jump()
				_hopped = true
			elif _hopped and _pressed_in_air and _floor_ticks > REST_TICKS:
				_step = next
				_hopped = false
				_pressed_in_air = false
		elif _hopped and not _pressed_in_air and now:
			fighter.input.press_jump()
			_pressed_in_air = true


# Counts the double jumps of one fighter in its fresh states, after every loop: the state on screen
# is the result of the tick the loop simulated for the first time, NetworkTime.tick - 1. A double
# jump shows as its stamp on that tick; a refusal as a press of that tick kept in the slot, in the
# air with the flight's double jump unused and the bar below the cost: the only reason the double
# jump would not come out (movimento.md, "Stamina": nothing is paid and the press waits).
class Flights:
	var double_jumps := 0
	## Double jumps in a flight with no jump: off a ledge, past the coyote.
	var ledge_double_jumps := 0
	## Double jumps on the tick right after the flight's jump.
	var next_tick_double_jumps := 0
	var refused_double_jumps := 0

	var _fighter: Fighter
	var _config: MovementConfig
	var _jumps_before := 0
	var _jump_tick := FighterState.NEVER


	func _init(watched: Fighter, config: MovementConfig) -> void:
		_fighter = watched
		_config = config
		_jumps_before = watched.state.jumps_used


	func observe() -> void:
		var state := _fighter.state
		var tick := NetworkTime.tick - 1
		if state.jumps_used == 1 and _jumps_before == 0:
			_jump_tick = tick
		if state.double_jump_tick == tick:
			double_jumps += 1
			if _jumps_before == 0:
				ledge_double_jumps += 1
			elif tick == _jump_tick + 1:
				next_tick_double_jumps += 1
		elif _refused(state, tick):
			refused_double_jumps += 1
		_jumps_before = state.jumps_used


	# Adds this fighter's counters to a scenario's paths, summed over its fighters.
	func add_to(paths: Dictionary[String, int]) -> void:
		var mine: Dictionary[String, int] = {
			"double_jumps": double_jumps,
			"ledge_double_jumps": ledge_double_jumps,
			"next_tick_double_jumps": next_tick_double_jumps,
			"refused_double_jumps": refused_double_jumps,
		}
		for path: String in mine:
			if not paths.has(path):
				paths[path] = 0
			paths[path] += mine[path]


	func _refused(state: FighterState, tick: int) -> bool:
		var kept := state.buffered_command == FighterCommand.JUMP and state.buffered_tick == tick
		var unused := not state.on_floor and state.jumps_used < 2
		var short := Stamina.at(state, _config, tick) < _config.double_jump_cost
		return kept and unused and short


# A scripted player of the dash: the Bot's calls plus the dash's press, and what the rules let it
# do on a coming tick, read from the state on screen as a player reads the HUD.
class DashBot:
	extends Bot

	var _config: MovementConfig
	var _floor_ticks := 0


	func _init(played: Fighter, config: MovementConfig) -> void:
		super(played)
		_config = config


	func drive() -> void:
		pass


	func done() -> bool:
		return false


	func _track_floor() -> void:
		_floor_ticks = _floor_ticks + 1 if fighter.state.on_floor else 0


	# True when a dash pressed `ticks` ticks after the next one would come out then, as far as the
	# cooldown and the bar say; the floor is the script's to see.
	func _legal_in(ticks: int) -> bool:
		var tick := NetworkTime.tick + ticks
		var state := fighter.state
		var period := _config.dash_ticks + _config.dash_cooldown_ticks
		var free := tick - state.dash_tick >= period
		return free and Stamina.at(state, _config, tick) >= _config.dash_cost


	func _dashing() -> bool:
		return fighter.state.mode == FighterState.Mode.DASH


# Dashes east over the crest and down the ramp, runs back up onto the platform, dashes west off
# the ledge, then hops and presses the dash just before landing.
class RampLedgeBot:
	extends DashBot

	enum Step {
		STAND,
		RAMP_DASH,
		BACK,
		LEDGE_DASH,
		FALL,
		HOP,
		AIR_DASH,
		DONE,
	}

	var _step := Step.STAND


	func done() -> bool:
		return _step == Step.DONE


	func drive() -> void:
		_track_floor()
		var state := fighter.state
		var where := fighter.position
		var high := where.y > HALF_PLATFORM
		var heading := Vector3.ZERO
		match _step:
			Step.STAND:
				if _floor_ticks > REST_TICKS:
					heading = Vector3.RIGHT
					fighter.input.press_dash()
					_step = Step.RAMP_DASH
			Step.RAMP_DASH:
				if not _dashing() and state.on_floor:
					_step = Step.BACK
			Step.BACK:
				heading = Vector3.LEFT
				if high and where.x < LEDGE_DASH_FROM_X:
					_step = Step.LEDGE_DASH
			Step.LEDGE_DASH:
				if _legal_in(0):
					heading = Vector3.LEFT
					fighter.input.press_dash()
					_step = Step.FALL
			Step.FALL:
				var landed := state.on_floor and not high and not _dashing()
				if landed and _floor_ticks > REST_TICKS and _legal_in(0):
					fighter.input.press_jump()
					_step = Step.HOP
			Step.HOP:
				var falling := not state.on_floor and fighter.velocity.y < 0.0
				if falling and where.y < BUFFER_PRESS_HEIGHT:
					heading = Vector3.LEFT
					fighter.input.press_dash()
					_step = Step.AIR_DASH
			Step.AIR_DASH:
				# The dash takes the direction of the tick it comes out on.
				heading = Vector3.LEFT
				if _dashing():
					_step = Step.DONE
		run(heading)


# Dashes into Block2m's face, presses in the cooldown and with the bar short, dashes on the plane
# with a jump near its end, and once landed presses the dash a little before the bar can pay.
class WallBot:
	extends DashBot

	enum Step {
		STAND,
		WALL_DASH,
		COOLDOWN,
		WAIT_BAR,
		PLANE_DASH,
		FLIGHT,
		BUFFERED,
		DONE,
	}

	var _step := Step.STAND


	func done() -> bool:
		return _step == Step.DONE


	func drive() -> void:
		_track_floor()
		var state := fighter.state
		var heading := Vector3.ZERO
		match _step:
			Step.STAND:
				if _floor_ticks > REST_TICKS:
					heading = Vector3.FORWARD
					fighter.input.press_dash()
					_step = Step.WALL_DASH
			Step.WALL_DASH:
				if not _dashing():
					# The first tick after the dash: a press the cooldown refuses.
					fighter.input.press_dash()
					_step = Step.COOLDOWN
			Step.COOLDOWN:
				var period := _config.dash_ticks + _config.dash_cooldown_ticks
				if NetworkTime.tick - state.dash_tick >= period:
					# The cooldown is over, and the bar of 5 cannot pay: a press the bar refuses.
					fighter.input.press_dash()
					_step = Step.WAIT_BAR
			Step.WAIT_BAR:
				if _legal_in(0):
					heading = Vector3.BACK
					fighter.input.press_dash()
					_step = Step.PLANE_DASH
			Step.PLANE_DASH:
				var exit_tick := state.dash_tick + _config.dash_ticks
				if _dashing() and NetworkTime.tick == exit_tick - JUMP_BEFORE_EXIT:
					fighter.input.press_jump()
				elif state.jumps_used == 1:
					_step = Step.FLIGHT
			Step.FLIGHT:
				var rested := state.on_floor and _floor_ticks > REST_TICKS
				if rested and _legal_in(BAR_AHEAD):
					heading = Vector3.FORWARD
					fighter.input.press_dash()
					_step = Step.BUFFERED
			Step.BUFFERED:
				# The dash takes the direction of the tick it comes out on.
				heading = Vector3.FORWARD
				if _dashing():
					_step = Step.DONE
		run(heading)


# Counts the dash's paths of one fighter in its fresh states, after every loop, like Flights: the
# state on screen is the result of the tick the loop simulated for the first time.
class Dashes:
	## Dashes started.
	var dashes := 0
	## Dashes that came out of the slot: pressed earlier and kept until they could.
	var buffered_dashes := 0
	## Presses on the ground kept in the slot because of the cooldown, or of the bar.
	var refused_cooldown := 0
	var refused_stamina := 0
	## Dash ticks on the ramp's floor, and dash ticks in the air at its crest or foot.
	var ramp_dash_ticks := 0
	var ramp_dash_air_ticks := 0
	## Dashes that left the floor away from the ramp: off a ledge.
	var ledge_dashes := 0
	## Dashes a wall stopped on the floor, below half the dash speed after the engine's move.
	var blocked_dashes := 0
	## Jumps that came out on the first tick after a dash.
	var jumps_after_dash := 0

	var _fighter: Fighter
	var _config: MovementConfig
	var _before: FighterState
	var _ledge_stamp := FighterState.NEVER
	var _blocked_stamp := FighterState.NEVER


	func _init(watched: Fighter, config: MovementConfig) -> void:
		_fighter = watched
		_config = config
		_before = watched.state.copy()


	func observe() -> void:
		var state := _fighter.state
		var tick := NetworkTime.tick - 1
		var dashing := state.mode == FighterState.Mode.DASH
		if dashing and state.dash_tick == tick:
			dashes += 1
			if _before.buffered_command == FighterCommand.DASH:
				buffered_dashes += 1
		_refusals(state, tick)
		if dashing:
			_dash_tick(state)
		var jumped := state.jumps_used == 1 and _before.jumps_used == 0
		if jumped and tick == state.dash_tick + _config.dash_ticks:
			jumps_after_dash += 1
		_before = state.copy()


	# Adds this fighter's counters to a scenario's paths, summed over its fighters.
	func add_to(paths: Dictionary[String, int]) -> void:
		var mine: Dictionary[String, int] = {
			"dashes": dashes,
			"ramp_dash_ticks": ramp_dash_ticks,
			"ramp_dash_air_ticks": ramp_dash_air_ticks,
			"ledge_dashes": ledge_dashes,
			"blocked_dashes": blocked_dashes,
			"buffered_dashes": buffered_dashes,
			"refused_cooldown": refused_cooldown,
			"refused_stamina": refused_stamina,
			"jumps_after_dash": jumps_after_dash,
		}
		for path: String in mine:
			if not paths.has(path):
				paths[path] = 0
			paths[path] += mine[path]


	# A press of this tick kept in the slot on the ground: the only reasons are the cooldown and
	# the bar (movimento.md, "Dash" and "Stamina": nothing is paid and the press waits).
	func _refusals(state: FighterState, tick: int) -> void:
		var kept := state.buffered_command == FighterCommand.DASH and state.buffered_tick == tick
		if not kept or not state.on_floor or state.mode != FighterState.Mode.GROUND:
			return
		if tick - state.dash_tick < _config.dash_ticks + _config.dash_cooldown_ticks:
			refused_cooldown += 1
		elif Stamina.at(state, _config, tick) < _config.dash_cost:
			refused_stamina += 1


	func _dash_tick(state: FighterState) -> void:
		var where := _fighter.position
		var across := absf(where.z) < SyncObserver.RAMP_HALF_WIDTH
		var on_ramp := where.x > SyncObserver.RAMP_FROM_X and where.x < SyncObserver.RAMP_TO_X
		var near_ramp := (
			where.x > SyncObserver.RAMP_FROM_X - HALF_PLATFORM
			and where.x < SyncObserver.RAMP_TO_X + HALF_PLATFORM
		)
		if across and near_ramp:
			if state.on_floor and on_ramp:
				ramp_dash_ticks += 1
			elif not state.on_floor:
				ramp_dash_air_ticks += 1
		elif not state.on_floor and _ledge_stamp != state.dash_tick:
			_ledge_stamp = state.dash_tick
			ledge_dashes += 1
		var speed := Vector2(_fighter.velocity.x, _fighter.velocity.z).length()
		var stopped := state.on_floor and speed < _config.dash_speed / 2.0
		if stopped and _blocked_stamp != state.dash_tick:
			_blocked_stamp = state.dash_tick
			blocked_dashes += 1
