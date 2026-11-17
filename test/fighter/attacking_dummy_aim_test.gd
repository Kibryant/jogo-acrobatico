# Criterion 4 of TASK-12.14: the dummy aims like a person (partida.md, "O boneco que ataca";
# combate.md, "A espada na mira": "O boneco e o bot miram como gente"; DEC-0057 §4). The yaw it
# sends puts its own aim line, the one that leaves its point O along the camera's direction
# (DEC-0045 §2), on the other's axis: AttackingDummy.aim_yaw(from, to, side, otherwise) is the yaw
# from its feet to the other's feet plus asin(side / distance), with the distance on the floor's
# plane greater than the shoulder; nearer, the feet-to-feet yaw alone; on one spot, `otherwise`,
# as in yaw_toward. It only produces input (DEC-0022), so its swing converges like a player's: a
# charged of the dummy against whoever stands still in front of it, from 1,2 to 2,3 m, touches.
# Three levels: the pure function; the core's sandwich with the dummy's yaw as input (ChargedRig
# under a Duel); and the real Match in Sozinho, netfox's ticks advanced by hand
# (test/support/netfox_ticks.gd; DEC-0027 §3), as in attacking_dummy_test.gd.
extends GdUnitTestSuite

const ChargedRig := preload("res://test/core/fighter/charged_rig.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")
const Duel := preload("res://test/core/fighter/duel.gd")
const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

const SHOULDER_M := 0.8 # movimento.md, "Câmera": "Ombro", 0,8 m to the right
const CONVERGENCE_M := 2.0 # combate.md, "A lâmina e o contato": "Convergência", 2,0 m
const AIM_HEIGHT_M := 1.6 # movimento.md, "Câmera": "Altura do pivô"
## partida.md, "O boneco que ataca": "um golpe a cada 3 s, 180 ticks".
const PERIOD_TICKS := 180
# combate.md, "Os golpes e as defesas": the charged's 42 / 7 / 27 ticks and the light's 15 / 6 / 12
# at 60; the charged takes 30 and the light 12; partida.md, "A vida sem partida": vida 100.
const CHARGED_TICKS := Vector3i(42, 7, 27)
const LIGHT_TICKS := Vector3i(15, 6, 12)
const CHARGED_DAMAGE := 30
const LIGHT_DAMAGE := 12
const MAX_HEALTH := 100
const CHARGED := &"charged_attack"
const LIGHT := &"light_attack"
# The fighters by name, the photo's key (DEC-0051 §1); the player first by name.
const PLAYER := &"A"
const DUMMY := &"B"
const TICKRATE := 60
const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts
const PRESS_AFTER_START := 10 # arithmetic
const SPARE_TICKS := 6 # arithmetic
const HAIR := 1e-6 # floating-point slack, not a design number
const YAW_HAIR := 1e-4 # the slack attacking_dummy_test.gd gives the dummy's yaw on screen
# Positions are single-precision vectors: 10 µm of slack on a distance to the aim line and the
# same in rad on a yaw worked out from them, not a design number.
const LINE_HAIR := 1e-5
# Any feet off the axes, and a target at another height: only the floor's plane counts.
const FROM := Vector3(1.0, 0.0, 1.0)
const STEP_UP := Vector3(0.0, 0.7, 0.0)
# In the Match: the flat floor west of the platform (charged_sync_test.gd), the dummy looking
# down -Z at the player 1,5 m ahead of it, at (-6; 0; 4,5) (TASK-12.14, criterion 4: "de 1,2 m a
# 2,3 m").
const DUMMY_FEET := Vector3(-6.0, 0.0, 6.0)
const APART_M := 1.5
# partida.md, "A mistura do boneco": the first four hold every kind, the guard break's included
# since TASK-12.4 (F-210 §1).
const ACTIONS := 4
# combate.md, "A lâmina e o contato": "Convergência: 1,2 na quebra"; "A mão": with the crosshair on
# the target's axis the hand grabs "de 0,88 a 1,48 m", so the player 1,5 m away is out of its reach.
const HAND_CONVERGENCE_M := 1.2
const LAST_ACTION_TICKS := 120 # loops after the fourth action begins, past its contact: arithmetic


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


# A point `distance` metres from `from` on the floor's plane, at `bearing` rad of yaw.
func _at(from: Vector3, bearing: float, distance: float) -> Vector3:
	return from + Blade.direction(bearing) * distance


