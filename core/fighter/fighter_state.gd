# The rules box of the fighter (visao-geral.md, "O estado em quatro caixas"): flat values only,
# which netfox records field by field through paths like ":state:mode" (DEC-0022). The body box,
# position and velocity, lives on the Fighter node. Times are stamps, the tick something
# happened, never counters (visao-geral.md, "Carimbo, não contagem").
class_name FighterState
extends RefCounted

# The state machine as data (DEC-0022): the mode and the tick it began.
enum Mode {
	GROUND,
	AIR,
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
# The tick of the last jump press still waiting; the jump consumes it back to NEVER.
var jump_pressed_tick := NEVER
# Jumps since the floor: the jump adds one, the floor renews it.
var jumps_used := 0
# Where the body looks, in rad: the camera's yaw (movimento.md, "Princípios").
var facing_yaw := 0.0


# An equal and independent state: the rules change the copy, never the state they receive.
func copy() -> FighterState:
	var other := FighterState.new()
	other.mode = mode
	other.mode_since = mode_since
	other.on_floor = on_floor
	other.left_floor_tick = left_floor_tick
	other.jump_pressed_tick = jump_pressed_tick
	other.jumps_used = jumps_used
	other.facing_yaw = facing_yaw
	return other
