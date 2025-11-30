extends Node3D

@onready var treasure_spawner: TreasureSpawner = %TreasureSpawner

@export var carry_containers: Array[Node3D]
@export var carry_point: PackedScene

var current_held_score: int:
	set(value):
		if value < 0:
			value = 0
		current_held_score = value

var active_treasures: Dictionary[Treasure, CarryPoint] = {}

signal treasure_drop_successful
signal carry_limit_reached(is_maxed: bool)

func _ready() -> void:
	SignalBus.treasure_list_changed.connect(set_point_positions)
	SignalBus.treasure_list_changed.connect(check_carry_limit)
	
func _on_treasure_picked_up(treasure_object: TreasureObject) -> void:
	if active_treasures.size() >= GameMaster.carry_limit:
		SignalBus.treasure_acquired.emit(false)
		return
	
	var treasure = treasure_object.treasure.get_instance()
	treasure_object.queue_free()
	await treasure_object.tree_exited
	SignalBus.treasure_object_destroyed.emit()
	add_treasure_to_list(treasure)
	SignalBus.treasure_acquired.emit(true)
	
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
	change_held_score(treasure.value)
	SignalBus.treasure_list_changed.emit(active_treasures.keys())

func remove_treasure_from_list(treasure: Treasure):
	active_treasures[treasure].queue_free()
	active_treasures.erase(treasure)
	change_held_score(-treasure.value)
	SignalBus.treasure_list_changed.emit(active_treasures.keys())

func change_held_score(value: int):
	current_held_score += value
	SignalBus.held_score_changed.emit(current_held_score)

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
	var is_maxed: bool = treasure_list.size() >= GameMaster.carry_limit
	carry_limit_reached.emit(is_maxed)
