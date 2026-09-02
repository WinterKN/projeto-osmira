extends Node


# =========================================================
# CUTSCENE STATE
# =========================================================

enum CutscenePhase {
	NONE,
	VIDEO,
	CUTSCENE_3D
}


var cutscene_phase := CutscenePhase.NONE

var skip_video_requested := false
var skip_cutscene_requested := false

var cutscene_finished := false
var video_finished := false


# =========================================================
# REFERENCES
# =========================================================

@export_group("Cutscene System")

@export var cutscene_manager: CutsceneManager


@export_group("Camera")

@export var cutscene_camera: Camera3D


@export_group("Player")

@export var player_animation: AnimationPlayer


@export_group("Video")

@export var video_player: VideoStreamPlayer


@export_group("Screen Transition")

@export var fade: ColorRect
@export var fade_duration := 0.7


@onready var cutscene_animation_player: AnimationPlayer = (
	get_node_or_null("AnimationPlayer") as AnimationPlayer
)


# =========================================================
# PLAYER ANIMATIONS
# =========================================================

@export_group("Player Animations")

@export var sitting_animation: StringName = (
	&"Cutscene/player_sit_idle"
)

@export var stand_up_animation: StringName = (
	&"Cutscene/player_stand_up"
)

@export var idle_animation: StringName = (
	&"Animações/player_idle"
)


# =========================================================
# CUTSCENE ANIMATIONS
# =========================================================

@export_group("Cutscene Animations")

@export var camera_animation: StringName = (
	&"OpeningCutsceneAnimation/Op"
)

@export var pause_after_camera := 0.5

@export var sitting_time := 2.0


# =========================================================
# READY
# =========================================================

func _ready() -> void:
	call_deferred("start_cutscene")


# =========================================================
# INPUT
# =========================================================

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("skip_cutscene"):
		return


	match cutscene_phase:

		CutscenePhase.VIDEO:
			skip_video_requested = true


		CutscenePhase.CUTSCENE_3D:
			skip_cutscene_requested = true

			skip_entire_cutscene()


	get_viewport().set_input_as_handled()


# =========================================================
# VALIDATION
# =========================================================

func validate_references() -> bool:

	if cutscene_manager == null:
		push_error(
			"OpeningCutscene: CutsceneManager não foi configurado."
		)
		return false


	if not cutscene_manager.validate_references():
		return false


	if cutscene_camera == null:
		push_error(
			"OpeningCutscene: CutsceneCamera não foi configurada."
		)
		return false


	if player_animation == null:
		push_error(
			"OpeningCutscene: Player Animation não foi configurado."
		)
		return false


	if video_player == null:
		push_error(
			"OpeningCutscene: Video Player não foi configurado."
		)
		return false


	if fade == null:
		push_error(
			"OpeningCutscene: Fade não foi configurado."
		)
		return false


	if cutscene_animation_player == null:
		push_error(
			"OpeningCutscene: AnimationPlayer não encontrado."
		)
		return false


	return true


# =========================================================
# START CUTSCENE
# =========================================================

func start_cutscene() -> void:

	if not validate_references():
		return


	# false = guarda a câmera atual,
	# bloqueia o player,
	# mas ainda NÃO ativa a câmera 3D.
	if not cutscene_manager.begin_cutscene(
		cutscene_camera,
		false
	):
		return


	cutscene_animation_player.stop()

	cutscene_animation_player.seek(
		0.0,
		true
	)


	cutscene_finished = false

	skip_video_requested = false
	skip_cutscene_requested = false

	video_finished = false

	cutscene_phase = CutscenePhase.NONE


	fade.color.a = 1.0


	if video_player.stream != null:

		await play_opening_video()

		if cutscene_finished:
			return

	else:

		video_player.hide()


	await start_3d_cutscene()


# =========================================================
# VIDEO
# =========================================================

func play_opening_video() -> void:

	cutscene_phase = CutscenePhase.VIDEO

	video_finished = false
	skip_video_requested = false


	if not video_player.finished.is_connected(
		_on_video_finished
	):
		video_player.finished.connect(
			_on_video_finished
		)


	video_player.show()
	video_player.play()


	await fade_from_black()


	while not video_finished:

		if skip_video_requested:
			break

		if cutscene_finished:
			return

		await get_tree().process_frame


	await fade_to_black()


	if cutscene_finished:
		return


	if video_player.is_playing():
		video_player.stop()


	video_player.hide()


# =========================================================
# VIDEO FINISHED
# =========================================================

func _on_video_finished() -> void:
	video_finished = true


# =========================================================
# CUTSCENE 3D
# =========================================================

