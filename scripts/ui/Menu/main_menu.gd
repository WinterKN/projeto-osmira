class_name MainMenu
extends Control


# ============================================================
# CONSTANTES
# ============================================================

const START_LEVEL_PATH := "res://game_scenes/Main_Scene/world.tscn"

const BLOCK_COUNT := 15
const PROGRESS_SPEED := 60.0

const BLOCK_EMPTY_COLOR := Color("#171714")
const BLOCK_FILLED_COLOR := Color("#d4d0bb")


# ============================================================
# BOTÕES
# ============================================================

@onready var start_button: Button = %Start_Button
@onready var load_button: Button = %Load_Button
@onready var options_button: Button = %Options_Button
@onready var exit_button: Button = %Exit_Button


# ============================================================
# SETAS - START
# ============================================================

@onready var start_arrow_left: TextureRect = %StartArrow
@onready var start_arrow_right: TextureRect = %StartArrow2


# ============================================================
# SETAS - LOAD
# ============================================================

@onready var load_arrow_left: TextureRect = %LoadArrow
@onready var load_arrow_right: TextureRect = %LoadArrow2


# ============================================================
# SETAS - OPTIONS
# ============================================================

@onready var options_arrow_left: TextureRect = %OptionsArrow
@onready var options_arrow_right: TextureRect = %OptionsArrow2


# ============================================================
# SETAS - EXIT
# ============================================================

@onready var exit_arrow_left: TextureRect = %ExitArrow
@onready var exit_arrow_right: TextureRect = %ExitArrow2


# ============================================================
# MENU
# ============================================================

@onready var options_menu: OptionsMenu = $InterfaceLayer/Options_Menu
@onready var margin_container: MarginContainer = $InterfaceLayer/MarginContainer


# ============================================================
# LOADING
# ============================================================

@onready var loading_layer: CanvasLayer = %LoadingLayer
@onready var loading_label: Label = %LoadingLabel
@onready var loading_blocks: HBoxContainer = %LoadingBlocks

@onready var menu_fade: ColorRect = %MenuFade


# ============================================================
# NAVEGAÇÃO
# ============================================================

var menu_buttons: Array[Button] = []

var menu_arrow_pairs: Array = []


# ============================================================
# LOADING VARIABLES
# ============================================================

var is_loading := false
var scene_ready := false

var loading_progress: Array = []

var target_progress: float = 0.0
var displayed_progress: float = 0.0

var loaded_scene: PackedScene = null
var is_changing_scene := false

var loading_dots_timer := 0.0
var loading_dots := 0


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	loading_layer.hide()

	_update_progress_blocks(
		0.0
	)

	handle_connecting_signals()

	setup_controller_navigation()

	_play_menu_fade_in()


# ============================================================
# CONFIGURAR NAVEGAÇÃO
# ============================================================

func setup_controller_navigation() -> void:

	menu_buttons = [
		start_button,
		load_button,
		options_button,
		exit_button
	]


	menu_arrow_pairs = [
		[
			start_arrow_left,
			start_arrow_right
		],

		[
			load_arrow_left,
			load_arrow_right
		],

		[
			options_arrow_left,
			options_arrow_right
		],

		[
			exit_arrow_left,
			exit_arrow_right
		]
	]


	# --------------------------------------------------------
	# CONFIGURAR BOTÕES
	# --------------------------------------------------------

	for i in range(
		menu_buttons.size()
	):

		var button: Button = (
			menu_buttons[i]
		)


		button.focus_mode = (
			Control.FOCUS_ALL
		)


		# ----------------------------------------------------
		# CONTROLE / TECLADO
		# ----------------------------------------------------

		button.focus_entered.connect(
			_on_menu_button_focus_entered.bind(
				i
			)
		)


		# ----------------------------------------------------
		# MOUSE
		# ----------------------------------------------------

		button.mouse_entered.connect(
			_on_menu_button_mouse_entered.bind(
				i
			)
		)


		# ----------------------------------------------------
		# ESCONDER SETAS INICIALMENTE
		# ----------------------------------------------------

		var arrows: Array = (
			menu_arrow_pairs[i]
		)


		for arrow_variant in arrows:

			var arrow := (
				arrow_variant as TextureRect
			)


			if arrow != null:

				arrow.hide()


	# ========================================================
	# FOCUS NEIGHBORS
	# ========================================================

	# START

	start_button.focus_neighbor_top = (
		start_button.get_path_to(
			exit_button
		)
	)


	start_button.focus_neighbor_bottom = (
		start_button.get_path_to(
			load_button
		)
	)


	# LOAD

	load_button.focus_neighbor_top = (
		load_button.get_path_to(
			start_button
		)
	)


	load_button.focus_neighbor_bottom = (
		load_button.get_path_to(
			options_button
		)
	)


	# OPTIONS

	options_button.focus_neighbor_top = (
		options_button.get_path_to(
			load_button
		)
	)


	options_button.focus_neighbor_bottom = (
		options_button.get_path_to(
			exit_button
		)
	)


	# EXIT

	exit_button.focus_neighbor_top = (
		exit_button.get_path_to(
			options_button
		)
	)


	exit_button.focus_neighbor_bottom = (
		exit_button.get_path_to(
			start_button
		)
	)


