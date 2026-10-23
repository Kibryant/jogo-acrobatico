# The replay file, format 1 (TASK-10.3; DEC-0027 §5; testes-e-entrega.md §4). It is event
# sourcing: the input of every tick instead of the video, the way the Redux DevTools rebuild a
# screen from its actions; to watch, the game runs the match again. Text in UTF-8 with "\n" only:
# a header of key=value lines, a "---" line, then one row per tick and fighter.
# - The header says which game recorded it (F-044 §2): format, version and commit (BuildStamp),
#   the rules' fingerprint, engine, platform, ticks per second, netfox's physics and clock
#   settings, the arena and its fingerprint, the seed, the whole movement configuration, one typed
#   field per line, the fighters, the first tick and the declared columns, by name and type.
# - A row holds netfox's absolute tick, the size of the tick loop that ran it, the fighter, the
#   input Sozinho applied on that tick and the check, 8 hex digits of the fingerprint of the state
#   the live game computed after it (StateTrace).
# - A float travels as the 8 bytes of its double in 16 lowercase hex digits: "%.9f" loses bits,
#   and a mouse yaw is never round (F-042 §3). A cell that is not exactly that is refused before
#   it is decoded, never read as 0: decode_double gives 0.0 for bytes it cannot decode.
# The input columns come from TickInput by reflection, so a field a later task adds joins the file
# by itself, and a reader maps the columns by name.
# Reading sorts what it finds into three tiers. An error makes the file unplayable: another
# format, tickrate, arena, physics or clock settings, a column this build does not know, a broken
# line or a malformed cell. A refusal makes it playable only with --force: another version,
# commit, engine, rules or arena fingerprint, or an input column or a configuration field this
# build has and the file lacks. A warning only informs: another platform, a cut last line.
class_name ReplayFile
extends RefCounted

const FORMAT := 1
## The format of a copy written for reading (--readable): decimals instead of hex digits, which
## no player plays.
const READABLE_FORMAT := "1-readable"
const SEPARATOR := "---"
const CELL_SEPARATOR := ","
const CONFIG_PREFIX := "config."
## netfox's pin (DEC-0023), part of the rules' fingerprint: updating netfox changes the rules.
const NETFOX_PIN := "cf5189d"
## The folders whose scripts and scenes move the body, every file below them (the plan of
## TASK-10.3): common/ holds the collision layers, and the scenes set the bodies up (review of
## TASK-10.3).
const RULES_FOLDERS: Array[String] = [
	"res://core",
	"res://fighter",
	"res://match",
	"res://arena",
	"res://common",
]
## The files of RULES_FOLDERS that join the fingerprint; data/ joins with its scripts only.
const RULES_EXTENSIONS: Array[String] = ["gd", "tscn"]
## The folder whose own scripts, and none below it, join the rules' fingerprint.
const RULES_DATA_FOLDER := "res://data"

# The columns every row has, before the input's; check is the optional one, after them.
const TICK := "tick"
const LOOP := "loop"
const FIGHTER := "fighter"
const CHECK := "check"
# The types of a cell.
const INT := "int"
const F64 := "f64"
const BOOL := "bool"
const STR := "str"
const HEX8 := "hex8"

# The header's fields, in the order they are written; the config.<field>:<type> lines follow
# "config".
const KEYS: Array[String] = [
	"format",
	"version",
	"commit",
	"rules",
	"engine",
	"platform",
	"tickrate",
	"physics_ticks_per_second",
	"sync_to_physics",
	"max_ticks_per_frame",
	"input_delay",
	"arena",
	"arena_sha256",
	"seed",
	"config",
	"fighters",
	"first_tick",
	"columns",
]
const INT_KEYS: Array[String] = [
	"tickrate",
	"physics_ticks_per_second",
	"max_ticks_per_frame",
	"input_delay",
	"seed",
	"fighters",
	"first_tick",
]
# Another value of these and the file cannot play here: the same input would run other ticks.
const HARD_KEYS: Array[String] = [
	"tickrate",
	"physics_ticks_per_second",
	"sync_to_physics",
	"max_ticks_per_frame",
	"input_delay",
	"arena",
]
# Another value of these is another build: refused, and played only with --force (F-042 §4).
const SOFT_KEYS: Array[String] = ["version", "commit", "engine", "arena_sha256"]

