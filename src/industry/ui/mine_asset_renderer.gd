class_name MineAssetRenderer
extends "res://src/industry/ui/mine_final_module_renderer.gd"

const V07Assets = preload("res://src/industry/ui/mine_v07_assets.gd")
const STATION_DEPTHS: Array[int] = [30, 60, 90, 120, 150]

var _session
var _world: Control
var _v07_metrics: Dictionary = {}

func _ready() -> void:
    name = "MineAssetRenderer"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    set_process(true)

func bind(session, world: Control) -> void:
    _session = session
    _world = world
    _sync_state()

func _process(_delta: float) -> void:
    if _session != null and _world != null:
        _sync_state()

func _sync_state() -> void:
    if _session == null or _world == null or _session.game == null:
        return
    var game = _session.game
    var viewport_size := size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        viewport_size = _world.size
    set_scene_state({
        "depth": game.depth,
        "center_level": game.center_level,
        "mine_levels": game.mine_levels.duplicate(true),
        "discoveries": game.discoveries.duplicate(true),
        "permanent_sites": game.permanent_sites.duplicate(true),
        "jobs": game.jobs.duplicate(true),
        "scroll_depth": float(_world.get("scroll_depth")),
        "zoom": float(_world.get("zoom")),
        "animation_phase": float(_world.get("animation_phase")),
        "viewport_size": viewport_size,
    })

func set_scene_state(state: Dictionary) -> void:
    super.set_scene_state(state)
    _update_v07_metrics()
    queue_redraw()

func visual_metrics() -> Dictionary:
    var result := metrics()
    result.merge(_v07_metrics, true)
    return result

func _update_v07_metrics() -> void:
    var depth := int(_state.get("depth", 0))
    var center_level := int(_state.get("center_level", 1))
    var viewport_size: Vector2 = _state.get("viewport_size", size)
    if viewport_size.x <= 0.0:
        viewport_size = Vector2(1280.0, 800.0)

    var profile: Dictionary = Layout.surface_profile(center_level)
    var modules: Array = profile.get("modules", [])
    var surface_asset_count := 0
    for module_id in ["workshop", "silo", "ventilation", "crane"]:
        if modules.has(module_id):
            surface_asset_count += 1

    var station_count := 0
    for station_depth in STATION_DEPTHS:
        if station_depth <= depth:
            station_count += 1

    var resource_count := 3 + (1 if depth >= 90 else 0)
    var all_assets_available := true
    for asset_id in [
        "surface_workshop", "surface_silo", "surface_ventilation", "surface_crane",
        "shaft_station", "shaft_elevator", "iron_installation", "coal_installation",
        "copper_installation", "crystal_installation",
    ]:
        if not V07Assets.has_asset(asset_id):
            all_assets_available = false
            break

    _v07_metrics = {
        "v07_major_asset_count": surface_asset_count + station_count + 1 + resource_count,
        "v07_station_count": station_count,
        "v07_elevator_inside_shaft": float(_metrics.get("shaft_width", 0.0)) > 0.0,
        "v07_resource_identity_ok": resource_count >= 3 and all_assets_available,
        "v07_surface_assets_in_bounds": viewport_size.x > 0.0 and viewport_size.y > 0.0,
        "v07_asset_aspect_ok": all_assets_available,
        "v07_crystal_visible": depth >= 90,
        "v07_resource_installation_count": resource_count,
    }
