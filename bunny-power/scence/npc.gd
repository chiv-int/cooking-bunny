extends CharacterBody2D

var is_chatting = false
var player_in_chat_zone = false

var dialogue = [
	"Hello cousin! Do you miss home?",
	"How was the city like?",
	"I heard you are going to cook for all of us...",
	"Is that true?",
]
var dialogue_index = 0

func _ready() -> void:
	$AnimatedSprite2D.play("IDLE")

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		print("Z pressed! in zone: ", player_in_chat_zone)
		if player_in_chat_zone and not is_chatting:
			_start_chat()
		elif is_chatting:
			_show_next_line()

func _on_chat_detection_area_body_entered(body: Node2D) -> void:
	# Only react to the player, ignore other bodies like slimes etc
	if body.is_in_group("player"):
		player_in_chat_zone = true
		print("ready to chat - press Z")

func _on_chat_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_chat_zone = false
		if is_chatting:
			_end_chat()

func _start_chat() -> void:
	is_chatting = true
	dialogue_index = 0
	_show_next_line()

func _show_next_line() -> void:
	if dialogue_index < dialogue.size():
		print(dialogue[dialogue_index])
		dialogue_index += 1
	else:
		_end_chat()

func _end_chat() -> void:
	is_chatting = false
	print("=== chat ended ===")
