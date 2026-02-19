class_name LANDetector_Client extends LANDetector

const HANDSHAKE_TIMEOUT = 5100 # Wait 5.1 seconds before giving up on handshake (2 frames)
const BROADCAST_INTERVAL = 2500 # Transmit search packet every 2.5 seconds

var search_timeout = 0
var handshake_timeout = 0

enum BStage {
	Searching,
	Authorizing,
	Handshake,
	Complete
}

var b_peer:PacketPeerUDP = null

func is_server() -> bool:
	return false

func _init() -> void:
	broadcaster_on()

func _process(_delta: float) -> void:
	super._process(_delta) # poll the current peer
	poll_remote_broadcast()

func broadcaster_on():
	if b_peer != null: return
	b_peer = PacketPeerUDP.new()
	while !b_peer.is_bound():
		b_peer.bind(randi_range(20000, 60000))

	b_peer.set_broadcast_enabled(true)
	b_peer.set_dest_address("255.255.255.255", PORT)

func broadcaster_off():
	if b_peer == null: return
	b_peer.close()
	b_peer = null


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
			b_peer.put_packet(data)
			stage = BStage.Authorizing
		BStage.Authorizing:
			var count = b_peer.get_available_packet_count()
			if !count:
				stage = BStage.Searching
				return

			var dest = b_peer.get_var()
			if dest == null || !(dest is Dictionary):
				stage = BStage.Searching
				if debug_mode: print("Error " + str(b_peer.get_packet_error()) + ": Invalid response")
				return
			var address = dest.get("ip")
			var port = dest.get("p")
			if debug_mode: print("connecting to " + address + ":" + str(port))
			new_peer = PacketPeerUDP.new()
			new_peer.set_dest_address(address, port)
			while new_peer.bind(randi_range(20000, 60000)) != OK:
				pass
			new_peer.put_var( static_auth_code )
			stage = BStage.Handshake
			handshake_timeout = Time.get_ticks_msec()
		BStage.Handshake:
			var count = new_peer.get_available_packet_count()
			if !count:
				if Time.get_ticks_msec() - handshake_timeout > HANDSHAKE_TIMEOUT:
					stage = BStage.Searching
				return
			var auth = new_peer.get_var()
			if auth != static_auth_code:
				stage = BStage.Searching
				return
			replace_peer(new_peer)
			if debug_mode: print("connected successfully")
			stage = BStage.Complete
		BStage.Complete:
			if !peer_connected():
				stage = BStage.Searching
			else:
				broadcaster_off()

func poll_remote_broadcast():
	if b_peer != null:
		if Time.get_ticks_msec() - search_timeout > BROADCAST_INTERVAL:
			find_server() # Search for a server
			search_timeout = Time.get_ticks_msec()
	elif !peer_connected():
		broadcaster_on()
