# The block sword (visual-e-audio.md, "O leve na tela"; TASK-12.1): a box of 1,4 × 0,06 × 0,02 m
# held at the hand, before the mannequin of TASK-12.9. Its pose is a function of the displayed
# state, the action, the tick its phase began and the swing's direction, and of the displayed tick,
# as DEC-0030 §4 asks of the mannequin: nothing of it is in the state, so the rollback never
# touches it and a resimulation never moves it twice (DEC-0031 §6). At rest it hangs on the right,
# the hand's side, pointing forward and down; in the windup it goes back, without colour; in the
# active it sweeps exactly the arc the rule tests (Blade), from the right to the left, in vermilion;
# in the recovery it comes back to rest. The angles of the rest and the windup are Claude's v0
# reading (DEC-0017); the active's are the rule's.
class_name Sword
extends Node3D

## m: the box's width and thickness (visual-e-audio.md, "O leve na tela"); its length is the
## blade's, from the combat numbers.
const WIDTH := 0.06
const THICKNESS := 0.02
## The active token's vermilion (visual-e-audio.md, "Os três canais por estado"; Okabe-Ito).
const ACTIVE_COLOUR := Color("#D55E00")
## The blade out of the active: a neutral grey, no colour of the combat tokens (DEC-0031). Claude's
## v0 reading (DEC-0017).
const STEEL := Color(0.55, 0.55, 0.57)
## The rest pose, relative to the facing: the hand on the right, the blade a little to the right
## and down. Claude's v0 reading (DEC-0017).
const REST_HAND_DEG := -60.0
const REST_YAW_DEG := -20.0
const REST_PITCH_DEG := -50.0
## The end of the windup: the hand further right and the blade pointing back, level. Claude's v0
## reading (DEC-0017).
const BACK_HAND_DEG := -80.0
const BACK_YAW_DEG := -150.0
const BACK_PITCH_DEG := 0.0

var _combat: CombatConfig
var _mesh := MeshInstance3D.new()
var _steel := StandardMaterial3D.new()
var _lit := StandardMaterial3D.new()


func _init(combat: CombatConfig) -> void:
	name = "Sword"
	_combat = combat
	_steel.albedo_color = STEEL
	_lit.albedo_color = ACTIVE_COLOUR
	_lit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var box := BoxMesh.new()
	box.size = Vector3(WIDTH, THICKNESS, combat.blade_length)
	_mesh.name = "Blade"
	_mesh.mesh = box
	# The box's centre half a blade along -Z: the node's origin is the hand.
	_mesh.position = Vector3(0.0, 0.0, -combat.blade_length / 2.0)
	_mesh.material_override = _steel
	add_child(_mesh)
	transform = pose(FighterState.new(), 0, combat)


# Puts the sword in the pose of state at tick, the displayed ones, and paints it.
func show_pose(state: FighterState, tick: int) -> void:
	transform = pose(state, tick, _combat)
	_mesh.material_override = _lit if lit(state) else _steel


## True while the blade wears the vermilion: in the active (visual-e-audio.md).
static func lit(state: FighterState) -> bool:
	return state.action == FighterState.Action.ACTIVE


## The sword's transform relative to the fighter's feet: the origin at the hand, the blade along its
## -Z. In the active the hand sits on the rule's circle, at the angle of the end of the tick's
## slice, and the blade runs radially from it, as Blade.segment draws it.
static func pose(state: FighterState, tick: int, combat: CombatConfig) -> Transform3D:
	var base := state.facing_yaw
	var hand := deg_to_rad(REST_HAND_DEG)
	var yaw := deg_to_rad(REST_YAW_DEG)
	var pitch := deg_to_rad(REST_PITCH_DEG)
	if state.action != FighterState.Action.NONE and combat.attacks.has(state.action_move):
		var attack: AttackConfig = combat.attacks[state.action_move]
		base = state.action_yaw
		var into := tick - state.action_since + 1
		match state.action:
			FighterState.Action.WINDUP:
				var share := _share(into, attack.windup_ticks)
				hand = lerpf(hand, deg_to_rad(BACK_HAND_DEG), share)
				yaw = lerpf(yaw, deg_to_rad(BACK_YAW_DEG), share)
				pitch = lerpf(pitch, deg_to_rad(BACK_PITCH_DEG), share)
			FighterState.Action.ACTIVE:
				var theta := Blade.slice_of(attack, clampi(into, 1, attack.active_ticks)).y
				hand = theta
				yaw = theta
				pitch = 0.0
			_:
				var share := _share(into, attack.recovery_ticks)
				hand = lerpf(attack.arc_to, hand, share)
				yaw = lerpf(attack.arc_to, yaw, share)
				pitch = lerpf(0.0, pitch, share)
	var at := Vector3.UP * combat.hand_height + Blade.direction(base + hand) * combat.hand_offset
	var turn := Basis(Vector3.UP, base + yaw) * Basis(Vector3.RIGHT, pitch)
	return Transform3D(turn, at)


## Where the blade's tip is, relative to the fighter's feet, in a pose.
static func tip_of(pose_transform: Transform3D, combat: CombatConfig) -> Vector3:
	return pose_transform * (Vector3.FORWARD * combat.blade_length)


static func _share(into: int, ticks: int) -> float:
	if ticks <= 0:
		return 1.0
	return clampf(float(into) / ticks, 0.0, 1.0)
