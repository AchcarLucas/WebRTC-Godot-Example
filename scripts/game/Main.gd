extends Control

const SERVER_SCENE_PATH: String = "res://scenes/game/ServerScene.tscn"
const CLIENT_SCENE_PATH: String = "res://scenes/game/ClientScene.tscn"

const WEBRTC_SERVER_MANAGER_SCENE_PATH: String = "res://scenes/managers/network/server/WebRTC_ServerManager.tscn"
const WEBRTC_CLIENT_MANAGER_SCENE_PATH: String = "res://scenes/managers/network/client/WebRTC_ClientManager.tscn"

const TEST_RPC_SCENE_PATH: String = "res://scenes/managers/network/rpc/test/TestRPC.tscn"
const CHAT_RPC_SCENE_PATH: String = "res://scenes/managers/network/rpc/chat/ChatRPC.tscn"

const SERVER_SCENE_LOADED = preload(SERVER_SCENE_PATH)
const CLIENT_SCENE_LOADED = preload(CLIENT_SCENE_PATH)

const WEBRTC_SERVER_MANAGER_SCENE_LOADED = preload(WEBRTC_SERVER_MANAGER_SCENE_PATH)
const WEBRTC_CLIENT_MANAGER_SCENE_LOADED = preload(WEBRTC_CLIENT_MANAGER_SCENE_PATH)

const TEST_RPC_SCENE_LOADED = preload(TEST_RPC_SCENE_PATH)
const CHAT_RPC_SCENE_LOADED = preload(CHAT_RPC_SCENE_PATH)

func _on_do_server_button_pressed() -> void:
	visible = false

	Network.packed_load(WEBRTC_SERVER_MANAGER_SCENE_LOADED)

	Network.packed_load(TEST_RPC_SCENE_LOADED)
	Network.packed_load(CHAT_RPC_SCENE_LOADED)

	get_parent().add_child(
		SERVER_SCENE_LOADED.instantiate()
	)

func _on_do_client_button_pressed() -> void:
	visible = false

	Network.packed_load(WEBRTC_CLIENT_MANAGER_SCENE_LOADED)

	Network.packed_load(TEST_RPC_SCENE_LOADED)
	Network.packed_load(CHAT_RPC_SCENE_LOADED)

	get_parent().add_child(
		CLIENT_SCENE_LOADED.instantiate()
	)
