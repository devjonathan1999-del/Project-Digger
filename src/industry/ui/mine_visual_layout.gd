class_name MineVisualLayout
extends RefCounted

const GALLERY_VARIANTS := [
    "standard",
    "narrow",
    "wide",
    "collapsed",
    "alcove",
    "dead_end",
]

static func _key(depth: int, side: int) -> int:
    var safe_depth := absi(depth)
    var band := safe_depth / 10
    return absi(safe_depth * 31 + side * 17 + band * 13 + (safe_depth % 23) * 7)

static func gallery_profile(depth: int, side: int, _total_depth: int, _center_level: int) -> Dictionary:
    var key := _key(depth, side)
    var variant: String = GALLERY_VARIANTS[key % GALLERY_VARIANTS.size()]
    var profile: Dictionary = {
        "variant": variant,
        "width_scale": 0.72 + float((key / 3) % 5) * 0.06,
        "height": 44.0 + float((key / 7) % 4) * 6.0,
        "support_spacing": 44 + (key % 4) * 8,
        "lamp_stride": 1 + (key % 3),
        "rail_break_start": -1.0,
        "rail_break_end": -1.0,
        "alcove_side": -1,
        "machine_count": 1 + (key % 2),
        "pipe_count": 1 + ((key / 5) % 2),
    }

    match variant:
        "narrow":
            profile["height"] = 36.0
            profile["width_scale"] = minf(float(profile["width_scale"]), 0.78)
            profile["support_spacing"] = 40
            profile["lamp_stride"] = 1
        "wide":
            profile["height"] = 68.0
            profile["width_scale"] = 1.0
            profile["machine_count"] = 2 + (key % 2)
        "collapsed":
            profile["rail_break_start"] = 0.48
            profile["rail_break_end"] = 0.68
            profile["machine_count"] = 0
        "alcove":
            profile["alcove_side"] = key % 2
            profile["width_scale"] = minf(0.94, float(profile["width_scale"]) + 0.06)
        "dead_end":
            profile["width_scale"] = 0.52 + float(key % 3) * 0.05
            profile["pipe_count"] = 0

    return profile

static func geology_profile(depth: int) -> Dictionary:
    var band := maxi(0, depth / 30)
    var cyan_strength := 0.04
    if depth >= 150:
        cyan_strength = 0.70
    elif depth >= 120:
        cyan_strength = 0.50
    elif depth >= 90:
        cyan_strength = 0.30
    elif depth >= 60:
        cyan_strength = 0.12

    return {
        "cyan_strength": cyan_strength,
        "fracture_count": 2 + mini(band, 5),
        "strata_count": 3 + mini(band, 4),
        "rock_block_count": 2 + mini(band, 4),
        "cavity_count": 0 if depth < 60 else 1 + mini((depth - 60) / 60, 2),
        "mineral_inclusion_count": 1 + mini(band, 4),
    }

static func surface_profile(center_level: int) -> Dictionary:
    var level := clampi(center_level, 1, 6)
    var modules: Array[String] = [
        "headframe",
        "workshop",
        "silo",
        "operations",
    ]
    if level >= 2:
        modules.append("ventilation")
    if level >= 4:
        modules.append("crane")
    if level >= 5:
        modules.append("antenna")
    if level >= 6:
        modules.append("pipe_network")

    return {
        "modules": modules,
        "center_level": level,
        "light_count": 2 + level,
        "service_density": 0.35 + float(level - 1) * 0.10,
    }
