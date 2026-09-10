class_name VerticalSliceLayout
extends RefCounted

const CONTENT_ID := "cave_v02_helix_02"
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

    # Anchored outer geology. The cave now reads as negative space cut through
    # a continuous mass rather than as isolated platforms floating in a box.
    _fill_rect(model, Rect2i(0, 0, 6, HEIGHT), &"rock_dense")
    _fill_rect(model, Rect2i(58, 0, 6, HEIGHT), &"rock_dense")
    _fill_rect(model, Rect2i(6, 0, 52, 4), &"rock_dense")

    # Broad irregular shoulders grow inward from the side walls. They remain
    # far from the canonical gate puzzle, so presentation gains density without
    # changing the intended stability solution.
    _fill_rect(model, Rect2i(6, 4, 7, 7), &"rock_dense")
    _fill_rect(model, Rect2i(6, 17, 5, 7), &"rock_dense")
    _fill_rect(model, Rect2i(6, 37, 7, 12), &"rock_dense")
    _fill_rect(model, Rect2i(6, 49, 4, 9), &"rock_dense")
    _fill_rect(model, Rect2i(53, 4, 5, 26), &"rock_dense")
    _fill_rect(model, Rect2i(51, 37, 7, 13), &"rock_dense")
    _fill_rect(model, Rect2i(54, 50, 4, 8), &"rock_dense")
    _carve_cells(model, [
        Vector2i(12, 4), Vector2i(12, 5), Vector2i(11, 6), Vector2i(12, 10),
        Vector2i(10, 17), Vector2i(10, 18), Vector2i(9, 23), Vector2i(10, 23),
        Vector2i(12, 37), Vector2i(12, 38), Vector2i(11, 39), Vector2i(12, 42),
        Vector2i(12, 46), Vector2i(11, 48), Vector2i(9, 49), Vector2i(9, 50),
        Vector2i(53, 4), Vector2i(53, 5), Vector2i(54, 8), Vector2i(53, 12),
        Vector2i(53, 17), Vector2i(54, 23), Vector2i(53, 28), Vector2i(53, 29),
        Vector2i(51, 37), Vector2i(51, 38), Vector2i(52, 41), Vector2i(51, 47),
        Vector2i(54, 50), Vector2i(54, 51), Vector2i(55, 56), Vector2i(54, 57),
    ])

    # Entrance pocket: overlapping, hand-eroded shelves descend from the left
    # shoulder and teach the material language without reading as a flat band.
    _fill_rect(model, Rect2i(6, 8, 12, 3), &"rock_common")
    _fill_rect(model, Rect2i(8, 11, 10, 2), &"rock_common")
    _fill_rect(model, Rect2i(14, 13, 10, 2), &"rock_fragile")
    _fill_rect(model, Rect2i(20, 15, 6, 2), &"rock_common")
    _carve_cells(model, [
        Vector2i(6, 8), Vector2i(7, 8), Vector2i(16, 8), Vector2i(17, 8),
        Vector2i(6, 10), Vector2i(17, 10),
        Vector2i(8, 11), Vector2i(17, 11), Vector2i(8, 12), Vector2i(9, 12), Vector2i(16, 12),
        Vector2i(14, 13), Vector2i(23, 13), Vector2i(14, 14), Vector2i(15, 14), Vector2i(22, 14),
        Vector2i(20, 15), Vector2i(25, 15), Vector2i(20, 16), Vector2i(24, 16), Vector2i(25, 16),
    ])

    # Left chamber shelves and stabilizer deposit.
    _fill_rect(model, Rect2i(6, 24, 10, 4), &"rock_common")
    _fill_rect(model, Rect2i(10, 28, 9, 3), &"rock_fragile")
    _fill_rect(model, Rect2i(12, 31, 7, 2), &"stabilizer")
    _fill_rect(model, Rect2i(6, 34, 12, 3), &"rock_common")
    _carve_cells(model, [
        Vector2i(6, 24), Vector2i(7, 24), Vector2i(15, 24), Vector2i(6, 27), Vector2i(15, 27),
        Vector2i(10, 28), Vector2i(18, 28), Vector2i(10, 30), Vector2i(11, 30), Vector2i(17, 30),
        Vector2i(12, 31), Vector2i(18, 31), Vector2i(12, 32), Vector2i(17, 32), Vector2i(18, 32),
        Vector2i(6, 34), Vector2i(7, 34), Vector2i(17, 34), Vector2i(6, 36), Vector2i(16, 36), Vector2i(17, 36),
    ])

    # Central chamber framing. Broad shelves emerge from surrounding geology
    # while asymmetric cuts keep their silhouette readable and non-rectangular.
    _fill_rect(model, Rect2i(18, 38, 8, 4), &"rock_common")
    _fill_rect(model, Rect2i(41, 30, 17, 4), &"rock_common")
    _fill_rect(model, Rect2i(44, 34, 14, 3), &"rock_fragile")
    _fill_rect(model, Rect2i(46, 50, 12, 5), &"rock_common")
    _carve_cells(model, [
        Vector2i(18, 38), Vector2i(19, 38), Vector2i(25, 38), Vector2i(18, 41), Vector2i(24, 41), Vector2i(25, 41),
        Vector2i(41, 30), Vector2i(42, 30), Vector2i(56, 30), Vector2i(57, 30), Vector2i(41, 33), Vector2i(57, 33),
        Vector2i(44, 34), Vector2i(45, 34), Vector2i(57, 34), Vector2i(44, 36), Vector2i(56, 36), Vector2i(57, 36),
        Vector2i(46, 50), Vector2i(47, 50), Vector2i(57, 50), Vector2i(46, 54), Vector2i(56, 54), Vector2i(57, 54),
    ])

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
    _carve_cells(model, [
        Vector2i(6, 58), Vector2i(7, 58), Vector2i(22, 58), Vector2i(23, 58), Vector2i(6, 63), Vector2i(23, 63),
        Vector2i(41, 58), Vector2i(42, 58), Vector2i(56, 58), Vector2i(57, 58), Vector2i(41, 63), Vector2i(57, 63),
        Vector2i(8, 64), Vector2i(9, 64), Vector2i(22, 64), Vector2i(23, 64),
        Vector2i(41, 64), Vector2i(42, 64), Vector2i(56, 64), Vector2i(57, 64),
    ])

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

func _carve_cells(model: TerrainModel, cells: Array[Vector2i]) -> void:
    for pos in cells:
        model.set_cell(pos, null)
