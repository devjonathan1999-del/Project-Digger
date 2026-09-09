extends RefCounted

func run(t: TestSupport) -> void:
    test_valid_and_invalid_dig(t)
    test_move(t)
    test_fuse(t)
    test_undo_and_cancel(t)

func _model_with_cell(pos: Vector2i, material_id: StringName) -> TerrainModel:
    var model := preload("res://src/terrain/terrain_model.gd").new(5, 5)
    model.set_cell(pos, preload("res://src/terrain/terrain_cell.gd").new(material_id))
    return model

func test_valid_and_invalid_dig(t: TestSupport) -> void:
    var actions := preload("res://src/terrain/terrain_actions.gd").new()
    var common := _model_with_cell(Vector2i(1, 1), &"rock_common")
    actions.begin_prepare(common, 5)
    t.equal(actions.dig(Vector2i(1, 1)), true, "creuser roche commune réussit")
    t.equal(common.get_cell(Vector2i(1, 1)), null, "cellule creusée supprimée")
    t.equal(actions.energy_remaining, 4, "creuser coûte 1 énergie")

    var dense := _model_with_cell(Vector2i(1, 1), &"rock_dense")
    actions.begin_prepare(dense, 5)
    t.equal(actions.dig(Vector2i(1, 1)), false, "roche dense non creusable")
    t.equal(actions.energy_remaining, 5, "action invalide ne consomme rien")

func test_move(t: TestSupport) -> void:
    var model := _model_with_cell(Vector2i(1, 1), &"rock_common")
    var actions := preload("res://src/terrain/terrain_actions.gd").new()
    actions.begin_prepare(model, 5)
    t.equal(actions.move([Vector2i(1, 1)], Vector2i(1, 0)), true, "déplacement vers case vide")
    t.equal(model.get_cell(Vector2i(1, 1)), null, "source vidée")
    t.equal(model.get_cell(Vector2i(2, 1)).material_id, &"rock_common", "matière déplacée")
    t.equal(actions.energy_remaining, 3, "déplacement coûte 2 énergie")

func test_fuse(t: TestSupport) -> void:
    var model := preload("res://src/terrain/terrain_model.gd").new(5, 5)
    model.set_cell(Vector2i(1, 1), preload("res://src/terrain/terrain_cell.gd").new(&"rock_common"))
    model.set_cell(Vector2i(2, 1), preload("res://src/terrain/terrain_cell.gd").new(&"stabilizer"))
    var actions := preload("res://src/terrain/terrain_actions.gd").new()
    actions.begin_prepare(model, 5)
    t.equal(actions.fuse(Vector2i(1, 1), Vector2i(2, 1)), true, "fusion stabilisante réussit")
    t.equal(model.get_cell(Vector2i(1, 1)).stability_modifier, 3.0, "fusion ajoute +3 stabilité")
    t.equal(model.get_cell(Vector2i(2, 1)), null, "stabilisant consommé")
    t.equal(actions.energy_remaining, 3, "fusion coûte 2 énergie")

func test_undo_and_cancel(t: TestSupport) -> void:
    var model := _model_with_cell(Vector2i(1, 1), &"rock_common")
    var actions := preload("res://src/terrain/terrain_actions.gd").new()
    actions.begin_prepare(model, 5)
    actions.dig(Vector2i(1, 1))
    t.equal(actions.undo(), true, "undo disponible après action")
    t.equal(model.get_cell(Vector2i(1, 1)).material_id, &"rock_common", "undo restaure terrain")
    t.equal(actions.energy_remaining, 5, "undo restaure énergie")

    actions.dig(Vector2i(1, 1))
    actions.cancel()
    t.equal(model.get_cell(Vector2i(1, 1)).material_id, &"rock_common", "cancel restaure snapshot initial")
    t.equal(actions.energy_remaining, 5, "cancel restaure énergie initiale")
