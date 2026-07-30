class_name Nest
extends Area3D

@onready var animation_player: AnimationPlayer = %AnimationPlayer

func _on_nest_object_entered(body: Node3D) -> void:
	if !body is TreasureObject:
		return
	GameMaster.current_points += body.treasure.value
	play_animation()
	SoundManager.play_sound(SoundManager.SFX_LIB[SoundManager.SFX_LIST.SFX_TREASURE_BANK_SINGLE])
	TreasurePool.return_object_to_pool(body)
	SignalBus.treasure_object_cleared.emit()


func play_animation():
	animation_player.stop()
	animation_player.play("on_get_treasure")
