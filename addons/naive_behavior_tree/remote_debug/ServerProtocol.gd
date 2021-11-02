tool
extends './RemoteDebugProtocol.gd'


func get_event_name_list():
	return .get_event_name_list() + [
		'tree_active',
		'tree_inactive',
		'tree_node_status_changed',
	]
#----- APIs -----

