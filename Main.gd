extends Control


const PORT := 5678

var server: WebSocketServer
var peers := []

onready var label := $Label as Label


func _ready() -> void:
	server = WebSocketServer.new()
	labelprint("Starting server...")
	var error := server.listen(PORT)
	if error:
		labelprint("Error!")
		return
	labelprint("Listening on %s:%d" % [server.bind_ip, PORT])
	error = server.connect("client_close_request", self, "_on_server_client_close_request")
	assert(not error)
	error = server.connect("client_connected", self, "_on_server_client_connected")
	assert(not error)
	error = server.connect("client_disconnected", self, "_on_server_client_disconnected")
	assert(not error)
	error = server.connect("data_received", self, "_on_server_data_received")
	assert(not error)

	for button in $Buttons.get_children():
		error = button.connect("pressed", self, "_on_button_pressed", [button.text])
		assert(not error)


func _process(_delta: float) -> void:
	if server.is_listening():
		server.poll()


func labelprint(text: String) -> void:
	print(text)
	label.text = "%s\n%s" % [text, label.text]


func _on_server_client_close_request(id: int, code: int, reason: String) -> void:
	labelprint("Received client close request: %d %d %s" % [id, code, reason])


func _on_server_client_connected(id: int, protocol: String) -> void:
	labelprint("Client connected: %d %s" % [id, protocol])
	peers.append(id)
	server.get_peer(id).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)


func _on_server_client_disconnected(id: int, was_clean_close: bool) -> void:
	labelprint("Client disconnected: %d %s" % [id, was_clean_close])
	peers.erase(id)


func _on_server_data_received(id: int) -> void:
	labelprint("Data received: %d" % id)


func _on_button_pressed(command: String) -> void:
	for id in peers:
		labelprint("Sending command to peer %d: %s" % [id, command])
		var error := server.get_peer(id).put_packet(command.to_ascii())
		if error:
			labelprint("Error sending packet")