# How far the axis of `to` is from the aim line of whoever stands at `from` with the camera on
# yaw, on the floor's plane: the line leaves the point O along the camera's direction.
func _off_the_aim_line(from: Vector3, yaw: float, to: Vector3, side: float) -> float:
	var origin := Aim.origin(from, yaw, AIM_HEIGHT_M, side)
	var forward := Aim.direction(yaw, 0.0)
	var step := Vector3(to.x - origin.x, 0.0, to.z - origin.z)
	return absf(step.cross(forward).y)


func _ahead_of_the_aim(from: Vector3, yaw: float, to: Vector3, side: float) -> float:
	var origin := Aim.origin(from, yaw, AIM_HEIGHT_M, side)
	var step := Vector3(to.x - origin.x, 0.0, to.z - origin.z)
	return step.dot(Aim.direction(yaw, 0.0))


# Many: at every distance of the criterion and beyond, at any bearing, the dummy's aim line
# passes through the other's axis, ahead of the dummy, whatever the other's height.
func test_the_aim_yaw_puts_the_dummys_aim_line_on_the_others_axis(
	distance: float,
	bearing: float,
	_test_parameters := [
		[1.2, 0.0],
		[1.5, 0.0],
		[1.84, 1.1],
		[2.0, -2.0],
		[2.3, 2.9],
		[1.2, -0.6],
		[2.3, PI],
		[0.9, 0.4],
		[10.0, -1.3],
	],
) -> void:
	for to: Vector3 in [_at(FROM, bearing, distance), _at(FROM, bearing, distance) + STEP_UP]:
		var yaw := AttackingDummy.aim_yaw(FROM, to, SHOULDER_M, 0.0)
		var off := _off_the_aim_line(FROM, yaw, to, SHOULDER_M)
		var message := "%.2f m away at bearing %.2f: yaw %.4f leaves the axis %.4f m off" % [
			distance,
			bearing,
			yaw,
			off,
		]
		assert_float(off).override_failure_message(message).is_equal_approx(0.0, LINE_HAIR)
		assert_float(_ahead_of_the_aim(FROM, yaw, to, SHOULDER_M)) \
				.override_failure_message("the other is behind the dummy's aim") \
				.is_greater(0.0)


# The count itself (DEC-0057 §4): the feet-to-feet yaw plus asin(side / distance): the dummy turns
# to the left of the other, so that its right shoulder's line falls on it.
func test_the_aim_yaw_is_the_feet_to_feet_yaw_plus_asin_of_side_over_distance(
	distance: float,
	bearing: float,
	_test_parameters := [[1.2, 0.0], [1.5, 1.1], [2.0, -2.0], [2.3, 0.4]],
) -> void:
	var to := _at(FROM, bearing, distance)
	var toward := AttackingDummy.yaw_toward(FROM, to, 0.0)
	var yaw := AttackingDummy.aim_yaw(FROM, to, SHOULDER_M, 0.0)
	var message := "%.2f m away: aim %.6f, feet to feet %.6f" % [distance, yaw, toward]
	assert_float(angle_difference(toward, yaw)).override_failure_message(message).is_equal_approx(
		asin(SHOULDER_M / distance),
		LINE_HAIR,
	)


# The dummy's swing then points at the other: aiming like a person and converging like a person,
# at 2,0 m the swing's direction is the feet-to-feet yaw exactly, the blade's tip on the axis.
func test_at_the_convergence_the_dummys_swing_points_at_the_others_axis() -> void:
	var to := _at(FROM, 0.7, CONVERGENCE_M)
	var yaw := AttackingDummy.aim_yaw(FROM, to, SHOULDER_M, 0.0)
	var swing := Aim.swing_yaw(yaw, SHOULDER_M, CONVERGENCE_M)
	assert_float(angle_difference(swing, AttackingDummy.yaw_toward(FROM, to, 0.0))) \
			.is_equal_approx(0.0, LINE_HAIR)


# Limit: at a distance not greater than the shoulder no aim line can pass over the other, and the
# dummy looks from its feet to the other's feet, as yaw_toward does.
func test_within_the_shoulder_the_aim_yaw_is_the_feet_to_feet_yaw(
	step: Vector3,
	_test_parameters := [
		[Vector3(0.0, 0.0, -0.79)],
		[Vector3(0.79, 0.0, 0.0)],
		[Vector3(0.0, 0.0, -0.5)],
		[Vector3(0.3, 0.0, 0.4)],
		[Vector3(-0.05, 2.0, 0.05)],
	],
) -> void:
	var to := FROM + step
	var yaw := AttackingDummy.aim_yaw(FROM, to, SHOULDER_M, 0.3)
	var toward := AttackingDummy.yaw_toward(FROM, to, 0.3)
	var message := "step %s: aim %.6f, feet to feet %.6f" % [step, yaw, toward]
	assert_bool(is_finite(yaw)).override_failure_message(message).is_true()
	assert_float(angle_difference(toward, yaw)).override_failure_message(message).is_equal_approx(
		0.0,
		LINE_HAIR,
	)


