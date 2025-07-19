extends Control

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):
		if visible:
			visible = false
		else:
			visible = true
