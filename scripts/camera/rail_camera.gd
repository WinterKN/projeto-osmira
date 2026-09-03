class_name RailCamera
extends Path3D

@export var camera: fixedCamera

# Distância que a câmera fica atrás do ponto mais próximo do player.
@export var follow_offset: float = 0.0

# Suavização.
@export var follow_speed: float = 8.0

@onready var path_follow: PathFollow3D = $PathFollow3D


func _physics_process(delta: float) -> void:
	if camera == null:
		return

	if not camera.current:
		return

	if camera.player == null:
		return

	# Posição global do player.
	var player_global_position: Vector3 = camera.player.global_position

	# Converte para o espaço local do Path3D.
	var player_local_position: Vector3 = to_local(player_global_position)

	# Ponto da curva mais próximo do player.
	var closest_offset: float = curve.get_closest_offset(
		player_local_position
	)

	# Faz a câmera ficar um pouco atrás.
	var target_progress: float = closest_offset - follow_offset

	# Impede sair antes do começo da curva.
	target_progress = clamp(
		target_progress,
		0.0,
		curve.get_baked_length()
	)

	# Movimento suave.
	path_follow.progress = lerp(
		path_follow.progress,
		target_progress,
		1.0 - exp(-follow_speed * delta)
	)