# Limit: a hair beyond the shoulder the line already passes over the other, a turn close to 90°.
func test_a_hair_beyond_the_shoulder_the_aim_line_is_on_the_axis() -> void:
	var to := _at(FROM, 0.0, SHOULDER_M + 0.01)
	var yaw := AttackingDummy.aim_yaw(FROM, to, SHOULDER_M, 0.0)
	assert_float(_off_the_aim_line(FROM, yaw, to, SHOULDER_M)).is_equal_approx(0.0, LINE_HAIR)


# None: on one spot, or one above the other, there is no yaw to find and the dummy keeps the one
# it is given, as in yaw_toward.
func test_on_one_spot_the_aim_yaw_is_the_one_given() -> void:
	assert_float(AttackingDummy.aim_yaw(FROM, FROM, SHOULDER_M, 0.7)).is_equal(0.7)
	assert_float(AttackingDummy.aim_yaw(FROM, FROM + Vector3.UP, SHOULDER_M, -1.2)).is_equal(-1.2)


# The shoulder is an argument: with none the aim line leaves the axis and the yaw is the
# feet-to-feet one; with half of it the turn is asin(0,4 / distance).
func test_the_aim_yaw_follows_the_side_it_is_given() -> void:
	var to := _at(FROM, -0.9, 1.5)
	var toward := AttackingDummy.yaw_toward(FROM, to, 0.0)
	var none := AttackingDummy.aim_yaw(FROM, to, 0.0, 0.0)
	assert_float(angle_difference(toward, none)).is_equal_approx(0.0, LINE_HAIR)
	var half := AttackingDummy.aim_yaw(FROM, to, 0.4, 0.0)
	assert_float(angle_difference(toward, half)).is_equal_approx(asin(0.4 / 1.5), LINE_HAIR)
	assert_float(_off_the_aim_line(FROM, half, to, 0.4)).is_equal_approx(0.0, LINE_HAIR)


# Criterion 4, in the core: a fighter whose input yaw is the dummy's, every tick, swings at a
# player standing still `distance` metres from it, at any bearing. Returns the duel, the player
# at index 0 and the dummy at index 1, run to past the swing's end.
func _dummy_swings(move: StringName, distance: float, bearing: float) -> Duel:
	var combat := ChargedRig.load_combat(TICKRATE)
	var movement := MovementRig.load_config(TICKRATE)
	var player_feet := _at(FROM, bearing, distance)
	var yaw := AttackingDummy.aim_yaw(FROM, player_feet, movement.aim_side, 0.0)
	var press := FIRST_TICK + PRESS_AFTER_START
	var duel := Duel.new()
	duel.add(
		ChargedRig.new(PLAYER, movement, combat, FIRST_TICK, player_feet, bearing + PI),
		func(_tick: int) -> TickInput:
			return ChargedRig.idle(bearing + PI),
	)
	duel.add(
		ChargedRig.new(DUMMY, movement, combat, FIRST_TICK, FROM, yaw),
		func(tick: int) -> TickInput:
			if tick != press:
				return ChargedRig.idle(yaw)
			if move == CHARGED:
				return ChargedRig.press_charged(Vector2.ZERO, yaw)
			return ChargedRig.press_light(Vector2.ZERO, yaw),
	)
	var phases := CHARGED_TICKS if move == CHARGED else LIGHT_TICKS
	duel.run_through(press + phases.x + phases.y + phases.z + SPARE_TICKS)
	return duel


# Criterion 4, many: the dummy's charged touches whoever stands still in front of it at 1,2, 1,5,
# 2,0 and 2,3 m, in its active phase, by the core's own stamp, and takes the charged's 30.
func test_the_dummys_charged_touches_a_player_standing_still_from_1_2_to_2_3_m(
	distance: float,
	bearing: float,
	_test_parameters := [[1.2, 0.0], [1.5, 0.0], [2.0, 0.0], [2.3, 0.0], [1.5, 2.2], [2.3, -1.0]],
) -> void:
	var duel := _dummy_swings(CHARGED, distance, bearing)
	var first_active := FIRST_TICK + PRESS_AFTER_START + CHARGED_TICKS.x
	var contact := duel.contact_tick_of(1)
	var message := "player %.2f m away: contact at %d, expected one from %d to %d" % [
		distance,
		contact,
		first_active,
		first_active + CHARGED_TICKS.y - 1,
	]
	assert_int(contact).override_failure_message(message).is_between(
		first_active,
		first_active + CHARGED_TICKS.y - 1,
	)
	if contact == FighterState.NEVER:
		return
	assert_str(String(duel.row_at(contact).fought[1].contact_target)).is_equal(String(PLAYER))
	assert_int(duel.row_at(contact + 1).fought[0].health).override_failure_message(message) \
			.is_equal(MAX_HEALTH - CHARGED_DAMAGE)


