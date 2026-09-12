class_name MineV06Assets
extends RefCounted

const PATHS := {
    "surface_workshop": "res://assets/industry/v06/surface_workshop.svg",
    "surface_silo": "res://assets/industry/v06/surface_silo.png",
    "surface_control": "res://assets/industry/v06/surface_control.png",
    "surface_ventilation": "res://assets/industry/v06/surface_ventilation.png",
    "surface_crane": "res://assets/industry/v06/surface_crane.png",
    "shaft_station": "res://assets/industry/v06/shaft_station.png",
    "iron_module": "res://assets/industry/v06/iron_module.png",
    "coal_module": "res://assets/industry/v06/coal_module.png",
    "copper_module": "res://assets/industry/v06/copper_module.png",
    "crystal_module": "res://assets/industry/v06/crystal_module.png",
}

static var _texture_cache: Dictionary = {}

static func has_asset(id: String) -> bool:
    return PATHS.has(id) and ResourceLoader.exists(str(PATHS[id]))

static func texture_for(id: String) -> Texture2D:
    if not has_asset(id):
        return null
    if _texture_cache.has(id):
        return _texture_cache[id] as Texture2D

    var source := load(str(PATHS[id])) as Texture2D
    if source == null:
        return null
    var image := source.get_image()
    if image == null or image.is_empty():
        _texture_cache[id] = source
        return source

    _fade_neutral_white_to_alpha(image)
    var processed := ImageTexture.create_from_image(image)
    _texture_cache[id] = processed
    return processed

static func _fade_neutral_white_to_alpha(image: Image) -> void:
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            var pixel := image.get_pixel(x, y)
            if pixel.a <= 0.0:
                continue
            var minimum := minf(pixel.r, minf(pixel.g, pixel.b))
            var maximum := maxf(pixel.r, maxf(pixel.g, pixel.b))
            if minimum < 0.90 or maximum - minimum > 0.08:
                continue
            var alpha_scale := clampf((0.985 - minimum) / 0.085, 0.0, 1.0)
            pixel.a *= alpha_scale
            image.set_pixel(x, y, pixel)
