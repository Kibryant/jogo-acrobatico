# TASK-12.4, criterion 9: the window of the tech in the summary of the replay
# (tools/replay_summary.gd), as testes-e-entrega.md §4 says ("Os apertos": "O aperto da quebra de
# quem está preso no GRABBED, depois do contato e até o último tick preso [...] é o tech [...] Um
# aperto da quebra depois disso, ainda sem agir, é um aperto como os outros"; "O agarrão": "o
# aperto do tech, que é o primeiro aperto da quebra depois do contato, até o último tick preso").
# The core counts the tech up to the last held tick, the contact + 20 + 4 - 1 at 60 (combate.md, "A
# quebra, o tech e a esquiva no tick": "O tech"; DEC-0058 §5). A press on that tick is the tech: no
# click, its ticks in the line "Agarrado:". A press later in GRABBED, still unable to act, is a
# click like any other: it waits in the slot, is lost "no agarrão" when its window closes before
# the victim acts again, or fires the guard break on the release, the contact + 76, when still
# within the buffer. The matches are played by the core's own rules
# (test/tools/replay_summary_grab_match.gd), and the summary is read only through its public
# interface: its lines, and the presses and the swings of each fighter's report.
extends GdUnitTestSuite

const ReplaySummary := preload("res://tools/replay_summary.gd")
const GrabMatch := preload("res://test/tools/replay_summary_grab_match.gd")
const GrabRig := preload("res://test/core/fighter/grab_rig.gd")
const Tape := preload("res://test/tools/replay_summary_tape.gd")

const GUARD_BREAK := GrabRig.GUARD_BREAK
const HEADERS: Array[String] = ["== Lutador 0, você", "== Lutador 1, o outro (o boneco ou o bot)"]
const BLOCK_PREFIX := "== Lutador "
const GRABBED_PREFIX := "Agarrado:"

# combate.md, "A quebra, o tech e a esquiva no tick": fired at F, a target 1,05 m straight along
# the hand is first touched by the 4th slice, so the contact is F + 21 + 3 ("A mão"); both are held
# up to the contact + 23 and let go on the contact + 24, the 20 ticks of the hold plus the 4 of the
# hitstop ("O agarrão"); without the tech the victim acts again on the contact + 76 ("O tech").
const F := 2
const CONTACT_AFTER := 24
const RELEASE := 24
const LAST_HELD := RELEASE - 1
const VICTIM_FREE := 76
# movimento.md, "Perdão": the slot keeps a press 150 ms, 9 ticks at 60, inclusive (DEC-0039).
const BUFFER_TICKS := 9
# A press 70 ticks after the contact waits in the slot for the release, 6 ticks later, within the
# 9 of the buffer.
const LATE_PRESS := 70
# movimento.md, "Câmera": the shoulder; combate.md, "A lâmina e o contato": "Convergência: 1,2 na
# quebra". The grabber, fighter 0, at the origin, its hand going down -Z; the victim, fighter 1,
# 1,05 m along it, looking back.
const SHOULDER_M := 0.8
const HAND_CONVERGENCE_M := 1.2
const IN_FRONT := Vector3(0.0, 0.0, -1.05)
const BACK_AT_THE_GRABBER := PI
# testes-e-entrega.md §4, "O agarrão": "Os formatos"; 23 ticks at 60 are 383 ms, ticks × 1000 ÷ 60
# to the nearest ms.
const NEVER_GRABBED := "Agarrado: nenhuma vez"
const GRABBED_ONCE_NO_TECH := "Agarrado: 1 vez; o tech em 0 (0 %)"
const GRABBED_WITH_THE_LAST_TECH := (
	"Agarrado: 1 vez; o tech em 1 (100 %); o aperto do tech, em mediana, 23 ticks (383 ms) "
	+ "depois do contato"
)
const NO_BREAK := "Quebra: nenhum clique"
const BREAK_AT_60 := (
	"Quebra: preparação 21 ticks (350 ms), ativo 6 ticks (100 ms), recuperação 24 ticks (400 ms)"
)
# testes-e-entrega.md §4, "Os cliques que não saíram", the 4th reason.
const IN_THE_GRAB := "no agarrão"

