extends RefCounted

func run(t: TestSupport) -> void:
    test_layout_acceptance(t)

func test_layout_acceptance(t: TestSupport) -> void:
    var layout := preload("res://src/content/vertical_slice_layout.gd").new()
    var data := layout.build()
    var model: TerrainModel = data["model"]
    var catalog := preload("res://src/core/material_catalog.gd").new()

    t.equal(model.width, 64, "largeur vertical slice")
    t.equal(model.height, 72, "hauteur vertical slice")

    var entrance_has_diggable := false
    for y in range(4, 13):
        for x in range(model.width):
            var cell := model.get_cell(Vector2i(x, y))
            if cell != null:
                var material := catalog.get_def(cell.material_id)
                if material != null and material.diggable:
                    entrance_has_diggable = true
                    break
        if entrance_has_diggable:
            break
    t.equal(entrance_has_diggable, true, "entrée contient un passage à creuser")

    var dense_found := false
    for y in range(40, 50):
        for x in range(26, 41):
            var cell := model.get_cell(Vector2i(x, y))
            if cell != null:
                var material := catalog.get_def(cell.material_id)
                if material != null and not material.diggable:
                    dense_found = true
                    break
        if dense_found:
            break
    t.equal(dense_found, true, "obstacle dense non creusable présent")

    var network := preload("res://src/network/ancient_network.gd").new()
    t.equal(network.is_connected(model, data["relay_source"], data["relay_pos"]), true, "relais connecté au départ")

    var actions := preload("res://src/terrain/terrain_actions.gd").new()
    actions.begin_prepare(model, 10)
    for support_pos in VerticalSliceLayout.SUPPORT_REMOVAL:
        t.equal(actions.dig(support_pos), true, "support canonique creusable: %s" % support_pos)
    actions.commit()

    var stability := preload("res://src/terrain/stability_system.gd").new()
    var movements := stability.resolve(model)
    var gate_fell := false
    for movement in movements:
        if movement.get("from") == VerticalSliceLayout.GATE_POS:
            gate_fell = true
            break
    t.equal(gate_fell, true, "suppression des supports fait tomber la porte dense")

    var exit_rect: Rect2i = data["exit_rect"]
    var corridor_clear := true
    for y in range(exit_rect.position.y, exit_rect.end.y):
        if model.get_cell(Vector2i(32, y)) != null:
            corridor_clear = false
            break
    t.equal(corridor_clear, true, "corridor vertical vide traverse la zone de sortie")
    t.equal(network.is_connected(model, data["relay_source"], data["relay_pos"]), true, "solution canonique préserve le relais")
