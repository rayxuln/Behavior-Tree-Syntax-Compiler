tool
extends PanelContainer

#----- Methods -----
func get_key():
	return get_node('HBoxContainer/Label')

func get_value():
	return get_node('HBoxContainer/Label2')
