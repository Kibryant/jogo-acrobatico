# TASK-12.2: the numbers of the guard, the stun, the hitstop and the tokens as design data,
# converted once at load (DEC-0004, rule 3; DEC-0055). combat_v0.tres gains the guard's raise and
# half angle (combate.md, "O bloqueio, a guarda andando e a stamina"; DEC-0054) and, on the light,
# the hitstun and the blockstun ("O tranco e a vantagem"), the two hitstops and the two camera
# shakes ("O hitstop e o tremor") and the block's stamina cost ("Os golpes e as defesas"); the
# CombatConfig turns every ms into the nearest tick, ties up (core/time/ticks.gd), at 60 ticks, the
# game's rate (DEC-0024), and at 30, netfox's default. tokens_v0.tres holds the colour, the pose
# and the HUD shape of the four states the duel reads so far (visual-e-audio.md, "Os três canais
# por estado"; DEC-0031). Every number is cited next to its value; the arithmetic is marked as such.
extends GdUnitTestSuite

const COMBAT_V0 := "res://data/combat_v0.tres"
const TOKENS_V0 := "res://data/tokens_v0.tres"
const HAIR := 1e-9 # floating-point slack, not a design number

## The move's ID the config keys the light attack by (glossario.md, "Golpe leve"; TASK-12.1 plan).
const LIGHT := &"light_attack"

# combate.md, "O bloqueio, a guarda andando e a stamina": "Segurar a tecla levanta a guarda em
# 100 ms (6 ticks)"; "ela bloqueia o golpe de quem está a até 90° de onde o corpo olha, medido no
# plano do chão" (DEC-0054 §2).
const GUARD_RAISE_MS := 100
const GUARD_HALF_ANGLE_DEG := 90.0
# combate.md, "O tranco e a vantagem", the rows "Leve acerta: 400 ms, 24 ticks" and "Leve
# bloqueado: 250 ms, 15 ticks".
const HITSTUN_MS := 400
const BLOCKSTUN_MS := 250
# combate.md, "O hitstop e o tremor", the rows "Leve acerta: 67 ms, 4 ticks; 100 ms, 0,5°, em quem
# levou" and "Leve bloqueado: 33 ms, 2 ticks; 100 ms, 0,3°, em quem bloqueou".
const HITSTOP_HIT_MS := 67
const HITSTOP_BLOCK_MS := 33
const HIT_SHAKE_MS := 100
const HIT_SHAKE_DEG := 0.5
const BLOCK_SHAKE_MS := 100
const BLOCK_SHAKE_DEG := 0.3
# combate.md, "Os golpes e as defesas", the row "Bloqueio": "5 por leve bloqueado".
const BLOCK_STAMINA_COST := 5.0

# By hand, the nearest tick with ties up (DEC-0022; visao-geral.md, "O tempo e a física no
# estado"). At 60 a tick is 16.7 ms: 100 ms are 6 ticks, 400 are 24 and 250 are 15, all exact;
# 67 ms are 4.02 ticks, rounded down to 4; 33 ms are 1.98, rounded up to 2. At 30 a tick is
# 33.3 ms: 100 ms are 3 and 400 are 12, exact; 250 ms are 7.5, the tie, which goes up to 8; 67 ms
# are 2.01, 2; 33 ms are 0.99, 1. The design's own ticks: "6", "24", "15", "4" and "2" at 60.
const GUARD_RAISE_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
const HITSTUN_TICKS: Dictionary[int, int] = { 30: 12, 60: 24 }
const BLOCKSTUN_TICKS: Dictionary[int, int] = { 30: 8, 60: 15 }
const HITSTOP_HIT_TICKS: Dictionary[int, int] = { 30: 2, 60: 4 }
const HITSTOP_BLOCK_TICKS: Dictionary[int, int] = { 30: 1, 60: 2 }
# The roundings in the units of core/time/ticks.gd (ms * tickrate, a whole tick being 1000):
# 67 * 60 = 4020, 4.02 ticks, below the half, so 4; 33 * 60 = 1980, 1.98 ticks, above the half, so
# 2; 33 * 30 = 990, 0.99 ticks, so 1; 250 * 30 = 7500, exactly 7.5, the tie that goes up to 8.
const ROUNDINGS: Array[Array] = [
	[HITSTOP_HIT_MS, 60, 4020, 4],
	[HITSTOP_BLOCK_MS, 60, 1980, 2],
	[HITSTOP_BLOCK_MS, 30, 990, 1],
	[BLOCKSTUN_MS, 30, 7500, 8],
]

