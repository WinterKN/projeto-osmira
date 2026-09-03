class_name interactable
extends Node3D

@export var interaction_ui: Node
@export var fixed_camera: fixedCamera
@export var dialogues: Dialogues
@export var player: Player
@export var person: GameManager.PERSON

@export_file("*.txt") var arquivo_dialogo_txt: String

@export_group("NPC")
@export var npc: Node3D
@export var npc_animation_player: AnimationPlayer
@export var idle_animation: StringName = &"idle"
@export var talk_animation: StringName = &"talk"
@export var talk_animation_2: StringName = &"talk_2"
@export var npc_turn_speed: float = 5.0
@export var npc_forward_offset: float = 0.0
@export var restore_npc_rotation: bool = true

@export_group("Player Rotation")
@export var player_turn_speed: float = 5.0
@export var player_forward_offset: float = 0.0

var ui_esta_visivel: bool = false
var em_interacao: bool = false
var player_no_trigger: bool = false

var original_camera_transform: Transform3D
var camera_estava_seguindo: bool = false

var npc_original_rotation_y: float = 0.0

var ultima_animacao_fala: StringName = &""


func _ready() -> void:
	var player_group = get_tree().get_nodes_in_group("player")

	if player_group.size() == 1:
		print("Achou o player pelo grupo 'player'")
		player = player_group[0]

	var dialog_group = get_tree().get_nodes_in_group("dialog")

	if dialog_group.size() == 1:
		print("Achou o dialogo pelo grupo 'dialog'")
		dialogues = dialog_group[0]

	if fixed_camera:
		original_camera_transform = fixed_camera.global_transform

		if fixed_camera.follow_player:
			camera_estava_seguindo = true

	if npc:
		npc_original_rotation_y = npc.rotation.y


func _process(delta: float) -> void:
	if not em_interacao:
		return

	if npc == null or player == null:
		return

	rotacionar_npc_para_player(delta)
	rotacionar_player_para_npc(delta)


func rotacionar_npc_para_player(delta: float) -> void:
	var direction: Vector3 = player.global_position - npc.global_position
	direction.y = 0.0

	if direction.length_squared() < 0.001:
		return

	var target_rotation: float = atan2(
		direction.x,
		direction.z
	)

	target_rotation += deg_to_rad(npc_forward_offset)

	npc.rotation.y = lerp_angle(
		npc.rotation.y,
		target_rotation,
		npc_turn_speed * delta
	)


func rotacionar_player_para_npc(delta: float) -> void:
	var direction: Vector3 = npc.global_position - player.global_position
	direction.y = 0.0

	if direction.length_squared() < 0.001:
		return

	var target_rotation: float = atan2(
		direction.x,
		direction.z
	)

	target_rotation += deg_to_rad(player_forward_offset)

	player.rotation.y = lerp_angle(
		player.rotation.y,
		target_rotation,
		player_turn_speed * delta
	)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return

	if not ui_esta_visivel and not em_interacao:
		return

	if not em_interacao:
		iniciar_interacao()

	var dialogo_ativo: bool = false

	if dialogues:
		dialogo_ativo = dialogues.avançar_dialogo()

	if not dialogo_ativo:
		encerrar_interacao()


func iniciar_interacao() -> void:
	em_interacao = true
	ultima_animacao_fala = &""

	if interaction_ui:
		interaction_ui.alternar_visibilidade(false)

	ui_esta_visivel = false

	_talk()

	if player:
		player.set_controls_enabled(false)

	if dialogues:
		if not dialogues.orador_alterado.is_connected(_on_orador_alterado):
			dialogues.orador_alterado.connect(_on_orador_alterado)

		if arquivo_dialogo_txt != "":
			dialogues.carregar_dialogo_txt(arquivo_dialogo_txt)

	if fixed_camera:
		var tween = create_tween().set_parallel(true)

		if fixed_camera.follow_player:
			fixed_camera.follow_player = false

		fixed_camera.follow_object = true
		fixed_camera.object = self

		tween.tween_property(
			fixed_camera,
			"fov",
			35.0,
			0.3
		).set_trans(Tween.TRANS_SINE)


