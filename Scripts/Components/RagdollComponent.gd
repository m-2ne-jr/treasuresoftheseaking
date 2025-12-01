class_name RagdollComponent
extends Node3D

@onready var ragdoll_container: RigidBody3D = %RagdollContainer

var is_ragdoll_active := false

var vertical_force := 0.9
var horizontal_force := 0.3
var torque := 0.03

func  _ready() -> void:
	reset()

func reparent_to_ragdoll(node: Node3D):
	if is_ragdoll_active:
		return
	node.reparent(ragdoll_container)

func get_impulse_from_angle(angle: float) -> Vector3:
	return Vector3(sin(angle), 0, cos(angle))

func activate_ragdoll():
	if is_ragdoll_active:
		return
	is_ragdoll_active = true
	ragdoll_container.process_mode = Node.PROCESS_MODE_INHERIT
	
	var impusle_angle := randf_range(-180, 180)
	var impulse_direction := get_impulse_from_angle(deg_to_rad(impusle_angle))
	var impulse:= (Vector3.UP * vertical_force) + (impulse_direction * horizontal_force)
	ragdoll_container.apply_central_impulse(impulse)
	
	var torque_angle := randf_range(-180, 180)
	var torque_direction := get_impulse_from_angle(deg_to_rad(torque_angle))
	ragdoll_container.apply_torque_impulse(torque_direction * torque)

func reset():
	ragdoll_container.process_mode = Node.PROCESS_MODE_DISABLED
	ragdoll_container.linear_velocity = Vector3.ZERO
	ragdoll_container.angular_velocity = Vector3.ZERO
	
	ragdoll_container.global_position = global_position
	ragdoll_container.rotation = global_rotation
	is_ragdoll_active = false
