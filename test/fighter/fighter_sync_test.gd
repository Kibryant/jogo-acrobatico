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
# cues of the maneuvers: played once per event, as many as the events (DEC-0031 §6). The wall
# scenario, parede (TASK-10.5, criterion 7), runs on walls it builds in the arena, away from the
# arena's own shapes, and has a test of its own; so does the grapple's, gancho (TASK-10.6,
# criterion 8), whose ray the fighter casts again on every resimulated tick that asks for it. The
# head's, cabeca (TASK-10.7, criterion 3), lands a fighter on another's head twice, where the rule
# slides it off, and has a test of its own too.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const SyncObserver := preload("res://test/support/sync_observer.gd")
const AimAt := preload("res://test/support/aim_at.gd")
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

# Parede (TASK-10.5, criterion 7): walls the scenario builds in the arena's empty north-west
# corner, 8 m tall and 1 m thick, every face along Z. The long lane is one plane in two blocks,
# 13 m each, meeting at a seam at z = 26: the runner enters it at full speed and runs until the
# 2,5 s are up, across the seam (F-129). The corridor has the 3,5 m inner gap of the planned one
# (TASK-10.5, "Números v0"): its west wall runs the whole 26 m, its east one stops at z = 27. The
# climber enters the west wall, wall-jumps to the east one and back, wall-jumps once more and
# double-jumps back into the same wall, which refuses it; once landed, it enters the east wall
# near its south end and runs off it. Once the runner has landed from its long run it steps away
# from the lane, runs back into it southward and wall-jumps with the stick pointing north, against
# the run: the turn (TASK-10.10, criterion 6; movimento.md, "A volta no pulo da parede").
const PAREDE_FROM_Z := 13.0
const PAREDE_SEAM_Z := 26.0
const PAREDE_TO_Z := 39.0
const CORRIDOR_EAST_TO_Z := 27.0
const PAREDE_HEIGHT := 8.0
const PAREDE_THICKNESS := 1.0
# The faces: the long lane's looks east from x = -37; the corridor's west wall looks east from
# x = -31 and its east wall looks west from x = -27.5, 3.5 m across.
const LONG_FACE_X := -37.0
const CORRIDOR_WEST_FACE_X := -31.0
const CORRIDOR_EAST_FACE_X := -27.5
const PAREDE_STARTS: Array[Vector3] = [Vector3(-35.5, 0, 12), Vector3(-29.5, 0, 12)]
# The runs into a wall: full speed north with a quarter of it into the wall, about 14°, so the
# speed along it is 6,8 m/s, above the 4 of the entry (movimento.md, "Corrida na parede").
const INTO_WEST := Vector3(-0.25, 0, 1)
const INTO_WEST_SOUTHWARD := Vector3(-0.25, 0, -1)
const INTO_EAST_SOUTHWARD := Vector3(0.25, 0, -1)
# m: after its long run the runner steps this far east of the lane's face before running back in.
const STEP_AWAY := 1.5
# m: the jump comes this far before the capsule would touch the face, at the apex of the jump.
const JUMP_BEFORE_FACE := 0.6
# Ticks on a wall before the climber's wall jump, and ticks after its last wall jump before the
# double jump that turns it back into the same wall.
const RUN_BEFORE_WALL_JUMP := 6
const TURN_BACK_AFTER := 5
const BACK_INTO_WEST := Vector3(-1, 0, 1.5)
const PAREDE_LOOPS := 480
# The self-test needs only the long runner's entry and a few ticks of its run.
const PAREDE_SELF_TEST_LOOPS := 80

# Gancho (TASK-10.6, criterion 8): three walls the scenario builds in the arena's empty south-east,
# away from its shapes and from the towers of TASK-10.6, all faces along X, on a copy of
# movement_v0.tres whose grapple recharges in 500 ms, 30 ticks, so the scenario stays short. The
# north wall's face looks south at z = 20, the south wall's looks north at z = 38, both 16 m wide
# and 10 m tall; between them, a low wall 1 m tall faces south at z = 28 in the east lane only.
# The west fighter presses the grapple at the sky, a miss; hooks the north wall 5 m up and is
# released by the distance; presses again in the cooldown, a refusal; and once landed and
# recharged hooks the south wall and jumps a few ticks into the pull: the release by the jump.
# The east fighter hooks the north wall low, across the low wall: its ray passes over the low
# wall, its feet do not, and the stop releases by the block; then it hooks the south wall and is
# released by the distance (movimento.md, "Gancho").
const GANCHO_STARTS: Array[Vector3] = [Vector3(24, 0, 34), Vector3(32, 0, 34)]
const GANCHO_COOLDOWN_MS := 500
const GANCHO_WALL_X := 28.0
const GANCHO_WALL_WIDTH := 16.0
const GANCHO_WALL_HEIGHT := 10.0
const GANCHO_NORTH_FACE_Z := 20.0
const GANCHO_SOUTH_FACE_Z := 38.0
const GANCHO_LOW_WALL := Vector3(32, 0.5, 27.75)
const GANCHO_LOW_WALL_SIZE := Vector3(4, 1, 0.5)
# The points the fighters aim at: on the north face 5 m up; on the north face 1,3 m up, so the ray
# from O, and the shoulder's second ray too, cross the low wall 1,47 m up, over its 1 m top, while
# the feet's line meets its face; and on the south face. Every point is at least 3 m from the feet,
# horizontally, so the camera aims at it from O (test/support/aim_at.gd; DEC-0045 §2).
const GANCHO_NORTH_HIGH := Vector3(24, 5, 20)
const GANCHO_NORTH_LOW := Vector3(32, 1.3, 20)
const GANCHO_SOUTH_WEST := Vector3(24, 2.5, 38)
const GANCHO_SOUTH_EAST := Vector3(32, 3, 38)
# Degrees: the miss looks this far up, the camera's limit, and the ray finds nothing.
const SKY_PITCH_DEG := 80.0
# Ticks of the pull before the west fighter's jump releases it.
const JUMP_INTO_PULL := 3
const GANCHO_LOOPS := 300
# The self-test needs only the east fighter's first fire and a few ticks of its cable.
const GANCHO_SELF_TEST_LOOPS := 30

