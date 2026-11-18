# Criterion 3 of TASK-12.15: with the centered camera the swing goes along the camera (F-219 §1:
# "O golpe sai na direção da câmera, porque Aim.swing_yaw com ombro 0 já dá o golpe reto";
# movimento.md, "Câmera": "Subida": "A câmera centrada [...] tem ombro 0 e subida 0,6 m";
# combate.md, "A espada na mira": "A conta": the camera's yaw minus asen(ombro / convergência), so
# no turn with a shoulder of 0). With the configuration made from data/movement_center.tres, the
# light, the charged and the guard break point along the camera's yaw, and with the crosshair on
# the axis of a target standing on the same floor each one touches from 0,9 m to the far end of
# its reach and misses just past it, with no compensation to the side; under the default shoulder
# of 0,8 m the charged with the crosshair on the target at 0,9 m passes beside it, which is the
# difference. Through the public interface of core/fighter, with GrabRigs under a Duel and a
# TickPhoto taken on every tick. Every number comes from docs/design, cited by section.
extends GdUnitTestSuite

const GrabRig := preload("res://test/core/fighter/grab_rig.gd")
const Player := preload("res://test/core/fighter/grab_player.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")
const Duel := preload("res://test/core/fighter/duel.gd")

## The centered camera's movement numbers (F-219 §1: "Os dados").
const MOVEMENT_CENTER := "res://data/movement_center.tres"
const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
# The moves' IDs (glossario.md, "Golpe leve", "Golpe carregado" and "Quebra de guarda").
const LIGHT := &"light_attack"
const CHARGED := &"charged_attack"
const GUARD_BREAK := GrabRig.GUARD_BREAK
# The fighters by name, the photo's key (DEC-0051 §1), and by index in the Duel.
const TARGET_NAME := &"A"
const ATTACKER_NAME := &"B"
const TARGET := 0
const ATTACKER := 1

# movimento.md, "Câmera": "Ombro": 0,8 m to the right in the default camera; "Subida": 0 in the
# centered one.
const SHOULDER_M := 0.8
const CENTER_SIDE_M := 0.0
# TASK-12.15, criterion 3: "pegam de 0,9 m até o alcance de cada golpe".
const NEAR_M := 0.9
# combate.md, "A lâmina e o contato": "Alcance efetivo: ≈ 2,4 m, centro a centro: ponta mais raio
# mais o raio da cápsula; dentro do arco": the tip at 2,0 m, the blade's 0,08 and the capsule's
# 0,35 are 2,43 m, for the light's arc and the charged's cut alike ("O toque": within 0,43 m of
# the target's axis). 2,4 m is inside it; 2,5 m is 0,5 m from the tip, beyond the touch, the
# distance the convergence suite already misses at ("mais longe que 2,4 m, falta alcance").
const SWORD_REACH_M := 2.4
const SWORD_PAST_M := 2.5
# combate.md, "A quebra, o tech e a esquiva no tick": "A mão": "apontada reto para o alvo, até
# 1,55 m": the hand's 1,2 m plus the capsule's 0,35. 1,5 m is inside it (0,3 m from the hand's
# end) and 1,6 m is past it (0,4 m).
const HAND_REACH_M := 1.5
const HAND_PAST_M := 1.6
# combate.md, "A espada na mira": "Onde pega": under the shoulder of 0,8 m, "o carregado, de 1,11
# a 2,40 m de centro a centro. Mais perto que 1,1 m, a lâmina ainda não chegou à linha da mira e
# passa ao lado dela": at 0,9 m the default camera's charged misses.
const CHARGED_NEAREST_UNDER_THE_SHOULDER_M := 1.11
# combate.md, "Os golpes e as defesas": the light takes 12 and the charged 30, the guard break 0;
# partida.md, "A vida sem partida": 100.
const LIGHT_DAMAGE := 12
const CHARGED_DAMAGE := 30
const MAX_HEALTH := 100
# combate.md, "Os golpes e as defesas": the longest move, the charged, is 42 / 7 / 27 ticks at 60,
# 76 in all, and 21 / 4 / 14 at 30.
const LONGEST_SWING_TICKS := 76

