class_name MineSceneRenderer
extends Control

const Style = preload("res://src/industry/ui/industry_theme.gd")

const PIXELS_PER_METER := 7.0
const SURFACE_Y := 72.0

var surface_module_count := 0
var gallery_detail_count := 0
var deep_accent_strength := 0.0

var _session
var _world: Control
var _state: Dictionary = {}

func _ready() -> void:
    name = "MineSceneRenderer"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    set_process(true)

func bind(session, world: Control) -> void:
    _session = session
    _world = world
    _sync_state()

func set_scene_state(state: Dictionary) -> void:
    _state = state.duplicate(true)
    var center_level := int(_state.get("center_level", 1))
    var depth := int(_state.get("depth", 0))
    surface_module_count = 4 + maxi(0, mini(center_level - 3, 3))
    gallery_detail_count = 5 if depth >= 30 else 3
    deep_accent_strength = accent_strength_for_depth(depth)
    queue_redraw()

func accent_strength_for_depth(depth: int) -> float:
    if depth < 60:
        return 0.10
    if depth < 90:
        return 0.18
    if depth < 120:
        return 0.40
    if depth < 150:
        return 0.62
    return 0.82

func _process(_delta: float) -> void:
    if _session == null or _world == null:
        return
    _sync_state()

func _sync_state() -> void:
    if _session == null or _world == null:
        return
    var game = _session.game
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
        "viewport_size": size,
    })

func _draw() -> void:
    if _state.is_empty():
        return
    draw_rect(Rect2(Vector2.ZERO, size), Color("0b1219"))
    _draw_geology()
    _draw_surface()
    _draw_shaft()
    _draw_galleries()
    _draw_sites_and_discoveries()
    _draw_drill()
    _draw_depth_atmosphere()

func _draw_geology() -> void:
    var zones := [
        [0.0, 30.0, Color("323338")],
        [30.0, 60.0, Color("293039")],
        [60.0, 90.0, Color("202a34")],
        [90.0, 120.0, Color("192833")],
        [120.0, 150.0, Color("13232d")],
        [150.0, 230.0, Color("0d1d28")],
    ]
    for zone in zones:
        var y1 := _depth_to_y(float(zone[0]))
        var y2 := _depth_to_y(float(zone[1]))
        var top := minf(y1, y2)
        var bottom := maxf(y1, y2)
        if bottom < 0.0 or top > size.y:
            continue
        draw_rect(Rect2(0, top, size.x, bottom - top), zone[2])

    var first_depth := maxi(0, floori(_scroll_depth() / 10.0) * 10)
    var last_depth := ceili(_scroll_depth() + size.y / maxf(PIXELS_PER_METER * _zoom(), 0.01)) + 10
    for depth_value in range(first_depth, last_depth + 1, 10):
        var y := _depth_to_y(float(depth_value))
        if y < 0.0 or y > size.y:
            continue
        var alpha := 0.055 + accent_strength_for_depth(depth_value) * 0.06
        var wave := sin(float(depth_value) * 0.27) * 5.0
        draw_line(Vector2(0, y), Vector2(size.x, y + wave), Color(0.70, 0.78, 0.80, alpha), 1.0)

func _draw_surface() -> void:
    var y := _depth_to_y(0.0)
    if y < -90.0 or y > size.y + 90.0:
        return
    draw_rect(Rect2(0, y - 74.0, size.x, 74.0), Color("14212a"))
    draw_line(Vector2(0, y), Vector2(size.x, y), Color("8e6a48"), 3.0)

    var center := size.x * 0.50
    _draw_headframe(center, y)
    _draw_workshop(size.x * 0.16, y)
    _draw_silo(size.x * 0.30, y)
    _draw_operations(size.x * 0.70, y)

    var level := int(_state.get("center_level", 1))
    if level >= 4:
        _draw_crane(size.x * 0.83, y)
    if level >= 5:
        _draw_antenna(size.x * 0.91, y)
    if level >= 6:
        _draw_surface_pipe_network(y)

