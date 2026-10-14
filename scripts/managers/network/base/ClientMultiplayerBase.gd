class_name ClientMultiplayerBase extends RefCounted

static var CLASS_NAME: String = (ClientMultiplayerBase as GDScript).get_global_name()

const SERVER_ID: int = 1

class ClientMultiplayer extends RefCounted:
	var id: int

	var peer: WebRTCPeerConnection

	var sdp: String
	var candidates: Array = []
	var pending_remote_candidates: Array = []

	var connected: bool = false