# The dummy's light converges too (combate.md, "A espada na mira": "o leve, de 0,80 a 2,42 m").
func test_the_dummys_light_touches_a_player_standing_still(
	distance: float,
	_test_parameters := [[1.0], [1.5], [2.3]],
) -> void:
	var duel := _dummy_swings(LIGHT, distance, 0.5)
	var first_active := FIRST_TICK + PRESS_AFTER_START + LIGHT_TICKS.x
	var contact := duel.contact_tick_of(1)
	assert_int(contact).override_failure_message("player %.2f m away: contact at %d"
	% [distance, contact]) \
			.is_between(first_active, first_active + LIGHT_TICKS.y - 1)
	if contact == FighterState.NEVER:
		return
	assert_int(duel.row_at(contact + 1).fought[0].health).is_equal(MAX_HEALTH - LIGHT_DAMAGE)


# A match with the dummy and the player standing 1,5 m apart on the flat floor, placed before
# netfox records its first state, the dummy attacking; or `apart` metres apart, the player straight
# down -Z from the dummy.
func _match(apart := APART_M) -> Match:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match: Match = auto_free(node)
	add_child(game_match)
	var me := multiplayer.get_unique_id()
	var player := game_match.spawn_fighter(Match.PLAYER_SLOT, me)
	var dummy := game_match.spawn_fighter(Match.DUMMY_SLOT, me)
	player.position = DUMMY_FEET + Vector3(0.0, 0.0, -apart)
	dummy.position = DUMMY_FEET
	game_match.let_dummy_attack(dummy, player)
	await get_tree().process_frame
	await get_tree().physics_frame
	return game_match


# Criterion 4, in the Match: over its first four actions, which hold a light, a charged, a feint
# and, since TASK-12.4, a guard break, the dummy's moves begin along the direction of a person
# aiming at the player: the yaw of aim_yaw, from its feet to the player's, turned by the move's
# convergence (DEC-0058 §2). Every charged it lets go takes 30 from the player standing still 1,5 m
# in front of it, and every light 12, the feint's light included; the guard break takes nothing and,
# 1,5 m away, grabs nobody; events are counted by the state entering them, against the loop before
# (F-187).
func test_in_the_match_the_dummys_swings_land_on_the_player_standing_in_front_of_it() -> void:
	var game_match := await _match()
	var player := game_match.fighter_at(Match.PLAYER_SLOT)
	var dummy := game_match.fighter_at(Match.DUMMY_SLOT)
	var apart := player.global_position.distance_to(dummy.global_position)
	assert_float(apart).override_failure_message("%.3f m apart" % apart) \
			.is_equal_approx(APART_M, 1e-3)
	assert_float(dummy.config.aim_side).is_equal_approx(SHOULDER_M, HAIR)
	var charged_expected := 0
	var lights_expected := 0
	for k: int in range(1, ACTIONS + 1):
		match AttackingDummy.kind_of(k):
			AttackingDummy.Kind.CHARGED:
				charged_expected += 1
			AttackingDummy.Kind.LIGHT, AttackingDummy.Kind.FEINT:
				lights_expected += 1
	assert_int(charged_expected).override_failure_message("no charged in the first four") \
			.is_greater(0)
	var windups := 0
	var hits_of_30 := 0
	var hits_of_12 := 0
	var dummy_before := dummy.state.copy()
	var player_before := player.state.copy()
	for _loop: int in ACTIONS * PERIOD_TICKS + LAST_ACTION_TICKS:
		player.input.sample_frame(Vector2.ZERO, player.state.facing_yaw)
		NetfoxTicks.run_loop()
		var state := dummy.state
		var began := (
			state.action != dummy_before.action or state.action_since != dummy_before.action_since
		)
		if began and state.action == FighterState.Action.WINDUP:
			windups += 1
			var aim := AttackingDummy.aim_yaw(
				dummy.global_position,
				player.global_position,
				dummy.config.aim_side,
				dummy_before.facing_yaw,
			)
			var convergence := CONVERGENCE_M
			if state.action_move == FighterCommand.GUARD_BREAK:
				convergence = HAND_CONVERGENCE_M
			var expected := aim - asin(SHOULDER_M / convergence)
			var message := "windup %d: the swing points to %.4f, expected %.4f" % [
				windups,
				state.action_yaw,
				expected,
			]
			assert_float(angle_difference(state.action_yaw, expected)) \
					.override_failure_message(message) \
					.is_equal_approx(0.0, YAW_HAIR)
		if player.state.hurt_tick != player_before.hurt_tick:
			var damage := player_before.health - player.state.health
			if damage == CHARGED_DAMAGE:
				hits_of_30 += 1
			elif damage == LIGHT_DAMAGE:
				hits_of_12 += 1
		dummy_before = state.copy()
		player_before = player.state.copy()
	var summary := "%d windups, %d hits of 30 (expected %d), %d hits of 12 (expected %d)" % [
		windups,
		hits_of_30,
		charged_expected,
		hits_of_12,
		lights_expected,
	]
	assert_int(hits_of_30).override_failure_message(summary).is_equal(charged_expected)
	assert_int(hits_of_12).override_failure_message(summary).is_equal(lights_expected)
	assert_int(player.state.grabbed_tick).override_failure_message("the player was grabbed") \
			.is_equal(FighterState.NEVER)
	assert_float(player.global_position.distance_to(dummy.global_position)) \
			.override_failure_message("the two moved") \
			.is_equal_approx(APART_M, 1e-3)


