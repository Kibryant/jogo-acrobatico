# The headless replay player on the command line (TASK-10.3, criteria 4, 6 and 7): tools/replay.sh
# runs it as the scene of a headless game, as tools/record_reference.sh does: a scene loads after
# netfox's autoloads, which a -s script cannot name (tools/check_scripts.gd). After "--":
#   FILE [--force] [--readable=OUT] [--trace=OUT] [--against=TRACE]
#   FILE --summary [--force]
#   --sample=OUT
# FILE is judged against this build (ReplayFile) and, when it can play, played through
# tools/replay_run.gd; --readable writes a copy in decimals, --trace the state trace, and
# --against compares the trace with another one, a --watch's, and says where they first differ
# and the size of the loop there on both sides. --summary prints, in Portuguese, the summary of
# the session instead (tools/replay_summary.gd; TASK-14), for tools/replay_summary.sh. --sample
# records the scripted session of the gate's tests (test/replay/replay_session.gd) to OUT, the
# recording the measurements play.
# Every line it prints for the shell script starts with "replay: ". It exits with 0 once it
# played or recorded, 1 when it refuses the file or cannot write, and 2 on a wrong argument.
extends Node

const ReplayRun := preload("res://tools/replay_run.gd")
const ReplaySummary := preload("res://tools/replay_summary.gd")
const ReplaySession := preload("res://test/replay/replay_session.gd")

const EXIT_REFUSED := 1
const EXIT_USAGE := 2
const USAGE := (
	"usage, after --: FILE [--force] [--readable=OUT] [--trace=OUT] [--against=TRACE],"
	+ " FILE --summary [--force], or --sample=OUT"
)

var _file := ""
var _options: Dictionary[String, String] = { }


func _ready() -> void:
	var problem := _read_arguments(OS.get_cmdline_user_args())
	if not problem.is_empty():
		_say(problem)
		_say(USAGE)
		get_tree().quit(EXIT_USAGE)
		return
	if _options.has("sample"):
		await _record_sample(_options["sample"])
		return
	if _options.has("summary"):
		await _summarize()
		return
	await _play()


func _read_arguments(arguments: PackedStringArray) -> String:
	const FLAGS: Array[String] = ["force", "summary"]
	const VALUED: Array[String] = ["readable", "trace", "against", "sample"]
	for argument: String in arguments:
		if not argument.begins_with("--"):
			if not _file.is_empty():
				return "one replay file at a time: %s and %s" % [_file, argument]
			_file = argument
			continue
		var parts := argument.trim_prefix("--").split("=", true, 1)
		if FLAGS.has(parts[0]) and parts.size() == 1:
			_options[parts[0]] = ""
		elif VALUED.has(parts[0]) and parts.size() == 2 and not parts[1].is_empty():
			_options[parts[0]] = parts[1]
		else:
			return "unknown argument: %s" % argument
	if _options.has("sample"):
		if not _file.is_empty() or _options.size() > 1:
			return "--sample records the sample session alone"
		return ""
	if _file.is_empty():
		return "which replay file?"
	if _options.has("summary"):
		for option: String in _options:
			if not FLAGS.has(option):
				return "--summary goes alone, or with --force"
	return ""


func _play() -> void:
	var replay := ReplayFile.open(_file)
	if replay.errors.is_empty():
		replay.judge(ReplayFile.this_build())
	var force := _options.has("force")
	_say(
		"%s: %d ticks in %d loops (%d jumps) from tick %s, version %s, commit %s"
		% [
			_file,
			replay.tick_count() if replay.errors.is_empty() else 0,
			replay.loops.size(),
			replay.jumps,
			replay.header.get("first_tick", "?"),
			replay.header.get("version", "?"),
			replay.header.get("commit", "?"),
		]
	)
	for message: String in replay.messages(force):
		_say(message)
	if not replay.playable(force):
		get_tree().quit(EXIT_REFUSED)
		return
	if _options.has("readable") and not _write(_options["readable"], replay.to_text(true)):
		return
	var result := await ReplayRun.new().play(self, replay, replay.movement_data())
	_say(result.describe())
	if result.first_apart >= 0:
		_say(
			"the state left the live game's on tick %d (tick %d of netfox's clock), fighter %d"
			% [
				result.first_apart,
				result.first_apart + replay.first_tick(),
				result.first_apart_fighter,
			]
		)
	if _options.has("trace") and not _write(_options["trace"], result.trace.text()):
		return
	if _options.has("against"):
		_compare(replay, result.trace, _options["against"])
	get_tree().quit(0)


