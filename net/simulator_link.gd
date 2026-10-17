# Whether netfox's NetworkSimulator connects this game by itself, and where (TASK-9, part 2). The
# simulator gives the hand tests their ping (TASK-9, choice 7; rede.md §10), but only through its
# own autoconnect (addons/netfox.extras/network-simulator.gd): one frame after it starts, it hosts
# on netfox/autoconnect/port, or joins when that port is taken, through a UDP proxy on the next
# port that holds every packet simulated_latency_ms in each direction; the proxy runs in the game
# that hosts. The project keeps autoconnect off (DEC-0023): tools/net_run.sh and
# tools/play_online.sh turn it on for one session with an override.cfg, and the Main then adopts
# the simulator's connection instead of opening its own.
class_name SimulatorLink
extends RefCounted

const ENABLED_SETTING := "netfox/autoconnect/enabled"
const HOST_SETTING := "netfox/autoconnect/host"
const PORT_SETTING := "netfox/autoconnect/port"
const LATENCY_SETTING := "netfox/autoconnect/simulated_latency_ms"
const LOSS_SETTING := "netfox/autoconnect/simulated_packet_loss_chance"
## The environment variables that keep the simulator off when they hold any value
## (network-simulator.gd, _ready).
const OFF_SWITCHES: Array[String] = ["CI", "NETFOX_CI", "NETFOX_NO_AUTOCONNECT"]
# The simulator's fallbacks for the settings it reads (network-simulator.gd,
# _load_project_settings).
const DEFAULT_HOST := "127.0.0.1"
const DEFAULT_PORT := 9999

## Where the game that hosts listens and the others join.
var host: String
var port: int
## ms the proxy holds each packet, in each direction: the ping is twice this.
var latency_ms: int
## % of the packets the proxy drops.
var packet_loss_percent: float


func _init(simulator_host: String, simulator_port: int, latency: int, loss := 0.0) -> void:
	host = simulator_host
	port = simulator_port
	latency_ms = latency
	packet_loss_percent = loss


# The simulator's own checks (network-simulator.gd, _ready): it connects a game only in an editor
# build, since it stays out of exported games; with autoconnect on; and with none of OFF_SWITCHES
# set. environment holds the value of each switch that is set; an empty value counts as unset, as
# the simulator reads it.
static func connects(editor: bool, enabled: bool, environment: Dictionary[String, String]) -> bool:
	if not editor or not enabled:
		return false
	for switch: String in OFF_SWITCHES:
		var value: String = environment.get(switch, "")
		if not value.is_empty():
			return false
	return true


# The link of this game to the simulator; null when the simulator does not connect it.
static func current() -> SimulatorLink:
	var environment: Dictionary[String, String] = { }
	for switch: String in OFF_SWITCHES:
		environment[switch] = OS.get_environment(switch)
	var enabled: bool = ProjectSettings.get_setting(ENABLED_SETTING, false)
	if not connects(OS.has_feature("editor"), enabled, environment):
		return null
	var simulator_host: String = ProjectSettings.get_setting(HOST_SETTING, DEFAULT_HOST)
	var simulator_port: int = ProjectSettings.get_setting(PORT_SETTING, DEFAULT_PORT)
	var latency: int = ProjectSettings.get_setting(LATENCY_SETTING, 0)
	var loss: float = ProjectSettings.get_setting(LOSS_SETTING, 0.0)
	return SimulatorLink.new(simulator_host, simulator_port, latency, loss)


# Where the clients knock: the proxy, on the next port, when the simulator delays or drops
# packets (network-simulator.gd, _is_proxy_required); the host's own port otherwise.
func join_port() -> int:
	if latency_ms > 0 or packet_loss_percent > 0.0:
		return port + 1
	return port


# One line for the log: where the simulator connects and what it adds.
func describe() -> String:
	return (
		"netfox's network simulator on %s:%d, %d ms each way (ping %d), %.1f%% loss;"
		+ " clients join on port %d"
	) % [host, port, latency_ms, 2 * latency_ms, packet_loss_percent, join_port()]