const HAIR := 1e-6 # floating-point slack, not a design number
const LINE_HAIR := 1e-5 # positions are single-precision vectors
const PRESS_AFTER_START := 10 # ticks after FIRST_TICK the move is pressed: arithmetic
const SPARE_TICKS := 6 # ticks a run keeps going past the swing's end: arithmetic
const YAW_STEP := 0.05 # rad per tick the camera turns: arithmetic
const FIRST_YAW := 0.3 # rad, arithmetic
# Any feet off the axes, so a wrong component of the placement shows: arithmetic.
const ELSEWHERE := Vector3(3.0, 0.0, -2.0)
const FACING_BACK := PI # the target looks toward +Z; where it looks changes nothing here


# The numbers of movement_center.tres as the configuration of one tickrate, or null, with the
# case failed, while the file does not exist.
func _center(tickrate: int) -> MovementConfig:
	var exists := ResourceLoader.exists(MOVEMENT_CENTER)
	assert_bool(exists).override_failure_message("%s does not exist" % MOVEMENT_CENTER).is_true()
	if not exists:
		return null
	var resource: Resource = load(MOVEMENT_CENTER)
	var typed := resource is MovementData
	assert_bool(typed).override_failure_message("%s is not a MovementData" % MOVEMENT_CENTER) \
			.is_true()
	if not typed:
		return null
	var config := MovementConfig.create(resource as MovementData, tickrate)
	assert_float(config.aim_side) \
			.override_failure_message("the centered camera's aim_side is %s, expected 0"
	% config.aim_side) \
			.is_equal_approx(CENTER_SIDE_M, HAIR)
	return config


func _press_tick() -> int:
	return FIRST_TICK + PRESS_AFTER_START


func _damage(move: StringName) -> int:
	if move == LIGHT:
		return LIGHT_DAMAGE
	if move == CHARGED:
		return CHARGED_DAMAGE
	return 0


# How far apart two yaws are, whatever the turns between them.
func _apart(yaw: float, other: float) -> float:
	return absf(angle_difference(yaw, other))


# Where a target stands so that its axis is on the attacker's aim line, `distance` metres centre
# to centre, for a camera `side` metres to the right of the body: at yaw 0 the camera looks down
# -Z with the right at +X and the aim line is x = side, so the axis is at
# (side; -sqrt(distance² - side²)); for another yaw, turned by it (TASK-12.14 plan). With no side
# the target is dead ahead of the body.
func _on_the_aim_line(feet: Vector3, yaw: float, distance: float, side: float) -> Vector3:
	assert(distance > absf(side), "the aim line passes %s m from the body" % side)
	var ahead := sqrt(distance * distance - side * side)
	return feet + Basis(Vector3.UP, yaw) * Vector3(side, 0.0, -ahead)


# The target standing still at target_feet, index 0, and the attacker at attacker_feet with the
# camera on yaw, pressing the move PRESS_AFTER_START ticks in, index 1; run to past the end of the
# longest swing.
func _swing_at(
	move: StringName,
	movement: MovementConfig,
	attacker_feet: Vector3,
	yaw: float,
	target_feet: Vector3,
) -> Duel:
	var combat := GrabRig.load_combat(movement.tickrate)
	var idler := Player.new(FACING_BACK)
	var attacker := Player.new(yaw)
	attacker.press(_press_tick(), move)
	var duel := Duel.new()
	duel.add(
		GrabRig.new(TARGET_NAME, movement, combat, FIRST_TICK, target_feet, FACING_BACK),
		idler.input,
	)
	duel.add(
		GrabRig.new(ATTACKER_NAME, movement, combat, FIRST_TICK, attacker_feet, yaw),
		attacker.input,
	)
	duel.run_through(_press_tick() + LONGEST_SWING_TICKS + SPARE_TICKS)
	return duel


# The move touched the target once, by the core's own stamp on the attacker (combate.md, "O leve no
# tick": "O contato"), naming the target and the move, and the target took it on the tick after:
# the move's damage for the sword; for the guard break, GRABBED by that contact with its health
# whole (DEC-0058 §4).
func _assert_touched(duel: Duel, move: StringName, where: String) -> void:
	var contact := duel.contact_tick_of(ATTACKER)
	var message := "%s, %s: contact at %d, expected one" % [where, move, contact]
	assert_int(contact).override_failure_message(message).is_not_equal(FighterState.NEVER)
	if contact == FighterState.NEVER:
		return
	assert_int(contact).override_failure_message(message).is_greater(_press_tick())
	var stamped := duel.row_at(contact).fought[ATTACKER]
	assert_str(String(stamped.contact_target)).override_failure_message(message).is_equal(
		String(TARGET_NAME)
	)
	assert_str(String(stamped.contact_move)).override_failure_message(message).is_equal(
		String(move)
	)
	var taken := duel.row_at(contact + 1).fought[TARGET]
	var after := "%s, %s: on the tick after the contact the target is %s" % [
		where,
		move,
		GrabRig.line(taken),
	]
	assert_int(taken.health).override_failure_message(after).is_equal(MAX_HEALTH - _damage(move))
	if move == GUARD_BREAK:
		assert_bool(GrabRig.is_grabbed(taken)).override_failure_message(after).is_true()
		assert_int(GrabRig.grabbed_tick(taken)).override_failure_message(after).is_equal(contact)


