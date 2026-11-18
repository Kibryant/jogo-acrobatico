# TASK-12.4: the numbers of the guard break, the grab, the tech and the dodge as design data,
# converted once at load (DEC-0004, rule 3; DEC-0058). combat_v0.tres gains the guard break
# (combate.md, "Os golpes e as defesas", the row "Quebra de guarda"; "A lâmina e o contato": the
# hand and the convergence) and the grab's numbers (combate.md, "A quebra de guarda e o tech", "O
# tranco e a vantagem" and "O hitstop e o tremor"); movement_v0.tres gains the dash's invulnerable
# window (movimento.md, "Dash": "Invulnerabilidade"); tokens_v0.tres gains the guard break's windup
# (visual-e-audio.md, "Os três canais por estado"). CombatConfig and MovementConfig turn every ms
# into the nearest tick, ties up (core/time/ticks.gd), at 60 ticks, the game's rate (DEC-0024), and
# at 30, netfox's default. Every number is cited next to its value; the arithmetic is marked.
extends GdUnitTestSuite

const COMBAT_V0 := "res://data/combat_v0.tres"
const MOVEMENT_V0 := "res://data/movement_v0.tres"
const TOKENS_V0 := "res://data/tokens_v0.tres"
const HAIR := 1e-9 # floating-point slack, not a design number

const GUARD_BREAK := &"guard_break" # combate.md, "A quebra, o tech e a esquiva no tick"
const LIGHT := &"light_attack"
const CHARGED := &"charged_attack"

# combate.md, "Os golpes e as defesas", the row "Quebra de guarda": 350 / 100 / 400 ms, "15, no
# início", dano 0; "A lâmina e o contato": "a mão em linha reta até 1,2 m", "Convergência: 1,2 na
# quebra".
const WINDUP_MS := 350
const ACTIVE_MS := 100
const RECOVERY_MS := 400
const COST := 15.0
const DAMAGE := 0
const HAND_REACH_M := 1.2
const CONVERGENCE_M := 1.2
# combate.md, "A quebra de guarda e o tech": "os dois ficam presos 333 ms (20 ticks)"; "O hitstop e
# o tremor", the row "Quebra pega": "os dois, 67 ms, 4 ticks; 100 ms, 0,5°"; "O tranco e a
# vantagem", the rows "Quebra sem tech": "1.200 ms, 72 ticks", and "Quebra com tech": "quem
# respondeu +2", the 33 ms of For Honor (F-173 §1 C09).
const HOLD_MS := 333
const GRAB_HITSTOP_MS := 67
const GRABBED_STUN_MS := 1200
const TECH_ADVANTAGE_MS := 33
const GRAB_SHAKE_MS := 100
const GRAB_SHAKE_DEG := 0.5
# movimento.md, "Dash": "Invulnerabilidade: dos ticks 3 a 10 dos 12"; combate.md, "Os golpes e as
# defesas", the row "Esquiva": "invulnerável de 50 a 167"; "Duração: 200".
const INVULNERABLE_FROM_MS := 50
const INVULNERABLE_TO_MS := 167
const DASH_MS := 200
# visual-e-audio.md, "Os três canais por estado": "Quebra de guarda, preparação: a mão em vermelhão
# desde o tick 0"; "Ativo: Vermelhão #D55E00".
const VERMILION := Color("#D55E00")
const COLOUR_HAIR := 0.002 # a channel stored in eight bits, not a design number

