class_name RailCamera 
extends Path3D

@export var camera: fixedCamera

func _physics_process(delta: float) -> void:
	if not camera.current:
		return
		
	if camera.player != null:
		var player_position = camera.player.global_position
A		$PathFollow3D.progress = curve.get_closest_offset(player_position)
