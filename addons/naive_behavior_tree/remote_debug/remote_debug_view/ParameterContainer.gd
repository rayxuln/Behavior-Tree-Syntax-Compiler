tool
extends VBoxContainer


var data:Dictionary

var ParameterView := preload('./ParameterView.tscn')

#----- Methods -----
func set_data(_data):
	data = _data
	update_content()

func update_data(_data:Dictionary):
	for k in _data.keys():
		data[k] = data.keys()
	update_content()

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
				c.get_value().text = str(data[k])
				use_old_child = true
				break
		if not use_old_child:
			var c = ParameterView.instance()
			c.get_key().text = k
			c.get_value().text = str(data[k])
			new_children.append(c)
	
	for c in children:
		c.free()
	
	for c in new_children:
		add_child(c)


