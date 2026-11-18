# TASK-12.2 (partida.md, "O boneco que ataca"): Sozinho's dummy presses a light every 3 s, 180
# ticks at 60, turned toward whoever plays, and only through its input box: it does not walk, and
# its swings come out of the same core as anyone's. TASK-12.3 mixes the actions by a fixed hash of
# their number, the feint a charged cut by the guard button's press 24 ticks in and a light 4 ticks
# later (partida.md, "O boneco que ataca"); since TASK-12.4 the cycle is of 6, 2 lights, 2 charged,
# 1 feint and 1 guard break, with no tech (F-210 §1; DEC-0058).
# The real Match runs in Sozinho with netfox's ticks advanced by hand (test/support/
# netfox_ticks.gd; DEC-0027 §3).
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const GrabRig := preload("res://test/core/fighter/grab_rig.gd")
const MATCH_SCENE := preload("res://match/match.tscn")

## partida.md, "O boneco que ataca": "um golpe a cada 3 s, 180 ticks".
const PERIOD_TICKS := 180
## The flat floor west of the platform (charged_sync_test.gd): the dummy, and the player 1,05 m in
## front of it, down -Z, where the player's hand first touches it on its 4th active tick
## (combate.md, "A mão"): the contact comes 21 + 3 ticks after the press.
const DUMMY_FEET := Vector3(-6.0, 0.0, 6.0)
const PLAYER_FEET := Vector3(-6.0, 0.0, 4.95)
const GRAB_CONTACT_AFTER := 24
## combate.md, "O agarrão" and "O tech": held up to the contact + 23; without the tech, unable to
## act up to the contact + 75 (72 + 4).
const HELD_TICKS := 23
const VICTIM_FREE := 76
## movimento.md, "Câmera": the shoulder; combate.md, "A lâmina e o contato": "Convergência: 1,2 na
## quebra".
const SHOULDER_M := 0.8
const HAND_CONVERGENCE_M := 1.2
## combate.md, "A lâmina e o contato": the sword converges at 2,0 m.
const SWORD_CONVERGENCE_M := 2.0
## combate.md, "O bloqueio, a guarda andando e a stamina": "levanta a guarda em 100 ms (6 ticks)".
const GUARD_RAISE_TICKS := 6
## partida.md, "O boneco que ataca": the feint's guard press 24 ticks into the charged's windup,
## the light 4 ticks after it; the feint lasts 12 (combate.md, "A finta").
const FEINT_PRESS_TICKS := 24
const LIGHT_AFTER_FEINT_TICKS := 4
const FEINT_TICKS := 12
const HAIR := 1e-4


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


# A match with the player and the dummy at their spawn points, the dummy attacking, netfox's
# deferred setup done.
func _match() -> Match:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match: Match = auto_free(node)
	add_child(game_match)
	var me := multiplayer.get_unique_id()
	var player := game_match.spawn_fighter(Match.PLAYER_SLOT, me)
	var dummy := game_match.spawn_fighter(Match.DUMMY_SLOT, me)
	game_match.let_dummy_attack(dummy, player)
	await get_tree().process_frame
	await get_tree().physics_frame
	return game_match


func test_the_period_is_180_ticks_at_60_and_90_at_30() -> void:
	var game_match := await _match()
	assert_int(game_match.attacking_dummy.period_ticks).is_equal(PERIOD_TICKS)
	var player := game_match.fighter_at(Match.PLAYER_SLOT)
	var dummy := game_match.fighter_at(Match.DUMMY_SLOT)
	var at_30 := AttackingDummy.new(dummy, player, 0, 30)
	assert_int(at_30.period_ticks).is_equal(PERIOD_TICKS / 2)
	at_30.free()


# The dummy presses on every period after its first tick, never on that tick, and on no other.
func test_it_presses_once_every_period_from_its_first_tick() -> void:
	var game_match := await _match()
	var attacking := game_match.attacking_dummy
	var start := attacking.start_tick
	var presses: Array[int] = []
	for tick: int in range(start, start + 3 * PERIOD_TICKS + 1):
		if attacking.presses_at(tick):
			presses.append(tick - start)
	assert_array(presses).is_equal([PERIOD_TICKS, 2 * PERIOD_TICKS, 3 * PERIOD_TICKS])


