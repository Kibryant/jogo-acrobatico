# TASK-14, the reach that splits the misses (testes-e-entrega.md §4, "O resumo": "As distâncias"):
# a miss is "ao alcance" when its shortest distance over the active is not beyond the reach, and
# "longe" when it is; only the misses within reach are listed with their three numbers. The reach
# is the header's: the hand, the blade, the blade's radius and the capsule's radius. The locked
# suites cannot see the split, which only the lines print, so this suite reads the summary's own
# wording. The matches are played by the core's rules (replay_summary_match.gd).
extends GdUnitTestSuite

const ReplaySummary := preload("res://tools/replay_summary.gd")
const PlayedMatch := preload("res://test/tools/replay_summary_match.gd")
const Tape := preload("res://test/tools/replay_summary_tape.gd")

const LIGHT := FighterCommand.LIGHT_ATTACK
# combate.md, "A lâmina e o contato": the hand 0,6 m from the axis, the blade 1,4 m with a radius
# of 0,08 m; movimento.md, "O corpo": the capsule's radius, 0,35 m. Together, 2,43 m.
const REACH_M := 2.43
# A header with a longer blade, 1,6 m: the reach becomes 2,63 m. The test's own number.
const LONG_BLADE_M := 1.6
const LONG_REACH_M := 2.63
# The light fired on F is over at F + 33 at 60 ticks (combate.md, "O leve no tick").
const F := 2
const LIGHT_OVER := 33
const MISSES := "Os erros, pela distância mais curta no ativo"
const LISTED := "Erros ao alcance"


# A light swung down -Z with the other fighter standing still `behind` metres behind the
# attacker, out of the arc: a miss at that distance on every tick of the active.
func _miss_behind(behind: float, combat: CombatConfig) -> ReplaySummary:
	var played := PlayedMatch.new(Tape.movement_v0(), combat)
	played.add_fighter(Vector3.ZERO, 0.0)
	played.add_fighter(Vector3(0.0, 0.0, behind), 0.0)
	played.press(0, F, [LIGHT])
	played.run(F + LIGHT_OVER + 10)
	return played.summarize()


static func _long_blade() -> CombatConfig:
	var data := Tape.combat_data_v0()
	data.blade_length_m = LONG_BLADE_M
	return CombatConfig.create(data, 60)


# The lines of the attacker's block, stripped: up to the other fighter's block.
static func _attacker_lines(summary: ReplaySummary) -> Array[String]:
	var lines: Array[String] = []
	for line: String in summary.lines():
		var stripped := line.strip_edges()
		if stripped.begins_with("== Lutador 1"):
			break
		lines.append(stripped)
	return lines


static func _line_starting(lines: Array[String], start: String) -> String:
	for line: String in lines:
		if line.begins_with(start):
			return line
	return ""


func test_the_reach_is_the_hand_the_blade_its_radius_and_the_capsule_of_the_header() -> void:
	var v0 := ReplaySummary.new(Tape.movement_v0(), Tape.combat_v0())
	assert_float(v0.reach()).is_equal_approx(REACH_M, 1e-6)
	var longer := ReplaySummary.new(Tape.movement_v0(), _long_blade())
	assert_float(longer.reach()).is_equal_approx(LONG_REACH_M, 1e-6)


func test_a_miss_not_beyond_the_reach_is_within_it_and_listed() -> void:
	var summary := _miss_behind(2.40, Tape.combat_v0())
	var swing := summary.fighter(0).swings[0]
	assert_str(swing.result).is_equal(ReplaySummary.MISS)
	assert_float(swing.nearest_distance).is_equal_approx(2.40, 1e-3)
	var lines := _attacker_lines(summary)
	var misses := _line_starting(lines, MISSES)
	assert_str(misses).contains("1 ao alcance").not_contains("longe")
	assert_str(_line_starting(lines, LISTED)).is_not_empty()


func test_a_miss_beyond_the_reach_is_far_and_not_listed() -> void:
	var summary := _miss_behind(2.46, Tape.combat_v0())
	var swing := summary.fighter(0).swings[0]
	assert_str(swing.result).is_equal(ReplaySummary.MISS)
	assert_float(swing.nearest_distance).is_greater(summary.reach())
	var lines := _attacker_lines(summary)
	var misses := _line_starting(lines, MISSES)
	assert_str(misses).contains("1 longe").not_contains("ao alcance")
	assert_str(_line_starting(lines, LISTED)).is_empty()


func test_the_split_follows_the_reach_of_the_header() -> void:
	# 2,50 m is beyond the v0's 2,43 m and within the 2,63 m of a header with a longer blade.
	var v0 := _line_starting(_attacker_lines(_miss_behind(2.50, Tape.combat_v0())), MISSES)
	assert_str(v0).contains("1 longe")
	var longer := _line_starting(_attacker_lines(_miss_behind(2.50, _long_blade())), MISSES)
	assert_str(longer).contains("1 ao alcance").contains("2,63 m")