func start_3d_cutscene() -> void:

	if cutscene_finished:
		return


	cutscene_phase = CutscenePhase.CUTSCENE_3D

	skip_cutscene_requested = false


	# Ativa a câmera específica da OpeningScene.
	cutscene_manager.activate_cutscene_camera()


	# Player sentado.
	player_animation.play(
		sitting_animation
	)


	# Verifica se existe animação da câmera.
	var has_camera_animation := (
		camera_animation != &""
		and
		cutscene_animation_player.has_animation(
			camera_animation
		)
	)


	if has_camera_animation:

		cutscene_animation_player.play(
			camera_animation
		)


	# Revela a cena 3D.
	await fade_from_black()


	if cutscene_finished:
		return


	if skip_cutscene_requested:
		skip_entire_cutscene()
		return


	# =====================================================
	# ESPERA CAMERA
	# =====================================================

	if has_camera_animation:

		var camera_finished := await wait_for_animation(
			cutscene_animation_player,
			camera_animation
		)


		if cutscene_finished:
			return


		if not camera_finished:
			skip_entire_cutscene()
			return


	else:

		var sitting_finished := await wait_for_seconds(
			sitting_time
		)


		if cutscene_finished:
			return


		if not sitting_finished:
			skip_entire_cutscene()
			return


	# =====================================================
	# PAUSA
	# =====================================================

	if pause_after_camera > 0.0:

		var pause_finished := await wait_for_seconds(
			pause_after_camera
		)


		if cutscene_finished:
			return


		if not pause_finished:
			skip_entire_cutscene()
			return


	# =====================================================
	# PLAYER LEVANTA
	# =====================================================

	player_animation.play(
		stand_up_animation
	)


	var stand_finished := await wait_for_animation(
		player_animation,
		stand_up_animation
	)


	if cutscene_finished:
		return


	if not stand_finished:
		skip_entire_cutscene()
		return


	end_cutscene()


# =========================================================
# WAIT FOR ANIMATION
# =========================================================

func wait_for_animation(
	animation_player: AnimationPlayer,
	animation_name: StringName
) -> bool:


	while animation_player.is_playing():


		if cutscene_finished:
			return false


		if skip_cutscene_requested:
			return false


		if animation_player.current_animation != String(
			animation_name
		):
			break


		await get_tree().process_frame


	return (
		not skip_cutscene_requested
		and not cutscene_finished
	)


# =========================================================
# WAIT FOR TIME
# =========================================================

func wait_for_seconds(seconds: float) -> bool:

	var elapsed := 0.0


	while elapsed < seconds:


		if cutscene_finished:
			return false


		if skip_cutscene_requested:
			return false


		await get_tree().process_frame


		elapsed += get_process_delta_time()


	return true


# =========================================================
# SKIP ENTIRE CUTSCENE
# =========================================================

func skip_entire_cutscene() -> void:

	if cutscene_finished:
		return


	cutscene_finished = true

	cutscene_phase = CutscenePhase.NONE


	# =====================================================
	# VIDEO
	# =====================================================

	if video_player != null:

		if video_player.is_playing():
			video_player.stop()

		video_player.hide()


	# =====================================================
	# CAMERA ANIMATION
	# =====================================================

	if cutscene_animation_player != null:

		if cutscene_animation_player.is_playing():
			cutscene_animation_player.stop()


	# =====================================================
	# PLAYER ANIMATION
	# =====================================================

	if player_animation != null:

		if player_animation.is_playing():
			player_animation.stop()


		player_animation.play(
			idle_animation
		)


	# =====================================================
	# REMOVE TELA PRETA
	# =====================================================

	if fade != null:
		fade.color.a = 0.0


	# =====================================================
	# RETORNA PARA GAMEPLAY
	# =====================================================

	if cutscene_manager != null:
		cutscene_manager.end_cutscene()


	skip_video_requested = false
	skip_cutscene_requested = false


# =========================================================
# NORMAL END
# =========================================================

func end_cutscene() -> void:

	if cutscene_finished:
		return


	cutscene_finished = true

	cutscene_phase = CutscenePhase.NONE


	if cutscene_animation_player.is_playing():
		cutscene_animation_player.stop()


	player_animation.play(
		idle_animation
	)


	cutscene_manager.end_cutscene()


	skip_video_requested = false
	skip_cutscene_requested = false


# =========================================================
# FADE TO BLACK
# =========================================================

func fade_to_black() -> void:

	if fade == null:
		return


	var tween := create_tween()


	tween.tween_property(
		fade,
		"color:a",
		1.0,
		fade_duration
	)


	await tween.finished


# =========================================================
# FADE FROM BLACK
# =========================================================

func fade_from_black() -> void:

	if fade == null:
		return


	var tween := create_tween()


	tween.tween_property(
		fade,
		"color:a",
		0.0,
		fade_duration
	)


	await tween.finished