func _draw_headframe(x: float, ground_y: float) -> void:
    var steel := Color("748088")
    var copper := Color("c98247")
    draw_line(Vector2(x - 32, ground_y), Vector2(x - 18, ground_y - 62), steel, 5.0)
    draw_line(Vector2(x + 32, ground_y), Vector2(x + 18, ground_y - 62), steel, 5.0)
    draw_line(Vector2(x - 20, ground_y - 60), Vector2(x + 20, ground_y - 60), steel, 5.0)
    draw_circle(Vector2(x, ground_y - 51), 10.0, Color("1a2228"))
    draw_arc(Vector2(x, ground_y - 51), 10.0, 0.0, TAU, 20, copper, 2.5)
    draw_line(Vector2(x, ground_y - 41), Vector2(x, ground_y + 12), copper, 2.0)

func _draw_workshop(x: float, ground_y: float) -> void:
    var rect := Rect2(x - 55, ground_y - 40, 110, 40)
    draw_rect(rect, Color("394149"))
    draw_rect(Rect2(rect.position + Vector2(7, 8), Vector2(42, 9)), Color("d3934f"))
    draw_line(Vector2(x - 58, ground_y - 40), Vector2(x, ground_y - 55), Color("646f76"), 4.0)
    draw_line(Vector2(x, ground_y - 55), Vector2(x + 58, ground_y - 40), Color("646f76"), 4.0)
    for px in [-38.0, 0.0, 38.0]:
        draw_circle(Vector2(x + px, ground_y - 6), 2.5, Color("d69a55"))

func _draw_silo(x: float, ground_y: float) -> void:
    draw_rect(Rect2(x - 22, ground_y - 50, 44, 50), Color("59656b"))
    draw_circle(Vector2(x, ground_y - 50), 22.0, Color("59656b"))
    draw_line(Vector2(x - 13, ground_y), Vector2(x - 13, ground_y + 8), Color("868f93"), 3.0)
    draw_line(Vector2(x + 13, ground_y), Vector2(x + 13, ground_y + 8), Color("868f93"), 3.0)
    draw_rect(Rect2(x - 17, ground_y - 34, 34, 4), Color("c77b40"))

func _draw_operations(x: float, ground_y: float) -> void:
    draw_rect(Rect2(x - 65, ground_y - 45, 130, 45), Color("303b43"))
    draw_rect(Rect2(x - 54, ground_y - 34, 48, 13), Color("53a8a5"))
    draw_rect(Rect2(x + 8, ground_y - 34, 44, 13), Color("d09452"))
    draw_line(Vector2(x - 70, ground_y - 46), Vector2(x + 70, ground_y - 46), Color("78838a"), 3.0)

func _draw_crane(x: float, ground_y: float) -> void:
    var steel := Color("6e787d")
    draw_line(Vector2(x, ground_y), Vector2(x, ground_y - 65), steel, 5.0)
    draw_line(Vector2(x - 5, ground_y - 60), Vector2(x + 72, ground_y - 60), steel, 4.0)
    draw_line(Vector2(x + 55, ground_y - 60), Vector2(x + 55, ground_y - 32), Color("c98142"), 2.0)

func _draw_antenna(x: float, ground_y: float) -> void:
    draw_line(Vector2(x, ground_y), Vector2(x, ground_y - 56), Color("69767d"), 3.0)
    draw_arc(Vector2(x, ground_y - 48), 12, -2.6, -0.5, 16, Color("42c7c0"), 2.0)
    draw_circle(Vector2(x, ground_y - 49), 3.0, Color("42d7cf"))

func _draw_surface_pipe_network(ground_y: float) -> void:
    var y := ground_y - 16.0
    draw_line(Vector2(size.x * 0.22, y), Vector2(size.x * 0.67, y), Color("aa6c3f"), 4.0)
    draw_line(Vector2(size.x * 0.38, y), Vector2(size.x * 0.38, ground_y - 2), Color("aa6c3f"), 4.0)

