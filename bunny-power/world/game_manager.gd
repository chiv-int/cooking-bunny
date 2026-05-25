extends Node

var quality_score = 0
var stars = 1

@onready var salt_sprite = $"../PotArea/SaltSprite"
@onready var garlic_sprite = $"../PotArea/GarlicSprite"
@onready var potato_sprite = $"../PotArea/PotatoSprite"
@onready var carrot_sprite = $"../PotArea/CarrotSprite"
@onready var sugar_sprite = $"../PotArea/SugarSprite"
@onready var coconut_sprite = $"../PotArea/CoconutSprite"
@onready var curry_sprite = $"../PotArea/CurryPasteSprite"
@onready var onion_sprite = $"../PotArea/OnionSprite"
@onready var player_anim = $"../Player/AnimatedSprite2D"

# Ingredient quantities
var ingredients = {
	"salt": 0,
	"sugar": 0,
	"curry_paste": 0,
	"coconut_milk": 0,
	"carrot": 0,
	"garlic": 0,
	"onion": 0
}

# Possible villager requests
var possible_requests = [
	"salt",
	"sugar",
	"curry_paste",
	"coconut_milk",
	"carrot",
	"garlic",
	"onion"
]

# Current requests
var villager_requests = []

# UI
@onready var star_label = $PanelContainer2/StarLabel
@onready var request_label = $PanelContainer/RequestLabel

# START GAME
func _ready():
	generate_requests()
	show_requests()
	update_ui()

# ALL INGREDIENTS AS REQUESTS
func generate_requests():
	villager_requests.clear()
	for ingredient in possible_requests:
		villager_requests.append(ingredient)

# SHOW REQUESTS ON SCREEN
func show_requests():
	request_label.text = "Villager wants:\n"
	for ingredient in villager_requests:
		request_label.text += "- " + ingredient + "\n"

# ADD INGREDIENTS
func add_ingredient(ingredient_name: String):
	ingredients[ingredient_name] += 1
	print(ingredient_name, " added")
	print(ingredients)

# BUTTON FUNCTIONS
func _on_salt_button_pressed():
	add_ingredient("salt")
	salt_sprite.visible = true
	player_anim.play("cook")

func _on_sugar_button_pressed():
	add_ingredient("sugar")
	sugar_sprite.visible = true
	player_anim.play("cook")

func _on_curry_paste_button_pressed():
	add_ingredient("curry_paste")
	curry_sprite.visible = true
	player_anim.play("cook")

func _on_coconut_milk_button_pressed():
	add_ingredient("coconut_milk")
	coconut_sprite.visible = true
	player_anim.play("cook")

func _on_carrot_button_pressed():
	add_ingredient("carrot")
	carrot_sprite.visible = true
	player_anim.play("cook")

func _on_garlic_button_pressed():
	add_ingredient("garlic")
	garlic_sprite.visible = true
	player_anim.play("cook")

func _on_onion_button_pressed():
	add_ingredient("onion")
	onion_sprite.visible = true
	player_anim.play("cook")

# SERVE CURRY
func _on_serve_button_pressed():
	calculate_curry_quality()

# MAIN SCORING SYSTEM
func calculate_curry_quality():
	quality_score = 0

	for ingredient in villager_requests:
		if ingredients[ingredient] == 1:
			quality_score += 2      # perfect, added once
		elif ingredients[ingredient] > 1:
			quality_score -= 1      # too much, deduct
		else:
			quality_score -= 1      # missing, deduct

	if quality_score < 0:
		quality_score = 0

	calculate_star_rating()
	update_ui()
	print("Final Score: ", quality_score)

# STAR SYSTEM
func calculate_star_rating():
	if quality_score >= 9:
		stars = 5
	elif quality_score >= 7:
		stars = 4
	elif quality_score >= 5:
		stars = 3
	elif quality_score >= 3:
		stars = 2
	else:
		stars = 1

# UPDATE UI
func update_ui():
	star_label.text = "Stars: "
	for i in range(stars):
		star_label.text += "⭐"
