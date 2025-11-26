extends Node

signal treasure_picked_up(treasure_object: TreasureObject)
@onready var area: Area3D = %Area3D

func _on_pickup_received(body: Node3D) -> void:
	if !body is TreasureObject:
		return
	var treasure_object = body as TreasureObject
	if !treasure_object.can_be_picked_up:
		return
	treasure_picked_up.emit(treasure_object)

func check_for_pickups(treasure_object: TreasureObject):
	if !area.overlaps_body(treasure_object):
		return
	treasure_picked_up.emit(treasure_object)
