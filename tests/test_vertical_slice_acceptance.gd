extends RefCounted

const SAVE_PATH := "user://project_digger_v02_acceptance.json"

func run(t: TestSupport) -> void:
    test_layout_acceptance(t)
    _cleanup()

func test_layout_acceptance(t: TestSupport) -> void:
    _cleanup()
    var layout := preload("res://src/content/vertical_slice_layout.gd").new()
    var data := layout.build()
    var model: TerrainModel = data["model"]
    var catalog := preload("res://src/core/material_catalog.gd").new()

    t.equal(VerticalSliceLayout.CONTENT_ID, "cave_v02_helix_01", "identifiant contenu v0.2 stable")
    t.equal(model.width, 64, "largeur cave v0.2")
    t.equal(model.height, 72, "hauteur cave v0.2")

    var required_metadata := ["entrance_rect", "chamber_rect", "ancient_path"]
    var metadata_complete := true
    for key in required_metadata:
        if not data.has(key):
            metadata_complete = false
            t.check(false, "métadonnée cave v0.2 présente: %s" % key)
    if not metadata_complete:
        return

    var entrance_rect: Rect2i = data["entrance_rect"]
    var chamber_rect: Rect2i = data["chamber_rect"]
    var ancient_path: Array[Vector2i] = data["ancient_path"]

    t.equal(entrance_rect, Rect2i(6, 5, 20, 12), "zone d'entrée contractuelle")
    t.equal(chamber_rect, Rect2i(18, 22, 28, 36), "chambre centrale contractuelle")
    t.equal(data["spawn_focus"], Vector2i(22, 12), "focus initial de la cave v0.2")
    t.check(ancient_path.size() >= 12, "réseau ancien visuellement exploitable")
    t.equal(ancient_path.front(), data["relay_source"], "chemin ancien commence à la source")
    t.equal(ancient_path.back(), data["relay_pos"], "chemin ancien termine au relais")

    var counts := {
        &"rock_common": 0,
        &"rock_fragile": 0,
        &"rock_dense": 0,
        &"stabilizer": 0,
    }
    for y in range(model.height):
        for x in range(model.width):
            var cell := model.get_cell(Vector2i(x, y))
            if cell != null and counts.has(cell.material_id):
                counts[cell.material_id] += 1
    for material_id in counts.keys():
        t.check(int(counts[material_id]) > 0, "matière présente: %s" % material_id)

    var entrance_has_diggable := false
    for y in range(entrance_rect.position.y, entrance_rect.end.y):
        for x in range(entrance_rect.position.x, entrance_rect.end.x):
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
    t.equal(network.is_relay_connected(model, data["relay_source"], data["relay_pos"]), true, "relais connecté au départ")

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
    var corridor_x: int = exit_rect.position.x + int(exit_rect.size.x / 2)
    t.equal(_is_corridor_clear(model, corridor_x, exit_rect.end.y), true, "corridor vertical ouvert de la porte jusqu'à la sortie")
    t.equal(network.is_relay_connected(model, data["relay_source"], data["relay_pos"]), true, "solution canonique préserve le relais")

    var save := preload("res://src/save/save_system.gd").new()
    t.equal(save.save_to_path(SAVE_PATH, model, {
        "relay_connected": true,
        "cycle_state": SimulationController.OBSERVER,
        "objective_reached": true,
        "content_id": VerticalSliceLayout.CONTENT_ID,
    }), true, "cave résolue sauvegardée")

    var loaded := save.load_from_path_for_content(SAVE_PATH, VerticalSliceLayout.CONTENT_ID)
    t.equal(loaded.is_empty(), false, "cave v0.2 résolue rechargée par content_id")
    if loaded.is_empty():
        return

    var fresh_data := layout.build()
    var restored: TerrainModel = fresh_data["model"]
    restored.restore(loaded["terrain"])
    t.equal(_is_corridor_clear(restored, corridor_x, exit_rect.end.y), true, "descente reste ouverte après restauration")
    t.equal(network.is_relay_connected(restored, fresh_data["relay_source"], fresh_data["relay_pos"]), true, "relais reste connecté après restauration")

func _is_corridor_clear(model: TerrainModel, corridor_x: int, end_y: int) -> bool:
    for y in range(VerticalSliceLayout.GATE_POS.y, end_y):
        if model.get_cell(Vector2i(corridor_x, y)) != null:
            return false
    return true

func _cleanup() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
