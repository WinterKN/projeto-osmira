class_name World
extends Node3D


const FADE_DURATION: float = 1.0


@onready var fade: ColorRect = %Fade


func _ready() -> void:
	_prepare_world_entry()


func _prepare_world_entry() -> void:
	# Garante que a tela comece completamente preta.
	fade.show()
	fade.modulate.a = 1.0

	# Espera a cena entrar completamente na árvore.
	await get_tree().process_frame

	# Espera um frame do World ser realmente renderizado.
	await RenderingServer.frame_post_draw

	_play_fade_in()


func _play_fade_in() -> void:
	var tween: Tween = create_tween()

	tween.tween_property(
		fade,
		"modulate:a",
		0.0,
		FADE_DURATION
	)

	await tween.finished

	fade.hide()
