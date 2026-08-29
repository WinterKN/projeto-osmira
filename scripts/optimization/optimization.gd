extends Node


enum Quality {
	LOW,
	MEDIUM,
	HIGH,
	ULTRA
}


signal quality_changed(quality: int)


const SAVE_PATH := "user://graphics.cfg"


var current_quality: int = Quality.MEDIUM


# ============================================================
# ADAPTIVE RESOLUTION
# ============================================================

var adaptive_resolution_enabled := false

var target_fps := 60.0

var adaptive_check_interval := 3.0

var _adaptive_timer := 0.0

var _base_render_scale := 0.67
var _minimum_render_scale := 0.50


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	process_mode = Node.PROCESS_MODE_ALWAYS

	load_settings()

	apply_global_quality()


# ============================================================
# PROCESS
# ============================================================

func _process(delta: float) -> void:

	if not adaptive_resolution_enabled:
		return

	_adaptive_timer += delta

	if _adaptive_timer < adaptive_check_interval:
		return

	_adaptive_timer = 0.0

	update_adaptive_resolution()


# ============================================================
# QUALITY
# ============================================================

func set_quality(quality: int) -> void:

	current_quality = clampi(
		quality,
		Quality.LOW,
		Quality.ULTRA
	)

	apply_global_quality()

	get_tree().call_group(
		"optimization_quality",
		"apply_optimization_quality",
		current_quality
	)

	save_settings()

	quality_changed.emit(current_quality)


# ============================================================
# GLOBAL QUALITY
# ============================================================

func apply_global_quality() -> void:

	var viewport := get_tree().root

	var shader_resolution := Vector2(640.0, 360.0)
	var shader_color_depth := 48.0
	var shadow_atlas_size := 2048


	match current_quality:

		Quality.LOW:

			_base_render_scale = 0.50
			_minimum_render_scale = 0.40

			shader_resolution = Vector2(480.0, 270.0)
			shader_color_depth = 32.0

			shadow_atlas_size = 1024


		Quality.MEDIUM:

			_base_render_scale = 0.67
			_minimum_render_scale = 0.50

			shader_resolution = Vector2(640.0, 360.0)
			shader_color_depth = 48.0

			shadow_atlas_size = 2048


		Quality.HIGH:

			_base_render_scale = 0.85
			_minimum_render_scale = 0.67

			shader_resolution = Vector2(960.0, 540.0)
			shader_color_depth = 48.0

			shadow_atlas_size = 4096


		Quality.ULTRA:

			_base_render_scale = 1.0
			_minimum_render_scale = 0.75

			shader_resolution = Vector2(1280.0, 720.0)
			shader_color_depth = 64.0

			shadow_atlas_size = 4096


	# --------------------------------------------------------
	# RESOLUÇÃO INTERNA 3D
	# --------------------------------------------------------

	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_NEAREST
	viewport.scaling_3d_scale = _base_render_scale


	# --------------------------------------------------------
	# SHADOW ATLAS
	# OmniLight3D / SpotLight3D
	# --------------------------------------------------------

	viewport.positional_shadow_atlas_size = shadow_atlas_size


	# --------------------------------------------------------
	# GLOBAL SHADER PARAMETERS
	# Shader PSX que já estamos usando
	# --------------------------------------------------------

	RenderingServer.global_shader_parameter_set(
		"resolution",
		shader_resolution
	)

	RenderingServer.global_shader_parameter_set(
		"color_depth",
		shader_color_depth
	)


# ============================================================
# ADAPTIVE RESOLUTION
# ============================================================

func update_adaptive_resolution() -> void:

	var viewport := get_tree().root

	var fps := float(
		Performance.get_monitor(
			Performance.TIME_FPS
		)
	)

	var current_scale := viewport.scaling_3d_scale


	# FPS muito abaixo da meta.
	if fps < target_fps - 10.0:

		current_scale -= 0.05

		current_scale = maxf(
			current_scale,
			_minimum_render_scale
		)


	# FPS estável novamente.
	elif fps >= target_fps - 2.0:

		current_scale += 0.05

		current_scale = minf(
			current_scale,
			_base_render_scale
		)


	viewport.scaling_3d_scale = current_scale


# ============================================================
# SECTORS
# ============================================================

func activate_sectors(active_sectors: Array) -> void:

	for sector in get_tree().get_nodes_in_group(
		"world_sector"
	):

		if not sector.has_method("set_sector_active"):
			continue

		var should_be_active := active_sectors.has(sector)

		if sector.get("always_active") == true:
			should_be_active = true

		sector.set_sector_active(
			should_be_active
		)


# ============================================================
# SAVE
# ============================================================

func save_settings() -> void:

	var config := ConfigFile.new()

	config.set_value(
		"graphics",
		"quality",
		current_quality
	)

	config.set_value(
		"graphics",
		"adaptive_resolution",
		adaptive_resolution_enabled
	)

	config.save(SAVE_PATH)


# ============================================================
# LOAD
# ============================================================

func load_settings() -> void:

	var config := ConfigFile.new()

	if config.load(SAVE_PATH) != OK:
		return

	current_quality = int(
		config.get_value(
			"graphics",
			"quality",
			Quality.MEDIUM
		)
	)

	adaptive_resolution_enabled = bool(
		config.get_value(
			"graphics",
			"adaptive_resolution",
			false
		)
	)
