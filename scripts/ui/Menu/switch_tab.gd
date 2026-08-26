extends Control

@onready var tab_container: TabContainer = $TabContainer
@onready var top_tab_buttons: HBoxContainer = $Top_Tab_Buttons

var tab_button_group := ButtonGroup.new()


func _ready() -> void:
	var buttons := top_tab_buttons.get_children()

	for i in range(buttons.size()):
		var button := buttons[i] as BaseButton

		if button == null:
			continue

		button.toggle_mode = true
		button.button_group = tab_button_group
		button.pressed.connect(_change_tab.bind(i))

	tab_container.current_tab = 0

	if buttons.size() > 0:
		var first_button := buttons[0] as BaseButton
		
		if first_button:
			first_button.button_pressed = true


func _change_tab(tab_index: int) -> void:
	print("Trocando para aba: ", tab_index)
	tab_container.current_tab = tab_index
