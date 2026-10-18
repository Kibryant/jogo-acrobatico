# Criteria 9 and 10 of TASK-9, from end to end in one process: a real ENet server and real ENet
# clients on this PC's loopback, each with its own SceneMultiplayer, run the game's handshake
# (HandshakeServer and HandshakeClient), polled by hand. netfox stays out: the handshake ends
# before netfox ever sees a peer, so one process holds every side. It proves what the pure tests
# cannot: a refusal reaches the client before the server drops it, a refused client is never
# admitted, and the room frees a seat when its player leaves.
extends GdUnitTestSuite

const LOOPBACK := "127.0.0.1"
const SEATS := 2 # TASK-9, choice 4
## ms: how long a step may take on the loopback; the steps take a few frames.
const STEP_TIMEOUT_MS := 3000
## ms: how long a hello is left waiting for a server that has not opened.
const WAIT_MS := 250

var _server_build := BuildStamp.new("0.1.0", "4f1c2e9")
var _server_api: SceneMultiplayer
var _server_peer: ENetMultiplayerPeer
var _handshake: HandshakeServer
var _port := 0
var _clients: Array[TestClient] = []
# The peers whose connection reached the server's authentication step.
var _authenticating: Array[int] = []
# What the server's handshake said, in order: "accepted <peer> <slot>", "refused <peer> <verdict>"
# and "left <peer> <slot>".
var _said: Array[String] = []


# One client with its own SceneMultiplayer, and what happened to it, in order: "accepted",
# "refused <verdict>", "connected" (admitted by Godot) and "dropped" (the server closed on it).
class TestClient:
	var api := SceneMultiplayer.new()
	var peer := ENetMultiplayerPeer.new()
	var handshake: HandshakeClient
	var events: Array[String] = []
	# The id the network gives this client, read while its connection is open.
	var _id := 0


	func _init(host: String, port: int, build: BuildStamp) -> void:
		peer.create_client(host, port)
		_id = peer.get_unique_id()
		handshake = HandshakeClient.new(api, build)
		handshake.accepted.connect(_on_accepted)
		handshake.refused.connect(_on_refused)
		api.connected_to_server.connect(_on_connected)
		api.server_disconnected.connect(_on_dropped)
		api.multiplayer_peer = peer


	func id() -> int:
		return _id


	func _on_accepted() -> void:
		events.append("accepted")


	func _on_refused(verdict: Handshake.Verdict) -> void:
		events.append("refused %d" % verdict)


	func _on_connected() -> void:
		events.append("connected")


	func _on_dropped() -> void:
		events.append("dropped")


func before_test() -> void:
	_said.clear()
	_authenticating.clear()
	_clients.clear()
	_server_api = SceneMultiplayer.new()
	_server_peer = ENetMultiplayerPeer.new()
	_server_peer.set_bind_ip(LOOPBACK)
	# Port 0: the system picks a free one.
	var error := _server_peer.create_server(0)
	assert(error == OK, "the test server needs a free UDP port: %s" % error_string(error))
	_port = _server_peer.host.get_local_port()
	_handshake = HandshakeServer.new(_server_api, _server_build, SEATS)
	_handshake.accepted.connect(_on_accepted)
	_handshake.refused.connect(_on_refused)
	_handshake.left.connect(_on_left)
	_server_api.peer_authenticating.connect(_on_authenticating)
	_server_api.multiplayer_peer = _server_peer


func after_test() -> void:
	for client: TestClient in _clients:
		client.peer.close()
	_server_peer.close()
	_clients.clear()
	_handshake = null


func test_the_same_build_is_accepted_seated_and_admitted() -> void:
	_handshake.open()
	var client := _connect(_server_build)
	assert_bool(await _poll_until(_admitted.bind([client]))).is_true()
	assert_array(client.events).is_equal(["accepted", "connected"])
	assert_array(_said).is_equal(["accepted %d 0" % client.id()])
	assert_array(_handshake.room.peers()).is_equal([client.id()])


