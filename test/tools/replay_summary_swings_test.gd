# Criteria 4 and 5 of TASK-14, the swings: what became of each light and each charged in the
# summary (tools/replay_summary.gd), as testes-e-entrega.md §4 says ("O resumo": "Os golpes";
# F-178 §1; F-180 §1; F-202 and F-204, contexto; F-205): the result (hit, blocked, parried, miss,
# cut, unfinished), the fighter that took the contact, the distances on the first active tick and
# the shortest over the active, the side of the cut and the crosshair, the target's health and the
# speed during the swing. The matches are played by the core's own rules
# (replay_summary_match.gd), so every contact, stun and hitstop is the one a replay shows, and the
# summary is read only through its public interface, agreed in the TASK-14 plan.
extends GdUnitTestSuite

const ReplaySummary := preload("res://tools/replay_summary.gd")
const PlayedMatch := preload("res://test/tools/replay_summary_match.gd")
const Tape := preload("res://test/tools/replay_summary_tape.gd")

const LIGHT := FighterCommand.LIGHT_ATTACK
const CHARGED := FighterCommand.CHARGED_ATTACK
const PARRY := FighterCommand.PARRY

# combate.md, "O leve no tick": "As fases" (DEC-0052): fired at F, active from F + 15, in recovery
# from F + 21, over at F + 33, at 60 ticks.
const LIGHT_ACTIVE := 15
const LIGHT_RECOVERY := 21
const LIGHT_OVER := 33
# combate.md, "As fases do carregado" (DEC-0056 §2): active from F + 42 and
# over at F + 76.
const CHARGED_ACTIVE := 42
const CHARGED_OVER := 76
# combate.md, "Os golpes e as defesas": the light takes 12, the charged 30; partida.md, "O duelo":
# the health is 100; "A vida sem partida": it returns to 100 two seconds, 120 ticks, after the
# last hit taken.
const LIGHT_DAMAGE := 12
const CHARGED_DAMAGE := 30
const MAX_HEALTH := 100
const REFILL_MS := 2000
const REFILL_TICKS := 120
# combate.md, "A espada na mira" (DEC-0045; DEC-0057): the aim line runs 0,8 m to the right of the
# body, and the swing points at the point of it 2,0 m from the axis.
const AIM_SIDE_M := 0.8
const CONVERGENCE_M := 2.0
# combate.md, "A lâmina e o contato": the hand 0,6 m from the axis, the blade 1,4 m long with a
# radius of 0,08 m; movimento.md, "O corpo": the capsule's radius, 0,35 m. Together the reach the
# summary splits the misses by, 2,43 m.
const REACH_M := 2.43
# The tick of the first click, and the tolerance of a distance: the feet are set exactly, and the
# sums go through 32-bit vectors.
const F := 2
const TOLERANCE := 1e-3
# The feet of the target of most duels: 1,5 m down -Z, inside the blade's reach. The tests' own
# geometry, not a design number.
const IN_FRONT := Vector3(0.0, 0.0, -1.5)

var played: PlayedMatch
# The camera's yaw that sends the swing straight down -Z: the swing turns asin(side /
# convergence) to the right of the camera, so the camera looks that much to the left.
var aim: float


func before_test() -> void:
	played = PlayedMatch.new(Tape.movement_v0(), Tape.combat_v0())
	aim = asin(played.tape.movement.aim_side / played.tape.combat.aim_convergence)


# A fresh match with the attacker, fighter 0, at the origin, its swing going down -Z.
func _with_attacker() -> int:
	played = PlayedMatch.new(Tape.movement_v0(), Tape.combat_v0())
	return played.add_fighter(Vector3.ZERO, aim)


# The tick of the first contact a fighter stamped, by the core's own stamp; fails without one.
func _contact_of(fighter: int) -> int:
	var tick := played.first_tick(fighter, 0, _touched_now)
	assert_int(tick).override_failure_message("fighter %d never touched" % fighter).is_greater(0)
	return tick


static func _touched_now(state: FighterState, tick: int) -> bool:
	return state.contact_tick == tick


# How far `point` is to the right of the line through `origin` along `yaw`, on the floor's plane:
# yaw 0 looks down -Z with +X to the right, and a positive yaw turns left.
static func _to_the_right(origin: Vector3, point: Vector3, yaw: float) -> float:
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	return (point - origin).dot(right)


