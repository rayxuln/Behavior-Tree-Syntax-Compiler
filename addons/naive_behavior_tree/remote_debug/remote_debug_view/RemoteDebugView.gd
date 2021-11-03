tool
extends Control

signal request_open_script(path)
signal request_screenshot

const DictionaryDatabase := preload('../DictionaryDatabase.gd')
const NBTGraphNode := preload('./NBTGraphNode.tscn')
const NBTGraphNodeType := preload('./NBTGraphNode.gd')

var db := DictionaryDatabase.new()
var obj_id_node_map := {}

var horizontal_margin := 100.0
var vertical_margin := 15.0

onready var title_label = $VBoxContainer/HBoxContainer/TitleLabel
onready var graph_edit = $VBoxContainer/GraphEdit
onready var popup_menu = $PopupMenu

func _ready() -> void:
	connect('visibility_changed', self, '_on_visibility_changed')

#----- Methods -----
func on_show():
	update_title()
	update_content()
	pass

func on_hide():
#	db.data.clear()
	pass

func update_content():
	if db.data.empty():
		graph_edit.hide()
		return
	graph_edit.show()
	
	var children := []
	for c in graph_edit.get_children():
		if c is NBTGraphNodeType:
			graph_edit.remove_child(c)
			children.append(c)
	for c in children:
		c.free()
	obj_id_node_map.clear()

	if db.data.root != null:
		create_tree(db.data.root)
	
	update_connections()
	
	yield(get_tree(), 'idle_frame')
	sort_nodes()

func get_status_text(s):
	match s:
		BTNode.CANCELLED:
			return 'Cancelled'
		BTNode.RUNNING:
			return 'Running'
		BTNode.SUCCEEDED:
			return 'Succeeded'
		BTNode.FAILED:
			return 'Failed'
		BTNode.FRESH:
			return 'Fresh'
	return 'Undefined'

func create_tree(node_data):
	# add node
	var node = NBTGraphNode.instance()
	graph_edit.add_child(node)
	node.set_data(node_data)
	node.connect('request_open_script', self, '_on_request_open_script')
	obj_id_node_map[node_data.obj_id] = node
	
	# add guard
	if node_data.guard != null:
		create_tree(node_data.guard)

	# add children
	for child_data in node_data.children:
		create_tree(child_data)

func update_title():
	if db.data.empty():
		title_label.text = 'Please select a BehaviorTree node in the remote scene.'
		return
	title_label.text = '%s(%s) - %s' % [db.get('tree_name'), get_status_text(db.get('tree_status')), ('active' if db.get('enable') else 'inactive')]

func on_recieve_all_data(data):
	if data == null:
		db.data.clear()
	else:
		db.data = data
	update_title()
	update_content()

func on_update_data(path:String, data):
	db.set(path, data)
	update_title()

func on_update_tree_node_data(remote_obj_id, node_data):
	if remote_obj_id == db.get('tree_obj_id'):
		db.set('tree_name', node_data.name)
		db.set('tree_status', node_data.status)
		update_title()
		return
	
	if obj_id_node_map.has(remote_obj_id):
		obj_id_node_map[remote_obj_id].update_data(node_data)
	else:
		printerr('obj[%s]\'s graph node does not exist, bug!' % remote_obj_id)
	

func gen_ct_node(obj_id):
	return {
		'obj_id': obj_id,
		'tree_size': Vector2.ZERO,
		'node_size': Vector2.ZERO,
		'guard': null,
		'children': [],
	}

func calc_tree_size(root:NBTGraphNodeType):
	var root_data = calc_node_size(root)
	var root_size = root_data.node_size
	
	var child_size = Vector2.ZERO
	for c in root.source_data.children:
		var child = obj_id_node_map[c.obj_id]
		var child_tree_data = calc_tree_size(child)
		var child_tree_size = child_tree_data.tree_size
		child_size.x = max(child_size.x, child_tree_size.x)
		child_size.y += child_tree_size.y + vertical_margin
		
		root_data.children.append(child_tree_data)
	
	root_size.x += child_size.x + horizontal_margin
	root_size.y = max(root_size.y, child_size.y)
	
	root_data.tree_size = root_size
	
	return root_data

func calc_node_size(node:NBTGraphNodeType):
	var res_data = gen_ct_node(node.source_data.obj_id)
	var res = node.rect_size
	if node.source_data.guard != null:
		var guard = obj_id_node_map[node.source_data.guard.obj_id]
		var guard_tree_data = calc_tree_size(guard)
		var guard_tree_size = guard_tree_data.tree_size
		res.x = res.x + guard_tree_size.x + horizontal_margin
		res.y = max(res.y, guard_tree_size.y)
		res_data.guard = guard_tree_data
	res_data.node_size = res
	return res_data

func place_node(ct_tree_root, origin:Vector2):
	var root:NBTGraphNodeType = obj_id_node_map[ct_tree_root.obj_id]
	root.offset.x = origin.x
	root.offset.y = origin.y + (ct_tree_root.tree_size.y - ct_tree_root.node_size.y) / 2.0
	
	if ct_tree_root.guard != null:
		var guard_origin = Vector2(root.offset.x + root.rect_size.x + horizontal_margin, root.offset.y)
		place_node(ct_tree_root.guard, guard_origin)
	
	origin.x += ct_tree_root.node_size.x + horizontal_margin
	for c in ct_tree_root.children:
		place_node(c, origin)
		origin.y += c.tree_size.y + vertical_margin

func sort_nodes():
	if db.get('root') == null:
		return
	var ct_tree = calc_tree_size(obj_id_node_map[db.get('root/obj_id')])
	place_node(ct_tree, Vector2.ZERO)

func connect_tree_node(root:NBTGraphNodeType):
	if root.source_data.guard != null:
		var guard = obj_id_node_map[root.source_data.guard.obj_id]
		graph_edit.connect_node(root.name, NBTGraphNodeType.GUARD_SLOT, guard.name, NBTGraphNodeType.PARENT_SLOT)
		connect_tree_node(guard)
	
	for c in root.source_data.children:
		var child = obj_id_node_map[c.obj_id]
		graph_edit.connect_node(root.name, NBTGraphNodeType.CHILDREN_SLOT, child.name, NBTGraphNodeType.PARENT_SLOT)
		connect_tree_node(child)

func update_connections():
	graph_edit.clear_connections()
	
	var root = obj_id_node_map[db.get('root/obj_id')]
	if root == null:
		return
	
	connect_tree_node(root)
#----- Signals -----
func _on_visibility_changed():
	if Engine.editor_hint:
		return
	if is_visible_in_tree():
		on_show()
	else:
		on_hide()

func _on_request_open_script(path):
	emit_signal('request_open_script', path)



func _on_ScreenShotButton_pressed() -> void:
	emit_signal('request_screenshot')


func _on_PopupMenu_id_pressed(id: int) -> void:
	match id:
		0:
			sort_nodes()
		2:
			emit_signal('request_screenshot')


func _on_GraphEdit_popup_request(position: Vector2) -> void:
	popup_menu.rect_global_position = get_global_mouse_position()
	popup_menu.popup()
