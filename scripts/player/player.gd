class_name Player
extends CharacterBody3D


# =========================================================
# MOVEMENT SETTINGS
# =========================================================

@export_group("Movement Settings")

@export var turn_speed := 180.0
@export var quick_turn_speed := 0.2
@export var walk_speed := 80.0
@export var run_speed := 280.0


# =========================================================
# ANIMATION SETTINGS
# =========================================================

@export_group("Animation Settings")

@export var animation_player: AnimationPlayer
@export var default_blend_time := 0.5


# =========================================================
# IDLE SETTINGS
# =========================================================

@export_group("Idle Settings")

@export var idle_start_time := 8.0
@export var idle_pose_time := 6.0


# =========================================================
# FOOTSTEP SETTINGS
# =========================================================

@export_group("Footstep Settings")

@export_enum(
	"Leaves",
	"Gravel",
	"Mud",
	"Stone",
	"Wood"
)
var footstep_surface: String = "Leaves"

@export_range(0.8, 1.2, 0.01)
var footstep_pitch_min := 0.95

@export_range(0.8, 1.2, 0.01)
var footstep_pitch_max := 1.05

@export_range(-20.0, 10.0, 0.5)
var footstep_volume_db := 0.0


# =========================================================
# NODES
# =========================================================

@onready var footstep_player: AudioStreamPlayer3D = \
	$footstepsAudio/footstepsPlayer


# =========================================================
# FOOTSTEP SOUNDS
# =========================================================

var leaves_footsteps: Array[AudioStream] = [
	preload("res://media_assets/audio/sfx/Footsteps/leaves01.ogg"),
	preload("res://media_assets/audio/sfx/Footsteps/leaves02.ogg")
]

var gravel_footsteps: Array[AudioStream] = [
	preload("res://media_assets/audio/sfx/Footsteps/gravel.ogg")
]

var mud_footsteps: Array[AudioStream] = [
	preload("res://media_assets/audio/sfx/Footsteps/mud02.ogg")
]

var stone_footsteps: Array[AudioStream] = [
	preload("res://media_assets/audio/sfx/Footsteps/stone01.ogg")
]

var wood_footsteps: Array[AudioStream] = [
	preload("res://media_assets/audio/sfx/Footsteps/wood01.ogg"),
	preload("res://media_assets/audio/sfx/Footsteps/wood02.ogg"),
	preload("res://media_assets/audio/sfx/Footsteps/wood03.ogg")
]


# =========================================================
# VARIABLES
# =========================================================

var idle_timer := 0.0
var idle_state := 0

const GRAVITY := -9.81

var is_quick_turning := false
var controls_enabled := true

var last_footstep_index := -1


# =========================================================
# READY
# =========================================================

func _ready() -> void:
	footstep_player.volume_db = footstep_volume_db
	add_to_group("player")


# =========================================================
# MOVEMENT
# =========================================================

func handle_turn(delta: float) -> void:
	var turn_dir := Input.get_axis(
		"turn_left",
		"turn_right"
	)

	rotation_degrees.y -= turn_dir * turn_speed * delta


func handle_walk(delta: float) -> void:
	var input_dir := Input.get_axis(
		"move_backward",
		"move_forward"
	)

	var walk_velocity := (
		basis.z
		* input_dir
		* walk_speed
		* delta
	)

	velocity.x = walk_velocity.x
	velocity.z = walk_velocity.z


func handle_run(delta: float) -> void:
	if Input.is_action_pressed("move_backward"):
		handle_walk(delta)
		return

	var input_strength := Input.get_action_strength(
		"move_forward"
	)

	var run_velocity := (
		basis.z
		* input_strength
		* run_speed
		* delta
	)

	velocity.x = run_velocity.x
	velocity.z = run_velocity.z


func handle_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = -2.0
	else:
		velocity.y += GRAVITY * delta


# =========================================================
# QUICK TURN
# =========================================================

func quick_turn() -> void:
	if is_quick_turning:
		return

	is_quick_turning = true

	var target_y_rotation := rotation.y + PI

	var tween := create_tween()

	tween.tween_property(
		self,
		"rotation:y",
		target_y_rotation,
		quick_turn_speed
	)

	tween.finished.connect(
		func():
			is_quick_turning = false
	)


# =========================================================
# CONTROLS
# =========================================================

func set_controls_enabled(value: bool) -> void:
	controls_enabled = value

	if not controls_enabled:
		velocity.x = 0.0
		velocity.z = 0.0


# =========================================================
# ANIMATION
# =========================================================

