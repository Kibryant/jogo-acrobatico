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
# yaw of TickInput. The charged attack cuts in the vertical plane of the swing's direction instead
# (combate.md, "O corte do carregado"; TASK-12.3): the same ring, centred on the attacker's axis at
# the hand's height, between two elevations, positive up; its touch is the same count, exact too.
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


# The least distance between the vertical slice from the elevation phi_from to phi_to and the
# target's capsule axis (combate.md, "O toque do carregado"). The slice lies in the vertical plane
# of the swing's direction and the axis stands upright, parallel to it, so the distance splits
# exactly into the gap off the plane, to the side, and the distance inside the plane between the
# sector and the axis's shadow on it, squared and summed.
static func cut_distance(
	feet: Vector3,
	swing_yaw: float,
	phi_from: float,
	phi_to: float,
	target_feet: Vector3,
	combat: CombatConfig,
	config: MovementConfig,
) -> float:
	# The target's axis in the swing's own frame: forward along the swing, x to the side.
	var offset := Basis(Vector3.UP, -swing_yaw) * (target_feet - feet)
	var side := offset.x
	var ahead := -offset.z
	var plane := feet.y + combat.hand_height
	var bottom := target_feet.y + config.capsule_radius - plane
	var top := target_feet.y + config.capsule_height - config.capsule_radius - plane
	var inside := _sector_to_upright(
		ahead,
		bottom,
		top,
		minf(phi_from, phi_to),
		maxf(phi_from, phi_to),
		combat,
	)
	return sqrt(side * side + inside * inside)


# Whether the vertical slice touches the target's capsule, as the flat one does (slice_touches).
static func cut_touches(
	feet: Vector3,
	swing_yaw: float,
	phi_from: float,
	phi_to: float,
	target_feet: Vector3,
	combat: CombatConfig,
	config: MovementConfig,
) -> bool:
	var distance := cut_distance(feet, swing_yaw, phi_from, phi_to, target_feet, combat, config)
	return distance <= config.capsule_radius + combat.blade_radius


# The blade of a vertical cut at the elevation phi, swung from feet along swing_yaw: [hand, tip].
static func cut_segment(
	feet: Vector3,
	swing_yaw: float,
	phi: float,
	combat: CombatConfig,
) -> PackedVector3Array:
	var along := direction(swing_yaw) * cos(phi) + Vector3.UP * sin(phi)
	var centre := feet + Vector3.UP * combat.hand_height
	var hand := centre + along * combat.hand_offset
	var tip := centre + along * (combat.hand_offset + combat.blade_length)
	return PackedVector3Array([hand, tip])


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


# The least distance in the cut's plane, (ahead, up) from the hand's centre, between the ring
# sector from the inner to the outer radius and from the elevation lo to hi, and the upright segment
# at x = ahead from y = bottom to y = top. Zero when they meet. Otherwise the two closest points of
# the pair lie on the boundaries, and the least of these candidates is exact: the segment's ends
# against the whole sector; the sector's four corners against the segment; and the one place where
# an arc's inside meets the segment's inside square to both, the arc's point at elevation 0, level
# with the hand, which faces an upright segment horizontally. A radial edge's inside against the
# segment's inside is never closest unless they cross, which is a meeting: two segments that do
# not cross are closest at an end of one.
static func _sector_to_upright(
	ahead: float,
	bottom: float,
	top: float,
	lo: float,
	hi: float,
	combat: CombatConfig,
) -> float:
	var inner := combat.hand_offset
	var outer := combat.hand_offset + combat.blade_length
	if _upright_meets_sector(ahead, bottom, top, lo, hi, inner, outer):
		return 0.0
	var low_end := Vector2(ahead, bottom)
	var high_end := Vector2(ahead, top)
	var nearest := minf(
		_to_sector(low_end, lo, hi, inner, outer),
		_to_sector(high_end, lo, hi, inner, outer),
	)
	for phi: float in [lo, hi]:
		var along := Vector2(cos(phi), sin(phi))
		for radius: float in [inner, outer]:
			var corner := along * radius
			var on := Vector2(ahead, clampf(corner.y, bottom, top))
			nearest = minf(nearest, corner.distance_to(on))
	if lo <= 0.0 and 0.0 <= hi and bottom <= 0.0 and 0.0 <= top:
		for radius: float in [inner, outer]:
			nearest = minf(nearest, absf(ahead - radius))
	return nearest


# Whether the upright segment meets the sector: on the line x = ahead, the heights inside the ring
# are two bands, |y| between sqrt(inner² - ahead²) and sqrt(outer² - ahead²); the heights within
# the elevations are one band, ahead·tan(lo) to ahead·tan(hi), for a line ahead of the axis (the
# elevations stay within ±90°, so the sector lies ahead of it).
static func _upright_meets_sector(
	ahead: float,
	bottom: float,
	top: float,
	lo: float,
	hi: float,
	inner: float,
	outer: float,
) -> bool:
	if ahead <= 0.0 or ahead > outer:
		return false
	var from := maxf(bottom, ahead * tan(lo))
	var to := minf(top, ahead * tan(hi))
	if from > to:
		return false
	var ring_low := sqrt(maxf(0.0, inner * inner - ahead * ahead))
	var ring_high := sqrt(outer * outer - ahead * ahead)
	var upper := maxf(from, ring_low) <= minf(to, ring_high)
	var lower := maxf(from, -ring_high) <= minf(to, -ring_low)
	return upper or lower


# The least distance in the cut's plane from the point p to the ring sector, as _flat_distance
# measures the flat one: inside the elevations it is the radial distance, and outside them the
# nearest point lies on one of the two edge blades.
static func _to_sector(p: Vector2, lo: float, hi: float, inner: float, outer: float) -> float:
	var nearest := minf(_to_ray(p, lo, inner, outer), _to_ray(p, hi, inner, outer))
	var radius := p.length()
	if radius == 0.0:
		return minf(nearest, inner)
	var angle := atan2(p.y, p.x)
	if angle >= lo and angle <= hi:
		nearest = minf(nearest, maxf(0.0, maxf(inner - radius, radius - outer)))
	return nearest


# The distance in the cut's plane from p to the edge blade at the elevation phi.
static func _to_ray(p: Vector2, phi: float, inner: float, outer: float) -> float:
	var along := Vector2(cos(phi), sin(phi))
	var t := clampf(p.dot(along), inner, outer)
	return p.distance_to(along * t)
