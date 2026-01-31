extends Control

@onready var host_button: Button = $VBoxContainer/HostButton
@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var server_name_input: LineEdit = $VBoxContainer/ServerNameInput
@onready var ip_input: LineEdit = $VBoxContainer/IPInput
@onready var port_input: LineEdit = $VBoxContainer/PortInput
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var player_list: ItemList = $VBoxContainer/PlayerList
@onready var start_game_button: Button = $VBoxContainer/StartGameButton
@onready var disconnect_button: Button = $VBoxContainer/DisconnectButton

var network_manager: Node

func _ready():
	# Get or create network manager
	network_manager = get_node_or_null("/root/NetworkManager")
	if not network_manager:
		push_warning("NetworkManager autoload not found!")
		return
	
	# Connect signals
	network_manager.server_created.connect(_on_server_created)
	network_manager.connection_succeeded.connect(_on_connection_succeeded)
	network_manager.connection_failed.connect(_on_connection_failed)
	network_manager.player_connected.connect(_on_player_connected)
	network_manager.player_disconnected.connect(_on_player_disconnected)
	
	# Connect button signals
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	back_button.pressed.connect(_on_back_pressed)
	start_game_button.pressed.connect(_on_start_game_pressed)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	
	# Initial UI state
	_update_ui_state(false)
	status_label.text = "Enter server details and Host or Join"

func _update_ui_state(connected: bool):
	host_button.visible = not connected
	join_button.visible = not connected
	back_button.visible = not connected
	server_name_input.visible = not connected
	ip_input.visible = not connected
	port_input.visible = not connected
	
	player_list.visible = connected
	disconnect_button.visible = connected
	
	# Only host can start the game
	start_game_button.visible = connected and network_manager and network_manager.is_host()

func _refresh_player_list():
	player_list.clear()
	for player_id in network_manager.players:
		var player_data = network_manager.players[player_id]
		var suffix = " (Host)" if player_data.get("is_host", false) else ""
		player_list.add_item(player_data.get("name", "Unknown") + suffix)

# ============ BUTTON HANDLERS ============

func _on_host_pressed():
	var server_name = server_name_input.text if server_name_input.text != "" else "Ghost Server"
	var port = int(port_input.text) if port_input.text != "" else 7777
	
	status_label.text = "Creating server..."
	var error = network_manager.create_server(port, server_name)
	
	if error != OK:
		status_label.text = "Failed to create server: " + str(error)

func _on_join_pressed():
	var ip = ip_input.text if ip_input.text != "" else "127.0.0.1"
	var port = int(port_input.text) if port_input.text != "" else 7777
	
	status_label.text = "Connecting to " + ip + ":" + str(port) + "..."
	var error = network_manager.join_server(ip, port)
	
	if error != OK:
		status_label.text = "Failed to connect: " + str(error)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_start_game_pressed():
	if network_manager.is_host():
		status_label.text = "Starting game..."
		network_manager.start_game()

func _on_disconnect_pressed():
	network_manager.disconnect_from_server()
	_update_ui_state(false)
	status_label.text = "Disconnected"
	player_list.clear()

# ============ NETWORK SIGNAL HANDLERS ============

func _on_server_created():
	status_label.text = "Server created! Waiting for players..."
	_update_ui_state(true)
	_refresh_player_list()

func _on_connection_succeeded():
	status_label.text = "Connected to server!"
	_update_ui_state(true)
	_refresh_player_list()

func _on_connection_failed():
	status_label.text = "Connection failed! Check IP and port."
	_update_ui_state(false)

func _on_player_connected(peer_id: int, _player_data: Dictionary):
	status_label.text = "Player " + str(peer_id) + " connected!"
	_refresh_player_list()

func _on_player_disconnected(peer_id: int):
	status_label.text = "Player " + str(peer_id) + " disconnected!"
	_refresh_player_list()
