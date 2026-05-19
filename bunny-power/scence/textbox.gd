extends CanvasLayer

const CHAR_READ_RATE = 0.05

@onready var textbox_container = $TextBoxContainer
@onready var start_symbol = $TextBoxContainer/MarginContainer/HBoxContainer/Start
@onready var end_symbol = $TextBoxContainer/MarginContainer/HBoxContainer/End
@onready var label = $TextBoxContainer/MarginContainer/HBoxContainer/Label

enum State{
	READY,
	READING,
	FINISHED
}

var current_state = State.READY
var text_queue = []
var tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Starting state: State.READY")
	hide_textbox()
	

func _process(_delta) -> void:
	match current_state: 
		State.READY:
			if !text_queue.is_empty():
				display_text()
		State.READING:
			if Input.is_action_just_pressed("ui_accept"):
				if tween:
					tween.kill()
				label.visible_characters = len(label.text)
				end_symbol.text = "v"
				change_state(State.FINISHED)
		State.FINISHED:
			if Input.is_action_just_pressed("ui_accept"):
				if !text_queue.is_empty():
					change_state(State.READY)  # ← will auto-display next line
				else:
					change_state(State.READY)
					hide_textbox()

func queue_text(next_text):
	text_queue.push_back(next_text)

func hide_textbox() -> void: 
	start_symbol.text = ""
	end_symbol.text = ""
	label.text = ""
	textbox_container.hide()

func show_textbox() ->void:
	start_symbol.text = "*"
	textbox_container.show()

func display_text() -> void:
	var next_text = text_queue.pop_front()
	label.text = next_text
	label.visible_characters = 0
	end_symbol.text = ""
	change_state(State.READING)
	show_textbox()
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(label, "visible_characters", len(next_text), len(next_text) * CHAR_READ_RATE)
	tween.tween_callback(func():
		end_symbol.text = "V"
		change_state(State.FINISHED)  # ← moved here so it fires AFTER tween finishes
	)

func change_state(next_state):
	current_state = next_state
	match current_state: 
		State.READY:
			print("changing state to: State.READY")
		State.READING:
			print("changing state to: State.READING")
		State.FINISHED:
			print("changing state to: State.FINISHED")