func handle_animation(delta: float) -> void:
	var input_vector := Input.get_vector(
		"turn_left",
		"turn_right",
		"move_backward",
		"move_forward"
	)

	if input_vector == Vector2.ZERO:
		handle_idle(delta)
		return

	# Qualquer input cancela o idle especial.
	idle_timer = 0.0
	idle_state = 0

	if input_vector.y > 0.0:

		if (
			Input.is_action_pressed("run")
			and not is_quick_turning
		):
			animation_player.play(
				"Animações/player_run",
				default_blend_time,
				1.15
			)

		else:
			animation_player.play(
				"Animações/player_walk",
				default_blend_time
			)

	elif input_vector.y < -0.2:
		animation_player.play(
			"Animações/player_walkBack",
			default_blend_time
		)

	elif input_vector.x < 0.0:
		animation_player.play(
			"Animações/player_turnLeft",
			default_blend_time
		)

	elif input_vector.x > 0.0:
		animation_player.play(
			"Animações/player_turnRight",
			default_blend_time
		)


# =========================================================
# IDLE
# =========================================================

func handle_idle(delta: float) -> void:
	idle_timer += delta

	match idle_state:

		# -----------------------------------------------------
		# IDLE PADRÃO
		# -----------------------------------------------------

		0:
			if (
				animation_player.current_animation
				!= "Animações/player_idle"
			):
				animation_player.play(
					"Animações/player_idle",
					default_blend_time
				)

			if idle_timer >= idle_start_time:
				idle_timer = 0.0
				idle_state = 1


		# -----------------------------------------------------
		# APOIADO NA ESQUERDA
		# -----------------------------------------------------

		1:
			if (
				animation_player.current_animation
				!= "Animações/player_idle_twistL"
			):
				animation_player.play(
					"Animações/player_idle_twistL",
					default_blend_time
				)

			if idle_timer >= idle_pose_time:
				idle_timer = 0.0
				idle_state = 2

				animation_player.play(
					"Animações/player_idle_twistL_to_twistR",
					default_blend_time
				)


		# -----------------------------------------------------
		# TRANSIÇÃO ESQUERDA -> DIREITA
		# -----------------------------------------------------

		2:
			if not animation_player.is_playing():
				idle_timer = 0.0
				idle_state = 3


		# -----------------------------------------------------
		# APOIADO NA DIREITA
		# -----------------------------------------------------

		3:
			if (
				animation_player.current_animation
				!= "Animações/player_idle_twistR"
			):
				animation_player.play(
					"Animações/player_idle_twistR",
					default_blend_time
				)

			if idle_timer >= idle_pose_time:
				idle_timer = 0.0
				idle_state = 4

				animation_player.play(
					"Animações/player_idle_twistR_to_twistL",
					default_blend_time
				)


		# -----------------------------------------------------
		# TRANSIÇÃO DIREITA -> ESQUERDA
		# -----------------------------------------------------

		4:
			if not animation_player.is_playing():
				idle_timer = 0.0
				idle_state = 1


# =========================================================
# FOOTSTEPS
# =========================================================

func play_footstep() -> void:
	if not controls_enabled:
		return

	if not is_on_floor():
		return

	var sounds := _get_current_footstep_sounds()

	if sounds.is_empty():
		return

	var sound_index := _get_random_footstep_index(
		sounds.size()
	)

	var sound := sounds[sound_index]

	last_footstep_index = sound_index

	footstep_player.stream = sound

	footstep_player.pitch_scale = randf_range(
		footstep_pitch_min,
		footstep_pitch_max
	)

	footstep_player.volume_db = footstep_volume_db

	footstep_player.play()


func _get_current_footstep_sounds() -> Array[AudioStream]:
	match footstep_surface:

		"Leaves":
			return leaves_footsteps

		"Gravel":
			return gravel_footsteps

		"Mud":
			return mud_footsteps

		"Stone":
			return stone_footsteps

		"Wood":
			return wood_footsteps

		_:
			return leaves_footsteps


func _get_random_footstep_index(
	sound_count: int
) -> int:

	if sound_count <= 1:
		return 0

	var new_index := randi_range(
		0,
		sound_count - 1
	)

	# Evita tocar exatamente o mesmo som
	# duas vezes seguidas.
	while new_index == last_footstep_index:
		new_index = randi_range(
			0,
			sound_count - 1
		)

	return new_index


func set_footstep_surface(
	surface: String
) -> void:

	match surface:
		"Leaves", "Gravel", "Mud", "Stone", "Wood":
			footstep_surface = surface

		_:
			push_warning(
				"Superfície de passo desconhecida: %s"
				% surface
			)


# =========================================================
# PHYSICS
# =========================================================

func _physics_process(delta: float) -> void:
	handle_gravity(delta)

	# =====================================================
	# CUTSCENE
	# =====================================================

	if not controls_enabled:
		velocity.x = 0.0
		velocity.z = 0.0

		move_and_slide()
		return


	# =====================================================
	# GAMEPLAY NORMAL
	# =====================================================

	handle_turn(delta)

	if Input.is_action_pressed("run"):
		handle_run(delta)
	else:
		handle_walk(delta)

	if is_quick_turning:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()

	handle_animation(delta)


# =========================================================
# INPUT
# =========================================================

func _unhandled_input(_event: InputEvent) -> void:
	if not controls_enabled:
		return

	if (
		Input.is_action_just_pressed("quick_turn")
		and not is_quick_turning
	):
		quick_turn()
