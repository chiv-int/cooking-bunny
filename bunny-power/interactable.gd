# Base class for all player-interactable objects in the world.
# Handles proximity detection + the "press Enter to interact" pattern.
# Subclasses override _on_interact() to define what happens.
class_name Interactable
extends Area2D

var player_nearby: bool = false

func _ready() -> void:
	if has_node("Label"):
		$Label.visible = false
	_on_ready()   # let subclasses do extra setup

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		if has_node("Label"):
			$Label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		if has_node("Label"):
			$Label.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and player_nearby:
		if _can_interact():
			_on_interact()

# --- Methods meant to be OVERRIDDEN by subclasses (POLYMORPHISM) ---

# Override to define what the interaction does
func _on_interact() -> void:
	pass

# Override to add conditions (e.g. quest must be active)
func _can_interact() -> bool:
	return true

# Override for extra setup in _ready
func _on_ready() -> void:
	pass
