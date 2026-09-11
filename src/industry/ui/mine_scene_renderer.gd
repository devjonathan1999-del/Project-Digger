class_name MineSceneRenderer
extends Control

const Style = preload("res://src/industry/ui/industry_theme.gd")
const Layout = preload("res://src/industry/ui/mine_visual_layout.gd")

const PIXELS_PER_METER := 7.0
const SURFACE_Y := 72.0
const GALLERY_HORIZONS := [12, 30, 60, 90, 120, 150]

var surface_module_count := 0
var gallery_detail_count := 0
var deep_accent_strength := 0.0
var gallery_variants_seen: Dictionary = {}
var gallery_silhouette_count := 0
var broken_rail_count := 0
var alcove_count := 0

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
    _update_gallery_metrics(depth, center_level)
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

func _update_gallery_metrics(depth: int, center_level: int) -> void:
    gallery_variants_seen.clear()
    gallery_silhouette_count = 0
    broken_rail_count = 0
    alcove_count = 0
    for horizon in GALLERY_HORIZONS:
        if horizon > depth + 15:
            continue
        for side in [0, 1]:
            var profile: Dictionary = Layout.gallery_profile(horizon, side, depth, center_level)
            var variant := str(profile["variant"])
            gallery_variants_seen[variant] = true
            gallery_silhouette_count += 1
            if float(profile["rail_break_start"]) >= 0.0:
                broken_rail_count += 1
            if int(profile["alcove_side"]) >= 0:
                alcove_count += 1

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
    for depth_value in GALLERY_HORIZONS:
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
    var total_depth := int(_state.get("depth", 0))
    var center_level := int(_state.get("center_level", 1))
    var left_profile: Dictionary = Layout.gallery_profile(int(depth_value), 0, total_depth, center_level)
    var right_profile: Dictionary = Layout.gallery_profile(int(depth_value), 1, total_depth, center_level)
    _draw_gallery_side_profile(left_start, left_end, y, false, accent, left_profile)
    _draw_gallery_side_profile(right_start, right_end, y, true, accent, right_profile)

func _draw_gallery_side_profile(start_x: float, end_x: float, y: float, mirrored: bool, accent: float, profile: Dictionary) -> void:
    var base_length := end_x - start_x
    var width_scale := clampf(float(profile["width_scale"]), 0.45, 1.0)
    var effective_start := start_x
    var effective_end := end_x
    if mirrored:
        effective_end = start_x + base_length * width_scale
    else:
        effective_start = end_x - base_length * width_scale

    var gallery_height := clampf(float(profile["height"]), 34.0, 76.0)
    var cavity_top := y - gallery_height * 0.5
    var cavity := Color("11191f")
    draw_rect(Rect2(effective_start, cavity_top, effective_end - effective_start, gallery_height), cavity)

    var variant := str(profile["variant"])
    if variant == "alcove":
        _draw_alcove(effective_start, effective_end, y, mirrored, gallery_height)
    elif variant == "collapsed":
        _draw_collapse(effective_start, effective_end, y, mirrored)
    elif variant == "dead_end":
        _draw_dead_end(effective_start, effective_end, y, mirrored, gallery_height)
    elif variant == "wide":
        _draw_storage(effective_start, effective_end, y, mirrored)

    var steel := Color("68767c")
    var amber := Color("d49a54")
    var cyan := Color(0.25, 0.86, 0.82, accent)
    var support_spacing := maxi(40, int(profile["support_spacing"]))
    var lamp_stride := maxi(1, int(profile["lamp_stride"]))
    var support_index := 0
    for support_x in range(int(effective_start) + 18, int(effective_end), support_spacing):
        var roof_y := cavity_top + 4.0
        draw_line(Vector2(support_x, roof_y), Vector2(support_x, y + gallery_height * 0.42), steel, 2.0)
        draw_line(Vector2(support_x - 8, roof_y), Vector2(support_x + 8, roof_y), steel, 2.0)
        if support_index % lamp_stride == 0:
            draw_circle(Vector2(support_x, roof_y + 7.0), 3.0, amber)
        support_index += 1

    _draw_profile_rails(effective_start, effective_end, y, profile)

    var pipe_count := maxi(0, int(profile["pipe_count"]))
    for pipe_index in range(pipe_count):
        var pipe_y := y - 8.0 - pipe_index * 6.0
        draw_line(Vector2(effective_start + 10, pipe_y), Vector2(effective_end - 10, pipe_y), Color("9a613a"), 3.0)
    if accent > 0.15:
        draw_line(Vector2(effective_start + 18, y + 6), Vector2(effective_end - 18, y + 6), cyan, 1.5)

    var machine_count := maxi(0, int(profile["machine_count"]))
    for machine_index in range(machine_count):
        var offset := float(machine_index) * 38.0
        var machine_x := effective_end - 46.0 - offset if not mirrored else effective_start + 16.0 + offset
        if machine_x < effective_start + 4.0 or machine_x + 32.0 > effective_end - 4.0:
            continue
        draw_rect(Rect2(machine_x, y - 4, 32, 18), Color("3d4a51"))
        draw_rect(Rect2(machine_x + 5, y + 1, 9, 5), amber)

