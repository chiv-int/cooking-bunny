extends Node2D

const PickupPopupScene = preload("res://scence/pickup_popup.tscn")  # adjust path to your scene

# map ingredient name -> its sprite texture
var ingredient_textures: Dictionary = {
	"carrot": preload("res://sprite/carrot.png"),
	"coconut_milk": preload("res://sprite/coconutmilk.png"),
	"curry_paste": preload("res://sprite/currypaste.png"),
	"garlic": preload("res://sprite/garlic.png"),
	"onion": preload("res://sprite/onion.png"),
	"potato": preload("res://sprite/potato.png"),
	"salt": preload("res://sprite/salt.png"),
	"brown_sugar": preload("res://sprite/suger.png"),
}

var player_node: Node2D = null
var stack_offset: float = 0.0   # for stacking rapid popups

func _ready() -> void:
	_find_player()
	QuestManager.ingredient_collected.connect(_on_ingredient_collected)

func _find_player() -> void:
	for p in get_tree().get_nodes_in_group("player"):
		player_node = p

func _on_ingredient_collected(ingredient_name: String, _amount: int) -> void:
	print("SPAWNER got ingredient_collected: ", ingredient_name, " | player_node = ", player_node)
	if not player_node:
		_find_player()
		if not player_node:
			print("SPAWNER: no player, skipping popup")
			return
	_spawn_popup(ingredient_name)

func _spawn_popup(ingredient_name: String) -> void:
	var popup = PickupPopupScene.instantiate()

	popup.global_position = player_node.global_position + Vector2(0, -30 - stack_offset)
	stack_offset += 25.0
	get_tree().create_timer(0.4).timeout.connect(func(): stack_offset = 0.0)

	get_parent().add_child(popup)   # <-- add to tree FIRST (runs _ready, resolves @onready)

	var texture = ingredient_textures.get(ingredient_name, null)
	popup.setup(texture, 1)         # <-- THEN setup, now amount_label existsy
