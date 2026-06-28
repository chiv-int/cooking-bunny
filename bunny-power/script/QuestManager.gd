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

var cook_restart_penalty: int = 0
var has_cooked_before: bool = false
var came_from_kitchen: bool = false
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
}
var required_amounts: Dictionary = {
	"carrot": 3,
	"onion": 2,
	"potato": 2,
	"garlic": 3,
	"coconut_milk": 1
}
var shop_stock: Dictionary = {
	"garlic": 3,
	"onion": 2,
	"chili": 3,
}
var shop_stock_default: Dictionary = {
	"garlic": 3,
	"onion": 2,
	"chili": 3
}

func restock_shop() -> void:
	shop_stock = shop_stock_default.duplicate()
	print("Shop restocked")
	
func start_quest() -> void:
	if current_state != QuestState.NOT_STARTED:
		print("Quest already started, blocked")
		return
	current_state = QuestState.STARTED
	emit_signal("quest_started")
	print("Quest started!")

func collect_ingredient(ingredient_name: String) -> void:
	if not inventory.has(ingredient_name):
		inventory[ingredient_name] = 0
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
		if inventory.get(ingredient, 0) < required_amounts[ingredient]:
			return
	if current_state == QuestState.READY_TO_COOK or current_state == QuestState.COMPLETED:
		return
	current_state = QuestState.READY_TO_COOK
	emit_signal("all_ingredients_ready")
	print("All ingredients ready! Time to cook!")

# returns true if this ingredient belongs in the curry recipe
func is_recipe_ingredient(ingredient_name: String) -> bool:
	return required_amounts.has(ingredient_name)

# returns a list of wrong ingredients the player collected (traps)
func get_wrong_ingredients() -> Array:
	var wrong = []
	for ingredient in inventory:
		if inventory[ingredient] > 0 and not required_amounts.has(ingredient):
			wrong.append(ingredient)
	return wrong

func has_enough(ingredient_name: String) -> bool:
	return inventory.get(ingredient_name, 0) >= required_amounts.get(ingredient_name, 1)

func is_quest_active() -> bool:
	return current_state != QuestState.NOT_STARTED