static var _f64_cell := RegEx.create_from_string("^[0-9a-f]{16}$")
static var _hex8_cell := RegEx.create_from_string("^[0-9a-f]{8}$")
static var _str_cell := RegEx.create_from_string("^([0-9a-f]{2})*$")
static var _sha256 := RegEx.create_from_string("^[0-9a-f]{64}$")
static var _rules_fingerprint := ""
static var _rules_computed := false

## The header's fields by key, as text; the config lines live in config.
var header: Dictionary[String, String] = { }
## The movement configuration of the header, typed, by MovementData field.
var config: Dictionary[String, Variant] = { }
## The columns of the rows, in the order of the file.
var columns: Array[Column] = []
## Every row, in the order of the file: by tick, and within a tick by fighter.
var rows: Array[Row] = []
## The tick loops, in order, as the recording ran them.
var loops: Array[Loop] = []
## How many times netfox's recorded clock jumped between two loops (a stall of over a second).
var jumps := 0
## What makes the file unplayable here, one message each, naming the field.
var errors := PackedStringArray()
## What makes it another build: it plays only with --force.
var refusals := PackedStringArray()
## What only informs.
var warnings := PackedStringArray()


# One column of the rows: its name in the file, its cell type and, for the input's, the indexed
# path of its TickInput field ("move:x" for move.x).
class Column:
	var name: String
	var type: String
	var path: String


	func _init(column_name: String, cell_type: String, indexed_path := "") -> void:
		name = column_name
		type = cell_type
		path = indexed_path


	func declared() -> String:
		return "%s:%s" % [name, type]


# One row: the input one fighter applied on one tick, and the check of the state after it.
class Row:
	var tick := 0
	var loop := 1
	var fighter := 0
	var input := TickInput.new()
	## 8 hex digits of the live state's fingerprint; empty when the file has no check column.
	var check := ""
	## The row's line in the file, for the messages.
	var line := 0


# One tick loop: its first tick and how many ticks it ran.
class Loop:
	var first_tick: int
	var size: int


	func _init(loop_first_tick: int, loop_size: int) -> void:
		first_tick = loop_first_tick
		size = loop_size


# text, when given, is read at once: its messages land in errors, refusals and warnings.
func _init(text := "") -> void:
	if not text.is_empty():
		_read(text)


# The file a text holds.
static func parse(text: String) -> ReplayFile:
	if text.is_empty():
		var empty := ReplayFile.new()
		empty.errors.append("the file is empty")
		return empty
	return ReplayFile.new(text)


# The file at path; an unreadable one has the reason in errors.
static func open(path: String) -> ReplayFile:
	if not FileAccess.file_exists(path):
		var missing := ReplayFile.new()
		missing.errors.append("no file at %s" % path)
		return missing
	return parse(FileAccess.get_file_as_string(path))


# The header of a new file for a match: this build, its arena and movement numbers, the fighters
# and the first tick. The columns are this build's: the fixed ones, the input's and the check.
static func for_match(game_match: Match, fighter_count: int, first_tick: int) -> ReplayFile:
	var replay := ReplayFile.new()
	replay.describe_build(game_match.arena, game_match.movement_data, fighter_count, first_tick)
	return replay


# The header this build would write, with a fresh arena: what a file is judged against.
static func this_build() -> ReplayFile:
	var node := Match.ARENA_SCENE.instantiate()
	var replay := ReplayFile.new()
	var resource: Resource = load(Match.MOVEMENT_DATA_PATH)
	assert(resource is MovementData, "%s must load as a MovementData" % Match.MOVEMENT_DATA_PATH)
	replay.describe_build(node, resource as MovementData, 1, 0)
	node.free()
	return replay


