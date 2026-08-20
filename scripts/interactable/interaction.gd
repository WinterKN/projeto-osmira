class_name interactable extends Node
@export var interaction_ui: Node



@export var player: Player


	
func _on_trigger_body_entered(body: Node3D) -> void:
	print("enter")
	
# --- BUSCA A UI DE INTERAÇÃO PELO GRUPO ---
	if interaction_ui == null:

		var uis = get_tree().get_nodes_in_group("ui_interacao")
		if uis.size() == 1:
			print("ao")
			interaction_ui = uis[0]
			interaction_ui.alternar_visibilidade(false)
			# Se encontrou a UI, executa o código normalmente
	if interaction_ui != null:
			print("oi")
			interaction_ui.set_text("[E] INTERAGIR")
			interaction_ui.alternar_visibilidade(true)

	else:
			push_error("ERRO: UI de interação não foi encontrada no grupo 'ui_interacao'!")

func _on_trigger_body_exited(body: Node3D) -> void:
	print("leave")
	interaction_ui.alternar_visibilidade(false)
	


func _on_area_3d_body_entered(body: Node3D) -> void:
	pass # Replace with function body.


func _on_area_3d_body_exited(body: Node3D) -> void:
	pass # Replace with function body.
