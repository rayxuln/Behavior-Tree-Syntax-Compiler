tool
extends Node

signal remote_node_selected(id)

var debug = false

const CaptureFuncObject = preload('./CaptureFuncObject.gd')

const TOOL_MENU_NAME := 'Behavior Tree Remote Debug'
const TOOL_MENU_ENABLE_ID := 0

const CLIENTS_MENU_NAME := 'Clients'
const CLIENTS_MENU_ID := 1

const REMOTE_DEBUG_CLIENT_AUTOLOAD_NAME := 'NBT_RemoteDebugClient'
const REMOTE_DEBUG_CLIENT_PATH := 'RemoteDebugClient.gd'

var tool_menu:PopupMenu = null

const RemoteDebugServer = preload('./RemoteDebugServer.gd')
var remote_debug_server:RemoteDebugServer
const REMOTE_DEBUG_VIEW_TITLE := 'NBT Remote Debug'

const RemoteDebugView = preload('./remote_debug_view/RemoteDebugView.tscn')
var remote_debug_view:Control

const ProgressModelView = preload('./remote_debug_view/ProgressModelView.tscn')

var remote_tree_np := @'/root/EditorNode/@@580/@@581/@@589/@@591/@@595/@@596/@@597/Scene/@@6782'

var enable := false

func _enter_tree() -> void:
	get_plugin().add_tool_submenu_item(TOOL_MENU_NAME, create_tool_item())

func _exit_tree() -> void:
	if enable:
		on_disable()
	get_plugin().remove_tool_menu_item(TOOL_MENU_NAME)

func _ready() -> void:
	connect('remote_node_selected', self, '_on_remote_node_selected')
	
	tool_menu.set_item_checked(TOOL_MENU_ENABLE_ID, enable)
	if enable:
		on_enable()

#----- Methods -----
func create_tool_item():
	if tool_menu == null:
		tool_menu = PopupMenu.new()
		tool_menu.add_check_item('Enable', TOOL_MENU_ENABLE_ID)
		tool_menu.connect('id_pressed', self, '_on_tool_menu_clicked')
		create_clients_submenu()
		update_clients_submenu()
	return tool_menu
	

func get_plugin() -> EditorPlugin:
	return get_parent() as EditorPlugin


func get_remote_tree() -> Tree:
	return get_node_or_null(remote_tree_np) as Tree

func get_remote_debug_client_script_path():
	var p = preload(REMOTE_DEBUG_CLIENT_PATH)
	return p.resource_path

func create_clients_submenu():
	var menu := PopupMenu.new()
	menu.connect('id_pressed', self, '_on_clients_menu_item_clicked')
	tool_menu.add_child(menu)
	menu.name = CLIENTS_MENU_NAME
	tool_menu.add_submenu_item(CLIENTS_MENU_NAME, CLIENTS_MENU_NAME, CLIENTS_MENU_ID)

func update_clients_submenu(removed_peer := null):
	if not enable:
		tool_menu.set_item_disabled(CLIENTS_MENU_ID, false)
		return -1
	
	if not remote_debug_server:
		return
	
	var current_client_index = -1
	var clients_menu := tool_menu.get_node(CLIENTS_MENU_NAME) as PopupMenu
	for i in clients_menu.get_item_count():
		if clients_menu.is_item_checked(i) and clients_menu.get_item_text(i) != remote_debug_server.get_peer_id(removed_peer):
			current_client_index = i
			break
	
	clients_menu.clear()
	
	for peer_id in remote_debug_server.clients.keys():
		clients_menu.add_check_item(peer_id)
		
	if current_client_index == -1:
		current_client_index = 0
	
	if current_client_index >= 0 and current_client_index < clients_menu.get_item_count():
		clients_menu.set_item_checked(current_client_index, true)
	
	tool_menu.set_item_disabled(CLIENTS_MENU_ID, clients_menu.get_item_count() == 0)
	
	return current_client_index

func on_enable():
	var tree = get_remote_tree()
	if tree == null:
		printerr('The remote tree is not available, may due to the path has been changed. Disabling...')
		return
	tree.connect('item_activated', self, '_on_remote_tree_item_doubleclicked')
	get_plugin().add_autoload_singleton(REMOTE_DEBUG_CLIENT_AUTOLOAD_NAME, get_remote_debug_client_script_path())
	
	remote_debug_server = RemoteDebugServer.new()
	add_child(remote_debug_server)
	remote_debug_server.connect('client_connected', self, '_on_client_connected')
	remote_debug_server.connect('client_disconnected', self, '_on_client_disconnected')
	remote_debug_server.connect('current_peer_changed', self, '_on_current_peer_changed')
	remote_debug_server.protocol.connect('tree_active', self, '_on_tree_active')
	remote_debug_server.protocol.connect('tree_inactive', self, '_on_tree_inactive')
	remote_debug_server.protocol.connect('tree_node_status_changed', self, '_on_tree_node_status_changed')
	
	update_clients_submenu()
	
	remote_debug_view = RemoteDebugView.instance()
	get_plugin().add_control_to_bottom_panel(remote_debug_view, REMOTE_DEBUG_VIEW_TITLE)
	remote_debug_view.connect('request_open_script', self, '_on_request_open_script')
	remote_debug_view.connect('request_screenshot', self, '_on_take_screenshot')
	
	print('enable remote debug')
	enable = true
	


func on_disable():
	var tree = get_remote_tree()
	if tree:
		tree.disconnect('item_activated', self, '_on_remote_tree_item_doubleclicked')
	get_plugin().remove_autoload_singleton(REMOTE_DEBUG_CLIENT_AUTOLOAD_NAME)
	
	remote_debug_server.queue_free()
	remote_debug_server = null
	
	get_plugin().remove_control_from_bottom_panel(remote_debug_view)
	remote_debug_view.queue_free()
	remote_debug_view = null
	
	print('disable remote debug')
	enable = false
	
	update_clients_submenu()

