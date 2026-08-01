class_name SpawnRegion
extends Area3D

@export var treasure_list: Array[WeightedTreasure]
@export_range(
	GameMaster.MIN_DEPTH,
	GameMaster.MAX_DEPTH
) var depth: int = GameMaster.MIN_DEPTH
@export var min_treasure_spawn: int
@export var max_treasure_spawn: int

var spawner_area: CollisionShape3D

func _ready() -> void:
	const START_DEPTH := 1
	
	var child_index: int = get_children().find_custom(_is_collision_shape)
	spawner_area = get_child(child_index)

	ErrorHelper.try(SignalBus.spawn_initial_treasures.connect(_force_spawn_treasures.bind(START_DEPTH)))


func _on_spawn_trigger_exited(area: Area3D) -> void:
	if !area is SpawnTrigger:
		return
	if !is_able_to_spawn():
		return
	
	SignalBus.treasures_being_spawned.emit(true)
	spawn_treasures()
	SignalBus.treasures_being_spawned.emit(false)

func spawn_treasures() -> void:
	var treasures_to_spawn: int = get_treasure_spawn_count()
	
	for i in treasures_to_spawn:
		var spawn_position: Vector3 = get_spawn_position(spawner_area.shape as BoxShape3D)
		var treasure: Treasure = get_treasure()
		if treasure == null:
			return
		
		var treasure_object: TreasureObject = get_treasure_to_spawn(treasure)
		treasure_object.global_position = spawn_position
		treasure_object.global_rotation.y = randf_range(-1, 1)


func get_treasure_spawn_count() -> int:
	return randi_range(min_treasure_spawn, max_treasure_spawn)


func get_treasure_to_spawn(treasure: Treasure) -> TreasureObject:
	var treasure_object: TreasureObject = TreasurePool.instance.get_object_from_pool(treasure)
	treasure_object.wave_created_on = GameMaster.current_wave
	return treasure_object


func get_spawn_position(region_shape: BoxShape3D) -> Vector3:
	var x_lower_bound: float = global_position.x - (region_shape.size.x / 2)
	var x_upper_bound: float = global_position.x + (region_shape.size.x / 2)
	var z_lower_bound: float = global_position.z - (region_shape.size.z / 2)
	var z_upper_bound: float = global_position.z + (region_shape.size.z / 2)
	
	var x_point: float = randf_range(x_lower_bound, x_upper_bound)
	var y_point: float = global_position.y + (region_shape.size.y / 2)
	var z_point: float = randf_range(z_lower_bound, z_upper_bound)
	
	return Vector3(x_point, y_point, z_point)


func get_treasure() -> Treasure:
	if treasure_list.is_empty():
		return
	
	calculate_treasure_weights(treasure_list)
	
	var roll: int = randi_range(1, 100)
	var treasure: Treasure
	for weighted_t: WeightedTreasure in treasure_list:
		treasure = weighted_t.treasure
		if weighted_t.low_bound <= roll && roll <= weighted_t.high_bound:
			break
	return treasure


func is_able_to_spawn() -> bool:
	if !GameMaster.is_game_time_active:
		return false
	if GameMaster.wave_state == GameMaster.WaveState.WAVE_OUT:
		return false
	if GameMaster.current_max_depth < depth:
		return false
	return true


func calculate_treasure_weights(treasures: Array) -> void:
	var weight_total: float = 0
	for weighted_t: WeightedTreasure in treasures:
		weight_total += weighted_t.weight
	
	var counted_weight: int = 0
	for weighted_t: WeightedTreasure in treasures:
		var norm_weight: int = weighted_t.get_normalized_weight(weight_total)
		weighted_t.low_bound = counted_weight + 1
		counted_weight += norm_weight
		weighted_t.high_bound = counted_weight
		if weighted_t.high_bound <= weighted_t.low_bound:
			weighted_t.high_bound = weighted_t.low_bound + 1


func _is_collision_shape(item: Variant) -> bool:
	return item is CollisionShape3D


func _force_spawn_treasures(requested_depth: int) -> void:
	if depth != requested_depth:
		return
	spawn_treasures()
