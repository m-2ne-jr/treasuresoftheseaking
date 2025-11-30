class_name TreasureSpawner
extends Node3D

@export var treasure_object_scene: PackedScene
@export var spawn_arc_width = 30
	
@export var spawn_force: int = 3
@export var speed_affect_mod: float = 0.5

var drop_force:= 5.0
var drop_treasure_lifetime := 1.0
var torque_force := 1.5

func spawn_treasure_with_force(treasure: Treasure, speed: float):
	var new_object: TreasureObject = setup_treasure_object(treasure)
	get_tree().root.add_child(new_object)
	new_object.animation_player.play("wait_allow_pick_up")
	
	var modified_speed: float = speed * speed_affect_mod
	launch_treasure_object(new_object, modified_speed)

func spawn_treasure_as_drop(treasure: Treasure):
	var new_object: TreasureObject = setup_treasure_object(treasure)
	get_tree().root.add_child(new_object)
	new_object.hitbox.disabled = true
	
	drop_object(new_object)
	await get_tree().create_timer(drop_treasure_lifetime).timeout
	new_object.queue_free()

func setup_treasure_object(treasure: Treasure) -> TreasureObject:
	var treasure_object = treasure_object_scene.instantiate() as TreasureObject
	treasure_object.treasure = treasure
	treasure_object.wave_created_on = GameMaster.current_wave + 1
	treasure_object.can_be_picked_up = false
	treasure_object.collision_mask = 264
	return treasure_object

func launch_treasure_object(treasure_object: TreasureObject, speed: float):
	var new_angle_min = deg_to_rad(-spawn_arc_width * 0.5)
	var new_angle_max = deg_to_rad(spawn_arc_width * 0.5)
	var direction = global_basis.y.rotated(global_basis.z.normalized(), randf_range(new_angle_min, new_angle_max))
	var force = (direction * speed) + (direction * spawn_force)
	
	treasure_object.global_position = global_position
	treasure_object.global_rotation = global_rotation
	treasure_object.apply_central_impulse(force * treasure_object.mass)
	treasure_object.global_rotation.x = randf_range(-1, 1)
	treasure_object.apply_torque_impulse(global_basis.x * torque_force)

func drop_object(treasure_object: TreasureObject):
	var angle := randf_range(-180, 180)
	angle = deg_to_rad(angle)
	var direction := Vector3(sin(angle), 1, cos(angle)).normalized()
	
	treasure_object.global_position = global_position
	treasure_object.look_at(direction)
	treasure_object.apply_central_impulse((direction * drop_force) * treasure_object.mass) 
	treasure_object.apply_torque_impulse(global_basis.x * torque_force)