func test_a_third_player_hears_that_the_room_is_full_before_it_is_dropped() -> void:
	_handshake.open()
	var first := _connect(_server_build)
	var second := _connect(_server_build)
	assert_bool(await _poll_until(_admitted.bind([first, second]))).is_true()
	var third := _connect(_server_build)
	assert_bool(await _poll_until(_dropped.bind([third]))).is_true()
	assert_array(third.events).is_equal(["refused %d" % Handshake.Verdict.ROOM_FULL, "dropped"])
	assert_bool(_said.has("refused %d %d" % [third.id(), Handshake.Verdict.ROOM_FULL])).is_true()
	assert_array(_handshake.room.peers()).is_equal([first.id(), second.id()])
	assert_bool(_server_api.get_peers().has(third.id())).is_false()


# DEC-0028 §3: another commit, the editor's empty one included, or another version is refused
# with the request to update, and never seated.
func test_another_build_hears_that_it_must_update_before_it_is_dropped() -> void:
	_handshake.open()
	var others: Array[TestClient] = [
		_connect(BuildStamp.new("0.1.0", "")),
		_connect(BuildStamp.new("0.1.0", "4f1c2ea")),
		_connect(BuildStamp.new("0.0.9", "4f1c2e9")),
	]
	assert_bool(await _poll_until(_dropped.bind(others))).is_true()
	var refusal := "refused %d" % Handshake.Verdict.UPDATE_REQUIRED
	for client: TestClient in others:
		assert_array(client.events).is_equal([refusal, "dropped"])
		var said := "refused %d %d" % [client.id(), Handshake.Verdict.UPDATE_REQUIRED]
		assert_bool(_said.has(said)).is_true()
	assert_array(_handshake.room.peers()).is_empty()


# The server answers no hello before it opens, when netfox's clock runs (Main.start_server).
func test_a_hello_that_comes_before_the_server_opens_waits_for_it() -> void:
	var client := _connect(_server_build)
	assert_bool(await _poll_until(_reached_the_server.bind(client))).is_true()
	assert_bool(await _poll_until(_answered.bind(client), WAIT_MS)).is_false()
	assert_array(_said).is_empty()
	_handshake.open()
	assert_bool(await _poll_until(_admitted.bind([client]))).is_true()
	assert_array(_said).is_equal(["accepted %d 0" % client.id()])


func test_a_player_who_leaves_frees_the_seat_for_a_new_one() -> void:
	_handshake.open()
	var first := _connect(_server_build)
	var second := _connect(_server_build)
	assert_bool(await _poll_until(_admitted.bind([first, second]))).is_true()
	first.peer.close()
	assert_bool(await _poll_until(_server_said.bind("left %d 0" % first.id()))).is_true()
	assert_array(_handshake.room.peers()).is_equal([second.id()])
	var newcomer := _connect(_server_build)
	assert_bool(await _poll_until(_admitted.bind([newcomer]))).is_true()
	assert_int(_handshake.room.slot_of(newcomer.id())).is_equal(0)


func _connect(build: BuildStamp) -> TestClient:
	var client := TestClient.new(LOOPBACK, _port, build)
	_clients.append(client)
	return client


# Polls the server and every client, frame after frame, until done() holds; false when it still
# does not after timeout_ms.
func _poll_until(done: Callable, timeout_ms := STEP_TIMEOUT_MS) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		_server_api.poll()
		for client: TestClient in _clients:
			client.api.poll()
		if done.call():
			return true
		await get_tree().process_frame
	return false


# Accepted by the handshake and admitted by Godot on both sides.
func _admitted(clients: Array) -> bool:
	for client: TestClient in clients:
		if not client.events.has("connected") or not _server_api.get_peers().has(client.id()):
			return false
	return true


func _dropped(clients: Array) -> bool:
	for client: TestClient in clients:
		if not client.events.has("dropped"):
			return false
	return true


func _reached_the_server(client: TestClient) -> bool:
	return _authenticating.has(client.id())


func _answered(client: TestClient) -> bool:
	return not client.events.is_empty()


func _server_said(line: String) -> bool:
	return _said.has(line)


func _on_authenticating(peer: int) -> void:
	_authenticating.append(peer)


func _on_accepted(peer: int, slot: int, _client: BuildStamp) -> void:
	_said.append("accepted %d %d" % [peer, slot])


func _on_refused(peer: int, verdict: Handshake.Verdict, _client: BuildStamp) -> void:
	_said.append("refused %d %d" % [peer, verdict])


func _on_left(peer: int, slot: int) -> void:
	_said.append("left %d %d" % [peer, slot])
