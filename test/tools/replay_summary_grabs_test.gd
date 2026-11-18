# Criterion 9 of TASK-12.4: the guard break in the summary of the replay (tools/replay_summary.gd),
# as testes-e-entrega.md §4 says ("O resumo": "Os golpes", "O resultado" and "O agarrão";
# DEC-0058): per fighter, the guard breaks that came out and what became of each (grabbed with a
# tech, grabbed without one, missed, cut), and, of whoever was grabbed, the grabs, the techs and
# the tech rate. The spec fixes these lines word by word: the guard break's phases, "Quebra:
# nenhum clique", the result line and the three forms of "Agarrado:"; and the reason "no agarrão"
# of a click that never fired. The matches are played by the core's own rules
# (replay_summary_grab_match.gd), and the summary is read only through its public interface, agreed
# in the TASK-14 plan: its lines, and the swings and the presses of each fighter's report.
extends GdUnitTestSuite

const ReplaySummary := preload("res://tools/replay_summary.gd")
const GrabMatch := preload("res://test/tools/replay_summary_grab_match.gd")
const GrabRig := preload("res://test/core/fighter/grab_rig.gd")
const Tape := preload("res://test/tools/replay_summary_tape.gd")
const Puppet := preload("res://test/tools/replay_summary_puppet.gd")

const GUARD_BREAK := GrabRig.GUARD_BREAK
const LIGHT := FighterCommand.LIGHT_ATTACK

# The block headers, exactly (testes-e-entrega.md §4).
const HEADERS: Array[String] = ["== Lutador 0, você", "== Lutador 1, o outro (o boneco ou o bot)"]
const BLOCK_PREFIX := "== Lutador "
# testes-e-entrega.md §4, "Os golpes": each move opens with its phases, "com 'Carregado:' no
# carregado e 'Quebra:' na quebra"; a move with no click prints "Quebra: nenhum clique".
# combate.md, "Os golpes e as defesas": the guard break is 350, 100 and 400 ms, which at 60 ticks
# are 21, 6 and 24; the ms of the line come back from the ticks, ticks × 1000 ÷ 60.
const NO_BREAK := "Quebra: nenhum clique"
const BREAK_AT_60 := (
	"Quebra: preparação 21 ticks (350 ms), ativo 6 ticks (100 ms), recuperação 24 ticks (400 ms)"
)
# At 30 ticks the nearest tick, ties up: 350 ms are 10,5 ticks, so 11, which read 367 ms; 100 ms
# are 3 and 400 ms are 12.
const BREAK_AT_30 := (
	"Quebra: preparação 11 ticks (367 ms), ativo 3 ticks (100 ms), recuperação 12 ticks (400 ms)"
)
# testes-e-entrega.md §4, "O resultado": 'A linha é "Resultado: 6 agarraram (4 com tech e 2 sem
# tech), 3 erros e 1 cortada"'.
const RESULT_OF_THE_SPEC := "Resultado: 6 agarraram (4 com tech e 2 sem tech), 3 erros e 1 cortada"
# testes-e-entrega.md §4, "O agarrão": "Os formatos".
const NEVER_GRABBED := "Agarrado: nenhuma vez"
const GRABBED_ONCE_NO_TECH := "Agarrado: 1 vez; o tech em 0 (0 %)"
const GRABBED_OF_THE_SPEC := (
	"Agarrado: 6 vezes; o tech em 4 (67 %); o aperto do tech, em mediana, 15 ticks (250 ms) "
	+ "depois do contato"
)
const GRABBED_PREFIX := "Agarrado:"
# One grab with its tech, pressed 10 ticks after the contact: the count of the second format, the
# rate, 1 of 1, and the press of the third: 10 ticks are 167 ms.
const GRABBED_ONCE_WITH_A_TECH := "Agarrado: 1 vez; o tech em 1 (100 %)"
const TECH_PRESS_10_TICKS := "10 ticks (167 ms) depois do contato"
# testes-e-entrega.md §4, "Os cliques que não saíram", the 4th reason: "no agarrão".
const IN_THE_GRAB := "no agarrão"