func _on_orador_alterado(orador: String) -> void:
	if orador == "npc":
		if fixed_camera:
			fixed_camera.follow_player = false
			fixed_camera.follow_object = true
			fixed_camera.object = self

		tocar_animacao_fala_aleatoria()

	elif orador == "player":
		if fixed_camera:
			fixed_camera.follow_object = false
			fixed_camera.follow_player = true

		voltar_npc_para_idle()


func tocar_animacao_fala_aleatoria() -> void:
	if npc_animation_player == null:
		return

	var animacoes: Array[StringName] = []

	if npc_animation_player.has_animation(talk_animation):
		animacoes.append(talk_animation)

	if npc_animation_player.has_animation(talk_animation_2):
		animacoes.append(talk_animation_2)

	if animacoes.is_empty():
		return

	if animacoes.size() == 1:
		ultima_animacao_fala = animacoes[0]
		npc_animation_player.play(ultima_animacao_fala)
		return

	var animacao_escolhida: StringName = animacoes.pick_random()

	while animacao_escolhida == ultima_animacao_fala:
		animacao_escolhida = animacoes.pick_random()

	ultima_animacao_fala = animacao_escolhida

	npc_animation_player.stop()
	npc_animation_player.play(animacao_escolhida)
	npc_animation_player.seek(0.0, true)


func voltar_npc_para_idle() -> void:
	if npc_animation_player == null:
		return

	npc_animation_player.stop()

	if npc_animation_player.has_animation(idle_animation):
		npc_animation_player.play(idle_animation)
		npc_animation_player.seek(0.0, true)


func encerrar_interacao() -> void:
	em_interacao = false
	ultima_animacao_fala = &""

	if player:
		player.set_controls_enabled(true)

	voltar_npc_para_idle()

	if npc and restore_npc_rotation:
		var tween_npc = create_tween()

		tween_npc.tween_property(
			npc,
			"rotation:y",
			npc_original_rotation_y,
			0.4
		).set_trans(Tween.TRANS_SINE)

	if dialogues:
		if dialogues.orador_alterado.is_connected(_on_orador_alterado):
			dialogues.orador_alterado.disconnect(_on_orador_alterado)

	if fixed_camera:
		fixed_camera.follow_object = false
		fixed_camera.object = null

		var tween = create_tween()

		tween.tween_property(
			fixed_camera,
			"fov",
			75.0,
			0.3
		).set_trans(Tween.TRANS_SINE)

		if camera_estava_seguindo:
			fixed_camera.follow_player = true

		else:
			var tween_pos = create_tween()

			tween_pos.tween_property(
				fixed_camera,
				"global_transform",
				original_camera_transform,
				0.3
			).set_trans(Tween.TRANS_SINE)

	if player_no_trigger and interaction_ui:
		interaction_ui.set_text("[E] INTERAGIR")
		interaction_ui.alternar_visibilidade(true)
		ui_esta_visivel = true
	else:
		ui_esta_visivel = false


func _talk() -> void:
	var ownDoneQuest = GameManager.own_quest_done(person)

	if ownDoneQuest:
		GameManager.quest_done(ownDoneQuest)
	else:
		GameManager.talk_with(person)


func _on_trigger_body_entered(body: Node3D) -> void:
	print("enter")

	if body != player:
		return

	player_no_trigger = true

	if interaction_ui == null:
		var uis = get_tree().get_nodes_in_group("ui_interacao")

		if uis.size() == 1:
			print("ao")

			interaction_ui = uis[0]
			interaction_ui.alternar_visibilidade(false)
			ui_esta_visivel = false

	if interaction_ui != null and not em_interacao:
		print("oi")

		interaction_ui.set_text("[E] INTERAGIR")
		interaction_ui.alternar_visibilidade(true)
		ui_esta_visivel = true

	elif interaction_ui == null:
		push_error(
			"ERRO: UI de interação não foi encontrada no grupo 'ui_interacao'!"
		)


func _on_trigger_body_exited(body: Node3D) -> void:
	print("leave")

	if body != player:
		return

	player_no_trigger = false

	if interaction_ui != null:
		interaction_ui.alternar_visibilidade(false)

	ui_esta_visivel = false
