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

static func has_asset(id: String) -> bool:
    return PATHS.has(id) and ResourceLoader.exists(str(PATHS[id]))

static func texture_for(id: String) -> Texture2D:
    if not has_asset(id):
        return null
    return load(str(PATHS[id])) as Texture2D
