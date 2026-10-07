# Guards the two export presets of DEC-0028: the Windows client and the headless Linux server,
# both with the pack inside the binary and without tests, gdUnit4, tools or reports. Godot has no
# runtime API for export presets, so this suite reads export_presets.cfg with ConfigFile: it is a
# configuration file, like project.godot, not source code (DEC-0027). A failure here means the
# presets changed: read DEC-0028 before "fixing" the test.
extends GdUnitTestSuite

const PRESETS_PATH := "res://export_presets.cfg"
const CLIENT := "Cliente Windows"
const SERVER := "Servidor Linux"
const PRESET_NAMES: Array[String] = [CLIENT, SERVER]
const PLATFORMS: Dictionary[String, String] = { CLIENT: "Windows Desktop", SERVER: "Linux" }
# Only the server is a dedicated server: it runs headless, with its visuals stripped.
const DEDICATED_SERVER: Dictionary[String, bool] = { CLIENT: false, SERVER: true }
# Patterns relative to res://, as the export dialog takes them (F-045 §2).
const EXCLUDED: Array[String] = ["test/*", "addons/gdUnit4/*", "tools/*", "reports/*"]
# .gitignore keeps build/ out of the repository.
const BUILD_FOLDER := "build/"
# Each preset is a "preset.N" section, and its options are in "preset.N.options".
const PRESET_PREFIX := "preset."
const OPTIONS_SUFFIX := ".options"


func test_the_client_and_the_server_presets_exist() -> void:
	var presets := _load_presets()
	for preset_name: String in PRESET_NAMES:
		var message := 'export_presets.cfg must have a preset named "%s" (DEC-0028)' % preset_name
		var section := _preset_section(presets, preset_name)
		assert_str(section).override_failure_message(message).is_not_empty()


func test_the_client_exports_for_windows_and_the_server_for_linux() -> void:
	var presets := _load_presets()
	for preset_name: String in PRESET_NAMES:
		var expected: String = PLATFORMS[preset_name]
		var platform: Variant = _value(presets, _preset_section(presets, preset_name), "platform")
		var message := (
			'preset "%s" must export for "%s", found %s (DEC-0028)'
			% [preset_name, expected, var_to_str(platform)]
		)
		assert_bool(_is_exactly(platform, expected)).override_failure_message(message).is_true()


func test_only_the_server_exports_as_a_dedicated_server() -> void:
	var presets := _load_presets()
	for preset_name: String in PRESET_NAMES:
		var expected: bool = DEDICATED_SERVER[preset_name]
		var section := _preset_section(presets, preset_name)
		var dedicated: Variant = _value(presets, section, "dedicated_server")
		var message := (
			'preset "%s" must have dedicated_server=%s, found %s (DEC-0028)'
			% [preset_name, expected, var_to_str(dedicated)]
		)
		assert_bool(_is_exactly(dedicated, expected)).override_failure_message(message).is_true()


func test_both_presets_embed_the_pack_in_the_binary() -> void:
	var presets := _load_presets()
	for preset_name: String in PRESET_NAMES:
		var options := _preset_section(presets, preset_name) + OPTIONS_SUFFIX
		var embed: Variant = _value(presets, options, "binary_format/embed_pck")
		var message := (
			'preset "%s" must have binary_format/embed_pck=true, found %s (DEC-0028)'
			% [preset_name, var_to_str(embed)]
		)
		assert_bool(_is_exactly(embed, true)).override_failure_message(message).is_true()


func test_both_presets_leave_out_tests_gdunit4_tools_and_reports() -> void:
	var presets := _load_presets()
	for preset_name: String in PRESET_NAMES:
		var section := _preset_section(presets, preset_name)
		var filter: Variant = _value(presets, section, "exclude_filter")
		var patterns := _patterns(filter)
		for excluded: String in EXCLUDED:
			var message := (
				'preset "%s" must exclude "%s", but its exclude_filter is %s (DEC-0028)'
				% [preset_name, excluded, var_to_str(filter)]
			)
			assert_bool(patterns.has(excluded)).override_failure_message(message).is_true()


func test_both_presets_export_into_the_ignored_build_folder() -> void:
	var presets := _load_presets()
	for preset_name: String in PRESET_NAMES:
		var path: Variant = _value(presets, _preset_section(presets, preset_name), "export_path")
		var inside_build := path is String and str(path).begins_with(BUILD_FOLDER)
		var message := (
			'preset "%s" must export into %s, which git ignores, found %s (DEC-0028)'
			% [preset_name, BUILD_FOLDER, var_to_str(path)]
		)
		assert_bool(inside_build).override_failure_message(message).is_true()


# export_presets.cfg as Godot reads it. A file that does not load fails the test that reads it.
func _load_presets() -> ConfigFile:
	var presets := ConfigFile.new()
	var error := presets.load(PRESETS_PATH)
	var message := "%s must load, got: %s (DEC-0028)" % [PRESETS_PATH, error_string(error)]
	assert_int(error).override_failure_message(message).is_equal(OK)
	return presets


# The "preset.N" section of the preset with this name, or "" when no preset has it.
func _preset_section(presets: ConfigFile, preset_name: String) -> String:
	for section: String in presets.get_sections():
		var index := section.trim_prefix(PRESET_PREFIX)
		if section.begins_with(PRESET_PREFIX) and index.is_valid_int():
			if _is_exactly(_value(presets, section, "name"), preset_name):
				return section
	return ""


# The value of a key in a section, or null when the section or the key is missing.
func _value(presets: ConfigFile, section: String, key: String) -> Variant:
	if not presets.has_section_key(section, key):
		return null
	return presets.get_value(section, key)


# True when value has the type and the content of expected: the string "true" is not true.
func _is_exactly(value: Variant, expected: Variant) -> bool:
	return typeof(value) == typeof(expected) and value == expected


# The patterns of a comma-separated filter, trimmed as the export dialog takes them; none when
# the filter is missing.
func _patterns(filter: Variant) -> PackedStringArray:
	var patterns := PackedStringArray()
	if filter is String:
		for pattern: String in str(filter).split(","):
			patterns.append(pattern.strip_edges())
	return patterns
