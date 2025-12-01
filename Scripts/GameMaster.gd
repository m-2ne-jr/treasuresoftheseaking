extends Node

enum WaveState { WAVE_OUT, WAVE_IN }
var wave_state: WaveState = WaveState.WAVE_OUT
var max_depth = 0

var is_player_respawning := true
var is_game_time_active := false
var is_treasure_spawning: bool

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
	6: GoalLevel.new(999, 85)
}

var goal_timer: Timer = Timer.new()

var current_wave: int = 0

const MAIN_SCENE = preload("res://Scenes/Main.tscn")
const UI_ROOT = preload("res://Scenes/UIRoot.tscn")

func _ready() -> void:
	goal_timer.timeout.connect(on_game_timer_timeout)
	SignalBus.player_ready.connect(check_time_left)
	SignalBus.treasures_being_spawned.connect(set_treasures_spawning)
	load_game_scene.call_deferred(true)
	
func load_game_scene(full_load: bool = false):
	if is_treasure_spawning:
		await SignalBus.treasures_being_spawned
	
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
	is_game_time_active = true
	is_player_respawning = false
	SignalBus.player_ready.emit()
	
func increase_goal_level():
	if current_goal == goal_levels.size():
		on_all_goals_complete()
		return
	
	current_goal += 1
	goal_timer.start(goal_timer.time_left + goal_levels[current_goal].time)
	SignalBus.goal_level_changed.emit()
	
	SoundManager.play_sound(SoundManager.sound_library["sfx_goal_reached"], true)
	
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
	if !is_game_time_active:
		return
	if goal_timer.time_left > 0:
		return
	on_game_timer_timeout()
	
func on_game_timer_timeout():
	print_debug("Game over.")
	set_game_end_flags()
	SignalBus.game_over.emit()

func on_all_goals_complete():
	print_debug("Win!")
	set_game_end_flags()
	SignalBus.game_complete.emit()

func set_game_end_flags():
	if is_player_respawning:
		await SignalBus.player_ready
	goal_timer.stop()
	is_player_respawning = true
	is_game_time_active = false
	
func restart_game():
	load_game_scene()
	await Engine.get_main_loop().process_frame
	SignalBus.game_restarted.emit()
	
	current_wave = 0
	current_goal = 1
	current_points = 0
	
	await SignalBus.player_ready
	goal_timer.start(goal_levels[current_goal].time)
	is_game_time_active = true

func set_treasures_spawning(state: bool):
	is_treasure_spawning = state
