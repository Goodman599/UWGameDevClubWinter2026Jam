extends CanvasLayer

signal eyes_closed
signal eyes_opened


func blink():
	show()
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($Eyelids, "texture:fill_to", Vector2(0.499, 0.499), 0.75)
	tween.parallel().tween_property($Eyelids, "self_modulate:a", 1, 0.75)
	await tween.finished
	
	tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	emit_signal("eyes_closed")
	tween.tween_property($Eyelids, "texture:fill_to", Vector2(0.0, 0.0), 0.75)
	tween.parallel().tween_property($Eyelids, "self_modulate:a", 0, 0.75)
	await tween.finished
	
	hide()
	emit_signal("eyes_opened")
	
