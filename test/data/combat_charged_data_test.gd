# TASK-12.3: the numbers of the charged attack, the parry and the feint as design data, converted
# once at load (DEC-0004, rule 3; DEC-0056). combat_v0.tres gains the charged attack (combate.md,
# "Os golpes e as defesas", the row "Golpe carregado"; "O tranco e a vantagem"; "O hitstop e o
# tremor"; "A lâmina e o contato": the vertical cut), the parry's and the feint's numbers (the rows
# "Parry" and "Finta"; "O parry"; "A finta"), and the light keeps its numbers, the new flags off.
# CombatConfig turns every ms into the nearest tick, ties up (core/time/ticks.gd), at 60 ticks, the
# game's rate (DEC-0024), and at 30, netfox's default, and turns the tip's heights of the vertical
# cut into elevations at load (combate.md, "O corte do carregado": "O dado guarda as duas alturas da
# ponta, e o código tira os ângulos na carga"). Every number is cited next to its value; the
# arithmetic is marked as such.
extends GdUnitTestSuite

const COMBAT_V0 := "res://data/combat_v0.tres"
const HAIR := 1e-9 # floating-point slack, not a design number
const DEGREE_HAIR := 0.01 # degrees: the slack of the design's two-decimal elevations

## The moves' IDs the config keys the attacks by (glossario.md, "Golpe leve" and "Golpe
## carregado"; combate.md, "O carregado, o parry e a finta no tick": "Os nomes no código").
const LIGHT := &"light_attack"
const CHARGED := &"charged_attack"

# combate.md, "Os golpes e as defesas", the row "Golpe carregado": 700 / 120 / 450 ms, "25, pagos
# na soltura", 30 de dano; "A lâmina e o contato": "corte de cima para baixo [...] de 2,2 m a 0,6 m
# de altura".
const WINDUP_MS := 700
const ACTIVE_MS := 120
const RECOVERY_MS := 450
const CHARGED_COST := 25.0
const CHARGED_DAMAGE := 30
const TIP_FROM_HEIGHT_M := 2.2
const TIP_TO_HEIGHT_M := 0.6
# combate.md, "O tranco e a vantagem", the rows "Carregado acerta: 700 ms" and "Carregado
# bloqueado: 417 ms"; "O hitstop e o tremor", the rows "Carregado acerta: 117 ms; 200 ms, 1,5°;
# metade em quem bateu" and "Carregado bloqueado: 67 ms; 100 ms, 0,3°"; "Os golpes e as defesas",
# the row "Bloqueio": "15 por carregado bloqueado".
const CHARGED_HITSTUN_MS := 700
const CHARGED_BLOCKSTUN_MS := 417
const CHARGED_HITSTOP_HIT_MS := 117
const CHARGED_HITSTOP_BLOCK_MS := 67
const CHARGED_HIT_SHAKE_MS := 200
const CHARGED_HIT_SHAKE_DEG := 1.5
const CHARGED_HIT_SHAKE_ATTACKER_SHARE := 0.5
const CHARGED_BLOCK_SHAKE_MS := 100
const CHARGED_BLOCK_SHAKE_DEG := 0.3
const CHARGED_BLOCK_COST := 15.0
# combate.md, "Os golpes e as defesas", the row "Parry": "janela de 200 desde o aperto; recupera
# 200 se aparou, 450 se não", "15, no aperto"; "O tranco e a vantagem", the row "Carregado
# aparado": "900 ms, 54 ticks, mais 9 ticks de hitstop sozinho"; "O hitstop e o tremor", the row
# "Parry: só quem foi aparado, 150 ms, 9 ticks; 150 ms, 1,0°, nos dois".
const PARRY_WINDOW_MS := 200
const PARRY_RECOVERY_MS := 200
const PARRY_WHIFF_RECOVERY_MS := 450
const PARRY_COST := 15.0
const PARRIED_STUN_MS := 900
const PARRIED_HITSTOP_MS := 150
const PARRY_SHAKE_MS := 150
const PARRY_SHAKE_DEG := 1.0
# combate.md, "Os golpes e as defesas", the row "Finta": "corta a preparação do carregado até
# 450 ms; recupera 200", "15, no aperto".
const FEINT_UNTIL_MS := 450
const FEINT_RECOVERY_MS := 200
const FEINT_COST := 15.0
# combate.md, "A lâmina e o contato": "A mão: 0,6 m do eixo do corpo, a 1,3 m de altura";
# "Comprimento da lâmina: 1,4": the tip reaches 2,0 m from the hand's centre.
const HAND_OFFSET_M := 0.6
const HAND_HEIGHT_M := 1.3
const BLADE_LENGTH_M := 1.4
const TIP_REACH_M := 2.0
# combate.md, "O corte do carregado": "φ₀ = asen((2,2 − 1,3) / 2,0) ≈ +26,74° a φ₇ = asen((0,6 −
# 1,3) / 2,0) ≈ −20,49°. Elevação positiva aponta para cima".
const ELEVATION_FROM_DEG := 26.74
const ELEVATION_TO_DEG := -20.49
# combate.md, "O leve no tick": "O arco do leve": -60° to +60°, untouched by this task.
const LIGHT_ARC_FROM_DEG := -60.0
const LIGHT_ARC_TO_DEG := 60.0

