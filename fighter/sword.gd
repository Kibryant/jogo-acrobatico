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
# TASK-12.3 (visual-e-audio.md, "O carregado, o parry e a finta na tela"): the charged's windup
# holds the sword above the head, sky blue, from its first tick, and trembles without recoiling when
# a light meets its armor; its active follows the rule's vertical cut, slice by slice, in
# vermilion; the parry's stance crosses the blade in front, yellow only in its window; the feint
# snaps the pose back to rest; whoever was parried holds the blade thrown up and back through the
# stun. The token is chosen by the action, the move and, in the stance, the tick
# (TokensData.for_state).
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
## The charged's windup (TASK-12.3): the hand above the head, a little right of the front, and the
## blade raised past upright, its tip behind the head. Claude's v0 reading (DEC-0017;
## visual-e-audio.md, "A espada acima da cabeça desde o tick 0").
const OVERHEAD_HAND_DEG := -15.0
const OVERHEAD_YAW_DEG := 0.0
const OVERHEAD_PITCH_DEG := 115.0
## m: the overhead hand's height above the feet, above the capsule's 1,8 m.
const OVERHEAD_HAND_HEIGHT := 1.9
## The parry's stance: the hand in front, a little right, and the blade across the body, pointing
## left and a little up. Claude's v0 reading (DEC-0017; "A lâmina cruzada à frente").
const CROSSED_HAND_DEG := -25.0
const CROSSED_YAW_DEG := 80.0
const CROSSED_PITCH_DEG := 20.0
## m: the crossed hand's height above the feet, at the chest.
const CROSSED_HAND_HEIGHT := 1.35
## Whoever was parried: the blade thrown up and back over the right shoulder, held through the stun.
## Claude's v0 reading (DEC-0017; F-188, the "reflexo" on the capsule).
const REFLECT_HAND_DEG := -50.0
const REFLECT_YAW_DEG := -160.0
const REFLECT_PITCH_DEG := 55.0
## m: the reflected hand's height above the feet, by the head.
const REFLECT_HAND_HEIGHT := 1.7
## The feint's snap: the overhead pose back to the rest in this many ticks, a jolt rather than a
## swing. Claude's v0 reading (DEC-0017; "A pose volta num estalo").
const SNAP_TICKS := 2
## The armor's tremor: the sword shakes this far to each side, alternating every tick and dying
## out over this many ticks, from the first tick the armored hit shows. Claude's v0 reading
## (DEC-0017; "O corpo não recua: só um tremor").
const TREMOR_M := 0.04
const TREMOR_TICKS := 6
## The poses by name, the tokens' (TokenData.pose), and the recovery's own, which has no token.
const POSE_BACK := &"blade_back"
const POSE_ARC := &"arc"
const POSE_UPRIGHT := &"blade_upright"
const POSE_RECOIL := &"recoil"
const POSE_OVERHEAD := &"overhead"
const POSE_CROSSED := &"crossed"
const POSE_SNAP := &"snap"
const POSE_REFLECT := &"reflect"
const POSE_RETURN := &"return"
const POSE_REST := &"rest"
## The pose of each action when no token names one: those of tokens_v0.tres, and the recovery's;
## the stance keeps its crossed pose once its window closes and its token goes.
const DEFAULT_POSES: Dictionary[int, StringName] = {
	FighterState.Action.WINDUP: POSE_BACK,
	FighterState.Action.ACTIVE: POSE_ARC,
	FighterState.Action.RECOVERY: POSE_RETURN,
	FighterState.Action.BLOCK: POSE_UPRIGHT,
	FighterState.Action.BLOCKSTUN: POSE_UPRIGHT,
	FighterState.Action.HITSTUN: POSE_RECOIL,
	FighterState.Action.PARRY: POSE_CROSSED,
	FighterState.Action.FEINT: POSE_SNAP,
	FighterState.Action.PARRIED: POSE_REFLECT,
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
	var colour := blade_colour(state, _tokens, tick, _combat)
	if colour.a <= 0.0:
		_mesh.material_override = _steel
		return
	_lit.albedo_color = colour
	_mesh.material_override = _lit


## True while the blade wears the vermilion: in the active (visual-e-audio.md).
static func lit(state: FighterState) -> bool:
	return state.action == FighterState.Action.ACTIVE


## The token a state shows at tick (TokensData.for_state); null without tokens or with none. The
## parry's window needs the combat's numbers: without them the stance shows no token.
static func token_of(
	state: FighterState,
	tokens: TokensData,
	tick: int,
	combat: CombatConfig,
) -> TokenData:
	if tokens == null:
		return null
	var window := combat.parry_window_ticks if combat != null else 0
	return tokens.for_state(state, tick, window)


## The blade's colour in a state at tick: its token's, an alpha of 0 for none; the reaction's colour
## is the body's flash, so the blade has none then. Without tokens, the active's vermilion alone.
static func blade_colour(
	state: FighterState,
	tokens: TokensData = null,
	tick := 0,
	combat: CombatConfig = null,
) -> Color:
	if state.action == FighterState.Action.HITSTUN:
		return Color(0, 0, 0, 0)
	if tokens == null:
		return ACTIVE_COLOUR if lit(state) else Color(0, 0, 0, 0)
	var token := token_of(state, tokens, tick, combat)
	return token.color if token != null else Color(0, 0, 0, 0)


## The name of the pose a state shows at tick: its token's, or the default of its action
## (DEFAULT_POSES), the charged's windup being overhead.
static func pose_name(
	state: FighterState,
	tokens: TokensData = null,
	tick := 0,
	combat: CombatConfig = null,
) -> StringName:
	var token := token_of(state, tokens, tick, combat)
	if token != null and not token.pose.is_empty():
		return token.pose
	var charged := state.action_move == FighterCommand.CHARGED_ATTACK
	if state.action == FighterState.Action.WINDUP and charged:
		return POSE_OVERHEAD
	if DEFAULT_POSES.has(state.action):
		return DEFAULT_POSES[state.action]
	return POSE_REST


## The sword's transform relative to the fighter's feet: the origin at the hand, the blade along its
## -Z. In the active the hand sits on the rule's circle, at the angle of the end of the tick's
## slice, and the blade runs radially from it, as Blade.segment draws it, or, for a vertical cut, at
## the elevation of the end of the tick's slice, as Blade.cut_segment draws it. The guard rises from
## the rest to upright over the guard's ticks, and the blockstun holds it up. A frozen tick of the
## hitstop shows the pose of the impact (Combat.posed_tick).
static func pose(
	state: FighterState,
	tick: int,
	combat: CombatConfig,
	tokens: TokensData = null,
) -> Transform3D:
	var shape := _rest(combat)
	var base := state.facing_yaw
	var into := Combat.posed_tick(state, tick) - state.action_since + 1
	var named := pose_name(state, tokens, tick, combat)
	if Combat.swinging(state) and combat.attacks.has(state.action_move):
		var attack: AttackConfig = combat.attacks[state.action_move]
		base = state.action_yaw
		match named:
			POSE_BACK:
				var back := _shape(
					BACK_HAND_DEG,
					BACK_YAW_DEG,
					BACK_PITCH_DEG,
					combat.hand_height,
					combat,
				)
				shape = shape.toward(back, _share(into, attack.windup_ticks))
			POSE_OVERHEAD:
				shape = _overhead(combat)
				_tremble(shape, state, tick, attack, base)
			POSE_ARC:
				var theta := Blade.slice_of(attack, clampi(into, 1, attack.active_ticks)).y
				shape = _swung(attack, theta, combat)
			_:
				var share := _share(into, attack.recovery_ticks)
				shape = _swung(attack, attack.arc_to, combat).toward(shape, share)
	elif named == POSE_UPRIGHT:
		var share := 1.0
		if state.action == FighterState.Action.BLOCK:
			share = _share(into, combat.guard_raise_ticks)
		var upright := _shape(
			GUARD_HAND_DEG,
			GUARD_YAW_DEG,
			GUARD_PITCH_DEG,
			GUARD_HAND_HEIGHT,
			combat,
		)
		shape = shape.toward(upright, share)
	elif named == POSE_RECOIL:
		shape = _shape(
			RECOIL_HAND_DEG,
			RECOIL_YAW_DEG,
			RECOIL_PITCH_DEG,
			combat.hand_height,
			combat,
		)
	elif named == POSE_CROSSED:
		shape = _shape(
			CROSSED_HAND_DEG,
			CROSSED_YAW_DEG,
			CROSSED_PITCH_DEG,
			CROSSED_HAND_HEIGHT,
			combat,
		)
	elif named == POSE_SNAP:
		shape = _overhead(combat).toward(shape, _share(into, SNAP_TICKS))
	elif named == POSE_REFLECT:
		shape = _shape(
			REFLECT_HAND_DEG,
			REFLECT_YAW_DEG,
			REFLECT_PITCH_DEG,
			REFLECT_HAND_HEIGHT,
			combat,
		)
	var at := Vector3.UP * shape.height + Blade.direction(base + shape.hand) * shape.out
	at += shape.offset
	var turn := Basis(Vector3.UP, base + shape.yaw) * Basis(Vector3.RIGHT, shape.pitch)
	return Transform3D(turn, at)


## Where the blade's tip is, relative to the fighter's feet, in a pose.
static func tip_of(pose_transform: Transform3D, combat: CombatConfig) -> Vector3:
	return pose_transform * (Vector3.FORWARD * combat.blade_length)


static func _share(into: int, ticks: int) -> float:
	if ticks <= 0:
		return 1.0
	return clampf(float(into) / ticks, 0.0, 1.0)


# A pose from its angles in degrees and the hand's height, the hand at the combat's offset.
static func _shape(
	hand_deg: float,
	yaw_deg: float,
	pitch_deg: float,
	height: float,
	combat: CombatConfig,
) -> PoseShape:
	return PoseShape.new(
		deg_to_rad(hand_deg),
		deg_to_rad(yaw_deg),
		deg_to_rad(pitch_deg),
		height,
		combat.hand_offset,
	)


static func _rest(combat: CombatConfig) -> PoseShape:
	return _shape(REST_HAND_DEG, REST_YAW_DEG, REST_PITCH_DEG, combat.hand_height, combat)


static func _overhead(combat: CombatConfig) -> PoseShape:
	return _shape(
		OVERHEAD_HAND_DEG,
		OVERHEAD_YAW_DEG,
		OVERHEAD_PITCH_DEG,
		OVERHEAD_HAND_HEIGHT,
		combat,
	)


# The blade where the rule measures it at the angle of a swing: flat at theta, or, for a vertical
# cut, at the elevation theta, the hand straight ahead on the cut's circle.
static func _swung(attack: AttackConfig, theta: float, combat: CombatConfig) -> PoseShape:
	if not attack.vertical_cut:
		return PoseShape.new(theta, theta, 0.0, combat.hand_height, combat.hand_offset)
	return PoseShape.new(
		0.0,
		0.0,
		theta,
		combat.hand_height + combat.hand_offset * sin(theta),
		combat.hand_offset * cos(theta),
	)


# The armor's tremor (visual-e-audio.md, "Armadura": "só um tremor"): from the first tick an armored
# hit of this windup shows, the tick after its contact, the hand jolts to one side and the other,
# dying out over TREMOR_TICKS. Keyed by hurt_tick, a stamp, so a resimulation shows the same.
static func _tremble(
	shape: PoseShape,
	state: FighterState,
	tick: int,
	attack: AttackConfig,
	base: float,
) -> void:
	if not attack.armor or state.hurt_tick < state.action_since:
		return
	var age := tick - state.hurt_tick - 1
	if age < 0 or age >= TREMOR_TICKS:
		return
	var side := 1.0 if age % 2 == 0 else -1.0
	var size := TREMOR_M * (1.0 - float(age) / TREMOR_TICKS)
	shape.offset = Blade.direction(base - PI / 2.0) * side * size


# The parameters of one pose: the hand's angle off the facing and its distance from the axis, the
# blade's yaw and pitch, the hand's height, and a jolt of the whole sword.
class PoseShape:
	var hand: float
	var yaw: float
	var pitch: float
	var height: float
	var out: float
	var offset := Vector3.ZERO


	func _init(
		hand_angle: float,
		blade_yaw: float,
		blade_pitch: float,
		hand_height: float,
		hand_out: float,
	) -> void:
		hand = hand_angle
		yaw = blade_yaw
		pitch = blade_pitch
		height = hand_height
		out = hand_out


	# The pose share of the way from this one to other, in a straight line, each number apart.
	func toward(other: PoseShape, share: float) -> PoseShape:
		return PoseShape.new(
			lerpf(hand, other.hand, share),
			lerpf(yaw, other.yaw, share),
			lerpf(pitch, other.pitch, share),
			lerpf(height, other.height, share),
			lerpf(out, other.out, share),
		)
