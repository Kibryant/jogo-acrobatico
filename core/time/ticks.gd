# The design writes times in ms and the core counts integer ticks (DEC-0004, rule 3). The
# conversion runs once, when the configuration is made at load (visao-geral.md, "O tempo e a
# física no estado" and "A configuração nasce na carga").
class_name Ticks
extends RefCounted

const MS_PER_SECOND := 1000
# Half a tick, in the units of ms * tickrate, where a whole tick is MS_PER_SECOND.
const HALF_TICK := 500


# The tick nearest to ms at tickrate ticks per second, and a tie rounds up: 350 ms at 30 ticks is
# 10.5 ticks and becomes 11. Integers only, so no float can tip a tie: ms * tickrate / 1000 plus
# half a tick, floored (posmod floors a negative too).
static func from_ms(ms: int, tickrate: int) -> int:
	var scaled := ms * tickrate + HALF_TICK
	@warning_ignore("integer_division")
	return (scaled - posmod(scaled, MS_PER_SECOND)) / MS_PER_SECOND
