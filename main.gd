extends Node2D

var current_node_id = 1
var all_nodes = {}

var session_visited_nodes = []

var visited_nodes_all_times = []

var current_lines = []



onready var Bread = preload('res://bread.tscn')
onready var Choice = preload('res://ChapterChoice.tscn')

onready var gauge = $Background/GlobalCompletion/Gauge


# Give something like C:\Users\j.gabes\AppData\Roaming\Godot\app_userdata\fdcn for windows
var all_times_already_visited_file = "user://all_times_already_visited.save"
var current_node_id_file = "user://current_node_id.save"
var session_visited_nodes_file  = "user://session_visited_nodes.save"


func load_all_times_already_visited():
	var f = File.new()
	if f.file_exists(all_times_already_visited_file):
		f.open(all_times_already_visited_file, File.READ)
		visited_nodes_all_times = f.get_var()
		f.close()
	else:
		visited_nodes_all_times = []

func save_all_times_already_visited():
	var f = File.new()
	f.open(all_times_already_visited_file, File.WRITE)
	print('SAVING in file: %s' % f)
	f.store_var(visited_nodes_all_times)
	f.close()


func load_current_node_id():
	var f = File.new()
	if f.file_exists(current_node_id_file):
		f.open(current_node_id_file, File.READ)
		current_node_id = f.get_var()
		f.close()
	else:
		current_node_id = 1

func save_current_node_id():
	var f = File.new()
	f.open(current_node_id_file, File.WRITE)
	print('SAVING in file: %s' % f)
	f.store_var(current_node_id)
	f.close()


func load_session_visited_nodes():
	var f = File.new()
	if f.file_exists(session_visited_nodes_file):
		f.open(session_visited_nodes_file, File.READ)
		session_visited_nodes = f.get_var()
		f.close()
	else:
		session_visited_nodes = []

func save_session_visited_nodes():
	var f = File.new()
	f.open(session_visited_nodes_file, File.WRITE)
	print('SAVING in file: %s' % f)
	f.store_var(session_visited_nodes)
	f.close()
	

func load_json_file(path):
	"""Loads a JSON file from the given res path and return the loaded JSON object."""
	var file = File.new()
	file.open(path, file.READ)
	var text = file.get_as_text()
	var result_json = JSON.parse(text)
	if result_json.error != OK:
		print("[load_json_file] Error loading JSON file '" + str(path) + "'.")
		print("\tError: ", result_json.error)
		print("\tError Line: ", result_json.error_line)
		print("\tError String: ", result_json.error_string)
		return null
	var obj = result_json.result
	return obj


func go_to_node(node_id):
	self.current_node_id = node_id
	self.save_current_node_id()
	
	# Update session, but maybe it's just a app reload
	if len(self.session_visited_nodes) == 0 or self.session_visited_nodes[len(self.session_visited_nodes) -1] != node_id:
		self.session_visited_nodes.append(self.current_node_id)
		self.save_session_visited_nodes()
	else:
		print('Already on the visited session update: %s' % str(self.session_visited_nodes))
	print('Visited session: %s' % str(self.session_visited_nodes))
	
	# Update id if not already visited
	if !(self.current_node_id in visited_nodes_all_times):
		self.visited_nodes_all_times.append(self.current_node_id)
		self.save_all_times_already_visited()
		
	print('SESSION visited nodes: %s' % str(self.session_visited_nodes))
	print('ALL TIMES visited nodes: %s' % str(self.visited_nodes_all_times))
	
	self.refresh()


func _get_node(node_id):
	return self.all_nodes['%s' % node_id]



static func delete_children(node):
	for n in node.get_children():
		node.remove_child(n)
		n.queue_free()
		


func _ready():
	#Load the main font file
	var dynamic_font = DynamicFont.new()
	dynamic_font.font_data = load('res://fonts/amon_font.tres')
	
	self.all_nodes = load_json_file("res://fdcn-1-compilated-data.json")
	
	# Load the nodes ids we did already visited in the past
	self.load_all_times_already_visited()
	self.load_current_node_id()
	self.load_session_visited_nodes()
	
	self.go_to_node(self.current_node_id)

	
	
