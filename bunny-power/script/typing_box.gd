extends Control

signal correct_ingredient(ingredient_name: String)
signal wrong_ingredient(typed_text: String)

@onready var input_field: LineEdit = $VBoxContainer/InputField
@onready var prompt_label: Label = $VBoxContainer/PromptedLable

var valid_ingredients: Array[String] = ["carrot", "potato", "lettuce"]

func _ready() -> void:
	visible = false
	input_field.text_submitted.connect(_on_text_submitted)

func open_typing_box() -> void:
	visible = true
	input_field.text = ""
	input_field.grab_focus()
	print("typing_box.open_box() called")

func close_typing_box() -> void:
	visible = false
	input_field.text = ""

func _on_text_submitted(submitted_text: String) -> void:
	var cleaned = submitted_text.to_lower().strip_edges()

	if cleaned in valid_ingredients:
		emit_signal("correct_ingredient", cleaned)
	else:
		emit_signal("wrong_ingredient", cleaned)

	input_field.text = ""
	input_field.grab_focus()
