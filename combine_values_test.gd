extends Label

@export var slider : HSlider
@export var slider2 : HSlider

func _process(delta: float) -> void:
	var value = (slider.value + slider2.value) *.5
	
	text = str(value)
