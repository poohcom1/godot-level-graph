@icon("res://addons/level_graph/assets/exit-svgrepo-com.svg")
@tool
extends Area2D

const LevelData := preload("res://addons/level_graph/core/level_data.gd")
const LevelGraphInterface := preload("res://addons/level_graph/core/level_graph_interface.gd")
const GROUP_NAME := "LEVEL_GRAPH_EXIT"

enum Id { A, B, C, D, E, F, G }

@export var id: Id = -1
@export var orientation: LevelData.ExitOrientation = LevelData.ExitOrientation.Right
@export var direction: LevelData.Direction = LevelData.Direction.Right

var raycast := RayCast2D.new()
var collision_shape := CollisionShape2D.new()

var _id_set = false

func _ready() -> void:
	add_to_group(GROUP_NAME)
	# Ready
	raycast.exclude_parent = true
	raycast.collide_with_areas = false
	raycast.target_position = Vector2(0, 48)
	add_child(raycast)
	for i in range(1, 33):
		set_collision_mask_value(i, true)
		set_collision_layer_value(i, true)
		
		raycast.set_collision_mask_value(i, true)
	
	collision_shape.debug_color = Color.YELLOW
	add_child(collision_shape, false, Node.INTERNAL_MODE_FRONT)
	
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2, 64)
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

func _on_player_enter(node: Node):
	var level_graph_singleton := LevelGraphInterface.get_singleton(self)
	if level_graph_singleton.is_player(node):
		level_graph_singleton.change_level(owner, id)

func get_spawn_position():
	if orientation == LevelData.ExitOrientation.Right or orientation == LevelData.ExitOrientation.Left:
		return raycast.get_collision_point()
	else:
		return global_position

static func get_exits(node: Node) -> Array[Node]:
	if not node.is_inside_tree():
		return []
	
	return node.get_tree().get_nodes_in_group(GROUP_NAME)


func _validate_property(property: Dictionary) -> void:
	if property["name"] == "direction" and (orientation == LevelData.ExitOrientation.Right or orientation == LevelData.ExitOrientation.Left):
		property["usage"] = PROPERTY_USAGE_NO_EDITOR
