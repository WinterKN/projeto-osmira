class_name GameEffects
extends Node


@onready var crt: ColorRect = $CanvasLayer/CRT
@onready var psx_shader_node: MeshInstance3D = $shader


var crt_material: ShaderMaterial
var psx_material: ShaderMaterial


# Valores originais configurados no Inspector.
var film_grain_noise: float
var film_grain_static_noise: float
var chromatic_aberration: float
var screen_warp: float


func _ready() -> void:
	# ---------------------------------------------------------
	# CRT
	# ---------------------------------------------------------
	crt_material = crt.material as ShaderMaterial

	if crt_material == null:
		push_error("GameEffects: CRT não possui um ShaderMaterial.")
		return


	# ---------------------------------------------------------
	# PSX SHADER
	# ---------------------------------------------------------
	psx_material = _get_psx_shader_material()

	if psx_material == null:
		push_error(
			"GameEffects: não foi possível encontrar o ShaderMaterial do PSX Shader."
		)
		return


	_store_default_values()


# =========================================================
# PEGA O MATERIAL DO MESHINSTANCE3D
# =========================================================

func _get_psx_shader_material() -> ShaderMaterial:
	# Primeiro tenta Material Override.
	if psx_shader_node.material_override is ShaderMaterial:
		return psx_shader_node.material_override as ShaderMaterial


	# Caso o material esteja colocado diretamente
	# na superfície da Mesh.
	if psx_shader_node.mesh != null:
		if psx_shader_node.mesh.get_surface_count() > 0:
			var surface_material := psx_shader_node.mesh.surface_get_material(0)

			if surface_material is ShaderMaterial:
				return surface_material as ShaderMaterial


	return null


# =========================================================
# GUARDA OS VALORES ORIGINAIS
# =========================================================

func _store_default_values() -> void:
	film_grain_noise = float(
		crt_material.get_shader_parameter("noise_opacity")
	)

	film_grain_static_noise = float(
		crt_material.get_shader_parameter("static_noise_intensity")
	)

	chromatic_aberration = float(
		crt_material.get_shader_parameter("aberration")
	)

	screen_warp = float(
		crt_material.get_shader_parameter("warp_amount")
	)


# =========================================================
# FILM GRAIN
# =========================================================

func set_film_grain(enabled: bool) -> void:
	if crt_material == null:
		return

	crt_material.set_shader_parameter(
		"noise_opacity",
		film_grain_noise if enabled else 0.0
	)

	crt_material.set_shader_parameter(
		"static_noise_intensity",
		film_grain_static_noise if enabled else 0.0
	)


# =========================================================
# CHROMATIC ABERRATION
# =========================================================

func set_chromatic_aberration(enabled: bool) -> void:
	if crt_material == null:
		return

	crt_material.set_shader_parameter(
		"aberration",
		chromatic_aberration if enabled else 0.0
	)


# =========================================================
# SCREEN DISTORTION
# =========================================================

func set_screen_distortion(enabled: bool) -> void:
	if crt_material == null:
		return

	crt_material.set_shader_parameter(
		"warp_amount",
		screen_warp if enabled else 0.0
	)


# =========================================================
# DITHERING
# =========================================================

func set_dithering(enabled: bool) -> void:
	if psx_material == null:
		return

	psx_material.set_shader_parameter(
		"enable_dithering",
		enabled
	)
