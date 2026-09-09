class_name VerticalSliceLayout
extends RefCounted

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

    # Permanent outer rock keeps the slice visually framed and structurally anchored.
    _fill_rect(model, Rect2i(0, 0, 6, HEIGHT), &"rock_dense")
    _fill_rect(model, Rect2i(58, 0, 6, HEIGHT), &"rock_dense")

    # Entrance: diggable material around rows 4–12, connected to the left wall.
    _fill_rect(model, Rect2i(6, 8, 20, 3), &"rock_common")

    # Friable ceiling around rows 14–24.
    _fill_rect(model, Rect2i(6, 18, 19, 2), &"rock_fragile")

    # Stabilizer vein around columns 12–18, rows 28–35.
    _fill_rect(model, Rect2i(12, 31, 7, 2), &"stabilizer")
    _fill_rect(model, Rect2i(6, 32, 6, 1), &"rock_common")

    # Dense blocking formation. Side masses are anchored to the bottom while a
    # central dense gate blocks the shaft and can only be removed by collapse.
    _fill_rect(model, Rect2i(26, 40, 5, 32), &"rock_dense")
    _fill_rect(model, Rect2i(34, 40, 7, 32), &"rock_dense")
    model.set_cell(GATE_POS, TerrainCell.new(&"rock_dense"))

    # Canonical removable support beneath the gate. The small cantilever at
    # (31,47) is supported by the anchored mass at x=30.
    model.set_cell(Vector2i(32, 45), TerrainCell.new(&"rock_common"))
    model.set_cell(Vector2i(32, 46), TerrainCell.new(&"rock_common"))
    model.set_cell(Vector2i(32, 47), TerrainCell.new(&"rock_common"))
    model.set_cell(Vector2i(31, 47), TerrainCell.new(&"rock_common"))

    # Stable support spine for the ancient network, separate from the gate shaft.
    _fill_rect(model, Rect2i(24, 46, 1, 26), &"rock_dense")

    var relay_source := Vector2i(18, 54)
    var relay_pos := Vector2i(25, 46)
    _fill_rect(model, Rect2i(19, 54, 6, 1), &"stabilizer")
    _fill_rect(model, Rect2i(25, 47, 1, 8), &"stabilizer")

    return {
        "model": model,
        "relay_source": relay_source,
        "relay_pos": relay_pos,
        "exit_rect": Rect2i(31, 65, 3, 5),
        "spawn_focus": Vector2(22 * CELL_SIZE, 9 * CELL_SIZE),
    }

func _fill_rect(model: TerrainModel, rect: Rect2i, material_id: StringName) -> void:
    for y in range(rect.position.y, rect.end.y):
        for x in range(rect.position.x, rect.end.x):
            model.set_cell(Vector2i(x, y), TerrainCell.new(material_id))
