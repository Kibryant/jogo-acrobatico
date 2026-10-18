# The server's side of the handshake (rede.md §9; DEC-0028 §3), in Godot's authentication step:
# with an auth_callback set, SceneMultiplayer keeps each new connection waiting, out of
# peer_connected, of netfox and of every RPC, until both sides complete it. A hello from the same
# build takes a seat while the room has one; another build is refused with the request to update,
# and a full room with its own message (TASK-9, choices 4 and 10).
# The caller keeps this object: SceneMultiplayer holds its callback without keeping it alive.
class_name HandshakeServer
extends RefCounted

## The handshake accepted peer and seated it in slot.
signal accepted(peer: int, slot: int, client: BuildStamp)
## The handshake refused peer; client is null when its hello was unreadable.
signal refused(peer: int, verdict: Handshake.Verdict, client: BuildStamp)
## A seated peer left, before or after joining the match; its seat is free again.
signal left(peer: int, slot: int)

var room: Room

var _api: SceneMultiplayer
var _build: BuildStamp
var _open := false
# Hellos that came before open(), answered by it.
var _waiting: Dictionary[int, PackedByteArray] = { }
# Peers already answered: another hello from one of them is ignored.
var _answered: Dictionary[int, bool] = { }


func _init(api: SceneMultiplayer, build: BuildStamp, seats: int) -> void:
	_api = api
	_build = build
	room = Room.new(seats)
	api.auth_callback = _on_hello
	api.peer_authentication_failed.connect(_on_peer_gone)
	api.peer_disconnected.connect(_on_peer_gone)


# From now on the server answers, starting with the hellos that waited. The Main opens it once
# netfox's clock runs, so no client syncs with a server whose clock has not started (rede.md §9).
func open() -> void:
	_open = true
	for peer: int in _waiting.keys():
		_answer(peer, _waiting[peer])
	_waiting.clear()


func _on_hello(peer: int, message: PackedByteArray) -> void:
	if _answered.has(peer) or _waiting.has(peer):
		return
	if _open:
		_answer(peer, message)
	else:
		_waiting[peer] = message


func _answer(peer: int, message: PackedByteArray) -> void:
	_answered[peer] = true
	var client := Handshake.read_hello(message)
	var answer := Handshake.verdict(client, _build, room.is_full())
	_api.send_auth(peer, Handshake.reply(answer))
	if answer == Handshake.Verdict.ACCEPTED:
		var slot := room.seat(peer)
		_api.complete_auth(peer)
		accepted.emit(peer, slot, client)
	else:
		_drop_after_the_reply(peer)
		refused.emit(peer, answer, client)


# ENet's peer_disconnect_later() sends what is queued for the peer, the refusal included, and
# only then closes. disconnect_peer() throws the queue away: in Godot 4.7.2 the refused client
# then never hears why (measured in TASK-9, part 2).
func _drop_after_the_reply(peer: int) -> void:
	var transport := _api.multiplayer_peer
	if transport is ENetMultiplayerPeer:
		var enet := transport as ENetMultiplayerPeer
		enet.get_peer(peer).peer_disconnect_later()
	else:
		_api.disconnect_peer(peer)


func _on_peer_gone(peer: int) -> void:
	_waiting.erase(peer)
	_answered.erase(peer)
	var slot := room.leave(peer)
	if slot != Room.NO_SEAT:
		left.emit(peer, slot)
