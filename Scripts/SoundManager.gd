extends Node

var music_library: Dictionary[StringName, AudioStream] = {
	&"bgm_game_over": preload("res://Assets/Audio/BGM/bgm_game_over.ogg"),
	&"bgm_game_complete": preload("res://Assets/Audio/BGM/bgm_game_complete.ogg")
}

var sound_library: Dictionary[StringName, AudioStream] = {
	&"sfx_player_die": preload("res://Assets/Audio/SFX/player_knockout.ogg"),
	&"sfx_treasure_pickup": preload("res://Assets/Audio/SFX/treasure_get.ogg"),
	&"sfx_treasure_drop": preload("res://Assets/Audio/SFX/treasure_throw.ogg"),
	&"sfx_treasure_max_capacity": preload("res://Assets/Audio/SFX/treasure_max_capacity.ogg"),
	&"sfx_treasure_bank_single": preload("res://Assets/Audio/SFX/treasure_cashout_single.ogg"),
	&"sfx_treasure_bank_all": preload("res://Assets/Audio/SFX/treasure_cashout_all.ogg"),
	
	&"sfx_goal_reached": preload("res://Assets/Audio/SFX/goal_reached.ogg")
}

var _bgm_player := AudioStreamPlayer.new()
var _default_volume_bgm := -24.0

var _audio_instance: AudioStreamPlayer
var _default_volume_sfx := -24.0

var _wave_stream_player := AudioStreamPlayer.new()
var _wave_volume := -28.0
var _min_wave_time := 5.0
var _max_wave_time := 9.0
var _wave_timer := Timer.new()

func _ready() -> void:
	SignalBus.game_over.connect(stop_bgm)
	
	add_child(_bgm_player)
	_bgm_player.volume_db = _default_volume_bgm
	
	add_child(_wave_stream_player)
	add_child(_wave_timer)
	_wave_timer.timeout.connect(play_wave_sound)
	
	play_wave_sound.call_deferred()

func play_sound(sound: AudioStream, set_single_instance: bool = false):
	var sfx_player := AudioStreamPlayer.new()
	if _audio_instance != null and set_single_instance:
		return
	add_child(sfx_player)
	if set_single_instance:
		_audio_instance = sfx_player
	
	sfx_player.stream = sound
	sfx_player.volume_db = _default_volume_sfx
	sfx_player.finished.connect(sfx_player.queue_free)
	
	sfx_player.play()

func play_wave_sound():
	_wave_stream_player.stream = preload("res://Assets/Audio/SFX/wave.ogg")
	_wave_stream_player.volume_db = _wave_volume
	_wave_stream_player.play()
	
	var wave_time = randf_range(_min_wave_time, _max_wave_time)
	_wave_timer.start(wave_time)

func play_bgm(bgm: AudioStream):
	_bgm_player.stream = bgm
	_bgm_player.play()

func stop_bgm():
	_bgm_player.stop()
