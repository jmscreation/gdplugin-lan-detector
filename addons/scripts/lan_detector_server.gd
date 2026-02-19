class_name LANDetector_Server extends LANDetector


var new_peer:PacketPeerUDP = null
var b_peer:PacketPeerUDP = PacketPeerUDP.new()


func is_server() -> bool:
	return true

func _init() -> void:
	b_peer.bind(4599)

func _process(_delta: float) -> void:
	super._process(_delta) # poll the current peer
	if !peer_connected():
		poll_broadcast_peers()
		poll_new_peers()


func poll_broadcast_peers():
	var count = b_peer.get_available_packet_count()
	for i in range(count):
		var packet = b_peer.get_packet() # simply get the packet
		var ip = b_peer.get_packet_ip()
		var port = b_peer.get_packet_port()
		if packet.decode_u64(0) == static_broadcast_code:
			if debug_mode: print("incoming Connection Request: " + ip + ":" + str(port) )
			b_peer.set_dest_address(ip, port)
			
			var addresses:Array
			var my_network_ip = ""
			var my_network_port

			for address in IP.get_local_addresses():
				if !address.contains(":") && address != "127.0.0.1":
					addresses.append(address)

			var b_parts = ip.split(".")
			for address in addresses:
				var a_parts = address.split(".")
				if a_parts[0] != b_parts[0]:
					continue
				if a_parts[1] != b_parts[1]:
					continue
				my_network_ip = address

			if my_network_ip != "":
				if debug_mode: print("connection attempt from " + ip)
				new_peer = PacketPeerUDP.new()
				while !new_peer.is_bound():
					my_network_port = randi_range(12000, 15000)
					new_peer.bind(my_network_port, my_network_ip)
				new_peer.set_dest_address(ip, port) # return to sender
				b_peer.put_var({ "ip" = my_network_ip , "p" = my_network_port })


func poll_new_peers():
	if new_peer != null:
		if new_peer.get_available_packet_count():
			var code = new_peer.get_var()
			var ip = new_peer.get_packet_ip()
			var port = new_peer.get_packet_port()
			if debug_mode: print("peer connected from " + ip + ":" + str(port))
			if static_auth_code != code:
				if debug_mode: print("peer failed authorization")
				new_peer.close()
				new_peer = null
			else:
				if debug_mode: print("peer authorized successfully!")
				new_peer.set_dest_address(ip,port)
				new_peer.put_var(1024) # magic code
				replace_peer(new_peer)
				new_peer = null
