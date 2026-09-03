extends Area3D

@onready var animation_player: AnimationPlayer = $"../Ending"

var camera_anterior: Camera3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)
		print("✅ AnimationPlayer encontrado com sucesso!")
	else:
		push_warning("❌ ERRO: AnimationPlayer '../Teste' NÃO foi encontrado na hierarquia!")


func _on_body_entered(body: Node3D) -> void:
	print("🟢 Algo colidiu com a Area3D: ", body.name)
	
	# Usando is_in_group ou checagem de nome flexível
	if body.name == "Player" or body.is_in_group("player"):
		print("✅ Player confirmado! Tentando tocar animação...")
		camera_anterior = get_viewport().get_camera_3d()
		
		if animation_player:
			if animation_player.has_animation("Ending"):
				animation_player.play("Ending")
				print("🎬 Animação 'Ending' iniciada!")
			else:
				print("❌ ERRO: A animação 'Ending' não existe no AnimationPlayer!")


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Ending":
		print("🏁 Cutscene finalizada.")
		if camera_anterior:
			camera_anterior.make_current()	
