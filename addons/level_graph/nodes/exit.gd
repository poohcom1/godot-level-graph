@icon("res://addons/level_graph/assets/exit-svgrepo-com.svg")
@tool
class_name Exit extends Area2D

signal exit_ready

const LevelData := preload("res://addons/level_graph/core/level_data.gd")
const LevelGraphInterface := preload("res://addons/level_graph/core/level_graph_interface.gd")
const GROUP_NAME := "LEVEL_GRAPH_EXIT"

enum Id { A, B, C, D, E, F, G }

@export var shape := Vector2(2, 78):
	set(size):
		_collision_shape_size = size
		if collision_shape != null and collision_shape.shape != null:
			collision_shape.shape.size = size
		if raycast != null:
			raycast.target_position = Vector2(0, size.y / 2)
	get():
		return _collision_shape_size

@export var id: Id = -1
@export var orientation: LevelData.ExitOrientation:
	set(value):
		orientation = value
		notify_property_list_changed()
	get:
		return orientation
@export var direction: LevelData.Direction = LevelData.Direction.Right

var is_exit_ready := false

var raycast := RayCast2D.new()
var collision_shape := CollisionShape2D.new()

var _id_set = false
var _collision_shape_size := Vector2(2, 78)
var _collision_point: Vector2


func _ready() -> void:
	add_to_group(GROUP_NAME)
	# Ready
	raycast.exclude_parent = true
	raycast.collide_with_areas = false
	raycast.target_position = Vector2(0, _collision_shape_size.y / 2)
	add_child(raycast)
	for i in range(1, 33):
		set_collision_mask_value(i, true)
		set_collision_layer_value(i, true)
		raycast.set_collision_mask_value(i, true)
	
	collision_shape.debug_color = Color.YELLOW
	add_child(collision_shape, false, Node.INTERNAL_MODE_FRONT)
	
	var rect := RectangleShape2D.new()
	rect.size = _collision_shape_size
	collision_shape.shape = rect
	
	if Engine.is_editor_hint() and is_inside_tree():
		await get_tree().process_frame
		if get_tree() == null: return
		var exits := get_tree().get_nodes_in_group(GROUP_NAME).filter(func(x: Node): 
			return x.owner == owner and x != self
		)
		if id == -1:
			id = len(exits)
		else:
			for exit in exits:
				if id == exit.id:
					id += 1
	if not Engine.is_editor_hint():
		body_entered.connect(_on_player_enter)
		area_entered.connect(_on_player_enter)
		
		
		if orientation == LevelData.ExitOrientation.Right or orientation == LevelData.ExitOrientation.Left:
			var raycast_hit = null
			for i in range(50):
				raycast_hit = raycast.get_collider()
				if raycast_hit is TileMapLayer:
					break
				await get_tree().process_frame

			if raycast_hit is TileMapLayer:
				_collision_point = raycast.get_collision_point()
			else:
				printerr("Exit is not colliding with tilemap. Found: " + str(raycast_hit))
		
	exit_ready.emit()
	is_exit_ready = true

func _on_player_enter(node: Node):
	var level_graph_singleton := LevelGraphInterface.get_singleton(self)
	if level_graph_singleton.is_player(node):
		level_graph_singleton.change_level(owner, id)

func get_spawn_position():
	if orientation == LevelData.ExitOrientation.Right or orientation == LevelData.ExitOrientation.Left:
		return _collision_point
	else:
		return global_position

static func get_exits(node: Node) -> Array[Exit]:
	if not node.is_inside_tree():
		return []
	var exits: Array[Exit] = []
	exits.assign(node.get_tree().get_nodes_in_group(GROUP_NAME))
	return exits


func _validate_property(property: Dictionary) -> void:
	if property["name"] == "direction" and (orientation == LevelData.ExitOrientation.Right or orientation == LevelData.ExitOrientation.Left):
		property["usage"] = PROPERTY_USAGE_NO_EDITOR
