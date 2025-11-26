extends Area3D

func _on_body_entered(body: Node3D) -> void:
	print_debug("Fallthrough detected.")
	body.queue_free()

func _on_body_exited(body: Node3D) -> void:
	print_debug("Fallthrough detected.")
	body.queue_free()