# Cabeca (TASK-10.7, criterion 3): in the arena's empty north-west, away from its shapes, the
# fighter below stands still at CABECA_HEAD, and the other runs at it from CABECA_RUN_UP off its
# axis, jumps CABECA_JUMP_FROM before it, double jumps at the apex with no direction and lands on
# its head, as probe C does (test/fighter/head_probe_test.gd). There it presses the jump, which
# the double jump spent leaves in the slot, and the rule slides it off at 3 m/s (movimento.md, "O
# corpo": "A cabeça do outro", "Escorregar da cabeça"). Once on the floor it walks away from the
# axis to CABECA_RUN_UP, stops and does it again from there: two passes.
const CABECA_HEAD := Vector3(-28, 0, -26)
const CABECA_RUN_UP := 2.5
const CABECA_JUMP_FROM := 2.0
# m/s: the run-up, as probe C's: 50 ticks of the jump and the double jump cover the 2 m.
const CABECA_RUN_SPEED := 2.4
# m/s: the walk back out to the next run-up.
const CABECA_WALK_SPEED := 3.5
# m: feet resting this high are on the other's head, its top 1,8 m above the floor.
const CABECA_HEAD_MIN_Y := 1.0
const CABECA_PASSES := 2
const CABECA_LOOPS := 400
# The self-test needs the first landing and a few ticks on the head.
const CABECA_SELF_TEST_LOOPS := 100

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


# Criterion 7 of TASK-10.5: the wall run under the rollback of 7 ticks on every tick, with zero
# divergence in the whole state: the entries, the end by time, the end at the wall's edge, the
# wall jumps from one wall to the other, the same wall refused, a double jump after a wall jump
# and a seam crossed in the run (F-129). TASK-10.10 adds a turned wall jump (criterion 6) and the
# head ray on every wall contact: the walls are 8 m tall, so they cover the body. As many cues as
# wall jumps, double jumps and wall runs, each run a short trail (movimento.md, "O que se vê na
# parede").
func test_the_wall_scenario_resimulates_with_zero_divergence() -> void:
	var parede := await _parede(PAREDE_LOOPS)
	var message := "%s diverged:\n%s" % [parede.scenario, "\n".join(parede.shown)]
	assert_int(parede.mismatches).override_failure_message(message).is_equal(0)
	assert_int(parede.paths["wall_entries"]).is_greater_equal(3)
	assert_int(parede.paths["wall_timeouts"]).is_greater_equal(1)
	assert_int(parede.paths["edge_exits"]).is_greater_equal(1)
	assert_int(parede.paths["wall_jumps"]).is_greater_equal(2)
	assert_int(parede.paths["wall_to_wall"]).is_greater_equal(1)
	assert_int(parede.paths["same_wall_refusals"]).is_greater_equal(1)
	assert_int(parede.paths["double_jumps_after_wall"]).is_greater_equal(1)
	assert_int(parede.paths["seams"]).is_greater_equal(1)
	assert_int(parede.paths["turned_wall_jumps"]).is_greater_equal(1)
	assert_int(parede.paths["bots_done"]).is_equal(PAREDE_STARTS.size())
	var cued := parede.paths["wall_jumps"] + parede.paths["double_jumps"]
	_assert_cues(parede, cued + parede.paths["wall_entries"])


# The wall's identity in the state (DEC-0042 §2): out of the recording, a rollback across the
# entry brings back the wall of the present on the ticks before it.
func test_the_wall_id_netfox_does_not_record_makes_the_sync_test_diverge() -> void:
	var observer := await _parede(PAREDE_SELF_TEST_LOOPS, ":state:wall_id")
	assert_int(observer.mismatches).is_greater(0)


# Criterion 8 of TASK-10.6: the grapple under the rollback of 7 ticks on every tick, with zero
# divergence in the whole state: four fires, their pulls, the releases by the distance, the jump
# and the block, a miss at the sky and a press refused in the cooldown. The fighter casts the ray
# again on every resimulated tick whose plan asks for it, so each fire comes out again on its
# resimulations (DEC-0044 §1). As many cues as cables and pulls (DEC-0031 §6).
func test_the_grapple_scenario_resimulates_with_zero_divergence() -> void:
	var gancho := await _gancho(GANCHO_LOOPS)
	var message := "%s diverged:\n%s" % [gancho.scenario, "\n".join(gancho.shown)]
	assert_int(gancho.mismatches).override_failure_message(message).is_equal(0)
	assert_int(gancho.paths["grapple_fires"]).is_greater_equal(4)
	assert_int(gancho.paths["attaches"]).is_greater_equal(3)
	assert_int(gancho.paths["releases_by_distance"]).is_greater_equal(1)
	assert_int(gancho.paths["releases_by_jump"]).is_greater_equal(1)
	assert_int(gancho.paths["releases_by_block"]).is_greater_equal(1)
	assert_int(gancho.paths["misses"]).is_greater_equal(1)
	assert_int(gancho.paths["refused_grapples"]).is_greater_equal(1)
	# Every fire came out again when its tick was simulated again: the ray was cast again there.
	assert_int(gancho.paths["resimulated_fires"]).is_greater_equal(gancho.paths["grapple_fires"])
	assert_int(gancho.paths["bots_done"]).is_equal(GANCHO_STARTS.size())
	_assert_cues(gancho, gancho.paths["grapple_fires"] + gancho.paths["attaches"])


