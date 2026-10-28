# The texts the game shows on screen (DEC-0031 §8): the code shows a key, an ID like
# NET_ROOM_FULL, and the player's language picks its message from the .po files in
# ui/translations/, pt-BR and en from the start. The Main installs them when the game opens, so
# project.godot lists no translation; Godot falls back to en for any other language.
class_name GameText
extends RefCounted

const CONNECTING := &"NET_CONNECTING"
const ROOM_FULL := &"NET_ROOM_FULL"
const UPDATE_REQUIRED := &"NET_UPDATE_REQUIRED"
const SERVER_NOT_RESPONDING := &"NET_SERVER_NOT_RESPONDING"
const SERVER_CLOSED := &"NET_SERVER_CLOSED"
# The mode of the fighter, as the HUD shows it (TASK-10.2).
const HUD_MODE_GROUND := &"HUD_MODE_GROUND"
const HUD_MODE_AIR := &"HUD_MODE_AIR"
const HUD_MODE_DASH := &"HUD_MODE_DASH"
const HUD_MODE_WALL_RUN := &"HUD_MODE_WALL_RUN"
const HUD_MODE_GRAPPLE := &"HUD_MODE_GRAPPLE"
# The tenths of a second until the next dash, beside its arc; the message holds the decimal
# separator of its language (TASK-10.4).
const HUD_DASH_COOLDOWN := &"HUD_DASH_COOLDOWN"
# The tenths of a second until the next grapple, beside its arc, with the maneuver's name: its
# row sits above the dash's (TASK-10.6; visual-e-audio.md, "O gancho na tela").
const HUD_GRAPPLE_COOLDOWN := &"HUD_GRAPPLE_COOLDOWN"
# Every row of a replay played in the window has played (--watch; TASK-10.3).
const REPLAY_ENDED := &"REPLAY_ENDED"
# The options screen (TASK-10.9; visual-e-audio.md, "A tela de opções"): its title, its three
# groups, the eight actions, the two sliders and the two buttons.
const OPTIONS_TITLE := &"OPTIONS_TITLE"
const OPTIONS_GROUP_KEYS := &"OPTIONS_GROUP_KEYS"
const OPTIONS_GROUP_MOUSE := &"OPTIONS_GROUP_MOUSE"
const OPTIONS_GROUP_INTERFACE := &"OPTIONS_GROUP_INTERFACE"
const OPTIONS_ACTION_MOVE_FORWARD := &"OPTIONS_ACTION_MOVE_FORWARD"
const OPTIONS_ACTION_MOVE_BACK := &"OPTIONS_ACTION_MOVE_BACK"
const OPTIONS_ACTION_MOVE_LEFT := &"OPTIONS_ACTION_MOVE_LEFT"
const OPTIONS_ACTION_MOVE_RIGHT := &"OPTIONS_ACTION_MOVE_RIGHT"
const OPTIONS_ACTION_JUMP := &"OPTIONS_ACTION_JUMP"
const OPTIONS_ACTION_DASH := &"OPTIONS_ACTION_DASH"
const OPTIONS_ACTION_GRAPPLE := &"OPTIONS_ACTION_GRAPPLE"
# The light attack, remappable since TASK-12.1 (F-175 §2).
const OPTIONS_ACTION_LIGHT_ATTACK := &"OPTIONS_ACTION_LIGHT_ATTACK"
const OPTIONS_SENSITIVITY := &"OPTIONS_SENSITIVITY"
# Beside the sensitivity: the mouse's travel for a full turn at 800 DPI, {cm} whole centimetres.
const OPTIONS_SENSITIVITY_TURN := &"OPTIONS_SENSITIVITY_TURN"
const OPTIONS_SCALE := &"OPTIONS_SCALE"
# Beside the scale: its value, {whole} and {tenth} its digits, with the language's separator.
const OPTIONS_SCALE_VALUE := &"OPTIONS_SCALE_VALUE"
const OPTIONS_RESTORE := &"OPTIONS_RESTORE"
const OPTIONS_CLOSE := &"OPTIONS_CLOSE"
# A key clicked: the screen waits for the new one for {action}.
const OPTIONS_WAITING := &"OPTIONS_WAITING"
# The new key, {key}, is already the key of another action, {action}: nothing changes.
const OPTIONS_TAKEN := &"OPTIONS_TAKEN"
# A mouse button on an action: {number} is 3 for the middle one, 4 and 5 for the side ones.
const OPTIONS_MOUSE_BUTTON := &"OPTIONS_MOUSE_BUTTON"
# The left mouse button, the light attack's default (TASK-12.1; visual-e-audio.md, "A tela de
# opções").
const OPTIONS_MOUSE_LEFT := &"OPTIONS_MOUSE_LEFT"
## Every key the code shows; StatusMessage, the HUD and the options screen take no other.
const KEYS: Array[StringName] = [
	CONNECTING,
	ROOM_FULL,
	UPDATE_REQUIRED,
	SERVER_NOT_RESPONDING,
	SERVER_CLOSED,
	HUD_MODE_GROUND,
	HUD_MODE_AIR,
	HUD_MODE_DASH,
	HUD_MODE_WALL_RUN,
	HUD_MODE_GRAPPLE,
	HUD_DASH_COOLDOWN,
	HUD_GRAPPLE_COOLDOWN,
	REPLAY_ENDED,
	OPTIONS_TITLE,
	OPTIONS_GROUP_KEYS,
	OPTIONS_GROUP_MOUSE,
	OPTIONS_GROUP_INTERFACE,
	OPTIONS_ACTION_MOVE_FORWARD,
	OPTIONS_ACTION_MOVE_BACK,
	OPTIONS_ACTION_MOVE_LEFT,
	OPTIONS_ACTION_MOVE_RIGHT,
	OPTIONS_ACTION_JUMP,
	OPTIONS_ACTION_DASH,
	OPTIONS_ACTION_GRAPPLE,
	OPTIONS_ACTION_LIGHT_ATTACK,
	OPTIONS_SENSITIVITY,
	OPTIONS_SENSITIVITY_TURN,
	OPTIONS_SCALE,
	OPTIONS_SCALE_VALUE,
	OPTIONS_RESTORE,
	OPTIONS_CLOSE,
	OPTIONS_WAITING,
	OPTIONS_TAKEN,
	OPTIONS_MOUSE_BUTTON,
	OPTIONS_MOUSE_LEFT,
]
## The keys whose message is the same word in pt-BR and in en: a loanword or a name the two
## languages share, not a copy of the other file.
const SAME_IN_BOTH: Array[StringName] = [
	OPTIONS_GROUP_MOUSE,
	OPTIONS_GROUP_INTERFACE,
	OPTIONS_ACTION_DASH,
	OPTIONS_MOUSE_BUTTON,
]
## The messages of each language, by locale.
const FILES: Dictionary[String, String] = {
	"pt_BR": "res://ui/translations/pt_BR.po",
	"en": "res://ui/translations/en.po",
}


# The messages of one language, as Godot reads them from its .po file.
static func load_language(locale: String) -> Translation:
	var path := FILES[locale]
	var resource: Resource = load(path)
	assert(resource is Translation, "%s must load as a Translation" % path)
	return resource as Translation


# Makes every language available to tr() and to the Labels that show a key. Installing twice
# adds nothing: load() returns the same Translation, and the server keeps one of each.
static func install() -> void:
	for locale: String in FILES:
		TranslationServer.add_translation(load_language(locale))


# The message of key in the player's language.
static func text(key: StringName) -> String:
	return str(TranslationServer.translate(key))
