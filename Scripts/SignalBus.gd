extends Node

@warning_ignore("unused_signal")
signal held_score_changed(value: int)
@warning_ignore("unused_signal")
signal score_changed(value: int)
@warning_ignore("unused_signal")
signal treasure_list_changed(treasure_list: Array[Treasure])
signal carry_count_updated(amount: int)
@warning_ignore("unused_signal")
signal goal_level_changed

@warning_ignore("unused_signal")
signal player_died
@warning_ignore("unused_signal")
signal player_respawned
@warning_ignore("unused_signal")
signal player_ready

@warning_ignore("unused_signal")
signal treasure_acquired(successful: bool)
@warning_ignore("unused_signal")
signal treasure_object_destroyed

func _ready() -> void:
	treasure_list_changed.connect(on_treasure_list_changed)

func on_treasure_list_changed(treasure_list: Array[Treasure]):
	carry_count_updated.emit(treasure_list.size())
