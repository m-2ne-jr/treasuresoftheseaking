extends Node

@onready var area: Area3D = %Area3D
var can_pickup := true
signal treasure_picked_up(treasure_object: TreasureObject)

func _ready() -> void:
	ErrorHelper.try(SignalBus.player_died.connect(set_pickup_able.bind(false)))
	ErrorHelper.try(SignalBus.player_ready.connect(set_pickup_able.bind(true)))
	ErrorHelper.try(SignalBus.game_over.connect(set_pickup_able.bind(false)))

func _on_pickup_received(body: Node3D) -> void:
	if !can_pickup:
		return
	if !body is TreasureObject:
		return
	var treasure_object: TreasureObject = body 
	if !treasure_object.can_be_picked_up:
		return
	treasure_picked_up.emit(treasure_object)

func check_for_pickups(treasure_object: TreasureObject) -> void:
	if !can_pickup:
		return
	if !area.overlaps_body(treasure_object):
		return
	treasure_picked_up.emit(treasure_object)

func set_pickup_able(is_active: bool) -> void:
	can_pickup = is_active
