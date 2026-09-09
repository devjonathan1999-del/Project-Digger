extends RefCounted

func run(t: TestSupport) -> void:
    test_conductive_chain(t)

func test_conductive_chain(t: TestSupport) -> void:
    var model := preload("res://src/terrain/terrain_model.gd").new(4, 3)
    model.set_cell(Vector2i(1, 1), preload("res://src/terrain/terrain_cell.gd").new(&"stabilizer"))
    model.set_cell(Vector2i(2, 1), preload("res://src/terrain/terrain_cell.gd").new(&"stabilizer"))
    var network := preload("res://src/network/ancient_network.gd").new()
    var source := Vector2i(0, 1)
    var relay := Vector2i(3, 1)

    t.equal(network.is_connected(model, source, relay), true, "chaîne conductrice relie le relais")
    model.set_cell(Vector2i(2, 1), null)
    t.equal(network.is_connected(model, source, relay), false, "couper la veine coupe le relais")
