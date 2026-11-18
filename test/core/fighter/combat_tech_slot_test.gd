# Criterion 3 of TASK-12.4, the tech apart from the slot (combate.md, "A quebra, o tech e a
# esquiva no tick": "O tech": "O tech não passa pela vaga: o aperto da quebra conta mesmo com
# outras teclas apertadas no mesmo tick ou depois dele, dentro do agarrão"; DEC-0058 §5), through
# the public interface of core/fighter, with GrabRigs under a Duel and a TickPhoto taken on every
# tick, the scene of test/core/fighter/combat_grab_test.gd. C is the contact tick. Whoever was
# grabbed is frozen from C + 1 to C + 4, so a press of the guard break in the hitstop counts on
# C + 5, and one later counts on its own tick, up to the last held tick, C + 23, whatever else is
# pressed on that tick or later: a light or a jump that would take the slot after it, a dash or a
# parry that would win the slot on its own tick. The tech then lets the victim go on C + 24 and
# the grabber on C + 26, and no other press of the hold comes out: each expires in the slot before
# the release. The tech's press never waits in the slot either: it fires no guard break of the
# victim's own at the release, nor does a second press of the same hold. Every number comes from
# docs/design, cited by section.
extends GdUnitTestSuite

const GrabRig := preload("res://test/core/fighter/grab_rig.gd")
const Player := preload("res://test/core/fighter/grab_player.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")
const Duel := preload("res://test/core/fighter/duel.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
const GUARD_BREAK := GrabRig.GUARD_BREAK
const VICTIM_NAME := &"A"
const GRABBER_NAME := &"B"
const VICTIM := 0
const GRABBER := 1

# combate.md, "Os golpes e as defesas": the guard break's windup of 21 ticks at 60. "A mão": a
# target 1,05 m straight along the hand is first touched by the 4th slice, so the contact is F + 24.
const WINDUP_TICKS := 21
const CONTACT_ACTIVE_TICK := 4
# "O agarrão": held up to C + 23, let go on C + 24; "O tech": "um aperto durante a paradinha conta
# em C + 5"; "quem agarrou [...] se solta em C + 26".
const RELEASE := 24
const FIRST_TECH_OFFSET := 5
const TECH_ADVANTAGE := 2
# movimento.md, "Perdão": the slot keeps a press 150 ms, 9 ticks at 60, inclusive (DEC-0039).
const BUFFER_TICKS := 9
const PRESS := FIRST_TICK + 30 # the grabber's press: arithmetic
const SPARE_TICKS := 6 # arithmetic
# movimento.md, "Câmera": the shoulder; combate.md, "A lâmina e o contato": "Convergência: 1,2 na
# quebra". The grabber at the origin, its hand down -Z; the victim 1,05 m along it, looking back.
const SHOULDER_M := 0.8
const HAND_CONVERGENCE_M := 1.2
const VICTIM_FEET := Vector3(0.0, 0.0, -1.05)
const FACING_THE_GRABBER := PI


class Scene:
	var duel := Duel.new()
	var victim: Player
	var grabber: Player


func _rig(name: StringName, feet: Vector3, yaw: float) -> GrabRig:
	return GrabRig.new(
		name,
		MovementRig.load_config(60),
		GrabRig.load_combat(60),
		FIRST_TICK,
		feet,
		yaw,
	)


func _contact() -> int:
	return PRESS + WINDUP_TICKS + CONTACT_ACTIVE_TICK - 1


func _scene() -> Scene:
	var scene := Scene.new()
	scene.victim = Player.new(FACING_THE_GRABBER)
	var hand := GrabRig.camera_for(0.0, SHOULDER_M, HAND_CONVERGENCE_M)
	scene.grabber = Player.new(hand)
	scene.grabber.press(PRESS, GUARD_BREAK)
	scene.duel.add(_rig(VICTIM_NAME, VICTIM_FEET, FACING_THE_GRABBER), scene.victim.input)
	scene.duel.add(_rig(GRABBER_NAME, Vector3.ZERO, 0.0), scene.grabber.input)
	return scene


func _assert_no(violations: Array[String]) -> void:
	assert_array(violations).override_failure_message(GrabRig.brief(violations)).is_empty()


# The grab of the contact, as the locked suite reads it: the victim GRABBED on C + 1 with the
# contact in its grabbed_tick.
func _assert_grabbed(scene: Scene) -> void:
	var contact := _contact()
	assert_int(scene.duel.contact_tick_of(GRABBER)).is_equal(contact)
	var held := scene.duel.row_at(contact + 1).fought[VICTIM]
	assert_bool(GrabRig.is_grabbed(held)).override_failure_message(GrabRig.line(held)).is_true()
	assert_int(GrabRig.grabbed_tick(held)).is_equal(contact)


# The tech counted on `counted` and on no tick before it; the victim free on C + 24 and the grabber
# on C + 26; between the contact and C + 26 the victim began nothing, fired no command (no jump, no
# dash, no parry, no move) and paid no stamina: every other press expired in the slot.
func _assert_tech_on(scene: Scene, counted: int) -> void:
	var contact := _contact()
	var violations: Array[String] = []
	for row: Duel.Row in scene.duel.rows:
		var tech := GrabRig.tech_tick(row.fought[VICTIM])
		var expected := counted if row.tick >= counted else FighterState.NEVER
		if tech != expected:
			violations.append("tick %d: tech_tick %d, expected %d" % [row.tick, tech, expected])
		if row.tick <= contact or row.tick > contact + RELEASE + TECH_ADVANTAGE:
			continue
		var victim := row.fought[VICTIM]
		var ended := row.ends[VICTIM]
		var began := victim.action == FighterState.Action.WINDUP
		if began or victim.action == FighterState.Action.PARRY:
			violations.append("tick %d: the victim began %s" % [row.tick, GrabRig.line(victim)])
		if ended.jumps_used != 0 or ended.dash_tick != FighterState.NEVER:
			violations.append("tick %d: the victim jumped or dashed" % row.tick)
		if victim.stamina_spent_tick != FighterState.NEVER:
			violations.append("tick %d: the victim paid stamina" % row.tick)
	_assert_no(violations)
	assert_int(GrabRig.free_tick(scene.duel, VICTIM, contact + 1)).is_equal(contact + RELEASE)
	assert_int(GrabRig.free_tick(scene.duel, GRABBER, contact + 2)).is_equal(
		contact + RELEASE + TECH_ADVANTAGE
	)


# The five combinations the slot would have lost (DEC-0058 §5; "O tech não passa pela vaga"): the
# guard break on C + 2 and then a light on C + 3, both in the hitstop; the guard break on C + 2 and
# then a jump on C + 4; the guard break with a dash, or with a parry, on the same tick C + 2; and
# the guard break with every other key on the same tick C + 10, out of the hitstop. The tech counts
# on C + 5 for a press of the hitstop and on C + 10 for the other, as alone.
func test_the_tech_counts_whatever_else_is_pressed_in_the_hold(
	case: String,
	break_after: int,
	others: Array,
	others_after: int,
	_test_parameters := [
		["a light after it", 2, [FighterCommand.LIGHT_ATTACK], 3],
		["a jump after it", 2, [FighterCommand.JUMP], 4],
		["a dash on its tick", 2, [FighterCommand.DASH], 2],
		["a parry on its tick", 2, [FighterCommand.PARRY], 2],
		[
			"every key on its tick",
			10,
			[
				FighterCommand.LIGHT_ATTACK,
				FighterCommand.CHARGED_ATTACK,
				FighterCommand.PARRY,
				FighterCommand.JUMP,
				FighterCommand.DASH,
				FighterCommand.GRAPPLE,
			],
			10,
		],
	],
) -> void:
	assert_int(others_after + BUFFER_TICKS).override_failure_message(case).is_less(RELEASE)
	var scene := _scene()
	var contact := _contact()
	scene.victim.press(contact + break_after, GUARD_BREAK)
	for command: StringName in others:
		scene.victim.press(contact + others_after, command)
	scene.duel.run_through(contact + RELEASE + TECH_ADVANTAGE + SPARE_TICKS)
	_assert_grabbed(scene)
	_assert_tech_on(scene, contact + maxi(break_after, FIRST_TECH_OFFSET))


# The tech's press never waits in the slot: pressed on the last held tick, it counts there, and on
# the release the victim stands free, its own guard break not fired (combate.md, "O tech": "o tech
# não é um comando que sai").
func test_the_techs_press_fires_no_guard_break_at_the_release() -> void:
	var scene := _scene()
	var contact := _contact()
	scene.victim.press(contact + RELEASE - 1, GUARD_BREAK)
	scene.duel.run_through(contact + RELEASE + BUFFER_TICKS + SPARE_TICKS)
	_assert_grabbed(scene)
	_assert_tech_on(scene, contact + RELEASE - 1)
	var violations: Array[String] = []
	for row: Duel.Row in scene.duel.rows:
		if row.tick >= contact + RELEASE and row.fought[VICTIM].action != FighterState.Action.NONE:
			violations.append(
				"tick %d: the victim is %s" % [row.tick, GrabRig.line(row.fought[VICTIM])]
			)
		if row.fought[VICTIM].buffered_command == GUARD_BREAK:
			violations.append("tick %d: the tech's press waits in the slot" % row.tick)
	_assert_no(violations)


# A second guard break of the same hold adds nothing: the tech stays on the first, and neither press
# fires a guard break at the release.
func test_a_second_press_of_the_same_hold_adds_nothing() -> void:
	var scene := _scene()
	var contact := _contact()
	scene.victim.press(contact + 6, GUARD_BREAK)
	scene.victim.press(contact + 16, GUARD_BREAK)
	scene.duel.run_through(contact + RELEASE + BUFFER_TICKS + SPARE_TICKS)
	_assert_grabbed(scene)
	_assert_tech_on(scene, contact + 6)
	var last := scene.duel.rows[scene.duel.rows.size() - 1].fought[VICTIM]
	assert_int(last.action).override_failure_message(GrabRig.line(last)).is_equal(
		FighterState.Action.NONE
	)
