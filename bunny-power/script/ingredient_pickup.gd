# An ingredient pickup — inherits proximity/input from Interactable (INHERITANCE)
extends Interactable

@export var ingredient_name: String = "carrot"

# Override: extra setup hook called by the base _ready() (TEMPLATE METHOD pattern)
func _on_ready() -> void:
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("IDLE")

# Override: collect the ingredient and remove this pickup (POLYMORPHISM)
func _on_interact() -> void:
	QuestManager.collect_ingredient(ingredient_name)
	queue_free()
