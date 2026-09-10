class_name TerrainVisualProfile
extends RefCounted

enum Edge { TOP, RIGHT, BOTTOM, LEFT }

static func base_color(material_id: StringName) -> Color:
    match material_id:
        &"rock_common":
            return Color("#626b75")
        &"rock_fragile":
            return Color("#8b715c")
        &"rock_dense":
            return Color("#303944")
        &"stabilizer":
            return Color("#249b9a")
        _:
            return Color("#686d73")

static func detail_color(material_id: StringName) -> Color:
    match material_id:
        &"rock_common":
            return Color("#7a838d")
        &"rock_fragile":
            return Color("#b28a67")
        &"rock_dense":
            return Color("#46515d")
        &"stabilizer":
            return Color("#68e2dc")
        _:
            return Color("#80858a")

static func display_name(material_id: StringName) -> String:
    match material_id:
        &"rock_common":
            return "Roche commune"
        &"rock_fragile":
            return "Roche fragile"
        &"rock_dense":
            return "Roche dense"
        &"stabilizer":
            return "Minerai stabilisateur"
        _:
            return "Matière inconnue"

static func edge_inset(pos: Vector2i, edge: int) -> float:
    return float(_key(pos, edge + 17) % 4)

static func detail_variant(pos: Vector2i, material_id: StringName) -> int:
    return _key(pos, _material_salt(material_id)) % 4

static func _material_salt(material_id: StringName) -> int:
    match material_id:
        &"rock_common":
            return 11
        &"rock_fragile":
            return 23
        &"rock_dense":
            return 37
        &"stabilizer":
            return 53
        _:
            return 71

static func _key(pos: Vector2i, salt: int) -> int:
    var value := pos.x * 73856093
    value = value ^ (pos.y * 19349663)
    value = value ^ (salt * 83492791)
    return absi(value)
