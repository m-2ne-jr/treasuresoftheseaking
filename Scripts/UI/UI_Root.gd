extends CanvasLayer

@onready var score_label: Label = %ScoreLabel
@onready var time_label: Label = %TimeLabel
@onready var anim_player: AnimationPlayer = %AnimationPlayer

var time_display_minutes: float
var time_display_seconds: float
var time_display_milliseconds: float

var screen_blackout_time: float = 0.75

signal screen_faded
signal screen_cleared

func _ready() -> void:
	GameMaster.score_changed.connect(update_score)
	GameMaster.player_died.connect(fade_screen_out)
	GameMaster.player_respawned.connect(fade_screen_in)
	
	screen_faded.connect(GameMaster.respawn_player)
	screen_cleared.connect(GameMaster.on_death_anim_finished)
	update_score(GameMaster.current_points)
	
func _process(_delta: float) -> void:
	time_display_minutes = floor(fmod(GameMaster.goal_timer.time_left, 3600) / 60)
	time_display_seconds = fmod(GameMaster.goal_timer.time_left, 60)
	time_display_milliseconds = fmod(GameMaster.goal_timer.time_left, 1) * 1000
	
	time_label.text = "%02d:%02d.%03d" % [time_display_minutes, time_display_seconds, time_display_milliseconds]
	
func update_score(value: int):
	score_label.text = "%s / %s" % [value, GameMaster.goal_levels[GameMaster.current_goal].score]

func fade_screen_out():
	anim_player.play("screen_fade_out")
	await anim_player.animation_finished
	screen_faded.emit()
	
func fade_screen_in():
	await get_tree().create_timer(screen_blackout_time).timeout
	anim_player.play("screen_fade_in")
	await anim_player.animation_finished
	screen_cleared.emit()
