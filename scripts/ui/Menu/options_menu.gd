class_name OptionsMenu
extends Control

@onready var exit_button: Button = $MarginContainer/VBoxContainer/Settings_Tab_Container/Bottom_Tab_Buttons/Exit_Button

signal exit_options_menu


func _ready() -> void:
	exit_button.pressed.connect(_on_exit_pressed)
	set_process(false)


func _on_exit_pressed() -> void:
	exit_options_menu.emit()
	set_process(false)
