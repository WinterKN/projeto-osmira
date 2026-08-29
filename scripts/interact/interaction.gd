class_name interactable extends Node

@export var interaction_ui: Node
@export var fixed_camera: fixedCamera
@export var dialogues : Dialogues
@export var player: Player

@export_file("*.txt") var arquivo_dialogo_txt: String

var ui_esta_visivel: bool = false
var em_interacao: bool = false
var original_camera_transform: Transform3D
var camera_estava_seguindo: bool = false

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
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and ui_esta_visivel:
		
		# Primeira interação: carrega o arquivo TXT, ajusta câmera e trava o player
		if not em_interacao:
			em_interacao = true
			if player:
				player.set_controls_enabled(false)
			
			# Carrega o TXT no array ANTES de avançar o diálogo
			if dialogues and arquivo_dialogo_txt != "":
				dialogues.carregar_dialogo_txt(arquivo_dialogo_txt)
			
			if fixed_camera:
				var tween = create_tween().set_parallel(true)
				if fixed_camera.follow_player == true:
					fixed_camera.follow_player = false
					
				fixed_camera.follow_object = true
				fixed_camera.object = self
				tween.tween_property(fixed_camera, "fov", 35.0, 0.3).set_trans(Tween.TRANS_SINE)

		var dialogo_ativo: bool = false
		if dialogues:
			dialogo_ativo = dialogues.avançar_dialogo()

		# Se o diálogo acabou (retornou false), encerra a interação
		if not dialogo_ativo:
			encerrar_interacao()
func encerrar_interacao() -> void:
	em_interacao = false
	if player:
		player.set_controls_enabled(true)
	
	#if camera_estava_seguindo == true:
		#fixed_camera.follow_player = true
		
	if fixed_camera:
		# 1. Desliga o foco no objeto
		fixed_camera.follow_object = false
		fixed_camera.object = null
		
		# 2. O Tween cuida APENAS do FOV (zoom) abrindo de volta
		var tween = create_tween()
		tween.tween_property(fixed_camera, "fov", 75.0, 0.3).set_trans(Tween.TRANS_SINE)
		
		# 3. Se ela acompanhava o player, reativa o acompanhamento DE IMEDIATO
		if camera_estava_seguindo:
			fixed_camera.follow_player = true
		else:
			# Se era uma câmera estática, aí sim fazemos o Tween para a posição original
			var tween_pos = create_tween()
			tween_pos.tween_property(fixed_camera, "global_transform", original_camera_transform, 0.3).set_trans(Tween.TRANS_SINE)
	
func _on_trigger_body_entered(body: CharacterBody3D) -> void:
	print("enter")
	# --------Codigo antigo (deixar) ---------
	if interaction_ui == null:
		var uis = get_tree().get_nodes_in_group("ui_interacao")
		if uis.size() == 1:
			print("ao")
			interaction_ui = uis[0]
			interaction_ui.alternar_visibilidade(false)
			ui_esta_visivel = false
			
# --- BUSCA A UI DE INTERAÇÃO PELO GRUPO ---
	if interaction_ui != null:
			print("oi")
			interaction_ui.set_text("[E] INTERAGIR")
			interaction_ui.alternar_visibilidade(true)
			ui_esta_visivel = true # Atualiza o estado para visível

	else:
			push_error("ERRO: UI de interação não foi encontrada no grupo 'ui_interacao'!")
	


func _on_trigger_body_exited(body: CharacterBody3D) -> void:
	print("leave")
	if interaction_ui != null:
		interaction_ui.alternar_visibilidade(false)
	ui_esta_visivel = false # Atualiza o estado para invisível
