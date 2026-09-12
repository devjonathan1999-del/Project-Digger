class_name MineV07Assets
extends RefCounted

const ATLAS_PATH := "res://assets/industry/v07/mine_assets_atlas.png"

const REGIONS := {
    "surface_workshop": Rect2(0, 32, 256, 192),
    "surface_silo": Rect2(256, 32, 256, 192),
    "surface_ventilation": Rect2(512, 32, 256, 192),
    "surface_crane": Rect2(768, 32, 256, 192),
    "shaft_station": Rect2(0, 312, 256, 144),
    "shaft_elevator": Rect2(288, 256, 192, 256),
    "iron_installation": Rect2(512, 312, 256, 144),
    "coal_installation": Rect2(768, 312, 256, 144),
    "copper_installation": Rect2(0, 568, 256, 144),
    "crystal_installation": Rect2(256, 568, 256, 144),
}

static var _atlas: Texture2D
static var _cache: Dictionary = {}

static func has_asset(id: String) -> bool:
    return REGIONS.has(id) and ResourceLoader.exists(ATLAS_PATH)

static func texture_for(id: String) -> Texture2D:
    if not has_asset(id):
        return null
    if _cache.has(id):
        return _cache[id] as Texture2D
    if _atlas == null:
        _atlas = load(ATLAS_PATH) as Texture2D
    if _atlas == null:
        return null

    var texture := AtlasTexture.new()
    texture.atlas = _atlas
    texture.region = REGIONS[id] as Rect2
    _cache[id] = texture
    return texture
