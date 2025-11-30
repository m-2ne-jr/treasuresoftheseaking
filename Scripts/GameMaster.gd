extends Node

enum WaveState { WAVE_OUT, WAVE_IN }
var wave_state: WaveState = WaveState.WAVE_OUT
var max_depth = 0

var player_spawn: Marker3D
var player_scene: PackedScene
var player: PlayerController

var carry_limit := 10

var current_points: int:
	set(value):
		current_points = value
		if current_points >= goal_levels[current_goal].score:
			current_points -= goal_levels[current_goal].score
			increase_goal_level()
		SignalBus.score_changed.emit(current_points)

var current_goal: int = 1
var goal_levels: Dictionary[int, GoalLevel] = {
	1: GoalLevel.new(25, 75),
	2: GoalLevel.new(80, 30),
	3: GoalLevel.new(140, 40),
	4: GoalLevel.new(300, 60),
	5: GoalLevel.new(650, 75)
}

var goal_timer: Timer = Timer.new()

var current_wave: int = 0

func _ready() -> void:
	player_spawn = get_node("/root/World/PlayerSpawn")
	player_scene = load("res://Scenes/Characters/PlayerBird.tscn")
	player = player_scene.instantiate() as PlayerController
	get_tree().root.add_child.call_deferred(player)
	respawn_player.call_deferred()
	
	goal_timer.one_shot = true
	add_child(goal_timer)
	goal_timer.start(goal_levels[current_goal].time)
	
	var ui_scene: PackedScene = load("res://Scenes/UIRoot.tscn")
	var ui_object = ui_scene.instantiate()
	get_tree().root.add_child.call_deferred(ui_object)
	
func increase_goal_level():
	current_goal += 1
	goal_timer.start(goal_timer.time_left + goal_levels[current_goal].time)
	SignalBus.goal_level_changed.emit()
	current_points = current_points

func on_player_died():
	SignalBus.player_died.emit()
	
func respawn_player():
	player.global_position = player_spawn.global_position
	SignalBus.player_respawned.emit()

func on_death_anim_finished():
	SignalBus.player_ready.emit()
