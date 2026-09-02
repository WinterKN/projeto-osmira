class_name BaseCutscene
extends Node3D


# =========================================================
# SYSTEM
# =========================================================

@export_group("System")

@export var cutscene_manager: CutsceneManager


# =========================================================
# CAMERA
# =========================================================

@export_group("Camera")

@export var cutscene_camera: Camera3D


# =========================================================
# CUTSCENE ANIMATION
# =========================================================

@export_group("Cutscene Animation")

@export var cutscene_animation_player: AnimationPlayer

@export var cutscene_animation: StringName = &""


# =========================================================
# PLAYER ANIMATION
# =========================================================

@export_group("Player Animation")

@export var player_animation: AnimationPlayer

@export var player_cutscene_animation: StringName = &""

@export var player_idle_animation: StringName = &"Animações/player_idle"


# =========================================================
# BEHAVIOUR
# =========================================================

@export_group("Behaviour")

@export var play_once := true
@export var auto_start_on_trigger := true


# =========================================================
# STATE
# =========================================================

var played := false
var cutscene_active := false
var cutscene_finished := false


# =========================================================
# READY
# =========================================================

func _ready() -> void:
	if cutscene_animation_player == null:
		cutscene_animation_player = get_node_or_null(
			"AnimationPlayer"
		) as AnimationPlayer

	if cutscene_camera == null:
		cutscene_camera = get_node_or_null(
			"CutsceneCamera"
		) as Camera3D


# =========================================================
# VALIDATION
# =========================================================

func validate_references() -> bool:
	if cutscene_manager == null:
		push_error(
			name + ": CutsceneManager não configurado."
		)
		return false

	if cutscene_camera == null:
		push_error(
			name + ": CutsceneCamera não configurada."
		)
		return false

	if cutscene_animation_player == null:
		push_error(
			name + ": AnimationPlayer não configurado."
		)
		return false

	return true


# =========================================================
# START CUTSCENE
# =========================================================

func start_cutscene() -> void:
	if cutscene_active:
		return

	if play_once and played:
		return

	if not validate_references():
		return


	played = true
	cutscene_active = true
	cutscene_finished = false


	if not cutscene_manager.begin_cutscene(
		cutscene_camera
	):
		cutscene_active = false
		return


	# =====================================================
	# PLAYER ANIMATION
	# =====================================================

	if player_animation != null:
		if player_cutscene_animation != &"":
			player_animation.play(
				player_cutscene_animation
			)


	# =====================================================
	# CUTSCENE ANIMATION
	# =====================================================

	if cutscene_animation != &"":
		if cutscene_animation_player.has_animation(
			cutscene_animation
		):
			cutscene_animation_player.play(
				cutscene_animation
			)

			await wait_for_cutscene_animation()


	if cutscene_finished:
		return


	end_cutscene()


# =========================================================
# WAIT CUTSCENE ANIMATION
# =========================================================

func wait_for_cutscene_animation() -> void:
	while cutscene_animation_player.is_playing():

		if cutscene_finished:
			return

		await get_tree().process_frame


# =========================================================
# END CUTSCENE
# =========================================================

func end_cutscene() -> void:
	if cutscene_finished:
		return


	cutscene_finished = true
	cutscene_active = false


	if cutscene_animation_player != null:
		if cutscene_animation_player.is_playing():
			cutscene_animation_player.stop()


	if player_animation != null:
		if player_idle_animation != &"":
			player_animation.play(
				player_idle_animation
			)


	if cutscene_manager != null:
		cutscene_manager.end_cutscene()


# =========================================================
# FORCE STOP
# =========================================================

func stop_cutscene() -> void:
	if not cutscene_active:
		return


	cutscene_finished = true
	cutscene_active = false


	if cutscene_animation_player != null:
		if cutscene_animation_player.is_playing():
			cutscene_animation_player.stop()


	if player_animation != null:
		if player_animation.is_playing():
			player_animation.stop()

		if player_idle_animation != &"":
			player_animation.play(
				player_idle_animation
			)


	if cutscene_manager != null:
		cutscene_manager.abort_cutscene()


# =========================================================
# TRIGGER
# =========================================================

func _on_trigger_body_entered(body: Node3D) -> void:
	if not auto_start_on_trigger:
		return

	if not body is Player:
		return

	start_cutscene()
