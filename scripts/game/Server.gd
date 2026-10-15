class_name Server extends Control

static var CLASS_NAME: String = (Server as GDScript).get_global_name()

@onready var client_id_lineedit: LineEdit = %ClientIDLineEdit

@onready var json_server_offer_textedit: TextEdit = %JSONServerOfferTextEdit
@onready var json_client_answer_textedit: TextEdit = %JSONClientAnswerTextEdit

@onready var chat_message_textedit: TextEdit = %ChatMessageTextEdit
@onready var chat_input_lineedit: LineEdit = %ChatInputLineEdit
@onready var chat_send_button: Button = %ChatSendMessageButton

@onready var apply_button: Button = %ApplyButton

@onready var webrtc_server_manager: WebRTC_ServerManager = get_node("/root/Network/WebRTC_ServerManager")
@onready var chat_rpc: ChatRPC = get_node("/root/Network/ChatRPC")

func _ready() -> void:
	webrtc_server_manager.initialize()

	webrtc_server_manager.add_ice_stun("stun:stun.l.google.com:19302")
	webrtc_server_manager.add_ice_stun("stun:stun1.l.google.com:19302")
	webrtc_server_manager.add_ice_stun("stun:stun.cloudflare.com:3478")

	webrtc_server_manager.add_ice_turn({
		"urls": [
			"turn:your_turn_server:3478"
		],
		"username": "username",
		"credential": "credential"
	})

	webrtc_server_manager.add_ice_turn({
		"urls": [
			"turn:backup_turn_server:3478"
		],
		"username": "user_b",
		"credential": "pass_b"
	})

	webrtc_server_manager.offer_completed.connect(_on_offer_completed)
	webrtc_server_manager.answer_completed.connect(_on_answer_completed)

	webrtc_server_manager.client_connected.connect(_on_client_connected)
	webrtc_server_manager.client_disconnected.connect(_on_client_disconnected)

	chat_rpc.received_message.connect(_on_received_message)

func _process(_delta: float) -> void:
	pass

#region UI Behavior

func _append_chat(message: String, customer: String="System") -> void:
	chat_message_textedit.text += "[%s] %s\n" % [customer, message]
	chat_message_textedit.scroll_vertical = (
		chat_message_textedit.get_line_count()
	)

#endregion

#region Callbacks

func _on_offer_completed(id: int) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	DebuggingHelper.debug("Offer Completed - Client ID <%s>" % [id], CLASS_NAME)

	json_server_offer_textedit.text = webrtc_server_manager.get_offer_output(id)

func _on_answer_completed(id: int) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	DebuggingHelper.debug("Answer Completed - Client ID <%s>" % [id], CLASS_NAME)

# ----------------------------------------------

func _on_client_connected(id: int) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	DebuggingHelper.debug("Client Connected - Client ID <%s>" % [id], CLASS_NAME)

	if multiplayer.is_server():
		chat_rpc.send_message.rpc("Client <%d> sucessfully connected to the server." % [id])

func _on_client_disconnected(id: int) -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])
	DebuggingHelper.debug("Client Disconnected - Client ID <%s>" % [id], CLASS_NAME)

	if multiplayer.is_server():
		chat_rpc.send_message.rpc("Client <%d> disconnected from server." % [id])

	webrtc_server_manager.destroy_client_id(id)

# ----------------------------------------------

func _on_create_offer_button_pressed() -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])

	var id := int(client_id_lineedit.text.strip_edges())

	webrtc_server_manager.create_offer(
		id
	)

	client_id_lineedit.text = "%s" % [id + 1]

func _on_apply_button_pressed() -> void:
	print(" - %s - %d" % [get_stack()[0]["function"], get_instance_id()])

	webrtc_server_manager.apply_answer(
		JSON.parse_string(
			json_client_answer_textedit.text
		)
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