static func _plane_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# The speeds the summary must hold for a move: the plane speed on every tick fed whose state is in
# a swing of the move and stands on the floor, by the core's own predicates.
func _speeds_fed(fighter: int, move: StringName) -> PackedFloat64Array:
	var speeds := PackedFloat64Array()
	for feed: Tape.Feed in played.tape.feeds:
		if feed.fighter != fighter or not Combat.swinging(feed.state):
			continue
		if feed.state.action_move != move or not Movement.stands(feed.state):
			continue
		speeds.append(Vector2(feed.velocity.x, feed.velocity.z).length())
	return speeds


func _speeds_of(report: ReplaySummary.FighterReport, move: StringName) -> PackedFloat64Array:
	var speeds: PackedFloat64Array = report.swing_speeds.get(move, PackedFloat64Array())
	return speeds


func _assert_speeds(actual: PackedFloat64Array, expected: PackedFloat64Array) -> void:
	assert_int(actual.size()).is_equal(expected.size())
	if actual.size() != expected.size():
		return
	for index: int in expected.size():
		assert_float(actual[index]).is_equal_approx(expected[index], TOLERANCE)


func test_the_design_numbers_of_the_aim_and_the_reach_are_the_configs() -> void:
	var movement := Tape.movement_v0()
	var combat := Tape.combat_v0()
	assert_float(movement.aim_side).is_equal_approx(AIM_SIDE_M, 1e-6)
	assert_float(combat.aim_convergence).is_equal_approx(CONVERGENCE_M, 1e-6)
	var reach := (
		combat.hand_offset + combat.blade_length + combat.blade_radius + movement.capsule_radius
	)
	assert_float(reach).is_equal_approx(REACH_M, 1e-6)
	assert_int(combat.max_health).is_equal(MAX_HEALTH)
	# The conversion: 2000 ms are 120 ticks at 60 and 60 at 30.
	assert_int(Ticks.from_ms(REFILL_MS, 60)).is_equal(REFILL_TICKS)
	assert_int(combat.health_refill_ticks).is_equal(REFILL_TICKS)
	assert_int(Tape.combat_v0(30).health_refill_ticks).is_equal(60)

# --- The result ---


func test_a_light_alone_in_the_arena_is_a_miss_with_no_distance() -> void:
	_with_attacker()
	played.press(0, F, [LIGHT])
	played.run(F + LIGHT_OVER + 10)
	var report := played.summarize().fighter(0)
	assert_int(report.swings.size()).is_equal(1)
	var swing := report.swings[0]
	assert_str(swing.result).is_equal(ReplaySummary.MISS)
	assert_int(swing.active_tick).is_equal(F + LIGHT_ACTIVE)
	assert_int(swing.contact_tick).is_equal(-1)
	assert_int(swing.target).is_equal(-1)
	assert_float(swing.first_active_distance).is_equal(-1.0)
	assert_float(swing.nearest_distance).is_equal(-1.0)


func test_a_light_that_lands_is_a_hit_on_the_other_and_one_swing_through_the_hitstop() -> void:
	_with_attacker()
	var target := played.add_fighter(IN_FRONT, PI)
	played.press(0, F, [LIGHT])
	played.run(F + LIGHT_OVER + 20)
	var contact := _contact_of(0)
	# The scenario: the target took it, and the hitstop moved the attacker's clock (DEC-0055 §5).
	assert_int(played.state(target, contact + 1).hurt_tick).is_equal(contact)
	assert_int(played.state(0, contact + 2).action_since).is_greater(F + LIGHT_ACTIVE)
	var report := played.summarize().fighter(0)
	assert_int(report.swings.size()).is_equal(1)
	var swing := report.swings[0]
	assert_str(swing.move).is_equal(LIGHT)
	assert_str(swing.result).is_equal(ReplaySummary.HIT)
	assert_int(swing.fire_tick).is_equal(F)
	assert_int(swing.active_tick).is_equal(F + LIGHT_ACTIVE)
	assert_int(swing.contact_tick).is_equal(contact)
	assert_int(swing.target).is_equal(target)
	assert_float(swing.first_active_distance).is_equal_approx(1.5, TOLERANCE)
	assert_float(swing.nearest_distance).is_equal_approx(1.5, TOLERANCE)


func test_a_light_on_a_raised_guard_is_blocked() -> void:
	_with_attacker()
	var target := played.add_fighter(IN_FRONT, PI)
	played.hold_guard(target, true)
	played.press(0, F, [LIGHT])
	played.run(F + LIGHT_OVER + 20)
	var contact := _contact_of(0)
	assert_int(played.state(target, contact + 1).block_tick).is_equal(contact)
	var summary := played.summarize()
	var swing := summary.fighter(0).swings[0]
	assert_str(swing.result).is_equal(ReplaySummary.BLOCKED)
	assert_int(swing.contact_tick).is_equal(contact)
	assert_int(swing.target).is_equal(target)
	# A block costs stamina, never health.
	assert_int(summary.fighter(target).lowest_health).is_equal(MAX_HEALTH)


