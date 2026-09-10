class_name VerticalSliceLayout
extends RefCounted

const CONTENT_ID := "cave_v02_helix_01"
const WIDTH := 64
const HEIGHT := 72
const CELL_SIZE := 16
const GATE_POS := Vector2i(32, 44)
const SUPPORT_REMOVAL: Array[Vector2i] = [
    Vector2i(32, 45),
    Vector2i(32, 46),
    Vector2i(32, 47),
    Vector2i(31, 47),
]

func build() -> Dictionary:
    var model := TerrainModel.new(WIDTH, HEIGHT)

    # Anchored outer geology.
    _fill_rect(model, Rect2i(0, 0, 6, HEIGHT), &"rock_dense")
    _fill_rect(model, Rect2i(58, 0, 6, HEIGHT), &"rock_dense")
    _fill_rect(model, Rect2i(6, 0, 52, 4), &"rock_dense")

    # Entrance pocket: stepped common/fragile ledges instead of a flat band.
    _fill_rect(model, Rect2i(6, 8, 12, 3), &"rock_common")
    _fill_rect(model, Rect2i(8, 11, 10, 2), &"rock_common")
    _fill_rect(model, Rect2i(14, 13, 10, 2), &"rock_fragile")
    _fill_rect(model, Rect2i(20, 15, 6, 2), &"rock_common")

    # Left chamber shelves and stabilizer deposit.
    _fill_rect(model, Rect2i(6, 24, 10, 4), &"rock_common")
    _fill_rect(model, Rect2i(10, 28, 9, 3), &"rock_fragile")
    _fill_rect(model, Rect2i(12, 31, 7, 2), &"stabilizer")
    _fill_rect(model, Rect2i(6, 34, 12, 3), &"rock_common")

    # Central chamber framing.
    _fill_rect(model, Rect2i(18, 38, 8, 4), &"rock_common")
    _fill_rect(model, Rect2i(41, 30, 17, 4), &"rock_common")
    _fill_rect(model, Rect2i(44, 34, 14, 3), &"rock_fragile")
    _fill_rect(model, Rect2i(46, 50, 12, 5), &"rock_common")

    # Dense blocking formation and stable side masses.
    _fill_rect(model, Rect2i(26, 40, 5, 32), &"rock_dense")
    _fill_rect(model, Rect2i(34, 40, 7, 32), &"rock_dense")
    _fill_rect(model, Rect2i(29, 39, 7, 3), &"rock_dense")
    model.set_cell(GATE_POS, TerrainCell.new(&"rock_dense"))

    # Canonical removable supports.
    for support_pos in SUPPORT_REMOVAL:
        model.set_cell(support_pos, TerrainCell.new(&"rock_common"))

    # Stable spine and ancient route.
    _fill_rect(model, Rect2i(24, 46, 1, 26), &"rock_dense")
    var relay_source := Vector2i(18, 54)
    var relay_pos := Vector2i(25, 46)
    var ancient_path: Array[Vector2i] = []
    for x in range(18, 26):
        ancient_path.append(Vector2i(x, 54))
    for y in range(53, 45, -1):
        ancient_path.append(Vector2i(25, y))
    for pos in ancient_path:
        model.set_cell(pos, TerrainCell.new(&"stabilizer"))

    # Lower descent framing.
    _fill_rect(model, Rect2i(6, 58, 18, 6), &"rock_common")
    _fill_rect(model, Rect2i(41, 58, 17, 6), &"rock_common")
    _fill_rect(model, Rect2i(8, 64, 16, 8), &"rock_dense")
    _fill_rect(model, Rect2i(41, 64, 17, 8), &"rock_dense")

    return {
        "model": model,
        "relay_source": relay_source,
        "relay_pos": relay_pos,
        "ancient_path": ancient_path,
        "entrance_rect": Rect2i(6, 5, 20, 12),
        "chamber_rect": Rect2i(18, 22, 28, 36),
        "exit_rect": Rect2i(31, 65, 3, 5),
        "spawn_focus": Vector2i(22, 12),
    }

func _fill_rect(model: TerrainModel, rect: Rect2i, material_id: StringName) -> void:
    for y in range(rect.position.y, rect.end.y):
        for x in range(rect.position.x, rect.end.x):
            model.set_cell(Vector2i(x, y), TerrainCell.new(material_id))
