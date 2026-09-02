class_name CutsceneManager
extends Node


# =========================================================
# REFERENCES
# =========================================================

@export_group("References")

@export var player: Player


# =========================================================
# STATE
# =========================================================

var previous_camera: Camera3D = null
var current_cutscene_camera: Camera3D = null
var cutscene_active := false


# =========================================================
# VALIDATION
# =========================================================

func validate_references() -> bool:
	if player == null:
		push_error(
			"CutsceneManager: Player não foi configurado no Inspector."
		)
		return false

	return true


# =========================================================
# BEGIN CUTSCENE
# =========================================================

func begin_cutscene(
	cutscene_camera: Camera3D,
	activate_camera_immediately: bool = true
) -> bool:

	if not validate_references():
		return false

	if cutscene_camera == null:
		push_error(
			"CutsceneManager: CutsceneCamera recebida é nula."
		)
		return false

	if cutscene_active:
		push_warning(
			"CutsceneManager: já existe uma cutscene ativa."
		)
		return false


	# Guarda a câmera atualmente ativa.
	var active_camera := get_viewport().get_camera_3d()

	if active_camera != null and active_camera != cutscene_camera:
		previous_camera = active_camera
	else:
		previous_camera = null


	# Guarda a câmera específica desta cutscene.
	current_cutscene_camera = cutscene_camera

	cutscene_active = true


	# Bloqueia o player.
	player.set_controls_enabled(false)

	player.idle_timer = 0.0
	player.idle_state = 0


	if activate_camera_immediately:
		activate_cutscene_camera()


	return true


# =========================================================
# ACTIVATE CUTSCENE CAMERA
# =========================================================

func activate_cutscene_camera() -> void:
	if not cutscene_active:
		push_warning(
			"CutsceneManager: nenhuma cutscene está ativa."
		)
		return

	if current_cutscene_camera == null:
		push_error(
			"CutsceneManager: não existe CutsceneCamera atual."
		)
		return

	current_cutscene_camera.make_current()


# =========================================================
# RESTORE PREVIOUS CAMERA
# =========================================================

func restore_previous_camera() -> void:
	if previous_camera == null:
		return

	if not is_instance_valid(previous_camera):
		return

	previous_camera.make_current()


# =========================================================
# END CUTSCENE
# =========================================================

func end_cutscene() -> void:
	if not cutscene_active:
		return


	restore_previous_camera()


	if player != null:
		player.idle_timer = 0.0
		player.idle_state = 0

		player.set_controls_enabled(true)


	cutscene_active = false

	current_cutscene_camera = null
	previous_camera = null


# =========================================================
# ABORT
# =========================================================

func abort_cutscene() -> void:
	end_cutscene()


# =========================================================
# GETTERS
# =========================================================

func get_previous_camera() -> Camera3D:
	return previous_camera


func get_cutscene_camera() -> Camera3D:
	return current_cutscene_camera


func is_cutscene_active() -> bool:
	return cutscene_active
