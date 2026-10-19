# The one bar of stamina for every maneuver (movimento.md, "Princípios" and "Stamina"), kept as a
# value and a stamp, never counted tick by tick (DEC-0022; visao-geral.md, "Carimbo, não
# contagem"): the state holds the bar right after the last spend and the tick of that spend, and
# the bar of any tick is computed from them. A rollback restores the two fields like any other,
# and no tick has to run for the bar to regain.
class_name Stamina
extends RefCounted


# The bar at tick: full while never spent; otherwise the value after the spend, still for
# stamina_wait_ticks, then regaining stamina_regen_per_tick on every tick, capped at the max
# (movimento.md, "Stamina": min(100, value + 0.5 * max(0, tick - stamp - 48)) at 60 ticks).
static func at(state: FighterState, config: MovementConfig, tick: int) -> float:
	if state.stamina_spent_tick == FighterState.NEVER:
		return config.stamina_max
	var regen_ticks := maxi(0, tick - state.stamina_spent_tick - config.stamina_wait_ticks)
	return minf(
		config.stamina_max,
		state.stamina_at_spend + regen_ticks * config.stamina_regen_per_tick,
	)


# Pays cost at tick: the bar as it reads then, minus the cost, stamped now, so the wait starts
# again from this tick. The caller checks first that the bar can pay (movimento.md, "Stamina":
# "Sem stamina suficiente, a manobra não sai"). It writes the state it receives: call it on the
# copy a rule is building, never on the state the rule received.
static func spend(next: FighterState, config: MovementConfig, tick: int, cost: float) -> void:
	next.stamina_at_spend = at(next, config, tick) - cost
	next.stamina_spent_tick = tick