# visual-e-audio.md, "Os três canais por estado": "Leve, preparação: Nenhuma: é o padrão";
# "Ativo: Vermelhão #D55E00 na lâmina e no rastro"; "Bloqueio: Nenhuma"; "Reação: Um flash
# branco". The colours are the Okabe-Ito's (F-053 §3.6). No colour is an alpha of 0 (TASK-12.2
# plan).
const VERMILION := Color("#D55E00")
const WHITE := Color.WHITE

# One impossible value per new number of the light (TASK-12.2 plan, AttackData): a negative time,
# a negative cost, a negative shake.
const ATTACK_IMPOSSIBLE: Dictionary[String, Variant] = {
	"hitstun_ms": -1,
	"blockstun_ms": -1,
	"hitstop_hit_ms": -1,
	"hitstop_block_ms": -1,
	"block_stamina_cost": -5.0,
	"hit_shake_ms": -1,
	"hit_shake_deg": -0.5,
	"block_shake_ms": -1,
	"block_shake_deg": -0.3,
}

# One impossible value per new number of the combat (TASK-12.2 plan, CombatData): a guard that
# rises in negative time, and a guard that covers a negative angle.
const COMBAT_IMPOSSIBLE: Dictionary[String, Variant] = {
	"guard_raise_ms": -1,
	"guard_half_angle_deg": -90.0,
}


func _load_v0() -> CombatData:
	var resource: Resource = load(COMBAT_V0)
	assert(resource is CombatData, "%s must load as a CombatData (TASK-12.1 plan)" % COMBAT_V0)
	return resource as CombatData


# A deep copy of combat_v0.tres, its attack included: load() caches the resource, so each case
# changes a duplicate and the baseline stays intact for every other test of the run.
func _v0_copy() -> CombatData:
	var copy: Resource = _load_v0().duplicate(true)
	assert(copy is CombatData, "a duplicate of %s must still be a CombatData" % COMBAT_V0)
	var data := copy as CombatData
	assert(data.light_attack != null, "%s must hold the light attack" % COMBAT_V0)
	var attack: Resource = data.light_attack.duplicate()
	assert(attack is AttackData, "a duplicate of an AttackData must still be an AttackData")
	data.light_attack = attack as AttackData
	return data


func _load_tokens() -> TokensData:
	var resource: Resource = load(TOKENS_V0)
	assert(resource is TokensData, "%s must load as a TokensData (TASK-12.2 plan)" % TOKENS_V0)
	return resource as TokensData


func _light_of(combat: CombatConfig) -> AttackConfig:
	assert_bool(combat.attacks.has(LIGHT)) \
			.override_failure_message("attacks must be keyed by %s, got %s"
	% [LIGHT, combat.attacks.keys()]) \
			.is_true()
	return combat.attacks[LIGHT]


func _assert_some_message_names(errors: PackedStringArray, field: String) -> void:
	var named := false
	for message: String in errors:
		if message.contains(field):
			named = true
	var unnamed := "no message names %s, got: %s" % [field, errors]
	assert_bool(named).override_failure_message(unnamed).is_true()


func _assert_no_colour(token: TokenData, which: String) -> void:
	assert_float(token.color.a).override_failure_message("%s has a colour: %s"
	% [which, token.color]) \
			.is_equal_approx(0.0, HAIR)


func _assert_colour(token: TokenData, expected: Color, which: String) -> void:
	var message := "%s is %s, expected %s" % [which, token.color, expected]
	assert_bool(token.color.is_equal_approx(expected)).override_failure_message(message).is_true()
	assert_float(token.color.a).override_failure_message(message).is_equal_approx(1.0, HAIR)


func test_combat_v0_still_passes_the_data_check_with_the_guard_numbers() -> void:
	assert_array(_load_v0().validate()).is_empty()
	assert_array(_v0_copy().validate()).is_empty()


# combate.md, "O bloqueio, a guarda andando e a stamina" and DEC-0054: the guard rises in 100 ms
# and covers 90° to each side of where the body looks.
func test_combat_v0_holds_the_guard_raise_and_the_half_angle() -> void:
	var data := _load_v0()
	assert_int(data.guard_raise_ms).is_equal(GUARD_RAISE_MS)
	assert_float(data.guard_half_angle_deg).is_equal_approx(GUARD_HALF_ANGLE_DEG, HAIR)


