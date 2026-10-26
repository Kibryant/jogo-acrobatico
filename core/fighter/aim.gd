# The aim of the grapple (movimento.md, "Gancho": "De onde sai a mira"; DEC-0044; DEC-0045): the
# camera's yaw and pitch of a tick as the direction of the ray, and the point O it leaves from, on
# the line of the screen's centre at the body's depth. Both are pure functions of the state, the
# input and the data, so the server casts the same ray with no camera. The node casts it in the
# tick (Fighter.aim_ray), the screen's reticle casts it along the camera, and the fire rule
# measures the reach from O (Movement.in_reach); with the camera free, the camera's optical axis
# passes through O (fighter/camera_rig.gd).
class_name Aim
extends RefCounted


# A unit vector: the pitch raises it from the horizontal, positive up, and the yaw turns it about
# the vertical the way the move turns (Movement._world), so yaw 0 and pitch 0 look down -Z, yaw
# +90° looks down -X and pitch +45° looks half way up, (0, 0.7071, -0.7071).
static func direction(yaw: float, pitch: float) -> Vector3:
	return Basis(Vector3.UP, yaw) * Vector3(0.0, sin(pitch), -cos(pitch))


# The point O (DEC-0045 §2): the feet, height up, and side to the right of the yaw, turned by the
# same Basis(UP, yaw) as the direction, so yaw 0 puts it toward +X and yaw +90° toward -Z. The
# pitch never moves it: the camera's shoulder sits at the pivot's height, and a negative side is
# the left shoulder.
static func origin(feet: Vector3, yaw: float, height: float, side: float) -> Vector3:
	return feet + Vector3.UP * height + Basis(Vector3.UP, yaw) * Vector3(side, 0.0, 0.0)
