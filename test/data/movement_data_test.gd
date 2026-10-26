# Criterion 5 of TASK-9: the data check, layer 3 of DEC-0027 §2. A movement .tres with an
# impossible number must fail the gate: MovementData.validate() returns one message per
# impossible number, movement_v0.tres passes it, and the scan below runs it over every
# MovementData under res://data/, so a bad file committed later fails here. The baseline numbers
# come from docs/design/movimento.md, cited by section. TASK-10.1, criterion 7, adds the double
# jump and the stamina (movimento.md, "Pulo e ar" and "Stamina"); TASK-10.4 adds the dash
# (movimento.md, "Dash"); TASK-10.5, criterion 7, adds the wall (movimento.md, "Corrida na
# parede"); TASK-10.10 adds the head ray and the lean on screen (same section); TASK-10.6 adds
# the grapple and the aim's height (movimento.md, "Gancho"), whose own checks live in
# movement_data_grapple_test.gd.
extends GdUnitTestSuite

const MOVEMENT_V0 := "res://data/movement_v0.tres"
const DATA_DIR := "res://data"
const HAIR := 1e-9 # floating-point slack, not a design number

# The six times of the skeleton (movimento.md, "Chão", "Pulo e ar" and "Perdão"), the wait of
# the stamina ("Stamina") and the duration and cooldown of the dash ("Dash") as MovementData
# fields (TASK-9, TASK-10.1 and TASK-10.4 plans).
const TIME_FIELDS: Array[String] = [
	"accel_time_ms",
	"stop_time_ms",
	"jump_rise_ms",
	"jump_fall_ms",
	"coyote_ms",
	"buffer_ms",
	"stamina_wait_ms",
	"dash_ms",
	"dash_cooldown_ms",
	"wall_run_max_ms",
	"wall_hold_ms",
]

# The thirteen numbers of the wall (movimento.md, "Corrida na parede"; TASK-10.5 plan, Data;
# TASK-10.10), each with one value that cannot be: an incline below 0° (also below the max
# slope), a negative entry speed, a run speed of zero (with the entry at a negative value, below
# it), a negative ceiling (below the run speed), two negative times (equal, so neither exceeds the
# other), a negative slide percentage, a jump without height, a negative push, a negative
# same-face angle, a ray inside the capsule, a negative lean and a negative lean time.
# The times are ints; the rest are floats.
const WALL_IMPOSSIBLE: Dictionary[String, Variant] = {
	"wall_min_incline_deg": -1.0,
	"wall_entry_speed_mps": -4.0,
	"wall_run_speed_mps": 0.0,
	"wall_max_speed_mps": -12.0,
	"wall_run_max_ms": -1,
	"wall_hold_ms": -1,
	"wall_slide_gravity_pct": -10.0,
	"wall_jump_height_m": 0.0,
	"wall_jump_push_mps": -5.0,
	"wall_same_face_deg": -10.0,
	"wall_clear_above_head_m": -0.3,
	"wall_lean_deg": -15.0,
	"wall_lean_ms": -1,
}

# The five numbers of the dash (movimento.md, "Dash"), each with one value that cannot be: a
# distance of zero (the speed derives from it), a duration that rounds to 0 ticks (the speed
# divides by it), a negative exit speed, a negative cooldown and a negative cost. The distance,
# the exit speed and the cost are floats; the duration and the cooldown are times.
const DASH_IMPOSSIBLE: Dictionary[String, Variant] = {
	"dash_distance_m": 0.0,
	"dash_ms": 0,
	"dash_exit_speed_mps": -7.0,
	"dash_cooldown_ms": -1,
	"dash_cost": -15.0,
}

# The five numbers of TASK-10.1 (movimento.md, "Pulo e ar" and "Stamina"), each with one value
# that cannot be: a height of zero, a max of zero, a negative cost, a negative wait and a
# negative regen. The height, the max, the cost and the regen are floats; the wait is a time.
const NEW_IMPOSSIBLE: Dictionary[String, Variant] = {
	"double_jump_height_m": 0.0,
	"stamina_max": 0.0,
	"double_jump_cost": -10.0,
	"stamina_wait_ms": -1,
	"stamina_regen_per_s": -30.0,
}


