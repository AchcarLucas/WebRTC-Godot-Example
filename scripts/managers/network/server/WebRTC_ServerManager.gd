class_name WebRTC_ServerManager extends WebRTCManagerBase

static var CLASS_NAME: String = "WebRTC_ServerManager"

class ClientMultiplayerExtended extends ClientMultiplayerBase.ClientMultiplayer:
	var offer_exported: bool = false
	var offer_output: String

	var answer_received: bool = false
	var answer_candidates_applied: bool = false

var _clients: Dictionary = {}

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	"""
		Verifica todos os clientes e se o offer foi finalizado
		se sim, salva no offer_output do cliente e faça um emit
		para avisar quem esta usando o manager
	"""
	for id in _clients:
		var client: ClientMultiplayerExtended = _clients[id]
		var peer: WebRTCPeerConnection = client.peer

		_try_add_answer_candidates(
			id,
			peer
		)

		if  not client.sdp.is_empty() and \
			not client.offer_exported and \
			peer.get_gathering_state() \
				== WebRTCPeerConnection.GATHERING_STATE_COMPLETE:
				client.offer_output = JSON.stringify({
						"id": id,
						"type": "offer",
						"sdp": client.sdp,
						"candidates": client.candidates
					}, 
					"\t"
				)
				client.offer_exported = true
				offer_completed.emit(id)

func initialize(
	ice_config: Array[Dictionary] = []
) -> int:
	if not ice_config.is_empty():
		_ice_config = ice_config

	destroy()

	var error: Error = Error.OK

	_multiplayer = WebRTCMultiplayerPeer.new()

	error = _multiplayer.create_server()

	if error != OK:
		push_error("Failed to create server <%s>" % error_string(error))
		return Error.ERR_CANT_CONNECT

	multiplayer.multiplayer_peer = _multiplayer

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	DebuggingHelper.debug("Server created. Server ID <%d>" % [ClientMultiplayerBase.SERVER_ID], CLASS_NAME)

	return Error.OK

func create_offer(id: int) -> int:
	if id < 2:
		push_error("The ID must be greater than or equal to 2.")
		return Error.ERR_UNAUTHORIZED

	if get_client_id(id) != null:
		push_error("A connection for ID <%d> already exists." % [id])
		return Error.ERR_ALREADY_EXISTS

	var error: Error = Error.OK

	_clients[id] = ClientMultiplayerExtended.new()

	_clients[id].id = id
	_clients[id].peer = WebRTCPeerConnection.new()

	DebuggingHelper.debug("iceServers %s" % [get_json_ice_servers()], CLASS_NAME)

	error = _clients[id].peer.initialize(
		{
			"iceServers": _ice_config
		}
	)

	if error != OK:
		push_error("Peer connection initialization failed <%s>" % error_string(error))
		destroy_client_id(id)
		return Error.FAILED

	_clients[id].peer.session_description_created.connect(
		_on_session_description_created.bind(id)
	)

	_clients[id].peer.ice_candidate_created.connect(
		_on_ice_candidate_created.bind(id)
	)

	error = _multiplayer.add_peer(_clients[id].peer, id)

	if error != OK:
		push_error("Adding the peer to the multiplayer session failed <%s>" % error_string(error))
		destroy_client_id(id)
		return Error.FAILED

	error = _clients[id].peer.create_offer()

	if error != OK:
		push_error("Failed to create the offer <%s>" % error_string(error))
		destroy_client_id(id)
		return Error.FAILED

	return Error.OK

func apply_answer(
	parsed: Variant
) -> int:
	var error: Error = Error.OK

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("The parsed object is not of the dictionary type.")
		return Error.ERR_INVALID_DATA

	var id: int = int(parsed.get("id", 0))

	if not id:
		push_error("The answer does not have an <id> field")
		return Error.ERR_INVALID_PARAMETER

	if _clients[id].answer_received:
		push_error("Answer already received")
		return Error.ERR_ALREADY_EXISTS

	if str(parsed.get("type", "")) != "answer":
		push_error("The answer is not of the type \"answer\".")
		return Error.FAILED

	var candidates = parsed.get("candidates", [])

	if typeof(candidates) != TYPE_ARRAY:
		push_error("The parsed object is not of the array type")
		return Error.ERR_INVALID_DATA

	var peer: WebRTCPeerConnection = _clients[id].peer

	error = peer.set_remote_description(
		"answer",
		str(
			parsed.get("sdp", "")
		)
	)

	if error != OK:
		push_error("Error calling the set_remote_description method <%s>", error_string(error))
		return Error.FAILED

	"""
		Recebemos com sucesso os candidates do answer do client
	"""
	_clients[id].pending_remote_candidates = candidates
	_clients[id].answer_received = true

	return Error.OK

func get_client_id(id: int) -> ClientMultiplayerExtended:
	if _clients.has(id):
		return _clients[id]
	return null

func get_clients() -> Dictionary:
	return _clients

func get_offer_output(id: int) -> String:
	if 	not _clients.has(id) or \
		not _clients[id].offer_exported:
		return String()

	return _clients[id].offer_output

func destroy_client_id(id: int) -> void:
	if _multiplayer.has_peer(id):
		_multiplayer.remove_peer(id)

	if _clients[id].peer != null:
		_clients[id].peer.close()
		_clients[id].peer = null

	_clients.erase(id)

func destroy_clients() -> void:
	for client_id in _clients:
		destroy_client_id(client_id)

	_clients.clear()

func destroy() -> void:
	if _multiplayer == null:
		return

	for peer_id in _multiplayer.get_peers():
		_multiplayer.remove_peer(peer_id)

	destroy_clients()

	_multiplayer.close()
	_multiplayer = null

func get_amount_clients_connected() -> int:
	var amount: int = 0
	for id in _clients:
		var client: ClientMultiplayerExtended = _clients[id]
		if client.connected:
			amount += 1
	return amount

func get_amount_clients() -> int:
	return len(_clients)

func _try_add_answer_candidates(
	id: int,
	peer: WebRTCPeerConnection
) -> void:
	if not _clients[id].answer_received:
		return

	if _clients[id].answer_candidates_applied:
		return

	if peer.get_signaling_state() \
		!= WebRTCPeerConnection.SIGNALING_STATE_STABLE:
			return

	var candidates: Array = _clients[id].pending_remote_candidates

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
		
		_clients[id].answer_candidates_applied = true
		_clients[id].pending_remote_candidates = []

	answer_completed.emit(id)

func _on_session_description_created(
	type: String,
	sdp: String,
	id: int
) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])

	if not _clients.has(id):
		push_error("Client ID <%d> does not exist" % [id])
		return

	if  type != "offer":
		return

	var error: Error = Error.OK

	error = _clients[id].peer.set_local_description(type, sdp)

	if error != OK:
		push_error("Failed to execute set_local_description method <%s>" % error_string(error))
		return

	# Guardamos o SDP do sinal. Não existe get_local_description().
	_clients[id].sdp = sdp

func _on_ice_candidate_created(
	media: String,
	index: int,
	candidate: String,
	id: int
) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])

	if not _clients.has(id):
		push_error("Client ID <%d> does not exist" % [id])
		return

	_clients[id].candidates.append({
			"media": media,
			"index": index,
			"candidate": candidate
		}
	)

func _on_peer_connected(id: int) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])

	_clients[id].connected = true
	client_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])

	_clients[id].connected = false
	client_disconnected.emit(id)
