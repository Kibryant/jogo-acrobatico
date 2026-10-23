# Drives netfox's tick loop by hand, the way netfox's own suite does (netfox-sonda,
# test/network-mocks.gd): with no wall clock, a test runs any number of ticks at once, and the
# same ticks every run. NetworkTime itself is never started, so its _process never runs a loop of
# its own in between. netfox has no public call for one tick, so this helper calls its private
# ones; DEC-0027 §3 allows that for netfox's tick, and the linter is told so line by line.
#
# Run the ticks inside a physics frame, after `await get_tree().physics_frame`. There netfox's
# physics_factor is the physics rate over the tickrate and move_and_slide() moves by the fixed
# physics step, so a tick moves exactly one tick. Inside a process frame the factor would use the
# last frame's delta and move_and_slide() this frame's, and a test's frames vary too much for that.
# The game runs its ticks in the physics step too (DEC-0040).
extends RefCounted


# One tick loop of `ticks` ticks, as NetworkTime._loop runs it: before_tick_loop gathers the
# input, every tick is emitted and its input recorded, and the rollback loop simulates.
static func run_loop(ticks := 1) -> void:
	assert(Engine.is_in_physics_frame(), "run the ticks after await get_tree().physics_frame")
	# gdlint-ignore-next-line private-access
	NetworkTime._before_tick_loop()
	for _tick: int in ticks:
		var tick := NetworkTime.tick
		NetworkTime.before_tick.emit(NetworkTime.ticktime, tick)
		NetworkTime.on_tick.emit(NetworkTime.ticktime, tick)
		NetworkTime.after_tick.emit(NetworkTime.ticktime, tick)
		# gdlint-ignore-next-line private-access
		NetworkRollback._after_tick(tick)
		# gdlint-ignore-next-line private-access
		NetworkTime._tick += 1
	# gdlint-ignore-next-line private-access
	NetworkTime._after_tick_loop()


static func run_loops(loops: int, ticks_per_loop := 1) -> void:
	for _loop: int in loops:
		run_loop(ticks_per_loop)


# Puts netfox's clock on tick between two loops, through the same private field run_loop()
# advances (TASK-10.3): a replay plays from its first recorded tick, and a jump of the recorded
# clock, a stall of over a second (NetworkTime._loop), plays as the same jump. Only the tests and
# the tools use it; the game never writes netfox's clock.
static func set_tick(tick: int) -> void:
	# gdlint-ignore-next-line private-access
	NetworkTime._tick = tick


# Clears netfox's clock and every history between tests: NetworkTime.stop() resets the tick and
# the rollback, history, synchronization and simulation servers.
static func reset() -> void:
	NetworkTime.stop()
