extends CharacterBody2D

var is_chatting = false
var player_in_chat_zone = false

var dialogue = [
	"wasssuppp, bunny",
	"How uni going for you?",
	". . .",
	"i heard you're the family chef this year?",
	"GoodLuck,ah bun!",
	
]
var dialogue_index = 0

func _ready() -> void:
	$AnimatedSprite2D.play("IDLE")

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		if player_in_chat_zone and not is_chatting:
			_start_chat()

func _on_chat_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_chat_zone = true

func _on_chat_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_chat_zone = false
		if is_chatting:
			_end_chat()

func _start_chat() -> void:
	is_chatting = true
	dialogue_index = 0
	# queue all lines at once into the textbox
	for line in dialogue:
		Textbox.queue_text(line)

func _end_chat() -> void:
	is_chatting = false
	Textbox.hide_textbox()
