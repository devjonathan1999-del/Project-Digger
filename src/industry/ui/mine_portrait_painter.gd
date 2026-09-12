extends RefCounted

const Assets = preload("res://src/industry/ui/mine_final_assets.gd")
const STEEL := Color("56646b")
const AMBER := Color("e8ad59")

static func draw_scene(host: Control, state: Dictionary, chambers: Dictionary) -> void:
    var depth := int(state.get("depth", 0))
    var zoom := maxf(0.01, float(state.get("zoom", 1.0)))
    var phase := float(state.get("animation_phase", 0.0))
    var ground := _y(0.0, state)
    var front := _y(float(depth) + 10.0, state)
    var center := host.size.x * 0.5
    var half := clampf(host.size.x * 0.06, 24.0, 42.0)
    _rock(host, ground, zoom)
    var future_top := clampf(front + 12.0, 0.0, host.size.y)
    host.draw_rect(Rect2(0.0, future_top, host.size.x, host.size.y - future_top), Color(0.01, 0.017, 0.025, 0.24))
    _surface(host, ground)
    _shaft(host, center, half, ground, front, phase)
    for id_value in chambers:
        var id := str(id_value)
        var rect: Rect2 = chambers[id_value]
        if rect.position.y < 26.0 or rect.position.y > host.size.y + 120.0:
            continue
        var crystal: Dictionary = state.get("portrait_crystal", {})
        if id == "crystal_installation" and crystal.is_empty():
            continue
        if id == "copper_installation" and depth < 78:
            _initial_copper(host, rect)
            _plate(host, rect, id, state)
            continue
        var right := id in ["coal_installation", "crystal_installation"]
        var floor_y := rect.position.y + rect.size.y * 0.71
        var edge := rect.position.x + 12.0 if right else rect.end.x - 12.0
        var shaft_edge := center + half if right else center - half
        var reached := floor_y <= front + 30.0
        # Existing mines remain available, with their initial transport network.
        _gallery(host, minf(edge, shaft_edge), maxf(edge, shaft_edge), floor_y, reached)
        var texture := Assets.texture_for(id)
        if texture != null:
            var tint := Color.WHITE
            if id == "crystal_installation" and crystal.get("kind", "") == "site" and not bool(crystal.get("active", false)):
                tint = Color(0.64, 0.69, 0.73)
            host.draw_texture_rect(texture, rect, false, tint)
        _plate(host, rect, id, state)
    _rig(host, center, half, ground, front, phase, state)
    _ruler(host, center + half + 12.0, state)
    _seams(host, state, front)

static func _y(depth: float, state: Dictionary) -> float:
    return 200.0 + (depth - float(state.get("scroll_depth", 0.0))) * 7.0 * maxf(0.01, float(state.get("zoom", 1.0)))

static func _rock(host: Control, ground: float, zoom: float) -> void:
    host.draw_rect(Rect2(Vector2.ZERO, host.size), Color("131b22"))
    var texture := Assets.texture_for("rock")
    if texture == null:
        return
    var tile := host.size.x * zoom
    var start_y := ground - floorf(ground / tile) * tile - tile
    var y := start_y
    while y < host.size.y:
        host.draw_texture_rect(texture, Rect2(0.0, y, tile, tile), false, Color("cbd0d4"))
        if tile < host.size.x:
            host.draw_texture_rect(texture, Rect2(tile, y, tile, tile), false, Color("cbd0d4"))
        y += tile

static func _surface(host: Control, ground: float) -> void:
    var texture := Assets.texture_for("surface")
    if texture == null:
        return
    var height := host.size.x * texture.get_height() / float(texture.get_width())
    if ground < -height or ground - height > host.size.y:
        return
    if ground > height:
        host.draw_texture_rect_region(texture, Rect2(0.0, 0.0, host.size.x, ground - height), Rect2(0.0, 0.0, texture.get_width(), 4.0))
    host.draw_texture_rect(texture, Rect2(0.0, ground - height, host.size.x, height), false)
    host.draw_line(Vector2(0.0, ground), Vector2(host.size.x, ground), Color("7d7668"), 3.0)

