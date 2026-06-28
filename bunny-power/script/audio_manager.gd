extends Node

var music_player: AudioStreamPlayer
const GAME_MUSIC = preload("res://fx/lofi.ogg")  # adjust to your filename
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)

	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.stream = GAME_MUSIC
	music_player.volume_db = -10.0   # quieter than SFX so it doesn't overpower
	music_player.play()

func play_sound(stream: AudioStream) -> void:
	sfx_player.stream = stream
	sfx_player.volume_db = 0.0
	sfx_player.play()

func play_sound_with_fade(stream: AudioStream, fade_start_delay: float = 0.1, fade_time: float = 0.5) -> void:
	sfx_player.stream = stream
	sfx_player.volume_db = 0.0
	sfx_player.play()
	await get_tree().create_timer(fade_start_delay).timeout
	var tween = create_tween()
	tween.tween_property(sfx_player, "volume_db", -80.0, fade_time)
	await tween.finished
	sfx_player.stop()
	sfx_player.volume_db = 0.0