# The summary of the session (TASK-14; testes-e-entrega.md §4, "O resumo"), every line in
# Portuguese for Arthur. A file the player refuses is refused here too, with a line that says
# whether it is no valid replay or another build that plays only with --force, then the reader's
# messages as the player says them. A file that plays is played as above, and the summary counts
# with the numbers the run played, the header's, made at the header's tickrate.
func _summarize() -> void:
	var replay := ReplayFile.open(_file)
	if replay.errors.is_empty():
		replay.judge(ReplayFile.this_build())
	var force := _options.has("force")
	var file_name := _file.get_file()
	if not replay.playable(force):
		if not replay.errors.is_empty():
			_say("%s não é um replay válido. O leitor diz:" % file_name)
		else:
			_say("%s é de outra build e só toca com --force. O leitor diz:" % file_name)
		for message: String in replay.messages(force):
			_say(message)
		get_tree().quit(EXIT_REFUSED)
		return
	var result := await ReplayRun.new().play(self, replay, replay.movement_data())
	var tickrate := replay.header["tickrate"].to_int()
	var summary := ReplaySummary.new(
		MovementConfig.create(result.movement_data, tickrate),
		CombatConfig.create(result.combat_data, tickrate),
	)
	summary.feed(replay, result.trace)
	summary.finish()
	# The editor's build stamps no commit (BuildStamp): a session Arthur plays from the source has
	# an empty one.
	var commit: String = replay.header.get("commit", "")
	var stamp := ("commit %s" % commit) if not commit.is_empty() else "sem commit (do código-fonte)"
	var title := "Resumo de %s: versão %s, %s" % [
		file_name,
		replay.header.get("version", "?"),
		stamp,
	]
	if force:
		title += "; tocado com --force"
	_say(title)
	var messages := replay.messages(force)
	if not messages.is_empty():
		_say("O leitor avisou:")
		for message: String in messages:
			_say(message)
	_say(_verdict(result, tickrate))
	for line: String in summary.lines():
		_say(line)
	get_tree().quit(0)


# Whether the state played again as the live game computed it, by the file's check column.
static func _verdict(result: ReplayRun.Result, tickrate: int) -> String:
	if not result.checked:
		return (
			"O arquivo não tem a coluna check: não dá para saber se o estado tocou igual ao do jogo"
			+ " ao vivo."
		)
	if result.first_apart < 0:
		return "O estado tocou igual ao do jogo ao vivo em todos os ticks."
	return (
		(
			"O estado se separou do jogo ao vivo no tick %s (%s), no lutador %d: o que vem depois"
			+ " dele não é a sessão."
		)
		% [
			ReplaySummary.whole(result.first_apart),
			ReplaySummary.duration(result.first_apart, tickrate),
			result.first_apart_fighter,
		]
	)


# The trace against another one, a --watch's: equal, or where they first differ, with the size of
# the loop that tick ran in here, as recorded, and there, from the other trace's .loops file.
func _compare(replay: ReplayFile, trace: StateTrace, other_path: String) -> void:
	if not FileAccess.file_exists(other_path):
		_say("against %s: no such trace" % other_path)
		return
	var other := FileAccess.get_file_as_string(other_path)
	var difference := StateTrace.first_difference(trace.text(), other)
	if difference == null:
		_say("against %s: equal byte for byte, sha256 %s" % [other_path, other.sha256_text()])
		return
	_say("against %s: %s" % [other_path, difference.describe()])
	if difference.tick < 0:
		return
	var recorded := -1
	for row: ReplayFile.Row in replay.rows:
		if row.tick - replay.first_tick() == difference.tick:
			recorded = row.loop
			break
	var theirs := _loop_of(other_path + ".loops", difference.tick)
	var same := "the same size" if theirs == recorded else "another size"
	_say(
		"the loop of tick %d: %d ticks in the recording and here, %s there: %s"
		% [difference.tick, recorded, "?" if theirs < 0 else str(theirs), same]
	)


func _record_sample(path: String) -> void:
	var session := await ReplaySession.new().record(self, path)
	_say(
		"sample: %d ticks in %d loops, %d double jumps, recorded in %.0f ms to %s"
		% [
			session.ticks,
			session.loops,
			session.double_jumps,
			session.record_usec / 1000.0,
			ProjectSettings.globalize_path(path),
		]
	)
	_say("sample: live trace sha256 %s" % session.trace.sha256())
	get_tree().quit(0)


# The size of the loop of tick in a .loops file; -1 when it says none.
static func _loop_of(path: String, tick: int) -> int:
	if not FileAccess.file_exists(path):
		return -1
	for line: String in FileAccess.get_file_as_string(path).split("\n", false):
		var cells := line.split(",")
		if cells.size() == 2 and cells[0].to_int() == tick:
			return cells[1].to_int()
	return -1


func _write(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_say("cannot write %s: %s" % [path, error_string(FileAccess.get_open_error())])
		get_tree().quit(EXIT_REFUSED)
		return false
	file.store_string(text)
	file.close()
	_say("wrote %s" % ProjectSettings.globalize_path(path))
	return true


static func _say(line: String) -> void:
	print("replay: %s" % line)
