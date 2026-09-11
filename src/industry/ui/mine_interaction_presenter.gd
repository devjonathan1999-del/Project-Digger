class_name MineInteractionPresenter
extends Control

const Style = preload("res://src/industry/ui/industry_theme.gd")

var _world: Control
var _labels: Dictionary = {}

func _ready() -> void:
    name = "MineInteractionPresenter"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    set_process(true)

func bind(world: Control) -> void:
    _world = world
    _sync()

func _process(_delta: float) -> void:
    if _world == null or not is_instance_valid(_world):
        return
    _sync()

func _sync() -> void:
    move_to_front()
    var seen: Dictionary = {}
    for node in _world.get_children():
        if not node is Button:
            continue
        var target := node as Button
        var key := _key_for_target(target.name)
        if key == "":
            continue
        seen[key] = true
        _style_target(target)
        _sync_label(key, _label_for_target(target), target)

    var existing := _labels.keys()
    for key_value in existing:
        var key := str(key_value)
        if seen.has(key):
            continue
        var stale = _labels[key]
        if is_instance_valid(stale):
            stale.free()
        _labels.erase(key)

func _style_target(target: Button) -> void:
    target.modulate = Color(1.0, 1.0, 1.0, 0.04)
    target.focus_mode = Control.FOCUS_NONE
    target.tooltip_text = target.text

func _sync_label(key: String, text: String, target: Button) -> void:
    var label: Label
    if _labels.has(key) and is_instance_valid(_labels[key]):
        label = _labels[key] as Label
    else:
        label = Label.new()
        label.name = "Label_" + key
        label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.add_theme_font_size_override("font_size", 11)
        label.add_theme_color_override("font_color", Style.TEXT)
        label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
        label.add_theme_constant_override("shadow_offset_x", 1)
        label.add_theme_constant_override("shadow_offset_y", 1)
        add_child(label)
        _labels[key] = label

    label.text = text
    label.visible = target.visible
    label.size = Vector2(maxf(92.0, target.size.x), 20.0)
    label.position = Vector2(target.position.x + target.size.x * 0.5 - label.size.x * 0.5, target.position.y - 20.0)
    if key == "Drill":
        label.add_theme_color_override("font_color", Style.COPPER)
    elif key.begins_with("Discovery_"):
        label.add_theme_color_override("font_color", Style.ACCENT)
    elif key.begins_with("Site_"):
        label.add_theme_color_override("font_color", Style.CRYSTAL_CYAN)

func _key_for_target(node_name: StringName) -> String:
    var value := str(node_name)
    if value.begins_with("Mine_"):
        return value.trim_prefix("Mine_")
    if value == "Drill":
        return "Drill"
    if value.begins_with("Discovery_"):
        return value
    if value.begins_with("Site_"):
        return value
    return ""

func _label_for_target(target: Button) -> String:
    var key := _key_for_target(target.name)
    match key:
        "iron":
            return "Fer"
        "coal":
            return "Charbon"
        "copper":
            return "Cuivre"
        "Drill":
            return "Foreuse"
    if key.begins_with("Site_"):
        return "Site d'exploitation"
    if key.begins_with("Discovery_"):
        var raw := target.text.to_lower()
        if "anomal" in raw:
            return "Anomalie"
        if "structure" in raw:
            return "Structure"
        if "cristal" in raw:
            return "Cristaux"
        return "Signal minéral"
    return target.text
