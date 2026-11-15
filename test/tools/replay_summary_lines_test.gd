# Criterion 2 of TASK-14 and the lines the spec fixes word by word (testes-e-entrega.md §4, "O
# resumo"): each fighter has its own report and its own block, in order, under an exact header; the
# first line says the ticks, the ticks per second, the duration and the fighters; and each move
# opens with its phases, in ticks and in ms, read from the configs the summary was made with, the
# replay's header, never from today's .tres (criteria 4 and 5). Every other line's wording is
# free, and no test reads it. The summary (tools/replay_summary.gd) is read only through its
# public interface, agreed in the TASK-14 plan.
extends GdUnitTestSuite

const ReplaySummary := preload("res://tools/replay_summary.gd")
const PlayedMatch := preload("res://test/tools/replay_summary_match.gd")
const Tape := preload("res://test/tools/replay_summary_tape.gd")
const Puppet := preload("res://test/tools/replay_summary_puppet.gd")

const JUMP := FighterCommand.JUMP
const LIGHT := FighterCommand.LIGHT_ATTACK
const CHARGED := FighterCommand.CHARGED_ATTACK

# The block headers, exactly (testes-e-entrega.md §4).
const HEADERS: Array[String] = [
	"== Lutador 0, você",
	"== Lutador 1, o outro (o boneco ou o bot)",
	"== Lutador 2, outro",
]
const BLOCK_PREFIX := "== Lutador "
const NO_LIGHT := "Leve: nenhum clique"
const NO_CHARGED := "Carregado: nenhum clique"
# combate.md, "Os golpes e as defesas" and "O leve no tick": the light is 250, 100 and 200 ms,
# which at 60 ticks are 15, 6 and 12; "As fases do carregado": 700, 120 and 450 ms, which are 42, 7
# and 27. The ms of the line come back from the ticks, ticks × 1000 ÷ 60, to the nearest ms: the 7
# ticks of the charged's active read 117 ms, not the 120 of the design.
const LIGHT_AT_60 := (
	"Leve: preparação 15 ticks (250 ms), ativo 6 ticks (100 ms), recuperação 12 ticks (200 ms)"
)
const CHARGED_AT_60 := (
	"Carregado: preparação 42 ticks (700 ms), ativo 7 ticks (117 ms), "
	+ "recuperação 27 ticks (450 ms)"
)
# At 30 ticks the nearest tick, ties up (Ticks.from_ms): 250 ms are 7,5 ticks, so 8, which read
# 267 ms; 100 ms are 3 and 200 ms are 6. The charged: 21 ticks, 3,6 so 4 (133 ms), and 13,5 so 14
# (467 ms) (combate.md, "As fases do carregado": "a 30 ticks, são 21, 4 e 14").
const LIGHT_AT_30 := (
	"Leve: preparação 8 ticks (267 ms), ativo 3 ticks (100 ms), recuperação 6 ticks (200 ms)"
)
const CHARGED_AT_30 := (
	"Carregado: preparação 21 ticks (700 ms), ativo 4 ticks (133 ms), "
	+ "recuperação 14 ticks (467 ms)"
)
# A replay recorded when the light's windup was 400 ms (combate.md, "Os golpes e as defesas": the
# light before DEC-0052 was 400 / 100 / 250): 24 ticks at 60.
const OLD_WINDUP_MS := 400
const OLD_WINDUP_TICKS := 24
const LIGHT_WITH_OLD_WINDUP := (
	"Leve: preparação 24 ticks (400 ms), ativo 6 ticks (100 ms), recuperação 12 ticks (200 ms)"
)


# The summary's lines without the spaces around them: a block may indent its lines.
func _stripped(summary: ReplaySummary) -> Array[String]:
	var lines: Array[String] = []
	for line: String in summary.lines():
		lines.append(line.strip_edges())
	return lines


# The lines of one fighter's block: after its header, up to the next block's header or the end.
func _block(lines: Array[String], fighter: int) -> Array[String]:
	var block: Array[String] = []
	var start := lines.find(HEADERS[fighter])
	assert_int(start).override_failure_message("no line '%s'" % HEADERS[fighter]).is_not_equal(-1)
	if start == -1:
		return block
	for index: int in range(start + 1, lines.size()):
		if lines[index].begins_with(BLOCK_PREFIX):
			break
		block.append(lines[index])
	return block


func _assert_has(lines: Array[String], line: String) -> void:
	assert_bool(lines.has(line)).override_failure_message("no line '%s'" % line).is_true()


func _assert_has_not(lines: Array[String], line: String) -> void:
	assert_bool(lines.has(line)).override_failure_message("a line '%s'" % line).is_false()


# A tape of `fighters` fighters standing for `ticks` ticks, with the v0 numbers.
func _standing(fighters: int, ticks: int, tickrate := 60) -> Tape:
	var tape := Tape.new(Tape.movement_v0(tickrate), Tape.combat_v0(tickrate))
	for fighter: int in fighters:
		var walker := Puppet.new(tape, fighter, Vector3(4.0 * fighter, 0.0, 0.0))
		walker.rest(ticks)
	return tape

