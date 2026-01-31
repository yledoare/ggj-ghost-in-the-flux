extends Node

# Network configuration
const DEFAULT_PORT: int = 7777
const MAX_PLAYERS: int = 8

# Server info for listing
var server_name: String = "Ghost Server"
var available_servers: Array = []

# Player info
var players: Dictionary = {}  # peer_id -> player_data

signal player_connected(peer_id: int, player_data: Dictionary)
signal player_disconnected(peer_id: int)
signal connection_succeeded()
signal connection_failed()
signal server_created()
signal server_list_updated()

func _ready():
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# ============ HOST FUNCTIONS ============

func create_server(port: int = DEFAULT_PORT, name: String = "Ghost Server") -> Error:
	server_name = name
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS)
	
	if error != OK:
		push_error("Failed to create server: " + str(error))
		return error
	
	multiplayer.multiplayer_peer = peer
	
	# Add host as player
	var host_id = 1
	players[host_id] = {
		"id": host_id,
		"name": "Host",
		"is_host": true
	}
	
	print("Server created on port ", port)
	server_created.emit()
	return OK

# ============ CLIENT FUNCTIONS ============

func join_server(address: String, port: int = DEFAULT_PORT) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	
	if error != OK:
		push_error("Failed to connect to server: " + str(error))
		return error
	
	multiplayer.multiplayer_peer = peer
	print("Connecting to ", address, ":", port)
	return OK

func disconnect_from_server():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	players.clear()

# ============ SIGNAL HANDLERS ============

func _on_peer_connected(id: int):
	print("Peer connected: ", id)
	# If we are the server, register this player
	if multiplayer.is_server():
		_register_player(id)

func _on_peer_disconnected(id: int):
	print("Peer disconnected: ", id)
	if players.has(id):
		players.erase(id)
		player_disconnected.emit(id)

func _on_connected_to_server():
	print("Connected to server!")
	var my_id = multiplayer.get_unique_id()
	players[my_id] = {
		"id": my_id,
		"name": "Player_" + str(my_id),
		"is_host": false
	}
	connection_succeeded.emit()

func _on_connection_failed():
	print("Connection failed!")
	multiplayer.multiplayer_peer = null
	connection_failed.emit()

func _on_server_disconnected():
	print("Server disconnected!")
	disconnect_from_server()

# ============ PLAYER MANAGEMENT ============

func _register_player(id: int):
	var player_data = {
		"id": id,
		"name": "Player_" + str(id),
		"is_host": false
	}
	players[id] = player_data
	player_connected.emit(id, player_data)
	
	# Sync player list to all clients
	_sync_player_list.rpc()

@rpc("authority", "call_local", "reliable")
func _sync_player_list():
	# This will be called on all clients to sync the player list
	pass

# ============ GAME START ============

func start_game():
	if multiplayer.is_server():
		_load_multiplayer_map.rpc()

@rpc("authority", "call_local", "reliable")
func _load_multiplayer_map():
	get_tree().change_scene_to_file("res://scenes/multiplayer/map_3d_multiplayer.tscn")

# ============ UTILITY ============

func is_host() -> bool:
	return multiplayer.is_server()

func get_my_id() -> int:
	return multiplayer.get_unique_id()

func get_player_count() -> int:
	return players.size()