# The grapple's point in the state: out of the recording, a rollback across the fire brings the
# point of the present back on the ticks before it, where the fresh state had none.
func test_the_grapple_point_netfox_does_not_record_makes_the_sync_test_diverge() -> void:
	var observer := await _gancho(GANCHO_SELF_TEST_LOOPS, ":state:grapple_point")
	assert_int(observer.paths["grapple_fires"]).is_greater_equal(1)
	assert_int(observer.mismatches).is_greater(0)


# Criterion 3 of TASK-10.7: the head under the rollback of 7 ticks on every tick, with zero
# divergence in the whole state, as probe C found on the code before the rule (rede.md §4, "A
# sonda C"): two landings on the head, two slides off it, a jump pressed on the head and refused
# there, and no tick where the rules stood on it. As many cues as double jumps and slides, one
# slide per landing (DEC-0031 §6).
func test_the_head_scenario_resimulates_with_zero_divergence() -> void:
	var cabeca := await _cabeca(CABECA_LOOPS)
	var message := "%s diverged:\n%s" % [cabeca.scenario, "\n".join(cabeca.shown)]
	assert_int(cabeca.mismatches).override_failure_message(message).is_equal(0)
	assert_int(cabeca.paths["head_landings"]).is_greater_equal(2)
	assert_int(cabeca.paths["slide_offs"]).is_greater_equal(2)
	assert_int(cabeca.paths["head_jump_refusals"]).is_greater_equal(1)
	assert_int(cabeca.paths["head_floor_ticks"]).is_equal(0)
	assert_int(cabeca.collisions).is_greater_equal(1)
	assert_int(cabeca.paths["bots_done"]).is_equal(1)
	assert_int(cabeca.paths["head_slides"]).is_equal(cabeca.paths["head_landings"])
	_assert_cues(cabeca, cabeca.paths["double_jumps"] + cabeca.paths["head_slides"])


# The slide's direction in the state: out of the recording, a rollback across the landing brings
# the present's direction back on the ticks before it, where the body was not on the head, and the
# slide pushes it there.
func test_the_slide_off_dir_netfox_does_not_record_makes_the_sync_test_diverge() -> void:
	var observer := await _cabeca(CABECA_SELF_TEST_LOOPS, ":state:slide_off_dir")
	assert_int(observer.paths["head_landings"]).is_greater_equal(1)
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


func _parede(loops: int, hidden := "") -> SyncObserver:
	var game_match := await _match_with(PAREDE_STARTS, hidden)
	_build_parede(game_match.arena)
	var config := game_match.config
	var bots: Array[DashBot] = [
		LongWallBot.new(game_match.fighters[0], config),
		CorridorBot.new(game_match.fighters[1], config),
	]
	var walls: Array[Walls] = []
	for fighter: Fighter in game_match.fighters:
		walls.append(Walls.new(fighter, config, game_match.arena))
	var scenario := "parede" if hidden.is_empty() else "parede without " + hidden
	var observer := _start(game_match, scenario)
	for _loop: int in loops:
		for bot: DashBot in bots:
			bot.drive()
		NetfoxTicks.run_loop()
		for path: Walls in walls:
			path.observe()
	for path: Walls in walls:
		path.add_to(observer.paths)
	observer.paths["bots_done"] = 0
	for bot: DashBot in bots:
		observer.paths["bots_done"] += 1 if bot.done() else 0
	_add_cues(observer, game_match)
	return _finish(observer, game_match)


func _gancho(loops: int, hidden := "") -> SyncObserver:
	var game_match := await _match_with(GANCHO_STARTS, hidden, _gancho_data())
	_build_gancho(game_match.arena)
	var config := game_match.config
	var bots: Array[DashBot] = [
		WestHookBot.new(game_match.fighters[0], config),
		EastHookBot.new(game_match.fighters[1], config),
	]
	var scenario := "gancho" if hidden.is_empty() else "gancho without " + hidden
	var observer := _start(game_match, scenario)
	var grapples := Grapples.new(game_match.fighters, config)
	for _loop: int in loops:
		for bot: DashBot in bots:
			bot.drive()
		NetfoxTicks.run_loop()
	grapples.stop()
	grapples.add_to(observer.paths)
	observer.paths["bots_done"] = 0
	for bot: DashBot in bots:
		observer.paths["bots_done"] += 1 if bot.done() else 0
	_add_cues(observer, game_match)
	return _finish(observer, game_match)


func _cabeca(loops: int, hidden := "") -> SyncObserver:
	var starts: Array[Vector3] = [CABECA_HEAD + Vector3(0, 0, CABECA_RUN_UP), CABECA_HEAD]
	var game_match := await _match_with(starts, hidden)
	var config := game_match.config
	var top := game_match.fighters[0]
	var below := Bot.new(game_match.fighters[1])
	var bot := HeadBot.new(top, CABECA_HEAD, config)
	var scenario := "cabeca" if hidden.is_empty() else "cabeca without " + hidden
	var observer := _start(game_match, scenario)
	var heads := Heads.new(top)
	for _loop: int in loops:
		if bot.done():
			break
		bot.drive()
		below.run(Vector3.ZERO)
		NetfoxTicks.run_loop()
		heads.observe()
	heads.add_to(observer.paths)
	observer.paths["head_jump_refusals"] = bot.refusals
	observer.paths["bots_done"] = 1 if bot.done() else 0
	_add_cues(observer, game_match)
	return _finish(observer, game_match)


