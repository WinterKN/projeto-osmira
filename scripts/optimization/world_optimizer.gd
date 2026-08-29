class_name WorldOptimizer
extends Node


# ============================================================
# REFERÊNCIAS
# ============================================================

@export_group("World")

# Pode deixar vazio.
# Se vazio, o script escaneia o World inteiro.
@export var scan_root: Node

@export var world_environment: WorldEnvironment
@export var directional_light: DirectionalLight3D


# ============================================================
# DETECÇÃO AUTOMÁTICA DE VEGETAÇÃO
# ============================================================

@export_group("Vegetation Detection")

# Se a cena da mesh estiver dentro de uma dessas pastas,
# será considerada vegetação.
@export var vegetation_paths: PackedStringArray = [
	"/trees/",
	"/plants/",
	"/bush/"
]


# ============================================================
# DISTÂNCIA DA VEGETAÇÃO
# ============================================================

@export_group("Vegetation Distance")

@export var foliage_distance_low := 35.0
@export var foliage_distance_medium := 60.0
@export var foliage_distance_high := 90.0
@export var foliage_distance_ultra := 140.0

@export var foliage_fade_margin := 8.0


# ============================================================
# SOMBRAS DA VEGETAÇÃO
# ============================================================

@export_group("Vegetation Shadows")

@export var foliage_shadows_low := false
@export var foliage_shadows_medium := true
@export var foliage_shadows_high := true
@export var foliage_shadows_ultra := true


# ============================================================
# DEBUG DE PERFORMANCE
# ============================================================

@export_group("Performance Debug")

@export var show_performance_in_output := true

# De quanto em quanto tempo imprime os dados no Output.
@export var performance_update_interval := 2.0


# ============================================================
# CACHE DOS OBJETOS
# ============================================================

var foliage_nodes: Array[GeometryInstance3D] = []

var particle_nodes: Array[GPUParticles3D] = []

var local_lights: Array[Light3D] = []


# ============================================================
# VALORES ORIGINAIS
# ============================================================

var original_particle_ratio: Dictionary = {}

var original_light_shadow: Dictionary = {}

var original_foliage_shadow: Dictionary = {}


var original_ssao := false
var original_ssil := false
var original_volumetric_fog := false

var original_directional_shadow_distance := 100.0


# ============================================================
# ESTATÍSTICAS DA VEGETAÇÃO
# ============================================================

# Quantidade de instâncias de cada .tscn de árvore.
var vegetation_scene_count: Dictionary = {}

# Quantidade de GeometryInstance3D encontrados
# pertencentes a cada cena.
var vegetation_mesh_count: Dictionary = {}


# ============================================================
# DEBUG TIMER
# ============================================================

var performance_timer := 0.0


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	# --------------------------------------------------------
	# ROOT DO SCAN
	# --------------------------------------------------------

	if scan_root == null:
		scan_root = get_tree().current_scene


	# --------------------------------------------------------
	# REGISTRA NO SISTEMA DE QUALIDADE
	# --------------------------------------------------------

	add_to_group("optimization_quality")


	# --------------------------------------------------------
	# ESCANEIA O WORLD
	# --------------------------------------------------------

	scan_world(scan_root)


	# --------------------------------------------------------
	# SALVA CONFIGURAÇÕES ORIGINAIS
	# --------------------------------------------------------

	cache_environment()


	# --------------------------------------------------------
	# RELATÓRIO
	# --------------------------------------------------------

	print_optimization_report()


	# --------------------------------------------------------
	# APLICA QUALIDADE ATUAL
	# --------------------------------------------------------

	call_deferred(
		"apply_optimization_quality",
		OptimizationManager.current_quality
	)


# ============================================================
# PROCESS
# ============================================================

func _process(delta: float) -> void:

	if not show_performance_in_output:
		return


	performance_timer += delta


	if performance_timer < performance_update_interval:
		return


	performance_timer = 0.0


	print_performance_report()


# ============================================================
# ESCANEAR WORLD
# ============================================================