static func _shaft(host: Control, center: float, half: float, top: float, bottom: float, phase: float) -> void:
    if bottom <= top:
        return
    var start := maxf(-20.0, top)
    var end := minf(host.size.y + 20.0, bottom)
    if end <= start:
        return
    host.draw_rect(Rect2(center - half - 4.0, start, half * 2.0 + 8.0, end - start), Color("0b1015"))
    var sleeve := Assets.texture_for("shaft")
    if sleeve == null:
        return
    var tile_height := half * 2.0 * sleeve.get_height() / float(sleeve.get_width())
    var y := top + floorf((start - top) / tile_height) * tile_height
    while y < end:
        var draw_top := maxf(start, y)
        var draw_height := minf(end, y + tile_height) - draw_top
        if draw_height > 0.0:
            var source := Rect2(0.0, (draw_top - y) / tile_height * sleeve.get_height(), sleeve.get_width(), draw_height / tile_height * sleeve.get_height())
            host.draw_texture_rect_region(sleeve, Rect2(center - half, draw_top, half * 2.0, draw_height), source)
        y += tile_height
    var elevator := Assets.texture_for("elevator")
    if elevator != null and bottom - top > 125.0:
        var travel := (sin(phase * 0.45) + 1.0) * 0.5
        var elevator_y := lerpf(top + 58.0, maxf(top + 58.0, bottom - 175.0), travel)
        var width := half * 1.2
        var height := width * elevator.get_height() / float(elevator.get_width())
        host.draw_texture_rect(elevator, Rect2(center - width * 0.5, elevator_y, width, height), false)

static func _gallery(host: Control, left: float, right: float, y: float, reached: bool) -> void:
    var color := Color("b38b50") if reached else Color("63706d")
    host.draw_rect(Rect2(left, y - 26.0, right - left, 32.0), Color("0d1317"))
    host.draw_line(Vector2(left, y), Vector2(right, y), STEEL, 4.0)
    host.draw_line(Vector2(left, y - 22.0), Vector2(right, y - 22.0), color, 1.5)
    var x := left + 5.0
    while x < right:
        host.draw_line(Vector2(x, y - 22.0), Vector2(x, y), color, 1.5)
        x += 20.0

static func _plate(host: Control, rect: Rect2, id: String, state: Dictionary) -> void:
    var labels := {"iron_installation": "FER", "coal_installation": "CHARBON", "copper_installation": "CUIVRE", "crystal_installation": "CRISTAL"}
    var right := id in ["coal_installation", "crystal_installation"]
    var width := minf(156.0, rect.size.x - 16.0)
    var position := Vector2(rect.end.x - width - 12.0 if right else rect.position.x + 12.0, rect.end.y - 36.0)
    var plate := Rect2(position, Vector2(width, 44.0))
    host.draw_style_box(_box(), plate)
    var initial := int(state.get("depth", 0)) < int({"iron_installation": 22, "coal_installation": 50, "copper_installation": 78}.get(id, 0))
    host.draw_string(ThemeDB.fallback_font, position + Vector2(10.0, 18.0), str(labels.get(id, id)), HORIZONTAL_ALIGNMENT_LEFT, width - 20.0, 14, Color("e9e5d9"))
    var rates: Dictionary = state.get("mine_rates", {})
    var resource_id := id.trim_suffix("_installation")
    var caption := "Réseau initial" if initial else ("+ %.1f / min" % (float(rates.get(resource_id, 0.0)) * 60.0) if rates.has(resource_id) else "Extraction active")
    if id == "crystal_installation":
        var crystal: Dictionary = state.get("portrait_crystal", {})
        if crystal.get("kind", "") == "site":
            caption = "+ %.1f / min" % (float(crystal.get("rate", 0.0)) * 60.0) if bool(crystal.get("active", false)) else "En veille"
        else:
            caption = "Exploration…" if crystal.get("state", "") == "exploring" else "Gisement repéré"
    host.draw_string(ThemeDB.fallback_font, position + Vector2(10.0, 34.0), caption, HORIZONTAL_ALIGNMENT_LEFT, width - 20.0, 11, Color("b7c1c3") if initial else AMBER)

