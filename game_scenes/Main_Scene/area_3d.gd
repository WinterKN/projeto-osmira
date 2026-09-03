extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	animation_player.animation_finished.connect(_on_animation_finished)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	


@onready var animation_player = $"../Teste"

var camera_anterior: Camera3D

	

func _on_body_entered(body):
	if body.name == "Player":
		camera_anterior = get_viewport().get_camera_3d()
		animation_player.play("Ending")

func _on_animation_finished(anim_name):
	if anim_name == "Ending":
		if camera_anterior:
			camera_anterior.make_current()
