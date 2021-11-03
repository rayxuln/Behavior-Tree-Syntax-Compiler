extends './RemoteDebugProtocol.gd'


signal set_current_behavior_tree(bt)

const excluded_param := [
	'guard_path',
]

func get_event_name_list():
	return .get_event_name_list() + [
	]
#----- APIs -----
func api_get_node_path(obj_id):
	var obj = instance_from_id(obj_id) as Node
	if not obj:
		printerr('obj id(%s) is invalid.' % obj_id)
		return
	return obj.get_path()

func api_get_bt_data(obj_id):
	var tree = instance_from_id(obj_id) as BehaviorTree
	if not tree:
		return null
	var res := {
		'tree_name': tree.name,
		'tree_obj_id': obj_id,
		'tree_status': tree.status,
		'enable': tree.enable,
		'root': null,
	}
	
	var tree_root_data = gen_tree_data(tree.get_node(tree.root_path))
	res.root = tree_root_data
	
	return res

func api_set_current_bt(obj_id):
	var tree = instance_from_id(obj_id) as BehaviorTree
	emit_signal('set_current_behavior_tree', tree)
	
#----- Methods -----
func gen_tree_node_data(node:BTNode, single := false):
	if node == null:
		printerr('The node is null!')
		return null
	var script := node.get_script() as Script
	if script == null:
		printerr('The script of node[%s] is null.' % node.get_path())
	var guard = node.get_node_or_null(node.guard_path)
	var res = {
			'name': node.name,
			'obj_id': node.get_instance_id(),
			'script': script.resource_path if script else '',
			'status': node.status,
		}
	if not single:
		res.guard =  gen_tree_data(guard) if guard else null
		res.children = []
		gen_tree_node_parameter_data(node, res)
	return res

func gen_tree_node_parameter_data(node:BTNode, btn_data):
	var pd := {}
	for p in node.get_property_list():
		if p.has('usage') and p.usage == (PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT):
			if not p.name in excluded_param:
				pd[p.name] = node.get(p.name)
	btn_data['params'] = pd

func gen_tree_data(node:BTNode):
	var data = gen_tree_node_data(node)
	if data == null:
		return null
	for c in node.get_children():
		if c is BTNode:
			var child_data = gen_tree_data(c)
			if child_data != null:
				data.children.append(child_data)
	return data





