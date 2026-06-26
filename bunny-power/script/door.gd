extends Area2D

var player_nearby = false
var is_transitioning = false

const ENTER_SOUND = preload("res://fx/door_open.MP3")
const EXIT_SOUND = preload("res://fx/door_close.MP3")

func _ready():
	$Label.visible = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		$Label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		$Label.visible = false

func _input(event):
	if event.is_action_pressed("ui_accept") and player_nearby and not is_transitioning:
		is_transitioning = true
		var current = get_tree().current_scene.scene_file_path
		if current == "res://scence/world.tscn":
			AudioManager.play_sound_with_fade(ENTER_SOUND)
			get_tree().change_scene_to_file("res://scence/house_interior.tscn")
		else:
			AudioManager.play_sound_with_fade(EXIT_SOUND, 0.0, 0.2)
			QuestManager.came_from_house = true
			get_tree().change_scene_to_file("res://scence/world.tscn")
