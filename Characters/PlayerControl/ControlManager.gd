class_name ControlManager
extends Node

enum Schema {
	KEYBOARD_HYBRID,
	KEYBOARD_ONLY,
	MOUSE_ONLY
}

const DEFAULT_SCHEME = Schema.KEYBOARD_HYBRID
var current_scheme: Schema:
	set(new_scheme):
		match new_scheme:
			Schema.KEYBOARD_HYBRID:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			Schema.KEYBOARD_ONLY:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Schema.MOUSE_ONLY:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

var keyboard_move_vector: Vector2:
	get: return _get_keyboard_move_input()

var camera_move_vector: Vector2:
	get: return _get_camera_move_input()

var mouse_button_vector: Vector2:
	get: return _get_both_mouse_buttons()

func _ready() -> void:
	current_scheme = DEFAULT_SCHEME


func get_movement_schema_input(control_scheme: Schema) -> Vector2:
	match control_scheme:
		Schema.KEYBOARD_HYBRID:
			return keyboard_move_vector
		Schema.KEYBOARD_ONLY:
			return keyboard_move_vector
		Schema.MOUSE_ONLY:
			return mouse_button_vector
	return Vector2.ZERO


func get_camera_schema_input(control_scheme: Schema, event: InputEvent) -> Vector2:
	match control_scheme:
		Schema.KEYBOARD_HYBRID:
			return _get_mouse_from_screen(event)
		Schema.KEYBOARD_ONLY:
			return camera_move_vector
		Schema.MOUSE_ONLY:
			return _get_mouse_from_screen(event)
	return Vector2.ZERO


func _get_keyboard_move_input() -> Vector2:
	return Input.get_vector(
		&"move_left",
		&"move_right",
		&"move_forward",
		&"move_backward"
	)


func _get_camera_move_input() -> Vector2:
	return Input.get_vector(
		&"camera_up",
		&"camera_down",
		&"camera_left",
		&"camera_right"
	)


func _get_both_mouse_buttons() -> Vector2:
	var mask: int = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT
	if (Input.get_mouse_button_mask() & mask) != mask:
		return Vector2.ZERO
	return Vector2.UP


func _get_mouse_from_screen(event: InputEvent) ->  Vector2:
	if !(event is InputEventMouseMotion):
		return Vector2.ZERO
	var screen_vector: Vector2 = (event as InputEventMouseMotion).screen_relative
	return Vector2(screen_vector.y, screen_vector.x) * -1
	
