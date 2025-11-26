class_name Treasure
extends Resource

@export var name: String
@export var value: int
@export var weight: float

@export var visual_scene: PackedScene
@export var hitbox_shape: Shape3D

@export var position_offset: float

func get_instance() -> Treasure:
	var new_treasure = Treasure.new()
	new_treasure.name = name
	new_treasure.value = value
	new_treasure.weight = weight
	new_treasure.visual_scene = visual_scene
	new_treasure.hitbox_shape = hitbox_shape
	new_treasure.position_offset = position_offset
	if has_meta("LockedRotation"):
		new_treasure.set_meta("LockedRotation", true)
	return new_treasure