# combate.md, "O tranco e a vantagem", "O hitstop e o tremor" and "Os golpes e as defesas": the
# light's stun, hitstop, shake and block cost.
func test_combat_v0_holds_the_lights_stun_hitstop_shake_and_block_cost() -> void:
	var light := _load_v0().light_attack
	assert_int(light.hitstun_ms).is_equal(HITSTUN_MS)
	assert_int(light.blockstun_ms).is_equal(BLOCKSTUN_MS)
	assert_int(light.hitstop_hit_ms).is_equal(HITSTOP_HIT_MS)
	assert_int(light.hitstop_block_ms).is_equal(HITSTOP_BLOCK_MS)
	assert_float(light.block_stamina_cost).is_equal_approx(BLOCK_STAMINA_COST, HAIR)
	assert_int(light.hit_shake_ms).is_equal(HIT_SHAKE_MS)
	assert_float(light.hit_shake_deg).is_equal_approx(HIT_SHAKE_DEG, HAIR)
	assert_int(light.block_shake_ms).is_equal(BLOCK_SHAKE_MS)
	assert_float(light.block_shake_deg).is_equal_approx(BLOCK_SHAKE_DEG, HAIR)


# The design's own ticks at 60 (combate.md: "6", "24 ticks", "15 ticks", "4", "2") and the
# arithmetic at 30: 3 / 12 / 8 / 2 / 1.
func test_the_guard_and_stun_times_become_6_24_15_4_2_ticks_at_60_and_3_12_8_2_1_at_30(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var combat := CombatConfig.create(_load_v0(), tickrate)
	var light := _light_of(combat)
	assert_int(combat.guard_raise_ticks).is_equal(GUARD_RAISE_TICKS[tickrate])
	assert_int(light.hitstun_ticks).is_equal(HITSTUN_TICKS[tickrate])
	assert_int(light.blockstun_ticks).is_equal(BLOCKSTUN_TICKS[tickrate])
	assert_int(light.hitstop_hit_ticks).is_equal(HITSTOP_HIT_TICKS[tickrate])
	assert_int(light.hitstop_block_ticks).is_equal(HITSTOP_BLOCK_TICKS[tickrate])


# The roundings that are not exact: 67 ms at 60 is 4.02 ticks and goes down to 4; 33 ms at 60 is
# 1.98 and goes up to 2; 33 ms at 30 is 0.99 and goes up to 1; 250 ms at 30 is the tie of 7.5 that
# goes up to 8 (DEC-0022).
func test_the_hitstops_round_to_the_nearest_tick_and_the_blockstun_tie_goes_up() -> void:
	for rounding: Array in ROUNDINGS:
		var ms: int = rounding[0]
		var tickrate: int = rounding[1]
		var scaled: int = rounding[2]
		var expected: int = rounding[3]
		assert_int(ms * tickrate).override_failure_message("%d ms at %d" % [ms, tickrate]) \
				.is_equal(scaled)
		assert_int(Ticks.from_ms(ms, tickrate)) \
				.override_failure_message("%d ms at %d ticks" % [ms, tickrate]) \
				.is_equal(expected)


# Every new time follows Ticks.from_ms, whatever the number in the file.
func test_the_new_time_fields_follow_ticks_from_ms(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var data := _load_v0()
	var combat := CombatConfig.create(data, tickrate)
	var light := _light_of(combat)
	var attack := data.light_attack
	assert_int(combat.guard_raise_ticks).is_equal(Ticks.from_ms(data.guard_raise_ms, tickrate))
	assert_int(light.hitstun_ticks).is_equal(Ticks.from_ms(attack.hitstun_ms, tickrate))
	assert_int(light.blockstun_ticks).is_equal(Ticks.from_ms(attack.blockstun_ms, tickrate))
	assert_int(light.hitstop_hit_ticks).is_equal(Ticks.from_ms(attack.hitstop_hit_ms, tickrate))
	assert_int(light.hitstop_block_ticks).is_equal(Ticks.from_ms(attack.hitstop_block_ms, tickrate))


# The half angle becomes radians, 90° is pi/2, and the cost is points, copied as it is, at any
# rate (DEC-0054 §2: "medido no plano do chão").
func test_the_half_angle_becomes_radians_and_the_block_cost_is_copied(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var combat := CombatConfig.create(_load_v0(), tickrate)
	assert_float(combat.guard_half_angle).is_equal_approx(deg_to_rad(GUARD_HALF_ANGLE_DEG), HAIR)
	assert_float(combat.guard_half_angle).is_equal_approx(PI / 2.0, HAIR)
	assert_float(_light_of(combat).block_stamina_cost).is_equal_approx(BLOCK_STAMINA_COST, HAIR)


# visual-e-audio.md, "Os três canais por estado": the four tokens the duel reads so far, from a
# Resource in data/ (DEC-0031 §5; TASK-12.2 plan): the light's windup and the guard have no colour,
# the active is vermilion and the reaction is a white flash.
func test_tokens_v0_holds_the_colours_of_the_four_states() -> void:
	var tokens := _load_tokens()
	assert_object(tokens.light_windup).override_failure_message("no light_windup").is_not_null()
	assert_object(tokens.active).override_failure_message("no active").is_not_null()
	assert_object(tokens.guard).override_failure_message("no guard").is_not_null()
	assert_object(tokens.reaction).override_failure_message("no reaction").is_not_null()
	_assert_no_colour(tokens.light_windup, "light_windup")
	_assert_colour(tokens.active, VERMILION, "active")
	_assert_no_colour(tokens.guard, "guard")
	_assert_colour(tokens.reaction, WHITE, "reaction")


# Every state has a pose, and the four poses differ: the windup takes the blade back, the active
# is the arc, the guard holds the blade upright in front, the reaction makes the body recoil; and
# every state has a shape for the HUD, which repeats the token with shape and colour, never by
# colour alone (visual-e-audio.md, "Os três canais por estado" and "Onde o sinal mora"; F-053).
func test_every_token_has_a_pose_and_a_hud_shape_and_the_poses_differ() -> void:
	var tokens := _load_tokens()
	var named: Dictionary[String, TokenData] = {
		"light_windup": tokens.light_windup,
		"active": tokens.active,
		"guard": tokens.guard,
		"reaction": tokens.reaction,
	}
	var poses: Array[StringName] = []
	for which: String in named:
		var token := named[which]
		assert_str(String(token.pose)).override_failure_message("%s has no pose" % which) \
				.is_not_empty()
		var no_shape := "%s has no HUD shape" % which
		assert_str(String(token.hud_shape)).override_failure_message(no_shape).is_not_empty()
		var repeated := "%s repeats the pose %s" % [which, token.pose]
		assert_array(poses).override_failure_message(repeated).not_contains([token.pose])
		poses.append(token.pose)


# Failure: an impossible number of the light's new fields is rejected, and a message names its
# field, so the gate's print says which number to fix.
func test_an_impossible_guard_or_stun_number_of_the_light_is_rejected_naming_its_field(
	field: String,
	_test_parameters := [
		["hitstun_ms"],
		["blockstun_ms"],
		["hitstop_hit_ms"],
		["hitstop_block_ms"],
		["block_stamina_cost"],
		["hit_shake_ms"],
		["hit_shake_deg"],
		["block_shake_ms"],
		["block_shake_deg"],
	],
) -> void:
	var data := _v0_copy()
	var value: Variant = ATTACK_IMPOSSIBLE[field]
	data.light_attack.set(field, value)
	assert_that(data.light_attack.get(field)) \
			.override_failure_message("%s is not an AttackData field" % field) \
			.is_equal(value)
	var errors := data.validate()
	assert_array(errors).override_failure_message("%s = %s must fail" % [field, value]) \
			.is_not_empty()
	_assert_some_message_names(errors, field)


# Failure: an impossible number of the guard is rejected, naming its field.
func test_an_impossible_guard_number_is_rejected_naming_its_field(
	field: String,
	_test_parameters := [["guard_raise_ms"], ["guard_half_angle_deg"]],
) -> void:
	var data := _v0_copy()
	var value: Variant = COMBAT_IMPOSSIBLE[field]
	data.set(field, value)
	assert_that(data.get(field)).override_failure_message("%s is not a CombatData field" % field) \
			.is_equal(value)
	var errors := data.validate()
	assert_array(errors).override_failure_message("%s = %s must fail" % [field, value]) \
			.is_not_empty()
	_assert_some_message_names(errors, field)


# Many: two impossible numbers, one of the guard and one of the light, name both fields.
func test_two_impossible_guard_numbers_name_both_fields() -> void:
	var data := _v0_copy()
	data.guard_raise_ms = -1
	data.light_attack.blockstun_ms = -1
	var errors := data.validate()
	assert_int(errors.size()).is_greater_equal(2)
	_assert_some_message_names(errors, "guard_raise_ms")
	_assert_some_message_names(errors, "blockstun_ms")