# combate.md, "A quebra, o tech e a esquiva no tick": "As fases": fired at F, active from F + 21,
# free on F + 51. "A mão": a target 1,05 m straight along the hand is first touched by the 4th
# slice, so the contact is F + 24. "O agarrão": held to the contact + 23; "O tech": without one
# the victim acts again on the contact + 76.
const BREAK_ACTIVE := 21
const BREAK_OVER := 51
const CONTACT_AFTER := 24
const RELEASE := 24
const VICTIM_FREE := 76
# movimento.md, "Perdão": the slot keeps a press 150 ms, 9 ticks at 60, inclusive.
const BUFFER_TICKS := 9
# movimento.md, "Câmera": the shoulder; combate.md, "A lâmina e o contato": "Convergência: 2,0 na
# espada; 1,2 na quebra".
const SHOULDER_M := 0.8
const HAND_CONVERGENCE_M := 1.2
const SWORD_CONVERGENCE_M := 2.0
# The grabber, fighter 0, at the origin, its hand going down -Z; the other, fighter 1, 1,05 m
# along it.
const HAND_ALONG := 0.0
const IN_FRONT := Vector3(0.0, 0.0, -1.05)
const BACK_AT_THE_GRABBER := PI
const AWAY := 0.0
const TOLERANCE := 1e-3
# The tick of the first guard break of most matches: any tick after the first.
const F := 2

# The match of the spec's example: ten guard breaks by fighter 0, one every 200 ticks, so the bar
# is full again for each (movimento.md, "Stamina": 30 points a second after 800 ms). The first
# four grab and fighter 1 answers with the tech, pressed 10, 15, 15 and 20 ticks after the
# contact: a median of 15 ticks. The next two grab with no answer. The next two go the other way
# and touch nobody. The ninth touches fighter 1 in the active of a light it swings away, so nobody
# is grabbed: a miss. The tenth is cut in its windup by a light of fighter 1.
const PERIOD := 200
const FIRST_BREAK := 10
const TECH_PRESSES_AFTER: Array[int] = [10, 15, 15, 20]
const GRABS := 6
const TECHS := 4
const MISSES := 3
const CUTS := 1
const BREAKS := 10

var played: GrabMatch


func _hand_camera(direction: float) -> float:
	return GrabRig.camera_for(direction, SHOULDER_M, HAND_CONVERGENCE_M)


func _sword_camera(direction: float) -> float:
	return GrabRig.camera_for(direction, SHOULDER_M, SWORD_CONVERGENCE_M)


# A fresh match with the grabber, fighter 0, and the other, fighter 1, looking back at it.
func _duel(tickrate := 60) -> void:
	played = GrabMatch.new(Tape.movement_v0(tickrate), Tape.combat_v0(tickrate))
	played.add_fighter(Vector3.ZERO, _hand_camera(HAND_ALONG))
	played.add_fighter(IN_FRONT, BACK_AT_THE_GRABBER)


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


# The block has exactly one line that begins with "Agarrado:"; returns it, or "".
func _grabbed_line(block: Array[String]) -> String:
	var found: Array[String] = []
	for line: String in block:
		if line.begins_with(GRABBED_PREFIX):
			found.append(line)
	assert_int(found.size()).override_failure_message("%d lines begin with '%s'"
	% [found.size(), GRABBED_PREFIX]).is_equal(1)
	return found[0] if found.size() == 1 else ""


func _has_line_with(block: Array[String], part: String) -> bool:
	for line: String in block:
		if line.contains(part):
			return true
	return false


# The guard break's swings of a report.
func _breaks_of(report: ReplaySummary.FighterReport) -> Array[ReplaySummary.Swing]:
	var breaks: Array[ReplaySummary.Swing] = []
	for swing: ReplaySummary.Swing in report.swings:
		if swing.move == GUARD_BREAK:
			breaks.append(swing)
	return breaks


func _presses_of(report: ReplaySummary.FighterReport, command: StringName) -> Array[int]:
	var ticks: Array[int] = []
	for press: ReplaySummary.Press in report.presses:
		if press.command == command:
			ticks.append(press.tick)
	return ticks


# The scenario: the hand touched on `contact` and fighter 1 was GRABBED by it on the next tick.
func _assert_the_grab_happened(contact: int) -> void:
	assert_int(played.state(0, contact).contact_tick) \
			.override_failure_message("the hand did not touch on %d" % contact) \
			.is_equal(contact)
	var held := played.state(1, contact + 1)
	assert_bool(GrabRig.is_grabbed(held)) \
			.override_failure_message("fighter 1 at %d is %s" % [contact + 1, GrabRig.line(held)]) \
			.is_true()
	assert_int(GrabRig.grabbed_tick(held)).is_equal(contact)


