extends SceneTree

const RENDERER_PATH := "res://src/industry/ui/mine_asset_renderer.gd"

class FakeGame:
    extends RefCounted
    var depth: int = 150
    var center_level: int = 6
    var mine_levels: Dictionary = {"iron": 5, "coal": 5, "copper": 5}
    var discoveries: Dictionary = {}
    var permanent_sites: Array = []
    var jobs: Dictionary = {}

class FakeSession:
    extends RefCounted
    var game: FakeGame = FakeGame.new()

class FakeWorld:
    extends Control
    var scroll_depth: float = 55.0
    var zoom: float = 1.0
    var animation_phase: float = 0.35

func _state(scroll_depth_value: float = 55.0) -> Dictionary:
    return {
        "depth": 150,
        "center_level": 6,
        "mine_levels": {"iron": 5, "coal": 5, "copper": 5},
        "discoveries": {},
        "permanent_sites": [],
        "jobs": {},
        "scroll_depth": scroll_depth_value,
        "zoom": 1.0,
        "animation_phase": 0.35,
        "viewport_size": Vector2(1280, 800),
    }

func _init() -> void:
    var failures := 0
    var renderer_script := load(RENDERER_PATH)
    if renderer_script == null:
        push_error("missing v0.7 runtime renderer: %s" % RENDERER_PATH)
        quit(1)
        return

    var renderer = renderer_script.new()
    renderer.size = Vector2(1280, 800)
    var world := FakeWorld.new()
    world.size = Vector2(1280, 800)
    var session := FakeSession.new()

    if not renderer.has_method("bind"):
        push_error("MineAssetRenderer must expose bind(session, world)")
        failures += 1
    else:
        renderer.bind(session, world)
        renderer._process(0.0)

    if not renderer.has_method("set_scene_state"):
        push_error("MineAssetRenderer must preserve set_scene_state")
        failures += 1
    else:
        renderer.set_scene_state(_state())

    if not renderer.has_method("visual_metrics"):
        push_error("MineAssetRenderer must expose visual_metrics")
        failures += 1
    else:
        var metrics: Dictionary = renderer.visual_metrics()
        for key in [
            "v07_major_asset_count",
            "v07_station_count",
            "v07_elevator_inside_shaft",
            "v07_resource_identity_ok",
            "v07_surface_assets_in_bounds",
            "v07_asset_aspect_ok",
            "v07_crystal_visible",
            "v07_resource_installation_count",
        ]:
            if not metrics.has(key):
                push_error("missing v0.7 visual metric: %s" % key)
                failures += 1

    # Task 3: surface + shaft must be composed from the v0.7 raster assets.
    renderer.set_scene_state(_state(0.0))
    var surface_metrics: Dictionary = renderer.visual_metrics()
    for key in [
        "v07_surface_asset_count",
        "v07_surface_uses_assets",
        "v07_shaft_uses_assets",
        "v07_elevator_rect",
        "v07_shaft_rect",
    ]:
        if not surface_metrics.has(key):
            push_error("missing v0.7 surface/shaft metric: %s" % key)
            failures += 1
    if int(surface_metrics.get("v07_surface_asset_count", 0)) < 4:
        push_error("desktop Centre 6 must expose four illustrated surface assets")
        failures += 1
    if not bool(surface_metrics.get("v07_surface_uses_assets", false)):
        push_error("surface must use v0.7 raster assets")
        failures += 1
    if not bool(surface_metrics.get("v07_shaft_uses_assets", false)):
        push_error("shaft stations/elevator must use v0.7 raster assets")
        failures += 1
    if int(surface_metrics.get("v07_station_count", 0)) != 5:
        push_error("depth 150 must expose five illustrated shaft stations")
        failures += 1

    if not renderer.has_method("_fit_rect"):
        push_error("MineAssetRenderer must preserve source aspect ratio with _fit_rect")
        failures += 1
    else:
        var fitted: Rect2 = renderer._fit_rect(Vector2(128.0, 96.0), Rect2(0.0, 0.0, 330.0, 120.0))
        var source_ratio := 128.0 / 96.0
        var fitted_ratio := fitted.size.x / fitted.size.y
        if absf(source_ratio - fitted_ratio) > 0.001:
            push_error("v0.7 asset fitting changed source aspect ratio")
            failures += 1

    var elevator_rect: Rect2 = surface_metrics.get("v07_elevator_rect", Rect2())
    var shaft_rect: Rect2 = surface_metrics.get("v07_shaft_rect", Rect2())
    if elevator_rect.size.x <= 0.0 or shaft_rect.size.x <= 0.0:
        push_error("shaft/elevator layout rects must be measurable")
        failures += 1
    elif elevator_rect.position.x < shaft_rect.position.x or elevator_rect.end.x > shaft_rect.end.x:
        push_error("illustrated elevator must stay inside shaft bounds")
        failures += 1

    renderer.free()
    world.free()
    quit(1 if failures > 0 else 0)
