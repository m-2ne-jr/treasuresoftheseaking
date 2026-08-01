extends Node3D

enum WaveLength { WAVE_SHORT, WAVE_MEDIUM, WAVE_FULL }

@export var depths: Dictionary[WaveLength, WaveDepth]

@onready var anim_player: AnimationPlayer = %AnimationPlayer
var next_wave_length: WaveLength

func _ready() -> void:
	ErrorHelper.try(SignalBus.game_over.connect(pause_player))
	ErrorHelper.try(SignalBus.game_complete.connect(pause_player))
	await SignalBus.player_ready
	request_wave_anim_length(depths[WaveLength.WAVE_SHORT].animation_name)

func get_next_wave_random() -> void:
	if GameMaster.wave_state == GameMaster.WaveState.WAVE_IN:
		return
	next_wave_length = depths.keys().pick_random()
	GameMaster.current_max_depth = depths[next_wave_length].max_depth
	print_debug(GameMaster.current_max_depth)

func request_next_wave_length() -> void:
	if GameMaster.wave_state == GameMaster.WaveState.WAVE_OUT:
		return
	anim_player.stop(true)
	request_wave_anim_length(depths[next_wave_length].animation_name)

func request_wave_anim_length(anim_name: StringName) -> void:
	anim_player.play(anim_name)
	
func set_wave_state(new_state: GameMaster.WaveState) -> void:
	if GameMaster.wave_state == new_state:
		return
	GameMaster.wave_state = new_state
	print_debug(GameMaster.WaveState.keys()[GameMaster.wave_state])

func go_to_next_wave() -> void:
	if GameMaster.wave_state == GameMaster.WaveState.WAVE_IN:
		return
	GameMaster.current_wave += 1
	print_debug(GameMaster.current_wave)

func pause_player() -> void:
	anim_player.pause.call_deferred()