func _draw_profile_rails(start_x: float, end_x: float, y: float, profile: Dictionary) -> void:
    var steel := Color("68767c")
    var dark := Color("37434a")
    var break_start := float(profile["rail_break_start"])
    var break_end := float(profile["rail_break_end"])
    if break_start < 0.0 or break_end <= break_start:
        draw_line(Vector2(start_x, y + 14), Vector2(end_x, y + 14), steel, 3.0)
        draw_line(Vector2(start_x, y + 19), Vector2(end_x, y + 19), dark, 2.0)
        return

    var gap_start := lerpf(start_x, end_x, clampf(break_start, 0.0, 1.0))
    var gap_end := lerpf(start_x, end_x, clampf(break_end, 0.0, 1.0))
    for rail_y in [y + 14.0, y + 19.0]:
        var color := steel if rail_y < y + 18.0 else dark
        var line_width := 3.0 if rail_y < y + 18.0 else 2.0
        draw_line(Vector2(start_x, rail_y), Vector2(gap_start, rail_y), color, line_width)
        draw_line(Vector2(gap_end, rail_y), Vector2(end_x, rail_y), color, line_width)

func _draw_collapse(start_x: float, end_x: float, y: float, mirrored: bool) -> void:
    var center_x := lerpf(start_x, end_x, 0.58 if not mirrored else 0.42)
    var rock := Color("4a4745")
    draw_circle(Vector2(center_x - 11, y + 8), 11.0, rock)
    draw_circle(Vector2(center_x + 2, y + 6), 14.0, Color("55504c"))
    draw_circle(Vector2(center_x + 15, y + 11), 9.0, Color("423f3d"))

func _draw_alcove(start_x: float, end_x: float, y: float, mirrored: bool, gallery_height: float) -> void:
    var width := minf(64.0, (end_x - start_x) * 0.30)
    var alcove_x := end_x - width if not mirrored else start_x
    draw_rect(Rect2(alcove_x, y - gallery_height * 0.72, width, gallery_height * 0.28), Color("0b141a"))
    draw_line(Vector2(alcove_x + 6, y - gallery_height * 0.45), Vector2(alcove_x + width - 6, y - gallery_height * 0.45), Color("596970"), 2.0)

func _draw_dead_end(start_x: float, end_x: float, y: float, mirrored: bool, gallery_height: float) -> void:
    var face_x := end_x - 5.0 if mirrored else start_x + 5.0
    var rock := Color("4b4946")
    draw_line(Vector2(face_x, y - gallery_height * 0.42), Vector2(face_x, y + gallery_height * 0.42), rock, 8.0)
    draw_circle(Vector2(face_x + (-6.0 if mirrored else 6.0), y + 10), 9.0, Color("55514d"))

func _draw_storage(start_x: float, end_x: float, y: float, mirrored: bool) -> void:
    var x := end_x - 86.0 if not mirrored else start_x + 48.0
    if x < start_x + 4.0 or x + 34.0 > end_x - 4.0:
        return
    draw_rect(Rect2(x, y - 25, 34, 16), Color("48545a"))
    draw_rect(Rect2(x + 5, y - 20, 24, 3), Color("b97842"))

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
