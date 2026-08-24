extends Control

@onready var label: Label = $Label
@onready var timer: Timer = $Timer


func _ready() -> void:
	if label.visible:
		timer.timeout.connect(animate_label)
		animate_label()
	
	
func animate_label() -> void:
	label.visible_characters += 1
	
	timer.start()
