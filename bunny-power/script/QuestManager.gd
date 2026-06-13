extends Node

signal quest_started
signal ingredient_collected(ingredient_name: String, amount: int)
signal all_ingredients_ready
signal shop_purchase_made

enum QuestState {
	NOT_STARTED,
	STARTED,
	READY_TO_COOK,
	COMPLETED
}

var current_state: QuestState = QuestState.NOT_STARTED
var came_from_house: bool = false
var last_wrong_ingredient: String = ""

var inventory: Dictionary = {
	"carrot": 0,
	"onion": 0,
	"potato": 0,
	"garlic": 0,
	"curry_paste": 0,
	"coconut_milk": 0,
	"salt": 0,
	"brown_sugar": 0,
	"chili": 0,
	"extra_sugar": 0,
	"butter": 0,
	"fish_sauce": 0
}

var required_amounts: Dictionary = {
	"carrot": 3,
	"onion": 2,
	"potato": 2,
	"garlic": 3,
	"curry_paste": 1,
	"coconut_milk": 1,
	"salt": 1,
	"brown_sugar": 3
}

var shop_stock: Dictionary = {
	"garlic": 3,
	"onion": 2,
	"chili": 3,
	"butter": 2,
	"fish_sauce": 1,
	"salt": 2
}

func start_quest() -> void:
	if current_state != QuestState.NOT_STARTED:
		print("Quest already started, blocked")
		return
	current_state = QuestState.STARTED
	emit_signal("quest_started")
	print("Quest started!")

func collect_ingredient(ingredient_name: String) -> void:
	if not inventory.has(ingredient_name):
		print("Unknown ingredient: ", ingredient_name)
		return
	inventory[ingredient_name] += 1
	print("Collected: ", ingredient_name, " | Total: ", inventory[ingredient_name])
	emit_signal("ingredient_collected", ingredient_name, inventory[ingredient_name])
	_check_all_collected()

func buy_ingredient(ingredient_name: String, amount: int = 1) -> void:
	print("buy_ingredient called with: ", ingredient_name)

	if not shop_stock.has(ingredient_name):
		print("Item not sold here: ", ingredient_name)
		return
	if shop_stock[ingredient_name] < amount:
		print("Out of stock: ", ingredient_name)
		return
	shop_stock[ingredient_name] -= amount
	collect_ingredient(ingredient_name)
	print("Bought: ", amount, "x ", ingredient_name, " | Stock left: ", shop_stock[ingredient_name])
	emit_signal("shop_purchase_made")

func _check_all_collected() -> void:
	for ingredient in required_amounts:
		if inventory[ingredient] < required_amounts[ingredient]:
			return
	current_state = QuestState.READY_TO_COOK
	emit_signal("all_ingredients_ready")
	print("All ingredients ready! Time to cook!")

func has_enough(ingredient_name: String) -> bool:
	return inventory.get(ingredient_name, 0) >= required_amounts.get(ingredient_name, 1)

func is_quest_active() -> bool:
	return current_state != QuestState.NOT_STARTED
