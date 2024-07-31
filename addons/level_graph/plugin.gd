@tool
extends EditorPlugin

# Scripts
const GraphEditContainerScn = preload("res://addons/level_graph/editor/graph_edit_container.tscn")
const GraphEditContainer = preload("res://addons/level_graph/editor/graph_edit_container.gd")
const LevelGraphInterface := preload("res://addons/level_graph/core/level_graph_interface.gd")
const Exit := preload("res://addons/level_graph/nodes/exit.gd")
const ExitIcon := preload("res://addons/level_graph/assets/exit-svgrepo-com.svg")

const ConnectionData := preload("res://addons/level_graph/core/connection_data.gd")
const EditorData := preload("res://addons/level_graph/core/editor_data.gd")
const LevelData := preload("res://addons/level_graph/core/level_data.gd")

const LevelGraphEnginePath := "res://addons/level_graph/core/level_graph_interface.gd"

# Constants
const EXIT_CLASS_NAME = "Exit"

var graph_editor_container: GraphEditContainer

func _enable_plugin() -> void:
	add_autoload_singleton("LevelGraph", LevelGraphEnginePath)

func _disable_plugin() -> void:
	remove_autoload_singleton("LevelGraph")
	

func _enter_tree() -> void:
	if not ProjectSettings.has_setting("level_graph/general/root_directory"):
		ProjectSettings.set_setting("level_graph/general/root_directory", "res://")
		ProjectSettings.set_initial_value("level_graph/general/root_directory", "res://")
	if not ProjectSettings.has_setting("level_graph/general/group_levels"):
		ProjectSettings.set_setting("level_graph/general/group_levels", false)
		ProjectSettings.set_initial_value("level_graph/general/group_levels", false)
	if not ProjectSettings.has_setting("level_graph/general/auto_refresh_levels"):
		ProjectSettings.set_setting("level_graph/general/auto_refresh_levels", false)
		ProjectSettings.set_initial_value("level_graph/general/auto_refresh_levels", false)
	
	if not ProjectSettings.has_setting("level_graph/runtime/load_level_data"):
		ProjectSettings.set_setting("level_graph/runtime/load_level_data", false)
		ProjectSettings.set_initial_value("level_graph/runtime/load_level_data", false)
	if not ProjectSettings.has_setting("level_graph/runtime/cache_level_data"):
		ProjectSettings.set_setting("level_graph/runtime/cache_level_data", false)
		ProjectSettings.set_initial_value("level_graph/runtime/cache_level_data", false)
	
	if not ProjectSettings.has_setting("level_graph/data/connections"):
		ProjectSettings.set_setting("level_graph/data/connections", ConnectionData.empty())
	if not ProjectSettings.has_setting("level_graph/data/_editor"):
		ProjectSettings.set_setting("level_graph/data/_editor", EditorData.empty())
	if not ProjectSettings.has_setting("level_graph/data/levels_cache"):
		ProjectSettings.set_setting("level_graph/data/levels_cache", LevelData.empty())
	ProjectSettings.save()
	
	ProjectSettings.add_property_info({
		"name": "level_graph/general/root_directory",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_DIR,
		"hint_string": ""
	})
	ProjectSettings.set_as_basic("level_graph/general/group_levels", true)
	ProjectSettings.set_as_basic("level_graph/general/root_directory", true)
	ProjectSettings.set_as_basic("level_graph/general/auto_refresh_levels", true)
	ProjectSettings.set_as_internal("level_graph/data/connections", true)
	ProjectSettings.set_as_internal("level_graph/data/levels_cache", true)
	ProjectSettings.set_as_internal("level_graph/data/_editor", true)
	add_custom_type(EXIT_CLASS_NAME, "Area2D", Exit, ExitIcon)
	
	graph_editor_container = GraphEditContainerScn.instantiate()
	
	EditorInterface.get_editor_main_screen().add_child(graph_editor_container)
	graph_editor_container.hide()


func _ready():
	await get_tree().process_frame
	var level_graph_interface := LevelGraphInterface.get_singleton(self)
	graph_editor_container.update_data(level_graph_interface.connection_data, level_graph_interface.editor_data, level_graph_interface.level_data)
	
	graph_editor_container.connection_updated.connect(level_graph_interface.update_connection_data)
	graph_editor_container.editor_updated.connect(level_graph_interface.update_editor_data)
	
	scene_changed.connect(func(node: Node):
		if node and graph_editor_container.visible:
			graph_editor_container.on_scene_active(node.scene_file_path)
	)

func _exit_tree() -> void:
	remove_custom_type(EXIT_CLASS_NAME)
	graph_editor_container.queue_free()

func _apply_changes() -> void:
	if not ProjectSettings.get_setting("level_graph/general/auto_refresh_levels", false):
		return
	await get_tree().process_frame
	var level_graph_interface := LevelGraphInterface.get_singleton(self)
	level_graph_interface.load_level_data()
	graph_editor_container.update_data(level_graph_interface.connection_data, level_graph_interface.editor_data, level_graph_interface.level_data)

# Main screen plugin
func _has_main_screen() -> bool:
	return true

func _get_plugin_icon() -> Texture2D:
	return preload("res://addons/level_graph/assets/map-1-svgrepo-com.svg")

func _get_plugin_name() -> String:
	return "Level"

func _make_visible(visible: bool) -> void:
	graph_editor_container.visible = visible
