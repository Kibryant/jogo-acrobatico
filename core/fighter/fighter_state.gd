# The rules box of the fighter (visao-geral.md, "O estado em quatro caixas"): flat values only,
# which netfox records field by field through paths like ":state:mode" (DEC-0022). The body box,
# position and velocity, lives on the Fighter node. Times are stamps, the tick something
# happened, never counters (visao-geral.md, "Carimbo, não contagem").
class_name FighterState
extends RefCounted

# The state machine as data (DEC-0022): the mode and the tick it began. GROUND and AIR change by
# contact, in after_move; DASH is a committed mode, which a command starts and only its own rule
# ends, both in before_move (DEC-0041). WALL_RUN is committed too, the input neither turns nor
# brakes it: the contact starts it in after_move, and it ends by its time or the wall jump in
# before_move, or by the contact lost in after_move (DEC-0041; movimento.md, "Corrida na parede").
# GRAPPLE is the pull toward the hook's point, committed too: it starts when the cable has flown
# and ends by its own release, both in before_move (DEC-0041; movimento.md, "Gancho").
enum Mode {
	GROUND,
	AIR,
	DASH = 2,
	WALL_RUN = 3,
	GRAPPLE = 4,
}

# The stamp of "never": far enough in the past that no window reaches it, so a fresh state
# never reads as a press or a ledge. Any tick minus NEVER still fits in 64-bit ints.
const NEVER := -1073741824

# A fresh state stands on the floor, as at a spawn point, since forever and with no stamps.
var mode: Mode = Mode.GROUND
var mode_since := NEVER
# The engine's verdict at the end of the last tick (MoveFacts.on_floor).
var on_floor := true
# The tick whose after_move first saw the body off the floor; the coyote counts from it.
var left_floor_tick := NEVER
# The slot of the buffer, one for every command (movimento.md, "Perdão"; DEC-0039): the command
# of the last press still waiting and its tick. A new press takes the slot; the command that
# fires, or a press whose window closed, leaves it empty (FighterCommand.NONE and NEVER).
var buffered_command: StringName = FighterCommand.NONE
var buffered_tick := NEVER
# Jumps since the floor, 0 to 2: the jump makes it 1, the double jump 2, the floor renews it.
var jumps_used := 0
# Where the body looks, in rad: the camera's yaw (movimento.md, "Princípios").
var facing_yaw := 0.0
# The stamina as a value and a stamp (movimento.md, "Stamina": "Como se guarda"): the bar right
# after the last spend and the tick of that spend. Stamina.at computes the bar from the tick;
# never spent, the bar is full.
var stamina_at_spend := 0.0
var stamina_spent_tick := NEVER
# The tick of the double jump of this flight; the floor clears it. The key its visual signal
# will play by, once per event (DEC-0031; TASK-10.4).
var double_jump_tick := NEVER
# The tick the last dash started: the dash lasts dash_ticks from it, and the next one may start
# dash_ticks + dash_cooldown_ticks after it, so the cooldown counts from the end (movimento.md,
# "Dash": "Recarga"). It stays after the dash; NEVER is a dash that never happened.
var dash_tick := NEVER
# Where the last dash goes: a horizontal unit vector, fixed on its first tick (movimento.md,
# "Dash": "Direção").
var dash_direction := Vector3.ZERO
# The wall of the run now, or of the last one (DEC-0042 §2): the flattened unit normal of its face
# and its identity, the collider's node path relative to the Arena, never an engine id. They stay
# after the run, so the same wall refuses a new one, until the floor clears them (movimento.md,
# "Corrida na parede": "Mesma parede"). A seam passes the run to the next block of the plane
# (F-129).
var wall_normal := Vector3.ZERO
var wall_id: StringName = &""
# The tick of the last wall jump: the key its visual signal plays by (DEC-0031). It stays after
# the jump; NEVER is a wall jump that never happened.
var wall_jump_tick := NEVER
# The grapple (movimento.md, "Gancho"; DEC-0044). The tick the hook was fired, while a cable is in
# the air, flying or pulling; NEVER when none is. The cable flies grapple_attach_ticks from it.
var grapple_fired_tick := NEVER
# Where the hook bit: the point the aim found on the fire, fixed until the release; the pull takes
# the feet to it.
var grapple_point := Vector3.ZERO
# The tick of the last release: the cooldown counts from it, as the dash's counts from its end
# ("Recarga"). It stays after the release; NEVER is a grapple that never happened.
var grapple_end_tick := NEVER
# Another fighter's head under the feet (movimento.md, "O corpo": "A cabeça do outro"; TASK-10.7):
# the horizontal unit vector away from the fighter below while the body is on its head, ZERO off
# it; and the tick the contact with that head began, the key its cue plays by (DEC-0031), NEVER
# off it. Declared before their rule (TASK-10.7, round A): nothing writes them yet.
var slide_off_dir := Vector3.ZERO
var head_landing_tick := NEVER


# An equal and independent state: the rules change the copy, never the state they receive.
func copy() -> FighterState:
	var other := FighterState.new()
	other.mode = mode
	other.mode_since = mode_since
	other.on_floor = on_floor
	other.left_floor_tick = left_floor_tick
	other.buffered_command = buffered_command
	other.buffered_tick = buffered_tick
	other.jumps_used = jumps_used
	other.facing_yaw = facing_yaw
	other.stamina_at_spend = stamina_at_spend
	other.stamina_spent_tick = stamina_spent_tick
	other.double_jump_tick = double_jump_tick
	other.dash_tick = dash_tick
	other.dash_direction = dash_direction
	other.wall_normal = wall_normal
	other.wall_id = wall_id
	other.wall_jump_tick = wall_jump_tick
	other.grapple_fired_tick = grapple_fired_tick
	other.grapple_point = grapple_point
	other.grapple_end_tick = grapple_end_tick
	other.slide_off_dir = slide_off_dir
	other.head_landing_tick = head_landing_tick
	return other
