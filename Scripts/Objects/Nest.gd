class_name Nest
extends Area3D

@onready var animation_player: AnimationPlayer = %AnimationPlayer

func _on_nest_object_entered(body: Node3D) -> void:
	if !body is TreasureObject:
		return
	GameMaster.current_points += body.treasure.value
	play_animation()
	body.queue_free()
	GameMaster.treasure_object_destroyed.emit()

func play_animation():
	animation_player.stop()
	animation_player.play("on_get_treasure")
