extends CharacterBody3D

# Player Nodes

@onready var neck = $neck
@onready var head = $neck/head
@onready var eyes = $neck/head/eyes

@onready var standing_collision_shape = $standing_collision_shape
@onready var crounching_collision_shape = $crounching_collision_shape
@onready var ray_cast_3d = $RayCast3D
@onready var camera_3d = $neck/head/eyes/Camera3D
@onready var animation_player = $neck/head/eyes/AnimationPlayer
@onready var player_head = $body/Player/Armature/Skeleton3D/PlayerHead

@onready var animation_tree = $body/Player/AnimationTree
@onready var state_machine = animation_tree["parameters/playback"]


# Speed Variables

var current_speed = 5.0

@export var walking_speed = 5.0
@export var sprinting_speed = 8.0
@export var crounching_speed = 3.0


# States

var walking = false
var sprinting = false
var crounching = false
var landing = false

# Tempo da animação de aterrissagem
var landing_timer = 0.0

# Ajuste esses valores conforme a duração real das suas animações
@export var normal_landing_time = 0.7
@export var hard_landing_time = 1.55


# Head Bobbing Variables

const head_bobbing_sprinting_speed = 18.0
const head_bobbing_walking_speed = 12.0
const head_bobbing_crounching_speed = 10.0

const head_bobbing_sprinting_intensity = 0.2
const head_bobbing_walking_intensity = 0.1
const head_bobbing_crounching_intensity = 0.05

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_intensity = 0.0


# Movement Variables

const jump_velocity = 4.5
var crounching_depth = -0.8
var lerp_speed = 10.0
var air_lerp_speed = 3.0
var last_velocity = Vector3.ZERO
var fall_time = 0.0


# Check Fall Speed

var was_on_floor = true


# Input Variables

var direction = Vector3.ZERO
const mouse_sens = 0.25


func _ready():

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	player_head.visible = true
	player_head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY

	animation_tree.active = true


func _input(event):

	# Mouse Looking Logic

	if event is InputEventMouseMotion:

		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))

		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))

		head.rotation.x = clamp(
			head.rotation.x,
			deg_to_rad(-70),
			deg_to_rad(80)
		)


func _physics_process(delta):

	var input_dir = Input.get_vector(
		"left",
		"right",
		"forward",
		"backward"
	)


	# --------------------------------------------------
	# LANDING TIMER
	# --------------------------------------------------

	if landing:

		landing_timer -= delta

		if landing_timer <= 0.0:

			landing = false


	# --------------------------------------------------
	# MOVEMENT STATE
	# --------------------------------------------------

	# Crouching

	if Input.is_action_pressed("crounch") and is_on_floor():

		current_speed = lerp(
			current_speed,
			crounching_speed,
			delta * lerp_speed
		)

		head.position.y = lerp(
			head.position.y,
			crounching_depth,
			delta * lerp_speed
		)

		standing_collision_shape.disabled = true
		crounching_collision_shape.disabled = false

		walking = false
		sprinting = false
		crounching = true


	elif !ray_cast_3d.is_colliding():

		# Standing

		standing_collision_shape.disabled = false
		crounching_collision_shape.disabled = true

		head.position.y = lerp(
			head.position.y,
			0.0,
			delta * lerp_speed
		)


		if Input.is_action_pressed("sprint"):

			# Sprinting

			current_speed = lerp(
				current_speed,
				sprinting_speed,
				delta * lerp_speed
			)

			walking = false
			sprinting = true
			crounching = false


		else:

			# Walking

			current_speed = lerp(
				current_speed,
				walking_speed,
				delta * lerp_speed
			)

			walking = true
			sprinting = false
			crounching = false


		# --------------------------------------------------
		# HEAD BOBBING
		# --------------------------------------------------

		if sprinting:

			head_bobbing_current_intensity = head_bobbing_sprinting_intensity
			head_bobbing_index += head_bobbing_sprinting_speed * delta

		elif walking:

			head_bobbing_current_intensity = head_bobbing_walking_intensity
			head_bobbing_index += head_bobbing_walking_speed * delta

		elif crounching:

			head_bobbing_current_intensity = head_bobbing_crounching_intensity
			head_bobbing_index += head_bobbing_crounching_speed * delta


		if is_on_floor() && input_dir != Vector2.ZERO:

			head_bobbing_vector.y = sin(head_bobbing_index)
			head_bobbing_vector.x = sin(head_bobbing_index / 2) + 0.5

			eyes.position.y = lerp(
				eyes.position.y,
				head_bobbing_vector.y * (head_bobbing_current_intensity / 2.0),
				delta * lerp_speed
			)

			eyes.position.x = lerp(
				eyes.position.x,
				head_bobbing_vector.x * head_bobbing_current_intensity,
				delta * lerp_speed
			)

		else:

			eyes.position.y = lerp(
				eyes.position.y,
				0.0,
				delta * lerp_speed
			)

			eyes.position.x = lerp(
				eyes.position.x,
				0.0,
				delta * lerp_speed
			)


	# --------------------------------------------------
	# GRAVITY
	# --------------------------------------------------

	if not is_on_floor():

		velocity += get_gravity() * delta

		if velocity.y < 0:

			fall_time += delta

	else:

		fall_time = 0.0


	# --------------------------------------------------
	# JUMP
	# --------------------------------------------------

	if Input.is_action_just_pressed("jump") and is_on_floor():

		velocity.y = jump_velocity

		# Efeito da câmera
		animation_player.play("jump")


	# --------------------------------------------------
	# MOVEMENT
	# --------------------------------------------------

	if is_on_floor():

		direction = lerp(
			direction,
			(transform.basis * Vector3(
				input_dir.x,
				0,
				input_dir.y
			)).normalized(),
			delta * lerp_speed
		)

	else:

		if input_dir != Vector2.ZERO:

			direction = lerp(
				direction,
				(transform.basis * Vector3(
					input_dir.x,
					0,
					input_dir.y
				)).normalized(),
				delta * air_lerp_speed
			)


	if direction:

		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed

	else:

		velocity.x = move_toward(
			velocity.x,
			0,
			current_speed
		)

		velocity.z = move_toward(
			velocity.z,
			0,
			current_speed
		)


	# Guarda a velocidade ANTES do move_and_slide
	last_velocity = velocity

	move_and_slide()


	# --------------------------------------------------
	# LANDING
	# --------------------------------------------------

	if is_on_floor() and not was_on_floor:

		if last_velocity.y < -10.0:

			landing = true
			landing_timer = hard_landing_time

			state_machine.travel("Hard Land")


		elif last_velocity.y < -4.0:

			landing = true
			landing_timer = normal_landing_time

			state_machine.travel("Land")


	# --------------------------------------------------
	# ANIMATION STATE
	# --------------------------------------------------

	if landing:

		# Não sobrescreve a animação de aterrissagem
		pass


	elif not is_on_floor():

		if velocity.y > 0:

			state_machine.travel("Jump")

		elif fall_time < 0.35:

			state_machine.travel("JumpDown")

		else:

			state_machine.travel("Fall")


	elif sprinting and input_dir != Vector2.ZERO:

		state_machine.travel("Run")


	elif input_dir != Vector2.ZERO:

		state_machine.travel("Walk")


	else:

		state_machine.travel("Idle")


	# Atualiza estado do chão
	was_on_floor = is_on_floor()