# The move touched nobody: no stamp on any tick, and the target keeps its health and is never
# grabbed.
func _assert_missed(duel: Duel, move: StringName, where: String) -> void:
	var contact := duel.contact_tick_of(ATTACKER)
	var message := "%s, %s: contact at %d, expected none" % [where, move, contact]
	assert_int(contact).override_failure_message(message).is_equal(FighterState.NEVER)
	var violations: Array[String] = []
	var began := false
	for row: Duel.Row in duel.rows:
		var target := row.fought[TARGET]
		if target.health != MAX_HEALTH or GrabRig.is_grabbed(target):
			violations.append("tick %d: the target is %s" % [row.tick, GrabRig.line(target)])
		if row.fought[ATTACKER].action_move == move:
			began = true
	assert_array(violations).override_failure_message(GrabRig.brief(violations)).is_empty()
	# The miss is a miss of this move, not a press that never came out.
	assert_bool(began).override_failure_message("%s: the %s never began" % [where, move]).is_true()


# One fighter alone with this movement configuration, at 60 ticks' or 30's combat numbers.
func _fighter(movement: MovementConfig) -> GrabRig:
	return GrabRig.new(ATTACKER_NAME, movement, GrabRig.load_combat(movement.tickrate), FIRST_TICK)


func _press(move: StringName, yaw: float) -> TickInput:
	return GrabRig.touching(GrabRig.walk(Vector2.ZERO, yaw), move)


# The placement itself, by the aim line of DEC-0045 §2: with the centered configuration the
# target's axis is on the line that leaves the attacker's point O along the camera's direction,
# at the asked distance centre to centre, and that line passes over the attacker's own axis.
func test_the_placement_puts_the_target_on_the_centered_aim_line_dead_ahead_of_the_body(
	yaw: float,
	distance: float,
	_test_parameters := [[0.0, 0.9], [0.0, 2.4], [1.1, 1.5], [-2.0, 2.5]],
) -> void:
	var config := _center(60)
	if config == null:
		return
	var target := _on_the_aim_line(ELSEWHERE, yaw, distance, config.aim_side)
	var origin := Aim.origin(ELSEWHERE, yaw, config.aim_height, config.aim_side)
	var forward := Aim.direction(yaw, 0.0)
	var from_origin := Vector3(target.x - origin.x, 0.0, target.z - origin.z)
	assert_float(absf(from_origin.cross(forward).y)).is_equal_approx(0.0, LINE_HAIR)
	assert_float(from_origin.dot(forward)).is_greater(0.0)
	assert_float(target.distance_to(ELSEWHERE)).is_equal_approx(distance, LINE_HAIR)
	assert_float(Vector2(origin.x - ELSEWHERE.x, origin.z - ELSEWHERE.z).length()) \
			.override_failure_message("the centered O is off the body's axis") \
			.is_equal_approx(0.0, LINE_HAIR)


# Criterion 3, the direction: on the first tick of the windup the swing's direction, action_yaw,
# is the camera's yaw, for the three moves, and the body looks along it. The direction is read on
# the state after the movement's slice (F-177).
func test_the_centered_camera_aims_the_swing_along_the_cameras_yaw(
	move: StringName,
	tickrate: int,
	yaw: float,
	_test_parameters := [
		[LIGHT, 60, 0.0],
		[LIGHT, 60, 1.1],
		[LIGHT, 30, -2.0],
		[CHARGED, 60, 0.0],
		[CHARGED, 60, -2.0],
		[CHARGED, 30, 1.1],
		[GUARD_BREAK, 60, 0.0],
		[GUARD_BREAK, 60, 1.1],
		[GUARD_BREAK, 60, -2.0],
	],
) -> void:
	var config := _center(tickrate)
	if config == null:
		return
	var fighter := _fighter(config)
	fighter.step(_press(move, yaw))
	assert_int(fighter.fought.action).override_failure_message("the %s did not begin" % move) \
			.is_equal(FighterState.Action.WINDUP)
	assert_str(String(fighter.fought.action_move)).is_equal(String(move))
	var state := fighter.state()
	var message := "camera %.6f: the %s points to %.6f and the body to %.6f" % [
		yaw,
		move,
		state.action_yaw,
		state.facing_yaw,
	]
	assert_float(_apart(state.action_yaw, yaw)).override_failure_message(message).is_less(HAIR)
	assert_float(_apart(state.facing_yaw, yaw)).override_failure_message(message).is_less(HAIR)