# ============================================================
# FOCO PELO CONTROLE / TECLADO
# ============================================================

func _on_menu_button_focus_entered(
	index: int
) -> void:

	_update_menu_arrows(
		index
	)


# ============================================================
# FOCO PELO MOUSE
# ============================================================

func _on_menu_button_mouse_entered(
	index: int
) -> void:

	if index < 0:
		return


	if index >= menu_buttons.size():
		return


	var button: Button = (
		menu_buttons[index]
	)


	if button == null:
		return


	if button.disabled:
		return


	# --------------------------------------------------------
	# O mouse passa por cima:
	# o botão vira o foco atual.
	#
	# Isso faz as setas acompanharem usando
	# exatamente o mesmo sistema do controle.
	# --------------------------------------------------------

	button.grab_focus()


# ============================================================
# ATUALIZAR SETAS
# ============================================================

func _update_menu_arrows(
	selected_index: int
) -> void:

	for i in range(
		menu_arrow_pairs.size()
	):

		var selected := (
			i == selected_index
		)


		var arrows: Array = (
			menu_arrow_pairs[i]
		)


		for arrow_variant in arrows:

			var arrow := (
				arrow_variant as TextureRect
			)


			if arrow != null:

				arrow.visible = (
					selected
				)


# ============================================================
# ESCONDER TODAS AS SETAS
# ============================================================

func _hide_all_menu_arrows() -> void:

	for arrows_variant in menu_arrow_pairs:

		var arrows: Array = (
			arrows_variant
		)


		for arrow_variant in arrows:

			var arrow := (
				arrow_variant as TextureRect
			)


			if arrow != null:

				arrow.hide()


# ============================================================
# MENU FADE
# ============================================================

func _play_menu_fade_in() -> void:

	start_button.disabled = true
	load_button.disabled = true
	options_button.disabled = true
	exit_button.disabled = true


	menu_fade.show()

	menu_fade.modulate.a = 1.0


	var tween := (
		create_tween()
	)


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


	# --------------------------------------------------------
	# PRIMEIRO FOCO
	# --------------------------------------------------------

	start_button.grab_focus()


# ============================================================
# START
# ============================================================

func on_start_pressed() -> void:

	if is_loading:
		return


	is_loading = true

	scene_ready = false

	is_changing_scene = false


	loaded_scene = null


	target_progress = 0.0
	displayed_progress = 0.0


	loading_dots_timer = 0.0
	loading_dots = 3


	loading_label.text = (
		"CARREGANDO..."
	)


	_update_progress_blocks(
		0.0
	)


	# --------------------------------------------------------
	# DESABILITAR MENU
	# --------------------------------------------------------

	start_button.disabled = true
	load_button.disabled = true
	options_button.disabled = true
	exit_button.disabled = true


	_hide_all_menu_arrows()


	# --------------------------------------------------------
	# LOADING
	# --------------------------------------------------------

	loading_layer.show()


	await get_tree().process_frame


	var error := (
		ResourceLoader.load_threaded_request(
			START_LEVEL_PATH,
			"PackedScene",
			true
		)
	)


	if error != OK:

		_loading_failed(
			"Erro ao iniciar o carregamento do World."
		)


# ============================================================
# PROCESS
# ============================================================

