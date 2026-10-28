# The dummy that attacks (partida.md, "O boneco que ataca"; TASK-12.2): until the fighting bot of
# TASK-12.8, Sozinho's dummy presses a light every 3 s, turned toward whoever plays, so the player
# can block it from the front, take it in the back and feel whose turn it is (combate.md, "O
# tranco e a vantagem"). It does not walk, guard or react. Like the BotPlayer it only produces
# input, through the calls the devices use (FighterInput.sample_frame and press_light_attack), and
# never writes state; the replay records the input it gave, so a session plays back without it.
# The yaw toward the player is read from the bodies on screen before each tick loop, as a person
# reads the screen: what it decided is the input of those ticks, whatever a rollback does later.
class_name AttackingDummy
extends Node

## ms between two lights (partida.md, "O boneco que ataca": "um leve a cada 3 s, 180 ticks").
const PERIOD_MS := 3000

## The input box it fills: the dummy's.
var input: FighterInput
## The dummy it plays and the fighter it turns toward.
var dummy: Fighter
var target: Fighter
## The tick its clock counts from: the first light comes one period after it.
var start_tick: int
## Ticks between two lights, PERIOD_MS at the match's tickrate.
var period_ticks: int


func _init(played: Fighter, turned_to: Fighter, first_tick: int, tickrate: int) -> void:
	name = "AttackingDummy"
	dummy = played
	target = turned_to
	input = played.input
	start_tick = first_tick
	period_ticks = Ticks.from_ms(PERIOD_MS, tickrate)


func _enter_tree() -> void:
	NetworkTime.before_tick.connect(_press_on_its_tick)
	NetworkTime.after_tick_loop.connect(_turn_for_the_next_loop)


func _exit_tree() -> void:
	NetworkTime.before_tick.disconnect(_press_on_its_tick)
	NetworkTime.after_tick_loop.disconnect(_turn_for_the_next_loop)


func _ready() -> void:
	_turn_for_the_next_loop()


## The yaw that looks from the dummy's feet to the target's, on the floor's plane: yaw 0 looks down
## -Z and a positive yaw turns left (Blade.direction). The dummy's own yaw when they stand on one
## axis.
static func yaw_toward(from: Vector3, to: Vector3, otherwise: float) -> float:
	var toward := Vector3(to.x - from.x, 0.0, to.z - from.z)
	if toward.is_zero_approx():
		return otherwise
	return atan2(-toward.x, -toward.z)


## Whether the dummy presses the light on tick: every period after its start, never on the start.
func presses_at(tick: int) -> bool:
	var step := tick - start_tick
	return step > 0 and step % period_ticks == 0


# netfox gathers the input once per tick loop, before its ticks (rede.md §2): right after a loop the
# dummy turns toward where the target stands now, standing still, for the next loop.
func _turn_for_the_next_loop() -> void:
	if not is_instance_valid(dummy) or not is_instance_valid(target):
		return
	var yaw := yaw_toward(dummy.global_position, target.global_position, dummy.state.facing_yaw)
	input.sample_frame(Vector2.ZERO, yaw)


# The light is a one-touch command (DEC-0026 §1): pressed right before its own tick, it counts on
# that tick only, as the BotPlayer's jump does.
func _press_on_its_tick(_delta: float, tick: int) -> void:
	if presses_at(tick):
		input.press_light_attack()
