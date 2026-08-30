extends StaticBody3D

@export var area: GameManager.AREA

var inRange



		
func _enter():
	GameManager.enter_area(area, 1)
	#queue_free()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		inRange = true
	if inRange:
		_enter()

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		inRange = false
