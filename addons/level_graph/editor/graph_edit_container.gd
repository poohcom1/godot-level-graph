@tool
## GraphEditContainer
## Render levels. Does not handle file reading/writing; data must be passed via update()

extends VBoxContainer

# Scripts
const BaseLevelElement := preload("res://addons/level_graph/editor/base_level_element.gd")
const LevelElementScene := preload("res://addons/level_graph/editor/level_graph_element.tscn")
const ConnectionData := preload("res://addons/level_graph/core/connection_data.gd")
const EditorData := preload("res://addons/level_graph/core/editor_data.gd")
const LevelData := preload("res://addons/level_graph/core/level_data.gd")
const LevelGraphInterface := preload("res://addons/level_graph/core/level_graph_interface.gd")

# Signals
signal connection_updated(data: ConnectionData)
signal editor_updated(data: EditorData)

# Constants
const EXIT_DIST: float = 20.0
const AUTO_POS_OFFSET := 100

@onready var graph_edit: GraphEdit = %GraphEdit
@export var font: Font

var connection_data: ConnectionData
var editor_data: EditorData
var level_data: LevelData
## K: String uid, V: GraphElement
var level_elements: Dictionary = {}

var dragging_from: String = ""

func on_scene_active(scene_path: String):
	var active_uid = ResourceUID.id_to_text(ResourceLoader.get_resource_uid(scene_path))
	
	for uid in level_elements:
		level_elements[uid].set_active(uid == active_uid)

func update_data(connection_data: ConnectionData, editor_data: EditorData, level_data: LevelData) -> void:
	self.connection_data = connection_data
	self.editor_data = editor_data
	self.level_data = level_data
	
	# Setup elements
	for child in graph_edit.get_children():
		if child is GraphElement or child is GraphFrame:
			child.queue_free()
	level_elements.clear()
	
	var offset := Vector2(100, 100)
	var frames := {}
	for level in level_data.levels:
		var frame: GraphFrame
		if frames.has(level.directory):
			frame = frames[level.directory]
		else:
			frame = GraphFrame.new()
			var color_picker := ColorPickerButton.new()
			color_picker.edit_alpha = false
			color_picker.color_changed.connect(func(c: Color):
				frame.tint_color_enabled = true
				frame.tint_color = Color(c.r, c.g, c.b, c.a / 2)
				editor_data.set_dir_color(level.directory, c)
				editor_updated.emit(editor_data)
			)
			
			var color := editor_data.get_dir_color(level.directory)
			if color != Color.BLACK:
				frame.tint_color_enabled = true
				frame.tint_color = Color(color.r, color.g, color.b, color.a / 2)
				color_picker.color = color
			
			color_picker.custom_minimum_size = Vector2(32, 32)
			frame.get_titlebar_hbox().add_child(color_picker)
			frame.name = level.directory
			frame.title = level.directory
			frames[level.directory] = frame
			graph_edit.add_child(frame)
		
		var graph_el: BaseLevelElement = LevelElementScene.instantiate()
		graph_el.name = level.name
		graph_el.set_text(level.name)
		level_elements[level.uid] = graph_el
		graph_edit.add_child(graph_el)
		graph_edit.attach_graph_element_to_frame.call_deferred(graph_el.name, frame.name)
		
		graph_el.dragged.connect(func(from: Vector2, to: Vector2):
			editor_data.set_level_model(level.uid, to, null)
			editor_updated.emit(editor_data)
		)
		graph_el.resized.connect(func():
			editor_data.set_level_model(level.uid, null, graph_el.size)
			editor_updated.emit(editor_data)
		)
		graph_el.element_selected.connect(func():
			EditorInterface.open_scene_from_path(ResourceUID.get_id_path(ResourceUID.text_to_id(level.uid)))
		)
		
		# Setup size and position (editor)
		if level.uid in editor_data.level_models:
			var model: EditorData.LevelModel = editor_data.level_models[level.uid]
			graph_el.position_offset = model.position
			graph_el.size = model.size
		else:
			graph_el.position_offset = offset
			offset.y += AUTO_POS_OFFSET
			
			editor_data.set_level_model(level.uid, graph_el.position_offset, graph_el.size)
			editor_updated.emit(editor_data)
	
	if EditorInterface.get_edited_scene_root():
		on_scene_active(EditorInterface.get_edited_scene_root().scene_file_path)

func _process(_delta):
	queue_redraw()

func _draw() -> void:
	if connection_data == null or editor_data == null or level_data == null: return
	
	var exit_pos_cache := _get_exit_positions()
	
	for conn in connection_data.connections:
		var from_key = create_exit_key(conn.from_level, conn.from_exit)
		var to_key = create_exit_key(conn.to_level, conn.to_exit)
		
		if dragging_from == from_key or dragging_from == to_key:
			continue
			
		if not exit_pos_cache.has(from_key) or not exit_pos_cache.has(to_key):
			continue
		
		var from_pos = exit_pos_cache[from_key]["pos"]
		var to_pos = exit_pos_cache[to_key]["pos"]
		
		draw_line(from_pos, to_pos, Color.WHITE, 2)
	
	if dragging_from != "":
		draw_line(exit_pos_cache[dragging_from]["pos"], get_local_mouse_position(), Color.WHITE, 2)
		
	for key in exit_pos_cache:
		var data = from_exit_key(key)
		
		var display_char = char(data[1] + 65)
		var active = _in_mouse_range(exit_pos_cache[key]["pos"]) or key == dragging_from
		
		draw_circle(exit_pos_cache[key]["pos"], 4, Color.GREEN if active else Color.WHITE)
		
		var orientation: LevelData.ExitOrientation = exit_pos_cache[key]["orientation"]
		var direction: LevelData.Direction = exit_pos_cache[key]["direction"]
		var scale := graph_edit.zoom
		var display_arrow = get_arrow(orientation, direction)
		var offset: Vector2 = ORIENTATION_TEXT_OFFSET[orientation] * 8 + Vector2(-4, 20)
		var color = Color.GREEN if active else Color.WHITE

		draw_char(font, exit_pos_cache[key]["pos"] + (offset) * scale, display_char, 16 * scale, color)
		draw_char(font, exit_pos_cache[key]["pos"] + (offset - Vector2(0, 14)) * scale, display_arrow, 16 * scale, color)



