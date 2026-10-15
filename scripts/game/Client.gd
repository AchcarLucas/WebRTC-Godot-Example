class_name Client extends Control

static var CLASS_NAME: String = (Client as GDScript).get_global_name()

@onready var json_server_offer_textedit: TextEdit = %JSONServerOfferTextEdit
@onready var json_client_answer_textedit: TextEdit = %JSONClientAnswerTextEdit

@onready var chat_message_textedit: TextEdit = %ChatMessageTextEdit
@onready var chat_input_lineedit: LineEdit = %ChatInputLineEdit
@onready var chat_send_button: Button = %ChatSendMessageButton

@onready var apply_button: Button = %ApplyButton

@onready var webrtc_client_manager: WebRTC_ClientManager = get_node("/root/Network/WebRTC_ClientManager")
@onready var chat_rpc: ChatRPC = get_node("/root/Network/ChatRPC")

func _ready() -> void:
	webrtc_client_manager.initialize()

	webrtc_client_manager.add_ice_stun("stun:stun.l.google.com:19302")
	webrtc_client_manager.add_ice_stun("stun:stun1.l.google.com:19302")
	webrtc_client_manager.add_ice_stun("stun:stun.cloudflare.com:3478")

	webrtc_client_manager.add_ice_turn({
		"urls": [
			"turn:your_turn_server:3478"
		],
		"username": "username",
		"credential": "credential"
	})

	webrtc_client_manager.add_ice_turn({
		"urls": [
			"turn:backup_turn_server:3478"
		],
		"username": "user_b",
		"credential": "pass_b"
	})

	webrtc_client_manager.offer_completed.connect(_on_offer_completed)
	webrtc_client_manager.answer_completed.connect(_on_answer_completed)

	webrtc_client_manager.client_connected.connect(_on_client_connected)
	webrtc_client_manager.client_disconnected.connect(_on_client_disconnected)

	webrtc_client_manager.connected_to_server.connect(_on_connected_to_server)
	webrtc_client_manager.connection_failed.connect(_on_connection_failed)
	webrtc_client_manager.server_disconnected.connect(_on_server_disconnected)

	chat_rpc.received_message.connect(_on_received_message)

func _process(_delta: float) -> void:
	pass

#region UI Behavior

func _append_chat(message: String, customer: String="System") -> void:
	chat_message_textedit.text += "[%s] %s\n" % [customer, message]
	chat_message_textedit.scroll_vertical = (
		chat_message_textedit.get_line_count()
	)

func _ui_behavior_connected() -> void:
	chat_send_button.disabled = false
	apply_button.disabled = true
	chat_input_lineedit.editable = true

func _ui_behavior_disconnected() -> void:
	chat_send_button.disabled = true
	apply_button.disabled = false
	chat_input_lineedit.editable = false

#endregion

#region Callbacks

func _on_offer_completed(id: int) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	DebuggingHelper.debug("Offer Completed - Client ID <%s>" % [id], CLASS_NAME)

func _on_answer_completed(id: int) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	DebuggingHelper.debug("Answer Completed - Client ID <%s>" % [id], CLASS_NAME)

	json_client_answer_textedit.text = webrtc_client_manager.get_answer_output()

# ----------------------------------------------

func _on_client_connected(id: int) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	if id == ClientMultiplayerBase.SERVER_ID:
		DebuggingHelper.debug("Host Connected - Host ID <%s>" % [id], CLASS_NAME)
	else:
		DebuggingHelper.debug("Client Connected - Client ID <%s>" % [id], CLASS_NAME)

func _on_client_disconnected(id: int) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	if id == ClientMultiplayerBase.SERVER_ID:
		DebuggingHelper.debug("Host Disconnected - Host ID <%s>" % [id], CLASS_NAME)
	else:
		DebuggingHelper.debug("Client Disconnected - Client ID <%s>" % [id], CLASS_NAME)

# ----------------------------------------------

func _on_connected_to_server() -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	DebuggingHelper.debug("Client successfully connected to the host server.", CLASS_NAME)

	_append_chat("You have been connected.")

func _on_connection_failed() -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	DebuggingHelper.debug("Failed to connect to the host server.", CLASS_NAME)

	_append_chat("Failed to connect to the host server.")

func _on_server_disconnected() -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	DebuggingHelper.debug("The server host was disconnected.", CLASS_NAME)

	_append_chat("The server host was disconnected.")

# ----------------------------------------------

func _on_apply_button_pressed() -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])

	var parsed: Variant = JSON.parse_string(
		json_server_offer_textedit.text
	)

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("The JSON offer is invalid.")
		return

	var id: int = int(parsed.get("id", 0))

	webrtc_client_manager.create_answer(id)

	webrtc_client_manager.apply_offer(
		parsed
	)

func _on_chat_send_message_button_pressed() -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])

	var message: String = chat_input_lineedit.text.erase(0, 0)

	if message.is_empty():
		return

	chat_rpc.send_message.rpc(message)

func _on_received_message(sender_id: int, message: String) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	_append_chat(message, "<%d>" % [sender_id])

#endregion
