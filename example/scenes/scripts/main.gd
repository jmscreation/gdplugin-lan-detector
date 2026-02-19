extends MarginContainer

func _on_serve_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/server.tscn")


func _on_search_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/client.tscn")
