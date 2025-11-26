extends Node3D

@export var cam_offset: float = 0.33
@export var senstivity: float = 3
@export var interpolation_speed: float = 0.25

var can_move: bool

const CAMERA_MARGIN = 0.01

func _ready() -> void:
	position = get_parent().position + Vector3(0, cam_offset, 0)
	
	GameMaster.player_respawned.connect(toggle_camera_movement.bind(false))
	GameMaster.player_ready.connect(toggle_camera_movement.bind(true))
	toggle_camera_movement.call_deferred(true)
	
func _physics_process(_delta: float) -> void:
	var input_x := 0.0
	var input_y := 0.0
	
	if can_move:
		input_x = Input.get_axis("camera_up", "camera_down")
		input_y = Input.get_axis("camera_left", "camera_right")
	
	if input_x || input_y:
		var clamped_x = clamp(global_rotation_degrees.x + input_x * senstivity, -60, 30)
		global_rotation.x = deg_to_rad(clamped_x)
		global_rotation.y += deg_to_rad(input_y * senstivity)

	var offsetPos = Vector3(0, cam_offset, 0)
	if position.distance_to(get_parent().position + offsetPos) > CAMERA_MARGIN:
		position = position.lerp(get_parent().position + offsetPos, interpolation_speed)

func toggle_camera_movement(state: bool):
	can_move = state
