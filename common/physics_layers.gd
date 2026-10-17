# The physics layers of the game, as the bit values that collision_layer and collision_mask take.
# The arena stays on Godot's default layer 1. The fighters live on their own layer, so the camera
# can collide with the world only: it moves in when a wall is in the way, never when the other
# fighter walks behind (movimento.md, "Câmera": "Aproxima quando uma parede fica no meio").
class_name PhysicsLayers
extends RefCounted

## The arena: floor, blocks and ramps.
const WORLD := 1
## The fighters' bodies, which collide with the world and with each other.
const FIGHTERS := 2
