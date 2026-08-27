class_name MainMenu
extends Control


const START_LEVEL_PATH := "res://game_scenes/Main_Scene/world.tscn"

const BLOCK_COUNT := 15
const PROGRESS_SPEED := 60.0

const BLOCK_EMPTY_COLOR := Color("#171714")
const BLOCK_FILLED_COLOR := Color("#d4d0bb")


@onready var start_button: Button = $InterfaceLayer/MarginContainer/HBoxContainer/VBoxContainer/Start_Button
@onready var load_button: Button = $InterfaceLayer/MarginContainer/HBoxContainer/VBoxContainer/Load_Button
@onready var exit_button: Button = $InterfaceLayer/MarginContainer/HBoxContainer/VBoxContainer/Exit_Button
@onready var options_button: Button = $InterfaceLayer/MarginContainer/HBoxContainer/VBoxContainer/Options_Button

@onready var options_menu: OptionsMenu = $InterfaceLayer/Options_Menu
@onready var margin_container: MarginContainer = $InterfaceLayer/MarginContainer

@onready var loading_layer: CanvasLayer = %LoadingLayer
@onready var loading_label: Label = %LoadingLabel
@onready var loading_blocks: HBoxContainer = %LoadingBlocks

@onready var menu_fade: ColorRect = %MenuFade


var is_loading := false
var scene_ready := false

var loading_progress: Array = []

var target_progress: float = 0.0
var displayed_progress: float = 0.0

var loaded_scene: PackedScene = null
var is_changing_scene: bool = false

var loading_dots_timer := 0.0
var loading_dots := 0


func _ready() -> void:
	loading_layer.hide()

	_update_progress_blocks(0.0)

	handle_connecting_signals()

	_play_menu_fade_in()


func _play_menu_fade_in() -> void:
	start_button.disabled = true
	load_button.disabled = true
	options_button.disabled = true
	exit_button.disabled = true

	menu_fade.show()
	menu_fade.modulate.a = 1.0

	var tween := create_tween()

	tween.tween_property(
		menu_fade,
		"modulate:a",
		0.0,
		1.3
	)

	await tween.finished

	menu_fade.hide()

	start_button.disabled = false
	load_button.disabled = false
	options_button.disabled = false
	exit_button.disabled = false


func on_start_pressed() -> void:
	if is_loading:
		return

	is_loading = true
	scene_ready = false

	loaded_scene = null

	target_progress = 0.0
	displayed_progress = 0.0

	loading_dots_timer = 0.0
	loading_dots = 3

	loading_label.text = "CARREGANDO..."

	_update_progress_blocks(0.0)

	start_button.disabled = true
	load_button.disabled = true
	options_button.disabled = true
	exit_button.disabled = true

	loading_layer.show()

	await get_tree().process_frame

	var error := ResourceLoader.load_threaded_request(
		START_LEVEL_PATH,
		"PackedScene",
		true
	)

	if error != OK:
		_loading_failed(
			"Erro ao iniciar o carregamento do World."
		)


func _process(delta: float) -> void:
	if not is_loading:
		return

	_update_loading_text(delta)

	# Faz o progresso VISUAL caminhar
	# suavemente até o progresso real.
	displayed_progress = move_toward(
		displayed_progress,
		target_progress,
		PROGRESS_SPEED * delta
	)

	_update_progress_blocks(displayed_progress)


	# Se o World já terminou de carregar,
	# fazemos a barra visual terminar até 100%.
	if scene_ready:
		target_progress = 100.0

		if displayed_progress >= 99.9:
			displayed_progress = 100.0

			_update_progress_blocks(100.0)

			if not is_changing_scene:
				is_changing_scene = true
				_finish_loading()

		return


	loading_progress.clear()

	var status := ResourceLoader.load_threaded_get_status(
		START_LEVEL_PATH,
		loading_progress
	)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if not loading_progress.is_empty():
				target_progress = (
					float(loading_progress[0])
					* 100.0
				)

		ResourceLoader.THREAD_LOAD_LOADED:
			_prepare_loaded_scene()

		ResourceLoader.THREAD_LOAD_FAILED:
			_loading_failed(
				"Falha ao carregar o World."
			)

		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_loading_failed(
				"O arquivo do World é inválido."
			)


func _update_progress_blocks(progress: float) -> void:
	var normalized_progress: float = clampf(
		progress,
		0.0,
		100.0
	)

	var filled_blocks: int = int(
		floor(
			(normalized_progress / 100.0)
			* float(BLOCK_COUNT)
		)
	)

	if normalized_progress >= 99.9:
		filled_blocks = BLOCK_COUNT

	for i: int in range(BLOCK_COUNT):
		if i >= loading_blocks.get_child_count():
			break

		var block: ColorRect = loading_blocks.get_child(i) as ColorRect

		if block == null:
			continue

		if i < filled_blocks:
			block.color = BLOCK_FILLED_COLOR
		else:
			block.color = BLOCK_EMPTY_COLOR


func _update_loading_text(delta: float) -> void:
	loading_dots_timer += delta

	if loading_dots_timer < 0.4:
		return

	loading_dots_timer = 0.0

	loading_dots += 1

	if loading_dots > 3:
		loading_dots = 0

	loading_label.text = (
		"CARREGANDO"
		+ ".".repeat(loading_dots)
	)


func _prepare_loaded_scene() -> void:
	loaded_scene = ResourceLoader.load_threaded_get(
		START_LEVEL_PATH
	) as PackedScene

	if loaded_scene == null:
		_loading_failed(
			"Não foi possível obter a cena do World."
		)
		return

	scene_ready = true

	target_progress = 100.0

func _finish_loading() -> void:
	_update_progress_blocks(100.0)

	await RenderingServer.frame_post_draw

	_change_to_loaded_scene()

func _change_to_loaded_scene() -> void:
	if loaded_scene == null:
		_loading_failed(
			"A cena carregada é inválida."
		)
		return

	is_loading = false
	scene_ready = false

	get_tree().change_scene_to_packed(
		loaded_scene
	)


func _loading_failed(message: String) -> void:
	push_error(message)

	is_loading = false
	scene_ready = false

	loaded_scene = null

	target_progress = 0.0
	displayed_progress = 0.0

	_update_progress_blocks(0.0)

	loading_layer.hide()

	start_button.disabled = false
	load_button.disabled = false
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

	options_button.pressed.connect(
		on_options_pressed
	)

	exit_button.pressed.connect(
		on_exit_pressed
	)

	options_menu.exit_options_menu.connect(
		on_exit_options_menu
	)
