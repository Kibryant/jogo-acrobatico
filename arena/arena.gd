# The block arena of the walking skeleton (TASK-9, "Números v0 do Claude"): an 80 x 80 m floor;
# the 1 m platform with its ledge and the 45° ramp of the netfox probe (netfox-sonda,
# probe_arena.gd); three 4 x 4 m blocks, 1, 2 and 3 m tall (movimento.md, "Métricas de nível":
# bench, door and ceiling; the 1 m one is climbed with the jump, the other two wait for phase 1);
# and two spawn points 10 m apart, facing each other. Everything sits on PhysicsLayers.WORLD,
# Godot's default layer. The floor's top is y = 0, so a spawn point at y = 0 stands on it.
class_name Arena
extends Node3D


# The spawn point of a slot, from SpawnPoints in scene order: its position is where the feet
# stand and its yaw (rotation.y) is where the fighter looks.
func spawn_point(slot: int) -> Node3D:
	var points := get_node(^"SpawnPoints").get_children()
	assert(slot >= 0 and slot < points.size(), "the arena has %d spawn points" % points.size())
	var point := points[slot]
	assert(point is Node3D, "spawn point %d must be a Node3D" % slot)
	return point as Node3D


func spawn_point_count() -> int:
	return get_node(^"SpawnPoints").get_child_count()
