class_name WeightedTreasure
extends Resource

@export var treasure: Treasure
@export var weight: float

var low_bound: int
var high_bound: int

func get_normalized_weight(total: float) -> int:
	return floori((weight / total) * 100)
