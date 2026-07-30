extends Area3D

@onready var footstep_sound_player: AudioStreamPlayer = %FootstepSoundPlayer

@export var minimum_pitch := 0.8
@export var maximum_pitch := 1.1

func _on_terrain_step(_body: Node3D) -> void:
	if GameMaster.is_player_respawning:
		return
	
	footstep_sound_player.pitch_scale = randf_range(minimum_pitch, maximum_pitch)
	footstep_sound_player.play()
