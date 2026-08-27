extends Control
class_name Dialogues 

@onready var label: Label = $Label
@onready var timer: Timer = $Timer

var dialogues: Array = [
]
#____EM TESTE_______

#___________________
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
	label.text = dialogues[index]
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
