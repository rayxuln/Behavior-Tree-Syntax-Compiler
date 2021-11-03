extends Node

signal server_message(peer, data)

const SETTING_KEY_DEBUG := 'nbt_plugin/remote_debug/debug_mode'
const SETTING_KEY_SEVER_ADDRESS := 'nbt_plugin/remote_debug/server_address'
const SETTING_KEY_SEVER_PORT := 'nbt_plugin/remote_debug/server_port'

var address := 'localhost'
var port := 45537

var peer:PacketPeerStream = null

var connected := false

var Protocol := preload('./ClientProtocol.gd')
var protocol := Protocol.new()

var current_tree:BehaviorTree = null

func _ready() -> void:
	peer = PacketPeerStream.new()
	var stream_peer = StreamPeerTCP.new()
	peer.stream_peer = stream_peer
	var err = stream_peer.connect_to_host(address, port)
	if err != OK:
		print_debug_msg('Can\'t connect to the server: %s:%s' % [address, port])
		print_debug_msg('Removing myself.')
		queue_free()
		queue_free()
		return
	print_debug_msg('connecting to server: %s:%s' % [address, port])
	connected = false
	
	protocol.connect('request_put_var', self, 'put_var')
	connect('server_message', protocol, 'on_recieve_data')
	protocol.connect('set_current_behavior_tree', self, 'set_current_behavior_tree')
	
	if ProjectSettings.has_setting(SETTING_KEY_SEVER_ADDRESS):
		address = ProjectSettings.get_setting(SETTING_KEY_SEVER_ADDRESS)
	if ProjectSettings.has_setting(SETTING_KEY_SEVER_PORT):
		port = ProjectSettings.get_setting(SETTING_KEY_SEVER_PORT)


func _process(delta: float) -> void:
	if not peer:
		return
	var stream_peer := peer.stream_peer
	if not stream_peer.is_connected_to_host():
		return
	if not connected and stream_peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		connected = true
		on_connected()
	if stream_peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		recieve_msg_from_peer()
	elif not stream_peer.is_connected_to_host():
		print_debug_msg('Disconnected from server, removing myself')
		queue_free()
#----- Methods -----
func print_debug_msg(msg:String):
	if ProjectSettings.get_setting(SETTING_KEY_DEBUG):
		print('[RemoteDebugClient]: %s' % msg)

func recieve_msg_from_peer():
	if not peer:
		return
	for i in peer.get_available_packet_count():
		var data = peer.get_var()
		var err = peer.get_packet_error()
		if err != OK:
			print_debug_msg('Error happens while fetching packet [Error:%s]' % err)
			continue
		emit_signal('server_message', peer, data)
#		print_debug_msg('from server: %s' % data)

func put_var(v):
	if peer == null:
		print_debug_msg('peer == null!')
		return
	var err = peer.put_var(v)
	if err != OK:
		print_debug_msg('can\'t put var. [Error:%s]' % err)
		return

func on_connected():
	print_debug_msg('Connected to the server.')

func set_current_behavior_tree(bt):
	if current_tree:
		current_tree.disconnect('tree_active', self, '_on_tree_active')
		current_tree.disconnect('tree_inactive', self, '_on_tree_inactive')
		current_tree.disconnect('task_status_changed', self, '_on_tree_node_status_changed')
	current_tree = bt
	print_debug_msg('set current bt: %s' % bt)
	if current_tree:
		current_tree.connect('tree_active', self, '_on_tree_active')
		current_tree.connect('tree_inactive', self, '_on_tree_inactive')
		current_tree.connect('task_status_changed', self, '_on_tree_node_status_changed')
#----- Signals -----
func _on_tree_active():
	protocol.boardcast_event('tree_active')

func _on_tree_inactive():
	protocol.boardcast_event('tree_inactive')

func _on_tree_node_status_changed(task):
	var data = protocol.gen_tree_node_data(task, true)
	protocol.boardcast_event('tree_node_status_changed', data)
