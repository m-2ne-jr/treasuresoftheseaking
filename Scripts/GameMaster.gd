extends Node

enum WaveState { WAVE_OUT, WAVE_IN }
var wave_state: WaveState = WaveState.WAVE_OUT
var max_depth = 0

var is_player_respawning := true

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
	5: GoalLevel.new(650, 75),
	6: GoalLevel.new(999, 80)
}

var goal_timer: Timer = Timer.new()

var current_wave: int = 0

const MAIN_SCENE = preload("res://Scenes/Main.tscn")
const UI_ROOT = preload("res://Scenes/UIRoot.tscn")

func _ready() -> void:
	goal_timer.timeout.connect(on_game_timer_timeout)
	SignalBus.player_ready.connect(check_time_left)
	load_game_scene.call_deferred(true)
	
func load_game_scene(full_load: bool = false):
	get_tree().change_scene_to_packed(MAIN_SCENE)
	await get_tree().scene_changed
	
	if !full_load:
		return
	player_spawn = get_node("/root/World/PlayerSpawn")
	player_scene = load("res://Scenes/Characters/PlayerBird.tscn")
	player = player_scene.instantiate() as PlayerController
	get_tree().root.add_child.call_deferred(player)
	respawn_player.call_deferred()
	
	goal_timer.one_shot = true
	add_child(goal_timer)
	goal_timer.start(goal_levels[current_goal].time)
	
	var ui_scene = UI_ROOT.instantiate()
	get_tree().root.add_child.call_deferred(ui_scene)
	is_player_respawning = false
	SignalBus.player_ready.emit()
	
func increase_goal_level():
	if current_goal == goal_levels.size():
		on_all_goals_complete()
		return
	current_goal += 1
	goal_timer.start(goal_timer.time_left + goal_levels[current_goal].time)
	SignalBus.goal_level_changed.emit()
	current_points = current_points

func on_player_died():
	is_player_respawning = true
	SignalBus.player_died.emit()
	
func respawn_player():
	player_spawn = get_node("/root/World/PlayerSpawn")
	player.global_position = player_spawn.global_position
	SignalBus.player_respawned.emit()

func on_death_anim_finished():
	SignalBus.player_ready.emit()

func check_time_left():
	if is_player_respawning:
		is_player_respawning = false
		return
	if goal_timer.time_left > 0:
		return
	on_game_timer_timeout()
	
func on_game_timer_timeout():
	print_debug("Game over.")
	if is_player_respawning:
		await SignalBus.player_ready
	is_player_respawning = true
	SignalBus.game_over.emit()

func restart_game():
	load_game_scene()
	SignalBus.game_restarted.emit()
	
	current_wave = 0
	current_points = 0
	current_goal = 1
	
	await SignalBus.player_ready
	goal_timer.start(goal_levels[current_goal].time)

func on_all_goals_complete():
	print_debug("Win!")
	if is_player_respawning:
		await SignalBus.player_ready
	goal_timer.stop()
	is_player_respawning = true
	SignalBus.game_complete.emit()