# Over four periods the dummy starts an action on each, turned toward the player, and never moves:
# a light, a charged or a guard break by the hash of its number, a feint as a charged that becomes
# FEINT 24 ticks in and a light when the feint ends. It presses through its input box, and the core
# fires it, each move pointing through its own convergence (DEC-0058 §2).
func test_it_mixes_its_actions_toward_the_player_without_walking() -> void:
	var game_match := await _match()
	var player := game_match.fighter_at(Match.PLAYER_SLOT)
	var dummy := game_match.fighter_at(Match.DUMMY_SLOT)
	var attacking := game_match.attacking_dummy
	var spawn := dummy.position
	# The dummy aims like a person and its swing converges like a player's (DEC-0057 §4): the swing
	# points along the aim yaw turned by the move's convergence.
	var aim := AttackingDummy.aim_yaw(
		dummy.global_position,
		player.global_position,
		dummy.config.aim_side,
		dummy.state.facing_yaw,
	)
	var expected: Array[String] = []
	for k: int in range(1, 5):
		var at := k * PERIOD_TICKS
		match AttackingDummy.kind_of(k):
			AttackingDummy.Kind.LIGHT:
				expected.append("%d windup light_attack" % at)
			AttackingDummy.Kind.CHARGED:
				expected.append("%d windup charged_attack" % at)
			AttackingDummy.Kind.GUARD_BREAK:
				expected.append("%d windup guard_break" % at)
			AttackingDummy.Kind.FEINT:
				expected.append("%d windup charged_attack" % at)
				expected.append("%d feint" % (at + FEINT_PRESS_TICKS))
				var light_at := at + FEINT_PRESS_TICKS + FEINT_TICKS
				expected.append("%d windup light_attack" % light_at)
	var seen: Array[String] = []
	var before := dummy.state.copy()
	# Up to the light after a feint of the 4th action, the latest event the four can have.
	for _loop: int in 4 * PERIOD_TICKS + FEINT_PRESS_TICKS + FEINT_TICKS + 2:
		player.input.sample_frame(Vector2.ZERO, player.state.facing_yaw)
		NetfoxTicks.run_loop()
		var state := dummy.state
		var since := state.action_since - attacking.start_tick
		var began := state.action != before.action or state.action_since != before.action_since
		if began and state.action == FighterState.Action.WINDUP:
			seen.append("%d windup %s" % [since, state.action_move])
			var attack: AttackConfig = game_match.combat.attacks[state.action_move]
			var swing := Aim.swing_yaw(aim, dummy.config.aim_side, attack.aim_convergence)
			assert_float(angle_difference(state.action_yaw, swing)).is_equal_approx(0.0, HAIR)
		elif began and state.action == FighterState.Action.FEINT:
			seen.append("%d feint" % since)
		before = state.copy()
	assert_array(seen).is_equal(expected)
	assert_vector(dummy.position).is_equal_approx(spawn, Vector3.ONE * HAIR)


# The mix (partida.md, "O boneco que ataca"; F-210 §1): the kind of the k-th action is a pure
# function of k, 2 in 6 lights, 2 in 6 charged, 1 in 6 feints and 1 in 6 guard breaks over many
# actions, within a tenth of each share, and the first four already hold all four, so a session of
# a minute meets them all.
func test_the_mix_is_two_lights_two_charged_one_feint_and_one_guard_break_in_six() -> void:
	var counts: Dictionary[AttackingDummy.Kind, int] = {
		AttackingDummy.Kind.LIGHT: 0,
		AttackingDummy.Kind.CHARGED: 0,
		AttackingDummy.Kind.FEINT: 0,
		AttackingDummy.Kind.GUARD_BREAK: 0,
	}
	var actions := 1000
	for k: int in range(1, actions + 1):
		var kind := AttackingDummy.kind_of(k)
		assert_int(AttackingDummy.kind_of(k)).override_failure_message("k %d changed" % k) \
				.is_equal(kind)
		counts[kind] += 1
	var shares: Dictionary[AttackingDummy.Kind, float] = {
		AttackingDummy.Kind.LIGHT: 2.0 / 6.0,
		AttackingDummy.Kind.CHARGED: 2.0 / 6.0,
		AttackingDummy.Kind.FEINT: 1.0 / 6.0,
		AttackingDummy.Kind.GUARD_BREAK: 1.0 / 6.0,
	}
	for kind: AttackingDummy.Kind in shares:
		var expected := shares[kind] * actions
		var message := "%s: %d of %d" % [AttackingDummy.Kind.find_key(kind), counts[kind], actions]
		assert_float(float(counts[kind])).override_failure_message(message).is_between(
			expected * 0.9,
			expected * 1.1,
		)
	var first: Array[AttackingDummy.Kind] = []
	for k: int in range(1, 5):
		if not first.has(AttackingDummy.kind_of(k)):
			first.append(AttackingDummy.kind_of(k))
	assert_int(first.size()).override_failure_message("the first four lack a kind").is_equal(4)


