extends Reference

var data := {}



func _init(_data:Dictionary = {}) -> void:
	data = _data

#----- Methods -----

# path = 'k1/k2/k3'
func get(path:String):
	var ss := path.split('/')
	var current_dic = data
	var index = 0
	for key in ss:
		if current_dic.has(key):
			if not current_dic[key] is Dictionary:
				if index < ss.size()-1:
					return null
			current_dic = current_dic[key]
		else:
			return null
		index += 1
	return current_dic

func set(path:String, value):
	var ss := path.split('/')
	if ss.empty():
		printerr('The path is empty.')
		return
	var current_dic = data
	var index := 0
	for key in ss:
		if not current_dic.has(key):
			if index == ss.size()-1:
				current_dic[key] = value
				return
			else:
				current_dic[key] = {}
		
		if index == ss.size()-1:
			current_dic[key] = value
			return
		else:
			if not current_dic[key] is Dictionary:
				printerr('Wrong path: %s, key is not dic: %s' % [path, key])
				return
			current_dic = current_dic[key]
		index += 1

