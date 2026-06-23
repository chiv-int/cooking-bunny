extends Control

@onready var list_container: VBoxContainer = $VBoxContainer/ScrollContainer/ListContainer
@onready var book_icon: TextureRect = $"../BookIcon"


var list_font = preload("res://sprite/8bitoperator_jve.ttf")

func _ready() -> void:
	visible = false
	QuestManager.ingredient_collected.connect(_on_ingredient_collected)
	QuestManager.quest_started.connect(_on_quest_started)
	# in case the quest already started before this UI loaded:
	book_icon.visible = QuestManager.is_quest_active()
	_refresh()

func _on_quest_started() -> void:
	book_icon.visible = true

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_checklist"):
		# only allow opening if the quest is active
		if QuestManager.is_quest_active():
			visible = not visible
			if visible:
				_refresh()
		else:
			print("Quest not started yet - checklist unavailable")

func _on_ingredient_collected(_ingredient_name: String, _amount: int) -> void:
	_refresh()

func _refresh() -> void:
	for child in list_container.get_children():
		child.queue_free()

	for ingredient in QuestManager.required_amounts:
		var have = QuestManager.inventory.get(ingredient, 0)
		var need = QuestManager.required_amounts[ingredient]

		var row = Label.new()
		var done = have >= need
		var check = "✓" if done else "✗"
		row.text = "[%s] %s: %d/%d" % [check, ingredient, have, need]
		row.add_theme_font_override("font", list_font)
		row.add_theme_font_size_override("font_size", 16)   # adjust size

		# color: green when complete, red when not
		if done:
			row.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))   # green
		else:
			row.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))   # red

		list_container.add_child(row)
