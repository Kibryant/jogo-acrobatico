# The combat tokens the duel reads so far (visual-e-audio.md, "Os três canais por estado";
# DEC-0031 §5; TASK-12.2): one TokenData per state, read by the sword, the cues and the HUD by the
# state on screen, never by the simulation. The charged attack, the parry and the guard break join
# with their tasks.
class_name TokensData
extends Resource

## The light attack's windup: no colour, the blade going back.
@export var light_windup: TokenData
## The active of a swing: vermilion on the blade and the trail, the arc.
@export var active: TokenData
## The guard: no colour, the blade upright in front.
@export var guard: TokenData
## The reaction of a hit taken: a white flash, the body recoiling.
@export var reaction: TokenData


# The token a state shows by its action (visual-e-audio.md, "Os três canais por estado"): the
# windup of the light, the active of a swing, the guard rising, up or blocking, and the reaction
# of a hit taken; null for an action with no token, at rest and in a recovery.
func for_action(action: FighterState.Action) -> TokenData:
	match action:
		FighterState.Action.WINDUP:
			return light_windup
		FighterState.Action.ACTIVE:
			return active
		FighterState.Action.BLOCK, FighterState.Action.BLOCKSTUN:
			return guard
		FighterState.Action.HITSTUN:
			return reaction
	return null