# The numbers of movimento.md as a MovementData built in code: the baseline each failure case
# breaks one number of. The .tres is checked against the same numbers in its own test.
func _design_data() -> MovementData:
	var data := MovementData.new()
	data.capsule_height_m = 1.8 # "O corpo"
	data.capsule_radius_m = 0.35 # "O corpo"
	data.max_slope_deg = 45.0 # "O corpo": above it, it is not floor
	data.run_speed_mps = 7.0 # "Chão"
	data.accel_time_ms = 150 # "Chão"
	data.stop_time_ms = 100 # "Chão"
	data.jump_height_m = 1.2 # "Pulo e ar"
	data.jump_rise_ms = 350 # "Pulo e ar"
	data.jump_fall_ms = 280 # "Pulo e ar"
	data.air_control_pct = 25.0 # "Pulo e ar": 25 % of the ground acceleration
	data.max_fall_speed_mps = 30.0 # "Pulo e ar"
	data.coyote_ms = 100 # "Perdão"
	data.buffer_ms = 150 # "Perdão"
	data.double_jump_height_m = 1.0 # "Pulo e ar": "Altura do pulo duplo"
	data.double_jump_cost = 10.0 # "Pulo e ar": "Custo do pulo duplo"
	data.stamina_max = 100.0 # "Stamina": "Máximo"
	data.stamina_wait_ms = 800 # "Stamina": "Espera para recuperar"
	data.stamina_regen_per_s = 30.0 # "Stamina": "Recuperação"
	data.dash_distance_m = 4.0 # "Dash": "Distância"
	data.dash_ms = 200 # "Dash": "Duração"
	data.dash_exit_speed_mps = 7.0 # "Dash": "Velocidade na saída"
	data.dash_cooldown_ms = 400 # "Dash": "Recarga"
	data.dash_cost = 15.0 # "Dash": "Custo"
	data.wall_min_incline_deg = 80.0 # "Corrida na parede": "Inclinação mínima da parede"
	data.wall_entry_speed_mps = 4.0 # "Corrida na parede": "Velocidade mínima para entrar"
	data.wall_run_speed_mps = 8.0 # "Corrida na parede": "Velocidade na parede"
	data.wall_max_speed_mps = 12.0 # "Corrida na parede": "Teto de velocidade na parede"
	data.wall_run_max_ms = 2500 # "Corrida na parede": "Duração máxima"
	data.wall_hold_ms = 1500 # "Corrida na parede": "Altura: mantida por 1,5 s"
	data.wall_slide_gravity_pct = 10.0 # "Corrida na parede": "Altura: 10% da gravidade"
	data.wall_jump_height_m = 1.2 # "Corrida na parede": "Pulo da parede"
	data.wall_jump_push_mps = 5.0 # "Corrida na parede": "Pulo da parede: 5 m/s para fora"
	data.wall_same_face_deg = 10.0 # "Corrida na parede": "Mesma parede, em números"
	data.wall_clear_above_head_m = 0.3 # "A parede passa da cabeça": 2,1 m above the feet
	data.wall_lean_deg = 15.0 # "Corrida na parede": "O que se vê na parede"
	data.wall_lean_ms = 100 # "Corrida na parede": "O que se vê na parede"
	data.grapple_range_m = 25.0 # "Gancho": "Alcance"
	data.grapple_min_range_m = 3.0 # "Gancho": "Alcance mínimo"
	data.grapple_attach_ms = 100 # "Gancho": "Tempo até prender"
	data.grapple_pull_speed_mps = 18.0 # "Gancho": "Velocidade da puxada"
	data.grapple_release_distance_m = 1.5 # "Gancho": "Como solta"
	data.grapple_block_pct = 50.0 # "Gancho": "Trava"
	data.grapple_cooldown_ms = 6000 # "Gancho": "Recarga"
	data.aim_height_m = 1.6 # "Gancho": "De onde sai a mira"
	data.aim_side_m = 0.8 # "Gancho": "De onde sai a mira"; "Câmera": "Ombro" (DEC-0045 §2)
	data.head_slide_speed_mps = 3.0 # "O corpo": "Escorregar da cabeça" (TASK-10.7)
	return data


func _load_v0() -> MovementData:
	var resource: Resource = load(MOVEMENT_V0)
	assert(
		resource is MovementData,
		"%s must load as a MovementData (TASK-9, part 1)" % MOVEMENT_V0,
	)
	return resource as MovementData


