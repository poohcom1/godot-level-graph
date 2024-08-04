## Main singleton to interface with the addon

@tool
extends Node

const Self := preload("res://addons/level_graph/core/level_graph_interface.gd")
const ConnectionData := preload("res://addons/level_graph/core/connection_data.gd")
const EditorData := preload("res://addons/level_graph/core/editor_data.gd")
const LevelData := preload("res://addons/level_graph/core/level_data.gd")


const MAX_THREADS := 16

signal level_changed(from_scene: String, exit: int)

var connection_data := ConnectionData.new()

## Not loaded in runtime unless `load_level_data` true
## Exit data can already be obtained from the current scene, but this can be useful for getting data from other scenes.
var level_data := LevelData.new()
var editor_data := EditorData.new()

var _player: Node

#region API
const Orientation := LevelData.ExitOrientation
## When Orientation is Top/Bottom; direction when falling or jump
const VerticalDirection := LevelData.Direction

func set_player(node: Node):
	_player = node

func is_player(node: Node):
	return node == _player


func change_level(from_scene: Node, from_exit: int) -> void:
	var scene_uid = ResourceUID.id_to_text(ResourceLoader.get_resource_uid(from_scene.scene_file_path))
	level_changed.emit(scene_uid, from_exit)

func get_destination(from_level: String, from_exit: int) -> Dictionary:
	var dest := connection_data.get_destination(from_level, from_exit)
	return {
		"level": dest[0],
		"exit": dest[1]
	}

func get_exit_node_in_level(exit_id: int) -> Exit:
	var exits = Exit.get_exits(self)
	for exit in exits:
		if exit.id == exit_id:
			if not exit.is_exit_ready:
				await exit.exit_ready
			else:
				await get_tree().process_frame
			return exit
	return null

func get_exit_node_orientation(node: Exit) -> LevelData.ExitOrientation:
	if node is Exit:
		return (node as Exit).orientation
	return -1

func get_exit_node_direction(node: Exit) -> LevelData.Direction:
	if node is Exit:
		return (node as Exit).direction
	return -1

func get_exit_node_spawn_position(node: Exit) -> Vector2:
	if node is Exit:
		return (node as Exit).get_spawn_position()
	push_error("Exit node is not an exit")
	return Vector2.ZERO

#endregion

static func get_singleton(node: Node) -> Self:
	return node.get_node("/root/LevelGraph")

func _ready() -> void:
	if Engine.is_editor_hint():
		# In editor
		if ProjectSettings.get_setting("level_graph/general/auto_refresh_levels", false):
			load_graph_data()
			load_level_data()
		ProjectSettings.settings_changed.connect(_reload_level_data)
	else:
		# In runtime
		load_graph_data()
		if ProjectSettings.get_setting("level_graph/runtime/load_level_data", false):
			load_level_data()

		# Setup C# singleton
		if ClassDB.class_exists("CSharpScript"):
			var csharp_script: Script = load("res://addons/level_graph/core/LevelGraphInterface.cs")
			var csharp_instance: Node = csharp_script.new(self)
			add_child(csharp_instance)


func load_graph_data() -> void:
	connection_data.deserialize(ProjectSettings.get_setting("level_graph/data/connections", []))
	editor_data.deserialize(ProjectSettings.get_setting("level_graph/data/_editor", {}))


func update_connection_data(connection_data: ConnectionData) -> void:
	ProjectSettings.set_setting("level_graph/data/connections", connection_data.serialize())
	ProjectSettings.save()
	self.connection_data = connection_data

func update_editor_data(editor_data: EditorData) -> void:
	ProjectSettings.set_setting("level_graph/data/_editor", editor_data.serialize())
	ProjectSettings.save()
	self.editor_data = editor_data


func load_level_data() -> void:
	level_data = LevelData.new()
	
	if not Engine.is_editor_hint():
		# In runtime
		if ProjectSettings.get_setting("level_graph/runtime/cache_level_data"):
			var cache = ProjectSettings.get_setting("level_graph/data/levels_cache", LevelData.empty())
			if len(cache) > 0:
				level_data.deserialize(cache)
				print_rich("[Level Graph][color=white] Loaded level data from cache.")
				return
			else:
				push_error("[Level Graph] No cache found, will load as normal. Please run 'Reload levels' or save in the editor if you have auto refresh on.")
		else:
			print_rich("[Level Graph][color=white] Generating level data from scenes.")
	
	var root_dir: String = ProjectSettings.get_setting("level_graph/general/root_directory", "res://")
	
	var scene_files: Array[String] = []
	_recurse_dir(root_dir, 99, func(scene_file: String): scene_files.append(scene_file))
	
	if not Engine.is_editor_hint():
		for scene_file in scene_files:
			var level := LevelData.load_level(scene_file)
			if len(level.exits) > 0:
				level_data.levels.append(level)
	else:
		var threads: Array[Thread]
		
		var scene_per_thread: int = ceil(float(len(scene_files)) / MAX_THREADS)
		for i in range(MAX_THREADS):
			var thread := Thread.new()
			thread.start(func():
				var levels: Array[LevelData.Level] = []
				for j in range(scene_per_thread):
					var ind := i * scene_per_thread + j
					if ind >= len(scene_files): break
					levels.append(LevelData.load_level(scene_files[ind]))
				return levels
			)
			threads.append(thread)
	
		for t in threads:
			var levels: Array[LevelData.Level] = t.wait_to_finish()
			for level in levels:
				if level and len(level.exits) > 0:
					level_data.levels.append(level)
	
	if ProjectSettings.get_setting("level_graph/runtime/cache_level_data", false):
		ProjectSettings.set_setting("level_graph/data/levels_cache", level_data.serialize())
	else:
		ProjectSettings.set_setting("level_graph/data/levels_cache", LevelData.empty())
	if Engine.is_editor_hint():
		ProjectSettings.save()

var _previous_cache_level_data = ProjectSettings.get_setting("level_graph/runtime/cache_level_data", false)
func _reload_level_data():
	if not ProjectSettings.get_setting("level_graph/general/auto_refresh_levels", false):
		return
	
	var cache_level_data = ProjectSettings.get_setting("level_graph/runtime/cache_level_data", false)
	if cache_level_data != _previous_cache_level_data:
		self.load_level_data.call_deferred()
	_previous_cache_level_data = cache_level_data

# Helper
static func _recurse_dir(path: String, max_level, callback: Callable, level = 0) -> void:
	if level > max_level:
		return
	var dir := DirAccess.open(path)
	for file in dir.get_files():
		if file.ends_with(".tscn"):
			callback.call(path.path_join(file))
	for subdir in dir.get_directories():
		_recurse_dir(path.path_join(subdir), max_level, callback, level + 1)