var played: GrabMatch


func _contact() -> int:
	return F + CONTACT_AFTER


# A fresh match: the grabber, fighter 0, breaks the guard of fighter 1 on F.
func _grab() -> void:
	played = GrabMatch.new(Tape.movement_v0(), Tape.combat_v0())
	var hand := GrabRig.camera_for(0.0, SHOULDER_M, HAND_CONVERGENCE_M)
	played.add_fighter(Vector3.ZERO, hand)
	played.add_fighter(IN_FRONT, BACK_AT_THE_GRABBER)
	played.press(0, F, GUARD_BREAK)


# The scenario, by the core's own stamps: the hand touched on the contact and fighter 1 was
# GRABBED by it on the next tick.
func _assert_the_grab_happened() -> void:
	var contact := _contact()
	assert_int(played.state(0, contact).contact_tick) \
			.override_failure_message("the hand did not touch on %d" % contact) \
			.is_equal(contact)
	var held := played.state(1, contact + 1)
	assert_bool(GrabRig.is_grabbed(held)) \
			.override_failure_message("fighter 1 at %d is %s" % [contact + 1, GrabRig.line(held)]) \
			.is_true()
	assert_int(GrabRig.grabbed_tick(held)).is_equal(contact)


# The summary's lines without the spaces around them.
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


# The one line of a block that begins with "Agarrado:", or "".
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


func _breaks_pressed(report: ReplaySummary.FighterReport) -> Array[ReplaySummary.Press]:
	var presses: Array[ReplaySummary.Press] = []
	for press: ReplaySummary.Press in report.presses:
		if press.command == GUARD_BREAK:
			presses.append(press)
	return presses


func _breaks_swung(report: ReplaySummary.FighterReport) -> Array[ReplaySummary.Swing]:
	var swings: Array[ReplaySummary.Swing] = []
	for swing: ReplaySummary.Swing in report.swings:
		if swing.move == GUARD_BREAK:
			swings.append(swing)
	return swings


# The last held tick, the contact + 23: the core counts the tech on it, and the summary takes the
# press as the tech, no click, its 23 ticks the median of the line "Agarrado:".
func test_a_press_on_the_last_held_tick_is_still_the_tech() -> void:
	_grab()
	var contact := _contact()
	var pressed := contact + LAST_HELD
	played.press(1, pressed, GUARD_BREAK)
	played.run(contact + RELEASE + 10)
	_assert_the_grab_happened()
	assert_int(GrabRig.tech_tick(played.state(1, pressed))) \
			.override_failure_message("the core did not count the tech on %d" % pressed) \
			.is_equal(pressed)
	var summary := played.summarize()
	var report := summary.fighter(1)
	assert_array(_breaks_pressed(report)).override_failure_message("the tech made a click") \
			.is_empty()
	assert_array(report.swings).is_empty()
	var lines := _stripped(summary)
	var victim := _block(lines, 1)
	assert_bool(victim.has(NO_BREAK)).override_failure_message("no line '%s'" % NO_BREAK).is_true()
	assert_str(_grabbed_line(victim)).is_equal(GRABBED_WITH_THE_LAST_TECH)
	assert_str(_grabbed_line(_block(lines, 0))).is_equal(NEVER_GRABBED)


