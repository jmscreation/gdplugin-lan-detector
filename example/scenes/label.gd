extends Label

func _on_message_received(msg:LANDATA.TYPE, data:Variant):
	match msg:
		LANDATA.TYPE.REPLY:
			if data is String:
				text = data
