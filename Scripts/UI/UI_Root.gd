extends CanvasLayer

@onready var score_label: Label = %ScoreLabel
@onready var time_label: Label = %TimeLabel
@onready var current_score_label: Label = %CurrentScoreLabel
@onready var carry_count_label: Label = %CarryCountLabel

@onready var screen_animator: AnimationPlayer = %ScreenAnimator
@onready var carry_label_animator: AnimationPlayer = %CarryLabelAnimator

var time_display_minutes: float
var time_display_seconds: float
var time_display_milliseconds: float

var screen_blackout_time: float = 0.75

var anim_just_finished: StringName

signal screen_faded
signal screen_cleared

func _ready() -> void:
	SignalBus.score_changed.connect(update_score)
	SignalBus.held_score_changed.connect(update_current_score)
	SignalBus.carry_count_updated.connect(update_carry_count)
	SignalBus.treasure_acquired.connect(on_treasure_get_state)
	
	SignalBus.player_died.connect(fade_screen_out)
	SignalBus.player_respawned.connect(fade_screen_in)
	SignalBus.game_over.connect(on_game_over)
	SignalBus.game_complete.connect(on_game_complete)
	
	screen_faded.connect(GameMaster.respawn_player)
	screen_cleared.connect(GameMaster.on_death_anim_finished)
	
	screen_animator.animation_finished.connect(set_anim_just_finished)
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

func on_treasure_get_state(was_successful: bool):
	if was_successful:
		return
	carry_label_animator.play("flash_carry_label")
	
func fade_screen_out():
	screen_animator.play("screen_fade_out")
	await screen_animator.animation_finished
	if anim_just_finished != "screen_fade_out":
		return
	screen_faded.emit()
	
func fade_screen_in():
	await get_tree().create_timer(screen_blackout_time).timeout
	screen_animator.play("screen_fade_in")
	await screen_animator.animation_finished
	if anim_just_finished != "screen_fade_in":
		return
	screen_cleared.emit()

func on_game_over():
	screen_animator.play("game_over")

func play_game_over_bgm():
	SoundManager.play_bgm(SoundManager.music_library["bgm_game_over"])
	
func on_game_complete():
	screen_animator.play("game_complete")

func play_game_complete_bgm():
	SoundManager.play_bgm(SoundManager.music_library["bgm_game_complete"])
	

func _on_game_over_restart_button_pressed() -> void:
	GameMaster.restart_game()
	screen_animator.play("game_over_restart")
	await screen_animator.animation_finished
	if anim_just_finished != "game_over_restart":
		_on_game_over_restart_button_pressed()
	GameMaster.respawn_player.call_deferred()

func _on_game_complete_restart_button_pressed() -> void:
	screen_animator.play("game_complete_restart")
	await screen_animator.animation_finished
	if anim_just_finished != "game_complete_restart":
		_on_game_complete_restart_button_pressed()
	GameMaster.restart_game()
	await get_tree().create_timer(screen_blackout_time).timeout
	GameMaster.respawn_player.call_deferred()

func set_anim_just_finished(anim_name: StringName):
	anim_just_finished = anim_name
