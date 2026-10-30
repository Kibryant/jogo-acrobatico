# The dummy that attacks (partida.md, "O boneco que ataca"; TASK-12.2): until the fighting bot of
# TASK-12.8, Sozinho's dummy starts an action every 3 s, turned toward whoever plays, so the player
# can block it from the front, take it in the back and feel whose turn it is (combate.md, "O
# tranco e a vantagem"). TASK-12.3 mixes its actions (partida.md, "O boneco que ataca": the mix):
# the k-th is a light, a charged or a feint, chosen by a fixed integer hash of k, 2 in 5 lights,
# 2 in 5 charged and 1 in 5 feints, so the player cannot learn the order and the replay plays it
# again with no seed. The feint is a charged cut by the guard button's press 24 ticks into its
# windup, then a light 4 ticks later, which waits in the slot until the feint's 12 ticks end. It
# does not walk, hold the guard or react. Like the BotPlayer it only produces input, through the
# calls the devices use (FighterInput.sample_frame, press_light_attack, press_charged_attack and
# press_guard), and never writes state; the replay records the input it gave, so a session plays
# back without it. The yaw toward the player is read from the bodies on screen before each tick
# loop, as a person reads the screen: what it decided is the input of those ticks, whatever a
# rollback does later.
class_name AttackingDummy
extends Node

## What the k-th action is.
enum Kind {
	LIGHT,
	CHARGED,
	FEINT,
}

## ms between two actions (partida.md, "O boneco que ataca": "um golpe a cada 3 s, 180 ticks").
const PERIOD_MS := 3000
## ms into the feinted charged's windup the guard button goes down: 24 ticks at 60, within the
## feint's 27 (combate.md, "A finta"). Claude's v0 reading (DEC-0017; partida.md, "O boneco que
## ataca").
const FEINT_PRESS_MS := 400
## ms after the feint's press the light is pressed: 4 ticks at 60, so it waits in the slot's 150 ms
## for the feint's 200 to end and fires right then. Claude's v0 reading (DEC-0017).
const LIGHT_AFTER_FEINT_MS := 67
## The hash of the mix (Knuth's multiplicative hash over 32 bits, its high bits folded down): the
## multiplier and the offset, which Claude picked so the first actions already hold all three
## kinds; any other offset is another order, never another share.
const HASH_MULTIPLIER := 2654435761
const HASH_OFFSET := 19
const HASH_MODULUS := 4294967296
## Of 5 hash slots: 0 and 1 are lights, 2 and 3 charged, 4 a feint.
const SLOTS := 5

## The input box it fills: the dummy's.
var input: FighterInput
## The dummy it plays and the fighter it turns toward.
var dummy: Fighter
var target: Fighter
## The tick its clock counts from: the first action comes one period after it.
var start_tick: int
## Ticks between two actions, PERIOD_MS at the match's tickrate.
var period_ticks: int
## Ticks from a feinted charged's press to the guard's press, and from that to the light's.
var feint_press_ticks: int
var light_after_feint_ticks: int


func _init(played: Fighter, turned_to: Fighter, first_tick: int, tickrate: int) -> void:
	name = "AttackingDummy"
	dummy = played
	target = turned_to
	input = played.input
	start_tick = first_tick
	period_ticks = Ticks.from_ms(PERIOD_MS, tickrate)
	feint_press_ticks = Ticks.from_ms(FEINT_PRESS_MS, tickrate)
	light_after_feint_ticks = Ticks.from_ms(LIGHT_AFTER_FEINT_MS, tickrate)


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


## The kind of the k-th action, k from 1: a pure function of k, the same on every PC and in every
## replay, with no randomness and no seed.
static func kind_of(k: int) -> Kind:
	var mixed := (k * HASH_MULTIPLIER + HASH_OFFSET) % HASH_MODULUS
	mixed = mixed ^ (mixed >> 13)
	var slot := mixed % SLOTS
	if slot < 2:
		return Kind.LIGHT
	if slot < 4:
		return Kind.CHARGED
	return Kind.FEINT


## Whether an action begins on tick: every period after its start, never on the start.
func presses_at(tick: int) -> bool:
	var step := tick - start_tick
	return step > 0 and step % period_ticks == 0


## The commands the dummy presses on tick, in the order it presses them (FighterCommand's IDs, the
## guard's press as &"guard"): the action's first press on its period tick, and a feint's guard
## and light after it.
func presses(tick: int) -> Array[StringName]:
	var pressed: Array[StringName] = []
	var step := tick - start_tick
	if step <= 0:
		return pressed
	var k := step / period_ticks
	var into := step % period_ticks
	if k < 1:
		return pressed
	var kind := kind_of(k)
	if into == 0:
		var light := kind == Kind.LIGHT
		pressed.append(FighterCommand.LIGHT_ATTACK if light else FighterCommand.CHARGED_ATTACK)
	elif kind == Kind.FEINT and into == feint_press_ticks:
		pressed.append(&"guard")
	elif kind == Kind.FEINT and into == feint_press_ticks + light_after_feint_ticks:
		pressed.append(FighterCommand.LIGHT_ATTACK)
	return pressed


# netfox gathers the input once per tick loop, before its ticks (rede.md §2): right after a loop the
# dummy turns toward where the target stands now, standing still, for the next loop.
func _turn_for_the_next_loop() -> void:
	if not is_instance_valid(dummy) or not is_instance_valid(target):
		return
	var yaw := yaw_toward(dummy.global_position, target.global_position, dummy.state.facing_yaw)
	input.sample_frame(Vector2.ZERO, yaw)


# Every press is a one-touch command (DEC-0026 §1): pressed right before its own tick, it counts
# on that tick only, as the BotPlayer's jump does. The guard's press never holds the guard.
func _press_on_its_tick(_delta: float, tick: int) -> void:
	for command: StringName in presses(tick):
		match command:
			FighterCommand.LIGHT_ATTACK:
				input.press_light_attack()
			FighterCommand.CHARGED_ATTACK:
				input.press_charged_attack()
			_:
				input.press_guard()
