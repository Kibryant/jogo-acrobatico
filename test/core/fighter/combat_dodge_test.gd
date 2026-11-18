# Criteria 5 and 6 of TASK-12.4, and the dash's part of criterion 2: the dash as the dodge
# (glossario.md, "Esquiva"; combate.md, "A esquiva e o dash" and "A quebra, o tech e a esquiva no
# tick": "A esquiva" and "O golpe corta o dash"; movimento.md, "Dash": "Invulnerabilidade";
# DEC-0050; DEC-0058 §6), through the public interface of core/fighter, with GrabRigs under a Duel
# and a TickPhoto taken on every tick. The tick the dash fires is its 1st; on its 3rd to 10th a
# blade or a hand that touches the capsule passes without stamping the contact, and the move stays
# live; on the 1st, 2nd, 11th and 12th it lands and cuts the dash, which ends as it would on its
# own, with the ground mode and the exit speed. A guard break that only touches the invulnerable
# ticks misses, and whoever tried it recovers in 24 ticks. Every number comes from docs/design,
# cited by section; the geometry is worked out by hand beside each scene.
extends GdUnitTestSuite

const GrabRig := preload("res://test/core/fighter/grab_rig.gd")
const Player := preload("res://test/core/fighter/grab_player.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")
const Duel := preload("res://test/core/fighter/duel.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
const GUARD_BREAK := GrabRig.GUARD_BREAK
const LIGHT := &"light_attack" # glossario.md, "Golpe leve"
# The fighters by name, the photo's key (DEC-0051 §1), and by index in the Duel.
const DASHER_NAME := &"A"
const ATTACKER_NAME := &"B"
const DASHER := 0
const ATTACKER := 1

# movimento.md, "Dash": 4 m in 200 ms, 12 ticks at 60, so a third of a metre per tick; it leaves at
# 7 m/s; "Invulnerabilidade: dos ticks 3 a 10 dos 12"; combate.md, "Os golpes e as defesas", the
# row "Esquiva": "é o dash: 200, invulnerável de 50 a 167": 50 ms are 3 ticks at 60 and 167 ms are
# 10,02, so 10.
const DASH_MS := 200
const DASH_TICKS := 12
const DASH_DISTANCE_M := 4.0
const DASH_STEP_M := DASH_DISTANCE_M / DASH_TICKS
const DASH_EXIT_SPEED_MPS := 7.0
const INVULNERABLE_FROM_MS := 50
const INVULNERABLE_TO_MS := 167
const FIRST_INVULNERABLE_TICK := 3
const LAST_INVULNERABLE_TICK := 10
const DISTANCE_TOLERANCE_M := 0.01 # 1 cm, the dash's own tolerance (TASK-10.4, criterion 1)
# combate.md, "Os golpes e as defesas": the light is 15 / 6 / 12 ticks, 33 in all, and takes 12;
# "O tranco e a vantagem": "Leve acerta: 24 ticks"; "O hitstop e o tremor": "Leve acerta: 4".
const LIGHT_WINDUP_TICKS := 15
const LIGHT_SWING_TICKS := 33
const LIGHT_DAMAGE := 12
const LIGHT_HITSTOP_TICKS := 4
# The guard break is 21 / 6 / 24 ticks, 51 in all; "Quebra pega: os dois, 4 ticks"; the hold ends
# on the contact + 24 ("O agarrão").
const BREAK_WINDUP_TICKS := 21
const BREAK_ACTIVE_TICKS := 6
const BREAK_RECOVERY_TICKS := 24
const BREAK_SWING_TICKS := 51
const GRAB_HITSTOP_TICKS := 4
const RELEASE := 24
const MAX_HEALTH := 100 # partida.md, "A vida sem partida"

# movimento.md, "Câmera": the shoulder, 0,8 m; combate.md, "A lâmina e o contato": "Convergência:
# 2,0 na espada; 1,2 na quebra".
const SHOULDER_M := 0.8
const HAND_CONVERGENCE_M := 1.2
const SWORD_CONVERGENCE_M := 2.0

# The light against the dash. The attacker stands at the origin and swings down -Z; the dasher
# comes straight at it along that line, a third of a metre per tick. combate.md, "O arco do leve":
# the slice of the active tick k runs from -60° + 20°·(k - 1) to -60° + 20°·k of the swing, between
# 0,6 and 2,0 m, and touches within 0,43 m of the axis. An axis dead ahead is in the 3rd slice,
# which ends there, and in the 4th, which begins there, and in no other while it is farther than
# 0,43 / sin 20° = 1,26 m: the 2nd and the 5th pass r · sin 20° to its side. So the blade can only
# touch on the 3rd and the 4th active ticks, F + 17 and F + 18.
# The photo of F + 17 shows the dasher 2,3 m away (the slice's corner is 0,3 m from the axis), the
# photo of F + 18 shows it 1,967 m away (inside the slice), and the photos of F + 19 and F + 20
# show it 1,633 and 1,3 m away, 0,56 and 0,84 m from the 5th and the 6th slices.
const LIGHT_ALONG := 0.0
const SEEN_AT_M := 2.3
const THIRD_SLICE := 3
# The hand against the dash. The grabber stands at the origin and its hand goes down -Z; the dasher
# crosses that line 1,0 m ahead, from the left to the right (+X), a third of a metre per tick.
# "A mão": the slice of the active tick k runs from 0,2 · (k - 1) to 0,2 · k m and touches within
# 0,35 m. An axis 1,0 m along the line and x to its side is 0,54 m from the 4th slice with x at
# -0,5, a sixth of a metre from the 5th with x at -1/6 and from the 6th with x at +1/6, and the 3rd
# slice ends 0,4 m short of it wherever it is. So the photo of F + 25, the 5th active tick, is the
# first that shows the dasher within the hand's reach, and the photo of F + 26 the second and last.
const HAND_ALONG := 0.0
const CROSSES_AT_M := 1.0
const SEEN_AT_SIDE_M := -1.0 / 6.0
const FIFTH_SLICE := 5
const HAND_TOUCH_M := 0.35
# The dasher standing still 1,05 m straight along the hand is first touched by the 4th slice.
const STANDING_FEET := Vector3(0.0, 0.0, -1.05)
const FOURTH_SLICE := 4

const FORWARD := Vector2(0, 1) # move.y goes forward, relative to yaw (TASK-9 plan)
const RIGHT := Vector2(1, 0)
const TOWARD_THE_ATTACKER := PI # the dasher's camera looks up +Z
const DOWN_THE_LINE := 0.0 # the dasher's camera looks down -Z, +X to its right
const HAIR := 1e-6 # floating-point slack, not a design number
const PLACE_HAIR := 1e-3 # a millimetre on a position summed over ticks in 32-bit vectors
const SPARE_TICKS := 6 # ticks a run keeps going past the last event: arithmetic
const PRESS_AFTER_START := 30 # ticks after FIRST_TICK the attacker presses: arithmetic
const PRESS := FIRST_TICK + PRESS_AFTER_START


# The fighters of one scene, their scripts, the tick the dash fires and where the dasher began.
class Scene:
	var duel := Duel.new()
	var dasher: Player
	var attacker: Player
	var dash_tick := 0
	var start := Vector3.ZERO


func _rig(name: StringName, feet: Vector3, yaw: float) -> GrabRig:
	return GrabRig.new(
		name,
		MovementRig.load_config(60),
		GrabRig.load_combat(60),
		FIRST_TICK,
		feet,
		yaw,
	)


func _assert_no(violations: Array[String]) -> void:
	assert_array(violations).override_failure_message(GrabRig.brief(violations)).is_empty()


func _horizontal_speed(velocity: Vector3) -> float:
	return Vector2(velocity.x, velocity.z).length()


# The attacker at the origin swinging the light down -Z on PRESS, and the dasher on that line,
# dashing straight at it, placed so that the photo of the 3rd active tick, F + 17, shows it 2,3 m
# away on the tick `seen_on` of its dash.
func _light_scene(seen_on: int) -> Scene:
	var scene := Scene.new()
	var third := PRESS + LIGHT_WINDUP_TICKS + THIRD_SLICE - 1
	scene.dash_tick = third - seen_on + 1
	scene.start = Vector3(0.0, 0.0, -(SEEN_AT_M + DASH_STEP_M * (seen_on - 1)))
	scene.dasher = Player.new(TOWARD_THE_ATTACKER)
	scene.dasher.press(scene.dash_tick, FighterCommand.DASH)
	scene.dasher.push_from(scene.dash_tick, FORWARD)
	scene.dasher.push_from(scene.dash_tick + 1, Vector2.ZERO)
	scene.attacker = Player.new(GrabRig.camera_for(LIGHT_ALONG, SHOULDER_M, SWORD_CONVERGENCE_M))
	scene.attacker.press(PRESS, FighterCommand.LIGHT_ATTACK)
	scene.duel.add(_rig(DASHER_NAME, scene.start, TOWARD_THE_ATTACKER), scene.dasher.input)
	scene.duel.add(_rig(ATTACKER_NAME, Vector3.ZERO, LIGHT_ALONG), scene.attacker.input)
	return scene


# The grabber at the origin, its hand going down -Z, pressing the guard break on PRESS, and the
# dasher crossing the hand's line 1,0 m ahead, from the left, placed so that the photo of the 5th
# active tick, F + 25, shows it a sixth of a metre short of the line on the tick `seen_on` of its
# dash.
func _hand_scene(seen_on: int) -> Scene:
	var scene := Scene.new()
	var fifth := PRESS + BREAK_WINDUP_TICKS + FIFTH_SLICE - 1
	scene.dash_tick = fifth - seen_on + 1
	scene.start = Vector3(SEEN_AT_SIDE_M - DASH_STEP_M * (seen_on - 1), 0.0, -CROSSES_AT_M)
	scene.dasher = Player.new(DOWN_THE_LINE)
	scene.dasher.press(scene.dash_tick, FighterCommand.DASH)
	scene.dasher.push_from(scene.dash_tick, RIGHT)
	scene.dasher.push_from(scene.dash_tick + 1, Vector2.ZERO)
	scene.attacker = Player.new(GrabRig.camera_for(HAND_ALONG, SHOULDER_M, HAND_CONVERGENCE_M))
	scene.attacker.press(PRESS, GUARD_BREAK)
	scene.duel.add(_rig(DASHER_NAME, scene.start, DOWN_THE_LINE), scene.dasher.input)
	scene.duel.add(_rig(ATTACKER_NAME, Vector3.ZERO, HAND_ALONG), scene.attacker.input)
	return scene


# The dash fired on its tick, as the movement's slice left it (F-177): the stamp, and the mode.
func _assert_the_dash_fired(scene: Scene) -> void:
	var fired := scene.duel.row_at(scene.dash_tick).ends[DASHER]
	assert_int(fired.dash_tick).override_failure_message("the dash did not fire on %d"
	% scene.dash_tick) \
			.is_equal(scene.dash_tick)
	assert_int(fired.mode).is_equal(FighterState.Mode.DASH)


# The tick of the dash a tick is: the tick the dash fires is the 1st.
func _dash_tick_of(scene: Scene, tick: int) -> int:
	return tick - scene.dash_tick + 1


# The photo of `tick` shows the dasher as the tick before left it: its distance from the origin on
# the floor's plane.
func _seen_distance(scene: Scene, tick: int) -> float:
	var feet := scene.duel.row_at(tick - 1).feet[DASHER]
	return Vector2(feet.x, feet.z).length()


# The dash was cut by the contact at `contact` and its freeze of `hitstop` ticks: frozen from
# contact + 1, the body stays where the contact tick left it; on the first tick the movement runs
# again, contact + 1 + hitstop, the mode is the ground's and the body leaves at the exit speed at
# most, never at the dash's 20 m/s; and the dash never comes back ("O golpe corta o dash").
func _assert_the_dash_was_cut(scene: Scene, contact: int, hitstop: int) -> void:
	var last := scene.duel.rows[scene.duel.rows.size() - 1].tick
	_assert_no(GrabRig.frozen_violations(scene.duel, DASHER, contact + 1, contact + hitstop, last))
	var held_at := scene.duel.row_at(contact).feet[DASHER]
	var runs_again := contact + 1 + hitstop
	var violations: Array[String] = []
	for row: Duel.Row in scene.duel.rows:
		if row.tick > contact and row.tick < runs_again:
			if row.feet[DASHER].distance_to(held_at) > HAIR:
				violations.append("tick %d: the frozen dasher moved" % row.tick)
		if row.tick >= runs_again:
			if row.ends[DASHER].mode != FighterState.Mode.GROUND:
				violations.append(
					"tick %d: mode %d, expected the ground's" % [row.tick, row.ends[DASHER].mode]
				)
			var speed := _horizontal_speed(row.plans[DASHER].velocity)
			if speed > DASH_EXIT_SPEED_MPS + HAIR:
				violations.append("tick %d: %.2f m/s, above the exit speed" % [row.tick, speed])
		if row.ends[DASHER].dash_tick != scene.dash_tick and row.tick >= scene.dash_tick:
			violations.append("tick %d: another dash" % row.tick)
	_assert_no(violations)
	var moved := scene.duel.row_at(runs_again).feet[DASHER].distance_to(held_at)
	assert_float(moved).override_failure_message("the cut dash moved %.3f m on its exit tick"
	% moved) \
			.is_less_equal(DASH_EXIT_SPEED_MPS / 60.0 + HAIR)


# The dash ran whole: 12 ticks in the dash's mode, 4 m, then the ground's mode at the exit speed at
# most; the dasher was never hit, never grabbed and never frozen.
func _assert_the_dash_ran_whole(scene: Scene) -> void:
	var violations: Array[String] = []
	for row: Duel.Row in scene.duel.rows:
		var state := row.fought[DASHER]
		if state.health != MAX_HEALTH or state.hurt_tick != FighterState.NEVER:
			violations.append("tick %d: the dasher was hit, %s" % [row.tick, GrabRig.line(state)])
		if GrabRig.is_grabbed(state) or GrabRig.grabbed_tick(state) != FighterState.NEVER:
			violations.append(
				"tick %d: the dasher was grabbed, %s" % [row.tick, GrabRig.line(state)]
			)
		if row.plans[DASHER].frozen or row.plans[ATTACKER].frozen:
			violations.append("tick %d: somebody froze" % row.tick)
		var dashing := row.tick >= scene.dash_tick and row.tick < scene.dash_tick + DASH_TICKS
		if dashing != (row.ends[DASHER].mode == FighterState.Mode.DASH):
			violations.append("tick %d: mode %d" % [row.tick, row.ends[DASHER].mode])
	_assert_no(violations)
	var last_dash_tick := scene.dash_tick + DASH_TICKS - 1
	var travelled := scene.duel.row_at(last_dash_tick).feet[DASHER].distance_to(scene.start)
	assert_float(travelled).is_equal_approx(DASH_DISTANCE_M, DISTANCE_TOLERANCE_M)
	var exit := scene.duel.row_at(last_dash_tick + 1)
	assert_int(exit.ends[DASHER].mode).is_equal(FighterState.Mode.GROUND)
	assert_float(_horizontal_speed(exit.plans[DASHER].velocity)).is_less_equal(
		DASH_EXIT_SPEED_MPS + HAIR
	)


# The conversion: the dash's 200 ms are 12 ticks at 60, and its invulnerability, from 50 to 167 ms,
# runs from the 3rd tick to the 10th (combate.md, "Os golpes e as defesas", the row "Esquiva").
func test_the_invulnerability_in_ms_is_the_ticks_3_to_10_of_the_12() -> void:
	assert_int(Ticks.from_ms(DASH_MS, 60)).is_equal(DASH_TICKS)
	assert_int(Ticks.from_ms(INVULNERABLE_FROM_MS, 60)).is_equal(FIRST_INVULNERABLE_TICK)
	assert_int(Ticks.from_ms(INVULNERABLE_TO_MS, 60)).is_equal(LAST_INVULNERABLE_TICK)
	assert_int(MovementRig.load_config(60).dash_ticks).is_equal(DASH_TICKS)


# Criterion 5: a light that first touches the dasher on the 1st, 2nd, 11th or 12th tick of its dash
# lands: the contact is stamped on that tick, the dasher takes the 12 and the hitstun on the next,
# frozen 4 ticks, and the dash is cut: on the first tick the movement runs again the mode is the
# ground's, at the exit speed at most.
func test_a_light_that_touches_the_dash_on_its_ticks_1_2_11_or_12_lands_and_cuts_it(
	touched_on: int,
	_test_parameters := [[1], [2], [11], [12]],
) -> void:
	var scene := _light_scene(touched_on)
	var contact := PRESS + LIGHT_WINDUP_TICKS + THIRD_SLICE - 1
	scene.duel.run_through(PRESS + LIGHT_SWING_TICKS + LIGHT_HITSTOP_TICKS + SPARE_TICKS)
	_assert_the_dash_fired(scene)
	assert_int(_dash_tick_of(scene, contact)).is_equal(touched_on)
	assert_float(_seen_distance(scene, contact)).is_equal_approx(SEEN_AT_M, PLACE_HAIR)
	assert_int(scene.duel.contact_tick_of(ATTACKER)) \
			.override_failure_message("the blade's contact at %d, expected %d"
	% [scene.duel.contact_tick_of(ATTACKER), contact]) \
			.is_equal(contact)
	var stamped := scene.duel.row_at(contact).fought[ATTACKER]
	assert_str(String(stamped.contact_target)).is_equal(String(DASHER_NAME))
	assert_str(String(stamped.contact_move)).is_equal(String(LIGHT))
	var hit := scene.duel.row_at(contact + 1).fought[DASHER]
	var message := "tick %d: the dasher is %s, expected the hit of the contact at %d" % [
		contact + 1,
		GrabRig.line(hit),
		contact,
	]
	assert_int(hit.action).override_failure_message(message).is_equal(FighterState.Action.HITSTUN)
	assert_int(hit.hurt_tick).override_failure_message(message).is_equal(contact)
	assert_int(hit.health).override_failure_message(message).is_equal(MAX_HEALTH - LIGHT_DAMAGE)
	_assert_the_dash_was_cut(scene, contact, LIGHT_HITSTOP_TICKS)


# Criterion 5: a light whose blade touches the dasher only on invulnerable ticks, the 3rd and the
# 4th of the dash, or the 9th and the 10th, never lands: no contact is stamped, nobody freezes, the
# light ends as alone, and the dash runs whole. By the photo of the 5th active tick the dasher is
# out of the blade's way, vulnerable or not.
func test_a_light_that_touches_the_dash_only_on_its_ticks_3_to_10_passes(
	first_touched_on: int,
	_test_parameters := [[3], [9]],
) -> void:
	assert_int(first_touched_on).is_greater_equal(FIRST_INVULNERABLE_TICK)
	assert_int(first_touched_on + 1).is_less_equal(LAST_INVULNERABLE_TICK)
	var scene := _light_scene(first_touched_on)
	var third := PRESS + LIGHT_WINDUP_TICKS + THIRD_SLICE - 1
	scene.duel.run_through(PRESS + LIGHT_SWING_TICKS + SPARE_TICKS)
	_assert_the_dash_fired(scene)
	# The blade does pass over the capsule on both ticks.
	assert_float(_seen_distance(scene, third)).is_equal_approx(SEEN_AT_M, PLACE_HAIR)
	assert_float(_seen_distance(scene, third + 1)).is_equal_approx(
		SEEN_AT_M - DASH_STEP_M,
		PLACE_HAIR,
	)
	assert_int(scene.duel.contact_tick_of(ATTACKER)) \
			.override_failure_message("the blade stamped a contact at %d"
	% scene.duel.contact_tick_of(ATTACKER)) \
			.is_equal(FighterState.NEVER)
	_assert_the_dash_ran_whole(scene)
	assert_int(GrabRig.free_tick(scene.duel, ATTACKER, PRESS + 1)).is_equal(
		PRESS + LIGHT_SWING_TICKS
	)


# Criterion 5 ("a lâmina ou a mão passa sem carimbar o contato, e o golpe segue vivo nos ticks
# seguintes do ativo"; "um carregado atrasado pega o fim do dash"): the blade passes over the
# dasher on the 10th tick of its dash without a stamp, stays live, and lands on the 11th: the
# contact is stamped on that second tick, and the dash is cut.
func test_a_light_that_passes_the_10th_tick_of_the_dash_stays_live_and_lands_on_the_11th() -> void:
	var scene := _light_scene(LAST_INVULNERABLE_TICK)
	var third := PRESS + LIGHT_WINDUP_TICKS + THIRD_SLICE - 1
	var contact := third + 1
	scene.duel.run_through(PRESS + LIGHT_SWING_TICKS + LIGHT_HITSTOP_TICKS + SPARE_TICKS)
	_assert_the_dash_fired(scene)
	assert_int(_dash_tick_of(scene, third)).is_equal(LAST_INVULNERABLE_TICK)
	assert_float(_seen_distance(scene, third)).is_equal_approx(SEEN_AT_M, PLACE_HAIR)
	assert_int(scene.duel.row_at(third).fought[ATTACKER].contact_tick) \
			.override_failure_message("the blade stamped on the dash's 10th tick") \
			.is_equal(FighterState.NEVER)
	assert_int(scene.duel.row_at(contact).fought[ATTACKER].contact_tick) \
			.override_failure_message("the blade did not land on the dash's 11th tick") \
			.is_equal(contact)
	var hit := scene.duel.row_at(contact + 1).fought[DASHER]
	assert_int(hit.action).override_failure_message(GrabRig.line(hit)).is_equal(
		FighterState.Action.HITSTUN
	)
	assert_int(hit.hurt_tick).is_equal(contact)
	assert_int(hit.health).is_equal(MAX_HEALTH - LIGHT_DAMAGE)
	_assert_the_dash_was_cut(scene, contact, LIGHT_HITSTOP_TICKS)


# The grab of the contact at `contact`: the hand's stamp, the dasher GRABBED on the next tick with
# the contact in its grabbed_tick, held up to contact + 23, and the grabber GRABBING from
# contact + 2 (DEC-0058 §4).
func _assert_the_hand_grabbed(scene: Scene, contact: int) -> void:
	assert_int(scene.duel.contact_tick_of(ATTACKER)) \
			.override_failure_message("the hand's contact at %d, expected %d"
	% [scene.duel.contact_tick_of(ATTACKER), contact]) \
			.is_equal(contact)
	var held := scene.duel.row_at(contact + 1).fought[DASHER]
	var message := "tick %d: the dasher is %s, expected GRABBED by the contact at %d" % [
		contact + 1,
		GrabRig.line(held),
		contact,
	]
	assert_bool(GrabRig.is_grabbed(held)).override_failure_message(message).is_true()
	assert_int(GrabRig.grabbed_tick(held)).override_failure_message(message).is_equal(contact)
	assert_int(held.health).override_failure_message(message).is_equal(MAX_HEALTH)
	_assert_no(
		GrabRig.action_violations(
			scene.duel,
			DASHER,
			contact + 1,
			contact + RELEASE - 1,
			GrabRig.grabbed(),
		),
	)
	_assert_no(
		GrabRig.action_violations(
			scene.duel,
			ATTACKER,
			contact + 2,
			contact + RELEASE - 1,
			GrabRig.grabbing(),
		),
	)


# Criteria 2 and 5: the guard break grabs whoever is on a tick of the dash that is not
# invulnerable. The dash fires on the very tick the hand reaches a fighter standing 1,05 m along
# it: the photo still shows it standing, its own state at the end of that tick is the dash's 1st
# tick, and it is grabbed; the dash is cut.
func test_the_guard_break_grabs_a_dash_on_its_1st_tick() -> void:
	var scene := Scene.new()
	var contact := PRESS + BREAK_WINDUP_TICKS + FOURTH_SLICE - 1
	scene.dash_tick = contact
	scene.start = STANDING_FEET
	scene.dasher = Player.new(DOWN_THE_LINE)
	scene.dasher.press(contact, FighterCommand.DASH)
	scene.dasher.push_from(contact, RIGHT)
	scene.dasher.push_from(contact + 1, Vector2.ZERO)
	scene.attacker = Player.new(GrabRig.camera_for(HAND_ALONG, SHOULDER_M, HAND_CONVERGENCE_M))
	scene.attacker.press(PRESS, GUARD_BREAK)
	scene.duel.add(_rig(DASHER_NAME, STANDING_FEET, DOWN_THE_LINE), scene.dasher.input)
	scene.duel.add(_rig(ATTACKER_NAME, Vector3.ZERO, HAND_ALONG), scene.attacker.input)
	scene.duel.run_through(contact + RELEASE + SPARE_TICKS)
	_assert_the_dash_fired(scene)
	_assert_the_hand_grabbed(scene, contact)
	_assert_the_dash_was_cut(scene, contact, GRAB_HITSTOP_TICKS)


# Criteria 2 and 5: the hand that first reaches the dasher on the 2nd, 11th or 12th tick of its
# dash grabs it, and the dash is cut: frozen the 4 ticks of the grab, then the ground's mode.
func test_the_guard_break_grabs_a_dash_on_its_ticks_2_11_or_12(
	touched_on: int,
	_test_parameters := [[2], [11], [12]],
) -> void:
	var scene := _hand_scene(touched_on)
	var contact := PRESS + BREAK_WINDUP_TICKS + FIFTH_SLICE - 1
	scene.duel.run_through(contact + RELEASE + SPARE_TICKS)
	_assert_the_dash_fired(scene)
	assert_int(_dash_tick_of(scene, contact)).is_equal(touched_on)
	var seen := scene.duel.row_at(contact - 1).feet[DASHER]
	assert_float(seen.x).is_equal_approx(SEEN_AT_SIDE_M, PLACE_HAIR)
	assert_float(seen.z).is_equal_approx(-CROSSES_AT_M, PLACE_HAIR)
	_assert_the_hand_grabbed(scene, contact)
	_assert_the_dash_was_cut(scene, contact, GRAB_HITSTOP_TICKS)


# Criterion 6: a guard break whose hand reaches the dasher only on invulnerable ticks, the 3rd and
# the 4th of the dash, or the 9th and the 10th, misses: no contact, nobody GRABBED or GRABBING,
# nobody frozen, the dash runs whole, and whoever tried recovers in the 24 ticks, free on F + 51.
func test_a_guard_break_that_touches_the_dash_only_on_its_ticks_3_to_10_misses(
	first_touched_on: int,
	_test_parameters := [[3], [9]],
) -> void:
	assert_int(first_touched_on).is_greater_equal(FIRST_INVULNERABLE_TICK)
	assert_int(first_touched_on + 1).is_less_equal(LAST_INVULNERABLE_TICK)
	var scene := _hand_scene(first_touched_on)
	var fifth := PRESS + BREAK_WINDUP_TICKS + FIFTH_SLICE - 1
	scene.duel.run_through(PRESS + BREAK_SWING_TICKS + SPARE_TICKS)
	_assert_the_dash_fired(scene)
	# The hand does reach the capsule on both ticks: a sixth of a metre from its line, 1,0 m along.
	for tick: int in [fifth, fifth + 1]:
		var seen := scene.duel.row_at(tick - 1).feet[DASHER]
		assert_float(absf(seen.x)).is_less(HAND_TOUCH_M)
		assert_float(absf(seen.x)).is_equal_approx(absf(SEEN_AT_SIDE_M), PLACE_HAIR)
		assert_float(seen.z).is_equal_approx(-CROSSES_AT_M, PLACE_HAIR)
	assert_int(scene.duel.contact_tick_of(ATTACKER)) \
			.override_failure_message("the hand stamped a contact at %d"
	% scene.duel.contact_tick_of(ATTACKER)) \
			.is_equal(FighterState.NEVER)
	_assert_the_dash_ran_whole(scene)
	assert_array(GrabRig.ticks_in(scene.duel, ATTACKER, GrabRig.grabbing())).is_empty()
	var recovery_from := PRESS + BREAK_WINDUP_TICKS + BREAK_ACTIVE_TICKS
	_assert_no(
		GrabRig.action_violations(
			scene.duel,
			ATTACKER,
			recovery_from,
			recovery_from + BREAK_RECOVERY_TICKS - 1,
			FighterState.Action.RECOVERY,
		),
	)
	assert_int(GrabRig.free_tick(scene.duel, ATTACKER, PRESS + 1)).is_equal(
		PRESS + BREAK_SWING_TICKS
	)


# Criteria 5 and 6: the hand passes over the dasher on the 10th tick of its dash without a stamp,
# stays live, and grabs it on the 11th, the last active tick.
func test_a_hand_that_passes_the_10th_tick_of_the_dash_stays_live_and_grabs_on_the_11th() -> void:
	var scene := _hand_scene(LAST_INVULNERABLE_TICK)
	var fifth := PRESS + BREAK_WINDUP_TICKS + FIFTH_SLICE - 1
	var contact := fifth + 1
	scene.duel.run_through(contact + RELEASE + SPARE_TICKS)
	_assert_the_dash_fired(scene)
	assert_int(_dash_tick_of(scene, fifth)).is_equal(LAST_INVULNERABLE_TICK)
	assert_int(scene.duel.row_at(fifth).fought[ATTACKER].contact_tick) \
			.override_failure_message("the hand stamped on the dash's 10th tick") \
			.is_equal(FighterState.NEVER)
	_assert_the_hand_grabbed(scene, contact)
	_assert_the_dash_was_cut(scene, contact, GRAB_HITSTOP_TICKS)
