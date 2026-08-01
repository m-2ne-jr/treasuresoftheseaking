extends Node

enum BGM_LIST {
	BGM_GAME_OVER,
	BGM_GAME_COMPLETE,
}

enum SFX_LIST {
	SFX_PLAYER_DIE,
	SFX_TREASURE_PICKUP,
	SFX_TREASURE_DROP,
	SFX_TREASURE_MAX_CAPACITY,
	SFX_TREASURE_BANK_SINGLE,
	SFX_TREASURE_BANK_ALL,
	SFX_GOAL_REACHED,
	SFX_WAVE,
}

const BGM_LIB: Dictionary[BGM_LIST, AudioStream] = {
	BGM_LIST.BGM_GAME_OVER: preload("uid://t14tiaqiaxxe"),
	BGM_LIST.BGM_GAME_COMPLETE: preload("uid://c4e3bxo3tgkjd"),
}

const SFX_LIB: Dictionary[SFX_LIST, AudioStream] = {
	SFX_LIST.SFX_PLAYER_DIE: preload("uid://b1rvi33x3ay6o"),
	SFX_LIST.SFX_TREASURE_PICKUP: preload("uid://b24vm6jch16jy"),
	SFX_LIST.SFX_TREASURE_DROP: preload("uid://crny27out32b0"),
	SFX_LIST.SFX_TREASURE_MAX_CAPACITY: preload("uid://cuqw88y2qe8rm"),
	SFX_LIST.SFX_TREASURE_BANK_SINGLE: preload("uid://d3qsu5lvpprp7"),
	SFX_LIST.SFX_TREASURE_BANK_ALL: preload("uid://of0ehtrwqpxc"),
	SFX_LIST.SFX_GOAL_REACHED: preload("uid://cr27wiey5ukh3"),
	SFX_LIST.SFX_WAVE: preload("uid://b7sifqmhngdo"),
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
	ErrorHelper.try(SignalBus.game_over.connect(stop_bgm))
	
	add_child(_bgm_player)
	_bgm_player.volume_db = _default_volume_bgm
	
	add_child(_wave_stream_player)
	add_child(_wave_timer)
	ErrorHelper.try(_wave_timer.timeout.connect(play_wave_sound))
	
	play_wave_sound.call_deferred()


func play_sound(sound: AudioStream, set_single_instance: bool = false) -> void:
	var sfx_player := AudioStreamPlayer.new()
	if _audio_instance != null and set_single_instance:
		return
	add_child(sfx_player)
	if set_single_instance:
		_audio_instance = sfx_player
	
	sfx_player.stream = sound
	sfx_player.volume_db = _default_volume_sfx
	ErrorHelper.try(sfx_player.finished.connect(sfx_player.queue_free))
	
	sfx_player.play()


func play_wave_sound() -> void:
	_wave_stream_player.stream = SFX_LIB[SFX_LIST.SFX_WAVE]
	_wave_stream_player.volume_db = _wave_volume
	_wave_stream_player.play()
	
	var wave_time: float = randf_range(_min_wave_time, _max_wave_time)
	_wave_timer.start(wave_time)


func play_bgm(bgm: AudioStream) -> void:
	_bgm_player.stream = bgm
	_bgm_player.play()


func stop_bgm() -> void:
	_bgm_player.stop()
