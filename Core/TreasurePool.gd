class_name TreasurePool
extends Node3D

var treasure_pool: Array[TreasureObject]

const TREASURE_OBJECT_SCENE = preload("uid://jpifec0xkcu7")
const INITIAL_POOL_SIZE: int = 120
const POOL_SIZE_INCREMENT: int = 10

static var instance: TreasurePool:
	get():
		if instance == null:
			instance = TreasurePool.new()
		if !instance.is_inside_tree():
			var tree: SceneTree = Engine.get_main_loop()
			tree.root.add_child(instance)
		return instance


func _ready() -> void:
	load_treasure_pool()
	ErrorHelper.try(SignalBus.game_restarted.connect(load_treasure_pool))


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
	var front_idx: int = treasure_pool.find_custom(_first_free_object)
	var front: TreasureObject = treasure_pool[front_idx]
	front.activate_object(treasure)
	return front


func extend_pool(new_obj_count: int) -> void:
	for i in new_obj_count:
		var treasure_obj: TreasureObject = TREASURE_OBJECT_SCENE.instantiate()
		add_child(treasure_obj)
		treasure_pool.append(treasure_obj)
		return_object_to_pool(treasure_obj)


func return_object_to_pool(treasure: TreasureObject) -> void:
	treasure.reset_object()
	treasure.global_position = Vector3.ZERO
	treasure.global_rotation = Vector3.ZERO
	treasure.scale = Vector3.ONE


func _first_free_object(t_obj: TreasureObject) -> bool:
	return t_obj.is_available
