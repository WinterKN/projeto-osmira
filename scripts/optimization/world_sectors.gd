class_name WorldSector
extends Node3D


@export var active_on_start := false

@export var always_active := false

@export var disable_collisions_when_inactive := true


var _is_active := true

var _original_process_mode: ProcessMode


var _collision_nodes: Array[CollisionObject3D] = []

var _collision_layers: Dictionary = {}

var _collision_masks: Dictionary = {}


var _particle_nodes: Array[GPUParticles3D] = []

var _particle_emitting: Dictionary = {}


var _audio_nodes: Array[AudioStreamPlayer3D] = []


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	add_to_group(
		"world_sector"
	)

	_original_process_mode = \
		process_mode

	cache_nodes(self)


	var should_start_active := (
		active_on_start
		or
		always_active
	)


	# Força a primeira atualização.
	_is_active = not should_start_active

	set_sector_active(
		should_start_active
	)


# ============================================================
# CACHE
# ============================================================

func cache_nodes(node: Node) -> void:

	if node is CollisionObject3D:

		_collision_nodes.append(node)

		_collision_layers[node] = \
			node.collision_layer

		_collision_masks[node] = \
			node.collision_mask


	if node is GPUParticles3D:

		_particle_nodes.append(node)

		_particle_emitting[node] = \
			node.emitting


	if node is AudioStreamPlayer3D:

		_audio_nodes.append(node)


	for child in node.get_children():

		cache_nodes(child)


# ============================================================
# ACTIVE
# ============================================================

func set_sector_active(
	active: bool
) -> void:

	if always_active:
		active = true


	if active == _is_active:
		return


	_is_active = active


	# --------------------------------------------------------
	# VISUAL
	# --------------------------------------------------------

	visible = active


	# --------------------------------------------------------
	# PARTICLES
	# --------------------------------------------------------

	for particles in _particle_nodes:

		if active:

			particles.emitting = bool(
				_particle_emitting.get(
					particles,
					true
				)
			)

		else:

			particles.emitting = false


	# --------------------------------------------------------
	# AUDIO
	# --------------------------------------------------------

	for audio in _audio_nodes:

		if audio.playing:

			audio.stream_paused = \
				not active


	# --------------------------------------------------------
	# COLLISIONS
	# --------------------------------------------------------

	if disable_collisions_when_inactive:

		for collision in _collision_nodes:

			if active:

				collision.collision_layer = int(
					_collision_layers.get(
						collision,
						0
					)
				)

				collision.collision_mask = int(
					_collision_masks.get(
						collision,
						0
					)
				)

			else:

				collision.collision_layer = 0
				collision.collision_mask = 0


	# --------------------------------------------------------
	# PROCESSING
	# --------------------------------------------------------

	if active:

		process_mode = \
			_original_process_mode

	else:

		process_mode = \
			Node.PROCESS_MODE_DISABLED
