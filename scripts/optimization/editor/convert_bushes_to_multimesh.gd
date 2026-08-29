@tool
extends EditorScript


# ============================================================
# CONFIGURAÇÃO
# ============================================================

const TARGET_SCENE := "bush_09.tscn"

# Com vegetação muito densa eu prefiro 20m.
#
# Isso gera mais MultiMeshes do que 30m,
# mas permite culling muito melhor.
const CELL_SIZE := 20.0

const GENERATED_ROOT_NAME := "Generated_Bush_MultiMeshes"


# ============================================================
# RUN
# ============================================================

func _run() -> void:

	var scene_root := (
		EditorInterface.get_edited_scene_root()
	)


	if scene_root == null:

		push_error(
			"Nenhuma cena aberta."
		)

		return


	# --------------------------------------------------------
	# PROTEÇÃO
	# --------------------------------------------------------

	if (
		scene_root.get_node_or_null(
			GENERATED_ROOT_NAME
		)
		!= null
	):

		push_error(
			"Já existe "
			+ GENERATED_ROOT_NAME
			+ ". Restaure/remova a conversão anterior primeiro."
		)

		return


	# --------------------------------------------------------
	# ENCONTRAR BUSHES
	# --------------------------------------------------------

	var bushes: Array[Node3D] = []


	collect_bushes(
		scene_root,
		bushes
	)


	if bushes.is_empty():

		push_error(
			"Nenhum "
			+ TARGET_SCENE
			+ " encontrado."
		)

		return


	print("")
	print("======================================")
	print("BUSH MULTIMESH CONVERTER V2")
	print("======================================")

	print(
		"Bushes encontrados: ",
		bushes.size()
	)


	# ========================================================
	# TEMPLATE
	# ========================================================

	var template_mesh_node := (
		find_first_mesh(
			bushes[0]
		)
	)


	if template_mesh_node == null:

		push_error(
			"O bush não possui MeshInstance3D."
		)

		return


	if template_mesh_node.mesh == null:

		push_error(
			"A MeshInstance3D não possui Mesh."
		)

		return


	# --------------------------------------------------------
	# MESH COMPARTILHADA
	# --------------------------------------------------------

	var shared_mesh := (
		create_shared_mesh(
			template_mesh_node
		)
	)


	if shared_mesh == null:

		push_error(
			"Falha ao criar/acessar Mesh."
		)

		return


	# ========================================================
	# SEPARAR EM CÉLULAS
	# ========================================================

	var cells: Dictionary = {}


	for bush in bushes:

		var cell := (
			get_cell(
				bush.global_position
			)
		)


		if not cells.has(
			cell
		):

			cells[cell] = []


		cells[cell].append(
			bush
		)


	# ========================================================
	# ROOT GERADO
	# ========================================================

	var generated_root := Node3D.new()

	generated_root.name = (
		GENERATED_ROOT_NAME
	)


	scene_root.add_child(
		generated_root
	)

	generated_root.owner = (
		scene_root
	)


	# ========================================================
	# MODELO
	# ========================================================

	var model_root := Node3D.new()

	model_root.name = (
		TARGET_SCENE.get_basename()
	)


	generated_root.add_child(
		model_root
	)

	model_root.owner = (
		scene_root
	)


	# ========================================================
	# GERAR MULTIMESHES
	# ========================================================

	var total_multimeshes := 0

	var total_instances := 0


	for cell in cells.keys():

		var cell_bushes: Array = (
			cells[cell]
		)


		if cell_bushes.is_empty():
			continue


		# ----------------------------------------------------
		# POSIÇÃO REAL DA CÉLULA
		#
		# MUITO IMPORTANTE:
		# agora o MultiMesh não fica mais em 0,0,0.
		# ----------------------------------------------------

		var cell_origin := (
			get_cell_origin(
				cell,
				cell_bushes
			)
		)


		# ----------------------------------------------------
		# MULTIMESH INSTANCE
		# ----------------------------------------------------

		var multi_instance := (
			MultiMeshInstance3D.new()
		)


		multi_instance.name = (
			"MM_"
			+ str(cell.x)
			+ "_"
			+ str(cell.y)
		)


		model_root.add_child(
			multi_instance
		)


		multi_instance.owner = (
			scene_root
		)


		# ----------------------------------------------------
		# POSICIONAR O NODE NA PRÓPRIA CÉLULA
		# ----------------------------------------------------

		multi_instance.global_position = (
			cell_origin
		)


		# ----------------------------------------------------
		# CONFIGURAÇÕES VISUAIS
		# ----------------------------------------------------

		multi_instance.layers = (
			template_mesh_node.layers
		)


		multi_instance.cast_shadow = (
			template_mesh_node.cast_shadow
		)


		multi_instance.gi_mode = (
			template_mesh_node.gi_mode
		)


		multi_instance.material_override = (
			template_mesh_node.material_override
		)


		multi_instance.material_overlay = (
			template_mesh_node.material_overlay
		)


		multi_instance.ignore_occlusion_culling = (
			template_mesh_node.ignore_occlusion_culling
		)


		multi_instance.extra_cull_margin = (
			template_mesh_node.extra_cull_margin
		)


		# ----------------------------------------------------
		# VISIBILITY RANGE ORIGINAL
		#
		# O WorldOptimizer pode substituir depois.
		# ----------------------------------------------------

		multi_instance.visibility_range_begin = (
			template_mesh_node.visibility_range_begin
		)


		multi_instance.visibility_range_begin_margin = (
			template_mesh_node.visibility_range_begin_margin
		)


		multi_instance.visibility_range_end = (
			template_mesh_node.visibility_range_end
		)


		multi_instance.visibility_range_end_margin = (
			template_mesh_node.visibility_range_end_margin
		)


		multi_instance.visibility_range_fade_mode = (
			template_mesh_node.visibility_range_fade_mode
		)


		# ====================================================
		# MULTIMESH RESOURCE
		# ====================================================

		var multimesh := (
			MultiMesh.new()
		)


		# Formato precisa ser definido ANTES
		# do instance_count.
		multimesh.transform_format = (
			MultiMesh.TRANSFORM_3D
		)


		multimesh.use_colors = false

		multimesh.use_custom_data = false


		# IMPORTANTE:
		# mesma Mesh compartilhada por todas as células.
		multimesh.mesh = (
			shared_mesh
		)


		multimesh.instance_count = (
			cell_bushes.size()
		)


		multi_instance.multimesh = (
			multimesh
		)


		# ====================================================
		# TRANSFORMS
		# ====================================================

		var inverse_multi := (
			multi_instance
			.global_transform
			.affine_inverse()
		)


		for index in range(
			cell_bushes.size()
		):

			var bush := (
				cell_bushes[index]
				as Node3D
			)


			if bush == null:
				continue


			var old_mesh := (
				find_first_mesh(
					bush
				)
			)


			if old_mesh == null:
				continue


			var local_transform := (
				inverse_multi
				*
				old_mesh.global_transform
			)


			multimesh.set_instance_transform(
				index,
				local_transform
			)


		# ====================================================
		# CUSTOM AABB
		# ====================================================

		var calculated_aabb := (
			multimesh.get_aabb()
		)


		if (
			calculated_aabb.size
			!=
			Vector3.ZERO
		):

			multimesh.custom_aabb = (
				calculated_aabb
			)


		# ====================================================
		# GROUP
		# ====================================================

		multi_instance.add_to_group(
			"opt_foliage",
			true
		)


		total_multimeshes += 1

		total_instances += (
			cell_bushes.size()
		)


		print(
			"Cell ",
			cell,
			" | ",
			cell_bushes.size(),
			" instâncias"
		)


	# ========================================================
	# ESCONDER ORIGINAIS
	# ========================================================

	for bush in bushes:

		bush.visible = false


		bush.set_meta(
			"converted_to_multimesh",
			true
		)


	# ========================================================
	# FINAL
	# ========================================================

	print("")
	print("--------------------------------------")

	print(
		"Bushes originais: ",
		bushes.size()
	)


	print(
		"MultiMeshes criados: ",
		total_multimeshes
	)


	print(
		"Instâncias: ",
		total_instances
	)

	print("--------------------------------------")

	print(
		"Conversão V2 concluída."
	)

	print(
		"Verifique visualmente antes de salvar."
	)

	print("======================================")
	print("")