func test_a_charged_met_by_a_parry_is_parried() -> void:
	_with_attacker()
	var target := played.add_fighter(IN_FRONT, PI)
	played.press(0, F, [CHARGED])
	# The parry two ticks before the charged comes down: its window covers the whole active.
	played.press(target, F + CHARGED_ACTIVE - 2, [PARRY])
	played.run(F + CHARGED_OVER + 40)
	var contact := _contact_of(0)
	assert_int(played.state(target, contact + 1).parry_tick).is_equal(contact)
	assert_int(played.state(0, contact + 2).action).is_equal(FighterState.Action.PARRIED)
	var summary := played.summarize()
	assert_int(summary.fighter(0).swings.size()).is_equal(1)
	var swing := summary.fighter(0).swings[0]
	assert_str(swing.move).is_equal(CHARGED)
	assert_str(swing.result).is_equal(ReplaySummary.PARRIED)
	assert_int(swing.active_tick).is_equal(F + CHARGED_ACTIVE)
	assert_int(swing.contact_tick).is_equal(contact)
	assert_int(swing.target).is_equal(target)
	assert_int(summary.fighter(target).lowest_health).is_equal(MAX_HEALTH)
	# The parry is no press of the summary, and no swing.
	assert_int(summary.fighter(target).presses.size()).is_equal(0)
	assert_int(summary.fighter(target).swings.size()).is_equal(0)


func test_a_charged_that_lands_is_a_hit_of_the_charged() -> void:
	_with_attacker()
	var target := played.add_fighter(IN_FRONT, PI)
	played.press(0, F, [CHARGED])
	played.run(F + CHARGED_OVER + 20)
	var contact := _contact_of(0)
	var summary := played.summarize()
	assert_int(summary.fighter(0).swings.size()).is_equal(1)
	var swing := summary.fighter(0).swings[0]
	assert_str(swing.move).is_equal(CHARGED)
	assert_str(swing.result).is_equal(ReplaySummary.HIT)
	assert_int(swing.active_tick).is_equal(F + CHARGED_ACTIVE)
	assert_int(swing.contact_tick).is_equal(contact)
	assert_int(swing.target).is_equal(target)
	assert_int(summary.fighter(target).lowest_health).is_equal(MAX_HEALTH - CHARGED_DAMAGE)


func test_a_light_cut_by_a_hit_taken_in_its_windup_is_cut_and_never_active() -> void:
	_with_attacker()
	# The other swings back up +Z, and clicked first.
	var other := played.add_fighter(IN_FRONT, PI + aim)
	played.press(other, F, [LIGHT])
	played.press(0, F + 6, [LIGHT])
	played.run(F + LIGHT_OVER + 40)
	var contact := _contact_of(other)
	# The scenario: fighter 0 was in its windup on the contact, and in the hitstun after it.
	assert_int(played.state(0, contact).action).is_equal(FighterState.Action.WINDUP)
	assert_int(played.state(0, contact + 1).action).is_equal(FighterState.Action.HITSTUN)
	var summary := played.summarize()
	assert_int(summary.fighter(0).swings.size()).is_equal(1)
	var cut := summary.fighter(0).swings[0]
	assert_str(cut.result).is_equal(ReplaySummary.CUT)
	assert_int(cut.fire_tick).is_equal(F + 6)
	assert_int(cut.active_tick).is_equal(-1)
	assert_int(cut.contact_tick).is_equal(-1)
	assert_int(cut.target).is_equal(-1)
	assert_float(cut.first_active_distance).is_equal(-1.0)
	assert_float(cut.nearest_distance).is_equal(-1.0)
	var landed := summary.fighter(other).swings[0]
	assert_str(landed.result).is_equal(ReplaySummary.HIT)
	assert_int(landed.target).is_equal(0)