# What each kind presses over its period: the light, the charged or the guard break on the period's
# tick; the feint the charged there, the guard's press 24 ticks later and the light 4 after that;
# nothing else, and never the tech.
func test_each_kind_presses_its_commands_on_their_ticks() -> void:
	var game_match := await _match()
	var attacking := game_match.attacking_dummy
	var start := attacking.start_tick
	assert_int(attacking.feint_press_ticks).is_equal(FEINT_PRESS_TICKS)
	assert_int(attacking.light_after_feint_ticks).is_equal(LIGHT_AFTER_FEINT_TICKS)
	var found: Dictionary[AttackingDummy.Kind, bool] = { }
	for k: int in range(1, 30):
		var kind := AttackingDummy.kind_of(k)
		found[kind] = true
		var expected: Dictionary[int, Array] = { }
		match kind:
			AttackingDummy.Kind.LIGHT:
				expected[0] = [FighterCommand.LIGHT_ATTACK]
			AttackingDummy.Kind.CHARGED:
				expected[0] = [FighterCommand.CHARGED_ATTACK]
			AttackingDummy.Kind.GUARD_BREAK:
				expected[0] = [FighterCommand.GUARD_BREAK]
			AttackingDummy.Kind.FEINT:
				expected[0] = [FighterCommand.CHARGED_ATTACK]
				expected[FEINT_PRESS_TICKS] = [&"guard"]
				expected[FEINT_PRESS_TICKS + LIGHT_AFTER_FEINT_TICKS] = [
					FighterCommand.LIGHT_ATTACK
				]
		for into: int in PERIOD_TICKS:
			var pressed := attacking.presses(start + k * PERIOD_TICKS + into)
			var wanted: Array = expected[into] if expected.has(into) else []
			var message := "action %d, tick %d into it: %s" % [k, into, pressed]
			assert_array(pressed).override_failure_message(message).is_equal(wanted)
	assert_int(found.size()).is_equal(4)
	assert_array(attacking.presses(start)).is_empty()


# The yaw toward a point follows the core's convention: yaw 0 looks down -Z, a positive yaw turns
# left (Blade.direction); on one axis the dummy keeps its own.
func test_the_yaw_toward_a_point_looks_at_it() -> void:
	var from := Vector3(1, 0, 1)
	for to: Vector3 in [Vector3(1, 0, -5), Vector3(-3, 2, 1), Vector3(4, 0, 5)]:
		var yaw := AttackingDummy.yaw_toward(from, to, 0.0)
		var flat := Vector3(to.x - from.x, 0.0, to.z - from.z).normalized()
		assert_vector(Blade.direction(yaw)).is_equal_approx(flat, Vector3.ONE * HAIR)
	assert_float(AttackingDummy.yaw_toward(from, from + Vector3.UP, 0.7)).is_equal(0.7)


# The player and the dummy 1,05 m apart, the dummy attacking, netfox's deferred setup done; with
# only_guard_breaks, the dummy of --dummy=guard_break; with holds_guard, the one of --dummy=block.
func _match_close(only_guard_breaks := false, holds_guard := false) -> Match:
	var node := MATCH_SCENE.instantiate()
	assert(node is Match, "match.tscn must have a Match at its root")
	var game_match: Match = auto_free(node)
	add_child(game_match)
	var me := multiplayer.get_unique_id()
	var player := game_match.spawn_fighter(Match.PLAYER_SLOT, me)
	var dummy := game_match.spawn_fighter(Match.DUMMY_SLOT, me)
	player.position = PLAYER_FEET
	dummy.position = DUMMY_FEET
	game_match.let_dummy_attack(dummy, player, only_guard_breaks, holds_guard)
	await get_tree().process_frame
	await get_tree().physics_frame
	return game_match


