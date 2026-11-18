# The dummy that attacks (partida.md, "O boneco que ataca"; TASK-12.2): until the fighting bot of
# TASK-12.8, Sozinho's dummy starts an action every 3 s, turned toward whoever plays, so the player
# can block it from the front, take it in the back and feel whose turn it is (combate.md, "O
# tranco e a vantagem"). Since TASK-12.14 it turns as a person aims (combate.md, "A espada na mira":
# "O boneco e o bot miram como gente"; DEC-0057 §4): the yaw it sends puts its own aim line, which
# leaves its point O on its shoulder's side (DEC-0045 §2), on the player's axis, so its swing
# converges like a player's and lands on whoever stands still in front of it (aim_yaw).
# TASK-12.3 mixes its actions (partida.md, "O boneco que ataca": the mix):
# the k-th is chosen by a fixed integer hash of k, so the player cannot learn the order and the
# replay plays it again with no seed. Since TASK-12.4 the cycle is of 6: 2 lights, 2 charged, 1
# feint and 1 guard break, and no tech when it is grabbed (F-210 §1; DEC-0058). The feint is a
# charged cut by the guard button's press 24 ticks into its windup, then a light 4 ticks later,
# which waits in the slot until the feint's 12 ticks end. The guard break grabs whoever stands
# within its hand's reach, 0,88 to 1,48 m with its aim on the player (combate.md, "A mão"). To train
# the tech, --dummy=guard_break makes it throw only guard breaks, one every period, aiming as a
# person does (partida.md, "A mistura do boneco"; F-212): only_guard_breaks. It does not walk, hold
# the guard or react. Like the BotPlayer it only produces input, through the calls
# the devices use (FighterInput.sample_frame, press_light_attack, press_charged_attack,
# press_guard and press_guard_break), and never writes state; the replay records the input it
# gave, so a session plays back without it. The yaw toward the player is read from the bodies on
# screen before each tick loop, as a person reads the screen: what it decided is the input of those
# ticks, whatever a rollback does later.
class_name AttackingDummy
extends Node

## What the k-th action is.
enum Kind {
	LIGHT,
	CHARGED,
	FEINT,
	GUARD_BREAK,
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
## multiplier and the offset, which Claude picked so the first four actions already hold all four
## kinds (a light, a charged, a guard break and a feint, in that order); any other offset is another
## order, never another share.
const HASH_MULTIPLIER := 2654435761
const HASH_OFFSET := 5
const HASH_MODULUS := 4294967296
## Of 6 hash slots: 0 and 1 are lights, 2 and 3 charged, 4 a feint and 5 a guard break.
const SLOTS := 6

## The input box it fills: the dummy's.
var input: FighterInput
## The dummy it plays and the fighter it aims at, as a person does (DEC-0057).
var dummy: Fighter
var target: Fighter
## The tick its clock counts from: the first action comes one period after it.
var start_tick: int
## Ticks between two actions, PERIOD_MS at the match's tickrate.
var period_ticks: int
## Ticks from a feinted charged's press to the guard's press, and from that to the light's.
var feint_press_ticks: int
var light_after_feint_ticks: int
## Every action a guard break, for training the tech (--dummy=guard_break; F-212), instead of the
## mix of kind_of.
var only_guard_breaks := false


func _init(
	played: Fighter,
	turned_to: Fighter,
	first_tick: int,
	tickrate: int,
	guard_breaks_only := false,
) -> void:
	name = "AttackingDummy"
	dummy = played
	target = turned_to
	only_guard_breaks = guard_breaks_only
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


## The yaw of a person aiming at the target (combate.md, "A espada na mira": "O boneco e o bot miram
## como gente"; DEC-0057 §4): the one whose aim line, side metres to the right of the dummy's axis
## along the yaw (Aim.origin), passes through the target's axis. It is the feet-to-feet yaw plus
## asin(side / d), d the distance on the floor's plane, turned left of the target so the right
## shoulder's line falls on it. When d is not greater than the shoulder no aim line can pass over
## the target, and it is the feet-to-feet yaw alone; on one axis, otherwise, as in yaw_toward.
static func aim_yaw(from: Vector3, to: Vector3, side: float, otherwise: float) -> float:
	var toward := yaw_toward(from, to, otherwise)
	var across := to.x - from.x
	var along := to.z - from.z
	var distance := sqrt(across * across + along * along)
	if distance <= absf(side):
		return toward
	return toward + asin(side / distance)


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
	if slot < 5:
		return Kind.FEINT
	return Kind.GUARD_BREAK


## The kind of this dummy's k-th action: the mix's (kind_of), or a guard break every time when it
## trains the tech (only_guard_breaks).
func kind_at(k: int) -> Kind:
	return Kind.GUARD_BREAK if only_guard_breaks else kind_of(k)


## Whether an action begins on tick: every period after its start, never on the start.
func presses_at(tick: int) -> bool:
	var step := tick - start_tick
	return step > 0 and step % period_ticks == 0


## The commands the dummy presses on tick, in the order it presses them (FighterCommand's IDs, the
## guard's press as &"guard"): the action's first press on its period tick, the light, the charged
## or the guard break, and a feint's guard and light after it.
func presses(tick: int) -> Array[StringName]:
	var pressed: Array[StringName] = []
	var step := tick - start_tick
	if step <= 0:
		return pressed
	var k := step / period_ticks
	var into := step % period_ticks
	if k < 1:
		return pressed
	var kind := kind_at(k)
	if into == 0:
		match kind:
			Kind.LIGHT:
				pressed.append(FighterCommand.LIGHT_ATTACK)
			Kind.GUARD_BREAK:
				pressed.append(FighterCommand.GUARD_BREAK)
			_:
				pressed.append(FighterCommand.CHARGED_ATTACK)
	elif kind == Kind.FEINT and into == feint_press_ticks:
		pressed.append(&"guard")
	elif kind == Kind.FEINT and into == feint_press_ticks + light_after_feint_ticks:
		pressed.append(FighterCommand.LIGHT_ATTACK)
	return pressed


# netfox gathers the input once per tick loop, before its ticks (rede.md §2): right after a loop the
# dummy aims at where the target stands now, standing still, for the next loop, with its own
# fighter's shoulder.
func _turn_for_the_next_loop() -> void:
	if not is_instance_valid(dummy) or not is_instance_valid(target):
		return
	var yaw := aim_yaw(
		dummy.global_position,
		target.global_position,
		dummy.config.aim_side,
		dummy.state.facing_yaw,
	)
	input.sample_frame(Vector2.ZERO, yaw)


# Every press is a one-touch command (DEC-0026 §1): pressed right before its own tick, it counts
# on that tick only, as the BotPlayer's jump does. The guard's press never holds the guard. The
# dummy never gives the tech (partida.md, "A mistura do boneco": "O boneco nunca dá o tech"; F-210
# §1): held GRABBED on screen, it leaves out the guard break its mix schedules, the tech's key.
func _press_on_its_tick(_delta: float, tick: int) -> void:
	for command: StringName in presses(tick):
		match command:
			FighterCommand.LIGHT_ATTACK:
				input.press_light_attack()
			FighterCommand.CHARGED_ATTACK:
				input.press_charged_attack()
			FighterCommand.GUARD_BREAK:
				if not grabbed():
					input.press_guard_break()
			_:
				input.press_guard()


## Whether the dummy's state on screen is held GRABBED: then the guard break would be the tech.
func grabbed() -> bool:
	return is_instance_valid(dummy) and dummy.state.action == FighterState.Action.GRABBED