# Criterion 3, many ticks: through the whole windup, with the camera turning every tick, the
# swing's direction is the camera's yaw of that tick; from the first tick after the windup to the
# move's end it stays the camera's yaw of the last windup tick, however the camera turns
# (combate.md, "O leve no tick": "A direção"). Each tick is told by the state entering it, on the
# combat's output.
func test_through_the_windup_the_centered_swing_follows_the_camera_and_then_stays(
	move: StringName,
	_test_parameters := [[LIGHT], [CHARGED], [GUARD_BREAK]],
) -> void:
	var config := _center(60)
	if config == null:
		return
	var fighter := _fighter(config)
	var violations: Array[String] = []
	var windup_ticks := 0
	var later_ticks := 0
	var fixed := 0.0
	for offset: int in LONGEST_SWING_TICKS + SPARE_TICKS:
		var yaw := FIRST_YAW + YAW_STEP * offset
		fighter.step(_press(move, yaw) if offset == 0 else GrabRig.idle(yaw))
		var fought := fighter.fought
		if fought.action == FighterState.Action.NONE:
			break
		if fought.action == FighterState.Action.WINDUP:
			windup_ticks += 1
			fixed = yaw
			if _apart(fought.action_yaw, yaw) > HAIR:
				violations.append(
					"windup tick %d: swing %.6f, camera %.6f" % [offset, fought.action_yaw, yaw]
				)
		else:
			later_ticks += 1
			if _apart(fought.action_yaw, fixed) > HAIR:
				violations.append(
					"tick %d: swing %.6f, expected fixed at %.6f"
					% [offset, fought.action_yaw, fixed]
				)
	assert_int(windup_ticks).override_failure_message("the %s had no windup" % move).is_greater(1)
	assert_int(later_ticks).override_failure_message("the %s never left the windup" % move) \
			.is_greater(1)
	assert_array(violations).override_failure_message(GrabRig.brief(violations)).is_empty()


# Criterion 3, one and the limit: with the crosshair on the axis of a target standing on the same
# floor, the light and the charged touch at 0,9 m and at 2,4 m, the sword's reach, and at the
# convergence itself, 2,0 m, with no compensation to the side.
func test_the_centered_sword_touches_the_target_on_the_crosshair_from_0_9_m_to_its_reach(
	move: StringName,
	tickrate: int,
	distance: float,
	_test_parameters := [
		[LIGHT, 60, NEAR_M],
		[LIGHT, 60, 2.0],
		[LIGHT, 60, SWORD_REACH_M],
		[LIGHT, 30, NEAR_M],
		[LIGHT, 30, SWORD_REACH_M],
		[CHARGED, 60, NEAR_M],
		[CHARGED, 60, 2.0],
		[CHARGED, 60, SWORD_REACH_M],
		[CHARGED, 30, NEAR_M],
		[CHARGED, 30, SWORD_REACH_M],
	],
) -> void:
	var config := _center(tickrate)
	if config == null:
		return
	var target := _on_the_aim_line(Vector3.ZERO, 0.0, distance, config.aim_side)
	var duel := _swing_at(move, config, Vector3.ZERO, 0.0, target)
	_assert_touched(
		duel,
		move,
		"centered, the target %.2f m away at %d ticks" % [distance, tickrate],
	)


# Criterion 3, the guard break: the hand grabs the target on the crosshair at 0,9 m, at its
# convergence, 1,2 m, and at 1,5 m, inside the 1,55 m a hand pointed straight at the target reaches.
func test_the_centered_guard_break_grabs_the_target_on_the_crosshair_from_0_9_m_to_its_reach(
	distance: float,
	_test_parameters := [[NEAR_M], [1.2], [HAND_REACH_M]],
) -> void:
	var config := _center(60)
	if config == null:
		return
	var target := _on_the_aim_line(Vector3.ZERO, 0.0, distance, config.aim_side)
	var duel := _swing_at(GUARD_BREAK, config, Vector3.ZERO, 0.0, target)
	_assert_touched(duel, GUARD_BREAK, "centered, the target %.2f m away" % distance)


