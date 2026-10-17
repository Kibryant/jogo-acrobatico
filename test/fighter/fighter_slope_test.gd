# Criterion 3 of TASK-9, the engine's side: the core reads facts.on_floor, and the engine judges
# the floor with the 45° of movimento.md, "O corpo". A fighter of fighter.tscn runs on ramps built
# here, through netfox's real tick loop driven by hand (DEC-0027 §3): 45° is floor, uphill and
# downhill at full speed, and 46° is not. The geometry is the test's own, so changing the arena
# never changes what these tests prove.
extends GdUnitTestSuite

const NetfoxTicks := preload("res://test/support/netfox_ticks.gd")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
const MOVEMENT_V0 := "res://data/movement_v0.tres"

const FORWARD := Vector2(0, 1)
const TOWARD_PLUS_X := -PI / 2 # the yaw that looks down +X: yaw 0 looks down -Z
const THICKNESS := 1.0 # m, of the test slabs
const GAP := 0.02 # m: a fighter placed on a slope starts this far above it


func before_test() -> void:
	NetfoxTicks.reset()


func after_test() -> void:
	NetfoxTicks.reset()


func _config() -> MovementConfig:
	var resource: Resource = load(MOVEMENT_V0)
	assert(resource is MovementData, "%s must load as a MovementData" % MOVEMENT_V0)
	return MovementConfig.create(resource as MovementData, NetworkTime.tickrate)


func _box(world: Node3D, center: Vector3, size: Vector3, roll_deg: float) -> void:
	var body := StaticBody3D.new()
	body.position = center
	body.rotation_degrees = Vector3(0, 0, roll_deg)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	world.add_child(body)


# A flat floor with its top at y = 0, 40 x 40 m.
func _floor(world: Node3D) -> void:
	_box(world, Vector3(0, -0.5, 0), Vector3(40, 1, 40), 0.0)


# A slab whose top face starts at `start` and runs `length` m along +X at slope_deg, up for a
# positive slope and down for a negative one; the rest of the slab sits under that face.
func _ramp(world: Node3D, start: Vector3, length: float, slope_deg: float) -> void:
	var along := Vector3(cos(deg_to_rad(slope_deg)), sin(deg_to_rad(slope_deg)), 0)
	var normal := Vector3(-along.y, along.x, 0)
	var center := start + along * (length / 2.0) - normal * (THICKNESS / 2.0)
	_box(world, center, Vector3(length, THICKNESS, 6), slope_deg)


# A fighter of fighter.tscn in a world, with netfox's deferred setup done.
func _fighter_in(world: Node3D, at: Vector3) -> Fighter:
	var node := FIGHTER_SCENE.instantiate()
	assert(node is Fighter, "fighter.tscn must have a Fighter at its root")
	var fighter := node as Fighter
	fighter.setup(_config(), at, TOWARD_PLUS_X, true)
	world.add_child(fighter)
	add_child(world)
	# netfox's deferred setup, then ticks inside a physics frame (test/support/netfox_ticks.gd).
	await get_tree().process_frame
	await get_tree().physics_frame
	return fighter


func _world() -> Node3D:
	var world: Node3D = auto_free(Node3D.new())
	return world


# Where the feet go so the capsule rests GAP above a slope rising from x = 0 at slope_deg: the
# bottom sphere's centre sits a radius away from the plane.
func _on_slope(x: float, slope_deg: float, radius: float) -> Vector3:
	var slope := deg_to_rad(slope_deg)
	var sphere_center_y := (radius + x * sin(slope)) / cos(slope)
	return Vector3(x, sphere_center_y - radius + GAP, 0)


func _run(fighter: Fighter, ticks: int, move: Vector2) -> Array[Dictionary]:
	var trace: Array[Dictionary] = []
	for step: int in range(1, ticks + 1):
		fighter.input.sample_frame(move, TOWARD_PLUS_X)
		NetfoxTicks.run_loop()
		trace.append(
			{
				"step": step,
				"position": fighter.position,
				"speed": Vector2(fighter.velocity.x, fighter.velocity.z).length(),
				"on_floor": fighter.state.on_floor,
				"mode": fighter.state.mode,
			},
		)
	return trace