# TASK-12.4 (partida.md, "A mistura do boneco": "O boneco nunca dá o tech"; F-210 §1): the player
# grabs the dummy 10 ticks before the dummy's third action, its guard break, so that action falls
# inside the hold, where the press would be the tech. The dummy leaves it out: no tech_tick, still
# GRABBED past the hold, and acting again only on the contact + 76.
func test_the_dummy_never_techs_the_guard_break_its_mix_schedules_in_a_hold() -> void:
	assert_int(AttackingDummy.kind_of(3)).is_equal(AttackingDummy.Kind.GUARD_BREAK)
	var game_match := await _match_close()
	var player := game_match.fighter_at(Match.PLAYER_SLOT)
	var dummy := game_match.fighter_at(Match.DUMMY_SLOT)
	var attacking := game_match.attacking_dummy
	var scheduled := attacking.start_tick + 3 * PERIOD_TICKS
	assert_array(attacking.presses(scheduled)).is_equal([FighterCommand.GUARD_BREAK])
	var contact := scheduled - 10
	var press := contact - GRAB_CONTACT_AFTER
	# The player's hand down +Z, at the dummy behind it.
	var hand := GrabRig.camera_for(PI, SHOULDER_M, HAND_CONVERGENCE_M)
	var tech_ticks: Array[int] = []
	while NetworkTime.tick <= contact + VICTIM_FREE:
		player.input.sample_frame(Vector2.ZERO, hand)
		if NetworkTime.tick == press:
			player.input.press_guard_break()
		NetfoxTicks.run_loop()
		var shown := NetworkTime.tick - 1
		if GrabRig.tech_tick(dummy.state) != FighterState.NEVER:
			tech_ticks.append(shown)
		if shown == contact + HELD_TICKS + 7:
			assert_bool(GrabRig.is_grabbed(dummy.state)) \
					.override_failure_message("past the hold the dummy is %s"
			% GrabRig.line(dummy.state)) \
					.is_true()
	assert_int(GrabRig.grabbed_tick(dummy.state)) \
			.override_failure_message("the player did not grab the dummy on %d" % contact) \
			.is_equal(contact)
	assert_array(tech_ticks).override_failure_message("the dummy teched").is_empty()
	assert_int(dummy.state.action).override_failure_message(GrabRig.line(dummy.state)).is_not_equal(
		FighterState.Action.GRABBED
	)


# TASK-12.4 (partida.md, "A mistura do boneco": "o `--dummy=guard_break` faz o boneco dar só
# quebras, uma a cada 3 s"; F-212): the training dummy presses the guard break on every period's
# tick and nothing else, where the mix lights, charges or feints; the match's own dummy keeps the
# mix.
func test_the_training_dummy_presses_only_a_guard_break_every_period() -> void:
	var game_match := await _match()
	assert_bool(game_match.attacking_dummy.only_guard_breaks).is_false()
	var player := game_match.fighter_at(Match.PLAYER_SLOT)
	var dummy := game_match.fighter_at(Match.DUMMY_SLOT)
	var training: AttackingDummy = auto_free(AttackingDummy.new(dummy, player, 0, 60, true))
	assert_bool(training.only_guard_breaks).is_true()
	assert_int(training.period_ticks).is_equal(PERIOD_TICKS)
	var mixed: Dictionary[AttackingDummy.Kind, bool] = { }
	for k: int in range(1, 30):
		mixed[AttackingDummy.kind_of(k)] = true
		assert_int(training.kind_at(k)).is_equal(AttackingDummy.Kind.GUARD_BREAK)
		for into: int in PERIOD_TICKS:
			var pressed := training.presses(k * PERIOD_TICKS + into)
			var wanted: Array = [FighterCommand.GUARD_BREAK] if into == 0 else []
			var message := "action %d, tick %d into it: %s" % [k, into, pressed]
			assert_array(pressed).override_failure_message(message).is_equal(wanted)
	assert_int(mixed.size()).override_failure_message("the mix it leaves out").is_equal(4)
	assert_array(training.presses(0)).is_empty()


