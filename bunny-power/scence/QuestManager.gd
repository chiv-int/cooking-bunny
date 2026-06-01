# QuestManager.gd
extends Node

signal quest_started
signal ingredient_collected(ingredient_name: String)
signal all_ingredients_ready

enum QuestState {
	NOT_STARTED,
	STARTED,
	READY_TO_COOK,
	COMPLETED
}

var current_state: QuestState = QuestState.NOT_STARTED

var inventory: Dictionary = {
	"carrot": false,
	"salt": false,
	"curry_powder": false
}

func start_quest() -> void:
	print("start_quest called, current state: ", current_state)
	if current_state != QuestState.NOT_STARTED:
		print("blocked by state check")
		return
	current_state = QuestState.STARTED
	emit_signal("quest_started")
	print("signal emitted!")

func collect_ingredient(ingredient_name: String) -> void:
	if inventory.has(ingredient_name):
		inventory[ingredient_name] = true
		emit_signal("ingredient_collected", ingredient_name)
		print("Collected: ", ingredient_name)
		_check_all_collected()

func _check_all_collected() -> void:
	for key in inventory:
		if inventory[key] == false:
			return
	current_state = QuestState.READY_TO_COOK
	emit_signal("all_ingredients_ready")

func is_quest_active() -> bool:
	return current_state != QuestState.NOT_STARTED
