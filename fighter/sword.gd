# The block sword (visual-e-audio.md, "O leve na tela"; TASK-12.1): a box of 1,4 × 0,06 × 0,02 m
# held at the hand, before the mannequin of TASK-12.9. Its pose is a function of the displayed
# state, the action, the tick its phase began and the swing's direction, and of the displayed tick,
# as DEC-0030 §4 asks of the mannequin: nothing of it is in the state, so the rollback never
# touches it and a resimulation never moves it twice (DEC-0031 §6). At rest it hangs on the right,
# the hand's side, pointing forward and down; in the windup it goes back, without colour; in the
# active it sweeps exactly the arc the rule tests (Blade), from the right to the left, in vermilion;
# in the recovery it comes back to rest. The angles of the rest and the windup are Claude's v0
# reading (DEC-0017); the active's are the rule's.
# TASK-12.2 reads the tokens as data (tokens_v0.tres; visual-e-audio.md, "A guarda e o tranco na
# tela"): each state's token names its pose and gives its colour, an alpha of 0 being the steel.
# The guard holds the blade upright in front, rising with the guard's ticks; the reaction throws it
# down and out, the colour of the reaction being the body's flash (ManeuverCues), never the
# blade's. On a frozen tick of the hitstop the pose holds the impact (Combat.posed_tick).
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
## The guard: the hand a little right of the front, lower than the swing's, and the blade nearly
## upright before the body. Claude's v0 reading (DEC-0017; visual-e-audio.md, "A guarda e o tranco
## na tela").
const GUARD_HAND_DEG := -20.0
const GUARD_YAW_DEG := 0.0
const GUARD_PITCH_DEG := 80.0
## m: the guard's hand height above the feet, so the upright blade's tip stays near the head.
const GUARD_HAND_HEIGHT := 0.9
## The reaction: the blade thrown down and out to the right. Claude's v0 reading (DEC-0017).
const RECOIL_HAND_DEG := -75.0
const RECOIL_YAW_DEG := -70.0
const RECOIL_PITCH_DEG := -70.0
## The poses by name, the tokens' (TokenData.pose), and the recovery's own, which has no token.
const POSE_BACK := &"blade_back"
const POSE_ARC := &"arc"
const POSE_UPRIGHT := &"blade_upright"
const POSE_RECOIL := &"recoil"
const POSE_RETURN := &"return"
const POSE_REST := &"rest"
## The pose of each action when no token names one: those of tokens_v0.tres, and the recovery's.
const DEFAULT_POSES: Dictionary[int, StringName] = {
	FighterState.Action.WINDUP: POSE_BACK,
	FighterState.Action.ACTIVE: POSE_ARC,
	FighterState.Action.RECOVERY: POSE_RETURN,
	FighterState.Action.BLOCK: POSE_UPRIGHT,
	FighterState.Action.BLOCKSTUN: POSE_UPRIGHT,
	FighterState.Action.HITSTUN: POSE_RECOIL,
}

var _combat: CombatConfig
var _tokens: TokensData
var _mesh := MeshInstance3D.new()
var _steel := StandardMaterial3D.new()
var _lit := StandardMaterial3D.new()


# tokens may be null, as in the tests that build a sword alone: the default poses and the active's
# vermilion then.
func _init(combat: CombatConfig, tokens: TokensData = null) -> void:
	name = "Sword"
	_combat = combat
	_tokens = tokens
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


# Puts the sword in the pose of state at tick, the displayed ones, and paints it in its token's
# colour, or the steel when the token has none.
func show_pose(state: FighterState, tick: int) -> void:
	transform = pose(state, tick, _combat, _tokens)
	var colour := blade_colour(state, _tokens)
	if colour.a <= 0.0:
		_mesh.material_override = _steel
		return
	_lit.albedo_color = colour
	_mesh.material_override = _lit


## True while the blade wears the vermilion: in the active (visual-e-audio.md).
static func lit(state: FighterState) -> bool:
	return state.action == FighterState.Action.ACTIVE


