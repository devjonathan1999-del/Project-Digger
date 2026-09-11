class_name MineModuleRenderer
extends Control

var _state: Dictionary = {}
var _metrics: Dictionary = {
    "surface_module_count": 0,
    "shaft_station_count": 0,
    "resource_installation_count": 0,
}

func _ready() -> void:
    name = "MineModuleRenderer"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func set_scene_state(state: Dictionary) -> void:
    _state = state.duplicate(true)
    var center_level: int = int(_state.get("center_level", 1))
    var depth: int = int(_state.get("depth", 0))
    _metrics["surface_module_count"] = clampi(center_level + 1, 2, 7)
    _metrics["shaft_station_count"] = maxi(0, depth / 30)
    _metrics["resource_installation_count"] = 3
    queue_redraw()

func metrics() -> Dictionary:
    return _metrics.duplicate(true)
