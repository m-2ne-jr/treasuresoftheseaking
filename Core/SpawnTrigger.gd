class_name SpawnTrigger
extends Area3D

func _on_treasure_exited(body: Node3D) -> void:
	if GameMaster.wave_state == GameMaster.WaveState.WAVE_OUT:
		return
	if !body is TreasureObject:
		return
	var treasure_object: TreasureObject = body as TreasureObject
	if treasure_object.wave_created_on < GameMaster.current_wave:
		TreasurePool.instance.return_object_to_pool(treasure_object)
