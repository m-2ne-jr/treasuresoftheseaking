extends Node3D

@export var cam_offset: float = 0.33
@export var senstivity: float = 3
@export var interpolation_speed: float = 0.25

var can_move: bool

const CAMERA_MARGIN = 0.01
const CAMERA_Y_MIN_DEG := -60
const CAMERA_Y_MAX_DEG := 30

func _ready() -> void:
	position = (get_parent() as Node3D).position + Vector3(0, cam_offset, 0)
	
	ErrorHelper.try(SignalBus.player_respawned.connect(set_camera_movement.bind(false)))
	ErrorHelper.try(SignalBus.player_ready.connect(set_camera_movement.bind(true)))
	ErrorHelper.try(SignalBus.game_over.connect(set_camera_movement.bind(false)))
	
	set_camera_movement.call_deferred(true)
	
func _physics_process(_delta: float) -> void:
	var input_x := 0.0
	var input_y := 0.0
	
	if can_move:
		input_x = Input.get_axis("camera_up", "camera_down")
		input_y = Input.get_axis("camera_left", "camera_right")
	
	if input_x || input_y:
		var clamped_x: float = clampf(
			global_rotation_degrees.x + input_x * senstivity,
			CAMERA_Y_MIN_DEG, 
			CAMERA_Y_MAX_DEG
		)
		global_rotation.x = deg_to_rad(clamped_x)
		global_rotation.y += deg_to_rad(input_y * senstivity)

	var offsetPos: Vector3 = Vector3(0, cam_offset, 0)
	var parent: Node3D = get_parent()
	if position.distance_to(parent.position + offsetPos) > CAMERA_MARGIN:
		position = position.lerp(parent.position + offsetPos, interpolation_speed)

func set_camera_movement(state: bool) -> void:
	can_move = state
