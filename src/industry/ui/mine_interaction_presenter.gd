class_name MineInteractionPresenter
extends Control

const Style = preload("res://src/industry/ui/industry_theme.gd")
const ModuleRenderer = preload("res://src/industry/ui/mine_final_module_renderer.gd")

const REST_ALPHA := 0.24
const EMPHASIZED_ALPHA := 1.0
const MIN_TOUCH_HEIGHT := 44.0
const NARROW_BREAKPOINT := 800.0

var _world: Control
var _labels: Dictionary = {}
var _selected_key := ""
var _module_renderer: Control

func _ready() -> void:
    name = "MineInteractionPresenter"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    set_process(true)

func bind(world: Control) -> void:
    _world = world
    if _world != null and _world.has_signal("selection_changed") and not _world.selection_changed.is_connected(_on_world_selection):
        _world.selection_changed.connect(_on_world_selection)
    _ensure_module_renderer()
    _sync_module_renderer()
    _sync()

func set_selected_key(key: String) -> void:
    _selected_key = key
    if key == "":
        _release_world_focus()
    _sync()

func marker_alpha(key: String) -> float:
    if not _labels.has(key) or not is_instance_valid(_labels[key]):
        return -1.0
    return float((_labels[key] as CanvasItem).modulate.a)

func marker_is_emphasized(key: String) -> bool:
    if not _labels.has(key) or not is_instance_valid(_labels[key]):
        return false
    return bool((_labels[key] as Control).get_meta("emphasized", false))

func _process(_delta: float) -> void:
    if _world == null or not is_instance_valid(_world):
        return
    _sync_module_renderer()
    _sync()

func _ensure_module_renderer() -> void:
    if _world == null or not is_instance_valid(_world):
        return

    # v0.7 owns the visual composition when IndustryScreen has installed it.
    # Reusing it here prevents the former v0.6 renderer from being inserted
    # above the new raster assets while preserving the legacy fallback for
    # isolated presenter tests and older scenes.
    var asset_renderer := _world.find_child("MineAssetRenderer", false, false)
    if asset_renderer != null:
        _module_renderer = asset_renderer as Control
        return

    var existing := _world.find_child("MineModuleRenderer", false, false)
    if existing != null:
        _module_renderer = existing as Control
        return
    _module_renderer = ModuleRenderer.new()
    _world.add_child(_module_renderer)
    var presenter_index := get_index()
    if presenter_index >= 0:
        _world.move_child(_module_renderer, presenter_index)

func _sync_module_renderer() -> void:
    if _world == null or not is_instance_valid(_world):
        return
    _ensure_module_renderer()
    if _module_renderer == null or not is_instance_valid(_module_renderer):
        return
    var session_value = _world.get("session")
    if session_value == null:
        return
    var game = session_value.game
    var mine_rates: Dictionary = {}
    if game.has_method("mine_rate"):
        for id in ["iron", "coal", "copper"]:
            mine_rates[id] = game.mine_rate(id)
    _module_renderer.set_scene_state({
        "depth": game.depth,
        "center_level": game.center_level,
        "mine_levels": game.mine_levels.duplicate(true),
        "mine_rates": mine_rates,
        "discoveries": game.discoveries.duplicate(true),
        "permanent_sites": game.permanent_sites.duplicate(true),
        "jobs": game.jobs.duplicate(true),
        "scroll_depth": float(_world.get("scroll_depth")),
        "zoom": float(_world.get("zoom")),
        "animation_phase": float(_world.get("animation_phase")),
        "viewport_size": _world.size,
    })

func _sync() -> void:
    if _world == null or not is_instance_valid(_world):
        return
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
        _align_portrait_resource(target)
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
    if not target.has_meta("presenter_original_text"):
        target.set_meta("presenter_original_text", target.text)
    if not target.has_meta("presenter_touch_expanded"):
        var old_height := target.size.y
        var target_height := maxf(MIN_TOUCH_HEIGHT, old_height)
        target.custom_minimum_size = Vector2(maxf(112.0, target.custom_minimum_size.x), maxf(MIN_TOUCH_HEIGHT, target.custom_minimum_size.y))
        target.size = Vector2(maxf(112.0, target.size.x), target_height)
        target.position.y -= (target_height - old_height) * 0.5
        target.set_meta("presenter_touch_expanded", true)
    var original_text := str(target.get_meta("presenter_original_text", ""))
    target.tooltip_text = original_text
    target.text = ""
    target.modulate = Color(1.0, 1.0, 1.0, 0.035)
    target.focus_mode = Control.FOCUS_ALL