# --- The first line ---


func test_first_line_of_one_fighter_says_1_lutador() -> void:
	var lines := _stripped(_standing(1, 120).summarize())
	assert_str(lines[0]).is_equal("120 ticks a 60 por segundo, 2 s, 1 lutador")


func test_first_line_of_the_spec_example_has_the_thousands_dot_and_the_minutes() -> void:
	# testes-e-entrega.md §4: 6860 ticks at 60 are 114,3 s, "1 min 54 s".
	var lines := _stripped(_standing(2, 6860).summarize())
	assert_str(lines[0]).is_equal("6.860 ticks a 60 por segundo, 1 min 54 s, 2 lutadores")


func test_first_line_rounds_the_duration_to_the_nearest_second() -> void:
	# 100 ticks at 60 are 1,67 s, and 80 ticks are 1,33 s.
	var up := _stripped(_standing(1, 100).summarize())
	assert_str(up[0]).is_equal("100 ticks a 60 por segundo, 2 s, 1 lutador")
	var down := _stripped(_standing(1, 80).summarize())
	assert_str(down[0]).is_equal("80 ticks a 60 por segundo, 1 s, 1 lutador")


func test_first_line_reads_the_ticks_per_second_from_the_configs() -> void:
	var lines := _stripped(_standing(1, 90, 30).summarize())
	assert_str(lines[0]).is_equal("90 ticks a 30 por segundo, 3 s, 1 lutador")


func test_first_line_of_three_fighters_says_3_lutadores() -> void:
	var lines := _stripped(_standing(3, 60).summarize())
	assert_str(lines[0]).is_equal("60 ticks a 60 por segundo, 1 s, 3 lutadores")

# --- One block per fighter ---


func test_one_fighter_has_one_report_and_only_its_own_block() -> void:
	var summary := _standing(1, 30).summarize()
	assert_int(summary.fighter_count()).is_equal(1)
	var lines := _stripped(summary)
	assert_int(lines.count(HEADERS[0])).is_equal(1)
	for line: String in lines:
		if line != HEADERS[0]:
			assert_bool(line.begins_with(BLOCK_PREFIX)) \
					.override_failure_message("a second block: '%s'" % line) \
					.is_false()


func test_two_fighters_have_the_block_of_you_then_the_block_of_the_other() -> void:
	var summary := _standing(2, 30).summarize()
	assert_int(summary.fighter_count()).is_equal(2)
	var lines := _stripped(summary)
	assert_int(lines.count(HEADERS[0])).is_equal(1)
	assert_int(lines.count(HEADERS[1])).is_equal(1)
	assert_int(lines.find(HEADERS[0])).is_greater(0)
	assert_int(lines.find(HEADERS[1])).is_greater(lines.find(HEADERS[0]))
	_assert_has_not(lines, HEADERS[2])


func test_a_third_fighter_has_its_block_last_under_its_own_header() -> void:
	var summary := _standing(3, 30).summarize()
	assert_int(summary.fighter_count()).is_equal(3)
	var lines := _stripped(summary)
	for header: String in HEADERS:
		assert_int(lines.count(header)).is_equal(1)
	assert_int(lines.find(HEADERS[1])).is_greater(lines.find(HEADERS[0]))
	assert_int(lines.find(HEADERS[2])).is_greater(lines.find(HEADERS[1]))


func test_two_fighters_fed_together_keep_separate_reports() -> void:
	var played := PlayedMatch.new(Tape.movement_v0(), Tape.combat_v0())
	# Far apart: nobody touches anybody.
	var jumper := played.add_fighter(Vector3.ZERO, 0.0)
	var swinger := played.add_fighter(Vector3(20.0, 0.0, 0.0), 0.0)
	played.press(jumper, 3, [JUMP])
	played.press(swinger, 5, [LIGHT])
	played.run(80)
	var summary := played.summarize()
	assert_int(summary.fighter_count()).is_equal(2)
	var first := summary.fighter(jumper)
	var second := summary.fighter(swinger)
	assert_int(first.ticks).is_equal(80)
	assert_int(second.ticks).is_equal(80)
	var first_jumps: int = first.maneuvers.get(ReplaySummary.JUMP, -1)
	var second_jumps: int = second.maneuvers.get(ReplaySummary.JUMP, -1)
	assert_int(first_jumps).is_equal(1)
	assert_int(second_jumps).is_equal(0)
	assert_int(first.presses.size()).is_equal(1)
	assert_str(first.presses[0].command).is_equal(JUMP)
	assert_int(second.presses.size()).is_equal(1)
	assert_str(second.presses[0].command).is_equal(LIGHT)
	assert_int(first.swings.size()).is_equal(0)
	assert_int(second.swings.size()).is_equal(1)
	assert_int(first.longest_flight).is_greater(0)
	assert_int(second.longest_flight).is_equal(0)
	var air: int = second.mode_ticks.get(FighterState.Mode.AIR, -1)
	assert_int(air).is_equal(0)
	# And each block has its own lines: the light's phases only under the fighter that clicked.
	var lines := _stripped(summary)
	_assert_has(_block(lines, jumper), NO_LIGHT)
	_assert_has_not(_block(lines, jumper), LIGHT_AT_60)
	_assert_has(_block(lines, swinger), LIGHT_AT_60)
	_assert_has_not(_block(lines, swinger), NO_LIGHT)

