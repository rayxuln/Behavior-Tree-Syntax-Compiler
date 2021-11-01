extends Node

signal server_message(peer, data)

var debug := true

var address := 'localhost'
var port := 45537

var peer:PacketPeerStream = null

var connected := false

var protocol := RemoteDebugProtocol.new()

func _ready() -> void:
	peer = PacketPeerStream.new()
	var stream_peer = StreamPeerTCP.new()
	peer.stream_peer = stream_peer
	var err = stream_peer.connect_to_host(address, port)
	if err != OK:
		print_debug_msg('Can\'t connect to the server: %s:%s' % [address, port])
		print_debug_msg('Removing myself.')
		queue_free()
		return
	print_debug_msg('connecting to server: %s:%s' % [address, port])
	connected = false
	
	protocol.connect('request_put_var', self, 'put_var')
	connect('server_message', protocol, 'on_recieve_data')

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
	if debug:
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
#----- Signals -----


