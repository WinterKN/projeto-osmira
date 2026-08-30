extends Node

signal quest_changed()
signal area_entered(area: AREA)
signal person_talked(person: PERSON)

enum  QUEST_TYPE {ENTER, TALK_WITH}
enum PERSON {BEN, ANNA}
enum AREA {OCA_PRINCIPAL}
var activeQuests: Array[Quest] = []

func add_quest(quest:Quest):
	activeQuests.append(quest.duplicate())
	quest_changed.emit()

func enter_area(area: AREA, quantity):	
	for quest: Quest in activeQuests:
		if quest.questType == QUEST_TYPE.ENTER and quest.questArea == area:
			quest.quantityCollected += quantity
			
	quest_changed.emit()
	area_entered.emit()

func talk_with(person: PERSON):
	for quest: Quest in activeQuests:
		if quest.questType == QUEST_TYPE.TALK_WITH and quest.questPerson == person:
			quest.quantityCollected += 1
	
	quest_changed.emit()
	person_talked.emit()

func own_quest_done(person:PERSON):
	for quest: Quest in activeQuests:
		var questDone =  quest.quantityCollected >= quest.quantityGoal
		
		if quest.to == person and questDone:
			return quest
			
func quest_done(quest:Quest):
	activeQuests.erase(quest)
	quest_changed.emit()
