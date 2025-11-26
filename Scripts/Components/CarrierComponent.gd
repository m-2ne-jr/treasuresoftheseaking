extends Node3D

@onready var treasure_spawner: TreasureSpawner = %TreasureSpawner

@export_range(0, 20) var carry_limit: int = 9
@export var carry_containers: Array[Node3D]
@export var carry_point: PackedScene

var current_held_score: int:
	set(value):
		if value < 0:
			value = 0
		current_held_score = value

var active_treasures: Dictionary[Treasure, CarryPoint] = {}

signal treasure_pickup_successful
signal treasure_drop_successful
signal treasure_list_changed(treasure_list: Array[Treasure])
signal carry_limit_reached(is_maxed: bool)

func _on_treasure_picked_up(treasure_object: TreasureObject) -> void:
	if active_treasures.size() >= carry_limit:
		return
	
	var treasure = treasure_object.treasure.get_instance()
	treasure_object.queue_free()
	await treasure_object.tree_exited
	GameMaster.treasure_object_destroyed.emit()
	add_treasure_to_list(treasure)
	treasure_pickup_successful.emit()
	
func _on_nest_entered(area: Area3D) -> void:
	if active_treasures.is_empty():
		return
	if !area is Nest:
		return
	
	var nest = area as Nest
	nest.play_animation()
	GameMaster.current_points += current_held_score
	
	for i in range(active_treasures.size(), 0, -1):
		remove_treasure_from_list(active_treasures.keys()[i - 1])

func on_treasure_drop_requested(current_speed: float):
	if active_treasures.is_empty():
		return
	drop_treasure(current_speed)
	treasure_drop_successful.emit()

func drop_treasure(current_speed: float):
	var index: int = active_treasures.size() - 1
	var treasure_to_drop: Treasure = active_treasures.keys()[index]
	treasure_spawner.spawn_treasure_with_force(treasure_to_drop, current_speed)
	remove_treasure_from_list(treasure_to_drop)

func add_treasure_to_list(treasure: Treasure):
	var point = carry_point.instantiate() as CarryPoint
	var container: Node3D = get_least_occupied_container()
	container.add_child(point)
	active_treasures.get_or_add(treasure, point)
	point.set_treasure_to_container(treasure)
	current_held_score += treasure.value
	treasure_list_changed.emit(active_treasures.keys())

func remove_treasure_from_list(treasure: Treasure):
	active_treasures[treasure].queue_free()
	active_treasures.erase(treasure)
	current_held_score -= treasure.value
	treasure_list_changed.emit(active_treasures.keys())

func set_point_positions(_treasure_list: Array[Treasure]):
	for carry_container: Node3D in carry_containers:
		var child_points = carry_container.get_children()
		var total_offset: float = 0
		
		for index in child_points.size():
			var point: CarryPoint = child_points[index] as CarryPoint
			point.position.y = 0
		
			var self_margin = point.carried_treasure.position_offset * 0.5
			total_offset += self_margin
		
			if index > 0:
				var point_below: CarryPoint = child_points[index - 1] as CarryPoint
				var below_margin = point_below.carried_treasure.position_offset * 0.5
				total_offset += below_margin
		
			point.position.y += total_offset

func get_least_occupied_container() -> Node3D:
	var container: Node3D
	
	for index: int in carry_containers.size():
		if index == 0:
			container = carry_containers[index]
			continue
		var count: int = carry_containers[index].get_child_count()
		var prev_count: int = carry_containers[index - 1].get_child_count()
		if prev_count > count:
			container = carry_containers[index]
	return container
	
func check_carry_limit(treasure_list: Array[Treasure]):
	var is_maxed: bool = treasure_list.size() >= carry_limit
	carry_limit_reached.emit(is_maxed)
