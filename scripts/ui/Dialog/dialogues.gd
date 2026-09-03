extends Control
class_name Dialogues 

signal orador_alterado(orador: String)

@export var quests: Array[Quest]

@onready var label: Label = $Label
@onready var timer: Timer = $Timer

var dialogues: Array = [
]

var index: int = 0
var is_dialogue_active: bool = false

func _ready() -> void:
	add_to_group("dialog")
	label.visible = false
	label.text = ""
	timer.timeout.connect(animate_label)
	
func carregar_dialogo_txt(caminho_arquivo: String) -> void:
	if not FileAccess.file_exists(caminho_arquivo):
		push_error("Arquivo TXT não encontrado: " + caminho_arquivo)
		return

	var arquivo = FileAccess.open(caminho_arquivo, FileAccess.READ)
	dialogues.clear() # Limpa diálogos anteriores

	while not arquivo.eof_reached():
		var linha = arquivo.get_line().strip_edges()
		if linha != "": # Ignora linhas vazias
			dialogues.append(linha)

	arquivo.close()
	index = 0
func avançar_dialogo() -> bool:
	# Trava de segurança: impede o erro se o array estiver vazio
	if dialogues.size() == 0:
		push_error("ERRO: Nenhum diálogo foi carregado no array!")
		return false

	if not is_dialogue_active:
		is_dialogue_active = true
		label.visible = true
		mostrar_fala_atual()
		return true

	# Se as letras ainda estão aparecendo, completa a frase imediatamente
	if label.visible_ratio < 1.0:
		label.visible_characters = -1
		timer.stop()
		return true

	index += 1

	if index < dialogues.size():
		mostrar_fala_atual()
		return true
	else:
		encerrar_dialogo()
		return false
func mostrar_fala_atual() -> void:
	if index < dialogues.size():
		var linha_bruta: String = dialogues[index]
		var texto_final: String = linha_bruta

		# Identifica quem está falando com base no primeiro caractere
		if linha_bruta.begins_with("*"):
			orador_alterado.emit("npc")
			texto_final = linha_bruta.substr(1).strip_edges() # Remove o '*' do texto
		elif linha_bruta.begins_with("#"):
			orador_alterado.emit("player")
			texto_final = linha_bruta.substr(1).strip_edges() # Remove o '#' do texto
		else:
			# Se não tiver caractere especial, mantém o padrão como NPC
			orador_alterado.emit("npc")

		label.text = texto_final
		label.visible_characters = 0
		timer.start()

func animate_label() -> void:
	if label.visible_ratio < 1.0:
		label.visible_characters += 1
		timer.start()
	else:
		timer.stop() # Para o timer assim que a frase completa

func encerrar_dialogo() -> void:
	is_dialogue_active = false
	label.visible = false
	label.text = ""
	index = 0
	timer.stop()
	if not quests.is_empty():
		_get_quest()

	
	
func _get_quest():
	var Pick = quests.front()
	GameManager.add_quest(Pick)
	quests.erase(Pick)