func on_mouse_down(mouse_pos: Vector2) -> bool:
	if connection_data == null: return false
	
	var exit = ""
	var exit_pos_cache := _get_exit_positions()
	for key in exit_pos_cache:
		var pos = exit_pos_cache[key]["pos"]
		if _in_mouse_range(pos):
			exit = key
			break
	if exit:
		var exit_data = from_exit_key(exit)
		for conn in connection_data.connections:
			if conn.has_exit(exit_data[0], exit_data[1]):
				var other_exit = conn.other_exit(exit_data[0], exit_data[1])
				dragging_from = create_exit_key(other_exit[0], other_exit[1])
				return true
		dragging_from = exit
		return true
	return false


func on_mouse_up(mouse_pos: Vector2):
	if dragging_from == "":
		return
	var exit = ""
	var exit_pos_cache := _get_exit_positions()
	for key in exit_pos_cache:
		var pos = exit_pos_cache[key]["pos"]
		if _in_mouse_range(pos):
			exit = key
			break
	if exit:
		var from = from_exit_key(dragging_from)
		var to = from_exit_key(exit)
		
		# Same level
		if from[0] == to[0]:
			dragging_from = ""
			return
		
		connection_data.create_connection(from[0], from[1], to[0], to[1])
		connection_data.create_connection(from[0], from[1], to[0], to[1])
		connection_updated.emit(connection_data)
	else:
		var from = from_exit_key(dragging_from)
		connection_data.remove_connection(from[0], from[1])
		connection_updated.emit(connection_data)
	
	dragging_from = ""


func _on_reload_levels():
	var level_graph_interface := LevelGraphInterface.get_singleton(self)
	level_graph_interface.load_level_data()
	level_graph_interface.load_graph_data()
	
	update_data(level_graph_interface.connection_data, level_graph_interface.editor_data, level_graph_interface.level_data)

func _on_print_level_data():
	print(LevelGraphInterface.get_singleton(self).level_data)

# Helper
var ORIENTATIONS_VECTORS := {
	LevelData.ExitOrientation.Top: Vector2(0.5, 0),
	LevelData.ExitOrientation.Bottom: Vector2(0.5, 1),
	LevelData.ExitOrientation.Left: Vector2(0, 0.5),
	LevelData.ExitOrientation.Right: Vector2(1, 0.5)
}

var ORIENTATION_TEXT_OFFSET := {
	LevelData.ExitOrientation.Top: Vector2(0, 1.5),
	LevelData.ExitOrientation.Bottom: Vector2(0, -3),
	LevelData.ExitOrientation.Left: Vector2(1.5, -1.5),
	LevelData.ExitOrientation.Right: Vector2(-1.5, -1.5)
}

func get_arrow(orientation, direction) -> String:
	match orientation:
		LevelData.ExitOrientation.Top:
			return "↳" if direction == LevelData.Direction.Right else "↲"
		LevelData.ExitOrientation.Bottom:
			return "↱" if direction == LevelData.Direction.Right else "↰"
		LevelData.ExitOrientation.Left:
			return "→"
		LevelData.ExitOrientation.Right:
			return "←"
	return "?"

func _get_exit_positions() -> Dictionary:
	var exit_pos_cache := {}
	for level in level_data.levels:
		var element: BaseLevelElement = level_elements[level.uid]

		for orientation in ORIENTATIONS_VECTORS:
			var exits := level.get_orientation_exits(orientation)
			var offsets := get_offsets(50 * graph_edit.zoom, len(exits))
			
			for i in range(len(exits)):
				var exit = exits[i]
				var offset = offsets[i]
				
				var side = ORIENTATIONS_VECTORS[orientation]
				
				var mid_pos = element.position + Vector2(
					side.x * element.size.x * graph_edit.zoom,
					side.y * element.size.y * graph_edit.zoom
				)
				
				var exit_pos = mid_pos + Vector2(
					int(side.x == 0.5) * offset,
					int(side.y == 0.5) * offset 
				)
				
				exit_pos_cache[create_exit_key(level.uid, exit)] = {
					"pos": exit_pos,
					"orientation": orientation,
					"direction": level.exit_directions[exit],
				}
	return exit_pos_cache

func _in_mouse_range(exit_pos: Vector2):
	return get_local_mouse_position().distance_squared_to(exit_pos) < 300 * graph_edit.zoom

static func get_offsets(dist: float, count: int) -> Array[float]:
	if count == 1:
		return [0]
	var start = -dist / 2.0
	var offsets: Array[float] = []
	for i in range(count):
		offsets.append(start + (i * dist / (count - 1)))
	offsets.reverse()
	return offsets

static func create_exit_key(level_uid: String, exit_id: int) -> String:
	return level_uid + "__" + str(exit_id)

static func from_exit_key(key: String) -> Array:
	var els = key.split("__")
	return [els[0], int(els[1])]
