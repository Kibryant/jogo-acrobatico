# Criterion 10 of TASK-9 and DEC-0028 §3: two peers play together only on the same build, the
# same version and the same commit, compared exactly; the editor's empty commit matches only
# another empty one (TASK-9, choice 10).
extends GdUnitTestSuite

const COMMIT := "4f1c2e9"


# Two editors, or the gate, run with no stamped commit and play together.
func test_the_same_version_and_commit_are_the_same_build() -> void:
	assert_bool(BuildStamp.new("0.1.0", COMMIT).same_as(BuildStamp.new("0.1.0", COMMIT))).is_true()
	assert_bool(BuildStamp.new("0.0.0", "").same_as(BuildStamp.new("0.0.0", ""))).is_true()


# The editor against a stamped build fails either way round.
func test_another_version_or_commit_is_another_build() -> void:
	var build := BuildStamp.new("0.1.0", COMMIT)
	var others: Array[BuildStamp] = [
		BuildStamp.new("0.1.1", COMMIT),
		BuildStamp.new("0.2.0", COMMIT),
		BuildStamp.new("0.1.0 ", COMMIT),
		BuildStamp.new("0.1.0", "4f1c2ea"),
		BuildStamp.new("0.1.0", COMMIT.to_upper()),
		BuildStamp.new("0.1.0", COMMIT.left(4)),
		BuildStamp.new("0.1.0", ""),
	]
	for other: BuildStamp in others:
		var message := "%s must differ from %s" % [other.describe(), build.describe()]
		assert_bool(build.same_as(other)).override_failure_message(message).is_false()
		assert_bool(other.same_as(build)).override_failure_message(message).is_false()


# The running game reads project.godot, where the CI stamps the commit at export; without the
# stamp, the commit is empty.
func test_the_running_build_reads_its_version_and_commit_from_the_project() -> void:
	var build := BuildStamp.current()
	var version := str(ProjectSettings.get_setting("application/config/version"))
	var commit := str(ProjectSettings.get_setting("application/config/commit", ""))
	assert_str(build.version).is_equal(version)
	assert_str(build.commit).is_equal(commit)
