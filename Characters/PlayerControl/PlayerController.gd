class_name PlayerController
extends CharacterBody3D

@onready var cam_pivot: CameraController = %CameraPivot
@onready var skin: Node3D = %Skin

@onready var control_manager: ControlManager = $ControlManager
@onready var animator: AnimatorComponent = %AnimatorComponent
@onready var hitbox_area: Area3D = %HitboxArea
@onready var ragdoll: RagdollComponent = $RagdollComponent

var base_speed: float = 5.0
var max_speed: float
var current_speed: float

var can_act: bool = true

const ACCELERATION: float = 50
const DIR_DEADZONE: float = 0.01

signal treasure_drop_requested(speed: float)

func _ready() -> void:
	ErrorHelper.try(SignalBus.treasure_list_changed.connect(_on_treasure_list_changed))
	ErrorHelper.try(SignalBus.player_respawned.connect(on_player_respawned))
	ErrorHelper.try(SignalBus.player_ready.connect(reset_player.bind(true)))
	ErrorHelper.try(SignalBus.game_over.connect(handle_player_knockout))
	ErrorHelper.try(SignalBus.game_complete.connect(reset_player.bind(false)))
	
	max_speed = base_speed


func _physics_process(delta: float) -> void:
	var input_dir: Vector2 = get_input_direction()
	var direction: Vector3 = get_movement_direction(input_dir)
	animator.set_movement_state(direction)
	current_speed = get_current_velocity(direction, delta)
	cam_pivot.follow_target(self)
	
	if !can_act:
		return
	
	move_and_slide()
	
	if direction.length() > DIR_DEADZONE:
		rotate_skin_to_direction(Vector2(direction.x, direction.z))


func get_input_direction() -> Vector2:
	if !can_act:
		return Vector2.ZERO
	return control_manager.get_movement_schema_input(control_manager.current_scheme)


func get_movement_direction(input: Vector2) -> Vector3:
	var right: Vector3 = cam_pivot.global_basis.x
	var forward: Vector3 = cam_pivot.global_basis.z
	
	var direction: Vector3 = input.x * right + input.y * forward
	direction.y = 0
	return direction.normalized()


func get_current_velocity(direction: Vector3, delta: float) -> float:
	var cached_y_velocity: float = velocity.y
	velocity.y = 0
	velocity = velocity.move_toward(direction * max_speed, delta * ACCELERATION)
	velocity.y = cached_y_velocity + get_gravity().y * delta
	
	return velocity.length()


func rotate_skin_to_direction(dir: Vector2) -> void:
		const SKIN_ROT_OFFSET_DEG := 90
		const SKIN_ROT_LERP_WEIGHT := 0.25
		
		var flipped_direction: Vector2 = Vector2(-dir.x, dir.y)
		var angle_degrees: float = rad_to_deg(flipped_direction.angle())
		
		# Have to offset skin Y rotation by 90 degrees to face the right way.
		# Possible Blender issue? 
		var new_rotation: float = deg_to_rad(angle_degrees - SKIN_ROT_OFFSET_DEG)
		skin.global_rotation.y = lerp_angle(
			skin.global_rotation.y,
			new_rotation,
			SKIN_ROT_LERP_WEIGHT
		)


func _input(event: InputEvent) -> void:
	const MAGNITUDE: float = 0.05
	
	cam_pivot.rotate_camera(
		control_manager.get_camera_schema_input(
			control_manager.current_scheme,
			event
		) * MAGNITUDE
	)


func _unhandled_input(event: InputEvent) -> void:
	if !can_act:
		return
	if event.is_action_released("drop_treasure"):
		treasure_drop_requested.emit(current_speed)

	
func _on_treasure_list_changed(treasure_list: Array[Treasure]) -> void:
	var speed_mod: float = get_speed_modifier(treasure_list)
	max_speed = base_speed * speed_mod
	
	
func get_speed_modifier(treasure_list: Array[Treasure]) -> float:
	const WEIGHT_FACTOR := 0.1
	var total_mod: float = 1
	
	for treasure: Treasure in treasure_list:
		total_mod *= 1 - (WEIGHT_FACTOR * log(treasure.weight + 1))
	print_debug(total_mod)
	return total_mod


func _on_carry_limit_reached(is_maxed: bool) -> void:
	const MASK_NO_TREASURE := 266
	const MASK_TREASURE := 270
	
	# You want treasure collision active when maxed out.
	collision_mask = MASK_TREASURE if is_maxed else MASK_NO_TREASURE


func _on_hitbox_area_entered(_area: Area3D) -> void:
	die()


func die() -> void:
	handle_player_knockout()
	GameMaster.on_player_died()
	
	
func handle_player_knockout() -> void:
	hitbox_area.shape_owner_set_disabled(hitbox_area.get_index(), true)
	animator.set_active(false)
	can_act = false
	
	SoundManager.play_sound(SoundManager.SFX_LIB[SoundManager.SFX_LIST.SFX_PLAYER_DIE])
	
	ragdoll.reparent_to_ragdoll(skin)
	ragdoll.activate_ragdoll()
	
	
func on_player_respawned() -> void:
	ragdoll.reset()
	skin.reparent(self)
	skin.global_rotation = Vector3.ZERO
	animator.set_active()


func reset_player(is_active: bool) -> void:
	hitbox_area.shape_owner_set_disabled(hitbox_area.get_index(), false)
	can_act = is_active
