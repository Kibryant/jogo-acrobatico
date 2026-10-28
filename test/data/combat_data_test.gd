# TASK-12.1: the combat numbers as design data, converted once at load (DEC-0004, rule 3;
# DEC-0051 §6). combat_v0.tres holds the numbers of docs/design/combate.md ("Os golpes e as
# defesas", the light attack row; "A lâmina e o contato") and of docs/design/partida.md ("A vida
# sem partida"), passes its own data check, and CombatConfig.create turns every ms into the nearest
# tick, ties up (core/time/ticks.gd), at 60 ticks, the game's rate (DEC-0024), and at 30, netfox's
# default. The slow walk of 3 m/s stays in the movement data for the guard and the charged attack
# (movimento.md, "Chão": "Andar devagar"; DEC-0052): the light no longer uses it. Every number is
# cited next to its value; the arithmetic is marked as such.
extends GdUnitTestSuite

const COMBAT_V0 := "res://data/combat_v0.tres"
const MOVEMENT_V0 := "res://data/movement_v0.tres"
const DATA_DIR := "res://data"
const HAIR := 1e-9 # floating-point slack, not a design number

## The move's ID the config keys the light attack by, the slot holds and the state carries
## (glossario.md, "Golpe leve"; TASK-12.1 plan).
const LIGHT := &"light_attack"

# combate.md, "Os golpes e as defesas", the row "Golpe leve": 250 / 100 / 200 ms, 8 de stamina no
# início, 12 de dano (DEC-0052: the light was 400 / 100 / 250).
const WINDUP_MS := 250
const ACTIVE_MS := 100
const RECOVERY_MS := 200
const LIGHT_COST := 8.0
const LIGHT_DAMAGE := 12
# combate.md, "A lâmina e o contato": the light sweeps "±60° da frente", from the right, the
# hand's side, to the left ("O leve no tick": "O arco do leve").
const ARC_FROM_DEG := -60.0
const ARC_TO_DEG := 60.0
# combate.md, "A lâmina e o contato": "A mão: 0,6 m do eixo do corpo, a 1,3 m de altura";
# "Comprimento da lâmina: 1,4"; "Raio da lâmina: 0,08".
const HAND_OFFSET_M := 0.6
const HAND_HEIGHT_M := 1.3
const BLADE_LENGTH_M := 1.4
const BLADE_RADIUS_M := 0.08
# partida.md, "A vida sem partida": "todo lutador tem vida 100 [...] e ela volta a 100 dois
# segundos, 120 ticks, depois do último golpe que ele levou".
const MAX_HEALTH := 100
const HEALTH_REFILL_MS := 2000
# movimento.md, "Chão": "Andar devagar: com a guarda alta ou durante o carregado: 3 m/s"; the
# light does not slow the body (DEC-0052).
const SLOW_WALK_MPS := 3.0

# By hand (combate.md, "Os golpes e as defesas": "Em ticks: 15 / 6 / 12"): at 60 ticks a tick is
# 16.7 ms, so 250 ms are 15 ticks, 100 are 6 and 200 are 12, all exact. At 30 a tick is 33.3 ms:
# 250 ms are 7.5 ticks, the tie, which rounds up to 8 (DEC-0022; visao-geral.md, "O tempo e a
# física no estado"), 100 ms are 3 and 200 are 6. The refill of 2000 ms is 120 ticks at 60 and
# 60 at 30, exact.
const WINDUP_TICKS: Dictionary[int, int] = { 30: 8, 60: 15 }
const ACTIVE_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }
const RECOVERY_TICKS: Dictionary[int, int] = { 30: 6, 60: 12 }
const REFILL_TICKS: Dictionary[int, int] = { 30: 60, 60: 120 }
# Arithmetic on the tie, now the windup's (DEC-0052): 250 ms * 30 ticks/s = 7500, exactly 7.5
# ticks in the units of core/time/ticks.gd (ms * tickrate, a whole tick being 1000).
const TIE_MS := 250
const TIE_TICKRATE := 30
const TIE_ROUNDED_UP := 8

## The light's times as AttackData fields (TASK-12.1 plan).
const ATTACK_TIME_FIELDS: Array[String] = ["windup_ms", "active_ms", "recovery_ms"]