# None: a replay with no guard break prints "Quebra: nenhum clique" and "Agarrado: nenhuma vez" in
# every fighter's block.
func test_a_replay_with_no_guard_break_says_no_click_and_never_grabbed() -> void:
	var tape := Tape.new(Tape.movement_v0(), Tape.combat_v0())
	for fighter: int in 2:
		var walker := Puppet.new(tape, fighter, Vector3(4.0 * fighter, 0.0, 0.0))
		walker.rest(60)
	var lines := _stripped(tape.summarize())
	for fighter: int in 2:
		var block := _block(lines, fighter)
		_assert_has(block, NO_BREAK)
		_assert_has(block, NEVER_GRABBED)
		assert_str(_grabbed_line(block)).is_equal(NEVER_GRABBED)
		for line: String in block:
			assert_bool(line.begins_with("Quebra: prepara")).is_false()


# One: a guard break alone in the arena opens with its phases in ticks and ms, is one click that
# fired at once, and one swing of its own move that missed.
func test_a_guard_break_alone_opens_with_its_phases_and_is_a_miss() -> void:
	played = GrabMatch.new(Tape.movement_v0(), Tape.combat_v0())
	played.add_fighter()
	played.press(0, F, GUARD_BREAK)
	played.run(F + BREAK_OVER + 10)
	var summary := played.summarize()
	var block := _block(_stripped(summary), 0)
	_assert_has(block, BREAK_AT_60)
	_assert_has_not(block, NO_BREAK)
	_assert_has(block, NEVER_GRABBED)
	var report := summary.fighter(0)
	var clicks := _presses_of(report, GUARD_BREAK)
	assert_int(clicks.size()).is_equal(1)
	if clicks.size() == 1:
		assert_int(clicks[0]).is_equal(F)
	var breaks := _breaks_of(report)
	assert_int(breaks.size()).is_equal(1)
	if breaks.size() != 1:
		return
	assert_str(breaks[0].result).is_equal(ReplaySummary.MISS)
	assert_int(breaks[0].fire_tick).is_equal(F)
	assert_int(breaks[0].active_tick).is_equal(F + BREAK_ACTIVE)
	assert_int(breaks[0].contact_tick).is_equal(-1)


# The conversion and its rounding: at 30 ticks the 350 ms of the windup are 10,5 ticks, which
# rounds up to 11 and reads 367 ms; the line comes from the configs the summary was made with.
func test_at_30_ticks_the_guard_breaks_phases_round_to_the_tick() -> void:
	assert_int(Ticks.from_ms(350, 30)).is_equal(11)
	assert_int(Ticks.from_ms(350, 60)).is_equal(21)
	played = GrabMatch.new(Tape.movement_v0(30), Tape.combat_v0(30))
	played.add_fighter()
	played.press(0, F, GUARD_BREAK)
	played.run(60)
	var block := _block(_stripped(played.summarize()), 0)
	_assert_has(block, BREAK_AT_30)
	_assert_has_not(block, BREAK_AT_60)


# One grab with no answer: the grabber's guard break is a swing with a contact on the other
# fighter, neither a miss nor cut nor unfinished, 1,05 m away on its first active tick; whoever was
# grabbed reads "Agarrado: 1 vez; o tech em 0 (0 %)", and the grabber "Agarrado: nenhuma vez".
func test_a_grab_without_a_tech_is_one_grab_and_a_tech_rate_of_0() -> void:
	_duel()
	played.press(0, F, GUARD_BREAK)
	played.run(F + CONTACT_AFTER + VICTIM_FREE + 10)
	var contact := F + CONTACT_AFTER
	_assert_the_grab_happened(contact)
	var summary := played.summarize()
	var lines := _stripped(summary)
	var grabber := _block(lines, 0)
	var victim := _block(lines, 1)
	_assert_has(grabber, BREAK_AT_60)
	assert_str(_grabbed_line(grabber)).is_equal(NEVER_GRABBED)
	_assert_has(victim, NO_BREAK)
	assert_str(_grabbed_line(victim)).is_equal(GRABBED_ONCE_NO_TECH)
	var breaks := _breaks_of(summary.fighter(0))
	assert_int(breaks.size()).is_equal(1)
	if breaks.size() != 1:
		return
	assert_int(breaks[0].contact_tick).is_equal(contact)
	assert_int(breaks[0].target).is_equal(1)
	assert_float(breaks[0].first_active_distance).is_equal_approx(IN_FRONT.length(), TOLERANCE)
	var result := str(breaks[0].result)
	assert_str(result).is_not_equal(str(ReplaySummary.MISS))
	assert_str(result).is_not_equal(str(ReplaySummary.CUT))
	assert_str(result).is_not_equal(str(ReplaySummary.UNFINISHED))
	# The guard break takes no health.
	assert_int(summary.fighter(1).lowest_health).is_equal(Tape.combat_v0().max_health)


