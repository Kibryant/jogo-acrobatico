# Criterion 8 of TASK-9: the permanent SyncTest (rede.md §4; DEC-0025; DEC-0027 §3). The real
# Match runs in Sozinho, Godot's offline peer, with netfox's ticks advanced by hand, one tick per
# loop (test/support/netfox_ticks.gd), and on every loop netfox is told to roll back 7 ticks, the
# depth of a 220 ms ping at 60 ticks (rede.md §4): it restores the state of 7 ticks before the
# present and simulates those 7 ticks, 6 of them again and the newest for the first time. The
# observer (test/support/sync_observer.gd) compares every resimulation of a fighter at a tick
# with the first result of that tick, so state the rollback forgets, a field netfox does not
# record or a flag the engine keeps, shows up as a divergence. The four scenarios go where the
# engine keeps state of its own (DEC-0025): the 45° ramp, the ledge, the landing and two fighters
# pushing each other on the ground. Each prints a summary line that proves its paths ran.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const SyncObserver := preload("res://test/support/sync_observer.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

## Ticks netfox rolls back on every loop: the depth of a 220 ms ping at 60 ticks (rede.md §4).
const DEPTH := 7
## ms: the four scenarios together on Arthur's PC (TASK-9, choice 6).
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

# Pouso: a hop in place on the floor, a jump onto the platform and a hop in place on it; each hop
# presses again just before landing, and the buffer turns that press into a jump on the first
# tick on the floor.
const POUSO_START := Vector3(-4.5, 0, 0)
const POUSO_LOOPS := 235
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

# The self-test needs only the first hop of the pouso scenario.
const SELF_TEST_LOOPS := 90

# The first tick of the run and the tick of the fighters' first recorded state.
var _first_tick := 0
var _first_state_tick := 0


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	if NetworkRollback.before_loop.is_connected(_force_rollback):
		NetworkRollback.before_loop.disconnect(_force_rollback)
	NetfoxTicks.reset()


func test_the_four_scenarios_resimulate_with_zero_divergence() -> void:
	var started := Time.get_ticks_msec()
	var rampa := await _rampa()
	var beirada := await _beirada()
	var pouso := await _pouso(POUSO_LOOPS)
	var empurrao := await _empurrao()
	var spent := Time.get_ticks_msec() - started
	# The budget is for Arthur's PC at rest (TASK-9, choice 6): the gate prints the time on every
	# run, and the reviewer checks it on a quiet run. A busy PC took up to three times as long, so
	# a ceiling here would turn the gate red for nothing; Arthur chose to show it (F-087 §1).
	var budget := "budget %d ms on Arthur's PC at rest" % BUDGET_MS
	print("SyncTest, the four scenarios together: %d ms (%s)" % [spent, budget])

	for observer: SyncObserver in [rampa, beirada, pouso, empurrao]:
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

	# They pushed each other for a while, and on the ground.
	assert_int(empurrao.collisions).is_greater_equal(EMPURRAO_MIN_CONTACTS)
	assert_int(empurrao.takeoffs).is_equal(0)


# The SyncTest's own canary: with on_floor out of what netfox records for the fighter, a rollback
# restores everything but the floor verdict, and the takeoff and landing of the first hop come out
# different when resimulated. If this stops diverging, the SyncTest has lost its teeth.
func test_a_field_netfox_does_not_record_makes_the_sync_test_diverge() -> void:
	var observer := await _pouso(SELF_TEST_LOOPS, ":state:on_floor")
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
	var observer := _start(game_match, "pouso" if hidden.is_empty() else "pouso without " + hidden)
	for _loop: int in loops:
		bot.drive()
		NetfoxTicks.run_loop()
	observer.paths["floor_landings"] = bot.floor_landings
	observer.paths["platform_landings"] = bot.platform_landings
	observer.paths["buffered_jumps"] = bot.buffered_jumps
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


# A Match in the tree with a fighter of each slot standing at its start, placed before netfox
# records its first state: the RollbackSynchronizer registers with call_deferred. The ticks then
# run inside a physics frame (test/support/netfox_ticks.gd). hidden, when not empty, is a state
# property taken out of what netfox records, for the self-test.
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
# each hop presses again just before landing, inside the buffer window.
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


	# A hop in place: once the body rests, press; falling close to the surface, press again; after
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
				_buffered = false
			return
		var falling := fighter.velocity.y < 0.0
		if falling and not _buffered and fighter.position.y - surface < BUFFER_PRESS_HEIGHT:
			fighter.input.press_jump()
			_buffered = true