# By hand, the nearest tick with ties up (DEC-0022; visao-geral.md, "O tempo e a física no
# estado"). At 60 a tick is 16,7 ms: 700 ms are 42 ticks, 450 are 27, 200 are 12, 900 are 54,
# exact; 120 ms are 7,2 ticks, so 7; 417 are 25,02, so 25; 117 are 7,02, so 7; 67 are 4,02, so 4;
# 150 are 9. At 30 a tick is 33,3 ms: 700 ms are 21, 200 are 6, 900 are 27, exact; 120 ms are
# 3,6, so 4; 450 are 13,5, the tie, up to 14; 417 are 12,51, so 13; 117 are 3,51, so 4; 67 are
# 2,01, so 2; 150 are 4,5, the tie, up to 5. The design's own ticks: "42 / 7 / 27", "25", "7",
# "4", "12; 12 ou 27", "54", "9", "até 27; 12" at 60, and "21, 4 e 14" at 30.
const WINDUP_TICKS: Dictionary[int, int] = { 30: 21, 60: 42 }
const ACTIVE_TICKS: Dictionary[int, int] = { 30: 4, 60: 7 }
const RECOVERY_TICKS: Dictionary[int, int] = { 30: 14, 60: 27 }
const CHARGED_HITSTUN_TICKS: Dictionary[int, int] = { 30: 21, 60: 42 }
const CHARGED_BLOCKSTUN_TICKS: Dictionary[int, int] = { 30: 13, 60: 25 }
const CHARGED_HITSTOP_HIT_TICKS: Dictionary[int, int] = { 30: 4, 60: 7 }
const CHARGED_HITSTOP_BLOCK_TICKS: Dictionary[int, int] = { 30: 2, 60: 4 }
const PARRY_WINDOW_TICKS: Dictionary[int, int] = { 30: 6, 60: 12 }
const PARRY_RECOVERY_TICKS: Dictionary[int, int] = { 30: 6, 60: 12 }
const PARRY_WHIFF_RECOVERY_TICKS: Dictionary[int, int] = { 30: 14, 60: 27 }
const PARRIED_STUN_TICKS: Dictionary[int, int] = { 30: 27, 60: 54 }
const PARRIED_HITSTOP_TICKS: Dictionary[int, int] = { 30: 5, 60: 9 }
const FEINT_UNTIL_TICKS: Dictionary[int, int] = { 30: 14, 60: 27 }
const FEINT_RECOVERY_TICKS: Dictionary[int, int] = { 30: 6, 60: 12 }
# The roundings that are not exact, in the units of core/time/ticks.gd (ms * tickrate, a whole
# tick being 1000): [ms, tickrate, scaled, expected ticks].
const ROUNDINGS: Array[Array] = [
	[ACTIVE_MS, 60, 7200, 7],
	[ACTIVE_MS, 30, 3600, 4],
	[RECOVERY_MS, 30, 13500, 14],
	[CHARGED_BLOCKSTUN_MS, 60, 25020, 25],
	[CHARGED_BLOCKSTUN_MS, 30, 12510, 13],
	[CHARGED_HITSTOP_HIT_MS, 60, 7020, 7],
	[CHARGED_HITSTOP_HIT_MS, 30, 3510, 4],
	[CHARGED_HITSTOP_BLOCK_MS, 30, 2010, 2],
	[PARRIED_HITSTOP_MS, 30, 4500, 5],
]
# The two ties among the new times, both at 30: 450 ms are exactly 13,5 ticks and 150 ms exactly
# 4,5; both go up (DEC-0022).
const TIES: Array[Array] = [[RECOVERY_MS, 30, 14], [PARRIED_HITSTOP_MS, 30, 5]]

