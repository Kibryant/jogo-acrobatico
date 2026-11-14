# Criteria 1, 2, 3 and 5 of TASK-12.14, the sword on the crosshair (combate.md, "A espada na mira"
# and "A lâmina e o contato": "Direção" and "Convergência"; DEC-0057), through the public interface
# of core/fighter, with the whole tick sandwich played by the ChargedRig and, for the contacts,
# rigs under a Duel with a TickPhoto taken on every tick. The camera sits 0,8 m to the right of
# the body, so the aim line, the screen's centre, runs 0,8 m to the right of the body's axis
# (DEC-0045 §2). On every windup tick the swing points from the body's axis to the point of that
# line 2,0 m from the axis: the camera's yaw minus asin(0,8 / 2,0), 23,578° to the right, for the
# light and the charged alike, the pitch left out. The body looks along the swing from the windup
# on; from the first active tick to the end of the recovery both stay. With the crosshair on a
# target's axis, the charged touches from 1,2 to 2,3 m centre to centre and misses at 1,0 and at
# 2,5 m, and the light touches from 1,0 to 2,3 m. The turn follows the data: the convergence of
# the CombatConfig and the shoulder of the MovementConfig. Every number comes from docs/design,
# cited by section; ticks by hand from the ms, nearest tick with ties up.
extends GdUnitTestSuite

