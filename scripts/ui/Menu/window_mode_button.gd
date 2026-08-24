extends Control

@onready var option_button: OptionButton = $HBoxContainer/OptionButton


enum WindowModeOption {
	EXCLUSIVE_FULLSCREEN,
	WINDOWED,
	BORDERLESS_WINDOWED,
	BORDERLESS_FULLSCREEN,
}


const WINDOW_MODE_NAMES: Array[String] = [
	"Full-Screen",
	"Window Mode",
	"Borderless Window",
	"Borderless Full-Screen",
]


func _ready() -> void:
	_add_window_mode_items()
	_select_current_window_mode()

	# Deixa usar o sinal conectado pelo inspetor ou conectar automaticamente pelo script. 
	# Dessa forma não existe conexão duplicada.
	if not option_button.item_selected.is_connected(_on_window_mode_selected):
		option_button.item_selected.connect(_on_window_mode_selected)


func _add_window_mode_items() -> void:
	option_button.clear()

	for window_mode_name in WINDOW_MODE_NAMES:
		option_button.add_item(window_mode_name)


func _select_current_window_mode() -> void:
	var mode := DisplayServer.window_get_mode()

	var borderless := DisplayServer.window_get_flag(
		DisplayServer.WINDOW_FLAG_BORDERLESS
	)

	match mode:

		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			option_button.select(
				WindowModeOption.EXCLUSIVE_FULLSCREEN
			)

		DisplayServer.WINDOW_MODE_FULLSCREEN:
			option_button.select(
				WindowModeOption.BORDERLESS_FULLSCREEN
			)

		DisplayServer.WINDOW_MODE_WINDOWED:

			if borderless:
				option_button.select(
					WindowModeOption.BORDERLESS_WINDOWED
				)

			else:
				option_button.select(
					WindowModeOption.WINDOWED
				)

		# Caso o jogo seja iniciado maximizado, tratamos ele como Window Mode.
		DisplayServer.WINDOW_MODE_MAXIMIZED:
			option_button.select(
				WindowModeOption.WINDOWED
			)

		_:
			option_button.select(
				WindowModeOption.WINDOWED
			)


func _on_window_mode_selected(index: int) -> void:
	if index < 0 or index >= WINDOW_MODE_NAMES.size():
		return

	match index:

		WindowModeOption.EXCLUSIVE_FULLSCREEN:
			_set_exclusive_fullscreen()

		WindowModeOption.WINDOWED:
			_set_windowed(false)

		WindowModeOption.BORDERLESS_WINDOWED:
			_set_windowed(true)

		WindowModeOption.BORDERLESS_FULLSCREEN:
			_set_borderless_fullscreen()


func _set_exclusive_fullscreen() -> void:
	# Fullscreen exclusivo.
	# É o equivalente ao fullscreen tradicional de jogos.
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)


func _set_borderless_fullscreen() -> void:
	# Fullscreen normal do Godot funciona como fullscreen sem bordas. Não precisa ativar WINDOW_FLAG_BORDERLESS aqui.
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN
	)


func _set_windowed(borderless: bool) -> void:
	# Primeiro voltamos pro modo Janela.
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_WINDOWED
	)

	# Depois escolhemos se a janela vai ter bordas.
	DisplayServer.window_set_flag(
		DisplayServer.WINDOW_FLAG_BORDERLESS,
		borderless
	)

	# Esperamos a janela atualizar antes de centralizar.
	await get_tree().process_frame

	_center_window()


func _center_window() -> void:
	# Descobre em qual tela o jogo ta.
	var screen := DisplayServer.window_get_current_screen()

	# Pega a área utilizável do monitor, desconsiderando a barra de tarefas.
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)

	# Tamanho total da janela incluindo decoração.
	var window_size := DisplayServer.window_get_size_with_decorations()

	var centered_position := Vector2i(
		usable_rect.position.x
		+ int((usable_rect.size.x - window_size.x) / 2.0),

		usable_rect.position.y
		+ int((usable_rect.size.y - window_size.y) / 2.0)
	)

	DisplayServer.window_set_position(centered_position)