# The training dummy never techs either (partida.md, "A mistura do boneco": "O boneco nunca dá o
# tech"): the player grabs it 10 ticks before its first guard break, which falls inside the hold,
# and the dummy leaves it out, still GRABBED past the hold.
func test_the_training_dummy_never_techs_the_guard_break_it_throws_in_a_hold() -> void:
	var game_match := await _match_close(true)
	var player := game_match.fighter_at(Match.PLAYER_SLOT)
	var dummy := game_match.fighter_at(Match.DUMMY_SLOT)
	var attacking := game_match.attacking_dummy
	var scheduled := attacking.start_tick + PERIOD_TICKS
	assert_array(attacking.presses(scheduled)).is_equal([FighterCommand.GUARD_BREAK])
	var contact := scheduled - 10
	var press := contact - GRAB_CONTACT_AFTER
	var hand := GrabRig.camera_for(PI, SHOULDER_M, HAND_CONVERGENCE_M)
	var tech_ticks: Array[int] = []
	while NetworkTime.tick <= contact + HELD_TICKS + 7:
		player.input.sample_frame(Vector2.ZERO, hand)
		if NetworkTime.tick == press:
			player.input.press_guard_break()
		NetfoxTicks.run_loop()
		if GrabRig.tech_tick(dummy.state) != FighterState.NEVER:
			tech_ticks.append(NetworkTime.tick - 1)
	assert_int(GrabRig.grabbed_tick(dummy.state)) \
			.override_failure_message("the player did not grab the dummy on %d" % contact) \
			.is_equal(contact)
	assert_array(tech_ticks).override_failure_message("the dummy teched").is_empty()
	assert_bool(GrabRig.is_grabbed(dummy.state)) \
			.override_failure_message("past the hold the dummy is %s" % GrabRig.line(dummy.state)) \
			.is_true()


# TASK-12.4 (partida.md, "A mistura do boneco": "o `--dummy=block` faz o boneco segurar a guarda";
# F-213): the dummy that holds its guard presses the guard button once, on its first tick, the
# button's edge, and no command ever after; no action of its own begins on any period.
func test_the_blocking_dummy_presses_the_guard_on_its_first_tick_and_nothing_after() -> void:
	var game_match := await _match()
	assert_bool(game_match.attacking_dummy.holds_guard).override_failure_message("the mix blocks") \
			.is_false()
	var player := game_match.fighter_at(Match.PLAYER_SLOT)
	var dummy := game_match.fighter_at(Match.DUMMY_SLOT)
	var start := 40
	var blocking: AttackingDummy = auto_free(
		AttackingDummy.new(dummy, player, start, 60, false, true)
	)
	assert_bool(blocking.holds_guard).is_true()
	assert_bool(blocking.only_guard_breaks).is_false()
	assert_array(blocking.presses(start)).is_equal([&"guard"])
	for tick: int in range(start - 5, start + 3 * PERIOD_TICKS + FEINT_PRESS_TICKS + 10):
		assert_bool(blocking.presses_at(tick)).override_failure_message("an action on %d" % tick) \
				.is_false()
		if tick != start:
			assert_array(blocking.presses(tick)) \
					.override_failure_message("a press on %d" % tick) \
					.is_empty()


# In the match, over more than a period, the blocking dummy's input box holds the guard on every
# tick, shows the guard's press on its first tick alone, and never an attack, a parry or a guard
# break; it aims at the player as a person does, its guard rises in 6 ticks and stays, and it does
# not walk (combate.md, "O bloqueio, a guarda andando e a stamina").
func test_the_blocking_dummy_holds_the_guard_on_every_tick_and_never_attacks() -> void:
	var game_match := await _match_close(false, true)
	var player := game_match.fighter_at(Match.PLAYER_SLOT)
	var dummy := game_match.fighter_at(Match.DUMMY_SLOT)
	var attacking := game_match.attacking_dummy
	assert_bool(attacking.holds_guard).is_true()
	var start := attacking.start_tick
	var spawn := dummy.position
	var aim := AttackingDummy.aim_yaw(
		dummy.global_position,
		player.global_position,
		dummy.config.aim_side,
		dummy.state.facing_yaw,
	)
	var press_ticks: Array[int] = []
	var open_ticks: Array[int] = []
	var attack_ticks: Array[int] = []
	var low_ticks: Array[int] = []
	while NetworkTime.tick <= start + PERIOD_TICKS + FEINT_PRESS_TICKS + FEINT_TICKS:
		player.input.sample_frame(Vector2.ZERO, player.state.facing_yaw)
		NetfoxTicks.run_loop()
		var shown := NetworkTime.tick - 1
		var box := dummy.input.to_tick_input()
		if box.guard_press:
			press_ticks.append(shown - start)
		if not box.guard:
			open_ticks.append(shown - start)
		if box.light_attack or box.charged_attack or box.parry or box.guard_break:
			attack_ticks.append(shown - start)
		if shown >= start + GUARD_RAISE_TICKS and dummy.state.action != FighterState.Action.BLOCK:
			low_ticks.append(shown - start)
		assert_float(angle_difference(box.yaw, aim)).is_equal_approx(0.0, HAIR)
	assert_array(press_ticks).override_failure_message("the guard's press: %s" % [press_ticks]) \
			.is_equal([0])
	assert_array(open_ticks).override_failure_message("guard let go on %s" % [open_ticks]) \
			.is_empty()
	assert_array(attack_ticks).override_failure_message("it attacked on %s" % [attack_ticks]) \
			.is_empty()
	assert_array(low_ticks).override_failure_message("the guard is down on %s" % [low_ticks]) \
			.is_empty()
	assert_vector(dummy.position).is_equal_approx(spawn, Vector3.ONE * HAIR)


