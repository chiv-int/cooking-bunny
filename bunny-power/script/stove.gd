# The stove — inherits proximity/input handling from Interactable (INHERITANCE)
extends Interactable

var is_transitioning: bool = false

# Override: set label text based on quest state when player approaches
func _on_body_entered(body: Node) -> void:
	super._on_body_entered(body)   # run the base behavior first (shows label)
	if body.is_in_group("player") and has_node("Label"):
		if QuestManager.is_quest_active():
			$Label.text = "press Enter to Cook"
		else:
			$Label.text = "Start the quest first"

# Override: only allow interaction if the quest is active (POLYMORPHISM)
func _can_interact() -> bool:
	return QuestManager.is_quest_active() and not is_transitioning

# Override: define what the stove does on interact (POLYMORPHISM)
func _on_interact() -> void:
	is_transitioning = true
	get_tree().change_scene_to_file("res://scence/kitchen.tscn")
