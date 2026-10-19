# The commands the slot of the buffer holds (movimento.md, "Perdão": "Um buffer só, para todo
# comando"; DEC-0039). A StringName, so netfox records the slot as a flat value; the dash and the
# grapple join when they exist (TASK-10.4 and TASK-10.6).
class_name FighterCommand
extends RefCounted

# The empty slot: no press waiting.
const NONE := &""
const JUMP := &"jump"
