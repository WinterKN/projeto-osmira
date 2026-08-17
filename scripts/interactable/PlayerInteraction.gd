# PlayerInteraction.gd
extends RayCast3D

@export var interaction_ui: Node


func _physics_process(_delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		
		# Verify if the hit object is an Interactable type
		if collider is Interactable:
			#print("Raycast está olhando para: ", collider.name)
			interaction_ui.set_text("[E] " + collider.prompt_message)
			interaction_ui.alternar_visibilidade(true)

			
			# Check if the player presses the interaction button
			if Input.is_action_just_pressed("interact"):
				# 1. Buscamos o nó do inventário na árvore de cenas usando o grupo
				var inventarios = get_tree().get_nodes_in_group("gerenciador_inventario")
				
				# 2. Verificamos se ele realmente foi encontrado
				if inventarios.size() > 0:
					var inventory_controller = inventarios[0] as InventoryController
					# 3. Passamos o controlador encontrado para o objeto interagir!
					collider.interact(inventory_controller)
				else:
					push_error("ERRO: O Raycast não encontrou nenhum nó no grupo 'gerenciador_inventario'!")
			return
			
	# Hide the UI prompt if not looking at an interactable object
	interaction_ui.alternar_visibilidade(false)