func test_a_charged_cut_by_a_feint_is_cut() -> void:
	_with_attacker()
	played.add_fighter(IN_FRONT, PI)
	played.press(0, F, [CHARGED])
	played.press(0, F + 10, [PlayedMatch.GUARD_PRESS])
	played.run(F + CHARGED_OVER + 10)
	assert_int(played.state(0, F + 10).action).is_equal(FighterState.Action.FEINT)
	var summary := played.summarize()
	assert_int(summary.fighter(0).swings.size()).is_equal(1)
	var swing := summary.fighter(0).swings[0]
	assert_str(swing.move).is_equal(CHARGED)
	assert_str(swing.result).is_equal(ReplaySummary.CUT)
	assert_int(swing.active_tick).is_equal(-1)
	assert_int(swing.contact_tick).is_equal(-1)
	assert_int(summary.fighter(1).lowest_health).is_equal(MAX_HEALTH)


func test_a_light_on_the_armor_of_a_charged_windup_is_a_hit_and_the_charged_goes_on() -> void:
	_with_attacker()
	var other := played.add_fighter(IN_FRONT, PI + aim)
	played.press(other, F, [CHARGED])
	played.press(0, F + 3, [LIGHT])
	played.run(F + CHARGED_OVER + 30)
	var light_contact := _contact_of(0)
	var charged_contact := _contact_of(other)
	# The scenario: the armor took the light with no stun, and the charged came down on its tick.
	assert_int(played.state(other, light_contact + 1).hurt_tick).is_equal(light_contact)
	assert_int(played.state(other, light_contact + 1).action).is_equal(FighterState.Action.WINDUP)
	assert_int(charged_contact).is_greater_equal(F + CHARGED_ACTIVE)
	var summary := played.summarize()
	var light := summary.fighter(0).swings[0]
	assert_str(light.result).is_equal(ReplaySummary.HIT)
	assert_int(light.contact_tick).is_equal(light_contact)
	assert_int(light.target).is_equal(other)
	assert_int(summary.fighter(other).swings.size()).is_equal(1)
	var charged := summary.fighter(other).swings[0]
	assert_str(charged.move).is_equal(CHARGED)
	assert_str(charged.result).is_equal(ReplaySummary.HIT)
	assert_int(charged.active_tick).is_equal(F + CHARGED_ACTIVE)
	assert_int(charged.contact_tick).is_equal(charged_contact)
	assert_int(charged.target).is_equal(0)
	assert_int(summary.fighter(other).lowest_health).is_equal(MAX_HEALTH - LIGHT_DAMAGE)
	assert_int(summary.fighter(0).lowest_health).is_equal(MAX_HEALTH - CHARGED_DAMAGE)


func test_a_swing_the_replay_ends_in_the_windup_of_is_unfinished() -> void:
	_with_attacker()
	played.add_fighter(IN_FRONT, PI)
	played.press(0, F, [LIGHT])
	played.run_through(F + 8)
	var report := played.summarize().fighter(0)
	assert_int(report.swings.size()).is_equal(1)
	var swing := report.swings[0]
	assert_str(swing.result).is_equal(ReplaySummary.UNFINISHED)
	assert_int(swing.active_tick).is_equal(-1)
	assert_int(swing.contact_tick).is_equal(-1)
	assert_int(swing.target).is_equal(-1)


func test_a_swing_the_replay_ends_in_the_active_of_with_no_contact_is_unfinished() -> void:
	_with_attacker()
	played.add_fighter(Vector3(0.0, 0.0, -6.0), PI)
	played.press(0, F, [CHARGED])
	played.run_through(F + CHARGED_ACTIVE + 2)
	var swing := played.summarize().fighter(0).swings[0]
	assert_str(swing.result).is_equal(ReplaySummary.UNFINISHED)
	assert_int(swing.active_tick).is_equal(F + CHARGED_ACTIVE)
	assert_float(swing.first_active_distance).is_equal_approx(6.0, TOLERANCE)


func test_a_swing_that_had_landed_when_the_replay_ends_in_it_is_still_a_hit() -> void:
	_with_attacker()
	var target := played.add_fighter(IN_FRONT, PI)
	played.press(0, F, [LIGHT])
	played.run(F + LIGHT_OVER + 20)
	var contact := _contact_of(0)
	# The same match again, ended on the tick the target shows the hit: the swing is in its active.
	_with_attacker()
	target = played.add_fighter(IN_FRONT, PI)
	played.press(0, F, [LIGHT])
	played.run_through(contact + 1)
	assert_int(played.state(target, contact + 1).hurt_tick).is_equal(contact)
	var swing := played.summarize().fighter(0).swings[0]
	assert_str(swing.result).is_equal(ReplaySummary.HIT)
	assert_int(swing.contact_tick).is_equal(contact)
	assert_int(swing.target).is_equal(target)


