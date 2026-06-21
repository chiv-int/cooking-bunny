extends Control

signal correct_ingredient(ingredient_name: String)
signal wrong_ingredient(typed_text: String)
signal all_ingredients_typed(typed_list: Array)

@onready var input_field: LineEdit = $VBoxContainer/InputField
@onready var prompt_label: Label = $VBoxContainer/PromptedLable

var valid_ingredients: Array[String] = ["carrot", "potato", "lettuce"]

var typed_ingredients: Array = []
var prompts_needed: int = 3
var current_prompt_index: int = 0

func _ready() -> void:
	visible = false
	input_field.text_submitted.connect(_on_text_submitted)

func open_typing_box() -> void:
	visible = true
	typed_ingredients.clear()
	current_prompt_index = 0
	_update_prompt_label()
	input_field.text = ""
	input_field.grab_focus()
	print("typing_box.open_box() called")

func close_typing_box() -> void:
	visible = false
	input_field.text = ""

func _update_prompt_label() -> void:
	prompt_label.text = "I need (%d/%d):" % [current_prompt_index + 1, prompts_needed]

func _on_text_submitted(submitted_text: String) -> void:
	var cleaned = submitted_text.to_lower().strip_edges()

	if cleaned in valid_ingredients and not (cleaned in typed_ingredients):
		typed_ingredients.append(cleaned)
		current_prompt_index += 1
		emit_signal("correct_ingredient", cleaned)

		if current_prompt_index >= prompts_needed:
			emit_signal("all_ingredients_typed", typed_ingredients)
		else:
			_update_prompt_label()
	else:
		emit_signal("wrong_ingredient", cleaned)

	input_field.text = ""
	input_field.grab_focus()
