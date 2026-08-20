class_name interactable extends Node
@export var interaction_ui: Node



@export var player: Player
var ui_esta_visivel: bool = false

	
func _unhandled_input(event: InputEvent) -> void:
	# Só permite interagir com a tecla "E" (ação "interact") se a UI estiver visível
	if event.is_action_pressed("interact") and ui_esta_visivel:
		print("Interagiu com o objeto!")
		queue_free()
		# Coloque aqui a lógica do que acontece quando o jogador interage
	
func _on_trigger_body_entered(body: Node3D) -> void:
	print("enter")

# --- BUSCA A UI DE INTERAÇÃO PELO GRUPO ---
	if interaction_ui != null:
			print("oi")
			interaction_ui.set_text("[E] INTERAGIR")
			interaction_ui.alternar_visibilidade(true)
			ui_esta_visivel = true # Atualiza o estado para visível

	else:
			push_error("ERRO: UI de interação não foi encontrada no grupo 'ui_interacao'!")
	if interaction_ui == null:

		var uis = get_tree().get_nodes_in_group("ui_interacao")
		if uis.size() == 1:
			print("ao")
			interaction_ui = uis[0]
			interaction_ui.alternar_visibilidade(false)
			ui_esta_visivel = false # Atualiza o estado para invisível
			# Se encontrou a UI, executa o código normalmente


func _on_trigger_body_exited(body: Node3D) -> void:
	print("leave")
	if interaction_ui != null:
		interaction_ui.alternar_visibilidade(false)
	ui_esta_visivel = false # Atualiza o estado para invisível
