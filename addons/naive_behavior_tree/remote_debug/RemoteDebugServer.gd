tool
extends Node

signal client_connected(peer)
signal client_disconnected(peer)
signal client_message(peer, data)
signal current_peer_changed(peer)

const port := 45537

var server:TCP_Server

var clients := {}

var debug := false

var current_peer:PacketPeerStream = null

var Protocol := preload('./ServerProtocol.gd')
var protocol := Protocol.new()

func _enter_tree() -> void:
	server = TCP_Server.new()
	
	var err := server.listen(port)
	if err != OK:
		printerr('Remote debug server can\'t listen on port: %s [ERROR:%s]' % [port, err])
		return
	
	print_debug_msg('Remote debug server lisien on port: %s' % port)

func _exit_tree() -> void:
	clients.clear()
	server.stop()
	print_debug_msg('Remote debug server stopped.')

func _ready() -> void:
	protocol.connect('request_put_var', self, 'put_var')
	connect('client_message', protocol, 'on_recieve_data')

func _process(delta: float) -> void:
	if not server.is_listening():
		return
	if server.is_connection_available():
		var stream_peer:StreamPeerTCP = server.take_connection()
		var peer := PacketPeerStream.new()
		peer.stream_peer = stream_peer
		var peer_id = get_peer_id(peer)
		
		if clients.has(peer_id):
			clients[peer_id].free()
		clients[peer_id] = peer
		print_debug_msg('[%s] connected.' % peer_id)
		emit_signal('client_disconnected', peer)
	
	check_all_client_status()
	recieve_msg_from_current_peer()
#----- Methods -----
func print_debug_msg(msg:String):
	if debug:
		print('[RemoteDebugServer]: %s' % msg)

func check_all_client_status():
	var removed_client_list := []
	for peer_id in clients.keys():
		var peer:PacketPeerStream = clients[peer_id]
		var stream_peer := peer.stream_peer
		var status = stream_peer.get_status()
		if status != StreamPeerTCP.STATUS_CONNECTED:
			print_debug_msg('[%s] has disconnected.' % peer_id)
			removed_client_list.append(peer_id)
	
	for peer_id in removed_client_list:
		var peer = clients[peer_id]
		clients.erase(peer_id)
		emit_signal('client_disconnected', peer)

func recieve_msg_from_current_peer():
	if current_peer == null:
		return
	for i in current_peer.get_available_packet_count():
		var data = current_peer.get_var()
		var err = current_peer.get_packet_error()
		if err != OK:
			print_debug_msg('Error happens while fetching packet [Error:%s]' % err)
			continue
		emit_signal('client_message', current_peer, data)
#		print_debug_msg('from client: %s' % data)

func get_peer_id(peer:PacketPeerStream) -> String:
	if not peer:
		return ''
	var stream_peer = peer.stream_peer
	return '%s:%s' % [stream_peer.get_connected_host(), stream_peer.get_connected_port()]

func set_current_peer_by_index(id:int):
	if id < 0 or id >= clients.keys().size():
		set_current_peer('')
		return
	set_current_peer(clients.keys()[id])

func set_current_peer(peer_id):
	if clients.has(peer_id):
		if clients[peer_id] == current_peer:
			return
		current_peer = clients[peer_id]
	else:
		current_peer = null
	print_debug_msg('set current peer to: %s' % (get_peer_id(current_peer) if current_peer else 'null'))
	emit_signal('current_peer_changed', current_peer)

func put_var(v):
	if current_peer == null:
		print_debug_msg('current_peer == null!')
		return
	var err = current_peer.put_var(v)
	if err != OK:
		print_debug_msg('can\'t put var. [Error:%s]' % err)
		return
#----- Signals -----

