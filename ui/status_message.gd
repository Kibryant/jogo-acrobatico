# The line of text a client shows over the game: connecting, refused, the server gone (TASK-9,
# criteria 10 and 11). It holds a key of GameText, and the Label shows its message in the
# player's language, since a Label translates a text that is a key. A plain Label with the
# default font for now: the Theme arrives with the first interface scene (DEC-0031 §8).
class_name StatusMessage
extends CanvasLayer

var _label := Label.new()


func _init() -> void:
	name = "StatusMessage"
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.visible = false
	add_child(_label)


# Shows the message of key, one of GameText.KEYS.
func show_key(key: StringName) -> void:
	assert(GameText.KEYS.has(key), "%s is not a key of GameText" % key)
	_label.text = key
	_label.visible = true


func clear() -> void:
	_label.visible = false
	_label.text = ""


# The key on screen; empty when nothing shows.
func shown_key() -> StringName:
	return StringName(_label.text) if _label.visible else &""