func _draw_shaft() -> void:
    var x := size.x * 0.5
    var top_y := _depth_to_y(0.0)
    var bottom_depth := float(int(_state.get("depth", 0)) + 10)
    var bottom_y := _depth_to_y(bottom_depth)
    var top := minf(top_y, bottom_y)
    var height := absf(bottom_y - top_y)
    draw_rect(Rect2(x - 22, top, 44, height), Color("091117"))
    draw_line(Vector2(x - 15, top_y), Vector2(x - 15, bottom_y), Color("69757b"), 3.0)
    draw_line(Vector2(x + 15, top_y), Vector2(x + 15, bottom_y), Color("69757b"), 3.0)
    draw_line(Vector2(x - 3, top_y), Vector2(x - 3, bottom_y), Color("b17140"), 1.5)
    for depth_value in range(10, int(bottom_depth) + 1, 10):
        var y := _depth_to_y(float(depth_value))
        draw_line(Vector2(x - 18, y), Vector2(x + 18, y), Color("39464d"), 1.0)

func _draw_galleries() -> void:
    var current_depth := int(_state.get("depth", 0))
    var horizons := [12, 30, 60, 90, 120, 150]
    for depth_value in horizons:
        if depth_value > current_depth + 15:
            continue
        var y := _depth_to_y(float(depth_value))
        if y < -70.0 or y > size.y + 70.0:
            continue
        _draw_gallery(float(depth_value), y)

func _draw_gallery(depth_value: float, y: float) -> void:
    var accent := accent_strength_for_depth(int(depth_value))
    var left_start := size.x * 0.08
    var left_end := size.x * 0.45
    var right_start := size.x * 0.55
    var right_end := size.x * 0.92
    var cavity := Color("11191f")
    draw_rect(Rect2(left_start, y - 24, left_end - left_start, 48), cavity)
    draw_rect(Rect2(right_start, y - 24, right_end - right_start, 48), cavity)
    _draw_gallery_side(left_start, left_end, y, false, accent)
    _draw_gallery_side(right_start, right_end, y, true, accent)

func _draw_gallery_side(start_x: float, end_x: float, y: float, mirrored: bool, accent: float) -> void:
    var steel := Color("68767c")
    var amber := Color("d49a54")
    var cyan := Color(0.25, 0.86, 0.82, accent)
    draw_line(Vector2(start_x, y + 14), Vector2(end_x, y + 14), steel, 3.0)
    draw_line(Vector2(start_x, y + 19), Vector2(end_x, y + 19), Color("37434a"), 2.0)
    for x in range(int(start_x) + 18, int(end_x), 58):
        draw_line(Vector2(x, y - 20), Vector2(x, y + 22), steel, 2.0)
        draw_line(Vector2(x - 8, y - 20), Vector2(x + 8, y - 20), steel, 2.0)
        draw_circle(Vector2(x, y - 13), 3.0, amber)
    var pipe_y := y - 8.0
    draw_line(Vector2(start_x + 10, pipe_y), Vector2(end_x - 10, pipe_y), Color("9a613a"), 3.0)
    if accent > 0.15:
        draw_line(Vector2(start_x + 18, y + 6), Vector2(end_x - 18, y + 6), cyan, 1.5)
    var machine_x := end_x - 46.0 if not mirrored else start_x + 16.0
    draw_rect(Rect2(machine_x, y - 4, 32, 18), Color("3d4a51"))
    draw_rect(Rect2(machine_x + 5, y + 1, 9, 5), amber)

func _draw_sites_and_discoveries() -> void:
    var discoveries: Dictionary = _state.get("discoveries", {})
    for discovery in discoveries.values():
        var depth := int(discovery.get("depth", 0))
        var slot := int(discovery.get("slot", 0))
        var x := size.x * (0.23 if slot % 2 == 0 else 0.70)
        var y := _depth_to_y(float(depth))
        if y < -50.0 or y > size.y + 50.0:
            continue
        var type_id := str(discovery.get("type", ""))
        if type_id == "unstable_cavity":
            var pulse := 18.0 + sin(_phase() * 3.0) * 3.0
            draw_circle(Vector2(x, y), pulse, Color(0.64, 0.34, 0.84, 0.13))
            draw_arc(Vector2(x, y), pulse - 4.0, 0, TAU, 24, Color("aa6de0"), 2.0)
        else:
            draw_line(Vector2(x - 13, y - 13), Vector2(x + 10, y + 12), Color("b67742"), 3.0)
            draw_line(Vector2(x - 3, y - 17), Vector2(x + 15, y + 3), Color("db9b54"), 2.0)

    var sites: Dictionary = _state.get("permanent_sites", {})
    for site in sites.values():
        var depth := int(site.get("depth", 0))
        var x := size.x * 0.70
        var y := _depth_to_y(float(depth))
        if y < -60.0 or y > size.y + 60.0:
            continue
        var active := bool(site.get("active", false))
        var glow := Color("43d7cf") if active else Color("41636a")
        draw_rect(Rect2(x - 25, y - 16, 50, 32), Color("26343b"))
        draw_rect(Rect2(x - 18, y - 9, 15, 7), glow)
        draw_line(Vector2(x + 12, y - 14), Vector2(x + 20, y - 28), Color("77868b"), 2.0)
        draw_circle(Vector2(x + 21, y - 30), 3.0, glow)