# By hand, the nearest tick with ties up (DEC-0022). At 60: 350 ms are 21 ticks, 100 are 6, 400
# are 24, 1.200 are 72, exact; 333 are 19,98, so 20; 67 are 4,02, so 4; 33 are 1,98, so 2; 50 are
# 3, exact; 167 are 10,02, so 10. At 30: 350 ms are 10,5, the tie, up to 11; 100 are 3, 400 are
# 12, 1.200 are 36, exact; 333 are 9,99, so 10; 67 are 2,01, so 2; 33 are 0,99, so 1; 50 are 1,5,
# the tie, up to 2; 167 are 5,01, so 5. The design's own ticks at 60: "21 / 6 / 24", "20", "4",
# "72", "+2", "ticks 3 a 10".
const WINDUP_TICKS: Dictionary[int, int] = { 30: 11, 60: 21 }
const ACTIVE_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
const RECOVERY_TICKS: Dictionary[int, int] = { 30: 12, 60: 24 }
const HOLD_TICKS: Dictionary[int, int] = { 30: 10, 60: 20 }
const GRAB_HITSTOP_TICKS: Dictionary[int, int] = { 30: 2, 60: 4 }
const GRABBED_STUN_TICKS: Dictionary[int, int] = { 30: 36, 60: 72 }
const TECH_ADVANTAGE_TICKS: Dictionary[int, int] = { 30: 1, 60: 2 }
const INVULNERABLE_FROM_TICK: Dictionary[int, int] = { 30: 2, 60: 3 }
const INVULNERABLE_TO_TICK: Dictionary[int, int] = { 30: 5, 60: 10 }

## The grab's times of CombatData, in ms (TASK-12.4 plan).
const GRAB_TIME_FIELDS: Array[String] = [
	"grab_hold_ms",
	"grab_hitstop_ms",
	"grabbed_stun_ms",
	"tech_advantage_ms",
	"grab_shake_ms",
]
## The flags of a sword move, all off for the guard break: no armor, no parry, no feint (combate.md,
## "A quebra de guarda e o tech": "a quebra não tem armadura"; "O parry": "Só apara o carregado").
const SWORD_FLAGS: Array[String] = [
	"pays_on_release",
	"armor",
	"breaks_armor",
	"parryable",
	"feintable",
	"vertical_cut",
]


func _load_v0() -> CombatData:
	var resource: Resource = load(COMBAT_V0)
	assert(resource is CombatData, "%s must load as a CombatData" % COMBAT_V0)
	return resource as CombatData


# A deep copy of combat_v0.tres, its moves included: load() caches the resource, so each case
# changes a duplicate and the baseline stays intact for every other test of the run.
func _v0_copy() -> CombatData:
	var copy: Resource = _load_v0().duplicate(true)
	assert(copy is CombatData, "a duplicate of %s must still be a CombatData" % COMBAT_V0)
	var data := copy as CombatData
	for move: StringName in [LIGHT, CHARGED, GUARD_BREAK]:
		var attack: Resource = data.attack(move).duplicate()
		assert(attack is AttackData, "a duplicate of an AttackData must still be an AttackData")
		data.set(move, attack)
	return data


func _load_movement_v0() -> MovementData:
	var resource: Resource = load(MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MOVEMENT_V0)
	return resource as MovementData


func _movement_copy() -> MovementData:
	var copy: Resource = _load_movement_v0().duplicate()
	assert(copy is MovementData, "a duplicate of %s must still be a MovementData" % MOVEMENT_V0)
	return copy as MovementData


func _guard_break_of(combat: CombatConfig) -> AttackConfig:
	assert_bool(combat.attacks.has(GUARD_BREAK)) \
			.override_failure_message("attacks must be keyed by %s, got %s"
	% [GUARD_BREAK, combat.attacks.keys()]) \
			.is_true()
	return combat.attacks[GUARD_BREAK]


func _assert_some_message_names(errors: PackedStringArray, field: String) -> void:
	var named := false
	for message: String in errors:
		if message.contains(field):
			named = true
	var unnamed := "no message names %s, got: %s" % [field, errors]
	assert_bool(named).override_failure_message(unnamed).is_true()


func test_combat_v0_holds_the_guard_break_and_still_passes_the_data_check() -> void:
	var data := _load_v0()
	assert_object(data.guard_break).override_failure_message("no guard_break").is_not_null()
	assert_array(data.validate()).is_empty()
	assert_array(_v0_copy().validate()).is_empty()


