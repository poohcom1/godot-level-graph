namespace Addons.LevelGraph;

using System;
using System.Threading.Tasks;
using Godot;

// Bridge; see level_data.gd
public enum LevelGraphOrientation {
    Right = 0,
    Left = 1,
    Top = 2,
    Bottom = 3,
}

public enum LevelGraphVerticalDirection {
    Right = 0,
    Left = 1
}

/// <summary>
/// Main singleton to interface with the level graph.
/// A wrapper of the gdscript singleton.
/// </summary>
public partial class LevelGraphInterface : Node {
    public static LevelGraphInterface Singleton { get; private set; } = null!;
    public static event Action<LevelGraphInterface>? SingletonReady;

    public event Action<string, int>? LevelChanged;

    private readonly Node _levelGraphNode;

    private LevelGraphInterface(Node levelGraphInterfaceNode) {
        _levelGraphNode = levelGraphInterfaceNode;
        _levelGraphNode.Connect("level_changed", Callable.From((string level, int stage) => LevelChanged?.Invoke(level, stage)));

        Singleton = this;
        SingletonReady?.Invoke(this);
    }

    private Node GetSingleton() {
        return _levelGraphNode;
    }

    public void SetPlayer(Node player) {
        GetSingleton().Call("set_player", player);
    }

    public bool IsPlayer(Node player) {
        return (bool)GetSingleton().Call("is_player", player);
    }

    public (string toLevel, int toExit) GetDestination(string levelUid, int exitId) {
        var result = GetSingleton().Call("get_destination", levelUid, exitId).AsGodotDictionary();
        return ((string)result["level"], (int)result["exit"]);
    }

    public async Task<Node2D?> GetExitNodeInLevel(int exitId) {
        var res = GetSingleton().Call("get_exit_node_in_level", exitId).AsGodotObject();
        return (Node2D)(await ToSignal(res, "completed"))[0];
    }

    public Vector2 GetExitNodeSpawnPosition(Node2D? exitNode) {
        return (Vector2)GetSingleton().Call("get_exit_node_spawn_position", exitNode!);
    }

    public LevelGraphOrientation GetExitNodeOrientation(Node2D? exitNode) {
        return (LevelGraphOrientation)GetSingleton().Call("get_exit_node_orientation", exitNode!).AsInt16();
    }

    public LevelGraphVerticalDirection GetExitNodeDirection(Node2D? exitNode) {
        return (LevelGraphVerticalDirection)GetSingleton().Call("get_exit_node_direction", exitNode!).AsInt16();
    }
}