# What the mode is for (F-213): the player's light stops on the blocking dummy's guard, which takes
# no damage; the player's guard break goes through it and grabs; held, the dummy keeps the button
# down and never techs, stays GRABBED up to the contact + 75, and its guard is up again by itself 6
# ticks after it can act (combate.md, "A guarda andando").
func test_the_blocking_dummy_blocks_a_light_is_grabbed_and_raises_its_guard_again() -> void:
	var game_match := await _match_close(false, true)
	var player := game_match.fighter_at(Match.PLAYER_SLOT)
	var dummy := game_match.fighter_at(Match.DUMMY_SLOT)
	var health := dummy.state.health
	var sword := GrabRig.camera_for(PI, SHOULDER_M, SWORD_CONVERGENCE_M)
	var hand := GrabRig.camera_for(PI, SHOULDER_M, HAND_CONVERGENCE_M)
	var light := NetworkTime.tick + 20
	var blocked := false
	while NetworkTime.tick <= light + 60:
		player.input.sample_frame(Vector2.ZERO, sword)
		if NetworkTime.tick == light:
			player.input.press_light_attack()
		NetfoxTicks.run_loop()
		blocked = blocked or dummy.state.action == FighterState.Action.BLOCKSTUN
	assert_bool(blocked) \
			.override_failure_message("the light was not blocked: %s" % GrabRig.line(dummy.state)) \
			.is_true()
	assert_int(dummy.state.health).override_failure_message("a blocked light hurt").is_equal(health)
	assert_int(dummy.state.action).is_equal(FighterState.Action.BLOCK)
	var press := NetworkTime.tick + 5
	var contact := press + GRAB_CONTACT_AFTER
	var tech_ticks: Array[int] = []
	var open_ticks: Array[int] = []
	while NetworkTime.tick <= contact + VICTIM_FREE - 1:
		player.input.sample_frame(Vector2.ZERO, hand)
		if NetworkTime.tick == press:
			player.input.press_guard_break()
		NetfoxTicks.run_loop()
		if GrabRig.tech_tick(dummy.state) != FighterState.NEVER:
			tech_ticks.append(NetworkTime.tick - 1)
		if not dummy.input.to_tick_input().guard:
			open_ticks.append(NetworkTime.tick - 1)
	assert_int(GrabRig.grabbed_tick(dummy.state)) \
			.override_failure_message("the guard stopped the guard break") \
			.is_equal(contact)
	assert_array(tech_ticks).override_failure_message("the dummy teched").is_empty()
	assert_array(open_ticks).override_failure_message("held, it let the guard go").is_empty()
	assert_bool(GrabRig.is_grabbed(dummy.state)) \
			.override_failure_message("on the contact + 75: %s" % GrabRig.line(dummy.state)) \
			.is_true()
	while NetworkTime.tick <= contact + VICTIM_FREE + GUARD_RAISE_TICKS:
		player.input.sample_frame(Vector2.ZERO, hand)
		NetfoxTicks.run_loop()
	assert_int(dummy.state.action).override_failure_message(GrabRig.line(dummy.state)) \
			.is_equal(FighterState.Action.BLOCK)
	assert_int(dummy.state.action_since).is_equal(contact + VICTIM_FREE)
