class_name ChatRPC extends Node

signal received_message(sender_id: int, messsage: String)

@rpc("any_peer", "call_local", "reliable")
func send_message(message: String) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	received_message.emit(sender_id, message)
