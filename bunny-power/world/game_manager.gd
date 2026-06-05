extends Node

const CORRECT_ORDER = [
	"onion", "garlic", "curry_paste",
	"carrot", "coconut_milk", "salt", "sugar"
]

const ALL_INGREDIENTS = [
	"onion", "garlic", "curry_paste",
	"carrot", "coconut_milk", "salt", "sugar"
]

var quality_score  := 0
var stars          := 1
var ingredients    := {}
var player_order   := []
var villager_requests := []

# Shelf sprites are loaded safely in _ready to avoid crash if a node is missing
var shelf_sprites := {}

# Trap ingredients — penalise heavily if added
const TRAP_INGREDIENTS = ["matcha"]
const TRAP_PENALTY     = 5

# All declared as Node2D to work with both Sprite2D and AnimatedSprite2D
@onready var pot_sprite:      Node2D         = $"../PotArea/PotSprite"
@onready var stove_light:     PointLight2D   = $"../StoveLight"

# UI
@onready var request_label:   Label          = $"PanelContainer/RequestLabel"
@onready var star_container:  HBoxContainer  = $"PanelContainer2/StarContainer"
const USE_STAR_ICONS := false   # set true if you have 5 TextureRect stars in StarContainer


func _ready() -> void:
	_init_shelf_sprites()
	_reset_ingredients()
	_generate_requests()
	_show_requests()

func _init_shelf_sprites() -> void:
	var paths := {
		"salt":         "../PotArea/SaltSprite",
		"sugar":        "../PotArea/SugarSprite",
		"curry_paste":  "../PotArea/CurryPasteSprite",
		"coconut_milk": "../PotArea/CoconutSprite",
		"carrot":       "../PotArea/CarrotSprite",
		"garlic":       "../PotArea/GarlicSprite",
		"onion":        "../PotArea/OnionSprite",
		"matcha":       "../PotArea/MatchaSprite"
	}
	for key in paths:
		var node = get_node_or_null(paths[key])
		if node:
			shelf_sprites[key] = node
		else:
			print("WARNING: shelf sprite not found for ", key, " at ", paths[key])

func _process(_delta: float) -> void:
	if stove_light:
		stove_light.energy = randf_range(1.8, 3.0)
		stove_light.scale  = Vector2.ONE * randf_range(0.95, 1.05)

#  SETUP
func _reset_ingredients() -> void:
	for ing in ALL_INGREDIENTS:
		ingredients[ing] = 0
	# Also track trap ingredients so penalty check works
	for trap in TRAP_INGREDIENTS:
		ingredients[trap] = 0
	player_order.clear()

func _generate_requests() -> void:
	villager_requests = ALL_INGREDIENTS.duplicate()

func _show_requests() -> void:
	if request_label:
		request_label.text = "Villager wants:\n"
		for ing in villager_requests:
			request_label.text += "- " + ing + "\n"

#  ADD INGREDIENT
func add_ingredient(ingredient_name: String) -> void:
	ingredients[ingredient_name] += 1
	if ingredient_name not in player_order:
		player_order.append(ingredient_name)

	_fly_ingredient_to_pot(ingredient_name)
	print("Added: ", ingredient_name, " | Total: ", player_order.size())

