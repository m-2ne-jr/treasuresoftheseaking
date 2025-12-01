extends Node

var sound_library: Dictionary[StringName, AudioStream] = {
	&"sfx_player_die": preload("res://Assets/Audio/SFX/player_knockout.ogg"),
	&"sfx_treasure_pickup": preload("res://Assets/Audio/SFX/treasure_get.ogg"),
	&"sfx_treasure_drop": preload("res://Assets/Audio/SFX/treasure_throw.ogg"),
	&"sfx_treasure_max_capacity": preload("res://Assets/Audio/SFX/treasure_max_capacity.ogg"),
	&"sfx_treasure_bank_single": preload("res://Assets/Audio/SFX/treasure_cashout_single.ogg"),
	&"sfx_treasure_bank_all": preload("res://Assets/Audio/SFX/treasure_cashout_all.ogg"),
	
	&"sfx_goal_reached": preload("res://Assets/Audio/SFX/goal_reached.ogg")
}

var _audio_instance: AudioStreamPlayer

var _default_volume := -12.0

var _wave_stream_player := AudioStreamPlayer.new()
var _wave_volume := -16.0
var _min_wave_time := 5.0
var _max_wave_time := 9.0
var _wave_timer := Timer.new()

func _ready() -> void:
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
	sfx_player.volume_db = _default_volume
	sfx_player.finished.connect(sfx_player.queue_free)
	
	sfx_player.play()

func play_wave_sound():
	_wave_stream_player.stream = preload("res://Assets/Audio/SFX/wave.ogg")
	_wave_stream_player.volume_db = _wave_volume
	_wave_stream_player.play()
	
	var wave_time = randf_range(_min_wave_time, _max_wave_time)
	_wave_timer.start(wave_time)