# The tech is no click (testes-e-entrega.md §4, "Os apertos": "O aperto da quebra de quem está no
# GRABBED é o tech: ele fica fora das contas dos apertos e dos cliques e entra só na linha do
# agarrão"): whoever answered has no press and no swing of the guard break, still prints "Quebra:
# nenhum clique", and its "Agarrado:" line counts one grab, one tech, 100 %, and the press 10 ticks
# after the contact, 167 ms.
func test_a_tech_is_no_click_and_counts_only_in_the_grabbed_line() -> void:
	_duel()
	played.press(0, F, GUARD_BREAK)
	var contact := F + CONTACT_AFTER
	played.press(1, contact + 10, GUARD_BREAK)
	played.run(contact + RELEASE + 20)
	_assert_the_grab_happened(contact)
	assert_int(GrabRig.tech_tick(played.state(1, contact + 10))).is_equal(contact + 10)
	var summary := played.summarize()
	var victim := _block(_stripped(summary), 1)
	_assert_has(victim, NO_BREAK)
	var line := _grabbed_line(victim)
	assert_bool(line.begins_with(GRABBED_ONCE_WITH_A_TECH)) \
			.override_failure_message("'%s' does not begin with '%s'"
	% [line, GRABBED_ONCE_WITH_A_TECH]) \
			.is_true()
	assert_bool(line.contains(TECH_PRESS_10_TICKS)) \
			.override_failure_message("'%s' does not say '%s'" % [line, TECH_PRESS_10_TICKS]) \
			.is_true()
	var report := summary.fighter(1)
	assert_array(_presses_of(report, GUARD_BREAK)).is_empty()
	assert_int(report.presses.size()).is_equal(0)
	assert_int(report.swings.size()).is_equal(0)