# TASK-12.4, the shoulder camera's check on the guard break (harness registry; combate.md, "A mão":
# "Com os dois no mesmo chão e a mira no eixo do alvo, a mão pega de 0,88 a 1,48 m"; DEC-0058 §2):
# in the real Match, the dummy aims at the player like a person and its hand converges at 1,2 m.
# Its third action is the guard break (partida.md, "A mistura do boneco"): it grabs the player
# standing still 1,2 m in front of it, where the hand crosses the aim line, and misses one 1,5 m
# away, beyond the 1,48.
func test_in_the_match_the_dummys_guard_break_grabs_at_1_2_m_and_misses_at_1_5_m(
	apart: float,
	grabs: bool,
	_test_parameters := [[1.2, true], [1.5, false]],
) -> void:
	assert_int(AttackingDummy.kind_of(3)).is_equal(AttackingDummy.Kind.GUARD_BREAK)
	var game_match := await _match(apart)
	var player := game_match.fighter_at(Match.PLAYER_SLOT)
	var dummy := game_match.fighter_at(Match.DUMMY_SLOT)
	var distance := player.global_position.distance_to(dummy.global_position)
	assert_float(distance).override_failure_message("%.3f m apart" % distance) \
			.is_equal_approx(apart, 1e-3)
	var guard_break: AttackConfig = game_match.combat.attacks[FighterCommand.GUARD_BREAK]
	var swing := guard_break.windup_ticks + guard_break.active_ticks + guard_break.recovery_ticks
	var held_on := FighterState.NEVER
	var breaks := 0
	var before := dummy.state.copy()
	for _loop: int in 3 * PERIOD_TICKS + swing + SPARE_TICKS:
		player.input.sample_frame(Vector2.ZERO, player.state.facing_yaw)
		NetfoxTicks.run_loop()
		var state := dummy.state
		var began := state.action != before.action or state.action_since != before.action_since
		if began and state.action == FighterState.Action.WINDUP:
			breaks += 1 if state.action_move == FighterCommand.GUARD_BREAK else 0
		if held_on == FighterState.NEVER and player.state.action == FighterState.Action.GRABBED:
			held_on = NetworkTime.tick - 1
		before = state.copy()
	assert_int(breaks).override_failure_message("the dummy's guard break never began").is_equal(1)
	var message := "%.2f m: grabbed_tick %d, held on %d" % [
		apart,
		player.state.grabbed_tick,
		held_on,
	]
	if grabs:
		assert_int(player.state.grabbed_tick).override_failure_message(message).is_not_equal(
			FighterState.NEVER
		)
		assert_int(held_on).override_failure_message(message).is_equal(
			player.state.grabbed_tick + 1
		)
	else:
		assert_int(player.state.grabbed_tick).override_failure_message(message).is_equal(
			FighterState.NEVER
		)
		assert_int(held_on).override_failure_message(message).is_equal(FighterState.NEVER)