# combate.md, the row "Quebra de guarda" and "A lâmina e o contato": its phases, its cost paid on
# its fire, no damage, the hand that grabs with its reach, its convergence, and no sword flag.
func test_combat_v0_holds_the_guard_breaks_times_cost_hand_and_convergence() -> void:
	var guard_break := _load_v0().guard_break
	assert_int(guard_break.windup_ms).is_equal(WINDUP_MS)
	assert_int(guard_break.active_ms).is_equal(ACTIVE_MS)
	assert_int(guard_break.recovery_ms).is_equal(RECOVERY_MS)
	assert_float(guard_break.stamina_cost).is_equal_approx(COST, HAIR)
	assert_int(guard_break.damage).is_equal(DAMAGE)
	assert_bool(guard_break.grab).is_true()
	assert_float(guard_break.hand_reach_m).is_equal_approx(HAND_REACH_M, HAIR)
	assert_float(guard_break.aim_convergence_m).is_equal_approx(CONVERGENCE_M, HAIR)
	for flag: String in SWORD_FLAGS:
		var value: Variant = guard_break.get(flag)
		var lit := "guard_break.%s is %s" % [flag, value]
		assert_bool(value is bool and not value).override_failure_message(lit).is_true()
	# Neither sword move grabs.
	assert_bool(_load_v0().light_attack.grab).is_false()
	assert_bool(_load_v0().charged_attack.grab).is_false()


# combate.md, "A quebra de guarda e o tech", "O hitstop e o tremor" and "O tranco e a vantagem":
# the hold, the grab's hitstop, the stun without the tech, the tech's advantage and the shake.
func test_combat_v0_holds_the_grab_numbers() -> void:
	var data := _load_v0()
	assert_int(data.grab_hold_ms).is_equal(HOLD_MS)
	assert_int(data.grab_hitstop_ms).is_equal(GRAB_HITSTOP_MS)
	assert_int(data.grabbed_stun_ms).is_equal(GRABBED_STUN_MS)
	assert_int(data.tech_advantage_ms).is_equal(TECH_ADVANTAGE_MS)
	assert_int(data.grab_shake_ms).is_equal(GRAB_SHAKE_MS)
	assert_float(data.grab_shake_deg).is_equal_approx(GRAB_SHAKE_DEG, HAIR)