func scan_world(node: Node) -> void:

	# --------------------------------------------------------
	# CONTA INSTÂNCIAS DAS CENAS DE VEGETAÇÃO
	# --------------------------------------------------------

	var node_scene_path := node.scene_file_path


	if not node_scene_path.is_empty():

		var lower_scene_path := node_scene_path.to_lower()


		for vegetation_path in vegetation_paths:

			if lower_scene_path.contains(
				vegetation_path.to_lower()
			):

				vegetation_scene_count[node_scene_path] = (
					vegetation_scene_count.get(
						node_scene_path,
						0
					) + 1
				)

				break


	# --------------------------------------------------------
	# GEOMETRY INSTANCE / VEGETAÇÃO
	# --------------------------------------------------------

	if node is GeometryInstance3D:

		var vegetation_source := (
			get_vegetation_source(node)
		)


		if not vegetation_source.is_empty():

			var geometry := (
				node as GeometryInstance3D
			)


			foliage_nodes.append(
				geometry
			)


			original_foliage_shadow[geometry] = (
				geometry.cast_shadow
			)


			vegetation_mesh_count[vegetation_source] = (
				vegetation_mesh_count.get(
					vegetation_source,
					0
				) + 1
			)


	# --------------------------------------------------------
	# GPU PARTICLES
	# --------------------------------------------------------

	if node is GPUParticles3D:

		var particles := (
			node as GPUParticles3D
		)


		particle_nodes.append(
			particles
		)


		original_particle_ratio[particles] = (
			particles.amount_ratio
		)


	# --------------------------------------------------------
	# LUZES LOCAIS
	# --------------------------------------------------------

	if (
		node is OmniLight3D
		or
		node is SpotLight3D
	):

		var light := (
			node as Light3D
		)


		local_lights.append(
			light
		)


		original_light_shadow[light] = (
			light.shadow_enabled
		)


	# --------------------------------------------------------
	# FILHOS
	# --------------------------------------------------------

	for child in node.get_children():

		scan_world(
			child
		)


# ============================================================
# DESCOBRIR DE QUAL CENA A VEGETAÇÃO VEIO
# ============================================================

func get_vegetation_source(
	node: Node
) -> String:

	var current: Node = node


	while current != null:

		var source_path := (
			current.scene_file_path
		)


		if not source_path.is_empty():

			var lower_source_path := (
				source_path.to_lower()
			)


			for vegetation_path in vegetation_paths:

				if lower_source_path.contains(
					vegetation_path.to_lower()
				):

					return source_path


		current = current.get_parent()


	return ""


# ============================================================
# CACHE DO ENVIRONMENT
# ============================================================

func cache_environment() -> void:

	# --------------------------------------------------------
	# DIRECTIONAL LIGHT
	# --------------------------------------------------------

	if directional_light != null:

		original_directional_shadow_distance = (
			directional_light.directional_shadow_max_distance
		)


	# --------------------------------------------------------
	# WORLD ENVIRONMENT
	# --------------------------------------------------------

	if world_environment == null:
		return


	if world_environment.environment == null:
		return


	var env := world_environment.environment


	original_ssao = (
		env.ssao_enabled
	)


	original_ssil = (
		env.ssil_enabled
	)


	original_volumetric_fog = (
		env.volumetric_fog_enabled
	)


# ============================================================
# APLICAR QUALIDADE
# ============================================================

func apply_optimization_quality(
	quality: int
) -> void:

	match quality:


		# ====================================================
		# LOW
		# ====================================================

		OptimizationManager.Quality.LOW:

			apply_foliage(
				foliage_distance_low,
				foliage_shadows_low
			)


			apply_particles(
				0.35
			)


			apply_local_lights_low()


			apply_environment(
				false,
				false,
				false
			)


			apply_directional_shadow_distance(
				35.0
			)


		# ====================================================
		# MEDIUM
		# ====================================================

		OptimizationManager.Quality.MEDIUM:

			apply_foliage(
				foliage_distance_medium,
				foliage_shadows_medium
			)


			apply_particles(
				0.60
			)


			apply_local_lights_medium()


			apply_environment(
				original_ssao,
				false,
				false
			)


			apply_directional_shadow_distance(
				60.0
			)


		# ====================================================
		# HIGH
		# ====================================================

		OptimizationManager.Quality.HIGH:

			apply_foliage(
				foliage_distance_high,
				foliage_shadows_high
			)


			apply_particles(
				0.85
			)


			restore_local_lights()


			apply_environment(
				original_ssao,
				false,
				original_volumetric_fog
			)


			apply_directional_shadow_distance(
				90.0
			)


		# ====================================================
		# ULTRA
		# ====================================================

		OptimizationManager.Quality.ULTRA:

			apply_foliage(
				foliage_distance_ultra,
				foliage_shadows_ultra
			)


			apply_particles(
				1.0
			)


			restore_local_lights()


			apply_environment(
				original_ssao,
				original_ssil,
				original_volumetric_fog
			)


			apply_directional_shadow_distance(
				original_directional_shadow_distance
			)


# ============================================================
# VEGETAÇÃO
# ============================================================

func apply_foliage(
	max_distance: float,
	enable_shadows: bool
) -> void:

	for foliage in foliage_nodes:

		if not is_instance_valid(
			foliage
		):
			continue


		# ----------------------------------------------------
		# VISIBILITY RANGE
		# ----------------------------------------------------

		foliage.visibility_range_end = (
			max_distance
		)


		foliage.visibility_range_end_margin = (
			foliage_fade_margin
		)


		# ----------------------------------------------------
		# SOMBRAS
		# ----------------------------------------------------

		if enable_shadows:

			foliage.cast_shadow = (
				original_foliage_shadow.get(
					foliage,
					GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				)
			)

		else:

			foliage.cast_shadow = (
				GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			)


