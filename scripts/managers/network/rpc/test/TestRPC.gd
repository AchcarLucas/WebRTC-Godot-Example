class_name TestRPC extends Node

'''
	OBS: Para o RPC funcionar, o script tem que compartilhar da mesma Scene
	A Scene TestRPC esta no Autoloaded para cumprir essa exigência!
'''

static var CLASS_NAME: String = (TestRPC as GDScript).get_global_name()

var once_execute: bool = false

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if 	once_execute or \
		multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return

	if multiplayer.multiplayer_peer.get_connection_status() \
			!= MultiplayerPeer.CONNECTION_CONNECTED:
		return

	if multiplayer.is_server():
		_just_server()
	else:
		_just_client()

func _just_server() -> void:
	var once_connected: bool = false

	for client_id in %WebRTC_ServerManager.get_clients():
		if %WebRTC_ServerManager.get_client_id(client_id).connected:
			once_connected = true

	if not once_connected:
		return

	_rpc_test_remote_authority.rpc("HELLO WORLD - AUTHORITY <Sent by the Server> <call_remote>")
	_rpc_test_remote_reliable.rpc("HELLO WORLD - RELIABLE <Sent by the Server> <call_remote>")
	_rpc_test_remote_unreliable_ordered.rpc("HELLO WORLD - UNRELIABLE ORDERED <Sent by the Server> <call_remote>")
	_rpc_test_remote_unreliable.rpc("HELLO WORLD - UNRELIABLE <Sent by the Server> <call_remote>")

	_rpc_test_local_authority.rpc("HELLO WORLD - AUTHORITY <Sent by the Server> <call_local>")
	_rpc_test_local_reliable.rpc("HELLO WORLD - RELIABLE <Sent by the Server> <call_local>")
	_rpc_test_local_unreliable_ordered.rpc("HELLO WORLD - UNRELIABLE ORDERED <Sent by the Server> <call_local>")
	_rpc_test_local_unreliable.rpc("HELLO WORLD - UNRELIABLE <Sent by the Server> <call_local>")

	DebuggingHelper.debug("Execute Once <Just Server>", CLASS_NAME)
	once_execute = true

func _just_client() -> void:
	_rpc_test_remote_authority.rpc("HELLO WORLD - AUTHORITY <Sent by the Client> <call_remote>")
	_rpc_test_remote_reliable.rpc("HELLO WORLD - RELIABLE <Sent by the Client> <call_remote>")
	_rpc_test_remote_unreliable_ordered.rpc("HELLO WORLD - UNRELIABLE ORDERED <Sent by the Client> <call_remote>")
	_rpc_test_remote_unreliable.rpc("HELLO WORLD - UNRELIABLE <Sent by the Client> <call_remote>")

	# _rpc_test_local_authority.rpc("HELLO WORLD - AUTHORITY <Sent by the Client> <call_local>")
	_rpc_test_local_reliable.rpc("HELLO WORLD - RELIABLE <Sent by the Client> <call_local>")
	_rpc_test_local_unreliable_ordered.rpc("HELLO WORLD - UNRELIABLE ORDERED <Sent by the Client> <call_local>")
	_rpc_test_local_unreliable.rpc("HELLO WORLD - UNRELIABLE <Sent by the Client> <call_local>")

	DebuggingHelper.debug("Execute Once <Just Client>", CLASS_NAME)
	once_execute = true

# just server
@rpc("authority", "call_remote", "reliable")
func _rpc_test_remote_authority(message: String) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	DebuggingHelper.debug("TEST rpc_test_reliable %s" % [message], CLASS_NAME)

@rpc("authority", "call_local", "reliable")
func _rpc_test_local_authority(message: String) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	DebuggingHelper.debug("TEST rpc_test_reliable %s" % [message], CLASS_NAME)

# any peer (just remote)
@rpc("any_peer", "call_remote", "reliable")
func _rpc_test_remote_reliable(message: String) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	DebuggingHelper.debug("TEST rpc_test_reliable %s" % [message], CLASS_NAME)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rpc_test_remote_unreliable_ordered(message: String) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	DebuggingHelper.debug("TEST rpc_test_unreliable_ordered %s" % [message], CLASS_NAME)

@rpc("any_peer", "call_remote", "unreliable")
func _rpc_test_remote_unreliable(message: String) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	DebuggingHelper.debug("TEST rpc_test_unreliable %s" % [message], CLASS_NAME)

# any peer (call local too)
@rpc("any_peer", "call_local", "reliable")
func _rpc_test_local_reliable(message: String) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	DebuggingHelper.debug("TEST rpc_test_reliable %s" % [message], CLASS_NAME)

@rpc("any_peer", "call_local", "unreliable_ordered")
func _rpc_test_local_unreliable_ordered(message: String) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	DebuggingHelper.debug("TEST rpc_test_unreliable_ordered %s" % [message], CLASS_NAME)

@rpc("any_peer", "call_local", "unreliable")
func _rpc_test_local_unreliable(message: String) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	DebuggingHelper.debug("TEST rpc_test_unreliable %s" % [message], CLASS_NAME)
