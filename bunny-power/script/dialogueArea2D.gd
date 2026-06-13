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
	print("READY on ", get_path(), " | is_farmer = ", is_farmer)
	if is_farmer:
		var boxes = get_tree().get_nodes_in_group("typing_box")
		if boxes.size() > 0:
			typing_box = boxes[0]
			typing_box.correct_ingredient.connect(_on_correct_ingredient)
			typing_box.wrong_ingredient.connect(_on_wrong_ingredient)
			print("typing_box connected: ", typing_box)

func _on_correct_ingredient(ingredient_name: String) -> void:
	print("Correct! Player typed: ", ingredient_name)
	typing_box.close_typing_box()
	typing_box_active = false
	player_node.can_move = true
	QuestManager.collect_ingredient(ingredient_name)
	QuestManager.collect_ingredient(ingredient_name)
	QuestManager.collect_ingredient(ingredient_name)
	QuestManager.collect_ingredient(ingredient_name)
	print("Gave 4x ", ingredient_name)

func _on_wrong_ingredient(typed_text: String) -> void:
	print("Wrong! Player typed: ", typed_text)
	QuestManager.last_wrong_ingredient = typed_text
	typing_box_active = false
	player_node.can_move = true

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
