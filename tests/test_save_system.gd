extends RefCounted

const SAVE_PATH := "user://project_digger_test_save.json"

func run(t: TestSupport) -> void:
    test_round_trip(t)
    test_transient_state_rejected(t)
    test_future_version_rejected(t)
    _cleanup()

func _cell(id: StringName, modifier: float = 0.0) -> TerrainCell:
    return preload("res://src/terrain/terrain_cell.gd").new(id, modifier)

func test_round_trip(t: TestSupport) -> void:
    _cleanup()
    var model := preload("res://src/terrain/terrain_model.gd").new(3, 3)
    model.set_cell(Vector2i(1, 1), _cell(&"rock_common", 3.0))
    var save := preload("res://src/save/save_system.gd").new()
    var extra := {
        "relay_connected": true,
        "cycle_state": SimulationController.PREPARE,
        "objective_reached": true,
    }

    t.equal(save.save_to_path(SAVE_PATH, model, extra), true, "sauvegarde écrite")
    var loaded := save.load_from_path(SAVE_PATH)
    t.equal(loaded.get("version"), 1, "version sauvegarde")
    t.equal(loaded.get("relay_connected"), true, "état relais restauré")
    t.equal(loaded.get("cycle_state"), SimulationController.PREPARE, "état cycle restauré")
    t.equal(loaded.get("objective_reached"), true, "objectif restauré")

    var restored := preload("res://src/terrain/terrain_model.gd").new()
    restored.restore(loaded["terrain"])
    t.equal(restored.get_cell(Vector2i(1, 1)).material_id, &"rock_common", "terrain restauré")
    t.equal(restored.get_cell(Vector2i(1, 1)).stability_modifier, 3.0, "modificateur restauré")

func test_transient_state_rejected(t: TestSupport) -> void:
    var model := preload("res://src/terrain/terrain_model.gd").new(2, 2)
    var save := preload("res://src/save/save_system.gd").new()
    t.equal(save.save_to_path(SAVE_PATH, model, {"cycle_state": SimulationController.RESOLVING}), false, "état Résoudre non persisté")

func test_future_version_rejected(t: TestSupport) -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify({"version": 2, "terrain": {}, "relay_connected": false, "cycle_state": 0, "objective_reached": false}))
    file.close()
    var save := preload("res://src/save/save_system.gd").new()
    t.equal(save.load_from_path(SAVE_PATH), {}, "version future rejetée")

func _cleanup() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
