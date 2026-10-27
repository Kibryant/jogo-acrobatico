# DEC-0048 §2, for TASK-10.13: a run that ends by time, by the lock (below 4 m/s along the
# wall), by the grapple's fire or by the contact lost at the wall's edge still refuses the same
# wall until the floor or another wall; only a flight that began with a wall jump re-enters it
# (DEC-0048 §1; DEC-0047 §1 and §2). One case per exit: the run ends that way, the body is brought
# back onto the same wall in the air by hand with 8 m/s along it (as movement_wall_test.gd comes
# back), the double jump spent by hand so that a renewal would show, and the touch starts no run
# and renews nothing. The control of each case: a run on another wall in between, or the floor,
# makes the same wall accept again, with the renewal (DEC-0047 §3; movimento.md, "Pulo e ar":
# "Renovação do pulo duplo"). Through the public interface of core/fighter with the engine's slice
# played by MovementRig (visao-geral.md, "O tick por dentro: o sanduíche"; rede.md §4). Every
# number comes from docs/design/movimento.md, cited by section; ticks by hand from the ms,
# nearest tick with ties up (visao-geral.md, "O tempo e a física no estado").
extends GdUnitTestSuite

const MovementRig := preload("res://test/core/fighter/movement_rig.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)

# movimento.md, "Corrida na parede".
const WALL_ENTRY_SPEED_MPS := 4.0 # "Velocidade mínima para entrar", along the wall
const WALL_RUN_SPEED_MPS := 8.0 # "Velocidade na parede"
# The wall times by hand (movimento.md, "Corrida na parede"): 2,5 s of run ("Duração máxima") is
# 75 ticks at 30 and 150 at 60, exact; 1,5 s of held height ("Altura") is 45 and 90.
const WALL_RUN_MAX_TICKS: Dictionary[int, int] = { 30: 75, 60: 150 }
const WALL_HOLD_TICKS: Dictionary[int, int] = { 30: 45, 60: 90 }
# movimento.md, "Gancho": 100 ms of cable ("Tempo até prender") is 3 ticks at 30 and 6 at 60.
const ATTACH_TICKS: Dictionary[int, int] = { 30: 3, 60: 6 }

# The two ways the same wall is accepted again (DEC-0048 §2: "até o chão ou outra parede").
const OTHER_WALL := "another wall in between"
const FLOOR := "the floor"

# The geometry of the rig, not design numbers (as in movement_wall_test.gd). The body approaches
# a wall from APPROACH_M in front of it, flying into it at APPROACH_SPEED_MPS; thrown back by
# hand, at THROWN_BACK_MPS into it. START_HEIGHT_M keeps the floor, when it is on, far below.
const APPROACH_M := 0.9
const APPROACH_SPEED_MPS := 2.0
const THROWN_BACK_MPS := 5.0
const START_HEIGHT_M := 10.0
const FALLING_VERTICAL_MPS := -6.0
const EDGE_M := 8.0 # where a face ends, or an obstacle stands, ahead of the touch
const CORRIDOR_GAP_M := 2.8 # the planned corridor, centre to centre (TASK-10.5, "Números v0")
const RUN_TICKS_BEFORE_THE_EXIT := 2
# The grapple's point, off the wall: 6 m out, 5 m up and 10 m ahead of the feet, within the 3 to
# 25 m of the range from the point O (movimento.md, "Gancho": "Alcance", "Alcance mínimo").
const POINT_OFF_THE_WALL := Vector3(6.0, 5.0, -10.0)
const WALL_A := &"ParedeA" # ids as the adapter reports them: node paths relative to the Arena
const WALL_B := &"ParedeB"
const OBSTACLE := &"Obstaculo"

const HAIR := 1e-6 # floating-point slack, not a design number
const GEOMETRY_HAIR := 1e-4 # a Vector3 holds 32-bit floats: a tilted clamp carries that error


func _rig(tickrate: int) -> MovementRig:
	return MovementRig.new(MovementRig.load_config(tickrate), FIRST_TICK)


# A rig with no floor: the body never lands unless a control switches the floor on.
func _air_rig(tickrate: int) -> MovementRig:
	var rig := _rig(tickrate)
	rig.floor_on = false
	return rig


# The wall at x = 0 facing +X: the body runs along -Z beside it.
func _wall_a(rig: MovementRig) -> MovementRig.FakeWall:
	return rig.add_wall(Vector3.RIGHT, 0.0, WALL_A)


# The facing wall of the corridor: the plane x = CORRIDOR_GAP_M, facing -X.
func _wall_b(rig: MovementRig) -> MovementRig.FakeWall:
	return rig.add_wall(Vector3.LEFT, -CORRIDOR_GAP_M, WALL_B)


# Puts the body in the air APPROACH_M in front of WALL_A, flying into it at APPROACH_SPEED_MPS
# while running -Z at 8 m/s, falling, and idles until the run starts; returns the entry tick.
func _run_on_wall_a(rig: MovementRig) -> int:
	rig.airborne(
		Vector3(APPROACH_M, START_HEIGHT_M, 0.0),
		Vector3(-APPROACH_SPEED_MPS, FALLING_VERTICAL_MPS, -WALL_RUN_SPEED_MPS),
	)
	return _fly_until_wall_run(rig, 2 * rig.config.tickrate)


# Idles until the core starts a wall run; returns the entry tick, or fails and returns -1.
func _fly_until_wall_run(rig: MovementRig, limit: int) -> int:
	for _step: int in limit:
		rig.step(MovementRig.idle())
		if rig.state.mode == FighterState.Mode.WALL_RUN:
			return rig.tick - 1
	fail("never started a wall run within %d ticks (at %d ticks)" % [limit, rig.config.tickrate])
	return -1


# Idles up to limit ticks and asserts no wall run ever starts; returns true if the wall was in
# contact on at least one tick, so a refusal is proven against a touch and not against air.
func _fly_without_wall_run(rig: MovementRig, limit: int, wall: StringName) -> bool:
	var touched := false
	var violations: Array[String] = []
	for _step: int in limit:
		var plan := rig.step(MovementRig.idle())
		if rig.last_facts.wall_id == wall:
			touched = true
		if plan.state.mode == FighterState.Mode.WALL_RUN \
				or rig.state.mode == FighterState.Mode.WALL_RUN:
			violations.append("tick %d: started a wall run" % (rig.tick - 1))
	assert_array(violations).override_failure_message("a wall run started: %s" % [violations]) \
			.is_empty()
	return touched


# The body in the air again, by hand, APPROACH_M in front of this wall's plane at its current
# height, thrown into it at THROWN_BACK_MPS with 8 m/s along -Z, and the double jump spent by
# hand on the tick before (as movement_wall_test.gd spends it), so that a renewal would show.
# The state keeps its last wall: MovementRig.airborne does not touch it. Returns the stamp.
func _thrown_at(rig: MovementRig, normal: Vector3, plane_x: float) -> int:
	rig.airborne(
		Vector3(plane_x + normal.x * APPROACH_M, rig.position.y, 0.0),
		Vector3(-normal.x * THROWN_BACK_MPS, FALLING_VERTICAL_MPS, -WALL_RUN_SPEED_MPS),
	)
	rig.state.jumps_used = 2
	rig.state.double_jump_tick = rig.tick - 1
	return rig.state.double_jump_tick


func _thrown_at_wall_a(rig: MovementRig) -> int:
	return _thrown_at(rig, Vector3.RIGHT, 0.0)


func _thrown_at_wall_b(rig: MovementRig) -> int:
	return _thrown_at(rig, Vector3.LEFT, CORRIDOR_GAP_M)


func _assert_wall_id(state: FighterState, wall: StringName) -> void:
	var message := "wall_id is %s, expected %s" % [state.wall_id, wall]
	assert_str(String(state.wall_id)).override_failure_message(message).is_equal(String(wall))


# The refusal (DEC-0048 §2): thrown back at WALL_A with the double jump spent, the touch starts
# no run within half a second, and the state keeps the last wall, the spent double jump and the
# air; the body slid along the wall (its velocity into it is gone).
func _assert_the_same_wall_refuses(rig: MovementRig, what: String) -> void:
	var stamp := _thrown_at_wall_a(rig)
	var touched := _fly_without_wall_run(rig, rig.config.tickrate / 2, WALL_A)
	assert_bool(touched).override_failure_message("%s: never came back to the wall" % what) \
			.is_true()
	assert_int(rig.state.mode).override_failure_message("%s: not in the air" % what).is_equal(
		FighterState.Mode.AIR
	)
	_assert_wall_id(rig.state, WALL_A)
	assert_vector(rig.state.wall_normal).is_equal_approx(Vector3.RIGHT, Vector3.ONE * GEOMETRY_HAIR)
	assert_int(rig.state.jumps_used).override_failure_message("%s: the touch renewed it" % what) \
			.is_equal(2)
	assert_int(rig.state.double_jump_tick).override_failure_message("%s: cleared" % what) \
			.is_equal(stamp)
	assert_float(rig.velocity.x).override_failure_message("%s: passed through the wall" % what) \
			.is_equal(0.0)


# The entry with the renewal (movimento.md, "Pulo e ar": "Renovação do pulo duplo"; DEC-0047 §2):
# WALL_RUN since the entry tick, the wall's id and flattened normal, no jump used, no stamp.
func _assert_wall_run_renewed(
	state: FighterState,
	entry_tick: int,
	wall: StringName,
	normal: Vector3,
) -> void:
	assert_int(state.mode).override_failure_message("not in WALL_RUN").is_equal(
		FighterState.Mode.WALL_RUN
	)
	assert_int(state.mode_since).is_equal(entry_tick)
	_assert_wall_id(state, wall)
	assert_vector(state.wall_normal).is_equal_approx(normal, Vector3.ONE * GEOMETRY_HAIR)
	assert_int(state.jumps_used).override_failure_message("the double jump was not renewed") \
			.is_equal(0)
	assert_int(state.double_jump_tick).is_equal(FighterState.NEVER)


# The control (DEC-0048 §2: "até o chão ou outra parede"; DEC-0047 §3): after the refusal, a run
# on WALL_B in between (renewed, as another wall), or the floor (renews and clears the wall),
# and then WALL_A accepts again, with the renewal.
func _assert_accepted_again_after(rig: MovementRig, control: String) -> void:
	if control == OTHER_WALL:
		_wall_b(rig)
		_thrown_at_wall_b(rig)
		var other_entry := _fly_until_wall_run(rig, rig.config.tickrate)
		_assert_wall_run_renewed(rig.state, other_entry, WALL_B, Vector3.LEFT)
		rig.rest(RUN_TICKS_BEFORE_THE_EXIT)
		assert_int(rig.state.mode).is_equal(FighterState.Mode.WALL_RUN)
	else:
		rig.floor_on = true
		var landing_tick := -1
		for _step: int in 3 * rig.config.tickrate:
			rig.step(MovementRig.idle())
			if rig.state.on_floor:
				landing_tick = rig.tick - 1
				break
		assert_int(landing_tick).override_failure_message("never landed").is_greater(0)
		assert_int(rig.state.mode).is_equal(FighterState.Mode.GROUND)
		rig.step(MovementRig.idle())
		assert_int(rig.state.jumps_used).override_failure_message("the floor did not renew") \
				.is_equal(0)
		assert_int(rig.state.double_jump_tick).is_equal(FighterState.NEVER)
		assert_str(String(rig.state.wall_id)).override_failure_message("the floor kept the wall") \
				.is_equal("")
		rig.floor_on = false
		rig.position.y = START_HEIGHT_M
	_thrown_at_wall_a(rig)
	var entry_tick := _fly_until_wall_run(rig, rig.config.tickrate)
	_assert_wall_run_renewed(rig.state, entry_tick, WALL_A, Vector3.RIGHT)


# The exit by time: the run lasts its 2,5 s and ends in the air, beside the wall (movimento.md,
# "Corrida na parede": "Duração máxima", "Fins da corrida"); back on the same wall, refused
# (DEC-0048 §2: "pelo tempo").
func test_after_a_run_that_ended_by_time_the_same_wall_refuses_until_the_floor_or_another_wall(
	tickrate: int,
	control: String,
	_test_parameters := [[30, OTHER_WALL], [60, OTHER_WALL], [30, FLOOR], [60, FLOOR]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	var entry_tick := _run_on_wall_a(rig)
	rig.rest(WALL_RUN_MAX_TICKS[tickrate] - 1)
	assert_int(rig.state.mode).override_failure_message("ended early").is_equal(
		FighterState.Mode.WALL_RUN
	)
	var after := rig.step(MovementRig.idle())
	assert_int(after.state.mode).override_failure_message("still on the wall after 2,5 s") \
			.is_equal(FighterState.Mode.AIR)
	assert_int(after.state.mode_since).is_equal(entry_tick + WALL_RUN_MAX_TICKS[tickrate])
	_assert_wall_id(rig.state, WALL_A)
	# Still beside the wall after the end: the touch of the next ticks starts nothing either.
	assert_str(String(rig.last_facts.wall_id)).is_equal(String(WALL_A))
	var touched := _fly_without_wall_run(rig, RUN_TICKS_BEFORE_THE_EXIT, WALL_A)
	assert_bool(touched).override_failure_message("left the wall at the end").is_true()
	_assert_the_same_wall_refuses(rig, "after the end by time")
	_assert_accepted_again_after(rig, control)


# The exit by the lock: an obstacle across the run drops the speed along the wall to 0, below
# the 4 m/s that serve as the lock, and the run ends on that tick (movimento.md, "Corrida na
# parede": "Fins da corrida: trava abaixo de 4 m/s"); back on the same wall, refused (DEC-0048
# §2: "pela trava").
func test_after_a_run_that_ended_by_the_lock_the_same_wall_refuses_until_the_floor_or_another_wall(
	tickrate: int,
	control: String,
	_test_parameters := [[30, OTHER_WALL], [60, OTHER_WALL], [30, FLOOR], [60, FLOOR]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	rig.add_wall(Vector3.BACK, -EDGE_M, OBSTACLE) # the plane z = -EDGE_M, across the run
	var entry_tick := _run_on_wall_a(rig)
	var end_tick := -1
	for _step: int in WALL_RUN_MAX_TICKS[tickrate]:
		rig.step(MovementRig.idle())
		if rig.state.mode != FighterState.Mode.WALL_RUN:
			end_tick = rig.tick - 1
			break
	assert_int(end_tick).override_failure_message("the run never ended").is_greater(entry_tick)
	assert_int(end_tick - entry_tick).is_less(WALL_HOLD_TICKS[tickrate])
	assert_float(rig.position.z).override_failure_message("passed the obstacle").is_equal_approx(
		-EDGE_M,
		GEOMETRY_HAIR,
	)
	assert_float(absf(rig.last_facts.velocity.z)).is_less(WALL_ENTRY_SPEED_MPS)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	assert_int(rig.state.mode_since).is_equal(end_tick)
	_assert_wall_id(rig.state, WALL_A)
	_assert_the_same_wall_refuses(rig, "after the lock")
	_assert_accepted_again_after(rig, control)


# The exit by the grapple's fire: the run ends on the fire tick, the body stays beside the wall
# while the cable flies and no run starts there, the pull takes it away and releases it in the
# air (movimento.md, "Gancho": "De onde dispara: na parede, a corrida acaba no disparo", "Tempo
# até prender", "Como solta"); back on the same wall, refused (DEC-0048 §2: "pelo gancho").
func test_after_a_run_that_ended_by_the_grapple_the_same_wall_refuses_until_floor_or_another_wall(
	tickrate: int,
	control: String,
	_test_parameters := [[30, OTHER_WALL], [60, OTHER_WALL], [30, FLOOR], [60, FLOOR]],
) -> void:
	var rig := _air_rig(tickrate)
	_wall_a(rig)
	_run_on_wall_a(rig)
	rig.rest(RUN_TICKS_BEFORE_THE_EXIT)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.WALL_RUN)
	var point := rig.position + POINT_OFF_THE_WALL
	rig.aim_hit = true
	rig.aim_point = point
	var fire_tick := rig.tick
	var plan := rig.step(MovementRig.press_grapple())
	assert_bool(plan.aim_request).override_failure_message("the wall run did not ask").is_true()
	assert_int(rig.state.grapple_fired_tick).override_failure_message("the hook did not bite") \
			.is_equal(fire_tick)
	assert_int(rig.state.mode).override_failure_message("the run did not end on the fire") \
			.is_equal(FighterState.Mode.AIR)
	assert_int(rig.state.mode_since).is_equal(fire_tick)
	_assert_wall_id(rig.state, WALL_A)
	# The cable flies: the body still runs -Z beside the wall, touching it, and no run starts.
	var touched := _fly_without_wall_run(rig, ATTACH_TICKS[tickrate] - 1, WALL_A)
	assert_bool(touched).override_failure_message("left the wall while the cable flew").is_true()
	var released := -1
	for _step: int in 3 * tickrate:
		var pull := rig.step(MovementRig.idle())
		assert_int(pull.state.mode).override_failure_message("a wall run during the grapple") \
				.is_not_equal(FighterState.Mode.WALL_RUN)
		if rig.state.grapple_end_tick != FighterState.NEVER:
			released = rig.state.grapple_end_tick
			break
	assert_int(released).override_failure_message("the grapple never released").is_greater(
		fire_tick + ATTACH_TICKS[tickrate]
	)
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	_assert_wall_id(rig.state, WALL_A)
	_assert_the_same_wall_refuses(rig, "after the grapple")
	_assert_accepted_again_after(rig, control)


# The exit by the contact lost: the face ends and the run ends on the tick the body is past its
# end, in the air, with the wall kept as the last one (movimento.md, "Corrida na parede": "Fins
# da corrida: borda"); back on the same face, refused (DEC-0048 §2: "pelo contato").
func test_after_a_run_that_ended_at_the_edge_the_same_wall_refuses_until_the_floor_or_another_wall(
	tickrate: int,
	control: String,
	_test_parameters := [[30, OTHER_WALL], [60, OTHER_WALL], [30, FLOOR], [60, FLOOR]],
) -> void:
	var rig := _air_rig(tickrate)
	var wall := _wall_a(rig)
	wall.along_max = wall.along_of(Vector3(0.0, 0.0, -EDGE_M))
	var entry_tick := _run_on_wall_a(rig)
	var end_tick := -1
	for _step: int in WALL_RUN_MAX_TICKS[tickrate]:
		rig.step(MovementRig.idle())
		if rig.state.mode != FighterState.Mode.WALL_RUN:
			end_tick = rig.tick - 1
			break
	assert_int(end_tick).override_failure_message("the run never ended").is_greater(entry_tick)
	assert_int(end_tick - entry_tick).is_less(WALL_HOLD_TICKS[tickrate])
	assert_float(wall.along_of(rig.position)).override_failure_message("ended before the edge") \
			.is_greater(wall.along_max)
	assert_str(String(rig.last_facts.wall_id)).is_equal("")
	assert_int(rig.state.mode).is_equal(FighterState.Mode.AIR)
	assert_int(rig.state.mode_since).is_equal(end_tick)
	_assert_wall_id(rig.state, WALL_A)
	_assert_the_same_wall_refuses(rig, "after the edge")
	_assert_accepted_again_after(rig, control)