# One impossible value per number of the light attack (TASK-12.1 plan, AttackData): a negative
# time, an active phase that rounds to 0 ticks at both rates (the slice divides the arc by the
# active ticks: combate.md, "O leve no tick": "A fatia do tick k do ativo"), a negative cost and a
# negative damage. The arc may be anything the design wants, so nothing of it is here.
const ATTACK_IMPOSSIBLE: Dictionary[String, Variant] = {
	"windup_ms": -1,
	"active_ms": 0,
	"recovery_ms": -1,
	"stamina_cost": -8.0,
	"damage": -12,
}

# One impossible value per number of the blade and the body (TASK-12.1 plan, CombatData): a hand
# at a negative distance or height, a blade without length, a negative blade radius, a fighter
# without health and a negative refill time. The refill of 0 is legal: it turns the refill off.
const COMBAT_IMPOSSIBLE: Dictionary[String, Variant] = {
	"hand_offset_m": -0.6,
	"hand_height_m": -1.3,
	"blade_length_m": 0.0,
	"blade_radius_m": -0.08,
	"max_health": 0,
	"health_refill_ms": -1,
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


func _load_movement_v0() -> MovementData:
	var resource: Resource = load(MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MOVEMENT_V0)
	return resource as MovementData


func _movement_v0_copy() -> MovementData:
	var copy: Resource = _load_movement_v0().duplicate()
	assert(copy is MovementData, "a duplicate of %s must still be a MovementData" % MOVEMENT_V0)
	return copy as MovementData


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


# Every .tres under a folder, recursively.
func _tres_files_under(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(dir_path)
	assert(dir != null, "%s must exist" % dir_path)
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var path := dir_path.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				found.append_array(_tres_files_under(path))
		elif entry.get_extension() == "tres":
			found.append(path)
		entry = dir.get_next()
	dir.list_dir_end()
	return found


func test_combat_v0_loads_as_combat_data_and_passes_the_data_check() -> void:
	var data := _load_v0()
	assert_object(data.light_attack).override_failure_message("no light attack").is_not_null()
	assert_array(data.validate()).is_empty()
	assert_array(_v0_copy().validate()).is_empty()


func test_combat_v0_holds_the_numbers_of_combate_md_and_partida_md() -> void:
	var data := _load_v0()
	var light := data.light_attack
	assert_int(light.windup_ms).is_equal(WINDUP_MS)
	assert_int(light.active_ms).is_equal(ACTIVE_MS)
	assert_int(light.recovery_ms).is_equal(RECOVERY_MS)
	assert_float(light.stamina_cost).is_equal_approx(LIGHT_COST, HAIR)
	assert_int(light.damage).is_equal(LIGHT_DAMAGE)
	assert_float(light.arc_from_deg).is_equal_approx(ARC_FROM_DEG, HAIR)
	assert_float(light.arc_to_deg).is_equal_approx(ARC_TO_DEG, HAIR)
	assert_float(data.hand_offset_m).is_equal_approx(HAND_OFFSET_M, HAIR)
	assert_float(data.hand_height_m).is_equal_approx(HAND_HEIGHT_M, HAIR)
	assert_float(data.blade_length_m).is_equal_approx(BLADE_LENGTH_M, HAIR)
	assert_float(data.blade_radius_m).is_equal_approx(BLADE_RADIUS_M, HAIR)
	assert_int(data.max_health).is_equal(MAX_HEALTH)
	assert_int(data.health_refill_ms).is_equal(HEALTH_REFILL_MS)


# Every CombatData under data/ passes the check, so a bad file committed later fails here, as the
# movement data does (test/data/movement_data_test.gd; DEC-0027 §2).
func test_every_combat_data_under_data_passes_the_data_check() -> void:
	var checked := 0
	for path: String in _tres_files_under(DATA_DIR):
		var resource: Resource = load(path)
		if resource is CombatData:
			checked += 1
			var data := resource as CombatData
			assert_array(data.validate()).override_failure_message(path).is_empty()
	assert_int(checked).override_failure_message("no CombatData under %s" % DATA_DIR).is_greater(0)


# The light's times by hand (combate.md, "Os golpes e as defesas": "15 / 6 / 12" at 60): 250 ms
# are 15 ticks at 60 and 7.5 at 30, the tie that rounds up to 8; 100 ms are 6 and 3; 200 ms are 12
# at 60 and 6 at 30.
func test_the_light_times_become_15_6_12_ticks_at_60_and_8_3_6_at_30(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var combat := CombatConfig.create(_load_v0(), tickrate)
	var light := _light_of(combat)
	assert_int(combat.tickrate).is_equal(tickrate)
	assert_int(light.windup_ticks).is_equal(WINDUP_TICKS[tickrate])
	assert_int(light.active_ticks).is_equal(ACTIVE_TICKS[tickrate])
	assert_int(light.recovery_ticks).is_equal(RECOVERY_TICKS[tickrate])


# The one tie among the combat's times: the windup of 250 ms at 30 ticks is exactly 7.5 ticks, and
# the tie goes up (DEC-0022; visao-geral.md, "O tempo e a física no estado"); the recovery of
# 200 ms is 6 whole ticks there, no tie.
func test_250_ms_at_30_ticks_is_the_tie_that_rounds_up_to_8() -> void:
	assert_int(TIE_MS * TIE_TICKRATE).is_equal(7500) # 7.5 ticks in the units of Ticks.from_ms
	assert_int(Ticks.from_ms(TIE_MS, TIE_TICKRATE)).is_equal(TIE_ROUNDED_UP)
	var light := _light_of(CombatConfig.create(_load_v0(), TIE_TICKRATE))
	assert_int(light.windup_ticks).is_equal(TIE_ROUNDED_UP)
	assert_int(RECOVERY_MS * TIE_TICKRATE).is_equal(6000) # 6 whole ticks: no tie
	assert_int(light.recovery_ticks).is_equal(RECOVERY_TICKS[TIE_TICKRATE])


# Every time of the light follows Ticks.from_ms, whatever the number in the file.
func test_the_light_time_fields_follow_ticks_from_ms(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var data := _load_v0()
	var light := _light_of(CombatConfig.create(data, tickrate))
	var attack := data.light_attack
	assert_int(light.windup_ticks).is_equal(Ticks.from_ms(attack.windup_ms, tickrate))
	assert_int(light.active_ticks).is_equal(Ticks.from_ms(attack.active_ms, tickrate))
	assert_int(light.recovery_ticks).is_equal(Ticks.from_ms(attack.recovery_ms, tickrate))
	var combat := CombatConfig.create(data, tickrate)
	assert_int(combat.health_refill_ticks).is_equal(Ticks.from_ms(data.health_refill_ms, tickrate))


# partida.md, "A vida sem partida": two seconds are 120 ticks at 60, and 60 at 30, exact.
func test_the_health_refill_becomes_120_ticks_at_60_and_60_at_30(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var combat := CombatConfig.create(_load_v0(), tickrate)
	assert_int(combat.health_refill_ticks).is_equal(REFILL_TICKS[tickrate])
	assert_int(combat.max_health).is_equal(MAX_HEALTH)


# A refill of 0 ms is no impossible number: it turns the refill off, 0 ticks at any rate
# (TASK-12.1 plan: "0 turns the refill off").
func test_a_refill_of_0_ms_is_allowed_and_becomes_0_ticks(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var data := _v0_copy()
	data.health_refill_ms = 0
	assert_array(data.validate()).is_empty()
	assert_int(CombatConfig.create(data, tickrate).health_refill_ticks).is_equal(0)


# The arc's degrees become radians, sign kept: -60° is -pi/3, +60° is +pi/3 (combate.md, "O leve
# no tick": the positive angle turns left, like the yaw).
func test_the_arc_becomes_radians(tickrate: int, _test_parameters := [[30], [60]]) -> void:
	var light := _light_of(CombatConfig.create(_load_v0(), tickrate))
	assert_float(light.arc_from).is_equal_approx(deg_to_rad(ARC_FROM_DEG), HAIR)
	assert_float(light.arc_to).is_equal_approx(deg_to_rad(ARC_TO_DEG), HAIR)
	assert_float(light.arc_from).is_equal_approx(-PI / 3.0, HAIR)
	assert_float(light.arc_to).is_equal_approx(PI / 3.0, HAIR)


# Metres, points and damage are not times: copied as they are at any rate.
func test_the_metres_the_cost_and_the_damage_are_copied(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var combat := CombatConfig.create(_load_v0(), tickrate)
	var light := _light_of(combat)
	assert_float(light.stamina_cost).is_equal_approx(LIGHT_COST, HAIR)
	assert_int(light.damage).is_equal(LIGHT_DAMAGE)
	assert_float(combat.hand_offset).is_equal_approx(HAND_OFFSET_M, HAIR)
	assert_float(combat.hand_height).is_equal_approx(HAND_HEIGHT_M, HAIR)
	assert_float(combat.blade_length).is_equal_approx(BLADE_LENGTH_M, HAIR)
	assert_float(combat.blade_radius).is_equal_approx(BLADE_RADIUS_M, HAIR)


# The attacks are keyed by the move's ID, the same StringName the slot holds (FighterCommand) and
# the state carries in action_move (DEC-0051 §6; F-007 §5: the move by ID, never the Resource).
func test_the_attacks_are_keyed_by_the_moves_id() -> void:
	var combat := CombatConfig.create(_load_v0(), 60)
	assert_int(combat.attacks.size()).is_equal(1)
	assert_bool(combat.attacks.has(LIGHT)).is_true()
	assert_str(String(FighterCommand.LIGHT_ATTACK)).is_equal(String(LIGHT))


# Failure: an impossible number of the light attack is rejected, and a message names its field,
# so the gate's print says which number to fix.
func test_an_impossible_number_of_the_light_attack_is_rejected_naming_its_field(
	field: String,
	_test_parameters := [
		["windup_ms"],
		["active_ms"],
		["recovery_ms"],
		["stamina_cost"],
		["damage"],
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


# Failure, at the limit of the rounding: an active phase of 8 ms is 0 ticks at both rates (the
# arithmetic of test/data/movement_data_ticks_test.gd: 8 ms is the largest time that rounds to 0
# at 60), and the slice divides the arc by the active ticks; 17 ms is 1 tick at both and passes.
func test_an_active_phase_that_rounds_to_0_ticks_is_rejected_and_one_tick_passes() -> void:
	var rejected := _v0_copy()
	rejected.light_attack.active_ms = 8
	_assert_some_message_names(rejected.validate(), "active_ms")
	var accepted := _v0_copy()
	accepted.light_attack.active_ms = 17
	assert_array(accepted.validate()).is_empty()


# Failure: an impossible number of the blade or the body is rejected, naming its field.
func test_an_impossible_number_of_the_blade_or_the_body_is_rejected_naming_its_field(
	field: String,
	_test_parameters := [
		["hand_offset_m"],
		["hand_height_m"],
		["blade_length_m"],
		["blade_radius_m"],
		["max_health"],
		["health_refill_ms"],
	],
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


# Failure: a combat without its light attack has no numbers to convert.
func test_a_combat_without_the_light_attack_is_rejected() -> void:
	var data := _v0_copy()
	data.light_attack = null
	assert_array(data.validate()).is_not_empty()


# Many: two impossible numbers give at least one message each, naming both fields.
func test_two_impossible_numbers_name_both_fields() -> void:
	var data := _v0_copy()
	data.max_health = 0
	data.light_attack.damage = -12
	var errors := data.validate()
	assert_int(errors.size()).is_greater_equal(2)
	_assert_some_message_names(errors, "max_health")
	_assert_some_message_names(errors, "damage")


# The slow walk is a movement number (movimento.md, "Chão": "Andar devagar: com a guarda alta ou
# durante o carregado: 3 m/s"), kept in movement_v0.tres for the guard (TASK-12.2) and the charged
# attack (TASK-12.3) and copied as a speed into the config at any rate; the light no longer uses
# it (DEC-0052).
func test_movement_v0_holds_the_slow_walk_of_3_mps() -> void:
	assert_float(_load_movement_v0().slow_walk_speed_mps).is_equal_approx(SLOW_WALK_MPS, HAIR)


func test_the_slow_walk_speed_is_copied_to_the_movement_config(
	tickrate: int,
	_test_parameters := [[30], [60]],
) -> void:
	var config := MovementConfig.create(_load_movement_v0(), tickrate)
	assert_float(config.slow_walk_speed).is_equal_approx(SLOW_WALK_MPS, HAIR)


func test_movement_v0_still_passes_the_data_check_with_the_slow_walk() -> void:
	assert_array(_load_movement_v0().validate()).is_empty()


# Failure: a speed cannot be negative, as every other speed of MovementData.
func test_a_negative_slow_walk_is_rejected_naming_its_field() -> void:
	var data := _movement_v0_copy()
	data.slow_walk_speed_mps = -3.0
	_assert_some_message_names(data.validate(), "slow_walk_speed_mps")
