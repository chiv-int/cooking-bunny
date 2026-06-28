extends Area2D

var player_nearby = false
var is_transitioning = false

func _ready():
	$Label.visible = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		if QuestManager.is_quest_active():
			$Label.text = "Press Enter to cook"
		else:
			$Label.text = "Start the quest first"
		$Label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		$Label.visible = false

func _input(event):
	if event.is_action_pressed("ui_accept") and player_nearby and not is_transitioning:
		if not QuestManager.is_quest_active():
			print("Quest not started — can't cook yet")
			return
		is_transitioning = true
		get_tree().change_scene_to_file("res://scence/kitchen.tscn")
