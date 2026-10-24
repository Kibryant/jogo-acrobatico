# Criterion 5 of TASK-10.10, the lean on screen (movimento.md, "Corrida na parede": "O que se vê na
# parede"; Q-37): during a wall run the capsule's mesh and its visor lean 15° away from the wall,
# pivoting on the feet, coming in over 100 ms and going out over 100 ms, per displayed frame. Only
# the visual node moves: the state, the body and the collision capsule stay as they were, so no
# rollback, replay or SyncTest ever sees the lean (DEC-0031 §6; DEC-0004, rule 2). Driven through
# Fighter.lean, the call _process makes on every frame, with the frame's time given by hand.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
const MOVEMENT_V0 := "res://data/movement_v0.tres"

const LEAN_DEG := 15.0 # movimento.md, "O que se vê na parede"
const LEAN_S := 0.1 # movimento.md, "O que se vê na parede": 100 ms
const YAW := 0.7 # where the body looks: any yaw, the lean keeps it
const HAIR := 1e-4 # floating-point slack of a basis, not a design number


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


func _fighter() -> Fighter:
	var resource: Resource = load(MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MOVEMENT_V0)
	var config := MovementConfig.create(resource as MovementData, 60)
	var node: Node = auto_free(FIGHTER_SCENE.instantiate())
	assert(node is Fighter, "fighter.tscn must have a Fighter at its root")
	var fighter := node as Fighter
	fighter.setup(config, Vector3(1, 2, 3), YAW, true)
	add_child(fighter)
	return fighter


# On the wall facing +X (the body on its +X side).
func _run_on_the_wall(fighter: Fighter) -> void:
	fighter.state.mode = FighterState.Mode.WALL_RUN
	fighter.state.on_floor = false
	fighter.state.wall_normal = Vector3.RIGHT
	fighter.state.wall_id = &"Parede"


# The angle between the visual's up and the world's up, in degrees.
func _tilt_deg(fighter: Fighter) -> float:
	return rad_to_deg(fighter.visual.global_transform.basis.y.normalized().angle_to(Vector3.UP))


func test_the_capsule_leans_15_degrees_away_from_the_wall_over_100_ms() -> void:
	var fighter := _fighter()
	_run_on_the_wall(fighter)
	fighter.lean(LEAN_S / 2.0)
	assert_float(_tilt_deg(fighter)).is_equal_approx(LEAN_DEG / 2.0, HAIR)
	fighter.lean(LEAN_S / 2.0)
	assert_float(_tilt_deg(fighter)).is_equal_approx(LEAN_DEG, HAIR)
	assert_float(rad_to_deg(fighter.lean_angle())).is_equal_approx(LEAN_DEG, HAIR)
	# The limit: it never leans past 15°, however long the run.
	fighter.lean(1.0)
	assert_float(_tilt_deg(fighter)).is_equal_approx(LEAN_DEG, HAIR)
	# Away from the wall: the top goes toward the wall's normal, the feet stay where they are.
	var up := fighter.visual.global_transform.basis.y.normalized()
	assert_float(up.x).is_equal_approx(sin(deg_to_rad(LEAN_DEG)), HAIR)
	assert_float(up.z).is_equal_approx(0.0, HAIR)
	assert_vector(fighter.visual.global_position).is_equal_approx(
		fighter.global_position,
		Vector3.ONE * HAIR,
	)
	# The body still looks where the state says: the facing, turned only by the lean.
	var forward := -fighter.visual.global_transform.basis.z.normalized()
	var flat := Vector3(forward.x, 0.0, forward.z).normalized()
	var facing := -Basis(Vector3.UP, YAW).z
	assert_float(flat.dot(facing)).is_greater(cos(deg_to_rad(LEAN_DEG)))


func test_the_lean_goes_out_over_100_ms_when_the_run_ends() -> void:
	var fighter := _fighter()
	_run_on_the_wall(fighter)
	fighter.lean(LEAN_S)
	fighter.state.mode = FighterState.Mode.AIR
	fighter.lean(LEAN_S / 2.0)
	assert_float(_tilt_deg(fighter)).is_equal_approx(LEAN_DEG / 2.0, HAIR)
	# Going out it still leans away from the wall it left.
	assert_float(fighter.visual.global_transform.basis.y.x).is_greater(0.0)
	fighter.lean(LEAN_S / 2.0)
	assert_float(_tilt_deg(fighter)).is_equal_approx(0.0, HAIR)
	assert_float(fighter.lean_angle()).is_equal(0.0)
	assert_bool(fighter.visual.basis.is_equal_approx(Basis(Vector3.UP, YAW))).is_true()


# None: off the wall, on the floor or in the air, the capsule never leans.
func test_off_the_wall_the_capsule_stands_upright(
	mode: FighterState.Mode,
	_test_parameters := [[FighterState.Mode.GROUND], [FighterState.Mode.AIR]],
) -> void:
	var fighter := _fighter()
	fighter.state.mode = mode
	fighter.state.wall_normal = Vector3.RIGHT
	fighter.lean(1.0)
	assert_float(_tilt_deg(fighter)).is_equal_approx(0.0, HAIR)
	assert_bool(fighter.visual.basis.is_equal_approx(Basis(Vector3.UP, YAW))).is_true()


# The lean is out of the simulation: the state, the body and the collision capsule are the same
# before and after a full lean (DEC-0031 §6).
func test_the_lean_touches_neither_the_state_nor_the_body() -> void:
	var fighter := _fighter()
	_run_on_the_wall(fighter)
	var before := fighter.state.copy()
	var position := fighter.global_position
	var velocity := fighter.velocity
	var collision := fighter.collision.global_transform
	fighter.lean(LEAN_S)
	for field: String in ReplayFile.script_fields(before):
		var message := "state.%s changed" % field
		assert_bool(fighter.state.get(field) == before.get(field)) \
				.override_failure_message(message) \
				.is_true()
	assert_vector(fighter.global_position).is_equal(position)
	assert_vector(fighter.velocity).is_equal(velocity)
	assert_bool(fighter.collision.global_transform.is_equal_approx(collision)).is_true()