func test_many_swings_keep_each_its_own_result_in_order() -> void:
	_with_attacker()
	var target := played.add_fighter(IN_FRONT, PI)
	# A light that lands, then a charged the target parries, then a light into the guard.
	played.press(0, F, [LIGHT])
	var second := F + LIGHT_OVER + 40
	played.press(0, second, [CHARGED])
	played.press(target, second + CHARGED_ACTIVE - 2, [PARRY])
	played.run_through(second + CHARGED_OVER + 80)
	var third := played.next_tick()
	played.hold_guard(target, true)
	played.press(0, third + 20, [LIGHT])
	played.run(20 + LIGHT_OVER + 20)
	var report := played.summarize().fighter(0)
	assert_int(report.swings.size()).is_equal(3)
	var results: Array[StringName] = []
	var moves: Array[StringName] = []
	for swing: ReplaySummary.Swing in report.swings:
		results.append(swing.result)
		moves.append(swing.move)
		assert_int(swing.target).is_equal(target)
	assert_array(moves).is_equal([LIGHT, CHARGED, LIGHT])
	assert_array(results).is_equal(
		[ReplaySummary.HIT, ReplaySummary.PARRIED, ReplaySummary.BLOCKED],
	)
	assert_int(report.swings[1].fire_tick).is_equal(second)
	assert_int(report.swings[2].fire_tick).is_equal(third + 20)

# --- The target ---


func test_the_target_is_the_fighter_that_shows_the_hit_not_the_nearest_one() -> void:
	_with_attacker()
	# One metre behind the attacker, out of the arc: the nearest, and untouched.
	var behind := played.add_fighter(Vector3(0.0, 0.0, 1.0), 0.0)
	var front := played.add_fighter(IN_FRONT, PI)
	played.press(0, F, [LIGHT])
	played.run(F + LIGHT_OVER + 20)
	var contact := _contact_of(0)
	assert_int(played.state(front, contact + 1).hurt_tick).is_equal(contact)
	assert_int(played.state(behind, contact + 1).hurt_tick).is_equal(FighterState.NEVER)
	var summary := played.summarize()
	var swing := summary.fighter(0).swings[0]
	assert_str(swing.result).is_equal(ReplaySummary.HIT)
	assert_int(swing.target).is_equal(front)
	# The distances are to the nearest other fighter, whoever took the hit.
	assert_float(swing.first_active_distance).is_equal_approx(1.0, TOLERANCE)
	assert_float(swing.nearest_distance).is_equal_approx(1.0, TOLERANCE)
	assert_int(summary.fighter(front).lowest_health).is_equal(MAX_HEALTH - LIGHT_DAMAGE)
	assert_int(summary.fighter(behind).lowest_health).is_equal(MAX_HEALTH)

# --- The distances, the side and the crosshair ---


func test_a_miss_far_away_keeps_the_distance_beyond_the_reach() -> void:
	_with_attacker()
	played.add_fighter(Vector3(0.0, 0.0, -6.0), PI)
	played.press(0, F, [LIGHT])
	played.run(F + LIGHT_OVER + 10)
	var swing := played.summarize().fighter(0).swings[0]
	assert_str(swing.result).is_equal(ReplaySummary.MISS)
	assert_float(swing.first_active_distance).is_equal_approx(6.0, TOLERANCE)
	assert_float(swing.nearest_distance).is_equal_approx(6.0, TOLERANCE)
	assert_float(swing.nearest_distance).is_greater(REACH_M)


func test_the_distance_is_on_the_floor_plane_from_feet_to_feet() -> void:
	_with_attacker()
	# 3 m to the side and 4 m ahead: 5 m on the plane.
	played.add_fighter(Vector3(3.0, 0.0, -4.0), PI)
	played.press(0, F, [LIGHT])
	played.run(F + LIGHT_OVER + 10)
	var swing := played.summarize().fighter(0).swings[0]
	assert_float(swing.first_active_distance).is_equal_approx(5.0, TOLERANCE)
	assert_float(swing.nearest_distance).is_equal_approx(5.0, TOLERANCE)


