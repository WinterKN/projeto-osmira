class_name interactable extends Node
@export var interaction_ui: Node


@export var fixed_camera: fixedCamera

@export var player: Player
var ui_esta_visivel: bool = false
var interagivel: bool = true
var original_camera_transform: Transform3D

func _ready() -> void:
	var player_group = get_tree().get_nodes_in_group("player")
	if player_group.size() == 1:
		print("Achou o player pelo grupo 'player'")
		player = player_group[0]
		
	if fixed_camera:
		original_camera_transform = fixed_camera.global_transform
	
func _unhandled_input(event: InputEvent) -> void:
	# Só permite interagir com a tecla "E" (ação "interact") se a UI estiver visível
	if event.is_action_pressed("interact") and ui_esta_visivel:
		print("Interagiu com o objeto!")
		#olhar para o objeto
		var tween = create_tween().set_parallel(true)
		if interagivel == false:
			fixed_camera.follow_object = false
			fixed_camera.object = null
			
			tween.tween_property(fixed_camera, "fov", 75.0, 0.3).set_trans(Tween.TRANS_SINE)
			tween.tween_property(fixed_camera, "global_transform", original_camera_transform, 0.3).set_trans(Tween.TRANS_SINE)
				
			interagivel = true
			player.set_controls_enabled(true)
		elif interagivel == true:
			fixed_camera.follow_object = true
			fixed_camera.object = self
			tween.tween_property(fixed_camera, "fov", 35.0, 0.3).set_trans(Tween.TRANS_SINE)
			interagivel = false
			player.set_controls_enabled(false)
			
		
			
		
		
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