func test_the_guard_break_times_become_21_6_24_ticks_at_60_and_11_3_12_at_30(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var guard_break := _guard_break_of(CombatConfig.create(_load_v0(), tickrate))
	assert_int(guard_break.windup_ticks).is_equal(WINDUP_TICKS[tickrate])
	assert_int(guard_break.active_ticks).is_equal(ACTIVE_TICKS[tickrate])
	assert_int(guard_break.recovery_ticks).is_equal(RECOVERY_TICKS[tickrate])
	assert_float(guard_break.stamina_cost).is_equal_approx(COST, HAIR)
	assert_bool(guard_break.grab).is_true()
	assert_float(guard_break.hand_reach).is_equal_approx(HAND_REACH_M, HAIR)
	assert_float(guard_break.aim_convergence).is_equal_approx(CONVERGENCE_M, HAIR)


# The grab's times by hand: 20 / 4 / 72 / 2 at 60, and 10 / 2 / 36 / 1 at 30.
func test_the_grab_times_become_ticks_at_60_and_30(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var combat := CombatConfig.create(_load_v0(), tickrate)
	assert_int(combat.grab_hold_ticks).is_equal(HOLD_TICKS[tickrate])
	assert_int(combat.grab_hitstop_ticks).is_equal(GRAB_HITSTOP_TICKS[tickrate])
	assert_int(combat.grabbed_stun_ticks).is_equal(GRABBED_STUN_TICKS[tickrate])
	assert_int(combat.tech_advantage_ticks).is_equal(TECH_ADVANTAGE_TICKS[tickrate])
	# The rounding: 333 ms are 19 980 and 33 ms 1 980 in the units of core/time/ticks.gd at 60, both
	# below a whole tick's half above, so up to 20 and 2; at 30, 9 990 and 990, so 10 and 1.
	assert_int(Ticks.from_ms(HOLD_MS, tickrate)).is_equal(HOLD_TICKS[tickrate])
	assert_int(Ticks.from_ms(TECH_ADVANTAGE_MS, tickrate)).is_equal(TECH_ADVANTAGE_TICKS[tickrate])


# The guard break is keyed by its ID, the command the slot holds (FighterCommand.GUARD_BREAK), and
# the data finds it by that command.
func test_the_guard_break_is_keyed_by_its_id_and_found_by_its_command() -> void:
	var data := _load_v0()
	assert_str(String(FighterCommand.GUARD_BREAK)).is_equal(String(GUARD_BREAK))
	assert_object(data.attack(FighterCommand.GUARD_BREAK)).is_same(data.guard_break)
	var combat := CombatConfig.create(data, 60)
	assert_bool(combat.attacks.has(GUARD_BREAK)).is_true()
	assert_array(CombatConfig.MOVES).is_equal([LIGHT, CHARGED, GUARD_BREAK])


func test_a_combat_without_the_guard_break_is_rejected_naming_it() -> void:
	var data := _v0_copy()
	data.guard_break = null
	var errors := data.validate()
	assert_array(errors).is_not_empty()
	_assert_some_message_names(errors, "guard_break")


# Failure: a negative grab time is rejected, and a message names its field; a negative shake too.
func test_a_negative_grab_number_is_rejected_naming_its_field(
	field: String,
	_test_parameters := [
		["grab_hold_ms"],
		["grab_hitstop_ms"],
		["grabbed_stun_ms"],
		["tech_advantage_ms"],
		["grab_shake_ms"],
		["grab_shake_deg"],
	],
) -> void:
	var data := _v0_copy()
	var value: Variant = -1.0 if field == "grab_shake_deg" else -1
	data.set(field, value)
	assert_that(data.get(field)).override_failure_message("%s is not a CombatData field" % field) \
			.is_equal(value)
	var errors := data.validate()
	assert_array(errors).override_failure_message("%s = %s must fail" % [field, value]) \
			.is_not_empty()
	_assert_some_message_names(errors, field)


# Limit: a grab time of 0 ms is legal, as every time the rules do not divide by.
func test_a_grab_time_of_0_ms_passes(
	field: String,
	_test_parameters := [["grab_hold_ms"], ["grab_hitstop_ms"], ["tech_advantage_ms"]],
) -> void:
	var data := _v0_copy()
	data.set(field, 0)
	assert_array(data.validate()).is_empty()
	assert_int(GRAB_TIME_FIELDS.find(field)).is_greater_equal(0)


# Failure: the hand of a move that grabs must reach, and the message names the move's field; a move
# that does not grab never reads its reach, so 0 passes there.
func test_a_hand_of_no_reach_is_rejected_on_the_guard_break_and_ignored_on_the_sword() -> void:
	var data := _v0_copy()
	data.guard_break.hand_reach_m = 0.0
	var errors := data.validate()
	assert_array(errors).is_not_empty()
	_assert_some_message_names(errors, "guard_break.hand_reach_m")
	var sword := _v0_copy()
	sword.light_attack.hand_reach_m = 0.0
	sword.charged_attack.hand_reach_m = 0.0
	assert_array(sword.validate()).is_empty()


# movimento.md, "Dash": "Invulnerabilidade": movement_v0.tres holds the window of 50 to 167 ms
# and still passes the data check.
func test_movement_v0_holds_the_dodge_window_of_50_to_167_ms_and_passes_the_data_check() -> void:
	var data := _load_movement_v0()
	assert_int(data.dash_invulnerable_from_ms).is_equal(INVULNERABLE_FROM_MS)
	assert_int(data.dash_invulnerable_to_ms).is_equal(INVULNERABLE_TO_MS)
	assert_int(data.dash_ms).is_equal(DASH_MS)
	assert_array(data.validate()).is_empty()


# The window in the dash's own ticks: the 3rd to the 10th of the 12 at 60, the 2nd to the 5th of
# the 6 at 30, the tie of 1,5 going up.
func test_the_dodge_window_becomes_the_dash_ticks_3_to_10_at_60_and_2_to_5_at_30(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var config := MovementConfig.create(_load_movement_v0(), tickrate)
	assert_int(config.dash_invulnerable_from_tick).is_equal(INVULNERABLE_FROM_TICK[tickrate])
	assert_int(config.dash_invulnerable_to_tick).is_equal(INVULNERABLE_TO_TICK[tickrate])
	assert_int(config.dash_invulnerable_to_tick).is_less_equal(config.dash_ticks)
	assert_int(Ticks.from_ms(INVULNERABLE_FROM_MS, tickrate)).is_equal(
		INVULNERABLE_FROM_TICK[tickrate]
	)


# Failure: a window that closes before it opens and a negative opening are rejected, each naming
# its field. A window that closes with the dash, or past it, passes: the dash's own end closes it,
# so no number of the window is impossible against the dash's length.
func test_an_impossible_dodge_window_is_rejected_naming_its_field() -> void:
	var closes_first := _movement_copy()
	closes_first.dash_invulnerable_to_ms = closes_first.dash_invulnerable_from_ms - 1
	_assert_some_message_names(closes_first.validate(), "dash_invulnerable_to_ms")
	var negative := _movement_copy()
	negative.dash_invulnerable_from_ms = -1
	_assert_some_message_names(negative.validate(), "dash_invulnerable_from_ms")
	var negative_end := _movement_copy()
	negative_end.dash_invulnerable_to_ms = -1
	_assert_some_message_names(negative_end.validate(), "dash_invulnerable_to_ms")
	var with_the_dash := _movement_copy()
	with_the_dash.dash_invulnerable_to_ms = with_the_dash.dash_ms
	assert_array(with_the_dash.validate()).is_empty()
	var past_the_dash := _movement_copy()
	past_the_dash.dash_invulnerable_to_ms = past_the_dash.dash_ms + 1
	assert_array(past_the_dash.validate()).is_empty()


# visual-e-audio.md, "Os três canais por estado": the guard break's windup in vermilion, with a pose
# and a HUD shape of its own, apart from the eight tokens before it.
func test_tokens_v0_holds_the_guard_break_windup_in_vermilion_with_its_own_pose_and_shape() -> void:
	var resource: Resource = load(TOKENS_V0)
	assert(resource is TokensData, "%s must load as a TokensData" % TOKENS_V0)
	var tokens := resource as TokensData
	var token := tokens.guard_break_windup
	assert_object(token).override_failure_message("no guard_break_windup").is_not_null()
	if token == null:
		return
	var colours := [[token.color.r, VERMILION.r], [token.color.g, VERMILION.g]]
	colours.append_array([[token.color.b, VERMILION.b], [token.color.a, VERMILION.a]])
	for pair: Array in colours:
		var stored: float = pair[0]
		var design: float = pair[1]
		assert_float(stored).is_equal_approx(design, COLOUR_HAIR)
	# The pose names the hand (visual-e-audio.md, "A quebra na cápsula"): the sword rests.
	assert_str(String(token.pose)).is_equal("hand")
	assert_str(String(token.hud_shape)).is_equal("arrow")
	var others: Array[TokenData] = [
		tokens.light_windup,
		tokens.active,
		tokens.guard,
		tokens.reaction,
		tokens.charged_windup,
		tokens.parry,
		tokens.feint,
		tokens.parried,
	]
	for other: TokenData in others:
		assert_str(String(other.pose)).is_not_equal(String(token.pose))
		assert_str(String(other.hud_shape)).is_not_equal(String(token.hud_shape))