# --- The moves' lines ---


func test_a_fighter_with_no_click_prints_no_click_for_both_moves() -> void:
	var lines := _stripped(_standing(2, 30).summarize())
	for fighter: int in 2:
		var block := _block(lines, fighter)
		_assert_has(block, NO_LIGHT)
		_assert_has(block, NO_CHARGED)
		for line: String in block:
			assert_bool(line.begins_with("Leve: prepara")).is_false()
			assert_bool(line.begins_with("Carregado: prepara")).is_false()


func test_each_move_with_a_click_opens_with_its_phases_in_ticks_and_ms() -> void:
	var played := PlayedMatch.new(Tape.movement_v0(), Tape.combat_v0())
	played.add_fighter()
	played.press(0, 2, [LIGHT])
	played.press(0, 60, [CHARGED])
	played.run(160)
	var block := _block(_stripped(played.summarize()), 0)
	_assert_has(block, LIGHT_AT_60)
	_assert_has(block, CHARGED_AT_60)
	_assert_has_not(block, NO_LIGHT)
	_assert_has_not(block, NO_CHARGED)


func test_only_the_move_clicked_opens_with_its_phases() -> void:
	var played := PlayedMatch.new(Tape.movement_v0(), Tape.combat_v0())
	played.add_fighter()
	played.press(0, 2, [CHARGED])
	played.run(100)
	var block := _block(_stripped(played.summarize()), 0)
	_assert_has(block, NO_LIGHT)
	_assert_has(block, CHARGED_AT_60)
	_assert_has_not(block, LIGHT_AT_60)
	_assert_has_not(block, NO_CHARGED)


func test_a_click_that_never_fired_is_still_a_click_of_the_move() -> void:
	var played := PlayedMatch.new(Tape.movement_v0(), Tape.combat_v0())
	played.add_fighter()
	played.press(0, 2, [JUMP])
	played.press(0, 8, [LIGHT])
	played.run(80)
	var summary := played.summarize()
	# The scenario: the click in the air fired no swing.
	assert_int(summary.fighter(0).swings.size()).is_equal(0)
	var block := _block(_stripped(summary), 0)
	_assert_has(block, LIGHT_AT_60)
	_assert_has_not(block, NO_LIGHT)


func test_the_phases_come_from_the_configs_the_summary_was_made_with() -> void:
	# A replay whose header has the light's windup at 400 ms: its summary reads 24 ticks, though
	# today's combat_v0.tres says 250 ms.
	var data := Tape.combat_data_v0()
	data.light_attack.windup_ms = OLD_WINDUP_MS
	var combat := CombatConfig.create(data, 60)
	# The conversion: 400 ms are 24 ticks at 60.
	assert_int(Ticks.from_ms(OLD_WINDUP_MS, 60)).is_equal(OLD_WINDUP_TICKS)
	var played := PlayedMatch.new(Tape.movement_v0(), combat)
	played.add_fighter()
	played.press(0, 2, [LIGHT])
	played.run(80)
	var summary := played.summarize()
	var block := _block(_stripped(summary), 0)
	_assert_has(block, LIGHT_WITH_OLD_WINDUP)
	_assert_has_not(block, LIGHT_AT_60)
	assert_int(summary.fighter(0).swings.size()).is_equal(1)
	assert_int(summary.fighter(0).swings[0].active_tick).is_equal(2 + OLD_WINDUP_TICKS)


func test_at_30_ticks_the_phases_round_to_the_tick_and_the_ms_come_back_from_the_ticks() -> void:
	var movement := Tape.movement_v0(30)
	var combat := Tape.combat_v0(30)
	# The conversion and its rounding: 250 ms are 7,5 ticks at 30, which rounds up to 8.
	assert_int(Ticks.from_ms(250, 30)).is_equal(8)
	var light: AttackConfig = combat.attacks[LIGHT]
	assert_int(light.windup_ticks).is_equal(8)
	var played := PlayedMatch.new(movement, combat)
	played.add_fighter()
	played.press(0, 2, [LIGHT])
	played.press(0, 40, [CHARGED])
	played.run(100)
	var summary := played.summarize()
	var lines := _stripped(summary)
	assert_str(lines[0]).is_equal("100 ticks a 30 por segundo, 3 s, 1 lutador")
	var block := _block(lines, 0)
	_assert_has(block, LIGHT_AT_30)
	_assert_has(block, CHARGED_AT_30)
	assert_int(summary.fighter(0).swings.size()).is_equal(2)
	assert_int(summary.fighter(0).swings[0].active_tick).is_equal(2 + 8)
