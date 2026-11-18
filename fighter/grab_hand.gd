# The guard break's hand on the capsule (visual-e-audio.md, "A quebra na cápsula"; TASK-12.4;
# F-212), until the mannequin of TASK-12.9: a vermilion sphere of 0,1 m of radius, held by the
# fighter, whose place is a function of the displayed state and tick, as the sword's pose is
# (DEC-0030 §4), so a rollback never moves it twice and a resimulation never plays it again.
# - In the windup of a move that grabs it shows on the body's axis, at the hand's height, from the
#   windup's first tick.
# - In the active it goes out along the move's line, at the far end of the tick's slice of the
#   rule's own hand (Blade.hand_slice, Blade.hand_segment): what the player sees passing or
#   grabbing is what the rule tests.
# - In the recovery it comes back to the body in a straight line, and goes at the recovery's end.
# - Whoever grabbed (GRABBING) holds it on the other's chest, the other's axis at the hand's height,
#   through the hold.
# Anywhere else it is hidden. The fighter's node is never turned (its visual is), so the hand's
# position relative to the fighter is the offset from the feet in the world's axes, as the sword's.
class_name GrabHand
extends MeshInstance3D

## m: the sphere's radius (visual-e-audio.md, "A quebra na cápsula": "uma esfera de 0,1 m de raio").
const RADIUS := 0.1

var _combat: CombatConfig
var _material := StandardMaterial3D.new()


# colour is the guard break windup's token's, vermilion in tokens_v0.tres; lit by nothing, so it
# reads the same in the shade.
func _init(combat: CombatConfig, colour := Sword.ACTIVE_COLOUR) -> void:
	name = "GrabHand"
	_combat = combat
	var sphere := SphereMesh.new()
	sphere.radius = RADIUS
	sphere.height = 2.0 * RADIUS
	mesh = sphere
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.albedo_color = colour
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false


## Puts the hand where state at tick shows it, the displayed ones; to_target is the offset from
## this fighter's feet to the feet of the fighter it holds, read only while GRABBING.
func show_hand(state: FighterState, tick: int, to_target: Vector3) -> void:
	visible = shows(state, _combat)
	if visible:
		position = place(state, tick, _combat, to_target)


## The hand's colour as drawn.
func colour() -> Color:
	return _material.albedo_color


## Whether a fighter in this state shows the hand: in the windup, the active or the recovery of a
## move that grabs, or holding a grab (GRABBING).
static func shows(state: FighterState, combat: CombatConfig) -> bool:
	if state.action == FighterState.Action.GRABBING:
		return true
	if not Combat.swinging(state) or not combat.attacks.has(state.action_move):
		return false
	var attack: AttackConfig = combat.attacks[state.action_move]
	return attack.grab


## The hand's place relative to the fighter's feet, in the world's axes, for a state that shows
## it. A frozen tick of the hitstop holds the pose of the tick before it (Combat.posed_tick).
static func place(
	state: FighterState,
	tick: int,
	combat: CombatConfig,
	to_target: Vector3,
) -> Vector3:
	var axis := Vector3.UP * combat.hand_height
	if state.action == FighterState.Action.GRABBING:
		return to_target + axis
	var attack: AttackConfig = combat.attacks[state.action_move]
	var into := Combat.posed_tick(state, tick) - state.action_since + 1
	var reach := 0.0
	match state.action:
		FighterState.Action.WINDUP:
			return axis
		FighterState.Action.ACTIVE:
			reach = Blade.hand_slice(attack, clampi(into, 1, attack.active_ticks)).y
		_:
			var share := clampf(float(into) / maxi(1, attack.recovery_ticks), 0.0, 1.0)
			reach = attack.hand_reach * (1.0 - share)
	return Blade.hand_segment(Vector3.ZERO, state.action_yaw, 0.0, reach, combat)[1]
