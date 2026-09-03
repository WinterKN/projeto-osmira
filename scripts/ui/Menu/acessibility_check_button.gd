class_name SettingToggle
extends Control


signal setting_changed(setting_name: StringName, enabled: bool)


@onready var name_label: Label = $HBoxContainer/Name_Label
@onready var state_label: Label = $HBoxContainer/State_Label
@onready var check_button: CheckButton = $HBoxContainer/CenterContainer/CheckButton


@export var setting_name: StringName
@export var display_name: String = "Setting"
@export var default_enabled: bool = true


func _ready() -> void:
	name_label.text = display_name

	set_state(default_enabled, false)

	if not check_button.toggled.is_connected(_on_setting_toggled):
		check_button.toggled.connect(_on_setting_toggled)


func _on_setting_toggled(enabled: bool) -> void:
	_update_state_label(enabled)

	setting_changed.emit(setting_name, enabled)


func set_state(enabled: bool, emit_signal: bool = false) -> void:
	check_button.set_pressed_no_signal(enabled)

	_update_state_label(enabled)

	if emit_signal:
		setting_changed.emit(setting_name, enabled)


func _update_state_label(enabled: bool) -> void:
	state_label.text = "On" if enabled else "Off"