# The walls of gancho, built in the arena at run time on the world's layer.
func _build_gancho(arena: Arena) -> void:
	var wide := Vector3(GANCHO_WALL_WIDTH, GANCHO_WALL_HEIGHT, PAREDE_THICKNESS)
	var half := PAREDE_THICKNESS / 2.0
	var middle := GANCHO_WALL_HEIGHT / 2.0
	_gancho_box(
		arena,
		&"GanchoNorte",
		Vector3(GANCHO_WALL_X, middle, GANCHO_NORTH_FACE_Z - half),
		wide,
	)
	_gancho_box(
		arena,
		&"GanchoSul",
		Vector3(GANCHO_WALL_X, middle, GANCHO_SOUTH_FACE_Z + half),
		wide,
	)
	_gancho_box(arena, &"GanchoMureta", GANCHO_LOW_WALL, GANCHO_LOW_WALL_SIZE)


func _gancho_box(arena: Arena, wall_name: StringName, center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = wall_name
	body.collision_layer = PhysicsLayers.WORLD
	body.position = center
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	arena.add_child(body)


# The walls of parede, built in the arena at run time on the world's layer, so their paths
# relative to it are their names (DEC-0042 §2).
func _build_parede(arena: Arena) -> void:
	var half := PAREDE_THICKNESS / 2.0
	_parede_box(arena, &"ParedeTesteSul", LONG_FACE_X - half, PAREDE_FROM_Z, PAREDE_SEAM_Z)
	_parede_box(arena, &"ParedeTesteNorte", LONG_FACE_X - half, PAREDE_SEAM_Z, PAREDE_TO_Z)
	_parede_box(
		arena,
		&"CorredorTesteOeste",
		CORRIDOR_WEST_FACE_X - half,
		PAREDE_FROM_Z,
		PAREDE_TO_Z,
	)
	_parede_box(
		arena,
		&"CorredorTesteLeste",
		CORRIDOR_EAST_FACE_X + half,
		PAREDE_FROM_Z,
		CORRIDOR_EAST_TO_Z,
	)


func _parede_box(arena: Arena, wall_name: StringName, x: float, from_z: float, to_z: float) -> void:
	var body := StaticBody3D.new()
	body.name = wall_name
	body.collision_layer = PhysicsLayers.WORLD
	body.position = Vector3(x, PAREDE_HEIGHT / 2.0, (from_z + to_z) / 2.0)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(PAREDE_THICKNESS, PAREDE_HEIGHT, to_z - from_z)
	collision.shape = shape
	body.add_child(collision)
	arena.add_child(body)


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


# The movement numbers of gancho: a copy of movement_v0.tres whose grapple recharges in 500 ms,
# checked like any design data.
func _gancho_data() -> MovementData:
	var resource: Resource = load(Match.MOVEMENT_DATA_PATH)
	assert(resource is MovementData, "%s must load as a MovementData" % Match.MOVEMENT_DATA_PATH)
	var copy := resource.duplicate()
	assert(copy is MovementData, "a copy of a MovementData is a MovementData")
	var data := copy as MovementData
	data.grapple_cooldown_ms = GANCHO_COOLDOWN_MS
	assert_array(data.validate()).override_failure_message("the grapple's fixture").is_empty()
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
		fighter.input.sample_frame(FORWARD, yaw_along(direction))


	# The yaw that looks along a horizontal world direction: yaw 0 looks down -Z, and forward
	# turned by yaw is (-sin(yaw), 0, -cos(yaw)).
	static func yaw_along(direction: Vector3) -> float:
		return atan2(-direction.x, -direction.z)


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


# Runs north into the long lane's face, jumping just before it, and rides the run to its end by
# time, across the seam; then it lands, steps away from the face, runs back into it southward and
# wall-jumps with the stick pointing north, against the run: the turn (TASK-10.10). Then it lands
# and stands.
class LongWallBot:
	extends DashBot

	enum Step {
		STAND,
		RUN_IN,
		ON_WALL,
		STEP_AWAY,
		RUN_BACK_IN,
		ON_WALL_SOUTHWARD,
		TURNED,
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
					_step = Step.RUN_IN
			Step.RUN_IN:
				heading = INTO_WEST.normalized()
				var touch_x := LONG_FACE_X + _config.capsule_radius
				if state.on_floor and fighter.position.x <= touch_x + JUMP_BEFORE_FACE:
					fighter.input.press_jump()
				if state.mode == FighterState.Mode.WALL_RUN:
					_step = Step.ON_WALL
			Step.ON_WALL:
				if state.on_floor:
					_step = Step.STEP_AWAY
			Step.STEP_AWAY:
				heading = Vector3.RIGHT
				if fighter.position.x >= LONG_FACE_X + STEP_AWAY:
					_step = Step.RUN_BACK_IN
			Step.RUN_BACK_IN:
				heading = INTO_WEST_SOUTHWARD.normalized()
				var touch_x := LONG_FACE_X + _config.capsule_radius
				if state.on_floor and fighter.position.x <= touch_x + JUMP_BEFORE_FACE:
					fighter.input.press_jump()
				if state.mode == FighterState.Mode.WALL_RUN:
					_step = Step.ON_WALL_SOUTHWARD
			Step.ON_WALL_SOUTHWARD:
				if NetworkTime.tick - state.mode_since == RUN_BEFORE_WALL_JUMP:
					# North, against the run going south: the stick turns the wall jump back.
					heading = Vector3.BACK
					fighter.input.press_jump()
					_step = Step.TURNED
			Step.TURNED:
				if state.on_floor:
					_step = Step.DONE
		run(heading)


# Climbs the corridor: into its west wall, a wall jump to the east one and one back, a last wall
# jump and a double jump back into the same west wall, which refuses it; then from the floor into
# the east wall near its south end, and off its edge.
class CorridorBot:
	extends DashBot

	enum Step {
		STAND,
		RUN_IN,
		ON_WEST,
		TO_EAST,
		TO_WEST,
		OFF_WEST,
		BACK_WEST,
		LANDED,
		EDGE_IN,
		ON_EDGE,
		DONE,
	}

	var _step := Step.STAND


	func done() -> bool:
		return _step == Step.DONE


	func drive() -> void:
		_track_floor()
		var state := fighter.state
		var where := fighter.position
		var running := state.mode == FighterState.Mode.WALL_RUN
		var heading := Vector3.ZERO
		match _step:
			Step.STAND:
				if _floor_ticks > REST_TICKS:
					_step = Step.RUN_IN
			Step.RUN_IN:
				heading = INTO_WEST.normalized()
				var touch_x := CORRIDOR_WEST_FACE_X + _config.capsule_radius
				if state.on_floor and where.x <= touch_x + JUMP_BEFORE_FACE:
					fighter.input.press_jump()
				if running:
					_step = Step.ON_WEST
			Step.ON_WEST:
				_wall_jump_after_run(Step.TO_EAST)
			Step.TO_EAST:
				_wall_jump_after_run(Step.TO_WEST)
			Step.TO_WEST:
				_wall_jump_after_run(Step.OFF_WEST)
			Step.OFF_WEST:
				if NetworkTime.tick - state.wall_jump_tick == TURN_BACK_AFTER:
					heading = BACK_INTO_WEST.normalized()
					fighter.input.press_jump()
					_step = Step.BACK_WEST
			Step.BACK_WEST:
				if state.on_floor:
					_step = Step.LANDED
			Step.LANDED:
				if _floor_ticks > REST_TICKS:
					_step = Step.EDGE_IN
			Step.EDGE_IN:
				heading = INTO_EAST_SOUTHWARD.normalized()
				var touch_x := CORRIDOR_EAST_FACE_X - _config.capsule_radius
				var beside := where.z < CORRIDOR_EAST_TO_Z - 1.0
				if state.on_floor and beside and where.x >= touch_x - JUMP_BEFORE_FACE:
					fighter.input.press_jump()
				if running:
					_step = Step.ON_EDGE
			Step.ON_EDGE:
				if not running:
					_step = Step.DONE
		run(heading)


	# On a wall run, the wall jump once the run is RUN_BEFORE_WALL_JUMP ticks old, then the next
	# step; in the air, it waits for the next wall.
	func _wall_jump_after_run(next: Step) -> void:
		var state := fighter.state
		if state.mode != FighterState.Mode.WALL_RUN:
			return
		if NetworkTime.tick - state.mode_since == RUN_BEFORE_WALL_JUMP:
			fighter.input.press_jump()
			_step = next


# Counts the wall's paths of one fighter in its fresh states, after every loop, like Flights: the
# state on screen is the result of the tick the loop simulated for the first time, and the slide
# collisions are still those of its move. The end of a run that is neither by time, nor the wall
# jump, nor the floor, with the body past the end of the face it ran on, is the edge; a touch of
# the last wall's face in the air, out of a run, is the same wall refusing (movimento.md,
# "Corrida na parede": "Mesma parede").
class Walls:
	var wall_entries := 0
	var wall_timeouts := 0
	var edge_exits := 0
	var wall_jumps := 0
	var wall_to_wall := 0
	var same_wall_refusals := 0
	var double_jumps := 0
	var double_jumps_after_wall := 0
	var seams := 0
	## Wall jumps whose velocity along the wall came out against the run's: the turn (TASK-10.10).
	var turned_wall_jumps := 0

	var _fighter: Fighter
	var _config: MovementConfig
	var _arena: Node
	var _before: FighterState
	var _before_velocity := Vector3.ZERO
	# The wall of the last wall jump, until the floor: the next entry on another wall is a hop.
	var _jumped_from: StringName = &""
	var _refusing := false


	func _init(watched: Fighter, config: MovementConfig, arena: Node) -> void:
		_fighter = watched
		_config = config
		_arena = arena
		_before = watched.state.copy()


	func observe() -> void:
		var state := _fighter.state
		var tick := NetworkTime.tick - 1
		var running := state.mode == FighterState.Mode.WALL_RUN
		var was_running := _before.mode == FighterState.Mode.WALL_RUN
		if state.on_floor:
			_jumped_from = &""
		if running and state.mode_since == tick:
			wall_entries += 1
			if not _jumped_from.is_empty() and state.wall_id != _jumped_from:
				wall_to_wall += 1
		elif running and was_running and state.wall_id != _before.wall_id:
			seams += 1
		var jumped := state.wall_jump_tick == tick
		if was_running and not running and not jumped and not state.on_floor:
			if tick - _before.mode_since >= _config.wall_run_max_ticks:
				wall_timeouts += 1
			elif _past_the_end(_before.wall_id):
				edge_exits += 1
		if jumped:
			wall_jumps += 1
			_jumped_from = state.wall_id
			var run_along := _along(_before_velocity, state.wall_normal)
			if run_along.dot(_along(_fighter.velocity, state.wall_normal)) < 0.0:
				turned_wall_jumps += 1
		if state.double_jump_tick == tick:
			double_jumps += 1
			if state.mode == FighterState.Mode.AIR and state.mode_since == state.wall_jump_tick:
				double_jumps_after_wall += 1
		var refused := state.mode == FighterState.Mode.AIR and _touches_the_last_wall(state)
		if refused and not _refusing:
			same_wall_refusals += 1
		_refusing = refused
		_before = state.copy()
		_before_velocity = _fighter.velocity


	func add_to(paths: Dictionary[String, int]) -> void:
		var mine: Dictionary[String, int] = {
			"wall_entries": wall_entries,
			"wall_timeouts": wall_timeouts,
			"edge_exits": edge_exits,
			"wall_jumps": wall_jumps,
			"wall_to_wall": wall_to_wall,
			"same_wall_refusals": same_wall_refusals,
			"double_jumps": double_jumps,
			"double_jumps_after_wall": double_jumps_after_wall,
			"seams": seams,
			"turned_wall_jumps": turned_wall_jumps,
		}
		for path: String in mine:
			if not paths.has(path):
				paths[path] = 0
			paths[path] += mine[path]


	# The horizontal velocity along a wall: its part on the plane of the flat normal.
	static func _along(velocity: Vector3, normal: Vector3) -> Vector3:
		var horizontal := Vector3(velocity.x, 0.0, velocity.z)
		return horizontal - normal * horizontal.dot(normal)


	# The body is north or south of the face of the wall it ran on, as parede builds it.
	func _past_the_end(wall: StringName) -> bool:
		var z := _fighter.position.z
		var to_z := CORRIDOR_EAST_TO_Z if wall == &"CorredorTesteLeste" else PAREDE_TO_Z
		return z < PAREDE_FROM_Z or z > to_z


	# The move of this tick hit the face of the state's last wall: the same collider, within the
	# same-face angle.
	func _touches_the_last_wall(state: FighterState) -> bool:
		if state.wall_id.is_empty():
			return false
		for slide: int in _fighter.get_slide_collision_count():
			var collision := _fighter.get_slide_collision(slide)
			for index: int in collision.get_collision_count():
				var collider := collision.get_collider(index)
				if collider is not Node:
					continue
				var node := collider as Node
				var path := StringName(str(_arena.get_path_to(node)))
				var normal := collision.get_normal(index)
				var flat := Vector3(normal.x, 0.0, normal.z).normalized()
				var same_face := flat.dot(state.wall_normal) >= _config.wall_same_face_cos
				if path == state.wall_id and same_face:
					return true
		return false


# A scripted player of the grapple: the dash bot's floor and numbers, and the camera aimed from
# the shoulder at a point, as the mouse would aim it, with the press of the Q.
class HookBot:
	extends DashBot

	var _pressed_tick := FighterState.NEVER


	# Samples a frame whose camera aims the ray from the point O through point (DEC-0045 §2;
	# test/support/aim_at.gd), no push, and presses the grapple: its press is this loop's tick.
	func _hook(point: Vector3) -> void:
		var feet := fighter.position
		var yaw := AimAt.yaw_to(feet, point, _config)
		fighter.input.sample_frame(Vector2.ZERO, yaw, AimAt.pitch_to(feet, point, _config))
		fighter.input.press_grapple()
		_pressed_tick = NetworkTime.tick


	# The camera at its highest, looking north: the ray climbs 24,6 m over the 4,3 m it goes
	# forward, far above every wall, and finds nothing.
	func _look_at_the_sky() -> void:
		fighter.input.sample_frame(Vector2.ZERO, 0.0, deg_to_rad(SKY_PITCH_DEG))


	func _released() -> bool:
		return fighter.state.grapple_end_tick != FighterState.NEVER


	func _recharged_and_rested() -> bool:
		var state := fighter.state
		var recharged := NetworkTime.tick - state.grapple_end_tick >= _config.grapple_cooldown_ticks
		return state.on_floor and _floor_ticks > REST_TICKS and recharged


# The west lane: a miss at the sky, a pull released by the distance at the north wall, a press
# refused in the cooldown, then a pull toward the south wall released by a jump.
class WestHookBot:
	extends HookBot

	enum Step {
		STAND,
		MISS,
		NORTH,
		REFUSE,
		LAND,
		SOUTH,
		JUMP_OFF,
		DONE,
	}

	var _step := Step.STAND
	var _released_at := FighterState.NEVER


	func done() -> bool:
		return _step == Step.DONE


	func drive() -> void:
		_track_floor()
		var state := fighter.state
		match _step:
			Step.STAND:
				if _floor_ticks > REST_TICKS:
					_look_at_the_sky()
					fighter.input.press_grapple()
					_pressed_tick = NetworkTime.tick
					_step = Step.MISS
					return
			Step.MISS:
				# The press asks on every tick of its window: the camera stays on the sky.
				if NetworkTime.tick - _pressed_tick <= _config.buffer_ticks + 1:
					_look_at_the_sky()
					return
				_hook(GANCHO_NORTH_HIGH)
				_step = Step.NORTH
				return
			Step.NORTH:
				if _released():
					_released_at = state.grapple_end_tick
					_step = Step.REFUSE
			Step.REFUSE:
				# Two ticks after the release, deep in the cooldown: the press waits and dies.
				if NetworkTime.tick - _released_at == 2:
					_hook(GANCHO_SOUTH_WEST)
					_step = Step.LAND
					return
			Step.LAND:
				if _recharged_and_rested():
					_hook(GANCHO_SOUTH_WEST)
					_step = Step.SOUTH
					return
			Step.SOUTH:
				var pulling := state.mode == FighterState.Mode.GRAPPLE
				if pulling and NetworkTime.tick - state.mode_since == JUMP_INTO_PULL:
					fighter.input.press_jump()
					_step = Step.JUMP_OFF
			Step.JUMP_OFF:
				if state.on_floor and _floor_ticks > REST_TICKS:
					_step = Step.DONE
		run(Vector3.ZERO)


# The east lane: a pull across the low wall that the stop releases by the block, then a pull
# toward the south wall released by the distance.
class EastHookBot:
	extends HookBot

	enum Step {
		STAND,
		BLOCKED,
		LAND,
		SOUTH,
		DONE,
	}

	var _step := Step.STAND


	func done() -> bool:
		return _step == Step.DONE


	func drive() -> void:
		_track_floor()
		match _step:
			Step.STAND:
				if _floor_ticks > REST_TICKS:
					_hook(GANCHO_NORTH_LOW)
					_step = Step.BLOCKED
					return
			Step.BLOCKED:
				if _released():
					_step = Step.LAND
			Step.LAND:
				if _recharged_and_rested():
					_hook(GANCHO_SOUTH_EAST)
					_step = Step.SOUTH
					return
			Step.SOUTH:
				var end := fighter.state.grapple_end_tick
				if end > _pressed_tick and fighter.state.on_floor and _floor_ticks > REST_TICKS:
					_step = Step.DONE
		run(Vector3.ZERO)


# Counts the grapple's paths of the fighters on netfox's after_process_tick, which comes after
# every fighter of the tick has moved: on a fresh tick, the fires, the pulls' starts, the releases
# by their cause, the misses and the refusals, from the state after the tick and the one before
# it; on a resimulated tick, the fires that came out again, which only a ray cast again can give
# (DEC-0044 §1). A release is by the jump when the tick's own input pressed it, by the distance
# when the feet started the tick within the release distance, otherwise by the block
# (movimento.md, "Gancho": "Como solta", "Trava").
class Grapples:
	var grapple_fires := 0
	var attaches := 0
	var releases_by_distance := 0
	var releases_by_jump := 0
	var releases_by_block := 0
	## Legal presses whose window closed with no fire: every tick of it asked and found nothing.
	var misses := 0
	## Presses kept in the slot while the grapple could not fire: the cooldown, or a cable out.
	var refused_grapples := 0
	var resimulated_fires := 0

	var _fighters: Array[Fighter] = []
	var _config: MovementConfig
	var _before: Array[FighterState] = []
	var _feet_before: Array[Vector3] = []
	var _newest: int


	func _init(fighters: Array[Fighter], config: MovementConfig) -> void:
		_fighters.assign(fighters)
		_config = config
		for fighter: Fighter in fighters:
			_before.append(fighter.state.copy())
			_feet_before.append(fighter.position)
		_newest = NetworkTime.tick - 1
		NetworkRollback.after_process_tick.connect(_observe)


	func stop() -> void:
		NetworkRollback.after_process_tick.disconnect(_observe)


	func add_to(paths: Dictionary[String, int]) -> void:
		paths["grapple_fires"] = grapple_fires
		paths["attaches"] = attaches
		paths["releases_by_distance"] = releases_by_distance
		paths["releases_by_jump"] = releases_by_jump
		paths["releases_by_block"] = releases_by_block
		paths["misses"] = misses
		paths["refused_grapples"] = refused_grapples
		paths["resimulated_fires"] = resimulated_fires


	func _observe(tick: int) -> void:
		var fresh := tick > _newest
		if fresh:
			_newest = tick
		for index: int in _fighters.size():
			var fighter := _fighters[index]
			var state := fighter.state
			if not fresh:
				if state.grapple_fired_tick == tick:
					resimulated_fires += 1
				continue
			if state.grapple_fired_tick == tick:
				grapple_fires += 1
			if state.mode == FighterState.Mode.GRAPPLE and state.mode_since == tick:
				attaches += 1
			if state.grapple_end_tick == tick:
				_note_release(fighter, index)
			_note_presses(state, _before[index], tick)
			_before[index] = state.copy()
			_feet_before[index] = fighter.position


	func _note_release(fighter: Fighter, index: int) -> void:
		var before := _before[index]
		var reach := _feet_before[index].distance_to(before.grapple_point)
		if fighter.input.to_tick_input().jump:
			releases_by_jump += 1
		elif reach <= _config.grapple_release_distance:
			releases_by_distance += 1
		else:
			releases_by_block += 1


	func _note_presses(state: FighterState, before: FighterState, tick: int) -> void:
		var pressed := state.buffered_command == FighterCommand.GRAPPLE
		if pressed and state.buffered_tick == tick:
			if not Movement.can_grapple(state, tick, _config):
				refused_grapples += 1
		var waited := before.buffered_command == FighterCommand.GRAPPLE
		var gone := state.buffered_command == FighterCommand.NONE
		var no_fire := state.grapple_fired_tick == FighterState.NEVER
		var closed := tick - before.buffered_tick > _config.buffer_ticks
		if (
			waited and gone and no_fire and closed
			and Movement.can_grapple(before, tick - 1, _config)
		):
			misses += 1


# The head's route (cabeca): from CABECA_RUN_UP off the axis it runs at it, jumps CABECA_JUMP_FROM
# before it, double jumps at the apex with no direction, lands on the head and presses the jump
# there, then waits for the slide and the fall; on the floor it walks straight away from the axis
# back to CABECA_RUN_UP, stops, and goes again, CABECA_PASSES times.
class HeadBot:
	extends Bot

	## m/s: slower than this on the floor, the body has stopped.
	const STILL_MPS := 0.01

	enum Phase {
		TO_START,
		STOP,
		RUN,
		RISE,
		DOUBLE,
		ON_HEAD,
		OFF_HEAD,
		DONE,
	}

	## Jumps pressed on the head that did not fire there: they stayed in the slot.
	var refusals := 0

	var _axis: Vector3
	var _config: MovementConfig
	var _phase := Phase.STOP
	var _passes := 0
	var _pressed_on_head := false
	var _press_checked := false
	var _yaw := 0.0


	func _init(played: Fighter, axis: Vector3, config: MovementConfig) -> void:
		super(played)
		_axis = axis
		_config = config


	func done() -> bool:
		return _phase == Phase.DONE


	func drive() -> void:
		var state := fighter.state
		var off_axis := Vector3(fighter.position.x - _axis.x, 0, fighter.position.z - _axis.z)
		match _phase:
			Phase.TO_START:
				if state.on_floor and off_axis.length() >= CABECA_RUN_UP:
					_phase = Phase.STOP
					_sample(Vector2.ZERO)
				else:
					_yaw = Bot.yaw_along(off_axis)
					_sample(FORWARD * CABECA_WALK_SPEED / _config.run_speed)
			Phase.STOP:
				_sample(Vector2.ZERO)
				var speed := Vector3(fighter.velocity.x, 0, fighter.velocity.z).length()
				if state.on_floor and speed < STILL_MPS:
					_yaw = Bot.yaw_along(-off_axis)
					_phase = Phase.RUN
			Phase.RUN:
				_yaw = Bot.yaw_along(-off_axis)
				_sample(FORWARD * CABECA_RUN_SPEED / _config.run_speed)
				if state.on_floor and off_axis.length() <= CABECA_JUMP_FROM:
					fighter.input.press_jump()
					_phase = Phase.RISE
			Phase.RISE:
				if not state.on_floor and state.jumps_used == 1 and fighter.velocity.y <= 0.0:
					_sample(Vector2.ZERO)
					fighter.input.press_jump()
					_phase = Phase.DOUBLE
				else:
					_sample(FORWARD * CABECA_RUN_SPEED / _config.run_speed)
			Phase.DOUBLE:
				_sample(Vector2.ZERO)
				if _on_head():
					_pressed_on_head = false
					_press_checked = false
					_phase = Phase.ON_HEAD
				elif state.on_floor:
					_phase = Phase.OFF_HEAD
			Phase.ON_HEAD:
				_sample(Vector2.ZERO)
				# The tick after the press: the jump waits in the slot, both jumps used, and the
				# body did not rise.
				if _pressed_on_head and not _press_checked:
					_press_checked = true
					var waits := state.buffered_command == FighterCommand.JUMP
					if waits and state.jumps_used == 2 and fighter.velocity.y <= 0.0:
						refusals += 1
				if not _on_head():
					_phase = Phase.OFF_HEAD
				elif not _pressed_on_head:
					fighter.input.press_jump()
					_pressed_on_head = true
			Phase.OFF_HEAD:
				_sample(Vector2.ZERO)
				if state.on_floor and fighter.position.y < CABECA_HEAD_MIN_Y:
					_passes += 1
					_phase = Phase.DONE if _passes >= CABECA_PASSES else Phase.TO_START


	func _on_head() -> bool:
		return fighter.state.on_floor and fighter.position.y > CABECA_HEAD_MIN_Y


	func _sample(move: Vector2) -> void:
		fighter.input.sample_frame(move, _yaw)


# Counts what the head did on the fresh ticks of one fighter, from the state on screen after each
# loop: the landings on a head, the slides off it, the slides' keys (head_landing_tick), the double
# jumps, and the ticks on a head where the rules stood, which the rule forbids.
class Heads:
	var _fighter: Fighter
	var _was_on_head := false
	var _landings := 0
	var _slide_offs := 0
	var _floor_ticks := 0
	var _slides: Dictionary[int, bool] = { }
	var _double_jumps: Dictionary[int, bool] = { }


	func _init(watched: Fighter) -> void:
		_fighter = watched


	func observe() -> void:
		var state := _fighter.state
		var on_head := state.on_floor and _fighter.position.y > CABECA_HEAD_MIN_Y
		if on_head and not _was_on_head:
			_landings += 1
		if _was_on_head and not on_head and state.slide_off_dir == Vector3.ZERO:
			_slide_offs += 1
		if on_head and Movement.stands(state):
			_floor_ticks += 1
		if state.slide_off_dir != Vector3.ZERO:
			_slides[state.head_landing_tick] = true
		if state.double_jump_tick != FighterState.NEVER:
			_double_jumps[state.double_jump_tick] = true
		_was_on_head = on_head


	func add_to(paths: Dictionary[String, int]) -> void:
		paths["head_landings"] = _landings
		paths["slide_offs"] = _slide_offs
		paths["head_floor_ticks"] = _floor_ticks
		paths["head_slides"] = _slides.size()
		paths["double_jumps"] = _double_jumps.size()