# Criterion 3, failure: just past each move's reach the crosshair on the target is not enough: the
# sword misses at 2,5 m and the hand at 1,6 m.
func test_the_centered_moves_miss_a_target_just_past_their_reach(
	move: StringName,
	tickrate: int,
	distance: float,
	_test_parameters := [
		[LIGHT, 60, SWORD_PAST_M],
		[LIGHT, 30, SWORD_PAST_M],
		[CHARGED, 60, SWORD_PAST_M],
		[CHARGED, 30, SWORD_PAST_M],
		[GUARD_BREAK, 60, HAND_PAST_M],
	],
) -> void:
	var config := _center(tickrate)
	if config == null:
		return
	var target := _on_the_aim_line(Vector3.ZERO, 0.0, distance, config.aim_side)
	var duel := _swing_at(move, config, Vector3.ZERO, 0.0, target)
	_assert_missed(
		duel,
		move,
		"centered, the target %.2f m away at %d ticks" % [distance, tickrate],
	)


# Criterion 3, anywhere: the rule turns with the camera and moves with the body.
func test_the_centered_moves_touch_the_target_on_the_crosshair_from_any_feet_and_yaw(
	move: StringName,
	yaw: float,
	distance: float,
	_test_parameters := [
		[LIGHT, 1.1, NEAR_M],
		[LIGHT, -2.0, SWORD_REACH_M],
		[CHARGED, 2.5, NEAR_M],
		[CHARGED, -0.7, SWORD_REACH_M],
		[GUARD_BREAK, 1.1, NEAR_M],
		[GUARD_BREAK, -2.0, HAND_REACH_M],
	],
) -> void:
	var config := _center(60)
	if config == null:
		return
	var target := _on_the_aim_line(ELSEWHERE, yaw, distance, config.aim_side)
	var duel := _swing_at(move, config, ELSEWHERE, yaw, target)
	_assert_touched(duel, move, "centered, yaw %.1f, the target %.2f m away" % [yaw, distance])


func test_the_centered_moves_miss_past_their_reach_from_any_feet_and_yaw(
	move: StringName,
	yaw: float,
	distance: float,
	_test_parameters := [
		[LIGHT, 1.1, SWORD_PAST_M],
		[CHARGED, -2.0, SWORD_PAST_M],
		[GUARD_BREAK, 2.5, HAND_PAST_M],
	],
) -> void:
	var config := _center(60)
	if config == null:
		return
	var target := _on_the_aim_line(ELSEWHERE, yaw, distance, config.aim_side)
	var duel := _swing_at(move, config, ELSEWHERE, yaw, target)
	_assert_missed(duel, move, "centered, yaw %.1f, the target %.2f m away" % [yaw, distance])


# The difference the centered camera makes: at 0,9 m, nearer than the 1,11 m where the default
# camera's charged starts to touch, the charged with the crosshair on the target's axis misses
# under the shoulder of 0,8 m (movement_v0.tres) and needs compensation to the side; with the
# centered camera, the same crosshair on the same target touches.
func test_at_0_9_m_the_shoulder_cameras_charged_misses_and_the_centered_one_touches(
	tickrate: int,
	_test_parameters := [[60], [30]],
) -> void:
	assert_float(NEAR_M).is_less(CHARGED_NEAREST_UNDER_THE_SHOULDER_M)
	var shoulder := MovementRig.load_config(tickrate)
	assert_float(shoulder.aim_side).is_equal_approx(SHOULDER_M, HAIR)
	var beside := _on_the_aim_line(ELSEWHERE, FIRST_YAW, NEAR_M, shoulder.aim_side)
	var missed := _swing_at(CHARGED, shoulder, ELSEWHERE, FIRST_YAW, beside)
	_assert_missed(missed, CHARGED, "the shoulder camera, the target 0.90 m away")
	var config := _center(tickrate)
	if config == null:
		return
	var ahead := _on_the_aim_line(ELSEWHERE, FIRST_YAW, NEAR_M, config.aim_side)
	var touched := _swing_at(CHARGED, config, ELSEWHERE, FIRST_YAW, ahead)
	_assert_touched(touched, CHARGED, "the centered camera, the target 0.90 m away")