func _draw_drill() -> void:
    var depth := int(_state.get("depth", 0))
    var x := size.x * 0.5
    var y := _depth_to_y(float(depth) + 7.0)
    if y < -80.0 or y > size.y + 80.0:
        return
    var active := (_state.get("jobs", {}) as Dictionary).has("drill")
    var body := Color("515e64")
    var copper := Color("c27b43")
    draw_rect(Rect2(x - 37, y - 17, 74, 30), body)
    draw_rect(Rect2(x - 29, y - 10, 21, 10), copper)
    draw_circle(Vector2(x - 23, y + 15), 7.0, Color("20282d"))
    draw_circle(Vector2(x + 23, y + 15), 7.0, Color("20282d"))
    var bit_color := Color("4ee0d5") if active else Color("aeb8bb")
    draw_line(Vector2(x, y + 13), Vector2(x, y + 37), bit_color, 5.0)
    draw_colored_polygon(PackedVector2Array([Vector2(x - 7, y + 35), Vector2(x + 7, y + 35), Vector2(x, y + 49)]), bit_color)
    if active:
        var pulse := 10.0 + sin(_phase() * 7.0) * 3.0
        draw_arc(Vector2(x, y + 45), pulse, 0, TAU, 18, Color("4de2d7"), 2.0)

func _draw_depth_atmosphere() -> void:
    var depth := int(_state.get("depth", 0))
    if depth < 90:
        return
    var strength := accent_strength_for_depth(depth)
    var alpha := 0.05 + strength * 0.07
    draw_rect(Rect2(0, 0, size.x, size.y), Color(0.08, 0.38, 0.40, alpha), false, 2.0)
    var crystal_depths: Array[float] = [98.0, 112.0, 132.0, 154.0]
    var ratios: Array[float] = [0.15, 0.84, 0.28, 0.72]
    for i in range(crystal_depths.size()):
        var y: float = _depth_to_y(crystal_depths[i])
        if y < -30.0 or y > size.y + 30.0:
            continue
        var x: float = size.x * ratios[i]
        _draw_crystal_cluster(Vector2(x, y), strength)

func _draw_crystal_cluster(center: Vector2, strength: float) -> void:
    var glow := Color(0.25, 0.91, 0.86, 0.18 + strength * 0.28)
    draw_circle(center, 17 + 10 * strength, glow)
    var offsets: Array[float] = [-10.0, 0.0, 11.0]
    for offset in offsets:
        var h := 13.0 + absf(offset) * 0.5
        var points := PackedVector2Array([
            center + Vector2(offset - 5, 5),
            center + Vector2(offset, -h),
            center + Vector2(offset + 6, 5),
            center + Vector2(offset, 11),
        ])
        draw_colored_polygon(points, Color("48d9d2"))

func _depth_to_y(depth_value: float) -> float:
    return SURFACE_Y + (depth_value - _scroll_depth()) * PIXELS_PER_METER * _zoom()

func _scroll_depth() -> float:
    return float(_state.get("scroll_depth", 0.0))

func _zoom() -> float:
    return maxf(0.01, float(_state.get("zoom", 1.0)))

func _phase() -> float:
    return float(_state.get("animation_phase", 0.0))
