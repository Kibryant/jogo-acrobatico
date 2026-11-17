# Criteria 2 and 3 of TASK-12.4: the grab and the tech (glossario.md, "Quebra de guarda" and
# "Tech"; combate.md, "A quebra de guarda e o tech", "O tranco e a vantagem" and "A quebra, o tech
# e a esquiva no tick"; DEC-0058 §3 to §5), through the public interface of core/fighter, with
# GrabRigs under a Duel and a TickPhoto taken on every tick. C is the contact tick. Whoever was
# grabbed resolves it on C + 1: GRABBED, the contact in grabbed_tick, frozen from C + 1 to C + 4;
# whoever grabbed reads that stamp in the photo on C + 2: GRABBING, frozen from C + 2 to C + 5.
# Both are held, with no input, up to C + 23. Who is grabbed: whoever stands on the floor without
# striking; who is not: whoever is in the active of a move, in the hitstun of a hit taken, parried,
# in the air, on the wall, on the grapple or already held; and two guard breaks that touch on the
# same tick both miss. The tech is a press of the guard break by whoever was grabbed, after the
# contact, counted on its first tick that is not frozen, up to C + 23, for free: with it the victim
# is free on C + 24 and the grabber on C + 26; without it the grabber is free on C + 24, the victim
# acts again on C + 76, and a charged the grabber starts on C + 24 lands on C + 66, one started on
# C + 33 on C + 75, before the victim's guard, parry or dash can come out. Every number comes from
# docs/design, cited by section.
extends GdUnitTestSuite