# Standing on a slope: the engine calls 45° floor, so the fighter lands and stays; 46° is a wall
# to it, so the fighter never stands and slides down (movimento.md, "O corpo").
func test_the_engine_calls_a_slope_floor_up_to_45_degrees(
	slope_deg: float,
	is_floor: bool,
	_test_parameters := [[45.0, true], [46.0, false]],
) -> void:
	var world := _world()
	_floor(world)
	_ramp(world, Vector3.ZERO, 8.0, slope_deg)
	var config := _config()
	var start := _on_slope(2.0, slope_deg, config.capsule_radius)
	var fighter := await _fighter_in(world, start)
	fighter.state.on_floor = false # placed GAP above the slope: it starts in the air
	var trace := _run(fighter, 20, Vector2.ZERO)
	# From the fifth tick on, after the GAP's short fall, every verdict is the slope's.
	var verdicts: Array[bool] = []
	var wrong := 0
	for row: Dictionary in trace.slice(4):
		verdicts.append(row["on_floor"])
		if row["on_floor"] != is_floor:
			wrong += 1
	var message := "on a %.0f° slope the floor verdicts were %s" % [slope_deg, verdicts]
	assert_int(wrong).override_failure_message(message).is_equal(0)
	var end: Vector3 = trace[-1]["position"]
	if is_floor:
		# It rests where it landed, a hair below where it started.
		assert_float(start.distance_to(end)).is_less(GAP + 0.01)
	else:
		assert_float(end.y).is_less(start.y - 0.2)


func test_running_up_a_45_degree_ramp_stays_on_the_floor() -> void:
	var world := _world()
	_floor(world)
	_ramp(world, Vector3.ZERO, 10.0, 45.0)
	var fighter := await _fighter_in(world, Vector3(-2, 0, 0))
	var trace := _run(fighter, 90, FORWARD)
	var violations: Array[String] = []
	for row: Dictionary in trace:
		if not row["on_floor"] or row["mode"] != FighterState.Mode.GROUND:
			violations.append("step %d: off the floor at %s" % [row["step"], row["position"]])
	assert_array(violations).is_empty()
	var end: Vector3 = trace[-1]["position"]
	assert_float(end.y).is_greater(1.0)


# Pushed into a 46° ramp from the flat floor, the fighter cannot walk up it: to the engine it is
# a wall, not floor.
func test_running_into_a_46_degree_ramp_does_not_climb_it() -> void:
	var world := _world()
	_floor(world)
	_ramp(world, Vector3.ZERO, 10.0, 46.0)
	var fighter := await _fighter_in(world, Vector3(-2, 0, 0))
	var trace := _run(fighter, 90, FORWARD)
	var highest := 0.0
	for row: Dictionary in trace:
		var position: Vector3 = row["position"]
		highest = maxf(highest, position.y)
	assert_float(highest).is_less(0.05)
	assert_bool(fighter.is_on_wall()).is_true()


# Downhill at full speed, the floor drops 0.117 m a tick under the fighter at 60 ticks, and the
# engine's snap, derived for that in Fighter.floor_snap_for, keeps it on the floor all the way
# down. Half that snap is the counter-test: the same run then leaves the floor, so the snap is
# what holds it.
func test_running_down_a_45_degree_ramp_at_full_speed_stays_on_the_floor(
	snap_scale: float,
	stays_on_floor: bool,
	_test_parameters := [[1.0, true], [0.5, false]],
) -> void:
	var height := 3.0
	var world := _world()
	_floor(world)
	_box(world, Vector3(-4, height / 2.0, 0), Vector3(8, height, 6), 0.0)
	_ramp(world, Vector3(0, height, 0), 6.0, -45.0)
	var fighter := await _fighter_in(world, Vector3(-6, height, 0))
	fighter.floor_snap_length *= snap_scale
	var trace := _run(fighter, 90, FORWARD)
	var off_floor: Array[String] = []
	var slowest_on_the_ramp := INF
	for row: Dictionary in trace:
		if not row["on_floor"]:
			off_floor.append("step %d at %s" % [row["step"], row["position"]])
		var position: Vector3 = row["position"]
		var speed: float = row["speed"]
		if position.x > 0.0 and position.y > 0.0:
			slowest_on_the_ramp = minf(slowest_on_the_ramp, speed)
	var end: Vector3 = trace[-1]["position"]
	assert_float(end.x).is_greater(height) # it went down to the floor at the foot
	if stays_on_floor:
		assert_array(off_floor).is_empty()
		# Down the whole ramp at the run speed of movimento.md, "Chão".
		assert_float(slowest_on_the_ramp).is_equal_approx(7.0, 1e-3)
	else:
		assert_array(off_floor).is_not_empty()
