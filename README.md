# Godot Level Graph

A Godot addon for level organization and room transitions using Area2D nodes, inspired by Nathan Hoad's [Location Manager](https://www.youtube.com/watch?v=_l3yTp9JOOg).

Designed specifically for 2D side-scrollers and metroidvanias with loosely connected rooms as opposed to a strict grid-like map.

This is a mirror of the addon in my game project, so I won't be actively maintaining it. Feel free to fork and upload to the asset library if you want.

![Preview](.github/preview.png)

## Setup

1. Copy the `addons/level_graph` folder to your project's `addons` folder.
2. Enable the plugin in the project settings.
3. In your project settings, set `Level Graph > General > Root Directory` to a folder where your level scenes will be stored.
4. Add `Exit` nodes into your scenes to define the room transitions.
5. Go to the `Level` editor tab and select `Reload levels`.
6. Connect your levels using the `Connect` button.
7. Setup your code. Use the `LevelGraph` singleton to get information about the levels and exits.

   ```gdscript
   # player.gd - Must be a body or area

   func _ready():
     LevelGraph.set_player(self)


   # stage_manager.gd - Whatever script you want to manage level changes

   func _ready() -> void:
     LevelGraph.level_changed.connect(_on_level_change)

   func _on_level_change(from_level: String, from_exit: int) -> void:
     var exit: Exit = LevelGraph.get_exit_node_in_level(from_exit)
     player.leave_level(exit.orientation) # For animating exit

     var dest: Dictionary = LevelGraph.get_destination(from_level, from_exit)
     get_tree().change_scene_to_file(dest["level"]) # Or whatever method you use to transition scenes

     var entry: Exit = LevelGraph.get_exit_node_in_level(dest["exit"])

     player.global_position = LevelGraph.get_exit_node_spawn_position(entry) # Uses the Exit's raycast to find the ground position when the Exit is Left/Right
     player.enter_level(entry.orientation) # For animating entry
   ```

## API
- `LevelGraph`: Singleton for getting level information. 
- `Exit`: An area 2D node that triggers a room transition when the player collides with it.
- `LevelGraph.Orientation`: Cosmetic value set on an Exit node, represented by the arrow on the level editor. Has no affect on transitions, but useful for getting the direction to animate player walking in/out or levels.
- `LevelGraph.VerticalDirection`: Cosmetic value set on an Exit node. Direction of the player when the exit is `Top` or `Bottom`. Can be used to set the facing direction of the player jumping/falling into levels.

## Settings

| Setting             | Description                                                                        |
| ------------------- | ---------------------------------------------------------------------------------- |
| Root Directory      | The folder where your level scenes are stored. Set this to speed up level loading. |
| Group Levels        | Group levels in the editor by parent directory.                                    |
| Auto refresh levels | Automatically reload levels on save.                                               |
