# The commands the slot of the buffer holds (movimento.md, "Perdão": "Um buffer só, para todo
# comando"; DEC-0039). A StringName, so netfox records the slot as a flat value.
class_name FighterCommand
extends RefCounted

# The empty slot: no press waiting.
const NONE := &""
const JUMP := &"jump"
const DASH := &"dash"
# The grapple (movimento.md, "Gancho"; TASK-10.6).
const GRAPPLE := &"grapple"
# The light attack (combate.md, "O leve no tick"): only Combat.step writes it into the slot, and
# the move's ID in the CombatConfig and in the state (DEC-0051 §4).
const LIGHT_ATTACK := &"light_attack"
# The charged attack and the parry (combate.md, "O carregado, o parry e a finta no tick"; DEC-0056
# §1): only Combat.step writes them into the slot; the charged is a move's ID too.
const CHARGED_ATTACK := &"charged_attack"
const PARRY := &"parry"
