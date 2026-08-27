class_name BootScene
extends Control


enum BootSection {
	WARNING,
	STUDIO_LOGO,
	GAME_LOGO,
	FINISHED
}


@export var main_menu_scene: PackedScene


@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var warning_layer: Control = $WarningLayer
@onready var studio_layer: Control = $StudioLayer
@onready var game_logo_layer: Control = $GameLogoLayer

@onready var fade_transition: ColorRect = $FadeTransition


var current_section := BootSection.WARNING
var is_changing_section := false


func _ready() -> void:
	fade_transition.show()
	fade_transition.modulate.a = 0.0

	animation_player.animation_finished.connect(
		_on_animation_finished
	)

	_play_current_section()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skip_boot"):
		get_viewport().set_input_as_handled()

		_next_section()


func _play_current_section() -> void:
	_hide_all_layers()

	match current_section:

		BootSection.WARNING:
			warning_layer.visible = true

			_play_animation("warning")


		BootSection.STUDIO_LOGO:
			studio_layer.visible = true

			_play_animation("studio_logo")


		BootSection.GAME_LOGO:
			game_logo_layer.visible = true

			_play_animation("game_logo")


		BootSection.FINISHED:
			_go_to_main_menu()

	is_changing_section = false


func _play_animation(animation_name: StringName) -> void:
	animation_player.play("Boot/" + str(animation_name))
	animation_player.advance(0.0)


func _next_section() -> void:
	if is_changing_section:
		return

	if current_section >= BootSection.FINISHED:
		return

	is_changing_section = true

	animation_player.stop(true)

	current_section += 1

	_play_current_section()


func _on_animation_finished(
	animation_name: StringName
) -> void:

	var expected_animation := _get_current_animation_name()

	if animation_name == expected_animation:
		_next_section()


func _get_current_animation_name() -> StringName:
	match current_section:
		BootSection.WARNING:
			return &"Boot/warning"

		BootSection.STUDIO_LOGO:
			return &"Boot/studio_logo"

		BootSection.GAME_LOGO:
			return &"Boot/game_logo"

	return &""


func _hide_all_layers() -> void:
	warning_layer.visible = false
	studio_layer.visible = false
	game_logo_layer.visible = false


func _go_to_main_menu() -> void:
	if main_menu_scene == null:
		push_error(
			"Nenhuma Main Menu Scene foi definida na BootScene."
		)
		return

	animation_player.play(&"Boot/fade_to_menu")
	await animation_player.animation_finished

	get_tree().change_scene_to_packed(main_menu_scene)
