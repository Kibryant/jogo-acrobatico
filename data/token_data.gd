# One combat token (visual-e-audio.md, "Os três canais por estado"; DEC-0031): what a state shows on
# its three channels, of which the screen draws two in the v0, the colour and the pose, and the
# shape the HUD repeats it with, never by colour alone (F-053 §2.2). Design data, immutable at
# runtime, read only by the screen: nothing of it enters the simulation (DEC-0004, rule 3).
class_name TokenData
extends Resource

## The token's colour, on the blade or the body; an alpha of 0 is no colour, the default's.
@export var color := Color(0, 0, 0, 0)
## The pose's name, which the sword (and later the mannequin) turns into a pose: a key, not
## a transform, so the pose stays the reader's business (DEC-0030 §4).
@export var pose: StringName
## The shape the HUD draws the token with beside the other fighter's health.
@export var hud_shape: StringName
