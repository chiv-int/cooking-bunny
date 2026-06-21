extends Area2D

const DialogueSystemPreload = preload("res://scence/dialogue_system.tscn")

@export var activate_instant: bool = false
@export var only_activate_once: bool = false
@export var override_dialogue_position: bool = false
@export var override_position: Vector2 = Vector2.ZERO
@export var dialogue: Array[DE]
@export var loop_dialogue: Array[DE]
@export var is_shop: bool = false
@export var is_farmer: bool = false
@export var farmer_typing_dialogue: Array[DE]
@export var farmer_correct_dialogue: Array[DE]
@export var farmer_wrong_dialogue: Array[DE]

var dialogue_top_pos: Vector2 = Vector2(160, 48)
var dialogue_bottom_pos: Vector2 = Vector2(160, 192)

var trivia_active: bool = false
var trivia_box: Control = null
var player_body_in: bool = false
var has_activated_already: bool = false
var player_node: CharacterBody2D = null
var active_dialogue = null
var is_restarting: bool = false
var has_introduced: bool = false
var typing_box: Control = null
var typing_box_active: bool = false

func _ready() -> void:
	_find_player()
	if is_farmer:
		var boxes = get_tree().get_nodes_in_group("typing_box")
		if boxes.size() > 0:
			typing_box = boxes[0]
			typing_box.correct_ingredient.connect(_on_correct_ingredient)
			typing_box.wrong_ingredient.connect(_on_wrong_ingredient)
			typing_box.all_ingredients_typed.connect(_on_all_ingredients_typed)
			print("typing_box connected: ", typing_box)
			
		
		var trivia_boxes = get_tree().get_nodes_in_group("trivia_box")
		print("trivia_box group search found: ", trivia_boxes.size(), " nodes")
		if trivia_boxes.size() > 0:
			trivia_box = trivia_boxes[0]
			trivia_box.answer_correct.connect(_on_trivia_correct)
			trivia_box.answer_wrong.connect(_on_trivia_wrong)
			print("trivia_box connected: ", trivia_box)

func _ask_next_trivia() -> void:
	if trivia_ingredients.is_empty():
		print("All trivia complete!")
		trivia_box.close_trivia()
		trivia_active = false
		player_node.can_move = true
		return

	trivia_active = true
	current_trivia_ingredient = trivia_ingredients[0]
	_show_random_question(current_trivia_ingredient)

func _show_random_question(ingredient: String) -> void:
	var questions = trivia_questions[ingredient]
	current_question_index = randi() % questions.size()
	var q = questions[current_question_index]

	# shuffle answer order so the correct one isn't always first
	var answers = q["answers"].duplicate()
	var correct_text = answers[q["correct"]]
	answers.shuffle()
	var new_correct_index = answers.find(correct_text)

	print("Asking about ", ingredient, ": ", q["question"])
	trivia_box.open_trivia(q["question"], answers, new_correct_index)



func _on_trivia_correct() -> void:
	print("TRIVIA CORRECT for ", current_trivia_ingredient)
	# give x4 of this ingredient
	for n in 4:
		QuestManager.collect_ingredient(current_trivia_ingredient)
	print("Gave 4x ", current_trivia_ingredient)

	# remove it from the list and move to the next
	trivia_ingredients.remove_at(0)
	_ask_next_trivia()

func _on_trivia_wrong() -> void:
	print("TRIVIA WRONG for ", current_trivia_ingredient)
	# show a DIFFERENT random question for the same ingredient
	_show_random_question(current_trivia_ingredient)

func _on_correct_ingredient(ingredient_name: String) -> void:
	print("Correct! Player typed: ", ingredient_name)
	# don't close, unlock, or reward yet - more prompts coming
	# the box itself advances to the next prompt (2/3, 3/3)
	# reward happens in _on_all_ingredients_typed after all 3

func _on_wrong_ingredient(typed_text: String) -> void:
	print("Wrong! Player typed: ", typed_text)
	QuestManager.last_wrong_ingredient = typed_text
	# stay locked and keep box open so player can retry this same slot

var trivia_ingredients: Array = []   # the 2 left for trivia (add near your other vars at top)

var trivia_questions: Dictionary = {
	"carrot": [
		{
			"question": "What vitamin are carrots best known for providing?",
			"answers": ["Vitamin A", "Vitamin C", "Vitamin D"],
			"correct": 0
		},
		{
			"question": "Which country is the world's largest producer of carrots?",
			"answers": ["China", "Brazil", "Canada"],
			"correct": 0
		},
		{
			"question": "Carrots grow as which part of the plant?",
			"answers": ["Root", "Leaf", "Flower"],
			"correct": 0
		}
	],
	"potato": [
		{
			"question": "Potatoes are originally native to which region?",
			"answers": ["The Andes (South America)", "Ireland", "China"],
			"correct": 0
		},
		{
			"question": "Which country grows the most potatoes today?",
			"answers": ["China", "USA", "France"],
			"correct": 0
		},
		{
			"question": "Potatoes are a good source of which nutrient?",
			"answers": ["Potassium", "Calcium", "Iron"],
			"correct": 0
		}
	],
	"lettuce": [
		{
			"question": "Lettuce is made up of mostly what?",
			"answers": ["Water", "Sugar", "Fat"],
			"correct": 0
		},
		{
			"question": "Which country produces the most lettuce?",
			"answers": ["China", "Italy", "Mexico"],
			"correct": 0
		},
		{
			"question": "Lettuce belongs to which plant family?",
			"answers": ["Daisy family", "Grass family", "Bean family"],
			"correct": 0
		}
	]
}

