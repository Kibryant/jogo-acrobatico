# The combat tokens the duel reads so far (visual-e-audio.md, "Os três canais por estado";
# DEC-0031 §5; TASK-12.2): one TokenData per state, read by the sword, the cues and the HUD by the
# state on screen, never by the simulation. TASK-12.3 adds the charged attack's windup, the parry's
# window, the feint and whoever was parried (visual-e-audio.md, "O carregado, o parry e a finta na
# tela"); the guard break joins with its task.
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
## The charged attack's windup: sky blue from its first tick, the sword above the head.
@export var charged_windup: TokenData
## The parry's window: yellow, the blade crossed in front; only in the window.
@export var parry: TokenData
## The feint: no colour, the pose snapping back.
@export var feint: TokenData
## Whoever was parried: the blade thrown up and back through the stun.
@export var parried: TokenData


# The token a state shows at tick (visual-e-audio.md, "Os três canais por estado"), by its action,
# its move and, in the parry's stance, the tick: the windup of the light or of the charged, the
# active of a swing, the guard rising, up or blocking, the reaction of a hit taken, the parry while
# its window of parry_window_ticks lasts, the feint and the parried one's stun; null for a state
# with no token: at rest, in a recovery, and in the stance once the window closed.
func for_state(state: FighterState, tick: int, parry_window_ticks: int) -> TokenData:
	match state.action:
		FighterState.Action.WINDUP:
			if state.action_move == FighterCommand.CHARGED_ATTACK:
				return charged_windup
			return light_windup
		FighterState.Action.ACTIVE:
			return active
		FighterState.Action.BLOCK, FighterState.Action.BLOCKSTUN:
			return guard
		FighterState.Action.HITSTUN:
			return reaction
		FighterState.Action.PARRY:
			var into := tick - state.action_since
			if into >= 0 and into < parry_window_ticks:
				return parry
		FighterState.Action.FEINT:
			return feint
		FighterState.Action.PARRIED:
			return parried
	return null
