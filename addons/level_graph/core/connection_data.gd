## ConnectionData - Data on level connections

var connections: Array[Connection] = []

#region Getters
## returns [level, exit]
func get_destination(scene: String, exit: int) -> Array:
	for conn in connections:
		if conn.has_exit(scene, exit):
			return conn.other_exit(scene, exit)
	return []
#endregion

#region Actions
func create_connection(from_level: String, from_exit: int, to_level: String, to_exit: int):
	var conn = Connection.new()
	conn.from_level = from_level
	conn.from_exit = from_exit
	conn.to_level = to_level
	conn.to_exit = to_exit
	
	# Check dupes
	if connections.any(func(c): return conn.equals(c)):
		return
	
	for i in range(len(connections) - 1, -1, -1):
		var c := connections[i]
		if c.from_level == from_level and c.from_exit == from_exit \
			or c.from_level == to_level and c.from_exit == to_exit \
			or c.to_level == to_level and c.to_exit == to_exit \
			or c.to_level == from_level and c.to_exit == from_exit:
			connections.remove_at(i)

	connections.append(conn)


func remove_connection(level: String, exit: int):
	for i in range(len(connections) - 1, -1, -1):
		var conn := connections[i]
		if conn.from_level == level and conn.from_exit == exit \
			or conn.to_level == level and conn.to_exit == exit:
			connections.remove_at(i)
#endregion

#region Serialize
static func empty() -> Array:
	return []

func serialize() -> Array:
	var data_dict := []
	# - Connections
	for conn in connections:
		var conn_dict := {}
		conn_dict["from_level"] = conn.from_level
		conn_dict["from_exit"] = conn.from_exit
		conn_dict["to_level"] = conn.to_level
		conn_dict["to_exit"] = conn.to_exit
		
		data_dict.append(conn_dict)
	return data_dict

func deserialize(data_dict: Array) -> void:
	# - Connections
	connections = []
	for conn_dict in data_dict:
		var conn = Connection.new()
		conn.from_level = conn_dict["from_level"] 
		conn.from_exit = conn_dict["from_exit"] 
		conn.to_level = conn_dict["to_level"] 
		conn.to_exit = conn_dict["to_exit"] 
		
		connections.append(conn)


#endregion
#region Subclasses
class Connection:
	var from_level: String
	var from_exit: int
	var to_level: String
	var to_exit: int
	
	func has_exit(level: String, exit: int) -> bool:
		return (from_level == level and from_exit == exit) or (to_level == level and to_exit == exit)
	
	## Assumes the exit EXISTS in this connection
	## returns [level, exit]
	func other_exit(level: String, exit: int) -> Array:
		if from_level == level and from_exit == exit:
			return [to_level, to_exit]
		return [from_level, from_exit]

	func _to_string() -> String:
		return "From: %s (%s), To: %s, (%s)" % [from_level, from_exit, to_level, to_exit]
	
	func equals(other: Connection) -> bool:
		return from_level == other.from_level and from_exit == other.from_exit and to_level == other.to_level and to_exit == other.to_exit \
			or from_level == other.to_level and from_exit == other.to_exit and to_level == other.from_level and to_exit == other.from_exit
#endregion