## The new flags of AttackData, all on for the charged and off for the light (TASK-12.3 plan).
const FLAGS: Array[String] = [
	"pays_on_release",
	"armor",
	"breaks_armor",
	"parryable",
	"feintable",
	"vertical_cut",
]
## The new times of CombatData, in ms (TASK-12.3 plan).
const NEW_TIME_FIELDS: Array[String] = [
	"parry_window_ms",
	"parry_recovery_ms",
	"parry_whiff_recovery_ms",
	"parried_stun_ms",
	"parried_hitstop_ms",
	"parry_shake_ms",
	"feint_until_ms",
	"feint_recovery_ms",
]
## The new costs of CombatData, in points.
const NEW_COST_FIELDS: Array[String] = ["parry_stamina_cost", "feint_stamina_cost"]
# One impossible value per new number of the charged (TASK-12.3 plan, AttackData): a share
# outside 0..1, and a tip height the blade cannot reach, farther than hand_offset + blade_length
# above or below the hand's height: 1,3 + 2,0 = 3,3 m and 1,3 - 2,0 = -0,7 m, a centimetre beyond.
const CHARGED_IMPOSSIBLE: Dictionary[String, Variant] = {
	"hit_shake_attacker_share": 1.5,
	"tip_from_height_m": 3.31,
	"tip_to_height_m": -0.71,
}
const SHARE_BELOW_ZERO := -0.5
# The limits that pass: a share of 0 or 1, and a tip a centimetre inside the blade's reach.
const TIP_REACHABLE_HIGH_M := 3.29
const TIP_REACHABLE_LOW_M := -0.69


func _load_v0() -> CombatData:
	var resource: Resource = load(COMBAT_V0)
	assert(resource is CombatData, "%s must load as a CombatData (TASK-12.1 plan)" % COMBAT_V0)
	return resource as CombatData


# A deep copy of combat_v0.tres, its attacks included: load() caches the resource, so each case
# changes a duplicate and the baseline stays intact for every other test of the run.
func _v0_copy() -> CombatData:
	var copy: Resource = _load_v0().duplicate(true)
	assert(copy is CombatData, "a duplicate of %s must still be a CombatData" % COMBAT_V0)
	var data := copy as CombatData
	assert(data.light_attack != null, "%s must hold the light attack" % COMBAT_V0)
	var light: Resource = data.light_attack.duplicate()
	assert(light is AttackData, "a duplicate of an AttackData must still be an AttackData")
	data.light_attack = light as AttackData
	if data.charged_attack != null:
		var charged: Resource = data.charged_attack.duplicate()
		assert(charged is AttackData, "a duplicate of an AttackData must still be an AttackData")
		data.charged_attack = charged as AttackData
	return data


func _charged_of(combat: CombatConfig) -> AttackConfig:
	assert_bool(combat.attacks.has(CHARGED)) \
			.override_failure_message("attacks must be keyed by %s, got %s"
	% [CHARGED, combat.attacks.keys()]) \
			.is_true()
	return combat.attacks[CHARGED]


func _light_of(combat: CombatConfig) -> AttackConfig:
	assert_bool(combat.attacks.has(LIGHT)).override_failure_message("no light attack").is_true()
	return combat.attacks[LIGHT]


func _assert_some_message_names(errors: PackedStringArray, field: String) -> void:
	var named := false
	for message: String in errors:
		if message.contains(field):
			named = true
	var unnamed := "no message names %s, got: %s" % [field, errors]
	assert_bool(named).override_failure_message(unnamed).is_true()


