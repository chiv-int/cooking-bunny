# A door — inherits proximity/input handling from Interactable (INHERITANCE)
extends Interactable

var is_transitioning: bool = false

const ENTER_SOUND = preload("res://fx/door_open.MP3")
const EXIT_SOUND = preload("res://fx/door_close.MP3")

# Override: doors are always usable (no quest condition), but block double-trigger
func _can_interact() -> bool:
	return not is_transitioning

# Override: define what the door does — two-way scene transition (POLYMORPHISM)
func _on_interact() -> void:
	is_transitioning = true
	var current = get_tree().current_scene.scene_file_path
	if current == "res://scence/world.tscn":
		AudioManager.play_sound_with_fade(ENTER_SOUND)
		get_tree().change_scene_to_file("res://scence/house_interior.tscn")
	else:
		AudioManager.play_sound_with_fade(EXIT_SOUND, 0.0, 0.2)
		QuestManager.came_from_house = true
		get_tree().change_scene_to_file("res://scence/world.tscn")