# ============================================================
# PARTÍCULAS
# ============================================================

func apply_particles(
	ratio: float
) -> void:

	for particles in particle_nodes:

		if not is_instance_valid(
			particles
		):
			continue


		var original: float = (
			original_particle_ratio.get(
				particles,
				1.0
			)
		)


		particles.amount_ratio = (
			original * ratio
		)


# ============================================================
# LUZES - LOW
# ============================================================

func apply_local_lights_low() -> void:

	for light in local_lights:

		if not is_instance_valid(
			light
		):
			continue


		# LOW:
		# nenhuma Omni/Spot projeta sombra dinâmica.

		light.shadow_enabled = false


# ============================================================
# LUZES - MEDIUM
# ============================================================

func apply_local_lights_medium() -> void:

	for light in local_lights:

		if not is_instance_valid(
			light
		):
			continue


		var originally_had_shadow: bool = (
			original_light_shadow.get(
				light,
				false
			)
		)


		# Se a luz originalmente nem tinha sombra,
		# continua sem.
		if not originally_had_shadow:

			light.shadow_enabled = false
			continue


		# Em MEDIUM apenas as luzes do grupo
		# opt_important_shadow mantêm sombra.

		light.shadow_enabled = (
			light.is_in_group(
				"opt_important_shadow"
			)
		)


# ============================================================
# RESTAURAR LUZES
# ============================================================

func restore_local_lights() -> void:

	for light in local_lights:

		if not is_instance_valid(
			light
		):
			continue


		light.shadow_enabled = (
			original_light_shadow.get(
				light,
				false
			)
		)


# ============================================================
# WORLD ENVIRONMENT
# ============================================================

func apply_environment(
	ssao: bool,
	ssil: bool,
	volumetric_fog: bool
) -> void:

	if world_environment == null:
		return


	if world_environment.environment == null:
		return


	var env := (
		world_environment.environment
	)


	env.ssao_enabled = (
		ssao
	)


	env.ssil_enabled = (
		ssil
	)


	env.volumetric_fog_enabled = (
		volumetric_fog
	)


# ============================================================
# DISTÂNCIA DAS SOMBRAS DO SOL
# ============================================================

func apply_directional_shadow_distance(
	distance: float
) -> void:

	if directional_light == null:
		return


	directional_light.directional_shadow_max_distance = (
		minf(
			distance,
			original_directional_shadow_distance
		)
	)


# ============================================================
# RELATÓRIO INICIAL
# ============================================================

func print_optimization_report() -> void:

	print("")
	print("========================================")
	print("========== WORLD OPTIMIZER =============")
	print("========================================")


	print(
		"Vegetação detectada: ",
		foliage_nodes.size()
	)


	print(
		"GPUParticles3D detectados: ",
		particle_nodes.size()
	)


	print(
		"Luzes locais detectadas: ",
		local_lights.size()
	)


	print("")
	print("--------- MODELOS DE VEGETAÇÃO ----------")


	var paths := (
		vegetation_scene_count.keys()
	)


	paths.sort_custom(
		func(a, b):
			return (
				vegetation_scene_count[a]
				>
				vegetation_scene_count[b]
			)
	)


	var total_tree_instances := 0


	for path in paths:

		var instance_count: int = (
			vegetation_scene_count[path]
		)


		var mesh_count: int = (
			vegetation_mesh_count.get(
				path,
				0
			)
		)


		total_tree_instances += (
			instance_count
		)


		print(
			path.get_file(),
			" | Instâncias: ",
			instance_count,
			" | GeometryInstances: ",
			mesh_count
		)


	print("")
	print(
		"Total de cenas de vegetação: ",
		total_tree_instances
	)


	print(
		"Total de GeometryInstance3D: ",
		foliage_nodes.size()
	)


	print("========================================")
	print("")


# ============================================================
# PERFORMANCE EM TEMPO REAL
# ============================================================

func print_performance_report() -> void:

	var fps := (
		Performance.get_monitor(
			Performance.TIME_FPS
		)
	)


	var draw_calls := (
		Performance.get_monitor(
			Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME
		)
	)


	var rendered_objects := (
		Performance.get_monitor(
			Performance.RENDER_TOTAL_OBJECTS_IN_FRAME
		)
	)


	var primitives := (
		Performance.get_monitor(
			Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME
		)
	)


	print(
		"[PERFORMANCE] FPS: ",
		int(fps),
		" | Draw Calls: ",
		int(draw_calls),
		" | Objetos: ",
		int(rendered_objects),
		" | Primitivas: ",
		int(primitives)
	)