func test_a_hit_dead_ahead_has_no_side_and_the_aim_line_to_the_right_of_the_target() -> void:
	_with_attacker()
	played.add_fighter(IN_FRONT, PI)
	played.press(0, F, [LIGHT])
	played.run(F + LIGHT_OVER + 20)
	# The scenario: the swing went straight down -Z.
	assert_float(played.state(0, F + LIGHT_ACTIVE).action_yaw).is_equal_approx(0.0, 1e-5)
	var swing := played.summarize().fighter(0).swings[0]
	assert_str(swing.result).is_equal(ReplaySummary.HIT)
	assert_float(swing.side).is_equal_approx(0.0, TOLERANCE)
	# The aim line leaves 0,8 m to the right and crosses the cut 2,0 m away: 1,5 m down the cut it
	# is still 0,8 - 1,5 × 0,8 / 2,0 = 0,2 m to the right of the target.
	assert_float(swing.crosshair).is_equal_approx(0.2, TOLERANCE)


func test_a_target_on_the_convergence_has_the_crosshair_on_it() -> void:
	_with_attacker()
	# 2,0 m down the cut: the point the aim line crosses it.
	played.add_fighter(Vector3(0.0, 0.0, -CONVERGENCE_M), PI)
	played.press(0, F, [LIGHT])
	played.run(F + LIGHT_OVER + 20)
	var swing := played.summarize().fighter(0).swings[0]
	assert_str(swing.result).is_equal(ReplaySummary.HIT)
	assert_float(swing.first_active_distance).is_equal_approx(CONVERGENCE_M, TOLERANCE)
	assert_float(swing.side).is_equal_approx(0.0, TOLERANCE)
	assert_float(swing.crosshair).is_equal_approx(0.0, TOLERANCE)


func test_a_miss_within_reach_to_the_left_has_a_negative_side_and_a_positive_crosshair() -> void:
	_with_attacker()
	# 2 m to the left and a little ahead, past the end of the light's arc: in reach, untouched.
	var feet := Vector3(-2.0, 0.0, -0.2)
	played.add_fighter(feet, PI)
	played.press(0, F, [LIGHT])
	played.run(F + LIGHT_OVER + 10)
	var swing := played.summarize().fighter(0).swings[0]
	assert_str(swing.result).is_equal(ReplaySummary.MISS)
	assert_float(swing.nearest_distance).is_equal_approx(feet.length(), TOLERANCE)
	assert_float(swing.nearest_distance).is_less(REACH_M)
	assert_float(swing.side).is_equal_approx(-2.0, TOLERANCE)
	var expected := AIM_SIDE_M - _to_the_right(Vector3.ZERO, feet, aim)
	assert_float(swing.crosshair).is_equal_approx(expected, TOLERANCE)
	assert_float(swing.crosshair).is_greater(AIM_SIDE_M)


func test_a_miss_within_reach_to_the_right_has_a_positive_side_and_a_negative_crosshair() -> void:
	_with_attacker()
	var feet := Vector3(2.0, 0.0, -0.2)
	played.add_fighter(feet, PI)
	played.press(0, F, [LIGHT])
	played.run(F + LIGHT_OVER + 10)
	var swing := played.summarize().fighter(0).swings[0]
	assert_str(swing.result).is_equal(ReplaySummary.MISS)
	assert_float(swing.nearest_distance).is_less(REACH_M)
	assert_float(swing.side).is_equal_approx(2.0, TOLERANCE)
	var expected := AIM_SIDE_M - _to_the_right(Vector3.ZERO, feet, aim)
	assert_float(swing.crosshair).is_equal_approx(expected, TOLERANCE)
	assert_float(swing.crosshair).is_less(0.0)


func test_a_miss_behind_the_attacker_is_within_reach_with_its_three_numbers() -> void:
	_with_attacker()
	var feet := Vector3(0.6, 0.0, 1.0)
	played.add_fighter(feet, 0.0)
	played.press(0, F, [CHARGED])
	played.run(F + CHARGED_OVER + 10)
	var swing := played.summarize().fighter(0).swings[0]
	assert_str(swing.move).is_equal(CHARGED)
	assert_str(swing.result).is_equal(ReplaySummary.MISS)
	assert_float(swing.first_active_distance).is_equal_approx(feet.length(), TOLERANCE)
	assert_float(swing.nearest_distance).is_less(REACH_M)
	assert_float(swing.side).is_equal_approx(0.6, TOLERANCE)
	var expected := AIM_SIDE_M - _to_the_right(Vector3.ZERO, feet, aim)
	assert_float(swing.crosshair).is_equal_approx(expected, TOLERANCE)


