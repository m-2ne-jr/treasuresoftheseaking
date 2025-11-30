extends CanvasLayer

@onready var score_label: Label = %ScoreLabel
@onready var time_label: Label = %TimeLabel
@onready var current_score_label: Label = %CurrentScoreLabel
@onready var carry_count_label: Label = %CarryCountLabel

@onready var screen_fade_animator: AnimationPlayer = %ScreenFadeAnimator

@onready var carry_label_animator: AnimationPlayer = %CarryLabelAnimator

var time_display_minutes: float
var time_display_seconds: float
var time_display_milliseconds: float

var screen_blackout_time: float = 0.75

signal screen_faded
signal screen_cleared

func _ready() -> void:
	SignalBus.score_changed.connect(update_score)
	SignalBus.held_score_changed.connect(update_current_score)
	SignalBus.carry_count_updated.connect(update_carry_count)
	SignalBus.treasure_acquired.connect(on_treasure_get_success)
	
	SignalBus.player_died.connect(fade_screen_out)
	SignalBus.player_respawned.connect(fade_screen_in)
	
	screen_faded.connect(GameMaster.respawn_player)
	screen_cleared.connect(GameMaster.on_death_anim_finished)
	
	update_score(GameMaster.current_points)
	update_current_score(0)
	update_carry_count(0)
	
func _process(_delta: float) -> void:
	time_display_minutes = floor(fmod(GameMaster.goal_timer.time_left, 3600) / 60)
	time_display_seconds = fmod(GameMaster.goal_timer.time_left, 60)
	time_display_milliseconds = fmod(GameMaster.goal_timer.time_left, 1) * 1000
	
	time_label.text = "%02d:%02d.%03d" % [time_display_minutes, time_display_seconds, time_display_milliseconds]
	
func update_score(value: int):
	score_label.text = "%s / %s" % [value, GameMaster.goal_levels[GameMaster.current_goal].score]

func update_current_score(value: int):
	current_score_label.text = "+ %s" % value

func update_carry_count(amount: int):
	carry_count_label.text = "%s / %s" % [amount, GameMaster.carry_limit]

func on_treasure_get_success(was_successful: bool):
	if was_successful:
		return
	carry_label_animator.play("flash_carry_label")
	
func fade_screen_out():
	screen_fade_animator.play("screen_fade_out")
	await screen_fade_animator.animation_finished
	screen_faded.emit()
	
func fade_screen_in():
	await get_tree().create_timer(screen_blackout_time).timeout
	screen_fade_animator.play("screen_fade_in")
	await screen_fade_animator.animation_finished
	screen_cleared.emit()
