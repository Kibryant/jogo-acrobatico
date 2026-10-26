# TASK-10.12: the arena's look, "Dia claro ajustado" (visual-e-audio.md, "A cara da arena"; F-158).
# Criterion 1: the procedural sky as background, the sky's ambient light, the Filmic tonemapping,
# the fog, the colour adjustments, the sun and the colours of the floor, the pieces, the tall
# pieces and the border, each as the doc's table says, with the border casting no shadow; no
# texture, so no new asset (DEC-0029). Criterion 2: the tone of whoever plays is lighter than every
# surface of the arena and the other's darker than every one (F-156 §3).
extends GdUnitTestSuite

const ARENA_SCENE := preload("res://arena/arena.tscn")
const HAIR := 1e-4

## The procedural sky (visual-e-audio.md, "A cara da arena": "Céu" and "Chão do céu").
const SKY_TOP := Color(0.12, 0.32, 0.72)
const SKY_HORIZON := Color(0.62, 0.74, 0.88)
const GROUND_BOTTOM := Color(0.14, 0.14, 0.15)
const GROUND_HORIZON := Color(0.45, 0.47, 0.50)
## Degrees: the sun disc's maximum angle.
const SUN_ANGLE_MAX := 25.0
## The ambient light, from the sky.
const AMBIENT_ENERGY := 0.4
## Filmic, at this exposure.
const EXPOSURE := 0.9
## A light fog, for the border's depth.
const FOG_COLOR := Color(0.66, 0.74, 0.86)
const FOG_DENSITY := 0.0015
const FOG_SKY_AFFECT := 0.15
## The colour adjustments.
const SATURATION := 1.05
const CONTRAST := 1.08
## The sun: 50° high, turned 30°, a little warm, with shadows.
const SUN_ROTATION_DEGREES := Vector3(-50, 30, 0)
const SUN_COLOR := Color(1.0, 0.95, 0.86)
const SUN_ENERGY := 1.5
## The surfaces' colours.
const FLOOR_COLOR := Color(0.18, 0.18, 0.19)
const PIECE_COLOR := Color(0.56, 0.54, 0.50)
const TALL_COLOR := Color(0.32, 0.36, 0.44)
const BORDER_COLOR := Color(0.13, 0.15, 0.19)

## The pieces in the neutral concrete: blocks, platforms, ramp, walls, corridor and landing; the
## dash ruler's strips are checked apart.
const PIECES: Array[String] = [
	"Platform",
	"Ramp",
	"Block1m",
	"Block2m",
	"Block3m",
	"PlataformaVaoA",
	"PlataformaVaoB",
	"ParedeLonga",
	"CorredorOeste",
	"CorredorLeste",
	"PatamarDoCorredor",
]
const TALL: Array[String] = ["TorreA", "TorreB", "Pilar10m"]
const BORDER: Array[String] = ["BordaNorte", "BordaSul", "BordaLeste", "BordaOeste"]
const RULER := "RéguaDoDash"


func test_the_background_is_the_procedural_sky_of_a_clear_day() -> void:
	var environment := _environment(_arena())
	assert_int(environment.background_mode).is_equal(Environment.BG_SKY)
	var sky := environment.sky
	assert_object(sky).is_not_null()
	if sky == null:
		return
	var material := sky.sky_material
	assert_bool(material is ProceduralSkyMaterial).is_true()
	if not material is ProceduralSkyMaterial:
		return
	var procedural := material as ProceduralSkyMaterial
	_assert_color(procedural.sky_top_color, SKY_TOP, "the sky's top")
	_assert_color(procedural.sky_horizon_color, SKY_HORIZON, "the sky's horizon")
	_assert_color(procedural.ground_bottom_color, GROUND_BOTTOM, "the sky ground's bottom")
	_assert_color(procedural.ground_horizon_color, GROUND_HORIZON, "the sky ground's horizon")
	assert_float(procedural.sun_angle_max).is_equal_approx(SUN_ANGLE_MAX, HAIR)


