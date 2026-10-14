class_name WebRTC_ClientManager extends WebRTCManagerBase

static var CLASS_NAME: String = "WebRTC_ClientManager"

signal connected_to_server()
signal connection_failed()
signal server_disconnected()

class ClientMultiplayerExtended extends ClientMultiplayerBase.ClientMultiplayer:
	var answer_exported: bool = false
	var answer_output: String

	var offer_received: bool = false
	var offer_candidates_applied: bool = false

var _client: ClientMultiplayerExtended

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if 	not has_client() or \
		_client.peer == null:
		return

	var client: ClientMultiplayerExtended = _client
	var id = client.id
	var peer: WebRTCPeerConnection = client.peer

	_try_add_offer_candidates(
		id,
		peer
	)

	if  not client.sdp.is_empty() and \
		not client.answer_exported and \
		peer.get_gathering_state() \
			== WebRTCPeerConnection.GATHERING_STATE_COMPLETE:
			client.answer_output = JSON.stringify({
					"id": id,
					"type": "answer",
					"sdp": client.sdp,
					"candidates": client.candidates
				}, 
				"\t"
			)
			client.answer_exported = true
			answer_completed.emit(id)

func initialize(
	ice_config: Array[Dictionary] = []
) -> int:
	if not ice_config.is_empty():
		_ice_config = ice_config

	destroy()

	_client = ClientMultiplayerExtended.new()
	_client.peer = WebRTCPeerConnection.new()

	_multiplayer = WebRTCMultiplayerPeer.new()

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	return Error.OK

func create_answer(id: int) -> int:
	if id < 2:
		push_error("The ID must be greater than or equal to 2.")
		return Error.ERR_UNAUTHORIZED

	if 	_client.id != 0:
		push_error("There is already an open connection with ID <%d>" % [_client.id])
		return Error.ERR_ALREADY_EXISTS

	var error: Error = Error.OK

	_client.id = id

	DebuggingHelper.debug("iceServers %s" % [get_json_ice_servers()], CLASS_NAME)

	error = _client.peer.initialize(
		{
			"iceServers": _ice_config
		}
	)

	if error != OK:
		push_error("Peer connection initialization failed <%s>" % error_string(error))
		destroy_client()
		return Error.FAILED

	_client.peer.session_description_created.connect(
		_on_session_description_created.bind(id)
	)

	_client.peer.ice_candidate_created.connect(
		_on_ice_candidate_created.bind(id)
	)

	error = _multiplayer.create_client(id)

	if error != OK:
		push_error("Failed to create client <%s>" % error_string(error))
		return Error.ERR_CANT_CONNECT

	error = _multiplayer.add_peer(_client.peer, ClientMultiplayerBase.SERVER_ID)

	if error != OK:
		push_error("Adding the peer to the multiplayer session failed <%s>" % error_string(error))
		destroy_client()
		return Error.FAILED

	multiplayer.multiplayer_peer = _multiplayer

	DebuggingHelper.debug("Client created. Client ID <%d>" % [id], CLASS_NAME)

	return Error.OK

func apply_offer(
	parsed: Variant
) -> int:
	var error: Error = Error.OK

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("The parsed object is not of the dictionary type.")
		return Error.ERR_INVALID_DATA

	var id: int = int(parsed.get("id", 0))

	if not id:
		push_error("The offer does not have an <id> field")
		return Error.ERR_INVALID_PARAMETER

	if _client.offer_received:
		push_error("Offer already received")
		return Error.ERR_ALREADY_EXISTS

	if str(parsed.get("type", "")) != "offer":
		push_error("The offer is not of the type \"offer\".")
		return Error.FAILED

	var candidates = parsed.get("candidates", [])

	if typeof(candidates) != TYPE_ARRAY:
		push_error("The parsed object is not of the array type")
		return Error.ERR_INVALID_DATA

	var peer: WebRTCPeerConnection = _client.peer

	error = peer.set_remote_description(
		"offer",
		str(
			parsed.get("sdp", "")
		)
	)

	if error != OK:
		push_error("Error calling the set_remote_description method <%s>", error_string(error))
		return Error.FAILED

	"""
		Recebemos com sucesso os candidates do offer do servidor
	"""
	_client.pending_remote_candidates = candidates
	_client.offer_received = true

	return Error.OK

func has_client() -> bool:
	return _client != null

func get_answer_output() -> String:
	if 	not has_client() or \
		not _client.answer_exported:
		return String()

	return _client.answer_output

func destroy_client() -> void:
	if not has_client():
		return

	if _multiplayer.has_peer(ClientMultiplayerBase.SERVER_ID):
		_multiplayer.remove_peer(ClientMultiplayerBase.SERVER_ID)

	if _client.peer != null:
		_client.peer.close()
		_client.peer = null

	_client = null

func destroy() -> void:
	if _multiplayer == null:
		return

	for peer_id in _multiplayer.get_peers():
		_multiplayer.remove_peer(peer_id)

	destroy_client()

	_multiplayer.close()
	_multiplayer = null

func _try_add_offer_candidates(
	id: int,
	peer: WebRTCPeerConnection
) -> void:
	if not _client.offer_received:
		return

	if _client.offer_candidates_applied:
		return

	'''
	if peer.get_signaling_state() \
		!= WebRTCPeerConnection.SIGNALING_STATE_STABLE:
			return
	'''

	var signaling_state = peer.get_signaling_state()

	var signaling_ready := (
		signaling_state == WebRTCPeerConnection.SIGNALING_STATE_HAVE_REMOTE_OFFER or \
		(
			not _client.sdp.is_empty() and \
			signaling_state == WebRTCPeerConnection.SIGNALING_STATE_STABLE
		)
	)

	if not signaling_ready:
		return

	var candidates: Array = _client.pending_remote_candidates

	# verifica se candidates é vazio, isso evita loop infinito
	if candidates.is_empty():
		return

	for item in candidates:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		var error: Error = peer.add_ice_candidate(
			str(item.get("media", "")),
			int(item.get("index", 0)),
			str(item.get("candidate", ""))
		)

		if error != OK:
			push_warning(
				"Failed to apply ICE candidates %d: %s" % [id, error]
			)
		
		_client.offer_candidates_applied = true
		_client.pending_remote_candidates = []

	offer_completed.emit(id)

func _on_session_description_created(
	type: String,
	sdp: String,
	id: int
) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])

	if not _client:
		push_error("Client ID <%d> does not exist" % [id])
		return

	if  type != "answer":
		return

	var error: Error = Error.OK

	error = _client.peer.set_local_description(type, sdp)

	if error != OK:
		push_error("Failed to execute set_local_description method <%s>" % error_string(error))
		return

	# Guardamos o SDP do sinal. Não existe get_local_description().
	_client.sdp = sdp

func _on_ice_candidate_created(
	media: String,
	index: int,
	candidate: String,
	id: int
) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])

	if not _client:
		push_error("Client ID <%d> does not exist" % [id])
		return

	_client.candidates.append({
			"media": media,
			"index": index,
			"candidate": candidate
		}
	)

# emit server and clients
func _on_peer_connected(id: int) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	client_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	client_disconnected.emit(id)

# emit clients only
func _on_connected_to_server() -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	_client.connected = true
	connected_to_server.emit()

func _on_connection_failed() -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	_client.connected = false
	connection_failed.emit()

func _on_server_disconnected() -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	_client.connected = false
	server_disconnected.emit()