# Past the last held tick, the release tick without the tech and a press 30 ticks after the
# contact, the victim still GRABBED until the contact + 76: the core counts no tech, and the press
# is a click like any other, which waits in the slot and is lost when its window closes, "no
# agarrão"; no guard break comes out, and the line "Agarrado:" says no tech.
func test_a_press_after_the_last_held_tick_is_a_click_lost_in_the_grab(
	pressed_after: int,
	_test_parameters := [[RELEASE], [30]],
) -> void:
	assert_int(pressed_after + BUFFER_TICKS).is_less(VICTIM_FREE)
	_grab()
	var contact := _contact()
	var pressed := contact + pressed_after
	played.press(1, pressed, GUARD_BREAK)
	played.run(contact + VICTIM_FREE + 10)
	_assert_the_grab_happened()
	var at_press := played.state(1, pressed)
	assert_bool(GrabRig.is_grabbed(at_press)).override_failure_message(GrabRig.line(at_press)) \
			.is_true()
	assert_int(GrabRig.tech_tick(played.state(1, contact + VICTIM_FREE))) \
			.override_failure_message("a tech past the hold") \
			.is_equal(FighterState.NEVER)
	var summary := played.summarize()
	var report := summary.fighter(1)
	var clicks := _breaks_pressed(report)
	assert_int(clicks.size()).override_failure_message("the press is no click").is_equal(1)
	if clicks.size() != 1:
		return
	assert_int(clicks[0].tick).is_equal(pressed)
	assert_int(clicks[0].fired_tick).is_equal(-1)
	assert_str(str(clicks[0].reason)).is_equal(str(ReplaySummary.IN_GRAB))
	assert_array(_breaks_swung(report)).override_failure_message("a guard break came out") \
			.is_empty()
	var victim := _block(_stripped(summary), 1)
	assert_bool(victim.has(BREAK_AT_60)).override_failure_message("no line '%s'" % BREAK_AT_60) \
			.is_true()
	assert_bool(_has_line_with(victim, IN_THE_GRAB)) \
			.override_failure_message("no line says '%s'" % IN_THE_GRAB) \
			.is_true()
	assert_str(_grabbed_line(victim)).is_equal(GRABBED_ONCE_NO_TECH)


# A press 70 ticks after the contact, the victim still GRABBED: no tech; the press waits in the slot
# and the guard break comes out on the release, the contact + 76, 6 ticks later, within the 9 of the
# buffer. The summary counts it as a click that fired after waiting, its swing fired on the release
# from the click of the contact + 70; the line "Agarrado:" says no tech and has no tech's press.
func test_a_press_late_in_the_grab_waits_in_the_slot_and_fires_at_the_release() -> void:
	assert_int(VICTIM_FREE - LATE_PRESS).is_less_equal(BUFFER_TICKS)
	_grab()
	var contact := _contact()
	var pressed := contact + LATE_PRESS
	var released := contact + VICTIM_FREE
	played.press(1, pressed, GUARD_BREAK)
	played.run(released + 10)
	_assert_the_grab_happened()
	var fired := played.state(1, released)
	var message := "fighter 1 at %d is %s" % [released, GrabRig.line(fired)]
	assert_int(fired.action).override_failure_message(message).is_equal(FighterState.Action.WINDUP)
	assert_int(fired.action_since).override_failure_message(message).is_equal(released)
	assert_str(String(fired.action_move)).is_equal(String(GUARD_BREAK))
	assert_int(GrabRig.tech_tick(fired)).is_equal(FighterState.NEVER)
	var summary := played.summarize()
	var report := summary.fighter(1)
	var clicks := _breaks_pressed(report)
	assert_int(clicks.size()).override_failure_message("the press is no click").is_equal(1)
	if clicks.size() == 1:
		assert_int(clicks[0].tick).is_equal(pressed)
		assert_int(clicks[0].fired_tick).is_equal(released)
		assert_str(str(clicks[0].reason)).is_empty()
	var swings := _breaks_swung(report)
	assert_int(swings.size()).is_equal(1)
	if swings.size() == 1:
		assert_int(swings[0].fire_tick).is_equal(released)
		assert_int(swings[0].press_tick).is_equal(pressed)
	var victim := _block(_stripped(summary), 1)
	assert_bool(victim.has(BREAK_AT_60)).is_true()
	assert_bool(_has_line_with(victim, "dos quais 1 esperou na vaga")) \
			.override_failure_message("the swing did not wait in the slot") \
			.is_true()
	assert_str(_grabbed_line(victim)).is_equal(GRABBED_ONCE_NO_TECH)