func refresh():
	# Update the % completion
	#var fdcn_completion = $MarginContainer/VBoxContainer/HBoxTotalSummary/FDCNCompletion
	var _nb_all_nodes = len(self.all_nodes)
	var _nb_visited = len(self.visited_nodes_all_times)
	#var _s = '%.1f %%' % (100 * _nb_visited / float(_nb_all_nodes)) + (' (%d /' % _nb_visited) + (' %d )' % _nb_all_nodes)
	#fdcn_completion.text = _s
	var completion_foot_note = $Background/GlobalCompletion/footnode
	completion_foot_note.text = (' %d /' % _nb_visited) + (' %d' % _nb_all_nodes)
	
	gauge.set_value(_nb_visited / float(_nb_all_nodes))
	
	# Now print my current node
	#print('Loaded object:', self.all_nodes['%s' % self.current_node_id])
	var my_node = self._get_node(self.current_node_id)
	
	# The act in progress
	var _acte_label = $Background/Position/Acte
	_acte_label.text = '%s' % my_node['computed']['chapter']
	
	var fill_bar = $Background/Position/fill_bar
	fill_bar.value = 40  # 40% of the act is done
	
	# The number
	var _chapitre_label = $Background/Position/NumeroChapitre
	_chapitre_label.text = '%s' % my_node['computed']['id']
	
	#Breads
	var breads = $Background/Dreadcumb/breads
	delete_children(breads)
	var nb_previous = len(self.session_visited_nodes)
	#print('ORIGINAL prevs: %s' % str(self.session_visited_nodes))
	
	var last_previous = self.session_visited_nodes
	if len(self.session_visited_nodes) > 5:
		last_previous = self.session_visited_nodes.slice(nb_previous - 5, nb_previous)
	#print('LAST 5: %s' % str(last_previous))
	var _nb_lasts = len(last_previous)
	var _i = 0
	for previous in last_previous:
		var bread = Bread.instance()
		bread.set_chap_number(previous)
		bread.set_main(self)
		#print('COMPARING BREAD: %s' % _i, ' ', _nb_lasts)
		#bread.set_position(Vector2(_i*200, 0))
		if _i == 0:
			#print('COMPARING BREAD: FIRST %s' % _i,' ',  _nb_lasts)
			bread.set_first()
		# If previous
		
		if _i == _nb_lasts - 2:
			bread.set_previous()
			#print('COMPARING BREAD: PREVIOUS %s' % _i, ' ', _nb_lasts)
		elif _i == _nb_lasts - 1:
			#print('COMPARING BREAD: CURRENT %s' % _i, ' ', _nb_lasts)
			bread.set_current()
		else:
			#print('COMPARING BREAD: NORMAL %s' % _i, ' ', _nb_lasts)
			bread.set_normal_color()
		breads.add_child(bread)
		_i = _i + 1
		
	
	# And my sons
	var sons_ids = my_node['computed']['sons']
	
	# Clean choices
	var choices = $Background/Next/Choices
	delete_children(choices)
	for son_id in sons_ids:
		print('My son: %s' % son_id)
		
		var son = self._get_node(son_id)
		
		var choice = Choice.instance()
		choice.set_main(self)
		print('NODE: %s' % son)
		choice.set_chapitre(son['computed']['id'])
		if son['computed']['is_combat']:
			choice.set_combat()
		if son_id in self.session_visited_nodes:
			choice.set_session_seen()
		if son_id in self.visited_nodes_all_times:
			choice.set_already_seen()
		choices.add_child(choice)
				




# We are jumping back until we found the good chapter number
func jump_back(previous_id):
	print('jump_back::Jumping back to %s' % previous_id)
	print('jump_back::SESSION visited nodes: %s' % str(self.session_visited_nodes))
	if len(self.session_visited_nodes) == 1:
		print('jump_back::CANNOT GO BACK')
		return
		
	while true:
		if len(self.session_visited_nodes) == 0:
			print('jump_back::CRITICAL: cannot find the jump back node %s' % previous_id)
			return
		var ptn_id = self.session_visited_nodes.pop_back()  # drop as we did stack it
		print('jump_back::BACK: Look at %s' % ptn_id, ' asked %s' % previous_id)
		if ptn_id == previous_id:
			print('jump_back::BACK: geck back at %s' % previous_id)
			break
	
	self.go_to_node(previous_id)
	
