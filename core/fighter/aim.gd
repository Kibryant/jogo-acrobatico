# The aim of the grapple (DEC-0044 §2; movimento.md, "Gancho": "De onde sai a mira"): the camera's
# yaw and pitch of a tick as the direction the ray leaves the shoulder along. The node casts the
# ray with it, and the screen's reticle too, so both aim the same way; with the camera centred, the
# ray from the shoulder goes through the middle of the screen (fighter/camera_rig.gd).
class_name Aim
extends RefCounted


# A unit vector: the pitch raises it from the horizontal, positive up, and the yaw turns it about
# the vertical the way the move turns (Movement._world), so yaw 0 and pitch 0 look down -Z, yaw
# +90° looks down -X and pitch +45° looks half way up, (0, 0.7071, -0.7071).
static func direction(yaw: float, pitch: float) -> Vector3:
	return Basis(Vector3.UP, yaw) * Vector3(0.0, sin(pitch), -cos(pitch))