const GrabRig := preload("res://test/core/fighter/grab_rig.gd")
const Player := preload("res://test/core/fighter/grab_player.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")
const Duel := preload("res://test/core/fighter/duel.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
const GUARD_BREAK := GrabRig.GUARD_BREAK
const LIGHT := &"light_attack" # glossario.md, "Golpe leve"
const CHARGED := &"charged_attack" # glossario.md, "Golpe carregado"
# The fighters by name, the photo's key (DEC-0051 §1), and by index in the Duel.
const VICTIM_NAME := &"A"
const GRABBER_NAME := &"B"
const THIRD_NAME := &"C"
const VICTIM := 0
const GRABBER := 1
const THIRD := 2

# combate.md, "Os golpes e as defesas", the row "Quebra de guarda": 21 / 6 / 24 ticks at 60, 15 of
# stamina; fired at F, free on F + 51 ("As fases").
const WINDUP_TICKS := 21
const ACTIVE_TICKS := 6
const SWING_TICKS := 51
const GUARD_BREAK_COST := 15.0
# combate.md, "A quebra de guarda e o tech": "No contato, os dois ficam presos 333 ms (20 ticks)";
# "O hitstop e o tremor", the row "Quebra pega: os dois, 67 ms, 4 ticks"; "O agarrão": "Os dois
# ficam presos, sem input, até C + 23, e se soltam em C + 24: os 20 ticks do agarrão mais os 4 da
# paradinha". 333 ms at 60 are 19,98 ticks, so 20, and 67 ms are 4,02, so 4.
const HOLD_MS := 333
const HOLD_TICKS := 20
const GRAB_HITSTOP_MS := 67
const GRAB_HITSTOP_TICKS := 4
const RELEASE := HOLD_TICKS + GRAB_HITSTOP_TICKS # C + 24
# "O tech": "quem agarrou lê o tech_tick na foto e se solta em C + 26, e quem respondeu fica 2
# ticks à frente"; "um aperto durante a paradinha conta em C + 5".
const TECH_ADVANTAGE := 2
const FIRST_TECH_OFFSET := 5
# "Sem o tech [...] quem foi agarrado segue no GRABBED, sem agir, até C + 75, e volta a agir em
# C + 76 (72 + 4)": 1.200 ms are 72 ticks at 60 ("O tranco e a vantagem": "Quebra sem tech").
const NO_TECH_MS := 1200
const NO_TECH_TICKS := 72
const VICTIM_FREE := NO_TECH_TICKS + GRAB_HITSTOP_TICKS # C + 76
# "O carregado que quem agarrou começa em C + 24 pega em C + 66; começado até C + 33, ainda pega
# antes de C + 76": the charged's windup is 42 ticks (combate.md, "As fases do carregado"), it
# takes 30 and stuns 42 ticks plus 7 of hitstop.
const CHARGED_WINDUP_TICKS := 42
const CHARGED_DAMAGE := 30
const LAST_GUARANTEED_START := 33
# combate.md, "Os golpes e as defesas": the light is 15 / 6 / 12 ticks and the charged 42 / 7 / 27;
# "O tranco e a vantagem": "Leve acerta: 24 ticks", "Leve bloqueado: 15 ticks", "Carregado aparado:
# 54 ticks, mais 9 ticks de hitstop"; "O hitstop e o tremor": "Leve acerta: 4", "Leve bloqueado: 2".
const LIGHT_HITSTUN_TICKS := 24
const LIGHT_HITSTOP_TICKS := 4
const LIGHT_BLOCKSTUN_TICKS := 15
const LIGHT_BLOCK_HITSTOP_TICKS := 2
# movimento.md, "Perdão": the slot keeps a press 150 ms, 9 ticks at 60, inclusive (DEC-0039).
const BUFFER_TICKS := 9
const STAMINA_MAX := 100.0 # movimento.md, "Stamina": "Máximo"
const MAX_HEALTH := 100 # partida.md, "A vida sem partida"

# movimento.md, "Câmera": the shoulder, 0,8 m; combate.md, "A lâmina e o contato": "Convergência:
# 2,0 na espada; 1,2 na quebra".
const SHOULDER_M := 0.8
const HAND_CONVERGENCE_M := 1.2
const SWORD_CONVERGENCE_M := 2.0
# The grabber stands at the origin and its hand goes down -Z. "A mão": the slice of the active tick
# k runs from 0,2 · (k - 1) to 0,2 · k m and touches within 0,35 m of the target's axis. A victim
# 1,05 m straight along the hand is first touched by the 4th slice (0,8 m, 0,25 m from the axis;
# the 3rd ends 0,45 m from it), so the contact is F + 21 + 3. One 1,5 m away is first touched by
# the 6th (1,2 m, 0,3 m from the axis; the 5th ends 0,5 m from it), F + 21 + 5, and there the
# charged's cut touches on its first active tick (combate.md, "O toque do carregado": "um alvo de
# frente a 1,5 m é tocado no primeiro tick ativo").
const HAND_ALONG := 0.0
const VICTIM_FEET := Vector3(0.0, 0.0, -1.05)
const CONTACT_ACTIVE_TICK := 4
const VICTIM_FEET_AT_1_5_M := Vector3(0.0, 0.0, -1.5)
const CONTACT_ACTIVE_TICK_AT_1_5_M := 6
# The victim looks back at the grabber (+Z, the yaw pi), or sends its own moves away from it, down
# -Z: an arc of ±60°, a vertical cut or a hand going the other way never reach the grabber behind.
const FACING_THE_GRABBER := PI
const AWAY := 0.0
# A third fighter 2,3 m beyond the victim, swinging back at it: its light's arc reaches an axis
# 2,3 m dead ahead on the third slice (combate.md, "O arco do leve"), 17 ticks after its press, and
# never the grabber, 3,35 m away. One 1,5 m beyond the victim stands where the victim's charged
# touches on its first active tick.
const THIRD_FEET_FOR_A_LIGHT := Vector3(0.0, 0.0, -3.35)
const THIRD_FEET_FOR_A_PARRY := Vector3(0.0, 0.0, -2.55)
const LIGHT_CONTACT_OFFSET := 17
# A second guard break onto somebody already held: from 1,05 m beyond the victim, back at it, or
# from 1,05 m behind the grabber, at its back; each hand ends 0,9 m short of the other fighter.
const SECOND_FEET_ON_THE_VICTIM := Vector3(0.0, 0.0, -2.1)
const SECOND_FEET_ON_THE_GRABBER := Vector3(0.0, 0.0, 1.05)
# Far from everybody, for a victim whose body is elsewhere (on a wall, on the grapple) while the
# photo of one tick, the test's own, shows it within the hand's reach (DEC-0051 §1).
const FAR := Vector3(50.0, 0.0, 0.0)
# The approach to a wall of test/core/fighter/movement_wall_test.gd: 0,9 m from the face, 10 m up,
# 2 m/s into it, falling at 6 m/s, 8 m/s along it (movimento.md, "Corrida na parede": "Velocidade
# na parede").
const WALL_APPROACH := Vector3(0.9, 10.0, 0.0)
const WALL_VELOCITY := Vector3(-2.0, -6.0, -8.0)
const WALL_ID := &"ParedeA"
# A grapple point about 21 m from the point O, within the 25 m of the reach and beyond the 3 m of
# the minimum (movimento.md, "Gancho"): the pull of 18 m/s lasts over a second.
const GRAPPLE_POINT := Vector3(0.0, 12.0, -18.0)
# movimento.md, "Pulo e ar": the jump leaves the floor at 6,69 m/s at 60 ticks, so two ticks into
# it the feet are about 0,22 m up, and the hand, at 1,3 m, still crosses the capsule's axis, which
# runs from 0,35 to 1,45 m above the feet: up to 0,95 m of height the reach is the floor's.
const HAND_STILL_REACHES_BELOW_M := 0.95

const FORWARD := Vector2(0, 1) # move.y goes forward, relative to yaw (TASK-9 plan)
const HAIR := 1e-6 # floating-point slack, not a design number
const SPARE_TICKS := 6 # ticks a run keeps going past the last event: arithmetic
# Ticks after FIRST_TICK the guard break is pressed: the victim's longest preparation, a charged
# that is in its recovery on the contact, starts 55 ticks before it. Arithmetic.
const PRESS_AFTER_START := 60
const PRESS := FIRST_TICK + PRESS_AFTER_START
const CONTACT := PRESS + WINDUP_TICKS + CONTACT_ACTIVE_TICK - 1


# The fighters of one scene and their scripts.
class Scene:
	var duel := Duel.new()
	var victim: Player
	var grabber: Player
	var third: Player


func _rig(name: StringName, feet: Vector3, yaw: float) -> GrabRig:
	return GrabRig.new(
		name,
		MovementRig.load_config(60),
		GrabRig.load_combat(60),
		FIRST_TICK,
		feet,
		yaw,
	)


func _sword_camera(direction: float) -> float:
	return GrabRig.camera_for(direction, SHOULDER_M, SWORD_CONVERGENCE_M)


func _hand_camera(direction: float) -> float:
	return GrabRig.camera_for(direction, SHOULDER_M, HAND_CONVERGENCE_M)


# The victim at victim_feet with its camera on victim_camera, index 0, and the grabber at the
# origin, its hand going down -Z, pressing the guard break on `press`, index 1.
func _scene(
	victim_camera := FACING_THE_GRABBER,
	victim_feet := VICTIM_FEET,
	press := PRESS,
) -> Scene:
	var scene := Scene.new()
	scene.victim = Player.new(victim_camera)
	scene.grabber = Player.new(_hand_camera(HAND_ALONG))
	scene.grabber.press(press, GUARD_BREAK)
	scene.duel.add(_rig(VICTIM_NAME, victim_feet, victim_camera), scene.victim.input)
	scene.duel.add(_rig(GRABBER_NAME, Vector3.ZERO, HAND_ALONG), scene.grabber.input)
	return scene


# A third fighter at feet, its camera on camera_yaw, index 2.
func _add_third(scene: Scene, feet: Vector3, camera_yaw: float) -> void:
	scene.third = Player.new(camera_yaw)
	scene.duel.add(_rig(THIRD_NAME, feet, camera_yaw), scene.third.input)


func _assert_no(violations: Array[String]) -> void:
	assert_array(violations).override_failure_message(GrabRig.brief(violations)).is_empty()


func _fought(scene: Scene, tick: int, index: int) -> FighterState:
	var row := scene.duel.row_at(tick)
	assert_object(row).override_failure_message("tick %d was not run" % tick).is_not_null()
	if row == null:
		return FighterState.new()
	return row.fought[index]


func _assert_action(scene: Scene, tick: int, index: int, action: int) -> void:
	var state := _fought(scene, tick, index)
	var message := "tick %d: fighter %d is %s, expected %s" % [
		tick,
		index,
		GrabRig.line(state),
		GrabRig.action_name(action),
	]
	assert_int(state.action).override_failure_message(message).is_equal(action)


# The grab of the contact at `contact`, by `grabber` on `victim`: the hand's one stamp on that
# tick, naming the victim and the move; the victim GRABBED on contact + 1 with the contact in its
# grabbed_tick and its health whole; the grabber not yet GRABBING on contact + 1 and GRABBING on
# contact + 2 (DEC-0058 §4).
func _assert_grab(scene: Scene, contact: int, victim := VICTIM, grabber := GRABBER) -> void:
	var stamped := _fought(scene, contact, grabber)
	var touch := "tick %d: contact (%d, %s, %s), expected (%d, %s, %s)" % [
		contact,
		stamped.contact_tick,
		stamped.contact_target,
		stamped.contact_move,
		contact,
		scene.duel.fighter(victim).fighter_name,
		GUARD_BREAK,
	]
	assert_int(stamped.contact_tick).override_failure_message(touch).is_equal(contact)
	assert_str(String(stamped.contact_target)).override_failure_message(touch).is_equal(
		String(scene.duel.fighter(victim).fighter_name)
	)
	assert_str(String(stamped.contact_move)).override_failure_message(touch).is_equal(
		String(GUARD_BREAK)
	)
	var before := _fought(scene, contact, victim)
	assert_bool(GrabRig.is_grabbed(before)) \
			.override_failure_message("the victim is GRABBED on the contact tick, too early") \
			.is_false()
	var held := _fought(scene, contact + 1, victim)
	var message := "tick %d: the victim is %s, expected GRABBED by the contact at %d" % [
		contact + 1,
		GrabRig.line(held),
		contact,
	]
	assert_bool(GrabRig.is_grabbed(held)).override_failure_message(message).is_true()
	assert_int(GrabRig.grabbed_tick(held)).override_failure_message(message).is_equal(contact)
	assert_int(held.health).override_failure_message(message).is_equal(MAX_HEALTH)
	assert_bool(GrabRig.is_grabbing(_fought(scene, contact + 1, grabber))) \
			.override_failure_message("the grabber is GRABBING before the photo shows the grab") \
			.is_false()
	var holder := _fought(scene, contact + 2, grabber)
	assert_bool(GrabRig.is_grabbing(holder)) \
			.override_failure_message("tick %d: the grabber is %s, expected GRABBING"
	% [contact + 2, GrabRig.line(holder)]) \
			.is_true()


# Nobody was grabbed in the whole run: `victim` is never GRABBED and its grabbed_tick never moves,
# `grabber` is never GRABBING, neither freezes because of a grab on a tick from `from` on, and the
# grabber's move, fired at `press`, ends on its own, free on press + 51 ("No vazio").
func _assert_no_grab(scene: Scene, press: int, victim := VICTIM, grabber := GRABBER) -> void:
	var violations: Array[String] = []
	for row: Duel.Row in scene.duel.rows:
		var target := row.fought[victim]
		if GrabRig.is_grabbed(target) or GrabRig.grabbed_tick(target) != FighterState.NEVER:
			violations.append("tick %d: the target is %s" % [row.tick, GrabRig.line(target)])
		if GrabRig.is_grabbing(row.fought[grabber]):
			violations.append("tick %d: the grabber is GRABBING" % row.tick)
		if row.plans[grabber].frozen:
			violations.append("tick %d: the grabber froze" % row.tick)
	_assert_no(violations)
	assert_int(GrabRig.free_tick(scene.duel, grabber, press + 1)).is_equal(press + SWING_TICKS)
	_assert_action(scene, press + SWING_TICKS - 1, grabber, FighterState.Action.RECOVERY)


# Criterion 2, the conversion: the hold of 333 ms is 20 ticks at 60, the hitstop of 67 ms is 4, and
# the 1.200 ms of the grab without a tech are 72 (combate.md, "A quebra de guarda e o tech"; "O
# hitstop e o tremor"); nearest tick, ties up.
func test_the_grabs_ms_are_these_ticks_at_60() -> void:
	assert_int(Ticks.from_ms(HOLD_MS, 60)).is_equal(HOLD_TICKS)
	assert_int(Ticks.from_ms(GRAB_HITSTOP_MS, 60)).is_equal(GRAB_HITSTOP_TICKS)
	assert_int(Ticks.from_ms(NO_TECH_MS, 60)).is_equal(NO_TECH_TICKS)
	assert_int(RELEASE).is_equal(24)
	assert_int(VICTIM_FREE).is_equal(76)


# Criterion 2: the guard break that touches a fighter standing still holds both for 20 ticks plus
# the 4 of the hitstop. The victim resolves it on C + 1 and is frozen from C + 1 to C + 4; the
# grabber reads it on C + 2 and is frozen from C + 2 to C + 5; both are held up to C + 23; on
# C + 24 the grabber is free. The guard break takes no health and costs the victim nothing.
func test_a_grab_holds_both_for_20_ticks_plus_the_4_of_the_hitstop() -> void:
	var scene := _scene()
	scene.duel.run_through(CONTACT + RELEASE + SPARE_TICKS)
	assert_int(scene.duel.contact_tick_of(GRABBER)).is_equal(CONTACT)
	_assert_grab(scene, CONTACT)
	_assert_no(
		GrabRig.action_violations(
			scene.duel,
			VICTIM,
			CONTACT + 1,
			CONTACT + RELEASE - 1,
			GrabRig.grabbed(),
		),
	)
	_assert_no(
		GrabRig.action_violations(
			scene.duel,
			GRABBER,
			CONTACT + 2,
			CONTACT + RELEASE - 1,
			GrabRig.grabbing(),
		),
	)
	_assert_action(scene, CONTACT + RELEASE, GRABBER, FighterState.Action.NONE)
	var last := CONTACT + RELEASE + SPARE_TICKS
	_assert_no(
		GrabRig.frozen_violations(
			scene.duel,
			VICTIM,
			CONTACT + 1,
			CONTACT + GRAB_HITSTOP_TICKS,
			last,
		),
	)
	_assert_no(
		GrabRig.frozen_violations(
			scene.duel,
			GRABBER,
			CONTACT + 2,
			CONTACT + 1 + GRAB_HITSTOP_TICKS,
			last,
		),
	)
	var violations: Array[String] = []
	for row: Duel.Row in scene.duel.rows:
		for index: int in 2:
			if row.fought[index].health != MAX_HEALTH:
				violations.append("tick %d: fighter %d lost health" % [row.tick, index])
		if row.fought[VICTIM].stamina_spent_tick != FighterState.NEVER:
			violations.append("tick %d: the victim paid stamina" % row.tick)
		if GrabRig.grabbed_tick(row.fought[GRABBER]) != FighterState.NEVER:
			violations.append("tick %d: the grabber carries a grabbed_tick" % row.tick)
		if GrabRig.tech_tick(row.fought[VICTIM]) != FighterState.NEVER:
			violations.append("tick %d: a tech nobody pressed" % row.tick)
	_assert_no(violations)


# Criterion 2, "sem input" ("O corpo preso": "os comandos esperam na vaga [...] O corpo não anda"):
# held, the stick moves nobody, and a jump and a light pressed early in the hold never come out:
# their window closes before the release. The victim, without a tech, stays so up to C + 75 and
# walks again on C + 76.
func test_while_held_the_stick_moves_nobody_and_no_command_comes_out() -> void:
	var scene := _scene()
	scene.victim.push_from(CONTACT + 1, FORWARD)
	scene.victim.press(CONTACT + 6, FighterCommand.JUMP)
	scene.victim.press(CONTACT + 8, FighterCommand.LIGHT_ATTACK)
	scene.grabber.push_from(CONTACT + 2, FORWARD)
	scene.grabber.press(CONTACT + 6, FighterCommand.JUMP)
	scene.grabber.press(CONTACT + 8, FighterCommand.LIGHT_ATTACK)
	scene.grabber.push_from(CONTACT + RELEASE, Vector2.ZERO)
	scene.duel.run_through(CONTACT + VICTIM_FREE + SPARE_TICKS)
	_assert_grab(scene, CONTACT)
	var victim_at := scene.duel.row_at(CONTACT).feet[VICTIM]
	var grabber_at := scene.duel.row_at(CONTACT + 1).feet[GRABBER]
	var violations: Array[String] = []
	for row: Duel.Row in scene.duel.rows:
		if row.tick > CONTACT and row.tick < CONTACT + VICTIM_FREE:
			if row.feet[VICTIM].distance_to(victim_at) > HAIR:
				violations.append("tick %d: the victim moved to %s" % [row.tick, row.feet[VICTIM]])
			if not GrabRig.is_grabbed(row.fought[VICTIM]):
				violations.append(
					"tick %d: the victim is %s" % [row.tick, GrabRig.line(row.fought[VICTIM])]
				)
			if row.ends[VICTIM].jumps_used != 0 or not row.ends[VICTIM].on_floor:
				violations.append("tick %d: the victim jumped" % row.tick)
		if row.tick > CONTACT + 1 and row.tick < CONTACT + RELEASE:
			if row.feet[GRABBER].distance_to(grabber_at) > HAIR:
				violations.append(
					"tick %d: the grabber moved to %s" % [row.tick, row.feet[GRABBER]]
				)
			if row.ends[GRABBER].jumps_used != 0 or not row.ends[GRABBER].on_floor:
				violations.append("tick %d: the grabber jumped" % row.tick)
	_assert_no(violations)
	# The presses of C + 6 and C + 8 were dropped when their windows closed: nothing fires at the
	# release.
	_assert_action(scene, CONTACT + RELEASE, GRABBER, FighterState.Action.NONE)
	_assert_action(scene, CONTACT + VICTIM_FREE, VICTIM, FighterState.Action.NONE)
	var walked := scene.duel.row_at(CONTACT + VICTIM_FREE).feet[VICTIM]
	assert_float(walked.distance_to(victim_at)) \
			.override_failure_message("the victim does not walk again on C + 76") \
			.is_greater(HAIR)


# Criterion 2 ("os comandos esperam na vaga"): a light the grabber presses 4 ticks before the
# release waits in the slot and fires on the release tick, C + 24; the old state is read on its
# last tick, C + 23 (F-195).
func test_a_command_pressed_late_in_the_hold_waits_and_fires_at_the_release() -> void:
	var scene := _scene()
	var pressed := CONTACT + RELEASE - 4
	scene.grabber.press(pressed, FighterCommand.LIGHT_ATTACK)
	scene.duel.run_through(CONTACT + RELEASE + SPARE_TICKS)
	_assert_grab(scene, CONTACT)
	for tick: int in range(pressed, CONTACT + RELEASE):
		var waiting := _fought(scene, tick, GRABBER)
		assert_bool(GrabRig.is_grabbing(waiting)) \
				.override_failure_message("tick %d: %s" % [tick, GrabRig.line(waiting)]) \
				.is_true()
		assert_str(String(waiting.buffered_command)).is_equal(String(FighterCommand.LIGHT_ATTACK))
		assert_int(waiting.buffered_tick).is_equal(pressed)
	var fired := _fought(scene, CONTACT + RELEASE, GRABBER)
	assert_int(fired.action).override_failure_message(GrabRig.line(fired)).is_equal(
		FighterState.Action.WINDUP
	)
	assert_int(fired.action_since).is_equal(CONTACT + RELEASE)
	assert_str(String(fired.action_move)).is_equal(String(LIGHT))


# What the victim does before the contact, by case, and its camera; returns the action its combat
# state must show on the contact tick.
func _prepare(case: String, victim: Player) -> int:
	match case:
		"walking":
			# One tick of walking toward the grabber before the contact: 1,3 cm nearer.
			victim.push_from(CONTACT - 1, FORWARD)
			return FighterState.Action.NONE
		"blocking":
			victim.guard_from(FIRST_TICK, true)
			return FighterState.Action.BLOCK
		"parry stance":
			victim.press(CONTACT - 3, FighterCommand.PARRY)
			return FighterState.Action.PARRY
		"light windup":
			victim.press(CONTACT - 5, FighterCommand.LIGHT_ATTACK)
			return FighterState.Action.WINDUP
		"charged windup":
			victim.press(CONTACT - 20, FighterCommand.CHARGED_ATTACK)
			return FighterState.Action.WINDUP
		"guard break windup":
			victim.press(CONTACT - 5, GUARD_BREAK)
			return FighterState.Action.WINDUP
		"light recovery":
			# Fired at C - 25: active from C - 10 to C - 5, in recovery from C - 4 to C + 7.
			victim.press(CONTACT - 25, FighterCommand.LIGHT_ATTACK)
			return FighterState.Action.RECOVERY
		"charged recovery":
			# Fired at C - 55: active from C - 13 to C - 7, in recovery from C - 6 to C + 20.
			victim.press(CONTACT - 55, FighterCommand.CHARGED_ATTACK)
			return FighterState.Action.RECOVERY
		"guard break recovery":
			# Fired at C - 30: active from C - 9 to C - 4, in recovery from C - 3 to C + 20.
			victim.press(CONTACT - 30, GUARD_BREAK)
			return FighterState.Action.RECOVERY
		"feint":
			# The charged at C - 8 and the guard button 5 ticks into its windup: FEINT for 12 ticks,
			# from C - 3 to C + 8 (combate.md, "A finta").
			victim.press(CONTACT - 8, FighterCommand.CHARGED_ATTACK)
			victim.press(CONTACT - 3, GrabRig.GUARD_PRESS)
			return FighterState.Action.FEINT
		"light active":
			# Fired at C - 17: active from C - 2 to C + 3.
			victim.press(CONTACT - 17, FighterCommand.LIGHT_ATTACK)
			return FighterState.Action.ACTIVE
		"charged active":
			# Fired at C - 45: active from C - 3 to C + 3.
			victim.press(CONTACT - 45, FighterCommand.CHARGED_ATTACK)
			return FighterState.Action.ACTIVE
		"guard break active":
			# Fired at C - 23: active from C - 2 to C + 3.
			victim.press(CONTACT - 23, GUARD_BREAK)
			return FighterState.Action.ACTIVE
	fail("unknown case %s" % case)
	return FighterState.Action.NONE


# The victim's camera for a case: its own moves go down -Z, away from the grabber.
func _camera_of(case: String) -> float:
	if case.begins_with("guard break"):
		return _hand_camera(AWAY)
	if case.begins_with("light") or case.begins_with("charged") or case == "feint":
		return _sword_camera(AWAY)
	return FACING_THE_GRABBER


# Criterion 2: the guard break grabs whoever stands on the floor without striking (DEC-0058 §3;
# "Quem a quebra agarra"): walking, blocking, in the parry's stance, in the windup or the recovery
# of a move (the light, the charged or the guard break), and in the feint. The victim's combat
# state on the contact tick shows the case; on C + 1 it is GRABBED, whatever it was doing is over,
# and the guard and the stance stamped nothing.
func test_the_guard_break_grabs_whoever_stands_on_the_floor_without_striking(
	case: String,
	_test_parameters := [
		["walking"],
		["blocking"],
		["parry stance"],
		["light windup"],
		["charged windup"],
		["guard break windup"],
		["light recovery"],
		["charged recovery"],
		["guard break recovery"],
		["feint"],
	],
) -> void:
	var scene := _scene(_camera_of(case))
	var expected := _prepare(case, scene.victim)
	scene.duel.run_through(CONTACT + RELEASE + SPARE_TICKS)
	_assert_action(scene, CONTACT, VICTIM, expected)
	if case == "walking":
		var speed := scene.duel.row_at(CONTACT).velocities[VICTIM].length()
		assert_float(speed).override_failure_message("the victim is not walking").is_greater(HAIR)
	_assert_grab(scene, CONTACT)
	_assert_no(
		GrabRig.action_violations(
			scene.duel,
			VICTIM,
			CONTACT + 1,
			CONTACT + RELEASE - 1,
			GrabRig.grabbed(),
		),
	)
	_assert_no(
		GrabRig.action_violations(
			scene.duel,
			GRABBER,
			CONTACT + 2,
			CONTACT + RELEASE - 1,
			GrabRig.grabbing(),
		),
	)
	var after := _fought(scene, CONTACT + 1, VICTIM)
	assert_int(after.block_tick).override_failure_message("the guard blocked the guard break") \
			.is_equal(FighterState.NEVER)
	assert_int(after.parry_tick).override_failure_message("the stance parried the guard break") \
			.is_equal(FighterState.NEVER)
	assert_int(after.hurt_tick).is_equal(FighterState.NEVER)
	assert_int(scene.duel.row_at(CONTACT + RELEASE).fought[GRABBER].health).is_equal(MAX_HEALTH)


# Criterion 2: the guard break grabs a target in the blockstun. A third fighter's light lands on
# the victim's raised guard 6 ticks before the contact: blocked, 15 ticks of blockstun plus 2 of
# hitstop, so the victim is in the blockstun, past its freeze, when the hand touches.
func test_the_guard_break_grabs_a_target_in_the_blockstun() -> void:
	var scene := _scene(AWAY)
	scene.victim.guard_from(FIRST_TICK, true)
	_add_third(scene, THIRD_FEET_FOR_A_LIGHT, _sword_camera(FACING_THE_GRABBER))
	var light_contact := CONTACT - 6
	scene.third.press(light_contact - LIGHT_CONTACT_OFFSET, FighterCommand.LIGHT_ATTACK)
	scene.duel.run_through(CONTACT + RELEASE + SPARE_TICKS)
	assert_int(_fought(scene, light_contact, THIRD).contact_tick).is_equal(light_contact)
	assert_int(_fought(scene, light_contact + 1, VICTIM).block_tick).is_equal(light_contact)
	assert_int(light_contact + LIGHT_BLOCKSTUN_TICKS + LIGHT_BLOCK_HITSTOP_TICKS).is_greater(
		CONTACT
	)
	_assert_action(scene, CONTACT, VICTIM, FighterState.Action.BLOCKSTUN)
	_assert_grab(scene, CONTACT)
	_assert_no(
		GrabRig.action_violations(
			scene.duel,
			VICTIM,
			CONTACT + 1,
			CONTACT + RELEASE - 1,
			GrabRig.grabbed(),
		),
	)


# Criterion 2: the guard break does not grab whoever is in the active of a move ("Não agarra quem
# está no ativo de um golpe"). The hand touches, and stamps its one contact, but the victim's own
# state on the contact tick is the active: it is not GRABBED, its move goes on, nobody freezes, and
# the guard break recovers on its own.
func test_the_guard_break_does_not_grab_a_target_in_the_active_of_a_move(
	case: String,
	move: StringName,
	_test_parameters := [
		["light active", LIGHT],
		["charged active", CHARGED],
		["guard break active", GUARD_BREAK],
	],
) -> void:
	var scene := _scene(_camera_of(case))
	var expected := _prepare(case, scene.victim)
	scene.duel.run_through(PRESS + SWING_TICKS + SPARE_TICKS)
	_assert_action(scene, CONTACT, VICTIM, expected)
	var stamped := _fought(scene, CONTACT, GRABBER)
	assert_int(stamped.contact_tick).override_failure_message("the hand did not touch").is_equal(
		CONTACT
	)
	assert_str(String(stamped.contact_target)).is_equal(String(VICTIM_NAME))
	_assert_no_grab(scene, PRESS)
	var after := _fought(scene, CONTACT + 1, VICTIM)
	assert_int(after.action).override_failure_message(GrabRig.line(after)).is_equal(
		FighterState.Action.ACTIVE
	)
	assert_str(String(after.action_move)).is_equal(String(move))
	var violations: Array[String] = []
	for row: Duel.Row in scene.duel.rows:
		if row.plans[VICTIM].frozen:
			violations.append("tick %d: the victim froze" % row.tick)
	_assert_no(violations)


# Criterion 2: the guard break does not grab whoever is in the hitstun of a hit taken ("Sem o
# tranco de golpe levado na lista, não existe laço de quebra, carregado e quebra de novo"). A third
# fighter's light lands 6 ticks before the hand touches: the victim is in the hitstun of 24 ticks
# plus 4, stays in it, and acts again when it ends, as without the guard break.
func test_the_guard_break_does_not_grab_a_target_in_the_hitstun_of_a_hit_taken() -> void:
	var scene := _scene(FACING_THE_GRABBER)
	_add_third(scene, THIRD_FEET_FOR_A_LIGHT, _sword_camera(FACING_THE_GRABBER))
	var light_contact := CONTACT - 6
	var stun_ends := light_contact + LIGHT_HITSTUN_TICKS + LIGHT_HITSTOP_TICKS
	scene.third.press(light_contact - LIGHT_CONTACT_OFFSET, FighterCommand.LIGHT_ATTACK)
	scene.duel.run_through(PRESS + SWING_TICKS + SPARE_TICKS)
	assert_int(_fought(scene, light_contact + 1, VICTIM).hurt_tick).is_equal(light_contact)
	_assert_action(scene, CONTACT, VICTIM, FighterState.Action.HITSTUN)
	_assert_no_grab(scene, PRESS)
	_assert_no(
		GrabRig.action_violations(
			scene.duel,
			VICTIM,
			light_contact + 1,
			stun_ends - 1,
			FighterState.Action.HITSTUN,
		),
	)
	assert_int(GrabRig.free_tick(scene.duel, VICTIM, light_contact + 1)).is_equal(stun_ends)


# Criterion 2: the guard break does not grab whoever was parried. The victim's charged touches a
# third fighter, 1,5 m ahead of it, on its first active tick, and the third fighter's parry, pressed
# 3 ticks before, parries it: the victim is PARRIED from that contact + 2 to + 62, and the hand
# touches it 15 ticks after that contact.
func test_the_guard_break_does_not_grab_a_parried_target() -> void:
	var scene := _scene(_sword_camera(AWAY))
	_add_third(scene, THIRD_FEET_FOR_A_PARRY, FACING_THE_GRABBER)
	var charged_contact := CONTACT - 15
	scene.victim.press(charged_contact - CHARGED_WINDUP_TICKS, FighterCommand.CHARGED_ATTACK)
	scene.third.press(charged_contact - 3, FighterCommand.PARRY)
	scene.duel.run_through(PRESS + SWING_TICKS + SPARE_TICKS)
	assert_int(_fought(scene, charged_contact + 1, THIRD).parry_tick).is_equal(charged_contact)
	_assert_action(scene, CONTACT, VICTIM, FighterState.Action.PARRIED)
	_assert_no_grab(scene, PRESS)
	_assert_action(scene, CONTACT + 1, VICTIM, FighterState.Action.PARRIED)


# Criterion 2: the guard break does not grab whoever is in the air. The victim jumps two ticks
# before the hand reaches it: its feet are some 0,2 m up, the hand still crosses its capsule, and
# its own state on the contact tick is the air.
func test_the_guard_break_does_not_grab_a_target_in_the_air() -> void:
	var scene := _scene()
	scene.victim.press(CONTACT - 2, FighterCommand.JUMP)
	scene.duel.run_through(PRESS + SWING_TICKS + SPARE_TICKS)
	var seen := scene.duel.row_at(CONTACT - 1)
	assert_float(seen.feet[VICTIM].y).is_greater(0.0)
	assert_float(seen.feet[VICTIM].y).is_less(HAND_STILL_REACHES_BELOW_M)
	assert_int(scene.duel.row_at(CONTACT).ends[VICTIM].mode).is_equal(FighterState.Mode.AIR)
	_assert_no_grab(scene, PRESS)


# The photo of one tick as the test gives it: every fighter as it is, but the victim's feet at
# `feet` (DEC-0051 §1: a fighter reads the others only in the photo).
func _photo_with_the_victim_at(scene: Scene, feet: Vector3) -> TickPhoto:
	var photo := TickPhoto.new()
	var victim := scene.duel.fighter(VICTIM)
	photo.add(victim.fighter_name, feet, victim.state().copy())
	scene.duel.fighter(GRABBER).snapshot(photo)
	return photo


# Runs until the victim's movement is in `mode`, then has the grabber press on the next tick and
# shows it, on the tick of its 4th slice, a photo with the victim 1,05 m along the hand. Returns
# the press tick.
func _break_at_a_victim_elsewhere(scene: Scene, mode: FighterState.Mode) -> int:
	for _step: int in 120:
		scene.duel.step()
		if scene.duel.fighter(VICTIM).state().mode == mode:
			break
	assert_int(scene.duel.fighter(VICTIM).state().mode) \
			.override_failure_message("the victim never reached the mode %d" % mode) \
			.is_equal(mode)
	var press := scene.duel.tick() + 1
	var touch := press + WINDUP_TICKS + CONTACT_ACTIVE_TICK - 1
	scene.grabber.press(press, GUARD_BREAK)
	scene.duel.run_through(touch - 1)
	scene.duel.stage_photo(_photo_with_the_victim_at(scene, VICTIM_FEET))
	scene.duel.run_through(press + SWING_TICKS + SPARE_TICKS)
	return press


# The control of the two tests below: a victim standing still far away, shown by the photo of one
# tick within the hand's reach, is grabbed. The staged photo does make the hand touch.
func test_a_standing_target_the_photo_shows_within_reach_is_grabbed() -> void:
	var scene := _scene(FACING_THE_GRABBER, FAR, FighterState.NEVER)
	var press := _break_at_a_victim_elsewhere(scene, FighterState.Mode.GROUND)
	_assert_grab(scene, press + WINDUP_TICKS + CONTACT_ACTIVE_TICK - 1)


# Criterion 2: the guard break does not grab whoever is on the wall. The victim runs on a wall far
# away; the photo of one tick shows it within the hand's reach, and its own state is the wall run.
func test_the_guard_break_does_not_grab_a_target_on_the_wall() -> void:
	var scene := _scene(FACING_THE_GRABBER, FAR, FighterState.NEVER)
	var body := scene.duel.fighter(VICTIM).rig
	body.floor_on = false
	body.add_wall(Vector3.RIGHT, FAR.x, WALL_ID)
	body.airborne(FAR + WALL_APPROACH, WALL_VELOCITY)
	var press := _break_at_a_victim_elsewhere(scene, FighterState.Mode.WALL_RUN)
	var touch := press + WINDUP_TICKS + CONTACT_ACTIVE_TICK - 1
	assert_int(scene.duel.row_at(touch).ends[VICTIM].mode).is_equal(FighterState.Mode.WALL_RUN)
	_assert_no_grab(scene, press)


# Criterion 2: the guard break does not grab whoever is on the grapple. The victim is being pulled
# far away; the photo of one tick shows it within the hand's reach, and its own state is the pull.
func test_the_guard_break_does_not_grab_a_target_on_the_grapple() -> void:
	# The victim's camera looks down -Z, where the point is, as a player would aim it.
	var scene := _scene(AWAY, FAR, FighterState.NEVER)
	var body := scene.duel.fighter(VICTIM).rig
	body.aim_hit = true
	body.aim_point = FAR + GRAPPLE_POINT
	scene.victim.press(FIRST_TICK + 1, FighterCommand.GRAPPLE)
	var press := _break_at_a_victim_elsewhere(scene, FighterState.Mode.GRAPPLE)
	var touch := press + WINDUP_TICKS + CONTACT_ACTIVE_TICK - 1
	assert_int(scene.duel.row_at(touch).ends[VICTIM].mode).is_equal(FighterState.Mode.GRAPPLE)
	_assert_no_grab(scene, press)


# Criterion 2: the guard break does not grab whoever is already held, GRABBING or GRABBED. A third
# fighter's hand touches the victim 10 ticks after the first contact, while both are held, or 40
# ticks after it, when the victim is still GRABBED after the release, or touches the grabber's back
# while it holds: nobody is grabbed again, the first grab's clock does not move, and the second
# guard break recovers on its own.
func test_the_guard_break_does_not_grab_a_fighter_already_held(
	touched: int,
	ticks_after_the_first_contact: int,
	_test_parameters := [[VICTIM, 10], [VICTIM, 40], [GRABBER, 10]],
) -> void:
	var scene := _scene()
	var second_contact := CONTACT + ticks_after_the_first_contact
	var second_press := second_contact - WINDUP_TICKS - CONTACT_ACTIVE_TICK + 1
	if touched == VICTIM:
		_add_third(scene, SECOND_FEET_ON_THE_VICTIM, _hand_camera(FACING_THE_GRABBER))
	else:
		_add_third(scene, SECOND_FEET_ON_THE_GRABBER, _hand_camera(HAND_ALONG))
	scene.third.press(second_press, GUARD_BREAK)
	scene.duel.run_through(CONTACT + VICTIM_FREE + SPARE_TICKS)
	_assert_grab(scene, CONTACT)
	var held := _fought(scene, second_contact, touched)
	assert_bool(GrabRig.is_grabbed(held) or GrabRig.is_grabbing(held)) \
			.override_failure_message("tick %d: the touched fighter is %s, expected held"
	% [second_contact, GrabRig.line(held)]) \
			.is_true()
	var violations: Array[String] = []
	for row: Duel.Row in scene.duel.rows:
		if row.tick > CONTACT and GrabRig.grabbed_tick(row.fought[VICTIM]) != CONTACT:
			violations.append(
				"tick %d: the victim's grabbed_tick is %d"
				% [row.tick, GrabRig.grabbed_tick(row.fought[VICTIM])]
			)
		if GrabRig.grabbed_tick(row.fought[GRABBER]) != FighterState.NEVER:
			violations.append("tick %d: the grabber was grabbed" % row.tick)
		if GrabRig.is_grabbing(row.fought[THIRD]) or row.plans[THIRD].frozen:
			violations.append("tick %d: the third fighter grabbed" % row.tick)
	_assert_no(violations)
	var last := CONTACT + VICTIM_FREE + SPARE_TICKS
	_assert_no(
		GrabRig.frozen_violations(
			scene.duel,
			VICTIM,
			CONTACT + 1,
			CONTACT + GRAB_HITSTOP_TICKS,
			last,
		),
	)
	assert_int(GrabRig.free_tick(scene.duel, GRABBER, CONTACT + 2)).is_equal(CONTACT + RELEASE)
	assert_int(GrabRig.free_tick(scene.duel, VICTIM, CONTACT + 1)).is_equal(CONTACT + VICTIM_FREE)
	assert_int(GrabRig.free_tick(scene.duel, THIRD, second_press + 1)).is_equal(
		second_press + SWING_TICKS
	)


# Criterion 2, many: two guard breaks that touch on the same tick both miss ("cada uma acha a outra
# no ativo"): both stamp their contact, nobody is GRABBED or GRABBING, nobody freezes, and both
# recover on their own.
func test_two_guard_breaks_that_touch_on_the_same_tick_both_miss() -> void:
	var scene := _scene(_hand_camera(FACING_THE_GRABBER))
	scene.victim.press(PRESS, GUARD_BREAK)
	scene.duel.run_through(PRESS + SWING_TICKS + SPARE_TICKS)
	for index: int in 2:
		assert_int(_fought(scene, CONTACT, index).contact_tick) \
				.override_failure_message("hand %d did not touch on %d" % [index, CONTACT]) \
				.is_equal(CONTACT)
		_assert_action(scene, CONTACT, index, FighterState.Action.ACTIVE)
	_assert_no_grab(scene, PRESS, VICTIM, GRABBER)
	_assert_no_grab(scene, PRESS, GRABBER, VICTIM)


# Criterion 3: a press of the guard break by whoever was grabbed, after the contact and up to the
# last held tick, C + 23, is the tech: it counts on the first tick the victim is not frozen, so a
# press during the hitstop, C + 1 to C + 4, counts on C + 5, and the tech_tick takes that tick. The
# victim is free on C + 24 and the grabber on C + 26: whoever answered is 2 ticks ahead.
func test_a_tech_pressed_after_the_contact_frees_both_and_puts_the_victim_2_ticks_ahead(
	pressed_after: int,
	counted_after: int,
	_test_parameters := [[1, 5], [4, 5], [5, 5], [10, 10], [23, 23]],
) -> void:
	assert_int(counted_after).is_equal(maxi(pressed_after, FIRST_TECH_OFFSET))
	var scene := _scene()
	scene.victim.press(CONTACT + pressed_after, GUARD_BREAK)
	scene.duel.run_through(CONTACT + RELEASE + TECH_ADVANTAGE + SPARE_TICKS)
	_assert_grab(scene, CONTACT)
	var counted := CONTACT + counted_after
	var violations: Array[String] = []
	for row: Duel.Row in scene.duel.rows:
		var tech := GrabRig.tech_tick(row.fought[VICTIM])
		var expected := counted if row.tick >= counted else FighterState.NEVER
		if tech != expected:
			violations.append("tick %d: tech_tick %d, expected %d" % [row.tick, tech, expected])
		if GrabRig.tech_tick(row.fought[GRABBER]) != FighterState.NEVER:
			violations.append("tick %d: the grabber carries a tech_tick" % row.tick)
		# The tech is no guard break of the victim's own, and it is free.
		if row.fought[VICTIM].action == FighterState.Action.WINDUP:
			violations.append("tick %d: the victim began a move" % row.tick)
		if row.fought[VICTIM].stamina_spent_tick != FighterState.NEVER:
			violations.append("tick %d: the tech cost stamina" % row.tick)
	_assert_no(violations)
	_assert_no(
		GrabRig.action_violations(
			scene.duel,
			VICTIM,
			CONTACT + 1,
			CONTACT + RELEASE - 1,
			GrabRig.grabbed(),
		),
	)
	_assert_no(
		GrabRig.action_violations(
			scene.duel,
			GRABBER,
			CONTACT + 2,
			CONTACT + RELEASE + TECH_ADVANTAGE - 1,
			GrabRig.grabbing(),
		),
	)
	var victim_free := GrabRig.free_tick(scene.duel, VICTIM, CONTACT + 1)
	var grabber_free := GrabRig.free_tick(scene.duel, GRABBER, CONTACT + 2)
	assert_int(victim_free).is_equal(CONTACT + RELEASE)
	assert_int(grabber_free).is_equal(CONTACT + RELEASE + TECH_ADVANTAGE)
	assert_int(grabber_free - victim_free).is_equal(TECH_ADVANTAGE)
	var last := CONTACT + RELEASE + TECH_ADVANTAGE + SPARE_TICKS
	_assert_no(
		GrabRig.frozen_violations(
			scene.duel,
			VICTIM,
			CONTACT + 1,
			CONTACT + GRAB_HITSTOP_TICKS,
			last,
		),
	)
	_assert_no(
		GrabRig.frozen_violations(
			scene.duel,
			GRABBER,
			CONTACT + 2,
			CONTACT + 1 + GRAB_HITSTOP_TICKS,
			last,
		),
	)


# Criterion 3 ("o tech não custa stamina"; DEC-0058, "Opções consideradas": "quem está sem stamina
# não fica sem defesa"): with an empty bar the tech still counts, and the bar is not touched.
func test_a_tech_costs_no_stamina_and_counts_with_an_empty_bar() -> void:
	var scene := _scene()
	scene.victim.press(CONTACT + 10, GUARD_BREAK)
	scene.duel.run_through(CONTACT - 1)
	var victim := scene.duel.fighter(VICTIM)
	victim.state().stamina_at_spend = 0.0
	victim.state().stamina_spent_tick = CONTACT - 1
	scene.duel.run_through(CONTACT + RELEASE + SPARE_TICKS)
	_assert_grab(scene, CONTACT)
	var teched := _fought(scene, CONTACT + 10, VICTIM)
	assert_float(Stamina.at(teched, victim.config(), CONTACT + 10)).is_equal_approx(0.0, HAIR)
	assert_int(GrabRig.tech_tick(teched)).is_equal(CONTACT + 10)
	assert_int(teched.stamina_spent_tick).is_equal(CONTACT - 1)
	assert_int(GrabRig.free_tick(scene.duel, VICTIM, CONTACT + 1)).is_equal(CONTACT + RELEASE)
	assert_int(GrabRig.free_tick(scene.duel, GRABBER, CONTACT + 2)).is_equal(
		CONTACT + RELEASE + TECH_ADVANTAGE
	)


# Criterion 3: without a tech the grabber is free on C + 24 and the victim stays GRABBED, unable to
# act, up to C + 75, and acts again on C + 76: the 72 ticks of the 1.200 ms plus the 4 of the
# hitstop.
func test_without_a_tech_the_victim_acts_again_at_contact_plus_76() -> void:
	var scene := _scene()
	scene.duel.run_through(CONTACT + VICTIM_FREE + SPARE_TICKS)
	_assert_grab(scene, CONTACT)
	_assert_no(
		GrabRig.action_violations(
			scene.duel,
			VICTIM,
			CONTACT + 1,
			CONTACT + VICTIM_FREE - 1,
			GrabRig.grabbed(),
		),
	)
	assert_int(GrabRig.free_tick(scene.duel, VICTIM, CONTACT + 1)).is_equal(CONTACT + VICTIM_FREE)
	assert_int(GrabRig.free_tick(scene.duel, GRABBER, CONTACT + 2)).is_equal(CONTACT + RELEASE)
	var violations: Array[String] = []
	for row: Duel.Row in scene.duel.rows:
		if GrabRig.tech_tick(row.fought[VICTIM]) != FighterState.NEVER:
			violations.append("tick %d: a tech nobody pressed" % row.tick)
	_assert_no(violations)
	# The victim freezes for the 4 ticks of the hitstop only: the wait is no freeze.
	_assert_no(
		GrabRig.frozen_violations(
			scene.duel,
			VICTIM,
			CONTACT + 1,
			CONTACT + GRAB_HITSTOP_TICKS,
			CONTACT + VICTIM_FREE + SPARE_TICKS,
		),
	)


# Criterion 3: a press of before the contact is no tech ("Um aperto de antes do contato não conta";
# "feito de C + 1 a C + 23"). With a full bar the press fires the victim's own guard break, whose
# windup the hand grabs; with an empty bar it waits in the slot, still inside its 150 ms when the
# victim's freeze ends, and must not count either. Pressed one tick before the contact or on the
# contact tick itself.
func test_a_tech_pressed_before_the_contact_does_not_count(
	pressed_before: int,
	bar_is_empty: bool,
	_test_parameters := [[1, false], [0, false], [1, true], [0, true]],
) -> void:
	var scene := _scene(_hand_camera(AWAY))
	var pressed := CONTACT - pressed_before
	scene.victim.press(pressed, GUARD_BREAK)
	scene.duel.run_through(pressed - 2)
	if bar_is_empty:
		var victim := scene.duel.fighter(VICTIM)
		victim.state().stamina_at_spend = 0.0
		victim.state().stamina_spent_tick = pressed - 2
	scene.duel.run_through(CONTACT + VICTIM_FREE + SPARE_TICKS)
	var on_press := _fought(scene, pressed, VICTIM)
	if bar_is_empty:
		assert_str(String(on_press.buffered_command)) \
				.override_failure_message("the press is not waiting in the slot: %s"
		% GrabRig.line(on_press)) \
				.is_equal(String(GUARD_BREAK))
		assert_int(CONTACT + FIRST_TECH_OFFSET - pressed).is_less_equal(BUFFER_TICKS)
	else:
		assert_int(on_press.action).override_failure_message(GrabRig.line(on_press)).is_equal(
			FighterState.Action.WINDUP
		)
	_assert_grab(scene, CONTACT)
	var violations: Array[String] = []
	for row: Duel.Row in scene.duel.rows:
		if GrabRig.tech_tick(row.fought[VICTIM]) != FighterState.NEVER:
			violations.append(
				"tick %d: tech_tick %d" % [row.tick, GrabRig.tech_tick(row.fought[VICTIM])]
			)
	_assert_no(violations)
	assert_int(GrabRig.free_tick(scene.duel, GRABBER, CONTACT + 2)).is_equal(CONTACT + RELEASE)
	assert_int(GrabRig.free_tick(scene.duel, VICTIM, CONTACT + 1)).is_equal(CONTACT + VICTIM_FREE)


# Criterion 3, the limit: C + 23 is the last held tick. A press on C + 24 is no tech: the victim
# stays GRABBED up to C + 75, and the press, whose window closes long before, fires nothing.
func test_a_press_after_the_last_held_tick_is_not_a_tech() -> void:
	var scene := _scene()
	scene.victim.press(CONTACT + RELEASE, GUARD_BREAK)
	scene.duel.run_through(CONTACT + VICTIM_FREE + BUFFER_TICKS + SPARE_TICKS)
	_assert_grab(scene, CONTACT)
	var violations: Array[String] = []
	for row: Duel.Row in scene.duel.rows:
		if GrabRig.tech_tick(row.fought[VICTIM]) != FighterState.NEVER:
			violations.append("tick %d: a tech after the hold" % row.tick)
		if row.fought[VICTIM].action == FighterState.Action.WINDUP:
			violations.append("tick %d: the late press fired a move" % row.tick)
	_assert_no(violations)
	assert_int(GrabRig.free_tick(scene.duel, GRABBER, CONTACT + 2)).is_equal(CONTACT + RELEASE)
	assert_int(GrabRig.free_tick(scene.duel, VICTIM, CONTACT + 1)).is_equal(CONTACT + VICTIM_FREE)


# Criterion 3 ("Com o tech [...] Tudo recomeça", with 2 ticks for whoever answered): after a tech a
# light the victim presses on C + 24 fires there, and one the grabber presses on the same tick
# waits in the slot and fires on C + 26. The old states are read on their last ticks (F-195).
func test_after_a_tech_both_act_again_the_victim_first() -> void:
	var scene := _scene()
	scene.victim.press(CONTACT + 10, GUARD_BREAK)
	scene.victim.press(CONTACT + RELEASE, FighterCommand.LIGHT_ATTACK)
	scene.grabber.press(CONTACT + RELEASE, FighterCommand.LIGHT_ATTACK)
	scene.duel.run_through(CONTACT + RELEASE + TECH_ADVANTAGE + SPARE_TICKS)
	_assert_grab(scene, CONTACT)
	assert_bool(GrabRig.is_grabbed(_fought(scene, CONTACT + RELEASE - 1, VICTIM))).is_true()
	var victim := _fought(scene, CONTACT + RELEASE, VICTIM)
	assert_int(victim.action).override_failure_message(GrabRig.line(victim)).is_equal(
		FighterState.Action.WINDUP
	)
	assert_int(victim.action_since).is_equal(CONTACT + RELEASE)
	assert_str(String(victim.action_move)).is_equal(String(LIGHT))
	var grabber_out := CONTACT + RELEASE + TECH_ADVANTAGE
	assert_bool(GrabRig.is_grabbing(_fought(scene, grabber_out - 1, GRABBER))).is_true()
	var grabber := _fought(scene, grabber_out, GRABBER)
	assert_int(grabber.action).override_failure_message(GrabRig.line(grabber)).is_equal(
		FighterState.Action.WINDUP
	)
	assert_int(grabber.action_since).is_equal(grabber_out)
	assert_str(String(grabber.action_move)).is_equal(String(LIGHT))


# The grab of criterion 3's punish: the victim 1,5 m straight along the hand, looking back at the
# grabber, grabbed on the 6th active tick. Run to two ticks past the contact; returns the scene.
func _grab_at_1_5_m() -> Scene:
	var scene := _scene(FACING_THE_GRABBER, VICTIM_FEET_AT_1_5_M)
	var contact := PRESS + WINDUP_TICKS + CONTACT_ACTIVE_TICK_AT_1_5_M - 1
	scene.duel.run_through(contact + 2)
	assert_int(scene.duel.contact_tick_of(GRABBER)).is_equal(contact)
	_assert_grab(scene, contact)
	return scene


# The victim's answer to the grab without a tech, from the tick after the contact on: the guard
# held, the parry or the dash pressed on every tick, or nothing.
func _answer(victim: Player, answer: String, contact: int, until: int) -> void:
	match answer:
		"guard":
			victim.guard_from(contact + 1, true)
		"parry":
			victim.press_every_tick(contact + 1, until, FighterCommand.PARRY)
		"dash":
			victim.press_every_tick(contact + 1, until, FighterCommand.DASH)
		"nothing":
			pass
		_:
			fail("unknown answer %s" % answer)


# Criterion 3 (F-208; "Quebra sem tech: um carregado garantido [...] nem a guarda, nem o parry, nem
# o dash chegam a tempo"): without a tech, a charged the grabber starts on the release tick, C + 24,
# touches on C + 66, and one started on C + 33 touches on C + 75, the last tick before the victim
# acts again. Whatever the victim holds or presses from the contact on, the guard, the parry or the
# dash, none comes out: the cut takes 30 on the tick after its contact, with the hitstun, and the
# hit takes the place of the grab.
func test_without_a_tech_the_grabbers_charged_lands_before_any_answer(
	started_after: int,
	answer: String,
	_test_parameters := [
		[24, "nothing"],
		[24, "guard"],
		[24, "parry"],
		[24, "dash"],
		[33, "nothing"],
		[33, "guard"],
		[33, "parry"],
		[33, "dash"],
	],
) -> void:
	assert_int(started_after).is_between(RELEASE, LAST_GUARANTEED_START)
	var scene := _grab_at_1_5_m()
	var contact := scene.duel.contact_tick_of(GRABBER)
	if contact == FighterState.NEVER:
		return
	var started := contact + started_after
	var lands := started + CHARGED_WINDUP_TICKS
	assert_int(lands).is_less(contact + VICTIM_FREE)
	# The camera turns from the hand's aim to the sword's, so the cut also goes down -Z.
	scene.grabber.look_from(contact + RELEASE, _sword_camera(HAND_ALONG))
	scene.grabber.press(started, FighterCommand.CHARGED_ATTACK)
	_answer(scene.victim, answer, contact, lands + SPARE_TICKS)
	scene.duel.run_through(lands + SPARE_TICKS)
	assert_bool(GrabRig.is_grabbing(_fought(scene, contact + RELEASE - 1, GRABBER))).is_true()
	var charging := _fought(scene, started, GRABBER)
	assert_int(charging.action).override_failure_message(GrabRig.line(charging)).is_equal(
		FighterState.Action.WINDUP
	)
	assert_int(charging.action_since).is_equal(started)
	assert_str(String(charging.action_move)).is_equal(String(CHARGED))
	var cut := _fought(scene, lands, GRABBER)
	assert_int(cut.contact_tick).override_failure_message("the cut touched on %d, expected %d"
	% [cut.contact_tick, lands]) \
			.is_equal(lands)
	assert_str(String(cut.contact_move)).is_equal(String(CHARGED))
	var violations: Array[String] = []
	for row: Duel.Row in scene.duel.rows:
		if row.tick <= contact or row.tick > lands:
			continue
		var victim := row.fought[VICTIM]
		if not GrabRig.is_grabbed(victim):
			violations.append("tick %d: the victim is %s" % [row.tick, GrabRig.line(victim)])
		if row.ends[VICTIM].dash_tick != FighterState.NEVER:
			violations.append("tick %d: the victim dashed" % row.tick)
		if row.ends[VICTIM].mode != FighterState.Mode.GROUND:
			violations.append("tick %d: the victim left the ground mode" % row.tick)
	_assert_no(violations)
	var hit := _fought(scene, lands + 1, VICTIM)
	var message := "tick %d: the victim is %s, expected the hit of the cut at %d" % [
		lands + 1,
		GrabRig.line(hit),
		lands,
	]
	assert_int(hit.action).override_failure_message(message).is_equal(FighterState.Action.HITSTUN)
	assert_int(hit.hurt_tick).override_failure_message(message).is_equal(lands)
	assert_int(hit.health).override_failure_message(message).is_equal(MAX_HEALTH - CHARGED_DAMAGE)
	assert_int(hit.block_tick).override_failure_message(message).is_equal(FighterState.NEVER)
	assert_int(hit.parry_tick).override_failure_message(message).is_equal(FighterState.NEVER)
	for tick: int in range(lands + 1, lands + SPARE_TICKS + 1):
		assert_int(scene.duel.row_at(tick).ends[VICTIM].dash_tick) \
				.override_failure_message("tick %d: the victim dashed out of the hit" % tick) \
				.is_equal(FighterState.NEVER)


# Criterion 3, the other side of the limit ("começado até C + 33, ainda pega antes de C + 76"): a
# charged started on C + 34 touches on C + 76, the tick the victim acts again, and the parry the
# victim was pressing comes out on that tick and parries it (combate.md, "O parry certo": "com o
# tick do contato na janela", which opens on the tick the stance begins).
func test_a_charged_started_one_tick_too_late_meets_the_parry() -> void:
	var scene := _grab_at_1_5_m()
	var contact := scene.duel.contact_tick_of(GRABBER)
	if contact == FighterState.NEVER:
		return
	var started := contact + LAST_GUARANTEED_START + 1
	var lands := started + CHARGED_WINDUP_TICKS
	assert_int(lands).is_equal(contact + VICTIM_FREE)
	scene.grabber.look_from(contact + RELEASE, _sword_camera(HAND_ALONG))
	scene.grabber.press(started, FighterCommand.CHARGED_ATTACK)
	_answer(scene.victim, "parry", contact, lands)
	scene.duel.run_through(lands + SPARE_TICKS)
	assert_bool(GrabRig.is_grabbed(_fought(scene, lands - 1, VICTIM))).is_true()
	var stance := _fought(scene, lands, VICTIM)
	assert_int(stance.action).override_failure_message(GrabRig.line(stance)).is_equal(
		FighterState.Action.PARRY
	)
	assert_int(stance.action_since).is_equal(lands)
	assert_int(_fought(scene, lands, GRABBER).contact_tick).is_equal(lands)
	var parried := _fought(scene, lands + 1, VICTIM)
	assert_int(parried.parry_tick).override_failure_message(GrabRig.line(parried)).is_equal(lands)
	assert_int(parried.health).is_equal(MAX_HEALTH)
	assert_int(parried.hurt_tick).is_equal(FighterState.NEVER)
