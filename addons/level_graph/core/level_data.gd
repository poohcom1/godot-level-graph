## LevelData - Data extracted from levels at runtime

const ExitScriptPath := "res://addons/level_graph/nodes/exit.gd"

enum ExitOrientation { 
	Right = 0,
	Left = 1,
	Top = 2,
	Bottom = 3,
}

enum Direction { Right = 0, Left = 1 }

var levels: Array[Level] = []

func serialize() -> Array:
	return levels.map(func(l: Level): return l.serialize())

func deserialize(data: Array):
	levels.assign(data.map(func(d: Dictionary):
		var l := Level.new()
		l.deserialize(d)
		return l
	))

static func empty() -> Array:
	return []
	
func convert_to_export() -> void:
	for level in levels:
		level.convert_to_export()

#region Getters
func get_exit_orientation(level_uid: String, exit: int) -> int:
	for level in levels:
		if level.uid == level_uid:
			if level.exit_orientations.has(exit):
				return level.exit_orientations[exit]
			push_error("Exit orientation not found for %s, exit: %d" % [level_uid, exit])
			return -1
	return -1

func get_exit_direction(level_uid: String, exit: int) -> int:
	for level in levels:
		if level.uid == level_uid:
			if level.exit_directions.has(exit):
				return level.exit_directions[exit]
			push_error("Exit direction not found for %s, exit: %d" % [level_uid, exit])
			return -1
	return -1

func _to_string() -> String:
	return "\n".join(levels.map(func(l: Level): return l._to_string()))
#endregion

#region Analyser

static func load_level(scene_file: String) -> Level:
	return parse_scene_file(scene_file)


static func parse_scene_file(scene_file: String) -> Level:
	var file_contents := FileAccess.get_file_as_string(scene_file)
	var lines := file_contents.split('\n')
	
	var level = Level.new()
	
	var uid_regex = RegEx.new()
	uid_regex.compile('uid="([^"]+)"')
	
	var id_regex = RegEx.new()
	id_regex.compile('id="([^"]+)"')
	
	var reg_match := uid_regex.search(lines[0])
	
	if not reg_match:
		return level
	
	level.uid = reg_match.get_string(1)
	level.name = scene_file.get_file().get_basename()
	level.directory = scene_file.get_slice("/", scene_file.get_slice_count("/") - 2)
	
	# Get exits
	var exit_script_id = ""
	for line in lines:
		if line.begins_with("["):
			if line.begins_with("[ext_resource"):
				if line.contains('path="%s"' % ExitScriptPath):
					var id_reg_match := id_regex.search(line)
					exit_script_id = id_reg_match.get_string(1)
					break
			elif line.begins_with("[gd_scene"):
				pass
			else:
				break
	if exit_script_id != "":
		for i in range(len(lines)):
			var line := lines[i]
			# Found exit
			if line.contains('script = ExtResource("%s")' % exit_script_id):
				var id := 0
				var orientation := ExitOrientation.Right
				var direction := Direction.Right
				
				var j = i
				while not lines[j].begins_with('[node') and j >= 0:
					j -= 1
				j += 1
				while not lines[j].begins_with('[node') and not lines[j].is_empty() and (j < len(lines)):
					if not " = " in lines[j]: continue
					var parts = lines[j].split(" = ")
					match parts[0]:
						"id": id = int(parts[1])
						"orientation": orientation = int(parts[1])
						"direction": direction = int(parts[1])
					j += 1
				
				level.exits.append(id)
				level.exit_orientations[id] = orientation
				level.exit_directions[id] = direction
	return level
#endregion

#region Subclasses
## Data model to represent levels visually
class Level:
	var uid: String
	var name: String
	var directory: String
	var exits: Array[int] = []
	## key: int (exit id), value: ExitOrientation
	var exit_orientations: Dictionary = {}
	## key: int (exit id), value: ExitDirection
	var exit_directions: Dictionary = {}
	
	func get_orientation_exits(o: ExitOrientation) -> Array[int]:
		return exits.filter(func(ind): return exit_orientations[ind] == o)
	
	func serialize() -> Dictionary:
		return {
			"uid": uid,
			"name": name,
			"directory": directory,
			"exits": exits,
			"exit_orientations": exit_orientations,
			"exit_directions": exit_directions,
		}
	
	func deserialize(data: Dictionary):
		uid = data["uid"]
		name = data["name"]
		directory = data["directory"]
		exits = data["exits"]
		exit_orientations = data["exit_orientations"]
		exit_directions = data["exit_directions"]
	
	func convert_to_export() -> void:
		uid = ResourceUID.get_id_path(ResourceUID.text_to_id(uid))

	func _to_string() -> String:
		return uid + ": " + name + ", Exits: " + str(exits) + ", Orientations: " + str(exit_orientations) + ", Direction: " + str(exit_directions)
#endregion
