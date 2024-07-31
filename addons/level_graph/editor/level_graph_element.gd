@tool
extends "res://addons/level_graph/editor/base_level_element.gd"

const DEFAULT_COLOR = Color.GRAY
const SELECTED_COLOR = Color.GREEN
const ACTIVE_COLOR = Color.ORANGE

@onready var label: Label = %Label
@onready var panel: Panel = $Panel

var _text: String = ""
var _selected := false
var _active := false

func set_text(text: String):
	_text = text
	if label:
		label.text = text

func set_active(active: bool) -> void:
	_active = active

func _ready() -> void:
	label.text = _text

	panel.modulate = DEFAULT_COLOR
	node_selected.connect(func(): _selected = true)
	node_deselected.connect(func(): _selected = false)
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			element_selected.emit()
			accept_event()

func _process(delta: float) -> void:
	panel.modulate = DEFAULT_COLOR
	
	if _active:
		panel.modulate = ACTIVE_COLOR
	if _selected:
		panel.modulate = SELECTED_COLOR
