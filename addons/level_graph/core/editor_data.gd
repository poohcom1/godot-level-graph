## EditorData - Meta data for display in editor

## Key: String uid, Value: LevelModel
var level_models: Dictionary = {}
## Key: String directory, Value: Color
var dir_colors: Dictionary = {}

#region Getters
func get_level_model(uid: String) -> LevelModel:
	return level_models[uid]



#region Actions
func set_level_model(uid: String, position, size) -> void:
	if not level_models.has(uid):
		level_models[uid] = LevelModel.new()
	if position != null:
		level_models[uid].position = position
	if size != null:
		level_models[uid].size = size


func set_dir_color(dir: String, color: Color) -> void:
	dir_colors[dir] = color

func get_dir_color(dir: String) -> Color:
	if dir_colors.has(dir):
		return dir_colors[dir]
	return Color.BLACK
#endregion

#region Serialize
static func empty() -> Dictionary:
	return {}

func serialize() -> Dictionary:
	var data_dict := {}

	# - Levels
	data_dict["level_models"] = {}
	for uid in level_models:
		var level_model: LevelModel = level_models[uid]
		data_dict["level_models"][uid] = level_model.serialize()
	
	# - Dir color
	data_dict["dir_colors"] = {}
	for dir in dir_colors:
		data_dict["dir_colors"][dir] = var_to_str(dir_colors[dir])
	
	return data_dict

func deserialize(data_dict: Dictionary) -> void:
	# - Levels
	level_models = {}
	for uid in data_dict["level_models"]:
		var level_model := LevelModel.new()
		level_model.deserialize(data_dict["level_models"][uid])
		level_models[uid] = level_model
	dir_colors = {}
	for dir in data_dict["dir_colors"]:
		dir_colors[dir] = str_to_var(data_dict["dir_colors"][dir])

#endregion
#region Subclasses
class LevelModel:
	var position: Vector2
	var size: Vector2
	
	func serialize() -> Dictionary:
		return { "position": var_to_str(position), "size": var_to_str(size) }
	
	func deserialize(data: Dictionary) -> void:
		position = str_to_var(data["position"])
		size = str_to_var(data["size"])
#endregion
