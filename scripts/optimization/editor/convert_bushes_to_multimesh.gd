@tool
extends EditorScript


# ============================================================
# CONFIGURAÇÃO
# ============================================================

# MODELOS QUE SERÃO CONVERTIDOS NESTA EXECUÇÃO.
#
# AGORA:
# somente bush_10.
#
# Depois, para converter bush_12:
#
# const TARGET_SCENES: PackedStringArray = [
#     "bush_12.tscn"
# ]
#
# Esta versão suporta múltiplas MeshInstance3D
# dentro da mesma cena.
const TARGET_SCENES: PackedStringArray = [
	"bush_11.tscn"
]


# Tamanho dos blocos espaciais.
#
# Mantemos 20x20 m porque funcionou bem
# com o bush_09.
const CELL_SIZE := 20.0


# IMPORTANTE:
# mesmo nome usado na conversão anterior.
#
# A V3 vai APROVEITAR esse node existente,
# e não vai apagar o bush_09.
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
			"Nenhuma cena está aberta no editor."
		)

		return


	print("")
	print("============================================")
	print("VEGETATION MULTIMESH CONVERTER V3")
	print("============================================")


	# ========================================================
	# ENCONTRAR OU CRIAR ROOT DOS MULTIMESHES
	# ========================================================

	var generated_root := (
		scene_root.get_node_or_null(
			GENERATED_ROOT_NAME
		)
		as Node3D
	)


	if generated_root == null:

		generated_root = Node3D.new()

		generated_root.name = (
			GENERATED_ROOT_NAME
		)


		scene_root.add_child(
			generated_root
		)


		generated_root.owner = (
			scene_root
		)


		print(
			"Container criado: ",
			GENERATED_ROOT_NAME
		)

	else:

		print(
			"Container existente encontrado: ",
			GENERATED_ROOT_NAME
		)


	# ========================================================
	# VERIFICAR QUAIS MODELOS AINDA PODEM SER CONVERTIDOS
	# ========================================================

	var active_targets: PackedStringArray = []


	for target_scene in TARGET_SCENES:

		var model_name := (
			target_scene.get_basename()
		)


		var existing_model := (
			generated_root.get_node_or_null(
				model_name
			)
		)


		if existing_model != null:

			push_warning(
				target_scene
				+ " já possui MultiMeshes gerados. "
				+ "Será ignorado."
			)

			continue


		active_targets.append(
			target_scene
		)


	if active_targets.is_empty():

		print(
			"Nenhum modelo novo para converter."
		)

		print("============================================")
		print("")

		return


	# ========================================================
	# ENCONTRAR INSTÂNCIAS
	# ========================================================

	var target_instances: Array[Node3D] = []


	collect_target_instances(
		scene_root,
		active_targets,
		target_instances
	)


	if target_instances.is_empty():

		push_error(
			"Nenhuma instância dos modelos selecionados "
			+ "foi encontrada."
		)

		return


	print(
		"Instâncias encontradas: ",
		target_instances.size()
	)


	# ========================================================
	# BUCKETS
	#
	# Cada bucket representa:
	#
	# MODELO
	# +
	# CÉLULA
	# +
	# MESH INTERNA
	#
	# Exemplo para bush_12:
	#
	# bush_12
	# Cell 3,4
	# Mesh_01
	#
	# bush_12
	# Cell 3,4
	# Mesh_02
	#
	# bush_12
	# Cell 3,4
	# Mesh_03
	#
	# ========================================================

	var buckets: Dictionary = {}


	# Roots que serão escondidos ao final.
	var roots_to_hide: Array[Node3D] = []


	for instance_root in target_instances:

		var scene_name := (
			instance_root.scene_file_path.get_file()
		)


		var cell := (
			get_cell(
				instance_root.global_position
			)
		)


		var mesh_nodes: Array[MeshInstance3D] = []


		collect_mesh_instances(
			instance_root,
			mesh_nodes
		)


		if mesh_nodes.is_empty():

			push_warning(
				"Sem MeshInstance3D em: "
				+ str(instance_root.get_path())
			)

			continue


		roots_to_hide.append(
			instance_root
		)


		# ----------------------------------------------------
		# CADA MESH INTERNA GANHA SEU PRÓPRIO BUCKET
		# ----------------------------------------------------

		for mesh_node in mesh_nodes:

			if mesh_node.mesh == null:
				continue


			var relative_path := (
				instance_root.get_path_to(
					mesh_node
				)
			)


			var bucket_key := (
				scene_name
				+ "|"
				+ str(cell.x)
				+ "|"
				+ str(cell.y)
				+ "|"
				+ str(relative_path)
			)


			if not buckets.has(
				bucket_key
			):

				buckets[bucket_key] = {
					"scene_name": scene_name,
					"cell": cell,
					"relative_path": relative_path,
					"meshes": []
				}


			var bucket_meshes: Array = (
				buckets[bucket_key]["meshes"]
			)


			bucket_meshes.append(
				mesh_node
			)


			buckets[bucket_key]["meshes"] = (
				bucket_meshes
			)


	# ========================================================
	# CACHE DE MESHES COMPARTILHADAS
	# ========================================================

	var shared_mesh_cache: Dictionary = {}


	# ========================================================
	# CACHE DOS PARENTS DOS MODELOS
	# ========================================================

	var model_parents: Dictionary = {}


	# ========================================================
	# ESTATÍSTICAS
	# ========================================================

	var total_multimeshes := 0

	var total_render_instances := 0


	var model_multimesh_count: Dictionary = {}

	var model_render_instance_count: Dictionary = {}


	# ========================================================
	# GERAR MULTIMESHES
	# ========================================================

	for bucket_key in buckets:

		var data: Dictionary = (
			buckets[bucket_key]
		)


		var scene_name: String = (
			data["scene_name"]
		)


		var cell: Vector2i = (
			data["cell"]
		)


		var relative_path: NodePath = (
			data["relative_path"]
		)


		var meshes: Array = (
			data["meshes"]
		)


		if meshes.is_empty():
			continue


		# ====================================================
		# TEMPLATE
		# ====================================================

		var template := (
			meshes[0]
			as MeshInstance3D
		)


		if template == null:
			continue


		if template.mesh == null:
			continue


		# ====================================================
		# MODEL ROOT
		#
		# Generated_Bush_MultiMeshes
		# ├── bush_09
		# └── bush_10
		# ====================================================

		var model_name := (
			scene_name.get_basename()
		)


		var model_parent: Node3D


		if model_parents.has(
			model_name
		):

			model_parent = (
				model_parents[model_name]
			)


		else:

			var existing_parent := (
				generated_root.get_node_or_null(
					model_name
				)
				as Node3D
			)


			if existing_parent != null:

				model_parent = (
					existing_parent
				)


			else:

				model_parent = Node3D.new()

				model_parent.name = (
					model_name
				)


				generated_root.add_child(
					model_parent
				)


				model_parent.owner = (
					scene_root
				)


			model_parents[model_name] = (
				model_parent
			)


		# ====================================================
		# MESH COMPARTILHADA
		# ====================================================

		var mesh_cache_key := (
			scene_name
				+ "|"
				+ str(relative_path)
		)


		var shared_mesh: Mesh


		if shared_mesh_cache.has(
			mesh_cache_key
		):

			shared_mesh = (
				shared_mesh_cache[
					mesh_cache_key
				]
			)


		else:

			shared_mesh = (
				create_shared_mesh(
					template
				)
			)


			if shared_mesh == null:

				push_warning(
					"Falha ao criar Mesh compartilhada: "
					+ mesh_cache_key
				)

				continue


			shared_mesh_cache[
				mesh_cache_key
			] = shared_mesh


		# ====================================================
		# MULTIMESH INSTANCE
		# ====================================================

		var multi_instance := (
			MultiMeshInstance3D.new()
		)


		multi_instance.name = (
			"MM_"
			+ str(cell.x)
			+ "_"
			+ str(cell.y)
			+ "_"
			+ sanitize_name(
				str(relative_path)
			)
		)


		model_parent.add_child(
			multi_instance
		)


		multi_instance.owner = (
			scene_root
		)


		# ====================================================
		# POSIÇÃO DO BLOCO
		#
		# O node fica realmente na própria célula.
		#
		# Isso é essencial para:
		#
		# Visibility Range
		# Frustum Culling
		# Occlusion Culling
		# ====================================================

		var cell_origin := (
			get_bucket_origin(
				cell,
				meshes
			)
		)


		multi_instance.global_position = (
			cell_origin
		)


		# ====================================================
		# CONFIGURAÇÕES VISUAIS
		# ====================================================

		copy_geometry_settings(
			template,
			multi_instance
		)


		# ====================================================
		# MULTIMESH RESOURCE
		# ====================================================

		var multimesh := (
			MultiMesh.new()
		)


		# IMPORTANTE:
		# deve ser definido antes do instance_count.
		multimesh.transform_format = (
			MultiMesh.TRANSFORM_3D
		)


		multimesh.use_colors = false

		multimesh.use_custom_data = false


		multimesh.mesh = (
			shared_mesh
		)


		multimesh.instance_count = (
			meshes.size()
		)


		multi_instance.multimesh = (
			multimesh
		)


		# ====================================================
		# COPIAR TRANSFORMS
		# ====================================================

		var inverse_multi := (
			multi_instance
			.global_transform
			.affine_inverse()
		)


		for index in range(
			meshes.size()
		):

			var old_mesh := (
				meshes[index]
				as MeshInstance3D
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
		# GROUP DO WORLD OPTIMIZER
		# ====================================================

		multi_instance.add_to_group(
			"opt_foliage",
			true
		)


		# ====================================================
		# METADADOS
		# ====================================================

		multi_instance.set_meta(
			"generated_multimesh",
			true
		)


		multi_instance.set_meta(
			"source_scene",
			scene_name
		)


		# ====================================================
		# ESTATÍSTICAS
		# ====================================================

		total_multimeshes += 1


		total_render_instances += (
			meshes.size()
		)


		model_multimesh_count[model_name] = (
			model_multimesh_count.get(
				model_name,
				0
			) + 1
		)


		model_render_instance_count[model_name] = (
			model_render_instance_count.get(
				model_name,
				0
			)
			+
			meshes.size()
		)


	# ========================================================
	# ESCONDER ORIGINAIS
	# ========================================================

	var hidden_roots := 0


	for instance_root in roots_to_hide:

		if not is_instance_valid(
			instance_root
		):
			continue


		instance_root.visible = false


		instance_root.set_meta(
			"converted_to_multimesh",
			true
		)


		hidden_roots += 1


	# ========================================================
	# RELATÓRIO
	# ========================================================

	print("")
	print("--------------------------------------------")
	print("CONVERSÃO FINALIZADA")
	print("--------------------------------------------")


	print(
		"Objetos originais convertidos: ",
		hidden_roots
	)


	print(
		"MultiMeshes criados nesta execução: ",
		total_multimeshes
	)


	print(
		"Instâncias visuais adicionadas: ",
		total_render_instances
	)


	print("")


	for model_name in model_multimesh_count.keys():

		print(
			model_name,
			" | MultiMeshes: ",
			model_multimesh_count[
				model_name
			],
			" | Instâncias visuais: ",
			model_render_instance_count[
				model_name
			]
		)


	print("--------------------------------------------")


	print(
		"Conversões anteriores foram preservadas."
	)


	print(
		"Verifique visualmente antes de salvar a cena."
	)


	print("============================================")
	print("")


# ============================================================
# ENCONTRAR INSTÂNCIAS ALVO
# ============================================================

func collect_target_instances(
	node: Node,
	targets: PackedStringArray,
	output: Array[Node3D]
) -> void:

	if (
		node is Node3D
		and
		not node.scene_file_path.is_empty()
	):

		var scene_name := (
			node.scene_file_path.get_file()
		)


		if targets.has(
			scene_name
		):

			# ------------------------------------------------
			# JÁ FOI CONVERTIDO?
			# ------------------------------------------------

			if (
				node.has_meta(
					"converted_to_multimesh"
				)
				and
				bool(
					node.get_meta(
						"converted_to_multimesh"
					)
				)
			):

				return


			output.append(
				node as Node3D
			)


			# Não precisa procurar dentro desta
			# instância de cena.
			return


	for child in node.get_children():

		collect_target_instances(
			child,
			targets,
			output
		)


# ============================================================
# COLETAR TODAS AS MESHES DO MODELO
# ============================================================

func collect_mesh_instances(
	node: Node,
	output: Array[MeshInstance3D]
) -> void:

	if node is MeshInstance3D:

		output.append(
			node as MeshInstance3D
		)


	for child in node.get_children():

		collect_mesh_instances(
			child,
			output
		)


# ============================================================
# MESH COMPARTILHADA
# ============================================================

func create_shared_mesh(
	template: MeshInstance3D
) -> Mesh:

	if template.mesh == null:
		return null


	var has_surface_override := false


	for surface_index in range(
		template.get_surface_override_material_count()
	):

		var override_material := (
			template.get_surface_override_material(
				surface_index
			)
		)


		if override_material != null:

			has_surface_override = true
			break


	# --------------------------------------------------------
	# SEM OVERRIDE
	#
	# Usa diretamente a Mesh original.
	# --------------------------------------------------------

	if not has_surface_override:

		return template.mesh


	# --------------------------------------------------------
	# COM OVERRIDE
	#
	# Cria apenas UMA cópia para esse tipo de mesh,
	# compartilhada por todas as células.
	# --------------------------------------------------------

	var mesh_copy := (
		template.mesh.duplicate()
		as Mesh
	)


	if mesh_copy == null:
		return null


	for surface_index in range(
		template.get_surface_override_material_count()
	):

		if (
			surface_index
			>=
			mesh_copy.get_surface_count()
		):

			continue


		var override_material := (
			template.get_surface_override_material(
				surface_index
			)
		)


		if override_material != null:

			mesh_copy.surface_set_material(
				surface_index,
				override_material
			)


	return mesh_copy


# ============================================================
# COPIAR CONFIGURAÇÕES VISUAIS
# ============================================================

func copy_geometry_settings(
	source: MeshInstance3D,
	target: MultiMeshInstance3D
) -> void:

	target.layers = (
		source.layers
	)


	target.cast_shadow = (
		source.cast_shadow
	)


	target.gi_mode = (
		source.gi_mode
	)


	target.material_override = (
		source.material_override
	)


	target.material_overlay = (
		source.material_overlay
	)


	target.extra_cull_margin = (
		source.extra_cull_margin
	)


	target.ignore_occlusion_culling = (
		source.ignore_occlusion_culling
	)


	target.visibility_range_begin = (
		source.visibility_range_begin
	)


	target.visibility_range_begin_margin = (
		source.visibility_range_begin_margin
	)


	target.visibility_range_end = (
		source.visibility_range_end
	)


	target.visibility_range_end_margin = (
		source.visibility_range_end_margin
	)


	target.visibility_range_fade_mode = (
		source.visibility_range_fade_mode
	)


# ============================================================
# CÉLULA
# ============================================================

func get_cell(
	position: Vector3
) -> Vector2i:

	return Vector2i(
		floori(
			position.x
			/
			CELL_SIZE
		),

		floori(
			position.z
			/
			CELL_SIZE
		)
	)


# ============================================================
# ORIGEM DO MULTIMESH
# ============================================================

func get_bucket_origin(
	cell: Vector2i,
	meshes: Array
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
	# Y MÉDIO
	# --------------------------------------------------------

	var y := 0.0

	var valid_count := 0


	for mesh_variant in meshes:

		var mesh_node := (
			mesh_variant
			as MeshInstance3D
		)


		if mesh_node == null:
			continue


		y += (
			mesh_node.global_position.y
		)


		valid_count += 1


	if valid_count > 0:

		y /= float(
			valid_count
		)


	return Vector3(
		x,
		y,
		z
	)


# ============================================================
# LIMPAR NOMES
# ============================================================

func sanitize_name(
	value: String
) -> String:

	var result := value


	result = result.replace(
		"/",
		"_"
	)


	result = result.replace(
		":",
		"_"
	)


	result = result.replace(
		".",
		"_"
	)


	result = result.replace(
		"@",
		"_"
	)


	if result.is_empty():

		result = "Mesh"


	return result
