# Criterion 6 of TASK-12.3, and the core of criterion 9: the feint (glossario.md, "Finta" and
# "Aperto da guarda"; combate.md, "A finta" and "O carregado, o parry e a finta no tick": "A
# finta"; DEC-0056 §5; DEC-0016), through the public interface of core/fighter with the whole tick
# sandwich played by the ChargedRig. The guard button going down in the charged's windup, from the
# tick after the press to the 27th, with 15 on the bar, cuts the windup: FEINT for 12 ticks, the 15
# paid on that tick, the 25 of the charged never paid. On the press tick itself, after the 27th
# tick, without the 15, outside the charged's windup or with the button held since before the
# charged, the guard button does nothing beyond what the guard does. In the feint the presses wait
# in the slot, the body walks slowly and looks where the camera looks, and with the button still
# held the guard rises after the 12 ticks. Every number comes from docs/design, cited by section;
# ticks by hand from the ms, nearest tick with ties up.
extends GdUnitTestSuite

const ChargedRig := preload("res://test/core/fighter/charged_rig.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
const CHARGED := &"charged_attack" # glossario.md, "Golpe carregado"
const LIGHT := &"light_attack" # glossario.md, "Golpe leve"

# combate.md, "Os golpes e as defesas", the row "Finta": "corta a preparação do carregado até
# 450 ms; recupera 200", "até 27; 12" ticks at 60, "15, no aperto". By hand at 30: 450 ms are
# 13,5 ticks, the tie that goes up to 14, and 200 ms are 6. Fired at F, the guard button going
# down from F + 1 to F + 27 feints ("A finta": "do tick seguinte ao disparo até o tick 27").
const FEINT_UNTIL_TICKS: Dictionary[int, int] = { 30: 14, 60: 27 }
const FEINT_RECOVERY_TICKS: Dictionary[int, int] = { 30: 6, 60: 12 }
const FEINT_COST := 15.0
const BELOW_FEINT_COST := 14.5
# combate.md, "Os golpes e as defesas", the row "Golpe carregado": 42 / 7 / 27 ticks at 60 and
# 21 / 4 / 14 at 30, "25, pagos na soltura".
const WINDUP_TICKS: Dictionary[int, int] = { 30: 21, 60: 42 }
const ACTIVE_TICKS: Dictionary[int, int] = { 30: 4, 60: 7 }
const RECOVERY_TICKS: Dictionary[int, int] = { 30: 14, 60: 27 }
const CHARGED_COST := 25.0
# combate.md, "Os golpes e as defesas", the row "Golpe leve": 15 / 6 / 12 ticks at 60, 8 de
# stamina no início (DEC-0052).
const LIGHT_WINDUP_TICKS: Dictionary[int, int] = { 30: 8, 60: 15 }
const LIGHT_SWING_TICKS: Dictionary[int, int] = { 30: 17, 60: 33 }
const LIGHT_COST := 8.0
# combate.md, "O bloqueio, a guarda andando e a stamina": the guard rises in 6 ticks at 60, 3 at
# 30.
const GUARD_RAISE_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
# movimento.md, "Stamina": "Máximo: 100"; "Espera para recuperar: 800 ms", 48 ticks at 60 and 24
# at 30.
const STAMINA_MAX := 100.0
const STAMINA_WAIT_TICKS: Dictionary[int, int] = { 30: 24, 60: 48 }
# movimento.md, "Chão": "Andar devagar: com a guarda alta ou durante o carregado: 3 m/s"
# (combate.md, "O corpo na postura, na finta e em quem foi aparado": "o corpo anda devagar, como
# na guarda"); "Velocidade de corrida: 7 m/s"; "Tempo até a velocidade máxima: 150 ms", 9 ticks
# at 60.
const SLOW_WALK_MPS := 3.0
const RUN_SPEED_MPS := 7.0
const ACCEL_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }

const FORWARD := Vector2(0, 1) # move.y goes forward: yaw 0 looks down -Z (TASK-9 plan)
const HAIR := 1e-6 # floating-point slack, not a design number
const YAW_STEP := 0.05 # rad per tick the camera turns: arithmetic
const SPARE_TICKS := 6 # ticks a run keeps going past the last event: arithmetic
const PRESS_AFTER_START := 10 # ticks after FIRST_TICK the charged is pressed: arithmetic
const EARLY_IN_THE_WINDUP := 5 # ticks into the windup the feint comes, mid cases: arithmetic
const BAR_SET_AT := 3 # ticks into the windup the bar is set by hand: arithmetic


