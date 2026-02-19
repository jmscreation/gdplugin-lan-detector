extends MarginContainer

func _on_peer_connected():
	$Server.send(LANDATA.TYPE.ECHO, "Echo From Server")

func _on_message_received(msg:LANDATA.TYPE, data:Variant):
	match msg:
		LANDATA.TYPE.ECHO:
			if data is String:
				$Server.send(LANDATA.TYPE.REPLY, data) # reply the echo back to peer
