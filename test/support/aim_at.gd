# The camera's yaw and pitch that aim the grapple at a world point, with the ray leaving the point
# O (DEC-0045 §2; movimento.md, "Gancho": "De onde sai a mira"): the feet, aim_height up, and
# aim_side to the right of the yaw. O moves with the yaw, so the yaw that looks from the feet at
# the point is turned toward it until the ray from O, side metres to its right, passes through the
# point. With d the horizontal step from the feet to the point and D its length, the yaw that looks
# along d is yaw0 = atan2(-d.x, -d.z); the ray from O crosses d at the point when the yaw is
# yaw0 + asin(side / D), and the horizontal run from O to the point is sqrt(D² - side²), which the
# pitch climbs from O's height to the point's. It needs D > |side|: a point within the shoulder's
# reach, horizontally, cannot be aimed from O. Arithmetic on Aim.origin, shared by the suites that
# drive a fighter's aim by hand (the SyncTest's gancho, the probe, the cues, the HUD).
extends RefCounted


# The yaw, in rad, whose ray from O of these feet passes over point.
static func yaw_to(feet: Vector3, point: Vector3, config: MovementConfig) -> float:
	var step := _flat_step(feet, point, config)
	return atan2(-step.x, -step.z) + asin(config.aim_side / step.length())


# The pitch, in rad, positive up, whose ray from O of these feet, at yaw_to, reaches point.
static func pitch_to(feet: Vector3, point: Vector3, config: MovementConfig) -> float:
	var step := _flat_step(feet, point, config)
	var run := sqrt(step.length_squared() - config.aim_side * config.aim_side)
	return atan2(point.y - feet.y - config.aim_height, run)


static func _flat_step(feet: Vector3, point: Vector3, config: MovementConfig) -> Vector3:
	var step := Vector3(point.x - feet.x, 0.0, point.z - feet.z)
	assert(
		step.length() > absf(config.aim_side),
		"a point %s m from the feet, horizontally, is within the shoulder's %s m"
		% [step.length(), config.aim_side],
	)
	return step
