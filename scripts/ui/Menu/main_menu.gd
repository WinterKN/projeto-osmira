class_name MainMenu
extends Control


const START_LEVEL_PATH := "res://game_scenes/Main_Scene/world.tscn"


@onready var start_button: Button = $InterfaceLayer/MarginContainer/HBoxContainer/VBoxContainer/Start_Button
@onready var exit_button: Button = $InterfaceLayer/MarginContainer/HBoxContainer/VBoxContainer/Exit_Button
@onready var options_button: Button = $InterfaceLayer/MarginContainer/HBoxContainer/VBoxContainer/Options_Button

@onready var options_menu: OptionsMenu = $InterfaceLayer/Options_Menu
@onready var margin_container: MarginContainer = $InterfaceLayer/MarginContainer

@onready var loading_layer: CanvasLayer = %LoadingLayer
@onready var loading_label: Label = %LoadingLabel


var is_loading := false
var loading_progress: Array = []


func _ready() -> void:
	loading_layer.hide()
	handle_connecting_signals()


func on_start_pressed() -> void:
	if is_loading:
		return

	is_loading = true

	# Impede o jogador de apertar os botões novamente.
	start_button.disabled = true
	options_button.disabled = true
	exit_button.disabled = true

	# Mostra a tela de loading.
	loading_layer.show()
	loading_label.text = "CARREGANDO... 0%"

	# Dá um frame para o Godot desenhar a tela de loading
	# antes de começar a carregar o World.
	await get_tree().process_frame

	var error := ResourceLoader.load_threaded_request(
		START_LEVEL_PATH,
		"PackedScene",
		true
	)

	if error != OK:
		push_error("Erro ao iniciar o carregamento do World.")

		is_loading = false
		loading_layer.hide()

		start_button.disabled = false
		options_button.disabled = false
		exit_button.disabled = false


func _process(_delta: float) -> void:
	if not is_loading:
		return

	loading_progress.clear()

	var status := ResourceLoader.load_threaded_get_status(
		START_LEVEL_PATH,
		loading_progress
	)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if not loading_progress.is_empty():
				var percentage := int(loading_progress[0] * 100.0)

				loading_label.text = "CARREGANDO... %d%%" % percentage

		ResourceLoader.THREAD_LOAD_LOADED:
			_finish_loading()

		ResourceLoader.THREAD_LOAD_FAILED:
			_loading_failed("Falha ao carregar o World.")

		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_loading_failed("O arquivo do World é inválido.")


func _finish_loading() -> void:
	is_loading = false

	loading_label.text = "CARREGANDO... 100%"

	var start_level := ResourceLoader.load_threaded_get(
		START_LEVEL_PATH
	) as PackedScene

	if start_level == null:
		_loading_failed("Não foi possível obter a cena do World.")
		return

	get_tree().change_scene_to_packed(start_level)


func _loading_failed(message: String) -> void:
	push_error(message)

	is_loading = false
	loading_layer.hide()

	start_button.disabled = false
	options_button.disabled = false
	exit_button.disabled = false


func on_options_pressed() -> void:
	margin_container.visible = false
	options_menu.set_process(true)
	options_menu.visible = true


func on_exit_pressed() -> void:
	get_tree().quit()


func on_exit_options_menu() -> void:
	margin_container.visible = true
	options_menu.visible = false


func handle_connecting_signals() -> void:
	start_button.pressed.connect(on_start_pressed)
	options_button.pressed.connect(on_options_pressed)
	exit_button.pressed.connect(on_exit_pressed)

	options_menu.exit_options_menu.connect(on_exit_options_menu)