func _fighter(tickrate: int) -> ChargedRig:
	return ChargedRig.new(
		&"A",
		MovementRig.load_config(tickrate),
		ChargedRig.load_combat(tickrate),
		FIRST_TICK,
	)


func _swing_ticks(tickrate: int) -> int:
	return WINDUP_TICKS[tickrate] + ACTIVE_TICKS[tickrate] + RECOVERY_TICKS[tickrate]


func _line(state: FighterState) -> String:
	return "%s since %d with %s, paid at %d" % [
		FighterState.Action.find_key(state.action),
		state.action_since,
		state.action_move,
		state.stamina_spent_tick,
	]


func _assert_action(
	state: FighterState,
	action: FighterState.Action,
	since: int,
	move: StringName = &"",
) -> void:
	var message := "%s, expected %s since %d" % [
		_line(state),
		FighterState.Action.find_key(action),
		since,
	]
	assert_int(state.action).override_failure_message(message).is_equal(action)
	assert_int(state.action_since).override_failure_message(message).is_equal(since)
	if not move.is_empty():
		assert_str(String(state.action_move)).override_failure_message(message).is_equal(
			String(move)
		)


func _assert_none(state: FighterState) -> void:
	assert_int(state.action).override_failure_message(_line(state)).is_equal(
		FighterState.Action.NONE
	)


func _assert_slot(state: FighterState, command: StringName, buffered_tick: int) -> void:
	var slot := "slot holds (%s, %d), expected (%s, %d)" % [
		state.buffered_command,
		state.buffered_tick,
		command,
		buffered_tick,
	]
	assert_str(String(state.buffered_command)).override_failure_message(slot).is_equal(
		String(command)
	)
	assert_int(state.buffered_tick).override_failure_message(slot).is_equal(buffered_tick)


# Fires a charged now, the camera on yaw, and returns the tick it fired on.
func _fire(fighter: ChargedRig, input: TickInput = ChargedRig.press_charged()) -> int:
	var first := fighter.tick()
	fighter.step(input)
	_assert_action(fighter.fought, FighterState.Action.WINDUP, first, CHARGED)
	return first


# Idles, the guard held when `held`, until `tick` is the next to simulate, checking the windup of
# a charged fired at `first` on every tick.
func _windup_until(fighter: ChargedRig, first: int, tick: int, held := false) -> void:
	while fighter.tick() < tick:
		fighter.step(ChargedRig.hold_guard() if held else ChargedRig.idle())
		_assert_action(fighter.fought, FighterState.Action.WINDUP, first, CHARGED)
		var state := fighter.fought
		assert_int(state.stamina_spent_tick).override_failure_message(_line(state)) \
				.is_equal(FighterState.NEVER)