# Many, the spec's own example: of ten guard breaks, six grab (four with the tech and two without),
# three miss and one is cut, and the result line says so word by word; whoever was grabbed reads
# six grabs, four techs, 67 %, and the median press of the tech 15 ticks, 250 ms, after the
# contact.
func test_the_result_line_and_the_grabbed_line_of_the_specs_example() -> void:
	_duel()
	var hand := _hand_camera(HAND_ALONG)
	var contacts: Array[int] = []
	for index: int in BREAKS:
		played.press(0, FIRST_BREAK + PERIOD * index, GUARD_BREAK)
	for index: int in GRABS:
		contacts.append(FIRST_BREAK + PERIOD * index + CONTACT_AFTER)
	for index: int in TECHS:
		played.press(1, contacts[index] + TECH_PRESSES_AFTER[index], GUARD_BREAK)
	# The 7th and the 8th go the other way, up +Z, where nobody is.
	var seventh := FIRST_BREAK + PERIOD * 6
	var eighth := FIRST_BREAK + PERIOD * 7
	played.look_from(0, seventh - 5, hand + PI)
	played.look_from(0, eighth + BREAK_OVER + 5, hand)
	# The 9th touches fighter 1 in the active of a light it swings down -Z, away from the grabber:
	# fired 17 ticks before the hand's contact, it is active from 2 ticks before it to 3 after.
	var ninth := FIRST_BREAK + PERIOD * 8
	played.look_from(1, ninth - 30, _sword_camera(AWAY))
	played.press(1, ninth + CONTACT_AFTER - 17, LIGHT)
	# The 10th is cut: fighter 1 turns its swing back at the grabber and clicks 10 ticks before the
	# guard break, so its light lands in the first ticks of the windup.
	var tenth := FIRST_BREAK + PERIOD * 9
	played.look_from(1, tenth - 60, _sword_camera(BACK_AT_THE_GRABBER))
	played.press(1, tenth - 10, LIGHT)
	played.run(tenth + 120)
	# The scenario, by the core's own stamps.
	for contact: int in contacts:
		_assert_the_grab_happened(contact)
	var ninth_contact := ninth + CONTACT_AFTER
	assert_int(played.state(0, ninth_contact).contact_tick).is_equal(ninth_contact)
	assert_int(played.state(1, ninth_contact).action).is_equal(FighterState.Action.ACTIVE)
	assert_bool(GrabRig.is_grabbed(played.state(1, ninth_contact + 1))).is_false()
	assert_int(played.state(0, tenth + 12).action) \
			.override_failure_message("the 10th guard break was not cut by the light") \
			.is_equal(FighterState.Action.HITSTUN)
	var summary := played.summarize()
	var lines := _stripped(summary)
	var grabber := _block(lines, 0)
	var victim := _block(lines, 1)
	_assert_has(grabber, BREAK_AT_60)
	_assert_has(grabber, RESULT_OF_THE_SPEC)
	assert_str(_grabbed_line(grabber)).is_equal(NEVER_GRABBED)
	assert_str(_grabbed_line(victim)).is_equal(GRABBED_OF_THE_SPEC)
	_assert_has(victim, NO_BREAK)
	var breaks := _breaks_of(summary.fighter(0))
	assert_int(breaks.size()).is_equal(BREAKS)
	var misses := 0
	var cuts := 0
	var landed := 0
	for swing: ReplaySummary.Swing in breaks:
		if swing.result == ReplaySummary.MISS:
			misses += 1
		elif swing.result == ReplaySummary.CUT:
			cuts += 1
		elif swing.target == 1 and contacts.has(swing.contact_tick):
			landed += 1
	assert_int(misses).is_equal(MISSES)
	assert_int(cuts).is_equal(CUTS)
	assert_int(landed).is_equal(GRABS)
	# The four techs are no clicks of fighter 1's.
	assert_array(_presses_of(summary.fighter(1), GUARD_BREAK)).is_empty()


# The failure, a click lost in the grab (testes-e-entrega.md §4, "Os cliques que não saíram", the
# 4th reason, after the stun and before the stance: "no agarrão: o estado depois do tick está no
# GRABBING ou no GRABBED"): a light either fighter clicks 6 ticks after the contact, held, never
# fires, its window closing before the release, and its block says "no agarrão"; the reason is
# none of the others.
func test_a_click_while_held_is_lost_in_the_grab(
	fighter: int,
	_test_parameters := [[0], [1]],
) -> void:
	_duel()
	played.press(0, F, GUARD_BREAK)
	var contact := F + CONTACT_AFTER
	var click := contact + 6
	assert_int(click + BUFFER_TICKS).is_less(contact + RELEASE)
	played.press(fighter, click, LIGHT)
	played.run(contact + VICTIM_FREE + 10)
	_assert_the_grab_happened(contact)
	var on_click := played.state(fighter, click)
	assert_bool(GrabRig.is_grabbing(on_click) or GrabRig.is_grabbed(on_click)).is_true()
	var summary := played.summarize()
	var report := summary.fighter(fighter)
	var lost: ReplaySummary.Press = null
	for press: ReplaySummary.Press in report.presses:
		if press.command == LIGHT and press.tick == click:
			lost = press
	assert_object(lost).override_failure_message("no press of the light on %d" % click) \
			.is_not_null()
	if lost == null:
		return
	assert_int(lost.fired_tick).is_equal(-1)
	var others: Array[String] = [
		str(ReplaySummary.SAME_TICK),
		str(ReplaySummary.SWING),
		str(ReplaySummary.STUN),
		str(ReplaySummary.STANCE),
		str(ReplaySummary.OFF_FLOOR),
		str(ReplaySummary.NO_STAMINA),
	]
	var reason := str(lost.reason)
	assert_bool(others.has(reason)) \
			.override_failure_message("the click's reason is %s, expected the grab's" % reason) \
			.is_false()
	assert_str(reason).override_failure_message("the lost click has no reason").is_not_empty()
	var block := _block(_stripped(summary), fighter)
	assert_bool(_has_line_with(block, IN_THE_GRAB)) \
			.override_failure_message("no line of fighter %d's block says '%s'"
	% [fighter, IN_THE_GRAB]) \
			.is_true()