func test_the_ambient_light_comes_from_the_sky_at_0_4() -> void:
	var environment := _environment(_arena())
	assert_int(environment.ambient_light_source).is_equal(Environment.AMBIENT_SOURCE_SKY)
	assert_float(environment.ambient_light_energy).is_equal_approx(AMBIENT_ENERGY, HAIR)


func test_the_tonemapping_is_filmic_at_exposure_0_9() -> void:
	var environment := _environment(_arena())
	assert_int(environment.tonemap_mode).is_equal(Environment.TONE_MAPPER_FILMIC)
	assert_float(environment.tonemap_exposure).is_equal_approx(EXPOSURE, HAIR)


func test_a_light_fog_gives_the_border_depth() -> void:
	var environment := _environment(_arena())
	assert_bool(environment.fog_enabled).is_true()
	_assert_color(environment.fog_light_color, FOG_COLOR, "the fog")
	assert_float(environment.fog_density).is_equal_approx(FOG_DENSITY, HAIR)
	assert_float(environment.fog_sky_affect).is_equal_approx(FOG_SKY_AFFECT, HAIR)


func test_the_colour_adjustments_lift_saturation_and_contrast_a_little() -> void:
	var environment := _environment(_arena())
	assert_bool(environment.adjustment_enabled).is_true()
	assert_float(environment.adjustment_saturation).is_equal_approx(SATURATION, HAIR)
	assert_float(environment.adjustment_contrast).is_equal_approx(CONTRAST, HAIR)


func test_the_sun_stands_50_degrees_high_a_little_warm_and_casts_shadows() -> void:
	var arena := _arena()
	var node := arena.get_node(^"Sun")
	assert_bool(node is DirectionalLight3D).is_true()
	if not node is DirectionalLight3D:
		return
	var sun := node as DirectionalLight3D
	assert_vector(sun.rotation_degrees).is_equal_approx(SUN_ROTATION_DEGREES, Vector3.ONE * HAIR)
	_assert_color(sun.light_color, SUN_COLOR, "the sun")
	assert_float(sun.light_energy).is_equal_approx(SUN_ENERGY, HAIR)
	assert_bool(sun.shadow_enabled).is_true()


func test_the_floor_is_a_neutral_asphalt() -> void:
	var arena := _arena()
	_assert_color(_material_of(arena, "Floor/Mesh").albedo_color, FLOOR_COLOR, "Floor")


func test_the_pieces_and_the_dash_ruler_share_one_neutral_concrete() -> void:
	var arena := _arena()
	var concrete := _material_of(arena, "Block1m/Mesh")
	_assert_color(concrete.albedo_color, PIECE_COLOR, "the pieces")
	for piece: String in PIECES:
		var failure := "%s is not in the pieces' material" % piece
		assert_object(_material_of(arena, piece + "/Mesh")) \
				.override_failure_message(failure) \
				.is_same(concrete)
	var strips := arena.get_node(RULER).get_children()
	assert_int(strips.size()).is_greater(0)
	for strip: Node in strips:
		var failure := "%s is not in the pieces' material" % strip.name
		var path := "%s/%s" % [RULER, strip.name]
		assert_object(_material_of(arena, path)).override_failure_message(failure).is_same(concrete)


func test_the_towers_and_the_pillar_share_one_blue_grey() -> void:
	var arena := _arena()
	var blue_grey := _material_of(arena, "TorreA/Mesh")
	_assert_color(blue_grey.albedo_color, TALL_COLOR, "the tall pieces")
	for piece: String in TALL:
		var failure := "%s is not in the tall pieces' material" % piece
		assert_object(_material_of(arena, piece + "/Mesh")) \
				.override_failure_message(failure) \
				.is_same(blue_grey)