func print_debug_msg(msg):
	if debug:
		print('[RemoteDebug]: %s' % msg)
#----- Lambdas -----
func __get_node_path_call_back(node_path):
	print_debug_msg(node_path)


func __get_bt_data_call_back(bt_data):
	remote_debug_view.on_recieve_all_data(bt_data)
	if bt_data == null:
		if remote_debug_view.is_visible_in_tree():
			get_plugin().hide_bottom_panel()
		return
	get_plugin().make_bottom_panel_item_visible(remote_debug_view)
#----- Signals -----
func _on_tool_menu_clicked(id:int):
	match id:
		TOOL_MENU_ENABLE_ID:
			var checked = not tool_menu.is_item_checked(TOOL_MENU_ENABLE_ID)
			tool_menu.set_item_checked(TOOL_MENU_ENABLE_ID, checked)
			if checked:
				on_enable()
			else:
				on_disable()

func _on_remote_tree_item_doubleclicked():
	var tree := get_remote_tree()
	var tree_item := tree.get_selected()
	var remote_node_id = tree_item.get_metadata(0)
	emit_signal('remote_node_selected', remote_node_id)

func _on_client_connected(peer:PacketPeerStream):
	var id = update_clients_submenu()
	remote_debug_server.set_current_peer_by_index(id)

func _on_client_disconnected(peer:PacketPeerStream):
	var id = update_clients_submenu(peer)
	remote_debug_server.set_current_peer_by_index(id)

func _on_clients_menu_item_clicked(id:int):
	var menu := tool_menu.get_node(CLIENTS_MENU_NAME) as PopupMenu
	var checked := menu.is_item_checked(id)
	if not checked:
		for i in menu.get_item_count():
			menu.set_item_checked(i, false)
		menu.set_item_checked(id, true)
		remote_debug_server.set_current_peer_by_index(id)

func _on_remote_node_selected(obj_id):
	if not enable:
		return
	remote_debug_server.protocol.call_api('get_node_path', [obj_id], CaptureFuncObject.new({}, self, '__get_node_path_call_back'))
	
	remote_debug_server.protocol.call_api('get_bt_data', [obj_id], CaptureFuncObject.new({}, self, '__get_bt_data_call_back'))
	
	remote_debug_server.protocol.call_api('set_current_bt', [obj_id])


func _on_tree_active(event):
	remote_debug_view.on_update_data('enable', true)

func _on_tree_inactive(event):
	remote_debug_view.on_update_data('enable', false)

func _on_current_peer_changed(peer):
	if not remote_debug_view:
		return
	remote_debug_view.on_recieve_all_data(null)

func _on_tree_node_status_changed(event):
	remote_debug_view.on_update_tree_node_data(event.data.obj_id, event.data)

func _on_request_open_script(path):
	var script = load(path) as Script
	if script == null:
		printerr('%s is not a script!' % path)
		return
	get_plugin().get_editor_interface().edit_resource(script)


func _on_take_screenshot():
	if remote_debug_view == null:
		return
	if remote_debug_view.db.data.empty():
		return
	
	var theme = get_plugin().get_editor_interface().get_base_control().theme
	
	var p = ProgressModelView.instance()
	add_child(p)
	p.title.text = 'Taking screen shot please wait...'
	p.theme = theme
	var pb:ProgressBar = p.progress_bar
	pb.max_value = 6
	pb.value = 0
	p.show_modal(true)
		
	var vp = Viewport.new()
	add_child(vp)
	vp.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	vp.render_target_update_mode = Viewport.UPDATE_ALWAYS
	vp.render_target_v_flip = true
	
#	print('start taking screenshot (1)')
	pb.value = 1
	
	yield(get_tree().create_timer(0.1), 'timeout')
#	print('setting up viewport (2)')
	var temp_view = RemoteDebugView.instance()
	vp.add_child(temp_view)
	temp_view.theme = theme
	temp_view.get_node('VBoxContainer/HBoxContainer').visible = false
	pb.value = 2
	var graph_edit = temp_view.graph_edit as GraphEdit
	graph_edit.get_child(0).visible = false
	
	yield(get_tree().create_timer(0.1), 'timeout')
#	print('setting up graph node view (3)')
	var data = remote_debug_view.db.data as Dictionary
	temp_view.on_recieve_all_data(data, false)
	temp_view.show()
	
	yield(get_tree().create_timer(0.5), 'timeout')
	var root = temp_view.obj_id_node_map[temp_view.db.get('root/obj_id')]
	var ct_tree = temp_view.calc_tree_size(root)
	vp.size = ct_tree.tree_size + Vector2(20, 20)
	
	
	pb.value = 3
	
	yield(get_tree().create_timer(0.1), 'timeout')
#	print('adjust graph node view (4)')
	graph_edit.scroll_offset = Vector2(-10, -10)
	graph_edit.minimap_enabled = false
	graph_edit.use_snap = false
	
	pb.value = 4
	
	yield(get_tree().create_timer(0.1), 'timeout')
#	print('taking image data (5)')
	var img = vp.get_texture().get_data() as Image
	img.save_png('res://nbt_screen_shot.png')
	pb.value = 5
	
	yield(get_tree().create_timer(0.1), 'timeout')
#	print('done! (6)')
	vp.queue_free()
	pb.value = 6
	
	yield(get_tree().create_timer(0.1), 'timeout')
	p.queue_free()
	
	






