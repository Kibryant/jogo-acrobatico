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
# After a spend, the bar regains nothing for this many ticks (movimento.md, "Stamina").
var stamina_wait_ticks: int

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
# The vertical speed of the double jump's press tick, in m/s, under the same rise gravity.
var double_jump_speed: float

# The stamina (movimento.md, "Pulo e ar" and "Stamina"), in points.
var double_jump_cost: float
var stamina_max: float
# Points regained on each tick after the wait.
var stamina_regen_per_tick: float

# The dash (movimento.md, "Dash"). It lasts dash_ticks, the press tick first, and the next one
# may start dash_cooldown_ticks after its end.
var dash_ticks: int
var dash_cooldown_ticks: int
# m/s: the distance over the dash's ticks, so the rounding of the duration never moves the
# distance.
var dash_speed: float
# m/s: the horizontal speed of the tick right after the dash, in the dash's direction.
var dash_exit_speed: float
# Stamina points, paid on the press tick.
var dash_cost: float

# The wall run (movimento.md, "Corrida na parede"). A face is a wall while |normal.y| is at most
# wall_max_normal_y, the cosine of the least incline; the same collider is the same wall while its
# normal is within wall_same_face_cos of the last one, as a dot product.
var wall_max_normal_y: float
var wall_same_face_cos: float
# m/s: the least speed along the wall that enters, the run's speed and its ceiling. A run slower
# than the entry speed ends: an obstacle stopped it.
var wall_entry_speed: float
var wall_run_speed: float
var wall_max_speed: float
# The run lasts wall_run_max_ticks from the entry; the height holds for wall_hold_ticks of them,
# the entry tick first, and the slide fills the rest.
var wall_run_max_ticks: int
var wall_hold_ticks: int
# The slide's vertical grows by this every tick, in m/s per tick: a share of the rise gravity.
var wall_slide_gravity_per_tick: float
# The vertical speed of the wall jump's press tick, in m/s, under the jump's rise gravity, and its
# push out of the wall, in m/s along the wall's normal.
var wall_jump_speed: float
var wall_jump_push: float
# m above the feet: the adapter's head ray, which must find the wall's face for the wall to cover
# the body (movimento.md, "Corrida na parede": "A parede cobre o corpo"). The core never reads it.
var wall_head_height: float
# The lean of the capsule's mesh away from the wall, in rad, and the time it takes to come in or
# go out, in seconds: it is eased per displayed frame, never per tick, and never in the state
# (movimento.md, "Corrida na parede": "O que se vê na parede"). The core never reads them.
var wall_lean: float
var wall_lean_s: float


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
	config.dash_ticks = Ticks.from_ms(data.dash_ms, tickrate)
	config.dash_cooldown_ticks = Ticks.from_ms(data.dash_cooldown_ms, tickrate)
	config.run_speed = data.run_speed_mps
	config.max_fall_speed = data.max_fall_speed_mps
	config.floor_max_angle = deg_to_rad(data.max_slope_deg)
	config.capsule_height = data.capsule_height_m
	config.capsule_radius = data.capsule_radius_m

	# The data check, MovementData.validate(), rejects a time that rounds to 0 ticks at 30 or at 60
	# ticks, and the gate runs it over every movement .tres under data/, before any build. This
	# assert, gone from a release build, only guards a debug run: data that skipped the check, or
	# another tickrate.
	var dividing: Array[int] = [
		config.accel_ticks,
		config.stop_ticks,
		config.rise_ticks,
		config.fall_ticks,
		config.dash_ticks,
	]
	for ticks: int in dividing:
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

	# The double jump rises under the same gravity g per tick (movimento.md, "No tick"). Leaving
	# at v, the body is (n * v - g * n * (n - 1) / 2) / tickrate up after n ticks, which over a
	# continuous n peaks at n = v / g + 1/2 with (v + g / 2)² / (2 * g * tickrate). Setting that
	# peak to h gives v = sqrt(2 * g * tickrate * h) - g / 2: the jump's own g * (rise_ticks - 1/2)
	# solves the same equation, with the peak on a whole tick. The double jump's peak falls between
	# ticks, so its apex comes a hair low: 0.9999 m on the 19th tick at 60 and 0.99998 m on the
	# 10th at 30. The smooth sqrt(2 * g * tickrate * h), 6.26 m/s at 60, would overshoot by 5 cm.
	var rise := config.rise_gravity_per_tick
	config.double_jump_speed = sqrt(2.0 * rise * tickrate * data.double_jump_height_m) - rise / 2.0

	config.stamina_wait_ticks = Ticks.from_ms(data.stamina_wait_ms, tickrate)
	config.double_jump_cost = data.double_jump_cost
	config.stamina_max = data.stamina_max
	config.stamina_regen_per_tick = data.stamina_regen_per_s / tickrate

	# The dash covers its distance in its whole ticks (movimento.md, "Dash": "Deriva a velocidade:
	# 20 m/s"): 4 m over 12 ticks at 60 is 20 m/s, and over 6 ticks at 30 too. A duration that
	# rounds to another tick count changes the speed, never the distance (DEC-0004, rule 3).
	config.dash_speed = data.dash_distance_m * tickrate / config.dash_ticks
	config.dash_exit_speed = data.dash_exit_speed_mps
	config.dash_cost = data.dash_cost

	# The wall run (movimento.md, "Corrida na parede"): the two angles become the numbers a rule
	# compares a normal with, and the two times become ticks like every other.
	config.wall_max_normal_y = cos(deg_to_rad(data.wall_min_incline_deg))
	config.wall_same_face_cos = cos(deg_to_rad(data.wall_same_face_deg))
	config.wall_entry_speed = data.wall_entry_speed_mps
	config.wall_run_speed = data.wall_run_speed_mps
	config.wall_max_speed = data.wall_max_speed_mps
	config.wall_run_max_ticks = Ticks.from_ms(data.wall_run_max_ms, tickrate)
	config.wall_hold_ticks = Ticks.from_ms(data.wall_hold_ms, tickrate)
	config.wall_slide_gravity_per_tick = rise * data.wall_slide_gravity_pct / 100.0
	# The double jump's formula, for the wall jump's own height: at the jump's 1,2 m it is the
	# jump's own exit speed, the same parabola on the ticks (movimento.md, "Pulo da parede").
	config.wall_jump_speed = sqrt(2.0 * rise * tickrate * data.wall_jump_height_m) - rise / 2.0
	config.wall_jump_push = data.wall_jump_push_mps
	# The head ray hangs from the capsule's top: 1,8 - 0,1 = 1,7 m above the feet.
	config.wall_head_height = data.capsule_height_m - data.wall_head_below_top_m
	config.wall_lean = deg_to_rad(data.wall_lean_deg)
	config.wall_lean_s = data.wall_lean_ms / 1000.0
	return config