func test_combat_v0_holds_the_charged_attack_and_still_passes_the_data_check() -> void:
	var data := _load_v0()
	assert_object(data.charged_attack).override_failure_message("no charged attack").is_not_null()
	assert_array(data.validate()).is_empty()
	assert_array(_v0_copy().validate()).is_empty()


# combate.md, "Os golpes e as defesas", the row "Golpe carregado", and "A lâmina e o contato": the
# charged's times, cost, damage and the tip's two heights.
func test_combat_v0_holds_the_charged_times_cost_damage_and_tip_heights() -> void:
	var charged := _load_v0().charged_attack
	assert_int(charged.windup_ms).is_equal(WINDUP_MS)
	assert_int(charged.active_ms).is_equal(ACTIVE_MS)
	assert_int(charged.recovery_ms).is_equal(RECOVERY_MS)
	assert_float(charged.stamina_cost).is_equal_approx(CHARGED_COST, HAIR)
	assert_int(charged.damage).is_equal(CHARGED_DAMAGE)
	assert_float(charged.tip_from_height_m).is_equal_approx(TIP_FROM_HEIGHT_M, HAIR)
	assert_float(charged.tip_to_height_m).is_equal_approx(TIP_TO_HEIGHT_M, HAIR)


# combate.md, "O tranco e a vantagem", "O hitstop e o tremor" and "Os golpes e as defesas": the
# charged's stun, hitstop, shakes, the attacker's share of the hit's shake and the block cost.
func test_combat_v0_holds_the_charged_stun_hitstop_shakes_and_block_cost() -> void:
	var charged := _load_v0().charged_attack
	assert_int(charged.hitstun_ms).is_equal(CHARGED_HITSTUN_MS)
	assert_int(charged.blockstun_ms).is_equal(CHARGED_BLOCKSTUN_MS)
	assert_int(charged.hitstop_hit_ms).is_equal(CHARGED_HITSTOP_HIT_MS)
	assert_int(charged.hitstop_block_ms).is_equal(CHARGED_HITSTOP_BLOCK_MS)
	assert_int(charged.hit_shake_ms).is_equal(CHARGED_HIT_SHAKE_MS)
	assert_float(charged.hit_shake_deg).is_equal_approx(CHARGED_HIT_SHAKE_DEG, HAIR)
	assert_float(charged.hit_shake_attacker_share).is_equal_approx(
		CHARGED_HIT_SHAKE_ATTACKER_SHARE,
		HAIR,
	)
	assert_int(charged.block_shake_ms).is_equal(CHARGED_BLOCK_SHAKE_MS)
	assert_float(charged.block_shake_deg).is_equal_approx(CHARGED_BLOCK_SHAKE_DEG, HAIR)
	assert_float(charged.block_stamina_cost).is_equal_approx(CHARGED_BLOCK_COST, HAIR)


# The charged pays on release, has armor, breaks armor, is parried, is feinted and cuts vertically
# (combate.md, "Os golpes e as defesas" and "A armadura do carregado"); the light does none of
# that, and its shake has no share for the attacker ("O hitstop e o tremor": "em quem levou").
func test_the_charged_has_every_flag_on_and_the_light_every_flag_off() -> void:
	var data := _load_v0()
	for flag: String in FLAGS:
		var on: Variant = data.charged_attack.get(flag)
		assert_bool(on is bool and on).override_failure_message("charged.%s is %s" % [flag, on]) \
				.is_true()
		var off: Variant = data.light_attack.get(flag)
		var lit := "light.%s: %s" % [flag, off]
		assert_bool(off is bool and not off).override_failure_message(lit).is_true()
	assert_float(data.light_attack.hit_shake_attacker_share).is_equal_approx(0.0, HAIR)


