# Criteria 9 and 10 of TASK-9 (DEC-0028 §3; rede.md §9): the handshake's messages and verdict as
# pure functions. The client says its version and commit; the server accepts the same build while
# the room has a seat, asks another build to update and tells a full room. A stranger's bytes are
# read as no hello at all, without an engine error.
extends GdUnitTestSuite

const ROOM_FREE := false
const ROOM_FULL := true

var _server := BuildStamp.new("0.1.0", "4f1c2e9")


func test_a_hello_carries_the_version_and_the_commit() -> void:
	for build: BuildStamp in [_server, BuildStamp.new("0.0.0", "")]:
		var said := Handshake.read_hello(Handshake.hello(build))
		assert_object(said).is_not_null()
		assert_str(said.version).is_equal(build.version)
		assert_str(said.commit).is_equal(build.commit)


func test_bytes_that_are_not_a_hello_read_as_none() -> void:
	var line_feed := 10
	var strangers: Array[PackedByteArray] = [
		PackedByteArray(),
		"0.1.0".to_ascii_buffer(),
		"0.1.0\n4f1c2e9\nmore".to_ascii_buffer(),
		PackedByteArray([0x30, line_feed, 0x00]),
		PackedByteArray([0x30, line_feed, 0xC3, 0xA9]),
		var_to_bytes(["0.1.0", "4f1c2e9"]),
		("0.1.0\n" + "a".repeat(Handshake.HELLO_LIMIT)).to_ascii_buffer(),
	]
	for message: PackedByteArray in strangers:
		var failure := "%s must not read as a hello" % [message]
		assert_object(Handshake.read_hello(message)).override_failure_message(failure).is_null()


func test_the_same_build_is_accepted_while_the_room_has_a_seat() -> void:
	var client := BuildStamp.new("0.1.0", "4f1c2e9")
	var verdict := Handshake.verdict(client, _server, ROOM_FREE)
	assert_int(verdict).is_equal(Handshake.Verdict.ACCEPTED)
	verdict = Handshake.verdict(client, _server, ROOM_FULL)
	assert_int(verdict).is_equal(Handshake.Verdict.ROOM_FULL)


# The message that helps another build is the one asking to update, even when the room is full;
# an unreadable hello comes from another build too.
func test_another_build_must_update_even_when_the_room_is_full() -> void:
	var others: Array[BuildStamp] = [
		BuildStamp.new("0.0.9", "4f1c2e9"),
		BuildStamp.new("0.1.0", "4f1c2ea"),
		BuildStamp.new("0.1.0", ""),
		null,
	]
	for client: BuildStamp in others:
		for room_full: bool in [ROOM_FREE, ROOM_FULL]:
			var verdict := Handshake.verdict(client, _server, room_full)
			assert_int(verdict).is_equal(Handshake.Verdict.UPDATE_REQUIRED)


# A reply this build cannot read comes from another build of the server.
func test_the_reply_carries_the_verdict_and_an_unreadable_one_asks_to_update() -> void:
	for verdict: int in Handshake.Verdict.values():
		var answer := verdict as Handshake.Verdict
		assert_int(Handshake.read_reply(Handshake.reply(answer))).is_equal(verdict)
	for message: PackedByteArray in [
		PackedByteArray(),
		PackedByteArray([0]),
		PackedByteArray([1, 1]),
	]:
		var verdict := Handshake.read_reply(message)
		assert_int(verdict).is_equal(Handshake.Verdict.UPDATE_REQUIRED)
