class_name LANDetector_Client extends LANDetector


var timeout = 0

enum BStage {
	Searching,
	Authorizing,
	Handshake,
	Complete
}

var beer:PacketPeerUDP = PacketPeerUDP.new()

func is_server() -> bool:
	return false

func _init() -> void:
	while !beer.is_bound():
		beer.bind(randi_range(20000, 60000))

	beer.set_broadcast_enabled(true)
	beer.set_dest_address("255.255.255.255", 4599)

func _process(_delta: float) -> void:
	super._process(_delta) # poll the current peer
	poll_remote_broadcast()


var stage:BStage = BStage.Searching
var new_peer:PacketPeerUDP = null
func find_server():
	match stage:
		BStage.Searching:
			if new_peer != null:
				new_peer.close()
				new_peer = null
			var data = PackedByteArray()
			data.resize(8)
			data.encode_u64(0, static_broadcast_code)
			beer.put_packet(data)
			stage = BStage.Authorizing
		BStage.Authorizing:
			var count = beer.get_available_packet_count()
			if !count:
				stage = BStage.Searching
				return

			var dest = beer.get_var()
			if dest == null || !(dest is Dictionary):
				stage = BStage.Searching
				if debug_mode: print("Error " + str(beer.get_packet_error()) + ": Invalid response")
				return
			var address = dest.get("ip")
			var port = dest.get("p")
			if debug_mode: print("connecting to " + address + ":" + str(port))
			new_peer = PacketPeerUDP.new()
			new_peer.set_dest_address(address, port)
			while !new_peer.is_bound():
				new_peer.bind(randi_range(20000, 60000))
			new_peer.put_var( static_auth_code )
			stage = BStage.Handshake
		BStage.Handshake:
			var count = new_peer.get_available_packet_count()
			if !count:
				stage = BStage.Searching
				return
			var auth = new_peer.get_var()
			if auth != 1024:
				stage = BStage.Searching
				return
			if debug_mode: print("connected successfully")
			replace_peer(new_peer)
			stage = BStage.Complete
		BStage.Complete:
			if !peer_connected():
				stage = BStage.Searching

func poll_remote_broadcast():
	if Time.get_ticks_msec() - timeout > 3000:
		find_server() # Search for a server automatically every 3 seconds
		timeout = Time.get_ticks_msec()