## The blade's colour in a state: its token's, an alpha of 0 for none; the reaction's colour is the
## body's flash, so the blade has none then. Without tokens, the active's vermilion alone.
static func blade_colour(state: FighterState, tokens: TokensData = null) -> Color:
	if state.action == FighterState.Action.HITSTUN:
		return Color(0, 0, 0, 0)
	if tokens == null:
		return ACTIVE_COLOUR if lit(state) else Color(0, 0, 0, 0)
	var token := tokens.for_action(state.action)
	return token.color if token != null else Color(0, 0, 0, 0)


## The name of the pose a state shows: its token's, or the default of its action (DEFAULT_POSES).
static func pose_name(state: FighterState, tokens: TokensData = null) -> StringName:
	if tokens != null:
		var token := tokens.for_action(state.action)
		if token != null and not token.pose.is_empty():
			return token.pose
	if DEFAULT_POSES.has(state.action):
		return DEFAULT_POSES[state.action]
	return POSE_REST


## The sword's transform relative to the fighter's feet: the origin at the hand, the blade along its
## -Z. In the active the hand sits on the rule's circle, at the angle of the end of the tick's
## slice, and the blade runs radially from it, as Blade.segment draws it. The guard rises from the
## rest to upright over the guard's ticks, and the blockstun holds it up. A frozen tick of the
## hitstop shows the pose of the impact (Combat.posed_tick).
static func pose(
	state: FighterState,
	tick: int,
	combat: CombatConfig,
	tokens: TokensData = null,
) -> Transform3D:
	var base := state.facing_yaw
	var hand := deg_to_rad(REST_HAND_DEG)
	var yaw := deg_to_rad(REST_YAW_DEG)
	var pitch := deg_to_rad(REST_PITCH_DEG)
	var height := combat.hand_height
	var into := Combat.posed_tick(state, tick) - state.action_since + 1
	var named := pose_name(state, tokens)
	if Combat.swinging(state) and combat.attacks.has(state.action_move):
		var attack: AttackConfig = combat.attacks[state.action_move]
		base = state.action_yaw
		match named:
			POSE_BACK:
				var share := _share(into, attack.windup_ticks)
				hand = lerpf(hand, deg_to_rad(BACK_HAND_DEG), share)
				yaw = lerpf(yaw, deg_to_rad(BACK_YAW_DEG), share)
				pitch = lerpf(pitch, deg_to_rad(BACK_PITCH_DEG), share)
			POSE_ARC:
				var theta := Blade.slice_of(attack, clampi(into, 1, attack.active_ticks)).y
				hand = theta
				yaw = theta
				pitch = 0.0
			_:
				var share := _share(into, attack.recovery_ticks)
				hand = lerpf(attack.arc_to, hand, share)
				yaw = lerpf(attack.arc_to, yaw, share)
				pitch = lerpf(0.0, pitch, share)
	elif named == POSE_UPRIGHT:
		var share := 1.0
		if state.action == FighterState.Action.BLOCK:
			share = _share(into, combat.guard_raise_ticks)
		hand = lerpf(hand, deg_to_rad(GUARD_HAND_DEG), share)
		yaw = lerpf(yaw, deg_to_rad(GUARD_YAW_DEG), share)
		pitch = lerpf(pitch, deg_to_rad(GUARD_PITCH_DEG), share)
		height = lerpf(height, GUARD_HAND_HEIGHT, share)
	elif named == POSE_RECOIL:
		hand = deg_to_rad(RECOIL_HAND_DEG)
		yaw = deg_to_rad(RECOIL_YAW_DEG)
		pitch = deg_to_rad(RECOIL_PITCH_DEG)
	var at := Vector3.UP * height + Blade.direction(base + hand) * combat.hand_offset
	var turn := Basis(Vector3.UP, base + yaw) * Basis(Vector3.RIGHT, pitch)
	return Transform3D(turn, at)


## Where the blade's tip is, relative to the fighter's feet, in a pose.
static func tip_of(pose_transform: Transform3D, combat: CombatConfig) -> Vector3:
	return pose_transform * (Vector3.FORWARD * combat.blade_length)


static func _share(into: int, ticks: int) -> float:
	if ticks <= 0:
		return 1.0
	return clampf(float(into) / ticks, 0.0, 1.0)