# ============================================================
# ENCONTRAR BUSHES
# ============================================================

func collect_bushes(
	node: Node,
	output: Array[Node3D]
) -> void:

	if (
		node is Node3D
		and
		not node.scene_file_path.is_empty()
		and
		node.scene_file_path.get_file()
		==
		TARGET_SCENE
	):

		output.append(
			node as Node3D
		)

		return


	for child in node.get_children():

		collect_bushes(
			child,
			output
		)


# ============================================================
# ENCONTRAR PRIMEIRA MESH
# ============================================================

func find_first_mesh(
	node: Node
) -> MeshInstance3D:

	if node is MeshInstance3D:

		return (
			node as MeshInstance3D
		)


	for child in node.get_children():

		var found := (
			find_first_mesh(
				child
			)
		)


		if found != null:

			return found


	return null


# ============================================================
# CRIAR MESH COMPARTILHADA
# ============================================================

func create_shared_mesh(
	template: MeshInstance3D
) -> Mesh:

	if template.mesh == null:
		return null


	var has_override := false


	for index in range(
		template.get_surface_override_material_count()
	):

		if (
			template.get_surface_override_material(
				index
			)
			!= null
		):

			has_override = true
			break


	# --------------------------------------------------------
	# SEM OVERRIDE:
	# usa diretamente a Mesh original.
	#
	# Não duplica nada.
	# --------------------------------------------------------

	if not has_override:

		return template.mesh


	# --------------------------------------------------------
	# COM OVERRIDE:
	# cria UMA ÚNICA cópia compartilhada.
	# --------------------------------------------------------

	var mesh_copy := (
		template.mesh.duplicate()
		as Mesh
	)


	for index in range(
		template.get_surface_override_material_count()
	):

		if index >= mesh_copy.get_surface_count():
			continue


		var material := (
			template.get_surface_override_material(
				index
			)
		)


		if material != null:

			mesh_copy.surface_set_material(
				index,
				material
			)


	return mesh_copy


# ============================================================
# CÉLULA
# ============================================================

func get_cell(
	position: Vector3
) -> Vector2i:

	return Vector2i(
		floori(
			position.x / CELL_SIZE
		),

		floori(
			position.z / CELL_SIZE
		)
	)


# ============================================================
# ORIGEM DA CÉLULA
# ============================================================

func get_cell_origin(
	cell: Vector2i,
	bushes: Array
) -> Vector3:

	# Centro X/Z da célula.
	var x := (
		(float(cell.x) + 0.5)
		*
		CELL_SIZE
	)


	var z := (
		(float(cell.y) + 0.5)
		*
		CELL_SIZE
	)


	# --------------------------------------------------------
	# Média da altura dos bushes.
	# --------------------------------------------------------

	var y := 0.0

	var count := 0


	for bush_variant in bushes:

		var bush := (
			bush_variant as Node3D
		)


		if bush == null:
			continue


		y += bush.global_position.y

		count += 1


	if count > 0:

		y /= float(count)


	return Vector3(
		x,
		y,
		z
	)