# Compares the file with the build that would play it: another tickrate, arena or physics and
# clock settings is an error; another version, commit, engine, rules or arena fingerprint, a
# refusal; another platform, a warning (testes-e-entrega.md §4). The rules are compared only when
# both fingerprints exist: an exported build leaves its own empty, and its commit says which it is.
func judge(here: ReplayFile) -> void:
	if not errors.is_empty():
		return
	for key: String in HARD_KEYS:
		if header[key] != here.header[key]:
			errors.append(
				"%s is %s in the file and %s in this game: it cannot play here"
				% [key, _shown(header[key]), _shown(here.header[key])],
			)
	for key: String in SOFT_KEYS:
		if header[key] != here.header[key]:
			refusals.append(
				"%s is %s in the file and %s in this game: another build"
				% [key, _shown(header[key]), _shown(here.header[key])],
			)
	var rules: String = header["rules"]
	var own_rules: String = here.header["rules"]
	if not rules.is_empty() and not own_rules.is_empty() and rules != own_rules:
		refusals.append(
			"rules is %s in the file and %s in this game: the scripts that move the body changed"
			% [rules.left(12), own_rules.left(12)],
		)
	if header["platform"] != here.header["platform"]:
		warnings.append(
			"recorded on %s, played on %s: the same build replayed equal on Windows and Linux in"
			% [header["platform"], here.header["platform"]]
			+ " the probe, but sine and cosine were not part of it (F-042 §5)",
		)


# True when the file can play: no error, and no refusal unless forced.
func playable(force: bool) -> bool:
	return errors.is_empty() and (force or refusals.is_empty())


# Every message, one line each, as a player tells them.
func messages(force: bool) -> PackedStringArray:
	var lines := PackedStringArray()
	for message: String in errors:
		lines.append("refused: %s" % message)
	for message: String in refusals:
		var verdict := "played anyway (--force)" if force else "refused, --force plays it"
		lines.append("%s: %s" % [verdict, message])
	for message: String in warnings:
		lines.append("warning: %s" % message)
	return lines


func first_tick() -> int:
	return header["first_tick"].to_int()


func fighter_count() -> int:
	return header["fighters"].to_int()


# The ticks the rows hold: one row per fighter on each.
@warning_ignore("integer_division")
func tick_count() -> int:
	return rows.size() / maxi(1, fighter_count())


# True when the rows carry the live state's check.
func has_check() -> bool:
	for column: Column in columns:
		if column.name == CHECK:
			return true
	return false


# The rows of one fighter, in order.
func rows_of(fighter: int) -> Array[Row]:
	var own: Array[Row] = []
	for row: Row in rows:
		if row.fighter == fighter:
			own.append(row)
	return own


# The movement numbers of the header, so a replay plays with the numbers it was recorded with even
# after the .tres changed. A field the file lacks, which only --force plays, comes from the game's
# own movement_v0.tres.
func movement_data() -> MovementData:
	var data := MovementData.new()
	var fallback: MovementData = null
	var types := movement_types()
	for field: String in types:
		if config.has(field):
			data.set(field, config[field])
			continue
		if fallback == null:
			var resource: Resource = load(Match.MOVEMENT_DATA_PATH)
			assert(resource is MovementData, "%s must load" % Match.MOVEMENT_DATA_PATH)
			fallback = resource as MovementData
		data.set(field, fallback.get(field))
	return data


# The header and the "---" line, each line ended by "\n": what a recorder writes before any row.
func header_text(readable := false) -> String:
	var lines := PackedStringArray()
	for key: String in KEYS:
		var value: String = header[key]
		if key == "format" and readable:
			value = READABLE_FORMAT
		lines.append("%s=%s" % [key, value])
		if key == "config":
			var types := movement_types()
			for field: String in config:
				var type: String = types[field]
				var cell := (
					readable_cell(config[field], type)
					if readable
					else write_cell(config[field], type)
				)
				lines.append("%s%s:%s=%s" % [CONFIG_PREFIX, field, type, cell])
	lines.append(SEPARATOR)
	return "\n".join(lines) + "\n"


# One row as a line, without its "\n".
func row_text(row: Row, readable := false) -> String:
	var cells := PackedStringArray()
	for column: Column in columns:
		var value: Variant = cell_value(row, column)
		cells.append(
			readable_cell(value, column.type) if readable else write_cell(value, column.type)
		)
	return CELL_SEPARATOR.join(cells)


