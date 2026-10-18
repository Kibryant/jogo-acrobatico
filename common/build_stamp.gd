# Which build of the game this is (DEC-0028 §3): the SemVer version of project.godot and the
# commit that the CI stamps in application/config/commit at export, empty in the editor. Two
# peers run the same rules only when both are exactly the same, which the handshake checks
# (rede.md §9); the replay header will carry the same two (DEC-0027).
class_name BuildStamp
extends RefCounted

const VERSION_SETTING := "application/config/version"
const COMMIT_SETTING := "application/config/commit"

var version: String
var commit: String


func _init(build_version := "", build_commit := "") -> void:
	version = build_version
	commit = build_commit


# The stamp of the running game. A build without a stamped commit has an empty one.
static func current() -> BuildStamp:
	return BuildStamp.new(
		str(ProjectSettings.get_setting(VERSION_SETTING, "")),
		str(ProjectSettings.get_setting(COMMIT_SETTING, "")),
	)


# The same build: the same version and the same commit, compared exactly, so the editor's empty
# commit matches only another empty one (TASK-9, choice 10).
func same_as(other: BuildStamp) -> bool:
	return version == other.version and commit == other.commit


func describe() -> String:
	return 'version %s, commit "%s"' % [version, commit]