# Every .tres under a folder, recursively.
func _tres_files_under(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(dir_path)
	assert(dir != null, "%s must exist (TASK-9, part 1)" % dir_path)
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


func test_movement_v0_holds_the_numbers_of_movimento_md() -> void:
	var data := _load_v0()
	var design := _design_data()
	assert_float(data.capsule_height_m).is_equal_approx(design.capsule_height_m, HAIR)
	assert_float(data.capsule_radius_m).is_equal_approx(design.capsule_radius_m, HAIR)
	assert_float(data.max_slope_deg).is_equal_approx(design.max_slope_deg, HAIR)
	assert_float(data.run_speed_mps).is_equal_approx(design.run_speed_mps, HAIR)
	assert_int(data.accel_time_ms).is_equal(design.accel_time_ms)
	assert_int(data.stop_time_ms).is_equal(design.stop_time_ms)
	assert_float(data.jump_height_m).is_equal_approx(design.jump_height_m, HAIR)
	assert_int(data.jump_rise_ms).is_equal(design.jump_rise_ms)
	assert_int(data.jump_fall_ms).is_equal(design.jump_fall_ms)
	assert_float(data.air_control_pct).is_equal_approx(design.air_control_pct, HAIR)
	assert_float(data.max_fall_speed_mps).is_equal_approx(design.max_fall_speed_mps, HAIR)
	assert_int(data.coyote_ms).is_equal(design.coyote_ms)
	assert_int(data.buffer_ms).is_equal(design.buffer_ms)
	assert_float(data.double_jump_height_m).is_equal_approx(design.double_jump_height_m, HAIR)
	assert_float(data.double_jump_cost).is_equal_approx(design.double_jump_cost, HAIR)
	assert_float(data.stamina_max).is_equal_approx(design.stamina_max, HAIR)
	assert_int(data.stamina_wait_ms).is_equal(design.stamina_wait_ms)
	assert_float(data.stamina_regen_per_s).is_equal_approx(design.stamina_regen_per_s, HAIR)
	assert_float(data.dash_distance_m).is_equal_approx(design.dash_distance_m, HAIR)
	assert_int(data.dash_ms).is_equal(design.dash_ms)
	assert_float(data.dash_exit_speed_mps).is_equal_approx(design.dash_exit_speed_mps, HAIR)
	assert_int(data.dash_cooldown_ms).is_equal(design.dash_cooldown_ms)
	assert_float(data.dash_cost).is_equal_approx(design.dash_cost, HAIR)
	assert_float(data.wall_min_incline_deg).is_equal_approx(design.wall_min_incline_deg, HAIR)
	assert_float(data.wall_entry_speed_mps).is_equal_approx(design.wall_entry_speed_mps, HAIR)
	assert_float(data.wall_run_speed_mps).is_equal_approx(design.wall_run_speed_mps, HAIR)
	assert_float(data.wall_max_speed_mps).is_equal_approx(design.wall_max_speed_mps, HAIR)
	assert_int(data.wall_run_max_ms).is_equal(design.wall_run_max_ms)
	assert_int(data.wall_hold_ms).is_equal(design.wall_hold_ms)
	assert_float(data.wall_slide_gravity_pct).is_equal_approx(design.wall_slide_gravity_pct, HAIR)
	assert_float(data.wall_jump_height_m).is_equal_approx(design.wall_jump_height_m, HAIR)
	assert_float(data.wall_jump_push_mps).is_equal_approx(design.wall_jump_push_mps, HAIR)
	assert_float(data.wall_same_face_deg).is_equal_approx(design.wall_same_face_deg, HAIR)
	assert_float(data.wall_clear_above_head_m).is_equal_approx(design.wall_clear_above_head_m, HAIR)
	assert_float(data.wall_lean_deg).is_equal_approx(design.wall_lean_deg, HAIR)
	assert_int(data.wall_lean_ms).is_equal(design.wall_lean_ms)
	assert_float(data.grapple_range_m).is_equal_approx(design.grapple_range_m, HAIR)
	assert_float(data.grapple_min_range_m).is_equal_approx(design.grapple_min_range_m, HAIR)
	assert_int(data.grapple_attach_ms).is_equal(design.grapple_attach_ms)
	assert_float(data.grapple_pull_speed_mps).is_equal_approx(design.grapple_pull_speed_mps, HAIR)
	assert_float(data.grapple_release_distance_m).is_equal_approx(
		design.grapple_release_distance_m,
		HAIR,
	)
	assert_float(data.grapple_block_pct).is_equal_approx(design.grapple_block_pct, HAIR)
	assert_int(data.grapple_cooldown_ms).is_equal(design.grapple_cooldown_ms)
	assert_float(data.aim_height_m).is_equal_approx(design.aim_height_m, HAIR)
	assert_float(data.aim_side_m).is_equal_approx(design.aim_side_m, HAIR)
	assert_float(data.head_slide_speed_mps).is_equal_approx(design.head_slide_speed_mps, HAIR)


# TASK-10.7: the slide off another fighter's head is 3,0 m/s in movement_v0.tres and in the
# design, as a MovementData field (movimento.md, "O corpo": "Escorregar da cabeça"; TASK-10.7
# plan, Data).
func test_movement_v0_holds_the_head_slide_speed_of_3_mps() -> void:
	assert_float(_load_v0().head_slide_speed_mps).is_equal_approx(3.0, HAIR)
	assert_float(_design_data().head_slide_speed_mps).is_equal_approx(3.0, HAIR)


# TASK-10.7: the slide needs a speed, or whoever lands on a head would never leave it
# (movimento.md, "O corpo": "Escorregar da cabeça"; TASK-10.7 plan, Data: "positive"): 0 and a
# negative value are rejected with one message naming the field.
func test_a_head_slide_speed_that_is_not_positive_is_rejected(
	mps: float,
	_test_parameters := [[0.0], [-3.0], [-0.01]],
) -> void:
	var data := _design_data()
	data.head_slide_speed_mps = mps
	_assert_one_message_naming(
		data.validate(),
		"head_slide_speed_mps",
		"a head slide of %.2f m/s must be rejected" % mps,
	)


func test_a_positive_head_slide_speed_is_allowed(
	mps: float,
	_test_parameters := [[0.01], [3.0], [30.0]],
) -> void:
	var data := _design_data()
	data.head_slide_speed_mps = mps
	var message := "a head slide of %.2f m/s must pass" % mps
	assert_array(data.validate()).override_failure_message(message).is_empty()


# Many: the head slide wrong together with another number gives one message each, naming its
# own field.
func test_a_bad_head_slide_speed_and_a_bad_dash_cost_give_two_messages() -> void:
	var data := _design_data()
	data.head_slide_speed_mps = 0.0
	data.dash_cost = -15.0
	var errors := data.validate()
	assert_array(errors).override_failure_message("%s" % [errors]).has_size(2)
	_assert_some_message_names(errors, "head_slide_speed_mps")
	_assert_some_message_names(errors, "dash_cost")


# TASK-10.11: the aim's side is signed, 0 the shoulder and negative the left one, so no value
# of it is impossible (movimento.md, "Câmera": "Ombro"; its own checks live in
# movement_data_grapple_test.gd).
func test_an_aim_side_of_zero_or_negative_passes_the_data_check(
	side_m: float,
	_test_parameters := [[0.0], [-0.8]],
) -> void:
	var data := _design_data()
	data.aim_side_m = side_m
	var message := "aim_side_m = %s must pass" % side_m
	assert_array(data.validate()).override_failure_message(message).is_empty()


func test_movement_v0_passes_the_data_check() -> void:
	assert_array(_load_v0().validate()).is_empty()


func test_the_design_numbers_pass_the_data_check() -> void:
	assert_array(_design_data().validate()).is_empty()


# The gate's data check: a bad movement .tres committed anywhere under data/ fails here.
func test_every_movement_tres_under_data_passes_the_data_check() -> void:
	var checked := 0
	for path: String in _tres_files_under(DATA_DIR):
		var resource: Resource = load(path)
		assert_object(resource).override_failure_message("%s does not load" % path).is_not_null()
		if resource is MovementData:
			var data := resource as MovementData
			var errors := data.validate()
			var message := "%s has impossible numbers: %s" % [path, errors]
			assert_array(errors).override_failure_message(message).is_empty()
			checked += 1
	var none := "no MovementData under %s: the scan found nothing to check" % DATA_DIR
	assert_int(checked).override_failure_message(none).is_greater_equal(1)


func test_a_negative_time_is_rejected(
	field: String,
	_test_parameters := [
		["accel_time_ms"],
		["stop_time_ms"],
		["jump_rise_ms"],
		["jump_fall_ms"],
		["coyote_ms"],
		["buffer_ms"],
		["stamina_wait_ms"],
		["dash_ms"],
		["dash_cooldown_ms"],
		["wall_hold_ms"],
	],
) -> void:
	var data := _design_data()
	data.set(field, -1)
	assert_int(data.get(field)).override_failure_message("%s is not a field" % field).is_equal(-1)
	var errors := data.validate()
	assert_array(errors).override_failure_message("%s = -1 must be rejected" % field).has_size(1)
	_assert_one_readable_message(errors)


# Acceleration is speed / time, deceleration is speed / time, and the jump's gravity and exit
# speed come from the rise and fall times (movimento.md, the "Deriva" notes of "Chão" and "Pulo
# e ar"): zero there divides by zero. The dash's speed is its distance over its duration
# (movimento.md, "Dash": "Deriva a velocidade"), TASK-10.4.
func test_a_zero_time_where_the_rule_divides_is_rejected(
	field: String,
	_test_parameters := [
		["accel_time_ms"],
		["stop_time_ms"],
		["jump_rise_ms"],
		["jump_fall_ms"],
		["dash_ms"],
	],
) -> void:
	var data := _design_data()
	data.set(field, 0)
	assert_int(data.get(field)).override_failure_message("%s is not a field" % field).is_equal(0)
	var errors := data.validate()
	assert_array(errors).override_failure_message("%s = 0 must be rejected" % field).has_size(1)
	_assert_one_readable_message(errors)


# Nothing divides by the windows ("Perdão"): zero is a legitimate "no forgiveness".
func test_a_zero_forgiveness_window_is_allowed(
	field: String,
	_test_parameters := [["coyote_ms"], ["buffer_ms"]],
) -> void:
	var data := _design_data()
	data.set(field, 0)
	assert_int(data.get(field)).override_failure_message("%s is not a field" % field).is_equal(0)
	assert_array(data.validate()).override_failure_message("%s = 0 must pass" % field).is_empty()


func test_a_slope_above_90_degrees_is_rejected(
	deg: float,
	_test_parameters := [[90.5], [91.0], [180.0]],
) -> void:
	var data := _design_data()
	data.max_slope_deg = deg
	var errors := data.validate()
	assert_array(errors).override_failure_message("slope %.1f° must be rejected" % deg).has_size(1)
	_assert_one_readable_message(errors)


func test_a_slope_up_to_90_degrees_is_allowed(
	deg: float,
	_test_parameters := [[0.0], [45.0], [90.0]],
) -> void:
	var data := _design_data()
	data.max_slope_deg = deg
	assert_array(data.validate()).override_failure_message("slope %.1f° must pass" % deg).is_empty()


func test_a_negative_slope_is_rejected() -> void:
	var data := _design_data()
	data.max_slope_deg = -1.0
	assert_array(data.validate()).has_size(1)


# The other numbers that cannot be: a negative speed, height, fall cap or air control, a
# capsule without height or radius (movimento.md, "O corpo", "Chão" and "Pulo e ar"), and from
# TASK-10.1 a double jump without height, a negative cost and a negative regen (movimento.md,
# "Pulo e ar" and "Stamina"; the double jump's exit speed comes from its height, so zero is
# no jump).
func test_other_impossible_numbers_are_rejected(
	field: String,
	value: float,
	_test_parameters := [
		["run_speed_mps", -7.0],
		["jump_height_m", -1.2],
		["max_fall_speed_mps", -30.0],
		["air_control_pct", -25.0],
		["capsule_height_m", 0.0],
		["capsule_height_m", -1.8],
		["capsule_radius_m", 0.0],
		["capsule_radius_m", -0.35],
		["double_jump_height_m", 0.0],
		["double_jump_height_m", -1.0],
		["double_jump_cost", -10.0],
		["stamina_regen_per_s", -30.0],
		["dash_distance_m", 0.0],
		["dash_distance_m", -4.0],
		["dash_exit_speed_mps", -7.0],
		["dash_cost", -15.0],
	],
) -> void:
	var data := _design_data()
	data.set(field, value)
	assert_float(data.get(field)).override_failure_message("%s is not a field" % field).is_equal(
		value
	)
	var errors := data.validate()
	var message := "%s = %s must be rejected" % [field, value]
	assert_array(errors).override_failure_message(message).has_size(1)
	_assert_one_readable_message(errors)


func test_every_impossible_number_gets_its_own_message() -> void:
	var data := _design_data()
	data.accel_time_ms = -150
	data.jump_rise_ms = 0
	data.max_slope_deg = 100.0
	assert_array(data.validate()).has_size(3)


func test_every_negative_time_gives_its_own_message() -> void:
	var data := _design_data()
	for field: String in TIME_FIELDS:
		data.set(field, -1)
	assert_array(data.validate()).has_size(TIME_FIELDS.size())


# TASK-10.1, criterion 7: the wait may be 0 ms (no wait; nothing divides by it) and the regen
# may be 0 points/s (the test fixtures freeze the bar that way, TASK-10.1 plan).
func test_a_zero_stamina_wait_or_regen_is_allowed(
	field: String,
	value: Variant,
	_test_parameters := [["stamina_wait_ms", 0], ["stamina_regen_per_s", 0.0]],
) -> void:
	var data := _design_data()
	data.set(field, value)
	assert_bool(data.get(field) == value).override_failure_message("%s is not a field" % field) \
			.is_true()
	assert_array(data.validate()).override_failure_message("%s = 0 must pass" % field).is_empty()


# The cost must fit the bar: above the max it is rejected with a message naming the cost; at
# the max (the limit) and at zero (none) it passes (TASK-10.1 plan: "não negativo e até
# stamina_max").
func test_a_double_jump_cost_above_the_stamina_max_is_rejected() -> void:
	var data := _design_data()
	data.double_jump_cost = data.stamina_max + 0.5
	var errors := data.validate()
	assert_array(errors).override_failure_message("cost above the max must be rejected") \
			.has_size(1)
	if errors.size() == 1:
		assert_str(errors[0]).contains("double_jump_cost")


func test_a_double_jump_cost_up_to_the_stamina_max_is_allowed(
	cost: float,
	_test_parameters := [[0.0], [10.0], [100.0]],
) -> void:
	var data := _design_data()
	data.double_jump_cost = cost
	assert_array(data.validate()).override_failure_message("cost %.1f must pass" % cost) \
			.is_empty()


# A bar with no points cannot pay anything: the max must be positive (movimento.md, "Stamina").
# The cost is set to 0 so that only the max is wrong: exactly one message, naming it.
func test_a_stamina_max_of_zero_is_rejected() -> void:
	var data := _design_data()
	data.double_jump_cost = 0.0
	data.stamina_max = 0.0
	var errors := data.validate()
	assert_array(errors).override_failure_message("stamina_max = 0 must be rejected").has_size(1)
	if errors.size() == 1:
		assert_str(errors[0]).contains("stamina_max")


# A negative max is rejected with a message naming it; whether a cost of 0 "above" a negative
# max adds a second message is the implementer's call, so only the max's message is required.
func test_a_negative_stamina_max_is_rejected() -> void:
	var data := _design_data()
	data.double_jump_cost = 0.0
	data.stamina_max = -100.0
	var errors := data.validate()
	var named := false
	for message: String in errors:
		if message.contains("stamina_max"):
			named = true
	var unnamed := "no message names stamina_max, got: %s" % [errors]
	assert_bool(named).override_failure_message(unnamed).is_true()


# Many: the five new numbers wrong at once give five messages, each naming its field; with the
# cost negative, no "cost above max" message can double up on the zero max.
func test_five_impossible_new_numbers_give_five_messages_each_naming_its_field() -> void:
	var data := _design_data()
	for field: String in NEW_IMPOSSIBLE:
		data.set(field, NEW_IMPOSSIBLE[field])
		var set_message := "%s is not a field" % field
		assert_bool(data.get(field) == NEW_IMPOSSIBLE[field]) \
				.override_failure_message(set_message) \
				.is_true()
	var errors := data.validate()
	assert_array(errors).has_size(NEW_IMPOSSIBLE.size())
	for field: String in NEW_IMPOSSIBLE:
		var named := false
		for message: String in errors:
			if message.contains(field):
				named = true
		var unnamed := "no message names %s, got: %s" % [field, errors]
		assert_bool(named).override_failure_message(unnamed).is_true()


# TASK-10.4: nothing divides by the cooldown of the dash (movimento.md, "Dash": "Recarga"), so
# 0 ms is a legitimate "no cooldown", like the two windows of "Perdão".
func test_a_zero_dash_cooldown_is_allowed() -> void:
	var data := _design_data()
	data.dash_cooldown_ms = 0
	assert_array(data.validate()).override_failure_message("dash_cooldown_ms = 0 must pass") \
			.is_empty()


# TASK-10.4: the exit speed may be 0 (the dash stops dead) and the cost may be 0 (a free dash),
# both legitimate; only negatives are impossible (TASK-10.4 plan: "not negative").
func test_a_zero_dash_exit_speed_or_cost_is_allowed(
	field: String,
	_test_parameters := [["dash_exit_speed_mps"], ["dash_cost"]],
) -> void:
	var data := _design_data()
	data.set(field, 0.0)
	assert_float(data.get(field)).override_failure_message("%s is not a field" % field).is_equal(
		0.0
	)
	assert_array(data.validate()).override_failure_message("%s = 0 must pass" % field).is_empty()


# TASK-10.4: the cost of the dash must fit the bar, like the double jump's (TASK-10.4 plan: "not
# negative, <= stamina_max"): above the max it is rejected with a message naming it; at the max
# (the limit) and at the design's 15 it passes.
func test_a_dash_cost_above_the_stamina_max_is_rejected() -> void:
	var data := _design_data()
	data.dash_cost = data.stamina_max + 0.5
	var errors := data.validate()
	assert_array(errors).override_failure_message("dash cost above the max must be rejected") \
			.has_size(1)
	if errors.size() == 1:
		assert_str(errors[0]).contains("dash_cost")


func test_a_dash_cost_up_to_the_stamina_max_is_allowed(
	cost: float,
	_test_parameters := [[0.0], [15.0], [100.0]],
) -> void:
	var data := _design_data()
	data.dash_cost = cost
	assert_array(data.validate()).override_failure_message("dash cost %.1f must pass" % cost) \
			.is_empty()


# Both costs above the max at once: one message each, naming its own field.
func test_both_costs_above_the_stamina_max_give_two_messages() -> void:
	var data := _design_data()
	data.double_jump_cost = data.stamina_max + 1.0
	data.dash_cost = data.stamina_max + 1.0
	var errors := data.validate()
	assert_array(errors).has_size(2)
	for field: String in ["double_jump_cost", "dash_cost"]:
		var named := false
		for message: String in errors:
			if message.contains(field):
				named = true
		assert_bool(named).override_failure_message("no message names %s: %s" % [field, errors]) \
				.is_true()


# Many: the five dash numbers wrong at once give five messages, each naming its field; with
# the cost negative, no "cost above max" message can double up.
func test_five_impossible_dash_numbers_give_five_messages_each_naming_its_field() -> void:
	var data := _design_data()
	for field: String in DASH_IMPOSSIBLE:
		data.set(field, DASH_IMPOSSIBLE[field])
		var set_message := "%s is not a field" % field
		assert_bool(data.get(field) == DASH_IMPOSSIBLE[field]) \
				.override_failure_message(set_message) \
				.is_true()
	var errors := data.validate()
	assert_array(errors).has_size(DASH_IMPOSSIBLE.size())
	for field: String in DASH_IMPOSSIBLE:
		var named := false
		for message: String in errors:
			if message.contains(field):
				named = true
		var unnamed := "no message names %s, got: %s" % [field, errors]
		assert_bool(named).override_failure_message(unnamed).is_true()


# TASK-10.5, criterion 7: the wall's incline must be a wall, not a floor: from the max slope
# (exclusive: at 45° it would be floor) up to 90° (inclusive). Outside 0 to 90 and at or below
# the max slope it is rejected with one message naming the field; 45,5°, 80° and 90° pass
# (movimento.md, "Corrida na parede": "Inclinação mínima da parede"; "O corpo": "Rampa máxima";
# TASK-10.5 plan, Data: "max_slope_deg < it <= 90").
func test_a_wall_incline_outside_the_max_slope_to_90_degrees_is_rejected(
	deg: float,
	_test_parameters := [[-1.0], [0.0], [44.0], [45.0], [90.5], [91.0], [180.0]],
) -> void:
	var data := _design_data()
	data.wall_min_incline_deg = deg
	var errors := data.validate()
	_assert_one_message_naming(
		errors,
		"wall_min_incline_deg",
		"incline %.1f° must be rejected" % deg,
	)


func test_a_wall_incline_above_the_max_slope_up_to_90_degrees_is_allowed(
	deg: float,
	_test_parameters := [[45.5], [80.0], [90.0]],
) -> void:
	var data := _design_data()
	data.wall_min_incline_deg = deg
	assert_array(data.validate()).override_failure_message("incline %.1f° must pass" % deg) \
			.is_empty()


# The entry speed cannot exceed the run speed on the wall, nor be negative: 8,5 and -4 are
# rejected naming the field; 0 (any touch enters) and 8 (the limit) pass (TASK-10.5 plan,
# Data: "not negative, ≤ run"; movimento.md, "Corrida na parede").
func test_a_wall_entry_speed_above_the_run_speed_or_negative_is_rejected(
	mps: float,
	_test_parameters := [[8.5], [-4.0]],
) -> void:
	var data := _design_data()
	data.wall_entry_speed_mps = mps
	var errors := data.validate()
	_assert_one_message_naming(
		errors,
		"wall_entry_speed_mps",
		"entry %.1f m/s must be rejected" % mps,
	)


func test_a_wall_entry_speed_up_to_the_run_speed_is_allowed(
	mps: float,
	_test_parameters := [[0.0], [4.0], [8.0]],
) -> void:
	var data := _design_data()
	data.wall_entry_speed_mps = mps
	assert_array(data.validate()).override_failure_message("entry %.1f m/s must pass" % mps) \
			.is_empty()


# The run speed must be positive. The entry speed is set to 0 so that only the run speed is
# wrong: exactly one message, naming it (TASK-10.5 plan, Data: "positive").
func test_a_wall_run_speed_that_is_not_positive_is_rejected(
	mps: float,
	_test_parameters := [[0.0], [-8.0]],
) -> void:
	var data := _design_data()
	data.wall_entry_speed_mps = 0.0
	data.wall_run_speed_mps = mps
	var errors := data.validate()
	_assert_one_message_naming(
		errors,
		"wall_run_speed_mps",
		"run speed %.1f must be rejected" % mps,
	)


# The ceiling cannot be below the run speed: 7,9, 0 and -12 are rejected naming the field; 8
# (the limit) and 12 pass (TASK-10.5 plan, Data: "≥ run"; movimento.md, "Corrida na parede":
# "Teto de velocidade na parede").
func test_a_wall_max_speed_below_the_run_speed_is_rejected(
	mps: float,
	_test_parameters := [[7.9], [0.0], [-12.0]],
) -> void:
	var data := _design_data()
	data.wall_max_speed_mps = mps
	var errors := data.validate()
	_assert_one_message_naming(errors, "wall_max_speed_mps", "ceiling %.1f must be rejected" % mps)


func test_a_wall_max_speed_from_the_run_speed_up_is_allowed(
	mps: float,
	_test_parameters := [[8.0], [12.0], [20.0]],
) -> void:
	var data := _design_data()
	data.wall_max_speed_mps = mps
	assert_array(data.validate()).override_failure_message("ceiling %.1f must pass" % mps) \
			.is_empty()


# The held height cannot outlast the run: 2501 ms against 2500 is rejected naming the hold;
# 2500 (the limit) and 0 (no held height: the slide starts at once) pass (TASK-10.5 plan,
# Data: "time, ≤ max"; movimento.md, "Corrida na parede": "Altura", "Duração máxima").
func test_a_wall_hold_longer_than_the_run_max_is_rejected() -> void:
	var data := _design_data()
	data.wall_hold_ms = data.wall_run_max_ms + 1
	var errors := data.validate()
	_assert_one_message_naming(
		errors,
		"wall_hold_ms",
		"a hold longer than the run must be rejected",
	)


func test_a_wall_hold_up_to_the_run_max_is_allowed(
	ms: int,
	_test_parameters := [[0], [1500], [2500]],
) -> void:
	var data := _design_data()
	data.wall_hold_ms = ms
	assert_array(data.validate()).override_failure_message("hold %d ms must pass" % ms).is_empty()


# Both wall times negative at once: one message each, naming its own field (equal, so neither
# exceeds the other).
func test_negative_wall_times_give_one_message_each() -> void:
	var data := _design_data()
	data.wall_run_max_ms = -1
	data.wall_hold_ms = -1
	var errors := data.validate()
	assert_array(errors).has_size(2)
	_assert_some_message_names(errors, "wall_run_max_ms")
	_assert_some_message_names(errors, "wall_hold_ms")


# A negative run max alone is rejected with a message naming it; whether the design's hold of
# 1500 ms "exceeding" a negative max adds a second message is the implementer's call.
func test_a_negative_wall_run_max_is_rejected() -> void:
	var data := _design_data()
	data.wall_run_max_ms = -1
	_assert_some_message_names(data.validate(), "wall_run_max_ms")


# The slide's share of the gravity is a percentage: outside 0 to 100 it is rejected naming the
# field; 0 (no slide), 10 and 100 (the full rise gravity) pass (TASK-10.5 plan, Data:
# "0..100"; movimento.md, "Corrida na parede": "Altura: 10% da gravidade de subida").
func test_a_wall_slide_gravity_outside_0_to_100_percent_is_rejected(
	pct: float,
	_test_parameters := [[-1.0], [100.5], [101.0], [200.0]],
) -> void:
	var data := _design_data()
	data.wall_slide_gravity_pct = pct
	var errors := data.validate()
	_assert_one_message_naming(errors, "wall_slide_gravity_pct", "%.1f %% must be rejected" % pct)


func test_a_wall_slide_gravity_from_0_to_100_percent_is_allowed(
	pct: float,
	_test_parameters := [[0.0], [10.0], [100.0]],
) -> void:
	var data := _design_data()
	data.wall_slide_gravity_pct = pct
	assert_array(data.validate()).override_failure_message("%.1f %% must pass" % pct).is_empty()


# The wall jump's exit speed derives from its height, so zero is no jump: 0 and -1,2 are
# rejected naming the field (TASK-10.5 plan, Data: "positive"; movimento.md, "Corrida na
# parede": "Pulo da parede").
func test_a_wall_jump_height_that_is_not_positive_is_rejected(
	height_m: float,
	_test_parameters := [[0.0], [-1.2]],
) -> void:
	var data := _design_data()
	data.wall_jump_height_m = height_m
	var errors := data.validate()
	_assert_one_message_naming(
		errors,
		"wall_jump_height_m",
		"height %.1f must be rejected" % height_m,
	)


# The push out of the wall cannot be negative (it would push into the wall); 0 (straight up)
# passes (TASK-10.5 plan, Data: "not negative").
func test_a_negative_wall_jump_push_is_rejected() -> void:
	var data := _design_data()
	data.wall_jump_push_mps = -5.0
	_assert_one_message_naming(data.validate(), "wall_jump_push_mps", "a negative push must fail")


func test_a_zero_wall_jump_push_is_allowed() -> void:
	var data := _design_data()
	data.wall_jump_push_mps = 0.0
	assert_array(data.validate()).override_failure_message("a push of 0 must pass").is_empty()


# The same-face angle goes from 0 to 90°: outside it is rejected naming the field; 0 (only the
# exact normal), 10 and 90 (any face of the collider) pass (TASK-10.5 plan, Data: "0..90";
# movimento.md, "Corrida na parede": "Mesma parede, em números").
func test_a_wall_same_face_angle_outside_0_to_90_degrees_is_rejected(
	deg: float,
	_test_parameters := [[-1.0], [90.5], [91.0], [180.0]],
) -> void:
	var data := _design_data()
	data.wall_same_face_deg = deg
	var errors := data.validate()
	_assert_one_message_naming(
		errors,
		"wall_same_face_deg",
		"same face %.1f° must be rejected" % deg,
	)


func test_a_wall_same_face_angle_from_0_to_90_degrees_is_allowed(
	deg: float,
	_test_parameters := [[0.0], [10.0], [90.0]],
) -> void:
	var data := _design_data()
	data.wall_same_face_deg = deg
	assert_array(data.validate()).override_failure_message("same face %.1f° must pass" % deg) \
			.is_empty()


# The ray stands at or above the capsule's top: below it, inside the capsule, is rejected naming
# the field; at the top, at the 30 cm of the design and far above it passes (movimento.md,
# "Corrida na parede": "A parede passa da cabeça"; TASK-10.10).
func test_a_ray_inside_the_capsule_is_rejected(
	clear_m: float,
	_test_parameters := [[-0.01], [-0.3], [-1.8]],
) -> void:
	var data := _design_data()
	data.wall_clear_above_head_m = clear_m
	_assert_one_message_naming(
		data.validate(),
		"wall_clear_above_head_m",
		"a ray %.2f m above the head must be rejected" % clear_m,
	)


func test_a_ray_at_or_above_the_head_is_allowed(
	clear_m: float,
	_test_parameters := [[0.0], [0.3], [3.0]],
) -> void:
	var data := _design_data()
	data.wall_clear_above_head_m = clear_m
	var message := "a ray %.2f m above the head must pass" % clear_m
	assert_array(data.validate()).override_failure_message(message).is_empty()


# The lean on screen goes from 0 to 90°, and its time is not negative; 0 ms leans at once
# (movimento.md, "Corrida na parede": "O que se vê na parede"; TASK-10.10).
func test_a_lean_outside_0_to_90_degrees_is_rejected(
	deg: float,
	_test_parameters := [[-1.0], [90.5]],
) -> void:
	var data := _design_data()
	data.wall_lean_deg = deg
	_assert_one_message_naming(data.validate(), "wall_lean_deg", "lean %.1f° must fail" % deg)


func test_a_negative_lean_time_is_rejected_and_zero_is_allowed() -> void:
	var data := _design_data()
	data.wall_lean_ms = -1
	_assert_one_message_naming(data.validate(), "wall_lean_ms", "a lean of -1 ms must fail")
	data.wall_lean_ms = 0
	assert_array(data.validate()).override_failure_message("a lean of 0 ms must pass").is_empty()


# Many: the thirteen wall numbers wrong at once give thirteen messages, each naming its field.
func test_every_impossible_wall_number_gives_its_own_message_naming_its_field() -> void:
	var data := _design_data()
	for field: String in WALL_IMPOSSIBLE:
		data.set(field, WALL_IMPOSSIBLE[field])
		var set_message := "%s is not a field" % field
		assert_bool(data.get(field) == WALL_IMPOSSIBLE[field]) \
				.override_failure_message(set_message) \
				.is_true()
	var errors := data.validate()
	assert_array(errors).override_failure_message("%s" % [errors]).has_size(WALL_IMPOSSIBLE.size())
	for field: String in WALL_IMPOSSIBLE:
		_assert_some_message_names(errors, field)


# Exactly one message (one per impossible number, TASK-9 plan, part 1), and it names the field,
# so the gate's print says which number to fix. The wording beyond the name is the implementer's.
func _assert_one_message_naming(errors: PackedStringArray, field: String, why: String) -> void:
	assert_array(errors).override_failure_message("%s, got: %s" % [why, errors]).has_size(1)
	if errors.size() == 1:
		var unnamed := "the message must name %s, got: %s" % [field, errors[0]]
		assert_str(errors[0]).override_failure_message(unnamed).contains(field)


func _assert_some_message_names(errors: PackedStringArray, field: String) -> void:
	var named := false
	for message: String in errors:
		if message.contains(field):
			named = true
	var unnamed := "no message names %s, got: %s" % [field, errors]
	assert_bool(named).override_failure_message(unnamed).is_true()


# The gate prints the message: it must say something. Guarded, so a missing rejection fails on
# the size assertion above instead of on an index error here.
func _assert_one_readable_message(errors: PackedStringArray) -> void:
	if errors.size() == 1:
		assert_str(errors[0]).is_not_empty()
