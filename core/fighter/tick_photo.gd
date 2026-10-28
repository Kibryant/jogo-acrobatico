# The photo of the tick (DEC-0051 §1; DEC-0026 §3): every fighter of the match as the tick begins,
# its name, the node's name and netfox's route, unique in the match; its feet; and a copy of its
# state. The Match fills it on netfox's after_prepare_tick, once the tick is restored, and each
# fighter reads the others only here, so the order of the nodes in the tree never changes the
# result: like a Promise.all over snapshots, nobody sees another's write of this tick. Values only.
class_name TickPhoto
extends RefCounted

var _entries: Dictionary[StringName, Entry] = { }
# The names in order, kept sorted on every add, so a reader walks them by name.
var _names: Array[StringName] = []


# One fighter in the photo.
class Entry:
	var name: StringName
	var feet: Vector3
	var state: FighterState


	func _init(entry_name: StringName, entry_feet: Vector3, entry_state: FighterState) -> void:
		name = entry_name
		feet = entry_feet
		state = entry_state


# Adds a fighter, a copy of its state, so a later change of the state never reaches the photo. A
# name already there is replaced.
func add(fighter_name: StringName, feet: Vector3, state: FighterState) -> void:
	if not _entries.has(fighter_name):
		_names.append(fighter_name)
		_names.sort_custom(
			func(a: StringName, b: StringName) -> bool:
				return String(a) < String(b),
		)
	_entries[fighter_name] = Entry.new(fighter_name, feet, state.copy())


func clear() -> void:
	_entries.clear()
	_names.clear()


func size() -> int:
	return _names.size()


func has(fighter_name: StringName) -> bool:
	return _entries.has(fighter_name)


# The fighter of that name, or null when the photo has none.
func find(fighter_name: StringName) -> Entry:
	if not _entries.has(fighter_name):
		return null
	return _entries[fighter_name]


# The fighters, in name order.
func entries() -> Array[Entry]:
	var ordered: Array[Entry] = []
	for fighter_name: StringName in _names:
		ordered.append(_entries[fighter_name])
	return ordered
