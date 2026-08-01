extends Area3D

func destroy_object(obj: Node3D) -> void:
	print_debug("Fallthrough detected.")
	if !obj is TreasureObject:
		obj.queue_free()
		return
	TreasurePool.instance.return_object_to_pool(obj as TreasureObject)
