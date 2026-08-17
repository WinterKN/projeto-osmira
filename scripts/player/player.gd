class_name Player extends CharacterBody3D

@export_group("Movement Settings")
@export var turn_speed := 180.0
@export var quick_turn_speed := 0.2
@export var walk_speed := 80.0
@export var run_speed := 280.0

@export_group("Animation Settings")
@export var animation_player: AnimationPlayer
@export var default_blend_time := 0.5

@export_group("Idle Settings")
@export var idle_start_time := 8.0
@export var idle_pose_time := 6.0

var idle_timer := 0.0
var idle_state := 0

const GRAVITY = -9.81
var is_quick_turning := false
var controls_enabled := true

func handle_turn(delta):
	var turn_dir = Input.get_axis("turn_left", "turn_right")
	rotation_degrees.y -= turn_dir * turn_speed * delta

func handle_walk(delta):
	var inpur_dir = Input.get_axis("move_backward", "move_forward")
	var walk_velocity = basis.z * inpur_dir * walk_speed * delta
	velocity.x = walk_velocity.x
	velocity.z = walk_velocity.z
	
func handle_run(delta):
	if Input.is_action_pressed("move_backward"):
		handle_walk(delta)
		return
	
	var input_strength = Input.get_action_strength("move_forward")
	var walk_velocity = basis.z * input_strength * run_speed * delta
	velocity.x = walk_velocity.x
	velocity.z = walk_velocity.z
	
func handle_gravity(delta):
	if is_on_floor():
		velocity.y = -2
	else:
		velocity.y += GRAVITY * delta
		
func quick_turn():
	is_quick_turning = true
	
	var target_y_rotation = rotation.y + PI
	
	var tween := create_tween()
	tween.tween_property(self, "rotation:y", target_y_rotation, quick_turn_speed)
	
	tween.finished.connect(func():
		is_quick_turning = false
	)
	
func set_controls_enabled(value: bool) -> void:
	controls_enabled = value

	if not controls_enabled:
		velocity.x = 0.0
		velocity.z = 0.0
	
func handle_animation(delta):
	var input_vector = Input.get_vector(
		"turn_left",
		"turn_right",
		"move_backward",
		"move_forward"
	)

	if input_vector == Vector2.ZERO:
		handle_idle(delta)
		return

	# Se houve qualquer input, cancela o idle especial
	idle_timer = 0.0
	idle_state = 0

	if input_vector.y > 0:
		if Input.is_action_pressed("run") and not is_quick_turning:
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

	elif input_vector.x < 0:
		animation_player.play(
			"Animações/player_turnLeft",
			default_blend_time
		)

	elif input_vector.x > 0:
		animation_player.play(
			"Animações/player_turnRight",
			default_blend_time
		)
		
func handle_idle(delta):
	idle_timer += delta

	match idle_state:
		# Idle padrão
		0:
			if animation_player.current_animation != "Animações/player_idle":
				animation_player.play("Animações/player_idle", default_blend_time)

			if idle_timer >= idle_start_time:
				idle_timer = 0.0
				idle_state = 1


		# Apoiado na esquerda
		1:
			if animation_player.current_animation != "Animações/player_idle_twistL":
				animation_player.play("Animações/player_idle_twistL", default_blend_time)

			if idle_timer >= idle_pose_time:
				idle_timer = 0.0
				idle_state = 2

				animation_player.play(
					"Animações/player_idle_twistL_to_twistR", default_blend_time)


		# Transição esquerda -> direita
		2:
			if not animation_player.is_playing():
				idle_timer = 0.0
				idle_state = 3


		# Apoiado na direita
		3:
			if animation_player.current_animation != "Animações/player_idle_twistR":
				animation_player.play("Animações/player_idle_twistR", default_blend_time)

			if idle_timer >= idle_pose_time:
				idle_timer = 0.0
				idle_state = 4

				animation_player.play(
					"Animações/player_idle_twistR_to_twistL", default_blend_time)


		# Transição direita -> esquerda
		4:
			if not animation_player.is_playing():
				idle_timer = 0.0
				idle_state = 1
	
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
		velocity.x = 0
		velocity.z = 0
	
	move_and_slide()
	
	handle_animation(delta)
	
func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled:
		return

	if Input.is_action_just_pressed("quick_turn") and not is_quick_turning:
		quick_turn()
