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

signal treasure_drop_requested(speed: float)

func _ready() -> void:
	SignalBus.treasure_list_changed.connect(_on_treasure_list_changed)
	SignalBus.player_respawned.connect(on_player_respawned)
	SignalBus.player_ready.connect(on_player_ready)
	SignalBus.game_over.connect(on_game_over)
	SignalBus.game_complete.connect(on_game_complete)
	
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
	
	if direction.length() > 0.01:
		rotate_skin_to_direction(Vector2(direction.x, direction.z))

func rotate_skin_to_direction(dir: Vector2):
		var flipped_direction = Vector2(-dir.x, dir.y)
		var angle_degrees = rad_to_deg(flipped_direction.angle())
		
		var new_rotation = deg_to_rad(angle_degrees - 90)
		skin.global_rotation.y = lerp_angle(skin.global_rotation.y, new_rotation, 0.25)

func _unhandled_input(event: InputEvent) -> void:
	if !can_act:
		return
	if event.is_action_released("drop_treasure"):
		treasure_drop_requested.emit(current_speed)
	
func _on_treasure_list_changed(treasure_list: Array[Treasure]) -> void:
	var speed_mod: float = get_speed_modifier(treasure_list)
	max_speed = base_speed * speed_mod
	
func get_speed_modifier(treasure_list: Array[Treasure]) -> float:
	var total_mod: float = 1
	
	for treasure: Treasure in treasure_list:
		total_mod *= 1 - (0.1 * log(treasure.weight + 1))
	print_debug(total_mod)
	return total_mod

func _on_carry_limit_reached(is_maxed: bool) -> void:
	collision_mask = 270 if is_maxed else 266

func _on_hitbox_area_entered(_area: Area3D) -> void:
	die()

func die():
	print_debug("Died.")
	handle_player_knockout()
	GameMaster.on_player_died()
	
func handle_player_knockout():
	hitbox_area.shape_owner_set_disabled(hitbox_area.get_index(), true)
	animator.set_active(false)
	can_act = false
	
	ragdoll.reparent_to_ragdoll(skin)
	ragdoll.activate_ragdoll()
	
func on_player_respawned():
	ragdoll.reset()
	skin.reparent(self)
	skin.global_rotation.y = 0
	animator.set_active()

func on_player_ready():
	hitbox_area.shape_owner_set_disabled(hitbox_area.get_index(), false)
	can_act = true

func on_game_over():
	handle_player_knockout()

func on_game_complete():
	hitbox_area.shape_owner_set_disabled(hitbox_area.get_index(), false)
	can_act = false
