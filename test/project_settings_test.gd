# Guards the project settings decided in DEC-0002, DEC-0005 and DEC-0022.
# A failure here means project.godot changed: read the DEC before "fixing" the test.
extends GdUnitTestSuite

const UNSAFE_ACCESS_WARNINGS: Array[String] = [
	"unsafe_property_access",
	"unsafe_method_access",
	"unsafe_cast",
	"unsafe_call_argument",
]


func test_physics_engine_is_jolt() -> void:
	var physics_engine: String = ProjectSettings.get_setting("physics/3d/physics_engine")
	assert_str(physics_engine).is_equal("Jolt Physics")


func test_renderer_is_compatibility() -> void:
	var method: String = ProjectSettings.get_setting("rendering/renderer/rendering_method")
	assert_str(method).is_equal("gl_compatibility")


func test_untyped_declaration_is_an_error() -> void:
	var level: int = ProjectSettings.get_setting("debug/gdscript/warnings/untyped_declaration")
	assert_int(level).is_equal(2)


func test_unsafe_access_is_an_error() -> void:
	for warning: String in UNSAFE_ACCESS_WARNINGS:
		var level: int = ProjectSettings.get_setting("debug/gdscript/warnings/" + warning)
		assert_int(level).override_failure_message("%s must be an error (2)" % warning).is_equal(2)


func test_physics_jitter_fix_is_off_for_netcode() -> void:
	var jitter_fix: float = ProjectSettings.get_setting("physics/common/physics_jitter_fix")
	assert_float(jitter_fix).is_equal(0.0)
