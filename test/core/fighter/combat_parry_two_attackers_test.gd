# TASK-12.3, an edge of the parry (combate.md, "O carregado, o parry e a finta no tick": "O leve
# não se apara"; DEC-0056 §4): two attackers touch the same parrier on the same tick, one with a
# charged inside the parry's window and one with a light. Only the charged's attacker reads the
# parry stamp and becomes PARRIED; the light's attacker reads its own result, the hit the light
# gave the stance, and freezes the 4 ticks of a hit, its swing going on. Three GuardRigs under a
# Duel with a TickPhoto taken by hand on every tick; the parrier is first by name, then the
# charged's attacker, so the parry is resolved before the light's hit ends the stance.
extends GdUnitTestSuite

const ChargedRig := preload("res://test/core/fighter/charged_rig.gd")
const MovementRig := preload("res://test/core/fighter/movement_rig.gd")
const Duel := preload("res://test/core/fighter/duel.gd")

const FIRST_TICK := 1000 # any tick: the rules read stamps, not counts (visao-geral.md)
const TICKRATE := 60
const PARRIER := &"A"
const CHARGER := &"B"
const LIGHTER := &"C"
# The parrier 1,5 m ahead of the charger, who looks down -Z from the origin: the cut touches it on
# the first active tick, 42 ticks after the press (combate.md, "O toque do carregado"). The light's
# attacker 1,5 m beyond the parrier, looking back up +Z: its light touches the parrier 17 ticks
# after the press, on its third slice (test/core/fighter/combat_parry_test.gd,
# LIGHT_CONTACT_OFFSET).
const PARRIER_FEET := Vector3(0.0, 0.0, -1.5)
const LIGHTER_FEET := Vector3(0.0, 0.0, -3.0)
const FACING_PLUS_Z := PI
const CHARGED_WINDUP_TICKS := 42 # combate.md, "Os golpes e as defesas": 42 / 7 / 27
const LIGHT_CONTACT_OFFSET := 17
const INTO_THE_WINDOW := 6 # ticks into the parry's window of 12 the contact falls: arithmetic
# combate.md, "O hitstop e o tremor": "Leve acerta: 4 ticks"; "Parry: só quem foi aparado, 9".
const LIGHT_HITSTOP_TICKS := 4
const PARRIED_HITSTOP_TICKS := 9
const LIGHT_DAMAGE := 12
const MAX_HEALTH := 100
const SPARE_TICKS := 12 # ticks the run keeps going past the contact: arithmetic


func _fighter(name: StringName, feet: Vector3, yaw: float, combat: CombatConfig) -> ChargedRig:
	return ChargedRig.new(name, MovementRig.load_config(TICKRATE), combat, FIRST_TICK, feet, yaw)


func _script(presses: Dictionary[int, TickInput], yaw: float) -> Callable:
	return func(tick: int) -> TickInput:
		return presses[tick] if presses.has(tick) else ChargedRig.idle(yaw)


func test_on_one_tick_only_the_charged_is_parried_and_the_light_learns_its_hit() -> void:
	var contact := FIRST_TICK + 60
	var charged_press := contact - CHARGED_WINDUP_TICKS
	var light_press := contact - LIGHT_CONTACT_OFFSET
	var parry_press := contact - INTO_THE_WINDOW
	var combat := ChargedRig.load_combat(TICKRATE)
	var duel := Duel.new()
	var parries: Dictionary[int, TickInput] = {
		parry_press: ChargedRig.press_parry(Vector2.ZERO, FACING_PLUS_Z),
	}
	duel.add(
		_fighter(PARRIER, PARRIER_FEET, FACING_PLUS_Z, combat),
		_script(parries, FACING_PLUS_Z),
	)
	var charges: Dictionary[int, TickInput] = {
		charged_press: ChargedRig.press_charged(Vector2.ZERO, 0.0),
	}
	duel.add(_fighter(CHARGER, Vector3.ZERO, 0.0, combat), _script(charges, 0.0))
	var lights: Dictionary[int, TickInput] = {
		light_press: ChargedRig.press_light(Vector2.ZERO, FACING_PLUS_Z),
	}
	duel.add(_fighter(LIGHTER, LIGHTER_FEET, FACING_PLUS_Z, combat), _script(lights, FACING_PLUS_Z))
	duel.run_through(contact + SPARE_TICKS)
	assert_int(duel.contact_tick_of(1)).override_failure_message("the charged missed").is_equal(
		contact
	)
	assert_int(duel.contact_tick_of(2)).override_failure_message("the light missed").is_equal(
		contact
	)
	# The parrier parries the charged and takes the light as without a defense.
	var parrier := duel.row_at(contact + 1).fought[0]
	assert_int(parrier.parry_tick).is_equal(contact)
	assert_int(parrier.hurt_tick).is_equal(contact)
	assert_int(parrier.health).is_equal(MAX_HEALTH - LIGHT_DAMAGE)
	assert_int(parrier.action).is_equal(FighterState.Action.HITSTUN)
	# Two ticks after the contact: the charged's attacker is PARRIED, frozen 9 ticks alone.
	var charger := duel.row_at(contact + 2).fought[1]
	assert_int(charger.action).is_equal(FighterState.Action.PARRIED)
	assert_int(charger.parried_tick).is_equal(contact)
	assert_int(charger.frozen_until_tick).is_equal(contact + 2 + PARRIED_HITSTOP_TICKS - 1)
	# The light's attacker is never PARRIED: it reads the hit, freezes its 4 ticks, and its swing
	# goes on.
	for row: Duel.Row in duel.rows:
		var lighter := row.fought[2]
		var where := "tick %d: %s" % [row.tick, FighterState.Action.find_key(lighter.action)]
		assert_int(lighter.action).override_failure_message(where).is_not_equal(
			FighterState.Action.PARRIED
		)
		assert_int(lighter.parried_tick).override_failure_message(where).is_equal(
			FighterState.NEVER
		)
	var lighter := duel.row_at(contact + 2).fought[2]
	assert_bool(Combat.swinging(lighter)).override_failure_message("the light's swing ended") \
			.is_true()
	assert_str(String(lighter.action_move)).is_equal(String(FighterCommand.LIGHT_ATTACK))
	assert_int(lighter.frozen_until_tick).is_equal(contact + 1 + LIGHT_HITSTOP_TICKS)
	assert_bool(duel.row_at(contact + 2).plans[2].frozen).is_true()
	assert_bool(duel.row_at(contact + 1).plans[2].frozen).is_false()
