class_name TreasureObject
extends RigidBody3D

@onready var hitbox: CollisionShape3D = %Hitbox
@onready var animation_player: AnimationPlayer = %AnimationPlayer

@export var treasure: Treasure

var can_be_picked_up: bool = true
var wave_created_on: int = 0

signal pickup_ready(treasure_object: TreasureObject)

func _ready() -> void:
	if treasure == null:
		queue_free()
		
	var visual_instance = treasure.visual_scene.instantiate()
	add_child(visual_instance)
	
	mass = treasure.weight
	hitbox.shape = treasure.hitbox_shape
	
	SignalBus.treasure_object_destroyed.connect(reactivate_physics)

func allow_pick_up():
	can_be_picked_up = true
	collision_mask = 15
	pickup_ready.emit(self)

func reactivate_physics():
	sleeping = false