# The whole file; readable writes decimals instead of hex digits, a copy no player plays.
func to_text(readable := false) -> String:
	var lines := PackedStringArray()
	for row: Row in rows:
		lines.append(row_text(row, readable))
	var body := "\n".join(lines) + "\n" if not lines.is_empty() else ""
	return header_text(readable) + body


# The value a row has in a column.
static func cell_value(row: Row, column: Column) -> Variant:
	match column.name:
		TICK:
			return row.tick
		LOOP:
			return row.loop
		FIGHTER:
			return row.fighter
		CHECK:
			return row.check
	return row.input.get_indexed(column.path)


# The columns this build writes: tick, loop and fighter, the input's by reflection over TickInput,
# a Vector2 as its .x and .y, and the check.
static func default_columns() -> Array[Column]:
	var all: Array[Column] = [
		Column.new(TICK, INT),
		Column.new(LOOP, INT),
		Column.new(FIGHTER, INT),
	]
	all.append_array(input_columns())
	all.append(Column.new(CHECK, HEX8))
	return all


# The columns of TickInput's fields, by reflection, in their order.
static func input_columns() -> Array[Column]:
	var found: Array[Column] = []
	for property: Dictionary in TickInput.new().get_property_list():
		var usage: int = property["usage"]
		var field: String = property["name"]
		if not usage & PROPERTY_USAGE_SCRIPT_VARIABLE or field.begins_with("_"):
			continue
		var kind: int = property["type"]
		match kind:
			TYPE_VECTOR2:
				found.append(Column.new(field + ".x", F64, field + ":x"))
				found.append(Column.new(field + ".y", F64, field + ":y"))
			TYPE_VECTOR3:
				for axis: String in ["x", "y", "z"]:
					found.append(Column.new("%s.%s" % [field, axis], F64, "%s:%s" % [field, axis]))
			_:
				var type := cell_type(kind)
				assert(not type.is_empty(), "TickInput.%s has a type no column takes yet" % field)
				found.append(Column.new(field, type, field))
	return found


# The fields of TickInput, by name: the box FighterInput fills.
static func input_fields() -> Array[String]:
	return script_fields(TickInput.new())