# Steps through a whole, unfeinted charged fired at `first` from where the fighter is, the guard
# held when `held`: the active since first + 42 with the 25 paid there, the recovery since
# first + 49, and NONE, or BLOCK with the button held, on first + 76.
func _assert_the_charged_goes_on(fighter: ChargedRig, first: int, held: bool) -> void:
	var active_from := first + WINDUP_TICKS[_tickrate_of(fighter)]
	var recovery_from := active_from + ACTIVE_TICKS[_tickrate_of(fighter)]
	var end := first + _swing_ticks(_tickrate_of(fighter))
	var violations: Array[String] = []
	while fighter.tick() < end:
		var tick := fighter.tick()
		fighter.step(ChargedRig.hold_guard() if held else ChargedRig.idle())
		var state := fighter.fought
		var expected := FighterState.Action.WINDUP
		var since := first
		if tick >= recovery_from:
			expected = FighterState.Action.RECOVERY
			since = recovery_from
		elif tick >= active_from:
			expected = FighterState.Action.ACTIVE
			since = active_from
		if state.action != expected or state.action_since != since:
			violations.append(
				"tick %d: %s, expected %s since %d"
				% [tick, _line(state), FighterState.Action.find_key(expected), since]
			)
		var paid := FighterState.NEVER if tick < active_from else active_from
		if state.stamina_spent_tick != paid:
			violations.append(
				"tick %d: paid at %d, expected %d" % [tick, state.stamina_spent_tick, paid]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	assert_float(fighter.stamina()).is_equal_approx(STAMINA_MAX - CHARGED_COST, HAIR)
	fighter.step(ChargedRig.hold_guard() if held else ChargedRig.idle())
	if held:
		fighter.step(ChargedRig.hold_guard())
		var after := fighter.fought
		var message := "%s after the swing's end at %d, expected BLOCK since %d or %d" % [
			_line(after),
			end,
			end,
			end + 1,
		]
		assert_int(after.action).override_failure_message(message).is_equal(
			FighterState.Action.BLOCK
		)
		assert_bool(after.action_since == end or after.action_since == end + 1) \
				.override_failure_message(message) \
				.is_true()
	else:
		_assert_none(fighter.fought)


static func _tickrate_of(fighter: ChargedRig) -> int:
	return fighter.config().tickrate


# Criterion 6: the guard button going down in the windup, from the tick after the press to the
# 27th tick, cuts the charged: FEINT from that tick for 12 ticks, the 15 paid there and the 25
# never, the body free again 12 ticks later, no active ever (combate.md, "A finta": "A ação vira
# FEINT desde esse tick, por 12 ticks, e os 15 saem nele. Os 25 do carregado nunca saem").
func test_a_guard_press_in_the_windup_feints_the_charged(
	tickrate: int,
	ticks_after_the_press: int,
	_test_parameters := [[60, 1], [60, 10], [60, 27], [30, 1], [30, 14]],
) -> void:
	var fighter := _fighter(tickrate)
	var first := _fire(fighter)
	var feint_tick := first + ticks_after_the_press
	assert_int(ticks_after_the_press).is_less_equal(FEINT_UNTIL_TICKS[tickrate])
	_windup_until(fighter, first, feint_tick)
	fighter.step(ChargedRig.press_guard())
	var feinted := fighter.fought
	_assert_action(feinted, FighterState.Action.FEINT, feint_tick)
	assert_int(feinted.stamina_spent_tick).override_failure_message(_line(feinted)).is_equal(
		feint_tick
	)
	assert_float(Stamina.at(feinted, fighter.config(), feint_tick)).is_equal_approx(
		STAMINA_MAX - FEINT_COST,
		HAIR,
	)
	var free_at := feint_tick + FEINT_RECOVERY_TICKS[tickrate]
	var last := first + _swing_ticks(tickrate) + SPARE_TICKS
	var violations: Array[String] = []
	while fighter.tick() <= last:
		var tick := fighter.tick()
		fighter.step(ChargedRig.idle())
		var state := fighter.fought
		if tick < free_at:
			if state.action != FighterState.Action.FEINT or state.action_since != feint_tick:
				violations.append(
					"tick %d: %s, expected FEINT since %d" % [tick, _line(state), feint_tick]
				)
		elif state.action != FighterState.Action.NONE:
			violations.append("tick %d: %s, expected NONE" % [tick, _line(state)])
		if state.stamina_spent_tick != feint_tick:
			violations.append(
				"tick %d: paid at %d after the feint" % [tick, state.stamina_spent_tick]
			)
		var bar := Stamina.at(state, fighter.config(), tick)
		if bar < STAMINA_MAX - FEINT_COST - HAIR:
			violations.append("tick %d: bar %.2f, the 25 were paid" % [tick, bar])
		if state.contact_tick != FighterState.NEVER:
			violations.append("tick %d: the feinted charged touched" % tick)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()


# Criterion 6, the limit: the guard button going down on the 28th tick after the press does not
# feint: the windup goes on, the 25 are paid on the first active tick and the charged runs to its
# end (combate.md, "A finta": "Depois do tick 27 [...] o aperto da guarda não faz nada além do que
# a guarda já faz").
func test_a_guard_press_after_the_27th_tick_does_not_feint(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var first := _fire(fighter)
	var press_tick := first + FEINT_UNTIL_TICKS[tickrate] + 1
	_windup_until(fighter, first, press_tick)
	fighter.step(ChargedRig.press_guard())
	_assert_action(fighter.fought, FighterState.Action.WINDUP, first, CHARGED)
	assert_int(fighter.fought.stamina_spent_tick).is_equal(FighterState.NEVER)
	_assert_the_charged_goes_on(fighter, first, false)


# Criterion 9: the guard button going down on the press tick itself, together with the charged,
# does not feint (combate.md, "A finta": "No próprio tick F, a finta é lida antes de o carregado
# sair da vaga: o aperto da guarda junto com o E não finta"); held from there, the button raises
# the guard again when the swing ends.
func test_a_guard_press_on_the_charged_press_tick_does_not_feint(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var first := _fire(fighter, ChargedRig.guard_going_down(ChargedRig.press_charged()))
	assert_int(fighter.fought.stamina_spent_tick).is_equal(FighterState.NEVER)
	_windup_until(fighter, first, first + FEINT_UNTIL_TICKS[tickrate] + 1, true)
	_assert_the_charged_goes_on(fighter, first, true)


# Criterion 9: whoever already held the guard when the charged began does not feint (combate.md,
# "A finta": "quem já segurava a guarda quando o carregado começou não finta sem querer"): the
# button down since the first tick, the charged fired from the guard, the button held through the
# whole windup, and the charged runs to its end, the guard back after it.
func test_a_guard_held_since_before_the_charged_does_not_feint(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var began := fighter.tick()
	fighter.step(ChargedRig.press_guard())
	_assert_action(fighter.fought, FighterState.Action.BLOCK, began)
	for _tick: int in GUARD_RAISE_TICKS[tickrate] + PRESS_AFTER_START:
		fighter.step(ChargedRig.hold_guard())
		_assert_action(fighter.fought, FighterState.Action.BLOCK, began)
	var first := _fire(fighter, ChargedRig.guarding(ChargedRig.press_charged()))
	_windup_until(fighter, first, first + FEINT_UNTIL_TICKS[tickrate] + 1, true)
	_assert_the_charged_goes_on(fighter, first, true)


# Criterion 6, the failure: without 15 on the bar the guard button does not feint, the windup goes
# on and nothing is paid; with exactly 15, the limit, it feints and the bar goes to 0 (combate.md,
# "A finta": "um guard_press com 15 de stamina na barra corta a preparação"). The bar is set by
# hand inside the windup, stamped there so it regains nothing before the button goes down; the run
# stops inside the windup, before the charged would have to pay.
func test_a_guard_press_without_15_stamina_does_not_feint_and_with_exactly_15_it_does(
	bar: float,
	feints: bool,
	_test_parameters := [[BELOW_FEINT_COST, false], [FEINT_COST, true]],
) -> void:
	var tickrate := 60
	var fighter := _fighter(tickrate)
	var first := _fire(fighter)
	var set_at := first + BAR_SET_AT
	var press_tick := first + EARLY_IN_THE_WINDUP + BAR_SET_AT
	var last := press_tick + FEINT_RECOVERY_TICKS[tickrate]
	assert_int(last).is_less(first + WINDUP_TICKS[tickrate])
	assert_int(last - set_at).is_less(STAMINA_WAIT_TICKS[tickrate])
	_windup_until(fighter, first, set_at)
	fighter.state().stamina_at_spend = bar
	fighter.state().stamina_spent_tick = set_at
	assert_float(fighter.stamina()).is_equal_approx(bar, HAIR)
	while fighter.tick() < press_tick:
		fighter.step(ChargedRig.idle())
		_assert_action(fighter.fought, FighterState.Action.WINDUP, first, CHARGED)
	fighter.step(ChargedRig.press_guard())
	if feints:
		_assert_action(fighter.fought, FighterState.Action.FEINT, press_tick)
		assert_int(fighter.fought.stamina_spent_tick).is_equal(press_tick)
		assert_float(Stamina.at(fighter.fought, fighter.config(), press_tick)).is_equal_approx(
			0.0,
			HAIR,
		)
		return
	_assert_action(fighter.fought, FighterState.Action.WINDUP, first, CHARGED)
	while fighter.tick() <= last:
		var tick := fighter.tick()
		fighter.step(ChargedRig.idle())
		_assert_action(fighter.fought, FighterState.Action.WINDUP, first, CHARGED)
		assert_int(fighter.fought.stamina_spent_tick).override_failure_message("paid with 14.5") \
				.is_equal(set_at)
		assert_float(Stamina.at(fighter.fought, fighter.config(), tick)).is_equal_approx(bar, HAIR)


# Criterion 6: in the feint the presses wait in the slot (combate.md, "A finta": "Na FEINT, os
# apertos esperam na vaga"): a light pressed in the feint fires on the first tick after its 12
# ticks, the feint's end tick, when still within the 150 ms.
func test_a_press_during_the_feint_waits_in_the_slot_and_fires_when_it_ends(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var first := _fire(fighter)
	var feint_tick := first + EARLY_IN_THE_WINDUP
	var free_at := feint_tick + FEINT_RECOVERY_TICKS[tickrate]
	var light_press := free_at - 3
	_windup_until(fighter, first, feint_tick)
	fighter.step(ChargedRig.press_guard())
	_assert_action(fighter.fought, FighterState.Action.FEINT, feint_tick)
	while fighter.tick() < free_at:
		var tick := fighter.tick()
		var input := ChargedRig.press_light() if tick == light_press else ChargedRig.idle()
		fighter.step(input)
		_assert_action(fighter.fought, FighterState.Action.FEINT, feint_tick)
		if tick >= light_press:
			_assert_slot(fighter.fought, FighterCommand.LIGHT_ATTACK, light_press)
		assert_int(fighter.fought.stamina_spent_tick).is_equal(feint_tick)
	fighter.step(ChargedRig.idle())
	_assert_action(fighter.fought, FighterState.Action.WINDUP, free_at, LIGHT)
	_assert_slot(fighter.fought, FighterCommand.NONE, FighterState.NEVER)
	assert_int(fighter.fought.stamina_spent_tick).is_equal(free_at)
	assert_float(Stamina.at(fighter.fought, fighter.config(), free_at)).is_equal_approx(
		STAMINA_MAX - FEINT_COST - LIGHT_COST,
		HAIR,
	)


# Criterion 6 (combate.md, "A finta": "Com o botão ainda segurado, a guarda sobe depois dos 12
# ticks"): the button held from the feint on, the guard is back when the feint ends, on the end
# tick or the one after, with that tick as its start; no guard inside the feint.
func test_after_the_feint_with_the_button_held_the_guard_rises(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var fighter := _fighter(tickrate)
	var first := _fire(fighter)
	var feint_tick := first + EARLY_IN_THE_WINDUP
	var free_at := feint_tick + FEINT_RECOVERY_TICKS[tickrate]
	_windup_until(fighter, first, feint_tick)
	fighter.step(ChargedRig.press_guard())
	_assert_action(fighter.fought, FighterState.Action.FEINT, feint_tick)
	while fighter.tick() < free_at:
		fighter.step(ChargedRig.hold_guard())
		_assert_action(fighter.fought, FighterState.Action.FEINT, feint_tick)
	fighter.step(ChargedRig.hold_guard())
	fighter.step(ChargedRig.hold_guard())
	var after := fighter.fought
	var message := "%s after the feint's end at %d, expected BLOCK since %d or %d" % [
		_line(after),
		free_at,
		free_at,
		free_at + 1,
	]
	assert_int(after.action).override_failure_message(message).is_equal(FighterState.Action.BLOCK)
	assert_bool(after.action_since == free_at or after.action_since == free_at + 1) \
			.override_failure_message(message) \
			.is_true()
	assert_int(after.stamina_spent_tick).override_failure_message("the guard paid").is_equal(
		feint_tick
	)


# Criterion 6, none: outside the charged's windup the guard button only does what the guard does
# (combate.md, "A finta": "fora da preparação do carregado, o aperto da guarda não faz nada além
# do que a guarda já faz"): standing idle it raises the guard, paying nothing; in a light's windup
# the light goes on; in the charged's active and recovery the charged goes on, and the guard rises
# after it.
func test_a_guard_press_outside_the_charged_windup_only_does_what_the_guard_does() -> void:
	var tickrate := 60
	var idle := _fighter(tickrate)
	var press := idle.tick()
	idle.step(ChargedRig.press_guard())
	_assert_action(idle.fought, FighterState.Action.BLOCK, press)
	assert_int(idle.fought.stamina_spent_tick).is_equal(FighterState.NEVER)
	var light := _fighter(tickrate)
	var light_first := light.tick()
	light.step(ChargedRig.press_light())
	_assert_action(light.fought, FighterState.Action.WINDUP, light_first, LIGHT)
	for _tick: int in EARLY_IN_THE_WINDUP:
		light.step(ChargedRig.idle())
	light.step(ChargedRig.press_guard())
	_assert_action(light.fought, FighterState.Action.WINDUP, light_first, LIGHT)
	assert_int(light.fought.stamina_spent_tick).is_equal(light_first)
	while light.tick() < light_first + LIGHT_SWING_TICKS[tickrate]:
		light.step(ChargedRig.idle())
		assert_int(light.fought.action).is_not_equal(FighterState.Action.FEINT)
	for into_the_swing: int in [
		WINDUP_TICKS[tickrate] + 2,
		WINDUP_TICKS[tickrate] + ACTIVE_TICKS[tickrate] + 5,
	]:
		var charged := _fighter(tickrate)
		var first := _fire(charged)
		var press_tick := first + into_the_swing
		while charged.tick() < press_tick:
			charged.step(ChargedRig.idle())
		charged.step(ChargedRig.press_guard())
		var pressed := charged.fought
		assert_int(pressed.action).override_failure_message(_line(pressed)).is_not_equal(
			FighterState.Action.FEINT
		)
		assert_str(String(pressed.action_move)).is_equal(String(CHARGED))
		assert_int(pressed.stamina_spent_tick).override_failure_message(_line(pressed)).is_equal(
			first + WINDUP_TICKS[tickrate]
		)
		_assert_the_charged_goes_on(charged, first, true)


# combate.md, "O corpo na postura, na finta e em quem foi aparado": "na postura e na finta, os
# comandos esperam na vaga, o corpo anda devagar, como na guarda, e a direção segue a câmera": a
# push held through the feint keeps the body at the slow walk of 3 m/s, the body looks where the
# camera looks on every tick of the feint, and the push runs past 3 once the feint is over.
func test_the_body_walks_slowly_and_looks_at_the_camera_during_the_feint() -> void:
	var tickrate := 60
	var fighter := _fighter(tickrate)
	var first := _fire(fighter, ChargedRig.press_charged(FORWARD))
	var feint_tick := first + EARLY_IN_THE_WINDUP
	var free_at := feint_tick + FEINT_RECOVERY_TICKS[tickrate]
	while fighter.tick() < feint_tick:
		fighter.step(ChargedRig.walk(FORWARD))
	var violations: Array[String] = []
	for offset: int in FEINT_RECOVERY_TICKS[tickrate]:
		var yaw := YAW_STEP * (offset + 1)
		var input := (
			ChargedRig.press_guard(FORWARD, yaw) if offset == 0 else ChargedRig.walk(FORWARD, yaw)
		)
		var plan := fighter.step(input)
		if fighter.fought.action != FighterState.Action.FEINT:
			violations.append("tick %d of the feint: %s" % [offset, _line(fighter.fought)])
		var speed := Vector3(plan.velocity.x, 0.0, plan.velocity.z).length()
		if speed > SLOW_WALK_MPS + HAIR:
			violations.append(
				"tick %d of the feint: %.3f m/s, over the slow walk" % [offset, speed]
			)
		if absf(plan.state.facing_yaw - yaw) > HAIR:
			violations.append(
				"tick %d of the feint: facing %.3f, camera %.3f"
				% [offset, plan.state.facing_yaw, yaw]
			)
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()
	assert_int(fighter.tick()).is_equal(free_at)
	for _tick: int in ACCEL_TICKS[tickrate]:
		fighter.step(ChargedRig.walk(FORWARD))
		_assert_none(fighter.fought)
	assert_float(fighter.horizontal_speed()).override_failure_message("still slow after it") \
			.is_greater(SLOW_WALK_MPS)
