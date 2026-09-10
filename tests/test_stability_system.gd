extends RefCounted

func run(t: TestSupport) -> void:
    test_support_states(t)
    test_stabilizer_changes_fragile_to_stable(t)
    test_collapse_is_deterministic(t)
    test_iteration_limit(t)

func _cell(id: StringName, modifier: float = 0.0) -> TerrainCell:
    return preload("res://src/terrain/terrain_cell.gd").new(id, modifier)

func _lateral_fixture() -> TerrainModel:
    var model := preload("res://src/terrain/terrain_model.gd").new(4, 4)
    model.set_cell(Vector2i(0, 3), _cell(&"rock_common"))
    model.set_cell(Vector2i(0, 2), _cell(&"rock_common"))
    model.set_cell(Vector2i(1, 2), _cell(&"rock_fragile"))
    return model

func test_support_states(t: TestSupport) -> void:
    var system := preload("res://src/terrain/stability_system.gd").new()
    var model := _lateral_fixture()
    model.set_cell(Vector2i(3, 0), _cell(&"rock_common"))
    var states := system.classify(model)
    t.equal(states[Vector2i(0, 3)], StabilitySystem.STABLE, "sol bas stable")
    t.equal(states[Vector2i(0, 2)], StabilitySystem.STABLE, "support vertical stable")
    t.equal(states[Vector2i(1, 2)], StabilitySystem.FRAGILE, "un seul support latéral rend la roche friable fragile")
    t.equal(states[Vector2i(3, 0)], StabilitySystem.CRITICAL, "masse sans support critique")

func test_stabilizer_changes_fragile_to_stable(t: TestSupport) -> void:
    var system := preload("res://src/terrain/stability_system.gd").new()
    var model := _lateral_fixture()
    t.equal(system.classify(model)[Vector2i(1, 2)], StabilitySystem.FRAGILE, "avant stabilisation")
    model.get_cell(Vector2i(1, 2)).stability_modifier += 3.0
    t.equal(system.classify(model)[Vector2i(1, 2)], StabilitySystem.STABLE, "stabilisant rend le bloc stable")

func test_collapse_is_deterministic(t: TestSupport) -> void:
    var system := preload("res://src/terrain/stability_system.gd").new()
    var first := preload("res://src/terrain/terrain_model.gd").new(3, 5)
    first.set_cell(Vector2i(1, 0), _cell(&"rock_common"))
    var second := preload("res://src/terrain/terrain_model.gd").new(3, 5)
    second.restore(first.snapshot())
    var first_moves := system.resolve(first)
    var second_moves := system.resolve(second)
    t.equal(first_moves, second_moves, "même terrain produit mêmes mouvements")
    t.check(not first_moves.is_empty(), "effondrement produit des mouvements")
    if not first_moves.is_empty():
        t.check(first_moves[0].has("material_id"), "mouvement expose la matière pour le feedback")
        t.equal(first_moves[0].get("material_id", &""), &"rock_common", "matière du mouvement conservée")
    t.equal(first.get_cell(Vector2i(1, 4)).material_id, &"rock_common", "bloc finit sur le fond")

func test_iteration_limit(t: TestSupport) -> void:
    var system := preload("res://src/terrain/stability_system.gd").new()
    var model := preload("res://src/terrain/terrain_model.gd").new(3, 8)
    model.set_cell(Vector2i(1, 0), _cell(&"rock_common"))
    var movements := system.resolve(model, 1)
    t.equal(movements.size(), 1, "une itération ne déplace le bloc qu'une fois")
    t.check(model.get_cell(Vector2i(1, 1)) != null, "limite d'itération respectée")
