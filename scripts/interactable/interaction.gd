class_name interactable extends Node
@export var interaction_ui: Node



@export var player: Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_trigger_body_entered(body: Node3D) -> void:
	print("enter")
	#interaction_label.alternar_visibilidade(true)
# --- BUSCA A UI DE INTERAÇÃO PELO GRUPO ---
	if interaction_ui == null:
		print("oi")
		var uis = get_tree().get_nodes_in_group("ui_interacao")
		if uis.size() > 0:
			interaction_ui = uis[0]
			
			# Se encontrou a UI, executa o código normalmente
		if interaction_ui != null:
			interaction_ui.set_text("[E] INTERAÇÃO")
			interaction_ui.alternar_visibilidade(false)
		else:
			push_error("ERRO: UI de interação não foi encontrada no grupo 'ui_interacao'!")

func _on_trigger_body_exited(body: Node3D) -> void:
	print("leave")
	if interaction_ui == null:
		var uis = get_tree().get_nodes_in_group("ui_interacao")
		if uis.size() > 0:
			interaction_ui = uis[0]
			
			# Se encontrou a UI, executa o código normalmente
		if interaction_ui != null:
			interaction_ui.set_text("")
			interaction_ui.alternar_visibilidade(false)
		else:
			push_error("ERRO: UI de interação não foi encontrada no grupo 'ui_interacao'!")
