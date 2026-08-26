extends Control

@onready var option_button: OptionButton = $HBoxContainer/OptionButton

@export_group("Visual")
@export var popup_theme: Theme


const DISPLAY_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(640, 480),
	Vector2i(1280, 720),
	Vector2i(1280, 960),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]


func _ready() -> void:
	_setup_popup_theme()
	_add_resolution_items()
	_select_current_resolution()

	# Permite conectar o sinal pelo Inspetor ou pelo código
	# sem correr o risco de conectar duas vezes.
	if not option_button.item_selected.is_connected(_on_resolution_selected):
		option_button.item_selected.connect(_on_resolution_selected)


func _setup_popup_theme() -> void:
	var popup: PopupMenu = option_button.get_popup()

	if popup_theme:
		popup.theme = popup_theme


func _add_resolution_items() -> void:
	option_button.clear()

	for resolution in DISPLAY_RESOLUTIONS:
		var index := option_button.item_count

		option_button.add_item(
			_resolution_to_text(resolution)
		)

		option_button.set_item_metadata(
			index,
			resolution
		)


func _select_current_resolution() -> void:
	var current_resolution := DisplayServer.window_get_size()
	var matching_index := _find_resolution_index(current_resolution)

	# Caso a resolução atual não exista na lista,
	# adicionamos ela temporariamente.
	if matching_index == -1:
		matching_index = option_button.item_count

		option_button.add_item(
			"%s (Current)" % _resolution_to_text(current_resolution)
		)

		option_button.set_item_metadata(
			matching_index,
			current_resolution
		)

	option_button.select(matching_index)


func _find_resolution_index(resolution: Vector2i) -> int:
	for index in range(option_button.item_count):
		if option_button.get_item_metadata(index) == resolution:
			return index

	return -1


func _on_resolution_selected(index: int) -> void:
	if index < 0 or index >= option_button.item_count:
		return

	var resolution: Vector2i = option_button.get_item_metadata(index)

	var mode := DisplayServer.window_get_mode()

	# O tamanho físico da janela só muda no modo janela.
	# Em fullscreen, a resolução usada é a do monitor.
	if mode != DisplayServer.WINDOW_MODE_WINDOWED:
		_select_current_resolution()
		return

	DisplayServer.window_set_size(resolution)

	# Espera o sistema operacional atualizar
	# o tamanho real da janela.
	await get_tree().process_frame

	_center_window()


func _center_window() -> void:
	# Descobre em qual tela a janela está.
	var screen := DisplayServer.window_get_current_screen()

	# Área utilizável sem barra de tarefas.
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)

	# Inclui bordas e barra de título.
	var window_size := DisplayServer.window_get_size_with_decorations()

	var centered_position := Vector2i(
		usable_rect.position.x
		+ int((usable_rect.size.x - window_size.x) / 2.0),

		usable_rect.position.y
		+ int((usable_rect.size.y - window_size.y) / 2.0)
	)

	DisplayServer.window_set_position(centered_position)


func _resolution_to_text(resolution: Vector2i) -> String:
	return "%d × %d" % [
		resolution.x,
		resolution.y
	]