var current_trivia_ingredient: String = ""
var current_question_index: int = -1

func _on_all_ingredients_typed(typed_list: Array) -> void:
	print("All 3 typed: ", typed_list)
	typing_box.close_typing_box()
	typing_box_active = false

	# copy so we don't mutate the original
	var pool = typed_list.duplicate()

	# pick ONE at random → give x4 immediately
	var free_index = randi() % pool.size()
	var free_ingredient = pool[free_index]
	pool.remove_at(free_index)

	for n in 4:
		QuestManager.collect_ingredient(free_ingredient)
	print("FREE BAG: gave 4x ", free_ingredient)

# the remaining 2 are saved for trivia
	trivia_ingredients = pool
	print("Trivia needed for: ", trivia_ingredients)

	# keep player locked and start trivia
	_ask_next_trivia()

func open_typing_box() -> void:
	if typing_box_active:
		print("already active, ignoring duplicate call")
		return
	print("!!!!! OPEN TYPING BOX RUNNING !!!!!")
	if typing_box:
		typing_box_active = true
		player_node.can_move = false
		typing_box.open_typing_box()
		print("box should be visible now")
	else:
		print("TYPING BOX IS NULL")


func _find_player() -> void:
	for i in get_tree().get_nodes_in_group("player"):
		player_node = i

func _process(_delta: float) -> void:
	if !player_node:
		_find_player()
		return
	if typing_box_active:
		player_node.can_move = false
		return
	if trivia_active:
		player_node.can_move = false
		return
	if activate_instant:
		return
	if !player_body_in:
		return
	if only_activate_once and has_activated_already:
		set_process(false)
		return
	if Input.is_action_just_pressed("ui_accept"):
		_activate_dialogue()

func _activate_dialogue() -> void:
	if !player_node:
		return
	if active_dialogue and is_instance_valid(active_dialogue):
		print("BLOCKED - dialogue already active on ", get_path())
		return
	print("CREATING new dialogue instance on ", get_path())
	
	player_node.can_move = false
	has_activated_already = true

	var camera = get_viewport().get_camera_2d()
	var viewport_size = get_viewport().get_visible_rect().size

	var new_dialogue = DialogueSystemPreload.instantiate()
	
	if is_shop and has_introduced and loop_dialogue.size() > 0:
		new_dialogue.dialogue = loop_dialogue
	else:
		new_dialogue.dialogue = dialogue
		if is_shop:
			has_introduced = true
	
	new_dialogue.global_position = camera.global_position - (viewport_size / 2) + Vector2(37.5, 270)
	active_dialogue = new_dialogue
	get_parent().add_child(new_dialogue)


func restart_shop() -> void:
	print("restart_shop called!")
	if is_restarting:
		print("blocked by is_restarting")
		return
	is_restarting = true
	print("waiting for frames...")
	await get_tree().process_frame
	await get_tree().process_frame
	if active_dialogue and is_instance_valid(active_dialogue):
		active_dialogue.queue_free()
		active_dialogue = null
		print("old dialogue cleared")
	await get_tree().process_frame
	is_restarting = false
	print("calling _activate_loop_dialogue")
	_activate_loop_dialogue()


func _activate_loop_dialogue() -> void:
	print("_activate_loop_dialogue called!")
	if !player_node:
		print("no player node!")
		return
		
	if active_dialogue and is_instance_valid(active_dialogue):
		print("active dialogue still exists, blocked!")
		return
	player_node.can_move = false
	var camera = get_viewport().get_camera_2d()
	var viewport_size = get_viewport().get_visible_rect().size
	var new_dialogue = DialogueSystemPreload.instantiate()
	new_dialogue.dialogue = loop_dialogue
	new_dialogue.global_position = camera.global_position - (viewport_size / 2) + Vector2(37.5, 270)
	active_dialogue = new_dialogue
	get_parent().add_child(new_dialogue)
	print("loop dialogue started!")

func end_shop() -> void:
	if player_node:
		player_node.can_move = true
	has_introduced = false
	if active_dialogue and is_instance_valid(active_dialogue):
		active_dialogue.set_process(false)
		active_dialogue.queue_free()
		active_dialogue = null

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_body_in = true
		if activate_instant:
			_activate_dialogue()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_body_in = false
