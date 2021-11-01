tool
extends Node

signal remote_node_selected(id)

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
	
	update_clients_submenu()
	
	print('enable remote debug')
	enable = true


func on_disable():
	var tree = get_remote_tree()
	if tree:
		tree.disconnect('item_activated', self, '_on_remote_tree_item_doubleclicked')
	get_plugin().remove_autoload_singleton(REMOTE_DEBUG_CLIENT_AUTOLOAD_NAME)
	
	remote_debug_server.queue_free()
	remote_debug_server = null
	
	print('disable remote debug')
	enable = false
	
	update_clients_submenu()

#----- Lambdas -----
func __get_node_path_call_back(node_path):
	print(node_path)

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
	remote_debug_server.protocol.call_api('get_node_path', [obj_id], CaptureFuncObject.new({}, self, '__get_node_path_call_back'))






