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
	ErrorHelper.try(SignalBus.treasure_list_changed.connect(set_point_positions))
	ErrorHelper.try(SignalBus.treasure_list_changed.connect(check_carry_limit))
	ErrorHelper.try(SignalBus.player_died.connect(drop_all_treasures))
	ErrorHelper.try(SignalBus.game_over.connect(drop_all_treasures))


func _on_treasure_picked_up(treasure_object: TreasureObject) -> void:
	if active_treasures.size() >= GameMaster.carry_limit:
		SoundManager.play_sound(SoundManager.SFX_LIB[SoundManager.SFX_LIST.SFX_TREASURE_MAX_CAPACITY])
		
		SignalBus.treasure_acquired.emit(false)
		return
	
	var treasure: Treasure = treasure_object.treasure.get_instance()
	
	var pickup_sfx := SoundManager.SFX_LIB[SoundManager.SFX_LIST.SFX_TREASURE_PICKUP]
	SoundManager.play_sound(pickup_sfx)
	
	TreasurePool.instance.return_object_to_pool(treasure_object)
	SignalBus.treasure_object_cleared.emit()
	
	add_treasure_to_list(treasure)
	SignalBus.treasure_acquired.emit(true)


func _on_nest_entered(area: Area3D) -> void:
	if active_treasures.is_empty():
		return
	if !area is Nest:
		return
	
	var nest: Nest = area as Nest
	nest.play_animation()
	
	var sfx: AudioStream
	if active_treasures.size() <= 1:
		sfx = SoundManager.SFX_LIB[SoundManager.SFX_LIST.SFX_TREASURE_BANK_SINGLE]
	else:
		sfx = SoundManager.SFX_LIB[SoundManager.SFX_LIST.SFX_TREASURE_BANK_ALL]
	SoundManager.play_sound(sfx)
	
	GameMaster.current_points += current_held_score
	
	for i in range(active_treasures.size(), 0, -1):
		var t: Treasure = active_treasures.keys()[i - 1]
		remove_treasure_from_list(t)


func on_treasure_drop_requested(current_speed: float) -> void:
	if active_treasures.is_empty():
		return
	
	drop_treasure(current_speed)
	SoundManager.play_sound(SoundManager.SFX_LIB[SoundManager.SFX_LIST.SFX_TREASURE_DROP])
	treasure_drop_successful.emit()


func drop_treasure(current_speed: float) -> void:
	var index: int = active_treasures.size() - 1
	var treasure_to_drop: Treasure = active_treasures.keys()[index]
	treasure_spawner.spawn_treasure_with_force(treasure_to_drop, current_speed)
	remove_treasure_from_list(treasure_to_drop)


func drop_all_treasures() -> void:
	if active_treasures.is_empty():
		return
	for i in range(active_treasures.size(), 0, -1):
		var treasure: Treasure = active_treasures.keys()[i - 1]
		treasure_spawner.spawn_treasure_as_drop(treasure)
		remove_treasure_from_list(treasure)


func add_treasure_to_list(treasure: Treasure) -> void:
	var point: CarryPoint = carry_point.instantiate()
	var container: Node3D = get_least_occupied_container()
	container.add_child(point)
	active_treasures.get_or_add(treasure, point)
	point.set_treasure_to_container(treasure)
	change_held_score(treasure.value)
	SignalBus.treasure_list_changed.emit(active_treasures.keys())


func remove_treasure_from_list(treasure: Treasure) -> void:
	active_treasures[treasure].queue_free()
	if !active_treasures.erase(treasure):
		return
	
	change_held_score(-treasure.value)
	SignalBus.treasure_list_changed.emit(active_treasures.keys())


func change_held_score(value: int) -> void:
	current_held_score += value
	SignalBus.held_score_changed.emit(current_held_score)


func set_point_positions(_treasure_list: Array[Treasure]) -> void:
	for carry_container: Node3D in carry_containers:
		var child_points: Array[Node] = carry_container.get_children()
		var total_offset: float = 0
		
		const MARGIN_PERCENT := 0.5
		
		for index in child_points.size():
			var point: CarryPoint = child_points[index] as CarryPoint
			point.position.y = 0
		
			var self_margin: float = point.carried_treasure.position_offset * MARGIN_PERCENT
			total_offset += self_margin
		
			if index > 0:
				var point_below: CarryPoint = child_points[index - 1] as CarryPoint
				var below_margin: float = point_below.carried_treasure.position_offset * MARGIN_PERCENT
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


func check_carry_limit(treasure_list: Array[Treasure]) -> void:
	var is_maxed: bool = treasure_list.size() >= GameMaster.carry_limit
	carry_limit_reached.emit(is_maxed)
