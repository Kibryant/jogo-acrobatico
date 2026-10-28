# The blade as the core's own count (DEC-0026 §4; combate.md, "A lâmina e o contato" and "O leve no
# tick"): a segment with a radius, from the hand, hand_offset off the attacker's axis and
# hand_height above its feet, to the tip, hand_offset + blade_length off it, along the swing's
# direction turned by theta. Over one active tick the blade sweeps a slice, the ring between the
# hand and the tip from one angle to the next, and the slice touches a target when its least
# distance to the target's capsule axis, from capsule_radius to capsule_height - capsule_radius
# above the target's feet, is at most capsule_radius + blade_radius. The count is exact, with no
# angle sampled: a target between the blades of two tick ends is touched, so a fast swing never
# skips a body, the way a continuous collision check never lets a bullet tunnel through a wall.
# Angles: yaw 0 looks down -Z and a positive angle turns left (Basis(UP, a) * FORWARD), like the
# yaw of TickInput.
class_name Blade
extends RefCounted


# The blade at theta, swung from feet along swing_yaw: [hand, tip], both at the hand's height.
static func segment(
	feet: Vector3,
	swing_yaw: float,
	theta: float,
	combat: CombatConfig,
) -> PackedVector3Array:
	var along := direction(swing_yaw + theta)
	var height := feet + Vector3.UP * combat.hand_height
	var hand := height + along * combat.hand_offset
	var tip := height + along * (combat.hand_offset + combat.blade_length)
	return PackedVector3Array([hand, tip])


# The angles of the slice of the k-th active tick of attack, k from 1: the arc split evenly over
# the active ticks, from arc_from toward arc_to (combate.md, "O leve no tick": "O arco do leve").
static func slice_of(attack: AttackConfig, k: int) -> Vector2:
	var span := attack.arc_to - attack.arc_from
	var from := attack.arc_from + span * (k - 1) / attack.active_ticks
	var to := attack.arc_from + span * k / attack.active_ticks
	return Vector2(from, to)


# The least distance between the slice swept from theta_from to theta_to and the target's capsule
# axis. The slice lies flat at the hand's height and the axis stands upright, so the distance
# splits exactly into a vertical gap and a horizontal one, squared and summed. A slice of no width
# (theta_from == theta_to) is the blade at that angle alone.
static func slice_distance(
	feet: Vector3,
	swing_yaw: float,
	theta_from: float,
	theta_to: float,
	target_feet: Vector3,
	combat: CombatConfig,
	config: MovementConfig,
) -> float:
	var plane := feet.y + combat.hand_height
	var bottom := target_feet.y + config.capsule_radius
	var top := target_feet.y + config.capsule_height - config.capsule_radius
	var gap := maxf(0.0, maxf(bottom - plane, plane - top))
	# The target's axis in the swing's own frame, flat: yaw 0 there is the swing's direction.
	var offset := Basis(Vector3.UP, -swing_yaw) * (target_feet - feet)
	var flat := Vector2(offset.x, offset.z)
	var across := _flat_distance(
		flat,
		minf(theta_from, theta_to),
		maxf(theta_from, theta_to),
		combat,
	)
	return sqrt(across * across + gap * gap)


# Whether the slice touches the target's capsule: its distance to the axis is at most the body's
# radius plus the blade's (combate.md, "O leve no tick": "O toque").
static func slice_touches(
	feet: Vector3,
	swing_yaw: float,
	theta_from: float,
	theta_to: float,
	target_feet: Vector3,
	combat: CombatConfig,
	config: MovementConfig,
) -> bool:
	var distance := slice_distance(
		feet,
		swing_yaw,
		theta_from,
		theta_to,
		target_feet,
		combat,
		config,
	)
	return distance <= config.capsule_radius + combat.blade_radius


# The horizontal unit vector at angle a: yaw 0 looks down -Z, and a positive angle turns left.
static func direction(angle: float) -> Vector3:
	return Basis(Vector3.UP, angle) * Vector3.FORWARD


# The least distance on the plane from the point p (x, z) to the ring sector between the hand's
# and the tip's radii, from angle lo to hi. Within the sector's angles it is the radial distance;
# any point's distance to the sector is never more than its distance to the two edge blades, and
# outside the angles the nearest point lies on one of them, so the least of the three is exact.
static func _flat_distance(p: Vector2, lo: float, hi: float, combat: CombatConfig) -> float:
	var inner := combat.hand_offset
	var outer := combat.hand_offset + combat.blade_length
	var nearest := minf(_to_edge(p, lo, inner, outer), _to_edge(p, hi, inner, outer))
	var radius := p.length()
	if radius == 0.0:
		return minf(nearest, inner)
	# The point's angle in the same convention: direction(a) is (-sin a, -cos a) on (x, z).
	var angle := atan2(-p.x, -p.y)
	if fposmod(angle - lo, TAU) <= hi - lo:
		nearest = minf(nearest, maxf(0.0, maxf(inner - radius, radius - outer)))
	return nearest


# The distance on the plane from p to the edge blade at angle, from the inner to the outer radius.
static func _to_edge(p: Vector2, angle: float, inner: float, outer: float) -> float:
	var along := Vector2(-sin(angle), -cos(angle))
	var t := clampf(p.dot(along), inner, outer)
	return p.distance_to(along * t)
