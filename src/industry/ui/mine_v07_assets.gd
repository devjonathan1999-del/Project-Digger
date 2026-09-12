class_name MineV07Assets
extends RefCounted

const PAYLOAD_PARTS := [
    "res://assets/industry/v07/payload/part01.b64",
    "res://assets/industry/v07/payload/part02.b64",
    "res://assets/industry/v07/payload/part03.b64",
    "res://assets/industry/v07/payload/part03b.b64",
    "res://assets/industry/v07/payload/part04.b64",
    "res://assets/industry/v07/payload/part05.b64",
]

const REGIONS := {
    "surface_workshop": Rect2(0, 16, 128, 96),
    "surface_silo": Rect2(128, 16, 128, 96),
    "surface_ventilation": Rect2(256, 16, 128, 96),
    "surface_crane": Rect2(384, 16, 128, 96),
    "shaft_station": Rect2(0, 156, 128, 72),
    "shaft_elevator": Rect2(144, 128, 96, 128),
    "iron_installation": Rect2(256, 156, 128, 72),
    "coal_installation": Rect2(384, 156, 128, 72),
    "copper_installation": Rect2(0, 284, 128, 72),
    "crystal_installation": Rect2(128, 284, 128, 72),
}

static var _atlas: Texture2D
static var _cache: Dictionary = {}

static func has_asset(id: String) -> bool:
    if not REGIONS.has(id):
        return false
    for path_value in PAYLOAD_PARTS:
        if not FileAccess.file_exists(str(path_value)):
            return false
    return true

static func texture_for(id: String) -> Texture2D:
    if not has_asset(id):
        return null
    if _cache.has(id):
        return _cache[id] as Texture2D
    if _atlas == null:
        _atlas = _load_atlas()
    if _atlas == null:
        return null

    var texture := AtlasTexture.new()
    texture.atlas = _atlas
    texture.region = REGIONS[id] as Rect2
    _cache[id] = texture
    return texture

static func _load_atlas() -> Texture2D:
    var encoded := ""
    for path_value in PAYLOAD_PARTS:
        encoded += FileAccess.get_file_as_string(str(path_value)).strip_edges()
    var png_bytes := Marshalls.base64_to_raw(encoded)
    if png_bytes.is_empty():
        push_error("v0.7 asset payload decoded to an empty buffer")
        return null
    var image := Image.new()
    var error := image.load_png_from_buffer(png_bytes)
    if error != OK or image.is_empty():
        push_error("v0.7 asset atlas could not be decoded: %s" % error_string(error))
        return null
    return ImageTexture.create_from_image(image)