# The script variables of an object, by name, without the private ones: the way
# test/fighter/fighter_scene_test.gd finds the fields of a box.
static func script_fields(object: Object) -> Array[String]:
	var fields: Array[String] = []
	for property: Dictionary in object.get_property_list():
		var usage: int = property["usage"]
		var field: String = property["name"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and not field.begins_with("_"):
			fields.append(field)
	return fields


# The exported fields of MovementData with their cell types, in their order.
static func movement_types() -> Dictionary[String, String]:
	var types: Dictionary[String, String] = { }
	for property: Dictionary in MovementData.new().get_property_list():
		var usage: int = property["usage"]
		var stored := usage & PROPERTY_USAGE_STORAGE and usage & PROPERTY_USAGE_SCRIPT_VARIABLE
		if not stored:
			continue
		var kind: int = property["type"]
		var type := cell_type(kind)
		var field: String = property["name"]
		assert(not type.is_empty(), "MovementData.%s has a type no header field takes yet" % field)
		types[field] = type
	return types


# The cell type of a Variant type; empty when none takes it.
static func cell_type(kind: int) -> String:
	match kind:
		TYPE_INT:
			return INT
		TYPE_FLOAT:
			return F64
		TYPE_BOOL:
			return BOOL
		TYPE_STRING, TYPE_STRING_NAME:
			return STR
	return ""


# A value as a cell of type.
static func write_cell(value: Variant, type: String) -> String:
	match type:
		F64:
			var number: float = value
			return f64_cell(number)
		BOOL:
			var flag: bool = value
			return "1" if flag else "0"
		STR:
			var text: String = str(value)
			return text.to_utf8_buffer().hex_encode()
		INT:
			var whole: int = value
			return str(whole)
	return str(value)


# A value as a decimal cell, for reading: the shortest decimal that gives the double back, and
# "-0" for the negative zero.
static func readable_cell(value: Variant, type: String) -> String:
	if type == F64:
		var number: float = value
		return String.num_scientific(number)
	if type == STR:
		return str(value)
	return write_cell(value, type)


# The 16 lowercase hex digits of the 8 bytes of a double.
static func f64_cell(value: float) -> String:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	return bytes.hex_encode()


# The double of a f64 cell; null when the cell is not exactly 16 lowercase hex digits, which is
# checked before any decoding.
static func read_f64(cell: String) -> Variant:
	if _f64_cell.search(cell) == null:
		return null
	return cell.hex_decode().decode_double(0)


# The value of a cell of type; null when the cell is malformed.
static func read_cell(cell: String, type: String) -> Variant:
	match type:
		F64:
			return read_f64(cell)
		INT:
			return cell.to_int() if cell.is_valid_int() else null
		BOOL:
			if cell == "0" or cell == "1":
				return cell == "1"
			return null
		HEX8:
			return cell if _hex8_cell.search(cell) != null else null
		STR:
			if _str_cell.search(cell) == null:
				return null
			return cell.hex_decode().get_string_from_utf8()
	return null


# The sha256 of the scripts that move the body, read from the files, plus netfox's pin: two games
# with the same fingerprint run the same rules. Only a game running from the source has the files
# to read, as Arthur plays; an exported build leaves it empty, and its commit says which build it
# is. Computed once per run.
static func rules_fingerprint() -> String:
	if not OS.has_feature("editor"):
		return ""
	if _rules_computed:
		return _rules_fingerprint
	var paths: Array[String] = []
	for folder: String in RULES_FOLDERS:
		_collect_scripts(folder, true, paths, RULES_EXTENSIONS)
	_collect_scripts(RULES_DATA_FOLDER, false, paths, ["gd"])
	paths.sort()
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	for path: String in paths:
		# Git keeps LF everywhere (.gitattributes); a CR from an editor is no change of rule.
		var text := FileAccess.get_file_as_string(path).replace("\r", "")
		context.update(("%s\n%s\n" % [path, text]).to_utf8_buffer())
	context.update(("netfox %s\n" % NETFOX_PIN).to_utf8_buffer())
	_rules_fingerprint = context.finish().hex_encode()
	_rules_computed = true
	return _rules_fingerprint


# The sha256 of what the arena gives the body to collide with and to start from: every
# CollisionShape3D, with its path, its shape and size and its transform relative to the arena,
# and every spawn point (Marker3D) with its path and transform, the numbers in f64 hex digits.
# Empty when a shape is not a box: the fingerprint learns each new shape by name first.
static func arena_fingerprint(arena: Node) -> String:
	var lines := PackedStringArray()
	for node: Node in _descendants(arena):
		if node is CollisionShape3D:
			var collision := node as CollisionShape3D
			if collision.shape is not BoxShape3D:
				return ""
			var box := collision.shape as BoxShape3D
			lines.append(
				"%s,BoxShape3D,%s,%s"
				% [_path_under(arena, node), _cells(box.size), _transform_cells(arena, collision)],
			)
		elif node is Marker3D:
			var marker := node as Marker3D
			lines.append(
				"%s,Marker3D,%s" % [_path_under(arena, node), _transform_cells(arena, marker)],
			)
	return "\n".join(lines).sha256_text()


# The shapes under the arena the fingerprint does not know yet, by path and class.
static func unknown_arena_shapes(arena: Node) -> PackedStringArray:
	var unknown := PackedStringArray()
	for node: Node in _descendants(arena):
		if node is CollisionShape3D:
			var collision := node as CollisionShape3D
			if collision.shape is not BoxShape3D:
				var kind := "no shape" if collision.shape == null else collision.shape.get_class()
				unknown.append("%s (%s)" % [_path_under(arena, node), kind])
	return unknown


static func _collect_scripts(
	folder: String,
	below: bool,
	paths: Array[String],
	extensions: Array[String],
) -> void:
	var directory := DirAccess.open(folder)
	if directory == null:
		return
	for file: String in directory.get_files():
		if extensions.has(file.get_extension()):
			paths.append(folder.path_join(file))
	if below:
		for child: String in directory.get_directories():
			_collect_scripts(folder.path_join(child), true, paths, extensions)


static func _descendants(node: Node) -> Array[Node]:
	var found: Array[Node] = []
	for child: Node in node.get_children():
		found.append(child)
		found.append_array(_descendants(child))
	return found


static func _path_under(root: Node, node: Node) -> String:
	var names := PackedStringArray()
	var walker := node
	while walker != null and walker != root:
		names.insert(0, String(walker.name))
		walker = walker.get_parent()
	return "/".join(names)


# The transform of node relative to root, without the tree: its own and its parents', up to root.
static func _transform_cells(root: Node, node: Node3D) -> String:
	var transform := node.transform
	var parent := node.get_parent()
	while parent != null and parent != root:
		if parent is Node3D:
			var parent_3d := parent as Node3D
			transform = parent_3d.transform * transform
		parent = parent.get_parent()
	var basis := transform.basis
	return CELL_SEPARATOR.join(
		[_cells(basis.x), _cells(basis.y), _cells(basis.z), _cells(transform.origin)],
	)


static func _cells(vector: Vector3) -> String:
	return CELL_SEPARATOR.join([f64_cell(vector.x), f64_cell(vector.y), f64_cell(vector.z)])


static func _shown(value: String) -> String:
	return '""' if value.is_empty() else value


# Fills the header with this build, arena and movement numbers, the fighters and the first tick,
# and the columns with this build's.
func describe_build(arena: Node, movement: MovementData, fighter_count: int, first: int) -> void:
	var build := BuildStamp.current()
	var engine: Dictionary = Engine.get_version_info()
	header["format"] = str(FORMAT)
	header["version"] = build.version
	header["commit"] = build.commit
	header["rules"] = rules_fingerprint()
	header["engine"] = "%s %s" % [engine["string"], engine["hash"]]
	header["platform"] = OS.get_name()
	header["tickrate"] = str(NetworkTime.tickrate)
	header["physics_ticks_per_second"] = str(Engine.physics_ticks_per_second)
	header["sync_to_physics"] = write_cell(NetworkTime.sync_to_physics, BOOL)
	header["max_ticks_per_frame"] = str(NetworkTime.max_ticks_per_frame)
	header["input_delay"] = str(NetworkRollback.input_delay)
	header["arena"] = Match.ARENA_SCENE.resource_path
	header["arena_sha256"] = arena_fingerprint(arena)
	# Nothing draws lots yet; the seed will be the first random number's (F-044 §2).
	header["seed"] = "0"
	header["config"] = movement.resource_path
	header["fighters"] = str(fighter_count)
	header["first_tick"] = str(first)
	columns = default_columns()
	var declared := PackedStringArray()
	for column: Column in columns:
		declared.append(column.declared())
	header["columns"] = CELL_SEPARATOR.join(declared)
	for field: String in movement_types():
		config[field] = movement.get(field)


func _read(text: String) -> void:
	if text.contains("\r"):
		errors.append(
			"the file has CR line endings (\\r\\n): a replay is written with \\n only, so another"
			+ " program changed it",
		)
		return
	var lines := text.split("\n")
	# A whole file ends with "\n", so its last piece is empty; anything else is a line the game
	# had not finished writing when it closed.
	var cut := lines[lines.size() - 1]
	lines.resize(lines.size() - 1)
	var separator := lines.find(SEPARATOR)
	if separator == -1:
		errors.append("no %s line ends the header: the file is cut before its rows" % SEPARATOR)
		return
	if not cut.is_empty():
		warnings.append(
			"the last line is cut, the game closed while writing it: discarded (%s)" % cut.left(24),
		)
	if _read_header(lines.slice(0, separator)):
		_read_rows(lines.slice(separator + 1), separator + 2)


func _read_header(lines: PackedStringArray) -> bool:
	for index: int in lines.size():
		var parts := lines[index].split("=", true, 1)
		if parts.size() != 2:
			errors.append("header line %d is no key=value: %s" % [index + 1, lines[index]])
			continue
		var key := parts[0]
		if key.begins_with(CONFIG_PREFIX):
			_read_config_line(key, parts[1])
		elif not KEYS.has(key):
			errors.append("header field %s is unknown to format %d" % [key, FORMAT])
		elif header.has(key):
			errors.append("header field %s is given twice" % key)
		else:
			header[key] = parts[1]
	# The format first: another format may write everything else another way.
	var format: String = header.get("format", "")
	if format != str(FORMAT):
		errors.clear()
		var found := "missing" if format.is_empty() else "%s" % format
		errors.append("format is %s: this player reads format %d" % [found, FORMAT])
		return false
	for key: String in KEYS:
		if not header.has(key):
			errors.append("header field %s is missing" % key)
	if not errors.is_empty():
		return false
	_check_header_values()
	_read_columns(header["columns"])
	for field: String in movement_types():
		if not config.has(field):
			refusals.append(
				"config field %s is missing from the file: --force takes it from %s"
				% [field, Match.MOVEMENT_DATA_PATH],
			)
	if errors.is_empty() and refusals.is_empty():
		var invalid := movement_data().validate()
		if not invalid.is_empty():
			errors.append("config: %s" % "; ".join(invalid))
	return errors.is_empty()


func _check_header_values() -> void:
	for key: String in INT_KEYS:
		if not header[key].is_valid_int():
			errors.append("header field %s is %s, not a whole number" % [key, header[key]])
	if read_cell(header["sync_to_physics"], BOOL) == null:
		errors.append("header field sync_to_physics is %s, not 0 or 1" % header["sync_to_physics"])
	if errors.is_empty() and fighter_count() < 1:
		errors.append(
			"header field fighters is %s: a replay plays at least one" % header["fighters"]
		)
	var rules: String = header["rules"]
	if not rules.is_empty() and _sha256.search(rules) == null:
		errors.append("header field rules is %s, not empty or 64 hex digits" % rules)
	if _sha256.search(header["arena_sha256"]) == null:
		errors.append(
			"header field arena_sha256 is %s, not 64 hex digits: the arena had a shape its"
			% _shown(header["arena_sha256"])
			+ " fingerprint does not know yet",
		)


func _read_config_line(key: String, cell: String) -> void:
	var declared := key.trim_prefix(CONFIG_PREFIX).split(":")
	if declared.size() != 2:
		errors.append("header field %s is no %s<field>:<type>" % [key, CONFIG_PREFIX])
		return
	var field := declared[0]
	var type := declared[1]
	var types := movement_types()
	if config.has(field):
		errors.append("config field %s is given twice" % field)
	elif not types.has(field):
		refusals.append(
			"config field %s is unknown to this build's MovementData: --force plays without it"
			% field,
		)
	elif types[field] != type:
		errors.append(
			"config field %s is %s in the file and %s in this build" % [field, type, types[field]],
		)
	else:
		var value: Variant = read_cell(cell, type)
		if value == null:
			errors.append("config field %s: %s is not a %s cell" % [field, cell, type])
		else:
			config[field] = value


func _read_columns(declared: String) -> void:
	var known: Dictionary[String, Column] = { }
	for column: Column in default_columns():
		known[column.name] = column
	var seen: Array[String] = []
	for item: String in declared.split(CELL_SEPARATOR):
		var parts := item.split(":")
		if parts.size() != 2:
			errors.append("columns: %s is no name:type" % item)
			continue
		var column_name := parts[0]
		if seen.has(column_name):
			errors.append("column %s is declared twice" % column_name)
			continue
		seen.append(column_name)
		if not known.has(column_name):
			errors.append(
				"column %s is unknown to this build: no fixed column and no field of TickInput"
				% column_name,
			)
		elif known[column_name].type != parts[1]:
			errors.append(
				"column %s is %s in the file and %s in this build"
				% [column_name, parts[1], known[column_name].type],
			)
		else:
			columns.append(known[column_name])
	for fixed: String in [TICK, LOOP, FIGHTER]:
		if not seen.has(fixed):
			errors.append("column %s is missing: every row needs it" % fixed)
	var neutral := TickInput.new()
	for column: Column in input_columns():
		if not seen.has(column.name):
			refusals.append(
				"column %s is missing: --force plays it with TickInput's default, %s"
				% [column.name, neutral.get_indexed(column.path)],
			)


func _read_rows(lines: PackedStringArray, first_line: int) -> void:
	for index: int in lines.size():
		var number := first_line + index
		var cells := lines[index].split(CELL_SEPARATOR)
		if cells.size() != columns.size():
			errors.append(
				"line %d is broken: %d cells where the header declares %d columns"
				% [number, cells.size(), columns.size()],
			)
			return
		var row := Row.new()
		row.line = number
		for at: int in columns.size():
			var column := columns[at]
			var value: Variant = read_cell(cells[at], column.type)
			if value == null:
				errors.append(
					'line %d, column %s: "%s" is not a %s cell'
					% [number, column.name, cells[at], column.type],
				)
				return
			match column.name:
				TICK:
					row.tick = value
				LOOP:
					row.loop = value
				FIGHTER:
					row.fighter = value
				CHECK:
					row.check = value
				_:
					row.input.set_indexed(column.path, value)
		rows.append(row)
	_group_ticks()


# Every tick has one row per fighter, in order, and the ticks only go forward; the ticks group into
# the loops the recording ran, each loop's ticks one after the other. The file may end in the
# middle of a tick or of a loop, cut by an abrupt close: that tail is dropped with a warning.
func _group_ticks() -> void:
	var fighters := fighter_count()
	var ticks: Array[int] = []
	var loop_of: Dictionary[int, int] = { }
	var index := 0
	while index < rows.size():
		var first := rows[index]
		if index + fighters > rows.size():
			warnings.append("tick %d is cut: not every fighter has its row; dropped" % first.tick)
			rows.resize(index)
			break
		for fighter: int in fighters:
			var row := rows[index + fighter]
			if row.tick != first.tick or row.fighter != fighter or row.loop != first.loop:
				errors.append(
					"line %d: fighter %d of tick %d in a loop of %d was expected, not fighter %d"
					% [row.line, fighter, first.tick, first.loop, row.fighter]
					+ " of tick %d in a loop of %d" % [row.tick, row.loop],
				)
				return
		var previous := ticks[ticks.size() - 1] if not ticks.is_empty() else first.tick - 1
		if first.tick <= previous:
			errors.append(
				"line %d: tick %d comes after tick %d, and ticks only go forward"
				% [first.line, first.tick, previous],
			)
			return
		ticks.append(first.tick)
		loop_of[first.tick] = first.loop
		index += fighters
	_group_loops(ticks, loop_of)
	if errors.is_empty() and not rows.is_empty() and rows[0].tick != first_tick():
		errors.append(
			"header field first_tick is %d, but the first row is tick %d"
			% [first_tick(), rows[0].tick],
		)


func _group_loops(ticks: Array[int], loop_of: Dictionary[int, int]) -> void:
	var most: int = header["max_ticks_per_frame"].to_int()
	var at := 0
	while at < ticks.size():
		var first := ticks[at]
		var size := loop_of[first]
		if size < 1 or size > most:
			errors.append(
				"tick %d ran in a loop of %d ticks, and netfox runs 1 to %d" % [first, size, most],
			)
			return
		if at + size > ticks.size():
			warnings.append(
				"the last loop, from tick %d, is cut: %d of its %d ticks; dropped"
				% [first, ticks.size() - at, size],
			)
			rows.resize(at * fighter_count())
			return
		for step: int in range(1, size):
			var tick := ticks[at + step]
			if tick != first + step or loop_of[tick] != size:
				errors.append(
					"tick %d is no tick %d of the loop of %d ticks from tick %d"
					% [tick, step + 1, size, first],
				)
				return
		if not loops.is_empty():
			var last := loops[loops.size() - 1]
			if first != last.first_tick + last.size:
				jumps += 1
		loops.append(Loop.new(first, size))
		at += size
