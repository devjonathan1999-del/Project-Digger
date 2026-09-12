extends SceneTree

const Renderer = preload("res://src/industry/ui/mine_asset_renderer.gd")

func _state(depth: int, scroll_depth: float) -> Dictionary:
    return {
        "depth": depth,
        "center_level": 6,
        "mine_levels": {"iron": 5, "coal": 5, "copper": 5},
        "discoveries": {},
        "permanent_sites": [],
        "jobs": {},
        "scroll_depth": scroll_depth,
        "zoom": 1.0,
        "animation_phase": 0.35,
        "viewport_size": Vector2(1280, 800),
    }

func _init() -> void:
    var failures := 0
    var renderer := Renderer.new()
    renderer.size = Vector2(1280, 800)

    renderer.set_scene_state(_state(60, 0.0))
    var shallow: Dictionary = renderer.visual_metrics()
    var shallow_ids: Array = shallow.get("v07_resource_asset_ids", [])
    if shallow_ids != ["iron_installation", "coal_installation", "copper_installation"]:
        push_error("depth 60 must use exactly the three shallow v0.7 resource PNGs")
        failures += 1
    if int(shallow.get("v07_resource_asset_count", 0)) != 3:
        push_error("depth 60 must draw three v0.7 resource installations")
        failures += 1
    if bool(shallow.get("v07_crystal_asset_drawn", true)):
        push_error("crystal PNG must stay hidden before 90 m")
        failures += 1
    if not bool(shallow.get("v07_resources_use_assets", false)):
        push_error("shallow resources must be asset-driven")
        failures += 1

    renderer.set_scene_state(_state(150, 82.0))
    var deep: Dictionary = renderer.visual_metrics()
    var deep_ids: Array = deep.get("v07_resource_asset_ids", [])
    if deep_ids != ["iron_installation", "coal_installation", "copper_installation", "crystal_installation"]:
        push_error("depth 150 must use all four v0.7 resource PNGs")
        failures += 1
    if int(deep.get("v07_resource_asset_count", 0)) != 4:
        push_error("depth 150 must expose four v0.7 resource installations")
        failures += 1
    if not bool(deep.get("v07_crystal_asset_drawn", false)):
        push_error("crystal PNG must be enabled from 90 m")
        failures += 1

    var rects: Dictionary = deep.get("v07_resource_rects", {})
    for id in ["iron_installation", "coal_installation", "copper_installation", "crystal_installation"]:
        if not rects.has(id):
            push_error("missing resource layout rect: %s" % id)
            failures += 1
            continue
        var rect: Rect2 = rects[id]
        if rect.size.x < 200.0 or rect.size.y < 100.0:
            push_error("resource PNG is too small to be a major installation: %s" % id)
            failures += 1

    renderer.free()
    quit(1 if failures > 0 else 0)