#  ANIMATION 1 — FLY TO POT
func _fly_ingredient_to_pot(ingredient_name: String) -> void:
	var shelf_node: Node2D = shelf_sprites.get(ingredient_name)
	if not shelf_node:
		print("WARNING: shelf_node not found for ", ingredient_name)
		return
	if not pot_sprite:
		print("WARNING: pot_sprite is null")
		return

	var flying: Node2D = shelf_node.duplicate()
	get_tree().current_scene.add_child(flying)
	flying.global_position = shelf_node.global_position
	flying.z_index         = 10
	flying.visible         = true
	flying.modulate.a      = 1.0
	flying.scale           = Vector2(3.5, 3.5)   

	# If it's a Sprite2D with a multi-image spritesheet,
	# show only the first frame by enabling Region and cropping to 1 cell
	if flying is Sprite2D:
		var spr     = flying as Sprite2D
		var tex     = spr.texture
		if tex:
			var hframes  = max(spr.hframes, 1)
			var vframes  = max(spr.vframes, 1)
			var cell_w   = float(tex.get_width())  / hframes
			var cell_h   = float(tex.get_height()) / vframes
			spr.hframes        = 1
			spr.vframes        = 1
			spr.region_enabled = true
			spr.region_rect    = Rect2(0, 0, cell_w, cell_h)
			spr.offset         = Vector2.ZERO

	var pot_pos: Vector2 = pot_sprite.global_position

	var tween := create_tween().set_parallel(true)

	# Horizontal travel
	tween.tween_property(flying, "global_position:x", pot_pos.x, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Arc up then fall down
	tween.tween_property(flying, "global_position:y",
		flying.global_position.y - 80, 0.22)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(flying, "global_position:y",
		pot_pos.y, 0.28)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Spin
	tween.parallel().tween_property(flying, "rotation_degrees", 360.0, 0.5)\
		.set_trans(Tween.TRANS_LINEAR)

	# Shrink into pot
	tween.parallel().tween_property(flying, "scale", Vector2(0.5, 0.5), 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Fade out near end
	tween.parallel().tween_property(flying, "modulate:a", 0.0, 0.2)\
		.set_delay(0.3).set_trans(Tween.TRANS_LINEAR)

	# Cleanup + flash
	tween.chain().tween_callback(flying.queue_free)
	tween.chain().tween_callback(_flash_pot)

func _flash_pot() -> void:
	if not pot_sprite:
		return
	var tween := create_tween()
	tween.tween_property(pot_sprite, "modulate", Color(1.4, 1.2, 0.8), 0.07)
	tween.tween_property(pot_sprite, "modulate", Color(1.0, 1.0, 1.0), 0.2)\
		.set_trans(Tween.TRANS_SINE)

#  SERVE + SCORING
func _on_serve_button_pressed() -> void:
	_calculate_curry_quality()

func _calculate_curry_quality() -> void:
	quality_score = 0

	# Score normal ingredients
	for ing in villager_requests:
		match ingredients[ing]:
			1: quality_score += 2
			0: quality_score -= 1
			_: quality_score -= 1

	# Heavy penalty for trap ingredients
	for trap in TRAP_INGREDIENTS:
		if ingredients.get(trap, 0) > 0:
			quality_score -= TRAP_PENALTY
			print("Trap ingredient used: ", trap, " | Penalty: -", TRAP_PENALTY)

	quality_score = max(0, quality_score)
	_calculate_star_rating()
	_reveal_stars_animated()
	print("Score: ", quality_score, " | Stars: ", stars)

func _count_correct_order_steps() -> int:
	var correct := 0
	for i in range(min(player_order.size(), CORRECT_ORDER.size())):
		if player_order[i] == CORRECT_ORDER[i]:
			correct += 1
	return correct

func _all_ingredients_added() -> bool:
	for ing in ALL_INGREDIENTS:
		if ingredients[ing] == 0:
			return false
	return true

func _calculate_star_rating() -> void:
	var all_added  := _all_ingredients_added()
	var good_steps := _count_correct_order_steps()
	if all_added and good_steps == 7:
		stars = 5
	elif all_added and good_steps >= 4:
		stars = 4
	elif all_added:
		stars = 3
	elif quality_score >= 3:
		stars = 2
	else:
		stars = 1

#  ANIMATION 4 — STAR REVEAL
func _reveal_stars_animated() -> void:
	if USE_STAR_ICONS and star_container:
		_reveal_star_icons()
	else:
		_reveal_star_text()

func _reveal_star_icons() -> void:
	var children := star_container.get_children()
	for i in range(children.size()):
		var s: TextureRect = children[i]
		s.modulate = Color(0.3, 0.3, 0.3, 0.5)
		s.scale    = Vector2(1.0, 1.0)
	var delay := 0.0
	for i in range(stars):
		var star_node: TextureRect = children[i]
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_callback(func():
			star_node.modulate = Color(1.0, 1.0, 1.0, 1.0)
			var inner := create_tween()
			inner.tween_property(star_node, "scale", Vector2(1.5, 1.5), 0.12)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			inner.tween_property(star_node, "scale", Vector2(0.9, 0.9), 0.08)
			inner.tween_property(star_node, "scale", Vector2(1.0, 1.0), 0.1)\
				.set_trans(Tween.TRANS_SPRING)
		)
		delay += 0.22

func _reveal_star_text() -> void:
	var star_label: Label = get_node_or_null("PanelContainer2/StarLabel")
	if not star_label:
		print("WARNING: StarLabel not found")
		return
	star_label.text = "Stars: "
	var delay := 0.0
	for i in range(stars):
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_callback(func():
			star_label.text += "⭐"
			var inner := create_tween()
			inner.tween_property(star_label, "scale", Vector2(1.2, 1.2), 0.1)
			inner.tween_property(star_label, "scale", Vector2(1.0, 1.0), 0.12)\
				.set_trans(Tween.TRANS_SPRING)
		)
		delay += 0.25
	if stars == 5:
		var shake_tween := create_tween()
		shake_tween.tween_interval(delay + 0.1)
		shake_tween.tween_callback(_shake_label.bind(star_label))

func _shake_label(label: Label) -> void:
	var origin := label.position
	var tween  := create_tween().set_loops(3)
	tween.tween_property(label, "position", origin + Vector2(4, 0),  0.05)
	tween.tween_property(label, "position", origin + Vector2(-4, 0), 0.05)
	tween.tween_property(label, "position", origin,                  0.05)

#  BUTTON HANDLERS
func _on_salt_button_pressed():         add_ingredient("salt")
func _on_sugar_button_pressed():        add_ingredient("sugar")
func _on_curry_paste_button_pressed():  add_ingredient("curry_paste")
func _on_coconut_milk_button_pressed(): add_ingredient("coconut_milk")
func _on_carrot_button_pressed():       add_ingredient("carrot")
func _on_garlic_button_pressed():       add_ingredient("garlic")
func _on_onion_button_pressed():        add_ingredient("onion")
func _on_matcha_button_pressed():       add_ingredient("matcha")
