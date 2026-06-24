extends Node2D

@onready var ingredient_sprite: Sprite2D = $IngredientSprite
@onready var amount_label: Label = $AmountLabel

# how long to hold before fading
var hold_time: float = 0.5
var fade_time: float = 0.2
# how far it drifts upward while showing
var drift: float = 20.0

func setup(texture: Texture2D, amount: int) -> void:
	if texture:
		ingredient_sprite.texture = texture
		ingredient_sprite.hframes = 2      # the sheet has 2 horizontal frames
		ingredient_sprite.frame = 0  
	amount_label.text = "x%d" % amount

func _ready() -> void:
	# animate: drift up + hold + fade out, then free
	var tween = create_tween()
	# drift upward the whole time
	tween.parallel().tween_property(self, "position:y", position.y - drift, hold_time + fade_time)
	# stay visible during hold, then fade
	tween.tween_interval(hold_time)
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.tween_callback(queue_free)
