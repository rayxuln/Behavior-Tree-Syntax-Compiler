tool
extends VBoxContainer


var data:Dictionary

var ParameterView := preload('./ParameterView.tscn')

var translate_map := {}
#var translate_map := {
#	'policy': {
#		BTCompositeParallel.Policy.SELECTOR: 'Selector',
#		BTCompositeParallel.Policy.SEQUENCE: 'Sequence',
#	},
#	'orchestrator': {
#		BTCompositeParallel.Orchestrator.Join: 'Join',
#		BTCompositeParallel.Orchestrator.Resume: 'Resume',
#	},
#}

#----- Methods -----
func property_hint_string_to_dict(s:String):
	var ss = s.split(',')
	var res = {}
	for p in ss:
		var ps = p.split(':')
		if ps.size() == 2:
			res[ps[1]] = ps[0]
	return res

func set_data(_data, node_script_path):
	data = _data
	
	if not node_script_path.empty():
			var node_script = load(node_script_path) as Script
			var ps = node_script.get_script_property_list()
			for p in ps:
				if p.usage == (PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE):
					if p.hint == PROPERTY_HINT_ENUM:
						translate_map[p.name] = property_hint_string_to_dict(p.hint_string)
	
	update_content()

func update_data(_data:Dictionary):
	for k in _data.keys():
		data[k] = _data[k]
	update_content()

func translated_data_value(data, k):
	var data_k = str(data[k])
	if translate_map.has(k):
		if translate_map[k].has(data_k):
			return translate_map[k][data_k]
	return data[k]

func update_content():
	var children = get_children()
	for c in children:
		remove_child(c)
	
	var new_children = []
	
	for k in data.keys():
		var use_old_child = false
		for c in children:
			if c.get_key().text == k:
				new_children.append(c)
				children.erase(c)
				c.get_value().text = str(translated_data_value(data, k))
				use_old_child = true
				break
		if not use_old_child:
			var c = ParameterView.instance()
			c.get_key().text = k
			c.get_value().text = str(translated_data_value(data, k))
			new_children.append(c)
	
	for c in children:
		c.free()
	
	for c in new_children:
		add_child(c)


