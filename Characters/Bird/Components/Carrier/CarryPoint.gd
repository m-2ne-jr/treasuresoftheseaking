class_name CarryPoint
extends Node3D

@onready var anim_player: AnimationPlayer = %AnimationPlayer

var carried_treasure: Treasure = null

func set_treasure_to_container(treasure: Treasure) -> void:
	carried_treasure = treasure
	var treasure_scene: Node3D = carried_treasure.visual_scene.instantiate()
	add_child(treasure_scene)
	anim_player.play("rotate_point")