func test_the_crosshair_follows_the_camera_of_the_last_windup_tick() -> void:
	played = PlayedMatch.new(Tape.movement_v0(), Tape.combat_v0())
	# The camera starts a quarter turn to the left, and comes to yaw 0 inside the windup; on the
	# first active tick it has already turned away again, and the swing no longer follows it.
	played.add_fighter(Vector3.ZERO, PI / 2.0)
	var feet := Vector3(0.5, 0.0, -3.0)
	played.add_fighter(feet, PI)
	played.press(0, F, [LIGHT])
	played.run_through(F + 9)
	played.look(0, 0.0)
	played.run_through(F + LIGHT_ACTIVE - 1)
	played.look(0, 1.0)
	played.run(LIGHT_OVER)
	# The scenario: the swing kept the direction of the last windup tick, with the camera at 0.
	var swing_yaw := Aim.swing_yaw(0.0, AIM_SIDE_M, CONVERGENCE_M)
	assert_float(played.state(0, F + LIGHT_ACTIVE).action_yaw).is_equal_approx(swing_yaw, 1e-5)
	var swing := played.summarize().fighter(0).swings[0]
	assert_str(swing.result).is_equal(ReplaySummary.MISS)
	# With the camera at yaw 0 the aim line is x = 0,8: the target at x = 0,5 has it 0,3 m to its
	# right.
	assert_float(swing.crosshair).is_equal_approx(0.3, TOLERANCE)
	assert_float(swing.side).is_equal_approx(
		_to_the_right(Vector3.ZERO, feet, swing_yaw),
		TOLERANCE,
	)
	assert_float(swing.side).is_less(0.0)


func test_the_nearest_distance_is_the_shortest_over_the_active_ticks() -> void:
	_with_attacker()
	var feet := Vector3(0.0, 0.0, -6.0)
	played.add_fighter(feet, PI)
	played.press(0, F, [LIGHT])
	played.run_through(F + 4)
	# The attacker runs forward through the swing: the light does not slow the body.
	played.push(0, Vector2(0.0, 1.0))
	played.run(LIGHT_OVER + 10)
	var first := _plane_distance(played.feet(0, F + LIGHT_ACTIVE), feet)
	var last := _plane_distance(played.feet(0, F + LIGHT_RECOVERY - 1), feet)
	# The scenario: it closed the distance through the six active ticks, and went on closing it in
	# the recovery, which does not count.
	assert_float(last).is_less(first - 0.1)
	var after := _plane_distance(played.feet(0, F + LIGHT_RECOVERY + 3), feet)
	assert_float(after).is_less(last - 0.1)
	var swing := played.summarize().fighter(0).swings[0]
	assert_str(swing.result).is_equal(ReplaySummary.MISS)
	assert_float(swing.first_active_distance).is_equal_approx(first, TOLERANCE)
	assert_float(swing.nearest_distance).is_equal_approx(last, TOLERANCE)

# --- The health ---


func test_a_fighter_never_hit_keeps_the_health_at_the_max_with_no_refill() -> void:
	_with_attacker()
	played.run(30)
	var report := played.summarize().fighter(0)
	assert_int(report.lowest_health).is_equal(MAX_HEALTH)
	assert_int(report.refills).is_equal(0)


func test_one_hit_is_the_lowest_health_and_the_refill_counts_once() -> void:
	_with_attacker()
	var target := played.add_fighter(IN_FRONT, PI)
	played.press(0, F, [LIGHT])
	played.run(F + LIGHT_OVER + REFILL_TICKS + 20)
	var summary := played.summarize()
	assert_int(summary.fighter(target).lowest_health).is_equal(MAX_HEALTH - LIGHT_DAMAGE)
	assert_int(summary.fighter(target).refills).is_equal(1)
	assert_int(summary.fighter(0).lowest_health).is_equal(MAX_HEALTH)
	assert_int(summary.fighter(0).refills).is_equal(0)


func test_the_refill_counts_on_the_tick_the_health_is_back_and_not_one_tick_before() -> void:
	_with_attacker()
	var target := played.add_fighter(IN_FRONT, PI)
	played.press(0, F, [LIGHT])
	played.run(F + LIGHT_OVER + 20)
	var contact := _contact_of(0)
	# The same match, ended one tick before the two seconds after the hit, then exactly on them.
	for last: int in [contact + REFILL_TICKS - 1, contact + REFILL_TICKS]:
		_with_attacker()
		target = played.add_fighter(IN_FRONT, PI)
		played.press(0, F, [LIGHT])
		played.run_through(last)
		var refilled := last == contact + REFILL_TICKS
		var health := MAX_HEALTH if refilled else MAX_HEALTH - LIGHT_DAMAGE
		assert_int(played.state(target, last).health).is_equal(health)
		var report := played.summarize().fighter(target)
		assert_int(report.refills).is_equal(1 if refilled else 0)
		assert_int(report.lowest_health).is_equal(MAX_HEALTH - LIGHT_DAMAGE)