func test_the_border_is_a_dark_frame_that_casts_no_shadow() -> void:
	var arena := _arena()
	var frame := _material_of(arena, "BordaNorte/Mesh")
	_assert_color(frame.albedo_color, BORDER_COLOR, "the border")
	for wall: String in BORDER:
		var failure := "%s is not in the border's material" % wall
		assert_object(_material_of(arena, wall + "/Mesh")) \
				.override_failure_message(failure) \
				.is_same(frame)
		var mesh := _mesh_instance(arena, wall + "/Mesh")
		assert_int(mesh.cast_shadow) \
				.override_failure_message("%s casts a shadow" % wall) \
				.is_equal(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)


# No new asset (DEC-0029): the surfaces are flat colours, with no texture.
func test_no_surface_of_the_arena_wears_a_texture() -> void:
	var arena := _arena()
	for path: String in ["Floor/Mesh", "Block1m/Mesh", "TorreA/Mesh", "BordaNorte/Mesh"]:
		var material := _material_of(arena, path)
		assert_object(material.albedo_texture) \
				.override_failure_message("%s wears a texture" % path) \
				.is_null()


# Criterion 2: the body of whoever plays stands out lighter than every surface, the other's darker.
func test_the_own_tone_is_lighter_and_the_others_darker_than_every_surface() -> void:
	var arena := _arena()
	var surfaces: Dictionary[String, Color] = {
		"the floor": _material_of(arena, "Floor/Mesh").albedo_color,
		"the pieces": _material_of(arena, "Block1m/Mesh").albedo_color,
		"the tall pieces": _material_of(arena, "TorreA/Mesh").albedo_color,
		"the border": _material_of(arena, "BordaNorte/Mesh").albedo_color,
	}
	var own := Fighter.OWN_TONE.get_luminance()
	var other := Fighter.OTHER_TONE.get_luminance()
	for surface: String in surfaces:
		var luminance := surfaces[surface].get_luminance()
		assert_float(own) \
				.override_failure_message("the own tone is not lighter than %s" % surface) \
				.is_greater(luminance)
		assert_float(other) \
				.override_failure_message("the other's tone is not darker than %s" % surface) \
				.is_less(luminance)


func _arena() -> Arena:
	var node := ARENA_SCENE.instantiate()
	assert(node is Arena, "arena.tscn must have an Arena at its root")
	var arena: Arena = auto_free(node)
	add_child(arena)
	return arena


func _environment(arena: Arena) -> Environment:
	var world := arena.get_node(^"World")
	assert(world is WorldEnvironment, "the arena's World is a WorldEnvironment")
	var environment := (world as WorldEnvironment).environment
	assert(environment != null, "the arena's World has an Environment")
	return environment


func _mesh_instance(arena: Arena, path: String) -> MeshInstance3D:
	var node := arena.get_node(path)
	assert(node is MeshInstance3D, "%s is a MeshInstance3D" % path)
	return node as MeshInstance3D


# The material a surface is drawn with: its primitive mesh's, with no override on the instance.
func _material_of(arena: Arena, path: String) -> StandardMaterial3D:
	var instance := _mesh_instance(arena, path)
	assert_object(instance.material_override) \
			.override_failure_message("%s has a material override" % path) \
			.is_null()
	var mesh := instance.mesh
	assert(mesh is PrimitiveMesh, "%s is a primitive mesh" % path)
	var material := (mesh as PrimitiveMesh).material
	assert(material is StandardMaterial3D, "%s has a StandardMaterial3D" % path)
	return material as StandardMaterial3D


func _assert_color(actual: Color, expected: Color, what: String) -> void:
	var off := maxf(
		maxf(absf(actual.r - expected.r), absf(actual.g - expected.g)),
		maxf(absf(actual.b - expected.b), absf(actual.a - expected.a)),
	)
	assert_float(off) \
			.override_failure_message("%s is %s, not %s" % [what, actual, expected]) \
			.is_less_equal(HAIR)