func _align_portrait_resource(target: Button) -> void:
    target.set_meta("final_crystal_art", false)
    if _world.size.x < NARROW_BREAKPOINT and _module_renderer != null and _module_renderer.has_method("final_crystal_binding"):
        var binding: Dictionary = _module_renderer.final_crystal_binding()
        if not binding.is_empty():
            var suffix := str(binding["id"]).replace(":", "_")
            if str(target.name) in ["Discovery_" + suffix, "Site_" + suffix]:
                target.set_meta("final_crystal_art", true)
                if binding["kind"] == "site" and str(target.name).begins_with("Discovery_"):
                    target.visible = false
                    return
                var rects: Dictionary = _module_renderer._resource_v07_rects(_world.size, int(_world.get("session").game.depth), true)
                if rects.has("crystal_installation"):
                    var crystal_rect: Rect2 = rects["crystal_installation"]
                    target.custom_minimum_size = Vector2(44.0, 44.0)
                    target.position = crystal_rect.position
                    target.size = crystal_rect.size
                    target.visible = _module_renderer._shallow_resource_visible(crystal_rect, true)
                    return
    if _world.size.x < NARROW_BREAKPOINT and target.name == "Drill" and _module_renderer != null and _module_renderer.has_method("final_drill_rect"):
        var drill_rect: Rect2 = _module_renderer.final_drill_rect()
        target.custom_minimum_size = Vector2(44.0, 44.0)
        target.position = drill_rect.position
        target.size = drill_rect.size
        target.visible = drill_rect.end.y >= 0.0 and drill_rect.position.y < _world.size.y
        return
    if _world.size.x >= NARROW_BREAKPOINT or not target.name.begins_with("Mine_"):
        return
    if _module_renderer == null or not _module_renderer.has_method("_resource_v07_rects"):
        return
    var session_value = _world.get("session")
    if session_value == null:
        return
    var resource_id := str(target.name).trim_prefix("Mine_")
    var rects: Dictionary = _module_renderer._resource_v07_rects(_world.size, session_value.game.depth, true)
    var asset_id := resource_id + "_installation"
    if not rects.has(asset_id):
        return
    var asset_rect: Rect2 = rects[asset_id]
    target.position = asset_rect.position
    target.size = asset_rect.size
    target.visible = _module_renderer._shallow_resource_visible(asset_rect, true)
    var install_depth: int = {"iron": 22, "coal": 50, "copper": 78}.get(resource_id, 0)
    target.set_meta("portrait_initial_network", session_value.game.depth < install_depth)

func _release_world_focus() -> void:
    if _world == null or not is_instance_valid(_world) or get_viewport() == null:
        return
    var focus_owner := get_viewport().gui_get_focus_owner()
    if not focus_owner is Control:
        return
    var cursor: Node = focus_owner
    while cursor != null:
        if cursor == _world:
            (focus_owner as Control).release_focus()
            return
        cursor = cursor.get_parent()

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
        label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.88))
        label.add_theme_constant_override("shadow_offset_x", 1)
        label.add_theme_constant_override("shadow_offset_y", 1)
        add_child(label)
        _labels[key] = label

    var hover_enabled := _world.size.x >= NARROW_BREAKPOINT
    var emphasized := key == _selected_key or target.has_focus() or (hover_enabled and target.is_hovered())
    label.set_meta("emphasized", emphasized)
    label.text = text if emphasized else "· " + text
    if bool(target.get_meta("portrait_initial_network", false)):
        label.text = text + " · réseau initial"
    label.visible = target.visible
    var portrait := not hover_enabled
    var label_height := 26.0 if portrait else 20.0
    label.size = Vector2(maxf(78.0, target.size.x), label_height)
    label.position = Vector2(target.position.x + target.size.x * 0.5 - label.size.x * 0.5, target.position.y - label_height)
    label.add_theme_font_size_override("font_size", 14 if portrait else (12 if emphasized else 10))
    label.modulate = Color(1.0, 1.0, 1.0, EMPHASIZED_ALPHA if emphasized else (0.90 if portrait else REST_ALPHA))
    label.add_theme_color_override("font_color", _color_for_key(key, emphasized))
    if portrait and _module_renderer != null and _module_renderer.has_method("uses_final_portrait"):
        if key in ["iron", "coal", "copper", "Drill"] or bool(target.get_meta("final_crystal_art", false)):
            label.visible = false # Identity plates are drawn inside the scene.
        elif key.begins_with("Discovery_") and not emphasized:
            label.text = "◆"
            label.size = Vector2(32.0, 26.0)
            label.position = target.position + Vector2(target.size.x * 0.5 - 16.0, -12.0)
            label.add_theme_font_size_override("font_size", 16)

func _color_for_key(key: String, emphasized: bool) -> Color:
    var color := Style.MUTED
    if key == "Drill":
        color = Style.COPPER
    elif key.begins_with("Discovery_"):
        color = Style.ACCENT
    elif key.begins_with("Site_"):
        color = Style.CRYSTAL_CYAN
    elif emphasized:
        color = Style.TEXT
    if emphasized:
        return color.lightened(0.10)
    return color

func _on_world_selection(kind: String, id: String) -> void:
    match kind:
        "mine":
            set_selected_key(id)
        "drill":
            set_selected_key("Drill")
        "discovery":
            set_selected_key("Discovery_" + id.replace(":", "_"))
        "site":
            set_selected_key("Site_" + id.replace(":", "_"))
        _:
            set_selected_key("")

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
    var original_text := str(target.get_meta("presenter_original_text", target.text))
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
        var raw := original_text.to_lower()
        if "anomal" in raw:
            return "Anomalie"
        if "structure" in raw:
            return "Structure"
        if "cristal" in raw:
            return "Cristaux"
        return "Signal minéral"
    return original_text
