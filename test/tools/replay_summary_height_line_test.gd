# TASK-14, the height line of the summary (testes-e-entrega.md §4, "O resumo": "Os limites"):
# below 0,05 m the highest point prints as 0,0, and the tick of that point would only be the float
# noise of the feet on the floor, so the line says the highest point never passed 0,0 m, with no
# tick and no maneuver. Session 22 printed "0,0 m ... depois de um dash" before this rule. Above
# it, the line keeps the point, its moment and its tick. The locked suites leave this line's
# wording free, so this suite reads the summary's own words.
extends GdUnitTestSuite

const ReplaySummary := preload("res://tools/replay_summary.gd")
const Tape := preload("res://test/tools/replay_summary_tape.gd")

const HEIGHT := "Altura:"


# One fighter standing on the floor for three ticks, its feet at height on tick 1 only, or on
# every tick.
static func _standing(height: float, every_tick := false) -> ReplaySummary:
	var combat := Tape.combat_v0()
	var summary := ReplaySummary.new(Tape.movement_v0(), combat)
	var state := FighterState.new()
	state.health = combat.max_health
	for tick: int in 3:
		var feet := Vector3(0.0, height if every_tick or tick == 1 else 0.0, 0.0)
		summary.add(tick, 0, TickInput.new(), state, feet, Vector3.ZERO)
	summary.finish()
	return summary


static func _height_line(summary: ReplaySummary) -> String:
	for line: String in summary.lines():
		var stripped := line.strip_edges()
		if stripped.begins_with(HEIGHT):
			return stripped
	return ""


func test_a_highest_point_of_float_noise_says_it_never_passed_zero_with_no_tick() -> void:
	var line := _height_line(_standing(0.00001))
	assert_str(line).contains("o ponto mais alto não passou de 0,0 m")
	assert_str(line).not_contains("tick").not_contains("depois de")


func test_a_highest_point_just_under_the_rounding_still_never_passed_zero() -> void:
	# 0,04 m prints as 0,0 with one decimal: the line takes the same rounding it prints.
	assert_str(_height_line(_standing(0.04))).contains("não passou de 0,0 m")


func test_a_tiny_negative_height_on_every_tick_never_passed_zero_either() -> void:
	# The highest point is then below zero, and still prints as 0,0, with no minus sign.
	var line := _height_line(_standing(-0.00001, true))
	assert_str(line).contains("não passou de 0,0 m").not_contains("-0,0")


func test_a_highest_point_that_prints_above_zero_keeps_its_moment_and_tick() -> void:
	var line := _height_line(_standing(0.2))
	assert_str(line).contains("o ponto mais alto, 0,2 m").contains("(tick 1)")
	assert_str(line).not_contains("não passou")