# combate.md, the rows "Parry" and "Finta", "O tranco e a vantagem" and "O hitstop e o tremor":
# the parry's window, recoveries, cost, the parried one's stun and hitstop, the parry's shake, and
# the feint's limit, recovery and cost.
func test_combat_v0_holds_the_parry_and_feint_numbers() -> void:
	var data := _load_v0()
	assert_int(data.parry_window_ms).is_equal(PARRY_WINDOW_MS)
	assert_int(data.parry_recovery_ms).is_equal(PARRY_RECOVERY_MS)
	assert_int(data.parry_whiff_recovery_ms).is_equal(PARRY_WHIFF_RECOVERY_MS)
	assert_float(data.parry_stamina_cost).is_equal_approx(PARRY_COST, HAIR)
	assert_int(data.parried_stun_ms).is_equal(PARRIED_STUN_MS)
	assert_int(data.parried_hitstop_ms).is_equal(PARRIED_HITSTOP_MS)
	assert_int(data.parry_shake_ms).is_equal(PARRY_SHAKE_MS)
	assert_float(data.parry_shake_deg).is_equal_approx(PARRY_SHAKE_DEG, HAIR)
	assert_int(data.feint_until_ms).is_equal(FEINT_UNTIL_MS)
	assert_int(data.feint_recovery_ms).is_equal(FEINT_RECOVERY_MS)
	assert_float(data.feint_stamina_cost).is_equal_approx(FEINT_COST, HAIR)


# The attacks by the move's ID (F-007 §5): two of them, the light and the charged, and
# CombatData.attack answers by the command (TASK-12.3 plan).
func test_the_attacks_are_keyed_by_the_moves_id_and_found_by_command() -> void:
	var data := _load_v0()
	var combat := CombatConfig.create(data, 60)
	assert_int(combat.attacks.size()).is_equal(2)
	assert_bool(combat.attacks.has(LIGHT)).is_true()
	assert_bool(combat.attacks.has(CHARGED)).is_true()
	assert_str(String(FighterCommand.CHARGED_ATTACK)).is_equal(String(CHARGED))
	assert_str(String(FighterCommand.PARRY)).is_equal("parry")
	assert_object(data.attack(FighterCommand.CHARGED_ATTACK)).is_same(data.charged_attack)
	assert_object(data.attack(FighterCommand.LIGHT_ATTACK)).is_same(data.light_attack)


