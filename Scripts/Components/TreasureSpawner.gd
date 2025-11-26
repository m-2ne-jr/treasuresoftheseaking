extends Node3D

@export var treasure_object_scene: PackedScene

func _on_spawner_exited(_area_rid: RID, area: Area3D, area_shape_index: int, _local_shape_index: int) -> void:
	if !is_able_to_spawn(area):
		return
	
	var shape_owner: int = area.shape_find_owner(area_shape_index)
	var shape: BoxShape3D = area.shape_owner_get_shape(shape_owner, area_shape_index) as BoxShape3D
	
	var treasures_to_spawn = get_treasure_spawn_count(area)
	for x in range(treasures_to_spawn):
		var treasure_object = get_treasure_to_spawn()
		var spawn_position: Vector3 = get_spawn_position(area, shape)
		var treasure = get_treasure_from_area(area)
		if treasure == null:
			return
		
		treasure_object.treasure = treasure
		get_tree().root.add_child(treasure_object)
		treasure_object.global_position = spawn_position
		treasure_object.global_rotation.y = randf_range(-1, 1)

func get_treasure_spawn_count(area: Area3D) -> int:
	var treasure_spawn_min: int = area.get_meta("MinTreasureSpawn")
	var treasure_spawn_max: int = area.get_meta("MaxTreasureSpawn")
	
	treasure_spawn_min = clampi(treasure_spawn_min, 0, treasure_spawn_max)
	if treasure_spawn_max < treasure_spawn_min:
		treasure_spawn_max = treasure_spawn_min
	var treasures_to_spawn: int = randi_range(treasure_spawn_min, treasure_spawn_max)
	return treasures_to_spawn

func get_treasure_to_spawn() -> TreasureObject:
	var treasure_object = treasure_object_scene.instantiate() as TreasureObject
	treasure_object.wave_created_on = GameMaster.current_wave
	return treasure_object

func get_spawn_position(spawner: Node3D, spawn_area: BoxShape3D) -> Vector3:
	var x_lower_bound: float = spawner.global_position.x - (spawn_area.size.x / 2)
	var x_upper_bound: float = spawner.global_position.x + (spawn_area.size.x / 2)
	var z_lower_bound: float = spawner.global_position.z - (spawn_area.size.z / 2)
	var z_upper_bound: float = spawner.global_position.z + (spawn_area.size.z / 2)
	
	var x_point: float = randf_range(x_lower_bound, x_upper_bound)
	var y_point: float = spawner.global_position.y + (spawn_area.size.y / 2)
	var z_point: float = randf_range(z_lower_bound, z_upper_bound)
	
	return Vector3(x_point, y_point, z_point)

func get_treasure_from_area(area: Node3D) -> Treasure:
	var treasures: Array = get_treasure_list(area)
	if treasures.is_empty():
		return
	
	calculate_treasure_weights(treasures)
	
	var roll: int = randi_range(1, 100)
	var treasure: Treasure
	for weighted_t: WeightedTreasure in treasures:
		treasure = weighted_t.treasure
		if weighted_t.low_bound <= roll && roll <= weighted_t.high_bound:
			break
	return treasure

func is_able_to_spawn(area: Area3D) -> bool:
	if GameMaster.wave_state == GameMaster.WaveState.WAVE_OUT:
		return false
	if !area.has_meta("Depth"):
		print_debug(area.name + " does not have a set depth - could not spawn treasures.")
		return false
	var spawner_depth: int = area.get_meta("Depth")
	if GameMaster.max_depth < spawner_depth:
		return false
	if !area.has_meta("MinTreasureSpawn"):
		print_debug(area.name + " has no minimum treasure spawn set - could not spawn treasures.")
		return false
	if !area.has_meta("MaxTreasureSpawn"):
		print_debug(area.name + " has no maximum treasure spawn set - could not spawn treasures.")
		return false
	return true

func is_weighted_treasure(obj) -> bool:
	return obj is WeightedTreasure

func get_treasure_list(area: Area3D) -> Array:
	var treasures: Array = []

	if !area.has_meta("TreasureList"):
		print_debug(area.name + " has no treasure list - could not spawn treasures.")
		return []
	treasures = area.get_meta("TreasureList")
	if !treasures.all(is_weighted_treasure):
		return []
	return treasures

func calculate_treasure_weights(treasures: Array):
	var weight_total: float = 0
	for weighted_t: WeightedTreasure in treasures:
		weight_total += weighted_t.weight
	
	var counted_weight: int = 0
	for weighted_t: WeightedTreasure in treasures:
		var norm_weight = weighted_t.get_normalized_weight(weight_total)
		weighted_t.low_bound = counted_weight + 1
		counted_weight += norm_weight
		weighted_t.high_bound = counted_weight
		if weighted_t.high_bound <= weighted_t.low_bound:
			weighted_t.high_bound = weighted_t.low_bound + 1

func _on_spawner_treasure_exited(body: Node3D) -> void:
	if GameMaster.wave_state == GameMaster.WaveState.WAVE_OUT:
		return
	if !body is TreasureObject:
		return
	var treasure_object = body as TreasureObject
	if treasure_object.wave_created_on < GameMaster.current_wave:
		treasure_object.queue_free()