func test_many_hits_keep_the_lowest_health_and_every_refill() -> void:
	_with_attacker()
	var target := played.add_fighter(IN_FRONT, PI)
	# Two lights land one after the other, the health refills, and a third lands later.
	played.press(0, F, [LIGHT])
	var second := F + LIGHT_OVER + 10
	played.press(0, second, [LIGHT])
	var third := second + LIGHT_OVER + REFILL_TICKS + 30
	played.press(0, third, [LIGHT])
	played.run_through(third + LIGHT_OVER + REFILL_TICKS + 30)
	# The scenario: two hits before the first refill.
	assert_int(played.state(target, second + LIGHT_OVER).health).is_equal(
		MAX_HEALTH - 2 * LIGHT_DAMAGE,
	)
	var summary := played.summarize()
	assert_int(summary.fighter(0).swings.size()).is_equal(3)
	for swing: ReplaySummary.Swing in summary.fighter(0).swings:
		assert_str(swing.result).is_equal(ReplaySummary.HIT)
	assert_int(summary.fighter(target).lowest_health).is_equal(MAX_HEALTH - 2 * LIGHT_DAMAGE)
	assert_int(summary.fighter(target).refills).is_equal(2)

# --- The speed during the swing ---


func test_a_fighter_with_no_swing_has_no_speed_sample() -> void:
	_with_attacker()
	played.push(0, Vector2(0.0, 1.0))
	played.run(30)
	var report := played.summarize().fighter(0)
	assert_int(_speeds_of(report, LIGHT).size()).is_equal(0)
	assert_int(_speeds_of(report, CHARGED).size()).is_equal(0)


func test_a_light_standing_still_samples_zero_on_each_of_its_33_ticks() -> void:
	_with_attacker()
	played.run(5)
	played.press(0, 5, [LIGHT])
	played.run(LIGHT_OVER + 10)
	var report := played.summarize().fighter(0)
	var speeds := _speeds_of(report, LIGHT)
	assert_int(speeds.size()).is_equal(LIGHT_OVER)
	for speed: float in speeds:
		assert_float(speed).is_equal(0.0)
	assert_int(_speeds_of(report, CHARGED).size()).is_equal(0)


func test_a_light_on_the_run_samples_the_plane_speed_of_each_tick_of_the_swing() -> void:
	_with_attacker()
	played.push(0, Vector2(0.0, 1.0))
	played.press(0, 20, [LIGHT])
	played.run(20 + LIGHT_OVER + 20)
	var expected := _speeds_fed(0, LIGHT)
	# The scenario: 33 ticks of swing, at the run's speed, well above the slow walk.
	assert_int(expected.size()).is_equal(LIGHT_OVER)
	assert_float(expected[0]).is_greater(played.tape.movement.slow_walk_speed)
	_assert_speeds(_speeds_of(played.summarize().fighter(0), LIGHT), expected)


func test_ticks_of_the_swing_off_the_floor_are_not_sampled() -> void:
	_with_attacker()
	played.push(0, Vector2(0.0, 1.0))
	played.press(0, 10, [LIGHT])
	played.run_through(10 + 12)
	# The floor ends under the swing, which goes on in the air.
	played.set_floor(0, false)
	played.run(LIGHT_OVER + 10)
	var expected := _speeds_fed(0, LIGHT)
	# The scenario: some ticks of the swing standing, the rest in the air.
	assert_int(expected.size()).is_between(5, LIGHT_OVER - 5)
	_assert_speeds(_speeds_of(played.summarize().fighter(0), LIGHT), expected)


func test_each_move_keeps_its_own_speed_samples() -> void:
	_with_attacker()
	played.push(0, Vector2(0.0, 1.0))
	played.press(0, 10, [LIGHT])
	var second := 10 + LIGHT_OVER + 15
	played.press(0, second, [CHARGED])
	played.run(second + CHARGED_OVER + 20)
	var light := _speeds_fed(0, LIGHT)
	var charged := _speeds_fed(0, CHARGED)
	assert_int(light.size()).is_equal(LIGHT_OVER)
	assert_int(charged.size()).is_equal(CHARGED_OVER)
	var report := played.summarize().fighter(0)
	_assert_speeds(_speeds_of(report, LIGHT), light)
	_assert_speeds(_speeds_of(report, CHARGED), charged)