# The charged's times by hand (combate.md, "Os golpes e as defesas": "42 / 7 / 27"; "As fases do
# carregado": "a 30 ticks, são 21, 4 e 14").
func test_the_charged_times_become_42_7_27_ticks_at_60_and_21_4_14_at_30(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var charged := _charged_of(CombatConfig.create(_load_v0(), tickrate))
	assert_int(charged.windup_ticks).is_equal(WINDUP_TICKS[tickrate])
	assert_int(charged.active_ticks).is_equal(ACTIVE_TICKS[tickrate])
	assert_int(charged.recovery_ticks).is_equal(RECOVERY_TICKS[tickrate])
	assert_int(charged.hitstun_ticks).is_equal(CHARGED_HITSTUN_TICKS[tickrate])
	assert_int(charged.blockstun_ticks).is_equal(CHARGED_BLOCKSTUN_TICKS[tickrate])
	assert_int(charged.hitstop_hit_ticks).is_equal(CHARGED_HITSTOP_HIT_TICKS[tickrate])
	assert_int(charged.hitstop_block_ticks).is_equal(CHARGED_HITSTOP_BLOCK_TICKS[tickrate])


# The parry's and the feint's times by hand (combate.md: "12; 12 ou 27", "54", "9", "até 27; 12"
# at 60; 6, 6, 14, 27, 5, 14, 6 at 30).
func test_the_parry_and_feint_times_become_ticks_at_60_and_30(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var combat := CombatConfig.create(_load_v0(), tickrate)
	assert_int(combat.parry_window_ticks).is_equal(PARRY_WINDOW_TICKS[tickrate])
	assert_int(combat.parry_recovery_ticks).is_equal(PARRY_RECOVERY_TICKS[tickrate])
	assert_int(combat.parry_whiff_recovery_ticks).is_equal(PARRY_WHIFF_RECOVERY_TICKS[tickrate])
	assert_int(combat.parried_stun_ticks).is_equal(PARRIED_STUN_TICKS[tickrate])
	assert_int(combat.parried_hitstop_ticks).is_equal(PARRIED_HITSTOP_TICKS[tickrate])
	assert_int(combat.feint_until_ticks).is_equal(FEINT_UNTIL_TICKS[tickrate])
	assert_int(combat.feint_recovery_ticks).is_equal(FEINT_RECOVERY_TICKS[tickrate])


# Every new time follows Ticks.from_ms, whatever the number in the file.
func test_the_new_time_fields_follow_ticks_from_ms(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var data := _load_v0()
	var combat := CombatConfig.create(data, tickrate)
	var charged := _charged_of(combat)
	var attack := data.charged_attack
	assert_int(charged.windup_ticks).is_equal(Ticks.from_ms(attack.windup_ms, tickrate))
	assert_int(charged.active_ticks).is_equal(Ticks.from_ms(attack.active_ms, tickrate))
	assert_int(charged.recovery_ticks).is_equal(Ticks.from_ms(attack.recovery_ms, tickrate))
	assert_int(charged.hitstun_ticks).is_equal(Ticks.from_ms(attack.hitstun_ms, tickrate))
	assert_int(charged.blockstun_ticks).is_equal(Ticks.from_ms(attack.blockstun_ms, tickrate))
	assert_int(charged.hitstop_hit_ticks).is_equal(Ticks.from_ms(attack.hitstop_hit_ms, tickrate))
	assert_int(charged.hitstop_block_ticks).is_equal(
		Ticks.from_ms(attack.hitstop_block_ms, tickrate)
	)
	assert_int(combat.parry_window_ticks).is_equal(Ticks.from_ms(data.parry_window_ms, tickrate))
	assert_int(combat.parry_recovery_ticks).is_equal(
		Ticks.from_ms(data.parry_recovery_ms, tickrate)
	)
	assert_int(combat.parry_whiff_recovery_ticks).is_equal(
		Ticks.from_ms(data.parry_whiff_recovery_ms, tickrate)
	)
	assert_int(combat.parried_stun_ticks).is_equal(Ticks.from_ms(data.parried_stun_ms, tickrate))
	assert_int(combat.parried_hitstop_ticks).is_equal(
		Ticks.from_ms(data.parried_hitstop_ms, tickrate)
	)
	assert_int(combat.feint_until_ticks).is_equal(Ticks.from_ms(data.feint_until_ms, tickrate))
	assert_int(combat.feint_recovery_ticks).is_equal(
		Ticks.from_ms(data.feint_recovery_ms, tickrate)
	)


# The roundings that are not exact: 120 ms at 60 is 7,2 ticks and goes down to 7, at 30 it is 3,6
# and goes up to 4; 417 ms is 25,02 at 60 and 12,51 at 30; 117 ms is 7,02 and 3,51; 67 ms at 30 is
# 2,01; 450 and 150 ms at 30 are the ties 13,5 and 4,5, which go up (DEC-0022).
func test_the_new_times_round_to_the_nearest_tick_and_the_ties_go_up() -> void:
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
	for tie: Array in TIES:
		var ms: int = tie[0]
		var tickrate: int = tie[1]
		var expected: int = tie[2]
		assert_int((ms * tickrate) % 1000).override_failure_message("%d ms at %d is no tie"
		% [ms, tickrate]) \
				.is_equal(500)
		assert_int(Ticks.from_ms(ms, tickrate)).is_equal(expected)
	# The config carries the two ties up: the charged's recovery and the parried one's hitstop.
	var at_30 := CombatConfig.create(_load_v0(), 30)
	assert_int(_charged_of(at_30).recovery_ticks).is_equal(RECOVERY_TICKS[30])
	assert_int(at_30.parried_hitstop_ticks).is_equal(PARRIED_HITSTOP_TICKS[30])


# Points, damage and flags are not times: copied as they are at any rate.
func test_the_costs_the_damage_and_the_flags_are_copied(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var combat := CombatConfig.create(_load_v0(), tickrate)
	var charged := _charged_of(combat)
	assert_float(charged.stamina_cost).is_equal_approx(CHARGED_COST, HAIR)
	assert_int(charged.damage).is_equal(CHARGED_DAMAGE)
	assert_float(charged.block_stamina_cost).is_equal_approx(CHARGED_BLOCK_COST, HAIR)
	assert_float(combat.parry_stamina_cost).is_equal_approx(PARRY_COST, HAIR)
	assert_float(combat.feint_stamina_cost).is_equal_approx(FEINT_COST, HAIR)
	var light := _light_of(combat)
	for flag: String in FLAGS:
		var on: Variant = charged.get(flag)
		assert_bool(on is bool and on).override_failure_message("charged.%s is %s" % [flag, on]) \
				.is_true()
		var off: Variant = light.get(flag)
		var lit := "light.%s: %s" % [flag, off]
		assert_bool(off is bool and not off).override_failure_message(lit).is_true()


# The vertical cut's elevations at load (combate.md, "O corte do carregado"): arc_from is
# asin((2,2 - 1,3) / 2,0), +26,74°, and arc_to is asin((0,6 - 1,3) / 2,0), -20,49°, positive up;
# the light's arc stays -60° to +60°.
func test_the_tip_heights_become_elevations_in_radians_positive_up(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var combat := CombatConfig.create(_load_v0(), tickrate)
	var charged := _charged_of(combat)
	var reach := combat.hand_offset + combat.blade_length
	assert_float(reach).is_equal_approx(TIP_REACH_M, HAIR)
	var from := asin((TIP_FROM_HEIGHT_M - HAND_HEIGHT_M) / reach)
	var to := asin((TIP_TO_HEIGHT_M - HAND_HEIGHT_M) / reach)
	assert_float(charged.arc_from).is_equal_approx(from, HAIR)
	assert_float(charged.arc_to).is_equal_approx(to, HAIR)
	assert_float(rad_to_deg(charged.arc_from)).is_equal_approx(ELEVATION_FROM_DEG, DEGREE_HAIR)
	assert_float(rad_to_deg(charged.arc_to)).is_equal_approx(ELEVATION_TO_DEG, DEGREE_HAIR)
	assert_float(charged.arc_from).is_greater(0.0)
	assert_float(charged.arc_to).is_less(0.0)
	var light := _light_of(combat)
	assert_float(light.arc_from).is_equal_approx(deg_to_rad(LIGHT_ARC_FROM_DEG), HAIR)
	assert_float(light.arc_to).is_equal_approx(deg_to_rad(LIGHT_ARC_TO_DEG), HAIR)


# The slices of the cut tile the elevations as the light's tile its arc (combate.md, "O corte do
# carregado": "em passos iguais"): the first slice starts at +26,74°, the last ends at -20,49°,
# each begins where the one before ended, 7 slices at 60 and 4 at 30.
func test_the_cuts_slices_tile_the_elevations_from_the_top_to_the_bottom(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var charged := _charged_of(CombatConfig.create(_load_v0(), tickrate))
	assert_int(charged.active_ticks).is_equal(ACTIVE_TICKS[tickrate])
	var step := (charged.arc_to - charged.arc_from) / charged.active_ticks
	var previous_end := charged.arc_from
	for k: int in range(1, charged.active_ticks + 1):
		var slice := Blade.slice_of(charged, k)
		assert_float(slice.x).override_failure_message("slice %d starts off" % k).is_equal_approx(
			previous_end,
			1e-5,
		)
		assert_float(slice.y - slice.x).override_failure_message("slice %d width" % k) \
				.is_equal_approx(step, 1e-5)
		previous_end = slice.y
	assert_float(previous_end).is_equal_approx(charged.arc_to, 1e-5)


# Failure: a negative new time of the combat is rejected, and a message names its field, so the
# gate's print says which number to fix.
func test_a_negative_new_time_is_rejected_naming_its_field(
	field: String,
	_test_parameters := [
		["parry_window_ms"],
		["parry_recovery_ms"],
		["parry_whiff_recovery_ms"],
		["parried_stun_ms"],
		["parried_hitstop_ms"],
		["parry_shake_ms"],
		["feint_until_ms"],
		["feint_recovery_ms"],
	],
) -> void:
	assert_bool(NEW_TIME_FIELDS.has(field)).is_true()
	var data := _v0_copy()
	data.set(field, -1)
	assert_that(data.get(field)).override_failure_message("%s is not a CombatData field" % field) \
			.is_equal(-1)
	var errors := data.validate()
	assert_array(errors).override_failure_message("%s = -1 must fail" % field).is_not_empty()
	_assert_some_message_names(errors, field)


# Failure: a negative cost of the parry or the feint is rejected, naming its field.
func test_a_negative_parry_or_feint_cost_is_rejected_naming_its_field(
	field: String,
	_test_parameters := [["parry_stamina_cost"], ["feint_stamina_cost"]],
) -> void:
	assert_bool(NEW_COST_FIELDS.has(field)).is_true()
	var data := _v0_copy()
	data.set(field, -15.0)
	assert_that(data.get(field)).override_failure_message("%s is not a CombatData field" % field) \
			.is_equal(-15.0)
	var errors := data.validate()
	assert_array(errors).override_failure_message("%s = -15 must fail" % field).is_not_empty()
	_assert_some_message_names(errors, field)


# Failure: an impossible number of the charged is rejected, naming its field: a share over 1, and
# a tip height the blade cannot reach, above or below.
func test_an_impossible_number_of_the_charged_is_rejected_naming_its_field(
	field: String,
	_test_parameters := [["hit_shake_attacker_share"], ["tip_from_height_m"], ["tip_to_height_m"]],
) -> void:
	var data := _v0_copy()
	var value: Variant = CHARGED_IMPOSSIBLE[field]
	data.charged_attack.set(field, value)
	assert_that(data.charged_attack.get(field)) \
			.override_failure_message("%s is not an AttackData field" % field) \
			.is_equal(value)
	var errors := data.validate()
	assert_array(errors).override_failure_message("%s = %s must fail" % [field, value]) \
			.is_not_empty()
	_assert_some_message_names(errors, field)


# Failure and limits of the share: below 0 it is rejected; 0 and 1 pass.
func test_a_share_below_0_is_rejected_and_0_and_1_pass() -> void:
	var rejected := _v0_copy()
	rejected.charged_attack.hit_shake_attacker_share = SHARE_BELOW_ZERO
	_assert_some_message_names(rejected.validate(), "hit_shake_attacker_share")
	for share: float in [0.0, 1.0]:
		var accepted := _v0_copy()
		accepted.charged_attack.hit_shake_attacker_share = share
		assert_array(accepted.validate()).override_failure_message("share %.1f" % share).is_empty()


# Limits of the tip: a centimetre inside the blade's reach, 3,29 m above the feet or -0,69 m, the
# tip is reachable and the data passes; a centimetre beyond, it is rejected.
func test_a_tip_a_centimetre_inside_the_blades_reach_passes_and_beyond_it_is_rejected() -> void:
	var high := _v0_copy()
	high.charged_attack.tip_from_height_m = TIP_REACHABLE_HIGH_M
	assert_array(high.validate()).is_empty()
	var low := _v0_copy()
	low.charged_attack.tip_to_height_m = TIP_REACHABLE_LOW_M
	assert_array(low.validate()).is_empty()
	var too_high := _v0_copy()
	too_high.charged_attack.tip_to_height_m = TIP_REACHABLE_HIGH_M + 0.02
	_assert_some_message_names(too_high.validate(), "tip_to_height_m")
	var too_low := _v0_copy()
	too_low.charged_attack.tip_from_height_m = TIP_REACHABLE_LOW_M - 0.02
	_assert_some_message_names(too_low.validate(), "tip_from_height_m")


# Failure: a combat without its charged attack has no numbers to convert.
func test_a_combat_without_the_charged_attack_is_rejected_naming_it() -> void:
	var data := _v0_copy()
	data.charged_attack = null
	var errors := data.validate()
	assert_array(errors).is_not_empty()
	_assert_some_message_names(errors, "charged_attack")


# Many: two impossible numbers, one of the parry and one of the charged, name both fields.
func test_two_impossible_new_numbers_name_both_fields() -> void:
	var data := _v0_copy()
	data.parry_window_ms = -1
	data.charged_attack.tip_from_height_m = 3.31
	var errors := data.validate()
	assert_int(errors.size()).is_greater_equal(2)
	_assert_some_message_names(errors, "parry_window_ms")
	_assert_some_message_names(errors, "tip_from_height_m")
