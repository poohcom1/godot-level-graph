extends EditorExportPlugin

const LevelGraphInterface := preload("res://addons/level_graph/core/level_graph_interface.gd")

const ConnectionData := preload("res://addons/level_graph/core/connection_data.gd")
const LevelData := preload("res://addons/level_graph/core/level_data.gd")

func _get_name() -> String:
	return "Level Graph"

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	var config_override := ConfigFile.new()

	print_rich("[Level Graph][color=white] Caching scene paths...")
	
	var connection_data := ConnectionData.new()
	connection_data.deserialize(ProjectSettings.get_setting("level_graph/data/connections", []))
	connection_data.convert_to_export()
	config_override.set_value("level_graph", "data/connections", connection_data.serialize())
	
	var level_data := LevelGraphInterface.generate_level_data()
	level_data.convert_to_export()
	config_override.set_value("level_graph", "data/levels_cache", level_data.serialize())

	add_file("res://override.cfg", config_override.encode_to_text().to_utf8_buffer(), false)