static func _rig(host: Control, center: float, half: float, _ground: float, front: float, phase: float, state: Dictionary) -> void:
    var texture := Assets.texture_for("drill")
    if texture == null:
        return
    var width := half * 1.6
    var height := width * texture.get_height() / float(texture.get_width())
    var active: bool = (state.get("jobs", {}) as Dictionary).has("drill")
    var bob := sin(phase * 15.0) * 1.2 if active else 0.0
    var rect := Rect2(center - width * 0.5, front - height + bob, width, height)
    if rect.end.y < -50.0 or rect.position.y > host.size.y:
        return
    host.draw_circle(Vector2(center, front - 20.0), 38.0, Color(0.9, 0.55, 0.20, 0.07))
    host.draw_texture_rect(texture, rect, false)
    for index in range(7):
        var x := center - half + float(index) * half * 2.0 / 7.0
        host.draw_line(Vector2(x, front + 3.0), Vector2(x + 6.0, front + 9.0), AMBER, 3.0)
    var plate := Rect2(center - 58.0, front + 14.0, 116.0, 44.0)
    host.draw_style_box(_box(), plate)
    host.draw_string(ThemeDB.fallback_font, plate.position + Vector2(8.0, 18.0), "FOREUSE", HORIZONTAL_ALIGNMENT_CENTER, 100.0, 14, Color("e9e5d9"))
    var depth := int(state.get("depth", 0))
    var caption := "Palier %d m" % ((depth / 30 + 1) * 30) if depth < 150 else "À explorer"
    host.draw_string(ThemeDB.fallback_font, plate.position + Vector2(8.0, 34.0), caption, HORIZONTAL_ALIGNMENT_CENTER, 100.0, 12, AMBER)

static func _ruler(host: Control, x: float, state: Dictionary) -> void:
    var scroll := float(state.get("scroll_depth", 0.0))
    var zoom := maxf(0.01, float(state.get("zoom", 1.0)))
    var end_depth := scroll + host.size.y / (7.0 * zoom)
    host.draw_line(Vector2(x, maxf(0.0, _y(0.0, state))), Vector2(x, host.size.y), Color(0.64, 0.70, 0.72, 0.40), 1.0)
    for depth in range(maxi(0, int(scroll / 5.0) * 5), int(end_depth) + 5, 5):
        var y := _y(float(depth), state)
        if y < 12.0 or y > host.size.y - 12.0:
            continue
        var major := depth % 30 == 0
        host.draw_line(Vector2(x - 4.0, y), Vector2(x + (10.0 if major else 3.0), y), Color("8a989e"), 1.0)
        if major:
            host.draw_string(ThemeDB.fallback_font, Vector2(x + 14.0, y + 5.0), "%d m" % depth, HORIZONTAL_ALIGNMENT_LEFT, 55.0, 13, Color("c1cacd"))

static func _seams(host: Control, state: Dictionary, front: float) -> void:
    for index in range(3):
        var y := _y(96.0 + float(index) * 38.0, state)
        if y < front + 80.0 or y > host.size.y - 20.0:
            continue
        var x := host.size.x * (0.80 if index % 2 == 0 else 0.20)
        var texture := Assets.texture_for("cyan_seam" if index % 2 == 0 else "copper_seam")
        if texture != null:
            var width := minf(210.0, host.size.x * 0.30)
            var height := width * texture.get_height() / float(texture.get_width())
            host.draw_texture_rect(texture, Rect2(x - width * 0.5, y - height * 0.5, width, height), false, Color(0.65, 0.70, 0.74, 0.70))

static func _initial_copper(host: Control, rect: Rect2) -> void:
    var texture := Assets.texture_for("copper_seam")
    if texture == null:
        return
    var width := rect.size.x - 24.0
    var height := width * texture.get_height() / float(texture.get_width())
    host.draw_texture_rect(texture, Rect2(rect.get_center() - Vector2(width, height) * 0.5, Vector2(width, height)), false, Color(0.82, 0.78, 0.72))

static func _box() -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = Color(0.025, 0.048, 0.063, 0.95)
    box.border_color = Color("5c6b6f")
    box.set_border_width_all(1)
    box.set_corner_radius_all(4)
    return box