const ChargedRig := preload("res://test/core/fighter/charged_rig.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")
const Duel := preload("res://test/core/fighter/duel.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
# The moves' IDs (glossario.md, "Golpe carregado" and "Golpe leve").
const CHARGED := &"charged_attack"
const LIGHT := &"light_attack"
# The fighters by name, the photo's key (DEC-0051 §1); the target first by name.
const TARGET := &"A"
const ATTACKER := &"B"
# The new numbers by the names agreed in combate.md, "A espada na mira": "Os nomes no código".
const CONVERGENCE_DATA_FIELD := &"aim_convergence_m"
const CONVERGENCE_CONFIG_FIELD := &"aim_convergence"

const SHOULDER_M := 0.8 # movimento.md, "Câmera": "Ombro", 0,8 m to the right
const CONVERGENCE_M := 2.0 # combate.md, "A lâmina e o contato": "Convergência", 2,0 m
# combate.md, "A lâmina e o contato": "Direção": "o golpe gira ≈ 23,58° para a direita do yaw da
# câmera"; DEC-0057, "Opções consideradas" 1: asen(0,8 / 2,0), 23,578°, 0,411517 rad.
const TURN_RAD := 0.411517
const TURN_DEG := 23.578
const SIX_DECIMALS := 1e-6 # the turn above is written to six decimals
const THREE_DECIMALS := 1e-3 # the degrees above are written to three decimals
# combate.md, "Os golpes e as defesas": the charged's 700 / 120 / 450 ms are 42 / 7 / 27 ticks at
# 60 and 21 / 4 / 14 at 30 ("As fases do carregado": "a 30 ticks, são 21, 4 e 14": 120 ms are 3,6,
# so 4, and 450 ms are 13,5, the tie that goes up); the light's 250 / 100 / 200 ms are 15 / 6 / 12
# at 60 and 8 / 3 / 6 at 30 (250 ms are 7,5, the tie that goes up; DEC-0052).
const CHARGED_TICKS: Dictionary[int, Vector3i] = {
	30: Vector3i(21, 4, 14),
	60: Vector3i(42, 7, 27),
}
const LIGHT_TICKS: Dictionary[int, Vector3i] = { 30: Vector3i(8, 3, 6), 60: Vector3i(15, 6, 12) }
# combate.md, "Os golpes e as defesas": the charged takes 30 and the light 12; partida.md, "A vida
# sem partida": vida 100.
const CHARGED_DAMAGE := 30
const LIGHT_DAMAGE := 12
const MAX_HEALTH := 100
# combate.md, "O toque do carregado": "um alvo de frente a 1,5 m é tocado no primeiro tick ativo";
# "O toque": the slice touches within 0,43 m of the target's axis. Dead ahead of the camera at
# 1,5 m, the cut's plane now passes 1,5 · sin 23,578° = 0,60 m to the side, beyond the 0,43.
const AHEAD_M := 1.5
# combate.md, "O arco do leve": "de −60° a +60° da direção do golpe". The arc turns with the swing,
# so from the camera it runs from 83,6° to the right to 36,4° to the left. At 1,5 m a target 80° to
# the right of the camera is inside it (20° outside the arc of a swing along the camera, 0,51 m
# from its edge, beyond the 0,43 of the touch); one 60° to the left is 23,6° outside it, 0,60 m
# from its edge, beyond the touch (on the edge of the arc of a swing along the camera).
const LIGHT_RIGHT_DEG := 80.0
const LIGHT_LEFT_DEG := 60.0
# Arthur's median charged began 1,84 m centre to centre (DEC-0057, "Contexto": "mediana de 1,84
# m"; TASK-12.14 plan).
const MEDIAN_M := 1.84

const HAIR := 1e-6 # floating-point slack, not a design number
# Positions are single-precision vectors: 10 µm of slack on a distance worked out from them.
const LINE_HAIR := 1e-5
const YAW_STEP := 0.05 # rad per tick the camera turns: arithmetic
const FIRST_YAW := 0.3 # rad, arithmetic
const SPARE_TICKS := 6 # ticks a run keeps going past the swing's end: arithmetic
const PRESS_AFTER_START := 10 # ticks after FIRST_TICK the swing is pressed: arithmetic
const REST_TICKS := 3 # idle ticks before a swing: arithmetic
# Any feet and yaws off the axes, so a wrong component of the placement shows: arithmetic.
const ELSEWHERE := Vector3(3.0, 0.0, -2.0)
const FACING_BACK := PI # the target looks toward +Z; where it looks changes nothing here


func _phases(move: StringName, tickrate: int) -> Vector3i:
	return CHARGED_TICKS[tickrate] if move == CHARGED else LIGHT_TICKS[tickrate]


func _swing_ticks(move: StringName, tickrate: int) -> int:
	var phases := _phases(move, tickrate)
	return phases.x + phases.y + phases.z


func _damage(move: StringName) -> int:
	return CHARGED_DAMAGE if move == CHARGED else LIGHT_DAMAGE


func _press(move: StringName, yaw: float) -> TickInput:
	if move == CHARGED:
		return ChargedRig.press_charged(Vector2.ZERO, yaw)
	return ChargedRig.press_light(Vector2.ZERO, yaw)


func _fighter(
	tickrate: int,
	combat: CombatConfig = null,
	movement: MovementConfig = null,
) -> ChargedRig:
	return ChargedRig.new(
		ATTACKER,
		movement if movement != null else MovementRig.load_config(tickrate),
		combat if combat != null else ChargedRig.load_combat(tickrate),
		FIRST_TICK,
	)


# combat_v0.tres with another convergence, in metres, as the configuration of one tickrate: the
# number is set by its agreed name, and the test stops here when the data has no such number.
func _combat_with_convergence(convergence_m: float, tickrate: int) -> CombatConfig:
	var data := ChargedRig.load_combat_data()
	data.set(CONVERGENCE_DATA_FIELD, convergence_m)
	assert_that(data.get(CONVERGENCE_DATA_FIELD)) \
			.override_failure_message("CombatData has no %s" % CONVERGENCE_DATA_FIELD) \
			.is_equal(convergence_m)
	return CombatConfig.create(data, tickrate)


# movement_v0.tres with another shoulder, in metres, as the configuration of one tickrate.
func _movement_with_side(side_m: float, tickrate: int) -> MovementConfig:
	var resource: Resource = load(MovementRig.MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MovementRig.MOVEMENT_V0)
	var copy: Resource = resource.duplicate()
	assert(copy is MovementData, "a duplicate must still be a MovementData")
	var data := copy as MovementData
	data.aim_side_m = side_m
	return MovementConfig.create(data, tickrate)


# A float the object holds under this name; the case fails when it holds none, and NAN comes back.
func _float_of(object: Object, field: StringName) -> float:
	var value: Variant = object.get(field)
	var missing := "%s has no float %s" % [object, field]
	assert_bool(value is float).override_failure_message(missing).is_true()
	if value is float:
		var number: float = value
		return number
	return NAN


# How far apart two yaws are, whatever the turns between them.
func _apart(yaw: float, other: float) -> float:
	return absf(angle_difference(yaw, other))


# Where a target stands so that its axis is on the attacker's aim line, `distance` metres centre
# to centre: with the camera at yaw 0, looking down -Z with the right at +X, the aim line is
# x = 0,8, so the axis is at (0,8; -sqrt(distance² - 0,8²)); for another yaw, turned by it
# (TASK-12.14 plan). The crosshair is then on the target's axis.
func _on_the_aim_line(attacker_feet: Vector3, yaw: float, distance: float) -> Vector3:
	var ahead := sqrt(distance * distance - SHOULDER_M * SHOULDER_M)
	return attacker_feet + Basis(Vector3.UP, yaw) * Vector3(SHOULDER_M, 0.0, -ahead)


# A point `distance` metres from the feet, `right_deg` degrees to the right of the yaw on the
# floor's plane (negative is to the left).
func _at_bearing(feet: Vector3, yaw: float, right_deg: float, distance: float) -> Vector3:
	return feet + Blade.direction(yaw - deg_to_rad(right_deg)) * distance


# The script of an attacker that keeps the camera on yaw and presses the move on `press`.
func _attacker(move: StringName, press: int, yaw: float) -> Callable:
	return func(tick: int) -> TickInput:
		if tick == press:
			return _press(move, yaw)
		return ChargedRig.idle(yaw)


func _idler(yaw: float) -> Callable:
	return func(_tick: int) -> TickInput:
		return ChargedRig.idle(yaw)


# The target standing still at target_feet, index 0, and the attacker at attacker_feet with the
# camera on yaw, pressing the move PRESS_AFTER_START ticks in, index 1; run to past the swing's end.
func _swing_at(
	move: StringName,
	tickrate: int,
	attacker_feet: Vector3,
	yaw: float,
	target_feet: Vector3,
) -> Duel:
	var combat := ChargedRig.load_combat(tickrate)
	var movement := MovementRig.load_config(tickrate)
	var duel := Duel.new()
	duel.add(
		ChargedRig.new(TARGET, movement, combat, FIRST_TICK, target_feet, FACING_BACK),
		_idler(FACING_BACK),
	)
	duel.add(
		ChargedRig.new(ATTACKER, movement, combat, FIRST_TICK, attacker_feet, yaw),
		_attacker(move, _press_tick(), yaw),
	)
	duel.run_through(_press_tick() + _swing_ticks(move, tickrate) + SPARE_TICKS)
	return duel


func _press_tick() -> int:
	return FIRST_TICK + PRESS_AFTER_START


# The swing touched the target once, on a tick of its active phase, by the core's own stamp
# (combate.md, "O leve no tick": "O contato"), and the target lost the move's damage on the tick
# after it. Returns the active tick of the contact, from 1, or 0 when there was none.
func _assert_touched(duel: Duel, move: StringName, tickrate: int, where: String) -> int:
	var phases := _phases(move, tickrate)
	var first_active := _press_tick() + phases.x
	var contact := duel.contact_tick_of(1)
	var message := "%s, %s at %d ticks: contact at %d, expected one from %d to %d" % [
		where,
		move,
		tickrate,
		contact,
		first_active,
		first_active + phases.y - 1,
	]
	assert_int(contact).override_failure_message(message).is_not_equal(FighterState.NEVER)
	if contact == FighterState.NEVER:
		return 0
	assert_int(contact).override_failure_message(message).is_between(
		first_active,
		first_active + phases.y - 1,
	)
	var stamped := duel.row_at(contact).fought[1]
	assert_str(String(stamped.contact_target)).override_failure_message(message).is_equal(
		String(TARGET)
	)
	assert_str(String(stamped.contact_move)).override_failure_message(message).is_equal(
		String(move)
	)
	var hurt := duel.row_at(contact + 1).fought[0]
	assert_int(hurt.health).override_failure_message("%s: health %d" % [where, hurt.health]) \
			.is_equal(MAX_HEALTH - _damage(move))
	return contact - first_active + 1


# The swing touched nobody: no stamp on any tick, and the target keeps its health.
func _assert_missed(duel: Duel, move: StringName, tickrate: int, where: String) -> void:
	var contact := duel.contact_tick_of(1)
	var message := "%s, %s at %d ticks: contact at %d, expected none" % [
		where,
		move,
		tickrate,
		contact,
	]
	assert_int(contact).override_failure_message(message).is_equal(FighterState.NEVER)
	for row: Duel.Row in duel.rows:
		assert_int(row.fought[0].health).override_failure_message("%s: %d" % [where, row.tick]) \
				.is_equal(MAX_HEALTH)


# Presses the move with the camera on yaw and returns the state at the end of that tick, the first
# of the windup: the combat wrote the swing's direction and the movement turned the body (F-177).
func _first_windup_tick(fighter: ChargedRig, move: StringName, input: TickInput) -> FighterState:
	fighter.step(input)
	assert_int(fighter.fought.action).override_failure_message("the %s did not begin" % move) \
			.is_equal(FighterState.Action.WINDUP)
	assert_str(String(fighter.fought.action_move)).is_equal(String(move))
	return fighter.state()


# The placement itself, by the aim line of DEC-0045 §2: the target's axis is on the line that
# leaves the attacker's point O along the camera's direction, at the asked distance centre to
# centre. A wrong placement would make every contact below prove nothing.
func test_the_placement_puts_the_targets_axis_on_the_attackers_aim_line(
	yaw: float,
	distance: float,
	_test_parameters := [[0.0, 1.0], [0.0, 2.3], [1.1, 1.84], [-2.0, 1.5]],
) -> void:
	var config := MovementRig.load_config(60)
	assert_float(config.aim_side).is_equal_approx(SHOULDER_M, HAIR)
	var target := _on_the_aim_line(ELSEWHERE, yaw, distance)
	var origin := Aim.origin(ELSEWHERE, yaw, config.aim_height, config.aim_side)
	var forward := Aim.direction(yaw, 0.0)
	var from_origin := Vector3(target.x - origin.x, 0.0, target.z - origin.z)
	assert_float(absf(from_origin.cross(forward).y)).is_equal_approx(0.0, LINE_HAIR)
	assert_float(from_origin.dot(forward)).is_greater(0.0)
	assert_float(target.distance_to(ELSEWHERE)).is_equal_approx(distance, LINE_HAIR)


# Criterion 1, many: with the crosshair on the axis of a target standing on the same floor, the
# charged touches at 1,2, 1,5, 2,0 and 2,3 m centre to centre, with no compensation (combate.md,
# "A espada na mira": "o carregado, de 1,11 a 2,40 m de centro a centro").
func test_a_charged_with_the_crosshair_on_the_target_touches_from_1_2_to_2_3_m(
	tickrate: int,
	distance: float,
	_test_parameters := [
		[60, 1.2],
		[60, 1.5],
		[60, 2.0],
		[60, 2.3],
		[30, 1.2],
		[30, 1.5],
		[30, 2.0],
		[30, 2.3],
	],
) -> void:
	var target := _on_the_aim_line(Vector3.ZERO, 0.0, distance)
	var duel := _swing_at(CHARGED, tickrate, Vector3.ZERO, 0.0, target)
	_assert_touched(duel, CHARGED, tickrate, "crosshair on the target %.2f m away" % distance)


# Criterion 1, the limits: at 1,0 m the blade has not reached the aim line yet and passes beside
# it; at 2,5 m the reach is short (combate.md, "A espada na mira": "Mais perto que 1,1 m [...];
# mais longe que 2,4 m, falta alcance").
func test_a_charged_with_the_crosshair_on_the_target_misses_at_1_0_m_and_at_2_5_m(
	tickrate: int,
	distance: float,
	_test_parameters := [[60, 1.0], [60, 2.5], [30, 1.0], [30, 2.5]],
) -> void:
	var target := _on_the_aim_line(Vector3.ZERO, 0.0, distance)
	var duel := _swing_at(CHARGED, tickrate, Vector3.ZERO, 0.0, target)
	_assert_missed(duel, CHARGED, tickrate, "crosshair on the target %.2f m away" % distance)


# Criterion 1, anywhere: the rule turns with the camera and moves with the body. At Arthur's
# median distance, 1,84 m, and at the ends of the window, from other feet and other yaws.
func test_a_charged_touches_the_target_on_the_crosshair_from_any_feet_and_yaw(
	yaw: float,
	distance: float,
	_test_parameters := [[1.1, 1.84], [-2.0, 1.84], [2.5, 1.2], [-0.7, 2.3]],
) -> void:
	var target := _on_the_aim_line(ELSEWHERE, yaw, distance)
	var duel := _swing_at(CHARGED, 60, ELSEWHERE, yaw, target)
	_assert_touched(duel, CHARGED, 60, "yaw %.1f, target %.2f m away" % [yaw, distance])


func test_a_charged_misses_at_1_0_m_and_at_2_5_m_from_any_feet_and_yaw(
	yaw: float,
	distance: float,
	_test_parameters := [[1.1, 1.0], [-2.0, 2.5]],
) -> void:
	var target := _on_the_aim_line(ELSEWHERE, yaw, distance)
	var duel := _swing_at(CHARGED, 60, ELSEWHERE, yaw, target)
	_assert_missed(duel, CHARGED, 60, "yaw %.1f, target %.2f m away" % [yaw, distance])


# The point is fixed and does not follow the other (combate.md, "A lâmina e o contato": "Direção":
# "Sem travar a mira no oponente"): a target dead ahead of the swing's direction at 1,5 m is
# touched on the first active tick ("O toque do carregado"), and one dead ahead of the camera at
# 1,5 m, 0,60 m off the cut's plane, is not touched.
func test_the_cut_goes_along_the_swing_direction_and_not_along_the_camera(
	tickrate: int,
	_test_parameters := [[60], [30]],
) -> void:
	var yaw := FIRST_YAW
	var along_the_swing := _at_bearing(ELSEWHERE, yaw, rad_to_deg(TURN_RAD), AHEAD_M)
	var touched := _swing_at(CHARGED, tickrate, ELSEWHERE, yaw, along_the_swing)
	var active_tick := _assert_touched(touched, CHARGED, tickrate, "ahead of the swing")
	assert_int(active_tick).override_failure_message("touched on active tick %d" % active_tick) \
			.is_equal(1)
	var along_the_camera := _at_bearing(ELSEWHERE, yaw, 0.0, AHEAD_M)
	var missed := _swing_at(CHARGED, tickrate, ELSEWHERE, yaw, along_the_camera)
	_assert_missed(missed, CHARGED, tickrate, "ahead of the camera")


# Criterion 2, many: with the crosshair on the target's axis, the light's arc touches at 1,0,
# 1,84 and 2,3 m (combate.md, "A espada na mira": "o leve, de 0,80 a 2,42 m").
func test_a_light_with_the_crosshair_on_the_target_touches_from_1_0_to_2_3_m(
	tickrate: int,
	distance: float,
	_test_parameters := [[60, 1.0], [60, 1.84], [60, 2.3], [30, 1.0], [30, 1.84], [30, 2.3]],
) -> void:
	var target := _on_the_aim_line(Vector3.ZERO, 0.0, distance)
	var duel := _swing_at(LIGHT, tickrate, Vector3.ZERO, 0.0, target)
	_assert_touched(duel, LIGHT, tickrate, "crosshair on the target %.2f m away" % distance)


func test_a_light_touches_the_target_on_the_crosshair_from_any_feet_and_yaw(
	yaw: float,
	distance: float,
	_test_parameters := [[1.1, 1.84], [-2.0, 1.0], [2.5, 2.3]],
) -> void:
	var target := _on_the_aim_line(ELSEWHERE, yaw, distance)
	var duel := _swing_at(LIGHT, 60, ELSEWHERE, yaw, target)
	_assert_touched(duel, LIGHT, 60, "yaw %.1f, target %.2f m away" % [yaw, distance])


# Criterion 2: the light's arc of ±60° is around the swing's direction, 23,578° to the right of
# the camera (combate.md, "O arco do leve"): at 1,5 m it reaches a target 80° to the right of the
# camera and no longer one 60° to the left.
func test_the_lights_arc_turns_with_the_swing(
	tickrate: int,
	_test_parameters := [[60], [30]],
) -> void:
	var yaw := FIRST_YAW
	var to_the_right := _at_bearing(ELSEWHERE, yaw, LIGHT_RIGHT_DEG, AHEAD_M)
	var touched := _swing_at(LIGHT, tickrate, ELSEWHERE, yaw, to_the_right)
	_assert_touched(touched, LIGHT, tickrate, "80 degrees to the right of the camera")
	var to_the_left := _at_bearing(ELSEWHERE, yaw, -LIGHT_LEFT_DEG, AHEAD_M)
	var missed := _swing_at(LIGHT, tickrate, ELSEWHERE, yaw, to_the_left)
	_assert_missed(missed, LIGHT, tickrate, "60 degrees to the left of the camera")


# Criterion 2: the light and the charged use the same point: for one camera yaw both swings point
# the same way, the yaw minus asin(shoulder / convergence), 23,578° to the right with the v0.
func test_the_light_and_the_charged_point_23_578_degrees_to_the_right_of_the_camera(
	tickrate: int,
	yaw: float,
	_test_parameters := [[60, 0.0], [60, 1.1], [60, -2.0], [30, 0.0], [30, 0.7]],
) -> void:
	var light := _first_windup_tick(_fighter(tickrate), LIGHT, _press(LIGHT, yaw))
	var charged := _first_windup_tick(_fighter(tickrate), CHARGED, _press(CHARGED, yaw))
	var message := "camera %.4f: the light points to %.6f and the charged to %.6f" % [
		yaw,
		light.action_yaw,
		charged.action_yaw,
	]
	assert_float(_apart(light.action_yaw, charged.action_yaw)).override_failure_message(message) \
			.is_less(HAIR)
	assert_float(_apart(charged.action_yaw, yaw - TURN_RAD)).override_failure_message(message) \
			.is_less(SIX_DECIMALS)
	assert_float(_apart(light.action_yaw, yaw - asin(SHOULDER_M / CONVERGENCE_M))) \
			.override_failure_message(message) \
			.is_less(HAIR)
	# To the right: a positive yaw turns left, so the swing's yaw is below the camera's.
	assert_float(rad_to_deg(angle_difference(charged.action_yaw, yaw))) \
			.override_failure_message(message) \
			.is_equal_approx(TURN_DEG, THREE_DECIMALS)


# The pitch does not enter (DEC-0057 §2): looking up or down, the swing points the same way.
func test_the_pitch_does_not_change_the_swings_direction(
	move: StringName,
	pitch: float,
	_test_parameters := [[CHARGED, 0.6], [CHARGED, -1.2], [LIGHT, 0.6], [LIGHT, -1.2]],
) -> void:
	var input := _press(move, FIRST_YAW)
	input.pitch = pitch
	var state := _first_windup_tick(_fighter(60), move, input)
	assert_float(_apart(state.action_yaw, FIRST_YAW - TURN_RAD)).is_less(SIX_DECIMALS)
	assert_float(_apart(state.facing_yaw, FIRST_YAW - TURN_RAD)).is_less(SIX_DECIMALS)


# Criterion 3: outside a swing the body looks along the camera, as before. Through the windup,
# with the camera turning every tick, the swing's direction and the body are both the camera's yaw
# of that tick minus the turn: the body looks along the swing and not along the camera, and
# turning the camera moves both by the same amount. From the first active tick to the end of the
# recovery both stay where the last windup tick left them, however the camera turns; on the end
# tick the body follows the camera again. The direction is read on the combat's output and the
# body on the state after the movement's slice, the one that turns it (F-177).
func test_the_body_looks_along_the_swing_from_the_windup_and_both_stay_from_the_active_on(
	move: StringName,
	tickrate: int,
	_test_parameters := [[CHARGED, 60], [CHARGED, 30], [LIGHT, 60], [LIGHT, 30]],
) -> void:
	var fighter := _fighter(tickrate)
	var violations: Array[String] = []
	for _rest: int in REST_TICKS:
		fighter.step(ChargedRig.idle(FIRST_YAW))
		if _apart(fighter.state().facing_yaw, FIRST_YAW) > HAIR:
			violations.append("before the swing: facing %.4f" % fighter.state().facing_yaw)
	var phases := _phases(move, tickrate)
	var windup := phases.x
	var swing := _swing_ticks(move, tickrate)
	var turn := asin(SHOULDER_M / CONVERGENCE_M)
	var fixed := FIRST_YAW + YAW_STEP * (windup - 1) - turn
	for offset: int in swing + 2:
		var yaw := FIRST_YAW + YAW_STEP * offset
		var input := _press(move, yaw) if offset == 0 else ChargedRig.idle(yaw)
		fighter.step(input)
		var fought := fighter.fought
		var end := fighter.state()
		var expected_action := FighterState.Action.NONE
		if offset < windup:
			expected_action = FighterState.Action.WINDUP
		elif offset < windup + phases.y:
			expected_action = FighterState.Action.ACTIVE
		elif offset < swing:
			expected_action = FighterState.Action.RECOVERY
		if fought.action != expected_action:
			violations.append(
				"tick %d: action %d, expected %d" % [offset, fought.action, expected_action]
			)
		var line := "tick %d: swing %.4f, facing %.4f, camera %.4f" % [
			offset,
			fought.action_yaw,
			end.facing_yaw,
			yaw,
		]
		if offset < windup:
			var along := yaw - turn
			if _apart(fought.action_yaw, along) > HAIR or _apart(end.facing_yaw, along) > HAIR:
				violations.append("%s, expected both at %.4f in the windup" % [line, along])
			if _apart(end.facing_yaw, end.action_yaw) > HAIR:
				violations.append("%s: the body does not look along the swing" % line)
		elif offset < swing:
			if _apart(fought.action_yaw, fixed) > HAIR or _apart(end.facing_yaw, fixed) > HAIR:
				violations.append("%s, expected both fixed at %.4f" % [line, fixed])
		elif _apart(end.facing_yaw, yaw) > HAIR:
			violations.append("%s: after the swing the body follows the camera" % line)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()


# Criterion 3, one: on a windup tick the body is 23,578° to the right of the camera, not on it.
func test_in_the_windup_the_body_is_not_on_the_cameras_yaw(
	move: StringName,
	_test_parameters := [[CHARGED], [LIGHT]],
) -> void:
	var state := _first_windup_tick(_fighter(60), move, _press(move, FIRST_YAW))
	var message := "camera %.4f, facing %.6f" % [FIRST_YAW, state.facing_yaw]
	assert_float(_apart(state.facing_yaw, FIRST_YAW)).override_failure_message(message) \
			.is_equal_approx(TURN_RAD, SIX_DECIMALS)
	assert_float(_apart(state.facing_yaw, state.action_yaw)).override_failure_message(message) \
			.is_less(HAIR)


# Criterion 3: a camera that turns only after the windup changes nothing of the swing: the target
# on the crosshair of the last windup tick is touched, however far the camera has turned away
# since. And a camera that comes to the target only on the last windup tick still touches it.
func test_the_swing_lands_where_the_crosshair_was_on_the_last_windup_tick(
	move: StringName,
	_test_parameters := [[CHARGED], [LIGHT]],
) -> void:
	var tickrate := 60
	var phases := _phases(move, tickrate)
	var press := _press_tick()
	var last_windup := press + phases.x - 1
	var final_yaw := -0.9
	var target := _on_the_aim_line(ELSEWHERE, final_yaw, MEDIAN_M)
	var combat := ChargedRig.load_combat(tickrate)
	var movement := MovementRig.load_config(tickrate)
	var duel := Duel.new()
	duel.add(
		ChargedRig.new(TARGET, movement, combat, FIRST_TICK, target, FACING_BACK),
		_idler(FACING_BACK),
	)
	# The camera looks the other way until the tick before the last windup tick, is on the target
	# on that tick alone, and turns away again from the first active tick on.
	var script := func(tick: int) -> TickInput:
		var yaw := final_yaw if tick == last_windup else final_yaw + PI
		if tick > last_windup:
			yaw = final_yaw + YAW_STEP * 4.0 * (tick - last_windup)
		return _press(move, yaw) if tick == press else ChargedRig.idle(yaw)
	duel.add(ChargedRig.new(ATTACKER, movement, combat, FIRST_TICK, ELSEWHERE, 0.0), script)
	duel.run_through(press + _swing_ticks(move, tickrate) + SPARE_TICKS)
	_assert_touched(duel, move, tickrate, "the crosshair on the target on the last windup tick")


# Criterion 5: the configuration carries the convergence of the data, 2,0 m in the v0.
func test_the_config_copies_the_convergence_of_the_data(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var v0 := ChargedRig.load_combat(tickrate)
	assert_float(_float_of(v0, CONVERGENCE_CONFIG_FIELD)) \
			.override_failure_message("CombatConfig has no %s" % CONVERGENCE_CONFIG_FIELD) \
			.is_equal_approx(CONVERGENCE_M, HAIR)
	var other := _combat_with_convergence(1.6, tickrate)
	assert_float(_float_of(other, CONVERGENCE_CONFIG_FIELD)).is_equal_approx(1.6, HAIR)


# Criterion 5: the direction changes with the data alone. A convergence of 1,6 m with the shoulder
# of 0,8 m turns the swing asin(0,8 / 1,6), 30°; 4,0 m turns it asin(0,2).
func test_another_convergence_in_the_data_changes_the_swings_direction(
	move: StringName,
	convergence_m: float,
	_test_parameters := [[CHARGED, 1.6], [LIGHT, 1.6], [CHARGED, 4.0], [LIGHT, 4.0]],
) -> void:
	var fighter := _fighter(60, _combat_with_convergence(convergence_m, 60))
	var state := _first_windup_tick(fighter, move, _press(move, FIRST_YAW))
	var expected := FIRST_YAW - asin(SHOULDER_M / convergence_m)
	var message := "convergence %.1f: swing %.6f, facing %.6f, expected %.6f" % [
		convergence_m,
		state.action_yaw,
		state.facing_yaw,
		expected,
	]
	assert_float(_apart(state.action_yaw, expected)).override_failure_message(message).is_less(HAIR)
	assert_float(_apart(state.facing_yaw, expected)).override_failure_message(message).is_less(HAIR)
	if is_equal_approx(convergence_m, 1.6):
		assert_float(_apart(state.action_yaw, FIRST_YAW - deg_to_rad(30.0))) \
				.override_failure_message(message) \
				.is_less(HAIR)


# Criterion 5: with the convergence at 1,6 m the blade crosses the aim line at 1,6 m: the charged
# touches a target on the crosshair there, the target being dead ahead
# of the swing (combate.md, "O toque do carregado").
func test_with_another_convergence_the_charged_touches_the_crosshair_at_that_distance() -> void:
	var tickrate := 60
	var combat := _combat_with_convergence(1.6, tickrate)
	var movement := MovementRig.load_config(tickrate)
	var target := _on_the_aim_line(ELSEWHERE, FIRST_YAW, 1.6)
	var duel := Duel.new()
	duel.add(
		ChargedRig.new(TARGET, movement, combat, FIRST_TICK, target, FACING_BACK),
		_idler(FACING_BACK),
	)
	duel.add(
		ChargedRig.new(ATTACKER, movement, combat, FIRST_TICK, ELSEWHERE, FIRST_YAW),
		_attacker(CHARGED, _press_tick(), FIRST_YAW),
	)
	duel.run_through(_press_tick() + _swing_ticks(CHARGED, tickrate) + SPARE_TICKS)
	_assert_touched(duel, CHARGED, tickrate, "convergence 1.6, target at 1.6 m")


# The shoulder is the MovementConfig's (DEC-0057 §2: "O side é o ombro do MovementData"): half the
# shoulder turns asin(0,4 / 2,0); no shoulder turns nothing; the left shoulder turns to the left.
func test_the_turn_follows_the_shoulder_of_the_movement_config(
	move: StringName,
	side_m: float,
	_test_parameters := [
		[CHARGED, 0.4],
		[LIGHT, 0.4],
		[CHARGED, 0.0],
		[LIGHT, 0.0],
		[CHARGED, -0.8],
		[LIGHT, -0.8],
	],
) -> void:
	var fighter := _fighter(60, null, _movement_with_side(side_m, 60))
	var state := _first_windup_tick(fighter, move, _press(move, FIRST_YAW))
	var expected := FIRST_YAW - asin(side_m / CONVERGENCE_M)
	var message := "shoulder %.1f: swing %.6f, facing %.6f, expected %.6f" % [
		side_m,
		state.action_yaw,
		state.facing_yaw,
		expected,
	]
	assert_float(_apart(state.action_yaw, expected)).override_failure_message(message).is_less(HAIR)
	assert_float(_apart(state.facing_yaw, expected)).override_failure_message(message).is_less(HAIR)


# Failure (combate.md, "A espada na mira": "se não for, a razão fica presa em 1 e o giro para em
# 90°, sem NaN"): a configuration whose convergence is not greater than the shoulder still gives a
# finite direction, a quarter turn to the right, for the swing and for the body.
func test_a_convergence_not_greater_than_the_shoulder_turns_90_degrees_and_is_never_nan(
	convergence_m: float,
	_test_parameters := [[0.8], [0.5]],
) -> void:
	var fighter := _fighter(60, _combat_with_convergence(convergence_m, 60))
	var state := _first_windup_tick(fighter, CHARGED, _press(CHARGED, FIRST_YAW))
	var message := "convergence %.1f: swing %s, facing %s" % [
		convergence_m,
		state.action_yaw,
		state.facing_yaw,
	]
	assert_bool(is_finite(state.action_yaw)).override_failure_message(message).is_true()
	assert_bool(is_finite(state.facing_yaw)).override_failure_message(message).is_true()
	assert_float(_apart(state.action_yaw, FIRST_YAW - PI / 2.0)).override_failure_message(message) \
			.is_less(HAIR)
