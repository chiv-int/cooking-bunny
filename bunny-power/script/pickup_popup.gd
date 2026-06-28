extends Node2D

@onready var ingredient_sprite: Sprite2D = $IngredientSprite
@onready var amount_label: Label = $AmountLabel
@onready var ping_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

# how long to hold before fading
var hold_time: float = 0.5
var fade_time: float = 0.2
# how far it drifts upward while showing
var drift: float = 20.0

func setup(texture: Texture2D, amount: int) -> void:
	if texture:
		ingredient_sprite.texture = texture
		var frame_size = texture.get_height()
		var frame_count = 1
		if frame_size > 0:
			frame_count = max(1, int(texture.get_width() / frame_size))
		ingredient_sprite.hframes = frame_count
		ingredient_sprite.frame = 0

		# Scale so one frame displays at 64x64
		var target_size := 32.0
		var frame_w: float = float(texture.get_width()) / float(frame_count)
		var frame_h: float = float(texture.get_height())
		if frame_w > 0 and frame_h > 0:
			var scale_factor = target_size / max(frame_w, frame_h)
			ingredient_sprite.scale = Vector2(scale_factor, scale_factor)
	amount_label.text = "x%d" % amount

func _ready() -> void:
	var ping_sound = $AudioStreamPlayer2D 
	ping_sound.pitch_scale = randf_range(0.95, 1.05)
	ping_sound.play()
	# animate: drift up + hold + fade out, then free
	var tween = create_tween()
	tween.parallel().tween_property(self, "position:y", position.y - drift, hold_time + fade_time)
	tween.tween_interval(hold_time)
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.tween_callback(queue_free)
