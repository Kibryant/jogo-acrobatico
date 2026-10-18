# The handshake on connecting (DEC-0028 §3; rede.md §9), as pure functions: the client says
# which build it is, and the server answers whether it may play. Like a login request before any
# API call: HandshakeServer and HandshakeClient carry these messages in Godot's authentication
# step, before netfox or any RPC sees the peer.
# The messages are plain ASCII, read byte by byte: whatever a stranger sends, reading it never
# makes the engine log an error (bytes_to_var() does, on bad data).
class_name Handshake
extends RefCounted

enum Verdict {
	ACCEPTED = 1,
	## The client is another build: a different version or commit (TASK-9, choice 10).
	UPDATE_REQUIRED = 2,
	## The room already seats its players (TASK-9, choice 4).
	ROOM_FULL = 3,
}

## Bytes: a hello longer than this is not one of ours.
const HELLO_LIMIT := 256
const SEPARATOR := "\n"
const NEWLINE_BYTE := 10
const FIRST_PRINTABLE := 32
const LAST_PRINTABLE := 126


# What a client says first: its version and its commit, one per line.
static func hello(build: BuildStamp) -> PackedByteArray:
	return (build.version + SEPARATOR + build.commit).to_ascii_buffer()


# The build a hello names; null when the bytes are not a hello.
static func read_hello(message: PackedByteArray) -> BuildStamp:
	if message.is_empty() or message.size() > HELLO_LIMIT:
		return null
	for byte: int in message:
		var printable := byte >= FIRST_PRINTABLE and byte <= LAST_PRINTABLE
		if not printable and byte != NEWLINE_BYTE:
			return null
	var lines := message.get_string_from_ascii().split(SEPARATOR)
	if lines.size() != 2:
		return null
	return BuildStamp.new(lines[0], lines[1])


# The server's answer. Another build is refused first, even when the room is full: it could not
# play here anyway, and the message that helps is the one asking to update.
static func verdict(client: BuildStamp, server: BuildStamp, room_full: bool) -> Verdict:
	if client == null or not client.same_as(server):
		return Verdict.UPDATE_REQUIRED
	if room_full:
		return Verdict.ROOM_FULL
	return Verdict.ACCEPTED


static func reply(answer: Verdict) -> PackedByteArray:
	return PackedByteArray([answer])


# The verdict a reply carries. A reply this build cannot read comes from another build of the
# server, so it reads as a request to update.
static func read_reply(message: PackedByteArray) -> Verdict:
	if message.size() == 1 and Verdict.values().has(message[0]):
		return message[0] as Verdict
	return Verdict.UPDATE_REQUIRED