func _process(
	delta: float
) -> void:

	if not is_loading:
		return


	_update_loading_text(
		delta
	)


	displayed_progress = (
		move_toward(
			displayed_progress,
			target_progress,
			PROGRESS_SPEED * delta
		)
	)


	_update_progress_blocks(
		displayed_progress
	)


	if scene_ready:

		target_progress = 100.0


		if displayed_progress >= 99.9:

			displayed_progress = 100.0


			_update_progress_blocks(
				100.0
			)


			if not is_changing_scene:

				is_changing_scene = true

				_finish_loading()


		return


	loading_progress.clear()


	var status := (
		ResourceLoader.load_threaded_get_status(
			START_LEVEL_PATH,
			loading_progress
		)
	)


	match status:


		ResourceLoader.THREAD_LOAD_IN_PROGRESS:

			if not loading_progress.is_empty():

				target_progress = (
					float(
						loading_progress[0]
					)
					*
					100.0
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


# ============================================================
# PROGRESS BLOCKS
# ============================================================

func _update_progress_blocks(
	progress: float
) -> void:

	var normalized_progress: float = (
		clampf(
			progress,
			0.0,
			100.0
		)
	)


	var filled_blocks: int = int(
		floor(
			(
				normalized_progress
				/
				100.0
			)
			*
			float(
				BLOCK_COUNT
			)
		)
	)


	if normalized_progress >= 99.9:

		filled_blocks = (
			BLOCK_COUNT
		)


	for i: int in range(
		BLOCK_COUNT
	):

		if (
			i
			>=
			loading_blocks.get_child_count()
		):

			break


		var block: ColorRect = (
			loading_blocks.get_child(
				i
			)
			as ColorRect
		)


		if block == null:
			continue


		if i < filled_blocks:

			block.color = (
				BLOCK_FILLED_COLOR
			)


		else:

			block.color = (
				BLOCK_EMPTY_COLOR
			)


# ============================================================
# LOADING TEXT
# ============================================================

func _update_loading_text(
	delta: float
) -> void:

	loading_dots_timer += delta


	if loading_dots_timer < 0.4:
		return


	loading_dots_timer = 0.0


	loading_dots += 1


	if loading_dots > 3:

		loading_dots = 0


	loading_label.text = (
		"CARREGANDO"
		+
		".".repeat(
			loading_dots
		)
	)


# ============================================================
# PREPARAR CENA
# ============================================================

func _prepare_loaded_scene() -> void:

	loaded_scene = (
		ResourceLoader.load_threaded_get(
			START_LEVEL_PATH
		)
		as PackedScene
	)


	if loaded_scene == null:

		_loading_failed(
			"Não foi possível obter a cena do World."
		)

		return


	scene_ready = true


	target_progress = 100.0


# ============================================================
# FINALIZAR LOADING
# ============================================================

func _finish_loading() -> void:

	_update_progress_blocks(
		100.0
	)


	await RenderingServer.frame_post_draw


	_change_to_loaded_scene()


# ============================================================
# TROCAR CENA
# ============================================================

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


# ============================================================
# LOADING FAILED
# ============================================================

func _loading_failed(
	message: String
) -> void:

	push_error(
		message
	)


	is_loading = false

	scene_ready = false

	is_changing_scene = false


	loaded_scene = null


	target_progress = 0.0
	displayed_progress = 0.0


	_update_progress_blocks(
		0.0
	)


	loading_layer.hide()


	start_button.disabled = false
	load_button.disabled = false
	options_button.disabled = false
	exit_button.disabled = false


	start_button.grab_focus()


# ============================================================
# OPTIONS
# ============================================================

func on_options_pressed() -> void:

	margin_container.visible = false


	options_menu.set_process(
		true
	)


	options_menu.visible = true


	# --------------------------------------------------------
	# REMOVER FOCO DO MENU PRINCIPAL
	# --------------------------------------------------------

	for button in menu_buttons:

		button.release_focus()


	_hide_all_menu_arrows()


# ============================================================
# EXIT
# ============================================================

func on_exit_pressed() -> void:

	get_tree().quit()


# ============================================================
# VOLTAR DAS OPÇÕES
# ============================================================

func on_exit_options_menu() -> void:

	margin_container.visible = true


	options_menu.visible = false


	options_menu.set_process(
		false
	)


	options_button.grab_focus()


# ============================================================
# SIGNALS
# ============================================================

func handle_connecting_signals() -> void:

	start_button.pressed.connect(
		on_start_pressed
	)


	options_button.pressed.connect(
		on_options_pressed
	)


	exit_button.pressed.connect(
		on_exit_pressed
	)


	options_menu.exit_options_menu.connect(
		on_exit_options_menu
	)
