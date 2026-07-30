extends Node3D

var treasure_pool: Array[TreasureObject]

const TREASURE_OBJECT_SCENE = preload("uid://jpifec0xkcu7")
const INITIAL_POOL_SIZE: int = 120
const POOL_SIZE_INCREMENT: int = 10

func _ready() -> void:
	load_treasure_pool()
	SignalBus.game_restarted.connect(load_treasure_pool)


func load_treasure_pool() -> void:
	clear_pool()
	extend_pool(INITIAL_POOL_SIZE)


func clear_pool() -> void:
	treasure_pool.clear()
	for child in get_children():
		child.queue_free()


func get_object_from_pool(treasure: Treasure) -> TreasureObject:
	if treasure_pool.is_empty():
		extend_pool(POOL_SIZE_INCREMENT)
	var front_treasure: TreasureObject = treasure_pool.pop_front()
	front_treasure.activate_object(treasure)
	return front_treasure


func extend_pool(new_obj_count: int):
	for i in new_obj_count:
		var treasure_obj = TREASURE_OBJECT_SCENE.instantiate() as TreasureObject
		add_child(treasure_obj)
		return_object_to_pool(treasure_obj)


func return_object_to_pool(treasure: TreasureObject) -> void:
	treasure.reset_object()
	treasure.global_position = Vector3.ZERO
	treasure.global_rotation = Vector3.ZERO
	treasure.scale = Vector3.ONE
	treasure_pool.append(treasure)
