extends CanvasLayer

@onready var panel = $Panel
@onready var anim = $Panel/AnimationPlayer
@onready var title_label = $Panel/VBoxContainer/title
@onready var desc_label = $Panel/VBoxContainer/dis

func _ready() -> void:
	panel.visible = false
	# force white text regardless of theme
	title_label.add_theme_color_override("font_color", Color.WHITE)
	desc_label.add_theme_color_override("font_color", Color.WHITE)
	QuestManager.quest_started.connect(_on_quest_started)

func _on_quest_started() -> void:
	panel.modulate = Color(1, 1, 1, 1)
	panel.visible = true
	anim.play("popup")
	
	var player = get_tree().get_first_node_in_group("player")
	while player and player.velocity == Vector2.ZERO:
		await get_tree().process_frame
	
	panel.visible = false
