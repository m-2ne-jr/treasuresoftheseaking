class_name PlayerController
extends CharacterBody3D

@onready var cam_pivot: Node3D = %CameraPivot
@onready var skin: Node3D = %Skin

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
	SignalBus.treasure_list_changed.connect(_on_treasure_list_changed)
	SignalBus.player_respawned.connect(on_player_respawned)
	SignalBus.player_ready.connect(reset_player.bind(true))
	SignalBus.game_over.connect(handle_player_knockout)
	SignalBus.game_complete.connect(reset_player.bind(false))
	
	max_speed = base_speed


func _physics_process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if can_act:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	var right = cam_pivot.global_basis.x
	var forward = cam_pivot.global_basis.z
	
	var direction: Vector3 = input_dir.x * right + input_dir.y * forward
	direction.y = 0
	direction = direction.normalized()
		
	var y_velocity = velocity.y
	velocity.y = 0
	velocity = velocity.move_toward(direction * max_speed, delta * ACCELERATION)
	velocity.y = y_velocity + get_gravity().y * delta
	
	current_speed = velocity.length()
	
	move_and_slide()
	animator.set_movement_state(direction)
	
	if direction.length() > DIR_DEADZONE:
		rotate_skin_to_direction(Vector2(direction.x, direction.z))


func rotate_skin_to_direction(dir: Vector2):
		const SKIN_ROT_OFFSET_DEG := 90
		const SKIN_ROT_LERP_WEIGHT := 0.25
		
		var flipped_direction = Vector2(-dir.x, dir.y)
		var angle_degrees = rad_to_deg(flipped_direction.angle())
		
		# Have to offset skin Y rotation by 90 degrees to face the right way.
		# Possible Blender issue? 
		var new_rotation = deg_to_rad(angle_degrees - SKIN_ROT_OFFSET_DEG)
		skin.global_rotation.y = lerp_angle(
			skin.global_rotation.y,
			new_rotation,
			SKIN_ROT_LERP_WEIGHT
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


func die():
	handle_player_knockout()
	GameMaster.on_player_died()
	
	
func handle_player_knockout():
	hitbox_area.shape_owner_set_disabled(hitbox_area.get_index(), true)
	animator.set_active(false)
	can_act = false
	
	SoundManager.play_sound(SoundManager.SFX_LIB[SoundManager.SFX_LIST.SFX_PLAYER_DIE])
	
	ragdoll.reparent_to_ragdoll(skin)
	ragdoll.activate_ragdoll()
	
	
func on_player_respawned():
	ragdoll.reset()
	skin.reparent(self)
	skin.global_rotation = Vector3.ZERO
	animator.set_active()


func reset_player(is_active: bool):
	hitbox_area.shape_owner_set_disabled(hitbox_area.get_index(), false)
	can_act = is_active
