extends Node

const CORRECT_ORDER = [
	"onion", "garlic", "curry_paste",
	"carrot", "coconut_milk", "salt", "sugar"
]

const ALL_INGREDIENTS = [
	"salt", "sugar", "curry_paste",
	"coconut_milk", "carrot", "garlic", "onion"
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

# Wrong order penalty per ingredient
const ORDER_PENALTY    = 1

# All declared as Node2D to work with both Sprite2D and AnimatedSprite2D
@onready var soup_sprite:     Node2D         = $"../PotArea/SoupSprite"
@onready var pot_sprite:      Node2D         = $"../PotArea/PotSprite"
@onready var steam_particles: GPUParticles2D = $"../PotArea/SteamParticles"
@onready var stove_light:     PointLight2D   = $"../StoveLight"

# UI
@onready var request_label:   Label          = $"PanelContainer/RequestLabel"
@onready var star_container:  HBoxContainer  = $"PanelContainer2/StarContainer"
@onready var feedback_panel:   PanelContainer = $"FeedbackPanel"
@onready var feedback_label:   Label          = $"FeedbackPanel/FeedbackLabel"
@onready var restart_button:   Button         = $"RestartButton"
const USE_STAR_ICONS := false

# ─────────────────────────────────────────────
func _ready() -> void:
	_init_shelf_sprites()
	_reset_ingredients()
	_generate_requests()
	_show_requests()
	_init_soup()
	_init_steam()
	# Make sure panel and button are hidden on game start
	if feedback_panel:
		feedback_panel.visible = false
	if restart_button:
		restart_button.visible = false

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
	# Hide feedback panel and restart button on reset
	if feedback_panel:
		feedback_panel.visible = false
	if restart_button:
		restart_button.visible = false

func _generate_requests() -> void:
	villager_requests = ALL_INGREDIENTS.duplicate()

func _show_requests() -> void:
	if request_label:
		request_label.text = "Villager wants:\n"
		for ing in villager_requests:
			request_label.text += "- " + ing + "\n"

func _init_soup() -> void:
	if soup_sprite:
		soup_sprite.self_modulate.a = 0.0
		soup_sprite.visible         = true
		print("SoupSprite found: ", soup_sprite.name)
	else:
		print("ERROR: SoupSprite not found! Check the path ../PotArea/SoupSprite")

func _init_steam() -> void:
	if steam_particles:
		steam_particles.emitting    = false
		steam_particles.amount      = 4
		steam_particles.speed_scale = 0.3

#  ADD INGREDIENT
func add_ingredient(ingredient_name: String) -> void:
	ingredients[ingredient_name] += 1
	if ingredient_name not in player_order:
		player_order.append(ingredient_name)

	# Check order penalty immediately when ingredient is added
	_check_order_penalty(ingredient_name)

	_fly_ingredient_to_pot(ingredient_name)

	# Fill soup and steam AFTER fly animation lands
	var t := create_tween()
	t.tween_interval(0.45)
	t.tween_callback(func():
		_fill_soup()
		_update_steam_intensity()
	)
	print("Added: ", ingredient_name, " | Total: ", player_order.size())

func _check_order_penalty(ingredient_name: String) -> void:
	# Skip trap ingredients — they have their own penalty
	if ingredient_name in TRAP_INGREDIENTS:
		return
	# Only check ingredients that are in the correct order list
	if ingredient_name not in CORRECT_ORDER:
		return
	var expected_index := player_order.size() - 1
	if expected_index < CORRECT_ORDER.size():
		var expected : String = CORRECT_ORDER[expected_index]
		if ingredient_name != expected:
			quality_score -= ORDER_PENALTY
			quality_score = max(0, quality_score)
			print("Wrong order! Expected: ", expected, " | Got: ", ingredient_name, " | -", ORDER_PENALTY)

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
	flying.scale           = Vector2(3.5, 3.5)   # start big, shrinks into pot

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

#  ANIMATION 2 — SOUP FILLS
func _fill_soup() -> void:
	if not soup_sprite:
		print("ERROR: soup_sprite is null in _fill_soup!")
		return

	var target_alpha := float(player_order.size()) / float(ALL_INGREDIENTS.size())
	print("Filling soup to alpha: ", target_alpha)

	# Use self_modulate so parent node modulate doesn't interfere
	soup_sprite.self_modulate.a = target_alpha

	var base_scale := soup_sprite.scale
	var tween := create_tween().set_parallel(true)
	tween.tween_property(soup_sprite, "self_modulate:a", target_alpha, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Ripple using current scale so it doesn't reset to Vector2(1,1)
	tween.tween_property(soup_sprite, "scale",
		Vector2(base_scale.x * 1.04, base_scale.y * 0.97), 0.15)\
		.set_trans(Tween.TRANS_SINE)
	tween.chain().tween_property(soup_sprite, "scale", base_scale, 0.2)\
		.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)

#  ANIMATION 3 — STEAM GROWS
func _update_steam_intensity() -> void:
	if not steam_particles:
		return
	# Turn steam on once the player adds the first ingredient
	if not steam_particles.emitting:
		steam_particles.emitting = true
	var t := float(player_order.size()) / float(ALL_INGREDIENTS.size())
	steam_particles.amount      = int(lerp(4.0, 35.0, t))
	steam_particles.speed_scale = lerp(0.3, 2.2, t)

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
	# Show stars + feedback immediately, hide stars after 7s
	_reveal_stars_animated()
	_show_order_feedback()
	var star_label: Label = get_node_or_null("PanelContainer2/StarLabel")
	if star_label:
		var t := create_tween()
		t.tween_interval(7.0)
		t.tween_callback(func():
			star_label.text = ""
			star_label.get_parent().visible = false
		)
	print("Score: ", quality_score, " | Stars: ", stars)

func _show_order_feedback() -> void:
	if not feedback_panel or not feedback_label:
		print("WARNING: FeedbackPanel or FeedbackLabel not found")
		return

	# Build feedback text
	var text := "📋 Correct Order vs Your Order\n"
	text += "─────────────────────\n"
	for i in range(CORRECT_ORDER.size()):
		var correct : String = CORRECT_ORDER[i]
		var player  : String = player_order[i] if i < player_order.size() else "missing"
		var icon    := "✅" if correct == player else "❌"
		text += "%s %d. Should be: %-12s | You did: %s\n" % [icon, i+1, correct, player]

	# Add trap warning if matcha was used
	for trap in TRAP_INGREDIENTS:
		if ingredients.get(trap, 0) > 0:
			text += "\n⚠️ You added %s! That ruined the dish! -%d pts" % [trap, TRAP_PENALTY]

	feedback_label.text = text

	# Animate panel in — stays until restart button is clicked
	feedback_panel.visible    = true
	feedback_panel.modulate.a = 0.0
	if restart_button:
		restart_button.visible = true
	var tween := create_tween()
	tween.tween_property(feedback_panel, "modulate:a", 1.0, 0.4)\
		.set_trans(Tween.TRANS_SINE)

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

# ─────────────────────────────────────────────
#  ANIMATION 4 — STAR REVEAL
# ─────────────────────────────────────────────
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
	# Show the panel when stars are revealed
	star_label.get_parent().visible = true
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
func _on_matcha_button_pressed():      add_ingredient("matcha")

func _on_restart_button_pressed() -> void:
	_reset_ingredients()
	_generate_requests()
	_show_requests()
	_init_soup()
	_init_steam()
	# Reset and hide star panel
	var star_panel = get_node_or_null("PanelContainer2")
	if star_panel:
		star_panel.visible = false
	var star_label: Label = get_node_or_null("PanelContainer2/StarLabel")
	if star_label:
		star_label.text = "Stars: "
	print("Game restarted!")
