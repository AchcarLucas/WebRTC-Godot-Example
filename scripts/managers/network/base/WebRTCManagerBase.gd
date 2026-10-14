class_name WebRTCManagerBase extends Node

const ICE_CONFIG: Array[Dictionary] = [
	{
		"urls": [
			"stun:stun.l.google.com:19302",
		]
	}
]

var _ice_config:Array[Dictionary] = ICE_CONFIG.duplicate(true)
var _multiplayer :WebRTCMultiplayerPeer

signal offer_completed(id: int)
signal answer_completed(id: int)

signal client_connected(id: int)
signal client_disconnected(id: int)


func get_json_ice_servers() -> String:
	return JSON.stringify(_ice_config, "\t")

"""
	Exemple:
	{
		"urls": [
			"stun:your_stun_server:3478",
		]
	}
"""
func add_ice_stun(stun: String) -> void:
	if _ice_config.is_empty():
		_ice_config.append(
			{
				"urls": [

				]
			}
		)

	_ice_config[0]["urls"].append(stun)

"""
	Exemple:
	{
		"urls": [
			"turn:your_turn_server:3478"
		],
		"username": "username",
		"credential": "credential"
	}
"""
func add_ice_turn(turn: Dictionary) -> void:
	_ice_config.append(turn)