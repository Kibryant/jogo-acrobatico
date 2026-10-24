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
# Every row of a replay played in the window has played (--watch; TASK-10.3).
const REPLAY_ENDED := &"REPLAY_ENDED"
## Every key the code shows; StatusMessage and the HUD take no other.
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
	REPLAY_ENDED,
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
