class_name Nest
extends Area3D

@onready var animation_player: AnimationPlayer = %AnimationPlayer

func _on_nest_object_entered(body: Node3D) -> void:
	if !body is TreasureObject:
		return
	
	var t_object: TreasureObject = body
	GameMaster.current_points += t_object.treasure.value
	play_animation()
	SoundManager.play_sound(SoundManager.SFX_LIB[SoundManager.SFX_LIST.SFX_TREASURE_BANK_SINGLE])
	TreasurePool.instance.return_object_to_pool(t_object)
	SignalBus.treasure_object_cleared.emit()


func play_animation() -> void:
	animation_player.stop()
	animation_player.play("on_get_treasure")
