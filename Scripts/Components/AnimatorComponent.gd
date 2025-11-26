class_name AnimatorComponent
extends Node

@onready var anim_tree: AnimationTree = %AnimationTree

func set_movement_state(move_dir: Vector3):
	anim_tree.set("parameters/LegStateMachine/conditions/idle", move_dir == Vector3.ZERO)
	anim_tree.set("parameters/LegStateMachine/conditions/moving", move_dir != Vector3.ZERO)
	
	var state = anim_tree.get("parameters/BodyTransition/current_state")
	var request: String = ""
	
	if state == "pickup" || state == "throw":
		await anim_tree.animation_finished
	
	request = "idle" if move_dir == Vector3.ZERO else "moving"
	if state == request:
		return
	
	set_body_transition_state(request)

func set_active(state := true):
	anim_tree.active = state

func on_treasure_pickup_success():
	set_body_transition_state("pickup")

func on_treasure_drop_success():
	set_body_transition_state("throw")

func set_body_transition_state(request: String):
	anim_tree.set("parameters/BodyTransition/transition_request", request)
