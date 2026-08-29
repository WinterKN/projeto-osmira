extends Camera3D

class_name fixedCamera



@export var follow_player := false
@export var follow_object := false
@export var object: interactable = null
var player: Player = null


func _physics_process(delta: float) -> void:
	if follow_player and player:
		look_at(player.global_position)
	elif follow_object and object:
		look_at(object.global_position)

func _on_trigger_body_entered(body: Node3D) -> void:
	if body is Player:
		if not body.controls_enabled:
			return

		player = body

		make_current()
