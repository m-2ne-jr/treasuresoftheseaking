class_name TreasureObject
extends RigidBody3D

@onready var hitbox: CollisionShape3D = %Hitbox

@export var treasure: Treasure
var visual_instance: Node3D

var can_be_picked_up: bool = true
var wave_created_on: int = 0
var is_available: bool = true

signal pickup_ready(treasure_object: TreasureObject)

@export_flags_3d_physics var collision_mask_layers: int = 0b100001100

const PICKUP_READY_WAIT_TIME: float = 0.5

func _ready() -> void:
	ErrorHelper.try(SignalBus.treasure_object_cleared.connect(reactivate_physics))


func activate_object(new_treasure: Treasure) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	is_available = false
	treasure = new_treasure
	mass = treasure.weight
	hitbox.shape = treasure.hitbox_shape
	
	visual_instance = treasure.visual_scene.instantiate() as Node3D
	add_child(visual_instance)


func reset_object() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	is_available = true
	
	if visual_instance == null:
		return
	visual_instance.queue_free()


func wait_for_pickup() -> void:
	await get_tree().create_timer(PICKUP_READY_WAIT_TIME).timeout
	can_be_picked_up = true
	collision_mask = collision_mask_layers
	pickup_ready.emit(self)


func reactivate_physics() -> void:
	pass
