# Criterion 2 of TASK-10 (DEC-0017; DEC-0004, rule 3): a movement number changed in a copy of the
# Resource changes the game without touching code. The double jump goes from 1,0 to 1,5 m on a
# duplicate() of movement_v0.tres; the copy passes validate(), its configuration is made the way
# the Match makes it at load (MovementConfig.create), and the top of a double jump, measured
# through the simulation, is 1,5 m above the press within 1 cm at 60 ticks. The simulation is the
# core with the engine's slice of the tick played by MovementRig on a flat floor, as the movement
# tests fly a body (test/core/fighter/movement_rig.gd). The cached movement_v0.tres still says
# 1,0 m afterwards, and its own configuration still tops 1,0 m: the copy never reaches it. It
# prints the measured top for the docs.
extends GdUnitTestSuite

const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const TICKRATE := 60
const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
const DESIGN_HEIGHT_M := 1.0 # movimento.md, "Pulo e ar": "Altura do pulo duplo"
const TUNED_HEIGHT_M := 1.5 # TASK-10, criterion 2: "o pulo duplo de 1,0 para 1,5 m"
const HEIGHT_TOLERANCE_M := 0.01 # 1 cm (visao-geral.md, "O tempo e a física no estado")
## Ticks after the jump when the double jump is pressed: still rising, as a player would.
const PRESS_AFTER := 3
const HAIR := 1e-6 # floating-point slack, not a design number


func test_a_copy_of_the_resource_with_a_1_5_m_double_jump_tops_1_5_m_without_code() -> void:
	var original := _cached()
	var copy: Resource = original.duplicate()
	assert(copy is MovementData, "a duplicate must still be a MovementData")
	var tuned := copy as MovementData
	assert_object(tuned).is_not_same(original)
	tuned.double_jump_height_m = TUNED_HEIGHT_M
	assert_array(tuned.validate()).is_empty()
	var rise := _double_jump_rise(MovementConfig.create(tuned, TICKRATE))
	var message := "the double jump of the copy rose %.4f m above the press" % rise
	print("Tuning: %s, %.1f m in the copy" % [message, TUNED_HEIGHT_M])
	assert_float(rise).override_failure_message(message).is_equal_approx(
		TUNED_HEIGHT_M,
		HEIGHT_TOLERANCE_M,
	)


# The copy changed in the test above, or here, never reaches the file's resource: load() hands
# back the same cached object, which still says 1,0 m and still tops 1,0 m.
func test_the_cached_resource_keeps_its_1_m_double_jump_when_a_copy_changes() -> void:
	var original := _cached()
	var copy: Resource = original.duplicate()
	assert(copy is MovementData, "a duplicate must still be a MovementData")
	(copy as MovementData).double_jump_height_m = TUNED_HEIGHT_M
	var again := _cached()
	assert_object(again).is_same(original)
	assert_float(again.double_jump_height_m).is_equal_approx(DESIGN_HEIGHT_M, HAIR)
	var rise := _double_jump_rise(MovementConfig.create(again, TICKRATE))
	var message := "the double jump of movement_v0.tres rose %.4f m above the press" % rise
	assert_float(rise).override_failure_message(message).is_equal_approx(
		DESIGN_HEIGHT_M,
		HEIGHT_TOLERANCE_M,
	)


func _cached() -> MovementData:
	var resource: Resource = load(MovementRig.MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MovementRig.MOVEMENT_V0)
	return resource as MovementData


# m: how far the double jump takes the feet above where it was pressed. The fighter jumps from the
# floor, presses again PRESS_AFTER ticks later, and the flight is followed up to the landing.
func _double_jump_rise(config: MovementConfig) -> float:
	var rig := MovementRig.new(config, FIRST_TICK)
	rig.step(MovementRig.press_jump())
	rig.rest(PRESS_AFTER - 1)
	var press_height := rig.position.y
	var plan := rig.step(MovementRig.press_jump())
	assert_int(plan.state.jumps_used).override_failure_message("no double jump").is_equal(2)
	var apex := rig.position.y
	for _step: int in 5 * config.tickrate:
		rig.step(MovementRig.idle())
		apex = maxf(apex, rig.position.y)
		if rig.state.on_floor:
			break
	assert_bool(rig.state.on_floor).override_failure_message("never landed").is_true()
	return apex - press_height
