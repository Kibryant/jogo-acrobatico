# The movement numbers of one match, made once at load for one tickrate (visao-geral.md, "A
# configuração nasce na carga"): every time of the MovementData becomes integer ticks (DEC-0004,
# rule 3) and the physics is derived for the size of the tick. It never changes during a match,
# so it stays out of the rollback state; the core reads it and never writes it.
class_name MovementConfig
extends RefCounted

var tickrate: int

# The times of movimento.md in ticks: the nearest tick, ties up (Ticks.from_ms).
var accel_ticks: int
var stop_ticks: int
var rise_ticks: int
var fall_ticks: int
var coyote_ticks: int
var buffer_ticks: int

var run_speed: float # m/s
var max_fall_speed: float # m/s
var floor_max_angle: float # rad: the engine judges the floor with it
var capsule_height: float # m
var capsule_radius: float # m

# The physics derived for the tick, as speed changes per tick (m/s per tick).
# Full input adds this, so rest to run_speed takes exactly accel_ticks.
var ground_accel_per_tick: float
# No input on the floor removes this, so run_speed to rest takes exactly stop_ticks.
var stop_decel_per_tick: float
# Input in the air adds air_control_pct of the ground acceleration.
var air_accel_per_tick: float
# Gravity while the body goes up, and in the rest of the flight.
var rise_gravity_per_tick: float
var fall_gravity_per_tick: float
# The vertical speed of the press tick, in m/s.
var jump_speed: float


# The jump is two parabolas sampled on the ticks: the body is at the apex, jump_height_m up, at
# the end of the rise_ticks-th tick counting the press, and back on the floor fall_ticks later.
# Each tick moves by velocity / tickrate, so the velocity of a tick is its mean over the tick:
# the press tick gets the rise parabola's mean, gravity * (rise_ticks - 1/2) per tick, and
# Movement splits the tick that crosses the apex between the two gravities. With the continuous
# formulas (2h/T and 2h/T²) the apex would stop at 1.09 m at 30 ticks and 1.14 m at 60
# (visao-geral.md, "Física derivada para o tick").
static func create(data: MovementData, tickrate: int) -> MovementConfig:
	var config := MovementConfig.new()
	config.tickrate = tickrate
	config.accel_ticks = Ticks.from_ms(data.accel_time_ms, tickrate)
	config.stop_ticks = Ticks.from_ms(data.stop_time_ms, tickrate)
	config.rise_ticks = Ticks.from_ms(data.jump_rise_ms, tickrate)
	config.fall_ticks = Ticks.from_ms(data.jump_fall_ms, tickrate)
	config.coyote_ticks = Ticks.from_ms(data.coyote_ms, tickrate)
	config.buffer_ticks = Ticks.from_ms(data.buffer_ms, tickrate)
	config.run_speed = data.run_speed_mps
	config.max_fall_speed = data.max_fall_speed_mps
	config.floor_max_angle = deg_to_rad(data.max_slope_deg)
	config.capsule_height = data.capsule_height_m
	config.capsule_radius = data.capsule_radius_m

	for ticks: int in [config.accel_ticks, config.stop_ticks, config.rise_ticks, config.fall_ticks]:
		assert(ticks > 0, "a time the rules divide by became 0 ticks at %d ticks" % tickrate)
	config.ground_accel_per_tick = config.run_speed / config.accel_ticks
	config.stop_decel_per_tick = config.run_speed / config.stop_ticks
	config.air_accel_per_tick = config.ground_accel_per_tick * data.air_control_pct / 100.0

	# A parabola of height h over n ticks has gravity 2h / (n / tickrate)², which is
	# 2h * tickrate / n² m/s per tick.
	var double_height_rate := 2.0 * data.jump_height_m * tickrate
	config.rise_gravity_per_tick = double_height_rate / (config.rise_ticks * config.rise_ticks)
	config.fall_gravity_per_tick = double_height_rate / (config.fall_ticks * config.fall_ticks)
	config.jump_speed = config.rise_gravity_per_tick * (config.rise_ticks - 0.5)
	return config
