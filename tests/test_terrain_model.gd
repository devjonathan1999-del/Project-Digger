extends RefCounted

func run(t: TestSupport) -> void:
    test_snapshot_round_trip(t)
    test_bounds(t)

func test_snapshot_round_trip(t: TestSupport) -> void:
    var model = preload("res://src/terrain/terrain_model.gd").new(4, 4)
    var cell = preload("res://src/terrain/terrain_cell.gd").new(&"rock_common")
    model.set_cell(Vector2i(1, 2), cell)
    var copy = model.snapshot()
    model.set_cell(Vector2i(1, 2), null)
    model.restore(copy)
    t.equal(model.get_cell(Vector2i(1, 2)).material_id, &"rock_common", "snapshot restaure la cellule")

func test_bounds(t: TestSupport) -> void:
    var model = preload("res://src/terrain/terrain_model.gd").new(2, 2)
    t.equal(model.get_cell(Vector2i(-1, 0)), null, "lecture hors limites renvoie null")
    t.equal(model.set_cell(Vector2i(2, 0), preload("res://src/terrain/terrain_cell.gd").new(&"rock_common")), false, "écriture hors limites refusée")
