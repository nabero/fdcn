extends Panel


onready var already_seen_polygon = $AlreadySeenPolygon
onready var session_seen_polygon = $SessionSeenPolygon
onready var combat_polygon = $CombatPolygon


var chap_number
var main

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_main(main):
	self.main = main

func set_chapitre(chapitre):
	self.chap_number = chapitre
	$NBChapitre.text = '%3d' % chapitre
	

func set_already_seen():
	$AlreadySeenPolygon.color = Color('00c2aa')

func set_session_seen():
	$SessionSeenPolygon.color = Color('00c2aa')

func set_combat():
	$CombatPolygon.color = Color('ff6f04')


func _on_Button_pressed():
	print('CLICK: on chapter: %s' % self.chap_number)
	self.main.go_to_node(self.chap_number)