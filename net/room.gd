# The room on the server (visao-geral.md, "Os contextos": the room, "sala", lives on the server):
# the seats of one match. A player takes a seat when the handshake accepts them and frees it on
# leaving. The seat is a slot: it picks the fighter's spawn point in the arena, while the fighter's
# node name follows the order the fighters spawn in (Match.spawn_fighter). A peer is the id the
# network gives each connection, never 0.
class_name Room
extends RefCounted

const NO_SEAT := -1
const EMPTY := 0

## How many players the room seats.
var capacity: int

# The peer in each slot, EMPTY when the slot is free.
var _peers: Array[int] = []


func _init(seats: int) -> void:
	capacity = seats
	_peers.resize(seats)
	_peers.fill(EMPTY)


func is_full() -> bool:
	return not _peers.has(EMPTY)


# Seats peer in the lowest free slot and returns it; NO_SEAT when the room is full or the peer
# already has a seat.
func seat(peer: int) -> int:
	if peer == EMPTY or _peers.has(peer):
		return NO_SEAT
	var slot := _peers.find(EMPTY)
	if slot != NO_SEAT:
		_peers[slot] = peer
	return slot


# Frees the seat of peer and returns its slot; NO_SEAT when the peer had none.
func leave(peer: int) -> int:
	var slot := slot_of(peer)
	if slot != NO_SEAT:
		_peers[slot] = EMPTY
	return slot


func slot_of(peer: int) -> int:
	if peer == EMPTY:
		return NO_SEAT
	return _peers.find(peer)


# The seated peers, in slot order.
func peers() -> Array[int]:
	var seated: Array[int] = []
	for peer: int in _peers:
		if peer != EMPTY:
			seated.append(peer)
	return seated
