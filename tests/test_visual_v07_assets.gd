extends SceneTree

const Assets = preload("res://src/industry/ui/mine_v07_assets.gd")
const REQUIRED := [
    "surface_workshop",
    "surface_silo",
    "surface_ventilation",
    "surface_crane",
    "shaft_station",
    "shaft_elevator",
    "iron_installation",
    "coal_installation",
    "copper_installation",
    "crystal_installation",
]

func _init() -> void:
    var failures := 0
    for id in REQUIRED:
        if not Assets.has_asset(id):
            push_error("missing v0.7 asset: %s" % id)
            failures += 1
            continue
        var texture := Assets.texture_for(id)
        if texture == null:
            push_error("asset did not load: %s" % id)
            failures += 1
            continue
        var image := texture.get_image()
        if image == null or image.is_empty():
            push_error("asset image empty: %s" % id)
            failures += 1
            continue
        if image.get_width() <= 0 or image.get_height() <= 0:
            push_error("asset dimensions invalid: %s" % id)
            failures += 1
            continue
        var corners := [
            image.get_pixel(0, 0).a,
            image.get_pixel(image.get_width() - 1, 0).a,
            image.get_pixel(0, image.get_height() - 1).a,
            image.get_pixel(image.get_width() - 1, image.get_height() - 1).a,
        ]
        if corners.min() > 0.08:
            push_error("asset lacks transparent corner: %s" % id)
            failures += 1
    quit(1 if failures > 0 else 0)
