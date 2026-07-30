class_name TreasureObject
extends RigidBody3D

@onready var hitbox: CollisionShape3D = %Hitbox
@onready var animation_player: AnimationPlayer = %AnimationPlayer

@export var treasure: Treasure
var visual_instance: Node3D

var can_be_picked_up: bool = true
var wave_created_on: int = 0

signal pickup_ready(treasure_object: TreasureObject)

@export_flags_3d_physics var collision_mask_layers: int = 15

func _ready() -> void:
	SignalBus.treasure_object_cleared.connect(reactivate_physics)


func activate_object(new_treasure: Treasure):
	process_mode = Node.PROCESS_MODE_INHERIT
	treasure = new_treasure
	mass = treasure.weight
	hitbox.shape = treasure.hitbox_shape
	
	visual_instance = treasure.visual_scene.instantiate() as Node3D
	add_child(visual_instance)


func reset_object():
	process_mode = Node.PROCESS_MODE_DISABLED
	
	if visual_instance == null:
		return
	visual_instance.queue_free()


func allow_pick_up():
	can_be_picked_up = true
	collision_mask = collision_mask_layers
	pickup_ready.emit(self)


func reactivate_physics():
	sleeping = false
