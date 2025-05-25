@tool
extends EditorPlugin


func _enable_plugin() -> void:
	add_autoload_singleton("Logger", "res://addons/logger/logger.tscn")


func _disable_plugin() -> void:
	remove_autoload_singleton("Logger")
