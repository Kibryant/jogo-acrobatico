# The client's side of the handshake (rede.md §9; DEC-0028 §3), in Godot's authentication step:
# as soon as the connection to the server opens, the client says which build it is, then waits
# for the verdict. Accepted, it completes the authentication, and SceneMultiplayer emits
# connected_to_server, which also starts netfox's clock (NetworkEvents, network-events.gd).
# The caller keeps this object: SceneMultiplayer holds its callback without keeping it alive.
class_name HandshakeClient
extends RefCounted

## The server accepted this build; connected_to_server follows.
signal accepted
## The server refused this client; it drops the connection right after.
signal refused(verdict: Handshake.Verdict)

const SERVER := MultiplayerPeer.TARGET_PEER_SERVER

var _api: SceneMultiplayer
var _build: BuildStamp
var _answered := false


func _init(api: SceneMultiplayer, build: BuildStamp) -> void:
	_api = api
	_build = build
	api.auth_callback = _on_reply
	api.peer_authenticating.connect(_on_connection_open)


func _on_connection_open(peer: int) -> void:
	if peer == SERVER:
		_api.send_auth(SERVER, Handshake.hello(_build))


func _on_reply(peer: int, message: PackedByteArray) -> void:
	if peer != SERVER or _answered:
		return
	_answered = true
	var answer := Handshake.read_reply(message)
	if answer == Handshake.Verdict.ACCEPTED:
		_api.complete_auth(SERVER)
		accepted.emit()
	else:
		refused.emit(answer)
