class_name fixedCamera
extends Camera3D


# ============================================================
# FOLLOW
# ============================================================

@export_group("Follow")

@export var follow_player := false

@export var follow_object := false

@export var object: Node3D = null


# Altura do ponto que a câmera olha no player.
# 0.0 = origem do Player
# 1.0 ~ 1.5 = aproximadamente tronco/cabeça
@export var follow_height := 1.2

# ============================================================
# MODO DE FOLLOW
# ============================================================

enum FollowMode {
	FULL,
	HORIZONTAL_ONLY
}

@export var follow_mode: FollowMode = FollowMode.FULL

var player: Player = null

func _physics_process(_delta: float) -> void:

	# --------------------------------------------------------
	# Câmeras que não estão sendo usadas NÃO podem continuar
	# alterando sua rotação.
	# --------------------------------------------------------

	if not current:
		return

	if follow_player and player != null:

		follow_target(player.global_position)
		return

	if follow_object and object != null:
		follow_target(object.global_position)

func follow_target(
	target_position: Vector3
) -> void:

	# --------------------------------------------------------
	# FOLLOW COMPLETO
	# A câmera pode olhar para cima/baixo e esquerda/direita.
	# --------------------------------------------------------

	if follow_mode == FollowMode.FULL:

		target_position.y += follow_height

		look_at(target_position, Vector3.UP)

	# --------------------------------------------------------
	# FOLLOW SOMENTE HORIZONTAL
	# A câmera gira somente para esquerda/direita.
	# --------------------------------------------------------

	elif follow_mode == FollowMode.HORIZONTAL_ONLY:

		target_position.y = global_position.y


		look_at(target_position, Vector3.UP)

func _on_trigger_body_entered(
	body: Node3D
) -> void:

	if not body is Player:
		return

	# --------------------------------------------------------
	# NÃO TROCAR A CÂMERA DURANTE A CUTSCENE E CONTROLES BLOQUEADOS
	# --------------------------------------------------------

	if not body.controls_enabled:
		return

	player = body
	make_current()
