class_name RagdollComponent
extends Node3D

@onready var ragdoll_container: RigidBody3D = %RagdollContainer

var is_ragdoll_active := false

const VERTICAL_FORCE := 0.9
const HORIZONTAL_FORCE := 0.3
const TORQUE := 0.03
const ANGLE_MIN_DEG := -180
const ANGLE_MAX_DEG := 180

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
	
	var impusle_angle := randf_range(ANGLE_MIN_DEG, ANGLE_MAX_DEG)
	var impulse_direction := get_impulse_from_angle(deg_to_rad(impusle_angle))
	var impulse:= (Vector3.UP * VERTICAL_FORCE) + (impulse_direction * HORIZONTAL_FORCE)
	ragdoll_container.apply_central_impulse(impulse)
	
	var torque_angle := randf_range(ANGLE_MIN_DEG, ANGLE_MAX_DEG)
	var torque_direction := get_impulse_from_angle(deg_to_rad(torque_angle))
	ragdoll_container.apply_torque_impulse(torque_direction * TORQUE)

func reset():
	ragdoll_container.process_mode = Node.PROCESS_MODE_DISABLED
	ragdoll_container.linear_velocity = Vector3.ZERO
	ragdoll_container.angular_velocity = Vector3.ZERO
	
	ragdoll_container.global_position = global_position
	ragdoll_container.rotation = global_rotation
	is_ragdoll_active = false
