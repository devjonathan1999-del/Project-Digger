extends RefCounted

const SAVE_PATH := "user://project_digger_test_save.json"
const TEMP_PATH := SAVE_PATH + ".tmp"

func run(t: TestSupport) -> void:
    test_round_trip(t)
    test_failed_save_preserves_previous_progress(t)
    test_successful_save_replaces_previous_progress(t)
    test_interrupted_temporary_save_is_ignored(t)
    test_failed_replacement_reports_failure(t)
    test_disk_full_preserves_previous_progress(t)
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

func test_failed_save_preserves_previous_progress(t: TestSupport) -> void:
    _cleanup()
    var model := TerrainModel.new(2, 2)
    model.set_cell(Vector2i(0, 0), _cell(&"rock_common"))
    var save := SaveSystem.new()
    t.check(save.save_to_path(SAVE_PATH, model, {}), "sauvegarde initiale écrite")
    var previous_bytes := FileAccess.get_file_as_bytes(SAVE_PATH)

    # A directory at the staging path makes writing fail on every platform,
    # without permission tricks or replacing the real filesystem with a mock.
    t.equal(DirAccess.make_dir_absolute(TEMP_PATH), OK, "écriture temporaire bloquée")
    model.set_cell(Vector2i(0, 0), null)
    t.equal(save.save_to_path(SAVE_PATH, model, {"objective_reached": true}), false, "échec de sauvegarde signalé")
    t.equal(FileAccess.get_file_as_bytes(SAVE_PATH), previous_bytes, "ancienne sauvegarde conservée octet pour octet")
    var restored := TerrainModel.new()
    restored.restore(save.load_from_path(SAVE_PATH).get("terrain", {}))
    t.check(restored.get_cell(Vector2i(0, 0)) != null, "ancienne progression toujours chargeable")
    _cleanup()

func test_successful_save_replaces_previous_progress(t: TestSupport) -> void:
    _cleanup()
    var model := TerrainModel.new(2, 2)
    model.set_cell(Vector2i(0, 0), _cell(&"rock_common"))
    var save := SaveSystem.new()
    t.check(save.save_to_path(SAVE_PATH, model, {}), "première progression sauvegardée")
    model.set_cell(Vector2i(0, 0), null)
    t.check(save.save_to_path(SAVE_PATH, model, {"objective_reached": true}), "nouvelle progression sauvegardée")
    var loaded := save.load_from_path(SAVE_PATH)
    t.equal(loaded.get("objective_reached"), true, "nouvel objectif chargé")
    var restored := TerrainModel.new()
    restored.restore(loaded.get("terrain", {}))
    t.equal(restored.get_cell(Vector2i(0, 0)), null, "nouveau terrain chargé")
    t.equal(FileAccess.file_exists(TEMP_PATH), false, "aucun fichier temporaire après succès")
    _cleanup()

func test_interrupted_temporary_save_is_ignored(t: TestSupport) -> void:
    _cleanup()
    var model := TerrainModel.new(2, 2)
    var save := SaveSystem.new()
    t.check(save.save_to_path(SAVE_PATH, model, {"objective_reached": true}), "progression validée sauvegardée")
    var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
    file.store_string("{\"version\":1,\"terrain\":")
    file.close()
    t.equal(save.load_from_path(SAVE_PATH).get("objective_reached"), true, "écriture interrompue ignorée au chargement")
    t.check(save.save_to_path(SAVE_PATH, model, {"objective_reached": false}), "sauvegarde possible après interruption")
    t.equal(save.load_from_path(SAVE_PATH).get("objective_reached"), false, "progression suivante chargée")
    t.equal(FileAccess.file_exists(TEMP_PATH), false, "ancien temporaire remplacé puis consommé")
    _cleanup()

func test_failed_replacement_reports_failure(t: TestSupport) -> void:
    _cleanup()
    # The staging file can be written, but cannot replace a directory.
    t.equal(DirAccess.make_dir_absolute(SAVE_PATH), OK, "remplacement final bloqué")
    var save := SaveSystem.new()
    t.equal(save.save_to_path(SAVE_PATH, TerrainModel.new(2, 2), {}), false, "échec du remplacement signalé")
    t.check(DirAccess.dir_exists_absolute(SAVE_PATH), "destination non supprimée en cas d'échec")
    t.equal(FileAccess.file_exists(TEMP_PATH), false, "temporaire nettoyé après échec")
    _cleanup()

func test_transient_state_rejected(t: TestSupport) -> void:
    var model := preload("res://src/terrain/terrain_model.gd").new(2, 2)
    var save := preload("res://src/save/save_system.gd").new()
    t.equal(save.save_to_path(SAVE_PATH, model, {"cycle_state": SimulationController.RESOLVING}), false, "état Résoudre non persisté")

func test_disk_full_preserves_previous_progress(t: TestSupport) -> void:
    # Linux provides a real write-failure device; no disk space is consumed.
    if OS.get_name() != "Linux" or not FileAccess.file_exists("/dev/full"):
        return
    _cleanup()
    var save := SaveSystem.new()
    var model := TerrainModel.new(2, 2)
    t.check(save.save_to_path(SAVE_PATH, model, {"objective_reached": true}), "progression sauvegardée avant disque plein")
    var previous_bytes := FileAccess.get_file_as_bytes(SAVE_PATH)
    var directory := DirAccess.open("user://")
    t.equal(directory.create_link("/dev/full", TEMP_PATH), OK, "échec disque injecté dans le temporaire")
    t.equal(save.save_to_path(SAVE_PATH, model, {}), false, "échec disque signalé")
    # Check the link before reading: /dev/full cannot be read to EOF.
    if directory.is_link(SAVE_PATH):
        t.check(false, "la sauvegarde ne doit pas être remplacée après un échec disque")
    else:
        t.check(FileAccess.get_file_as_bytes(SAVE_PATH) == previous_bytes, "ancienne progression conservée après échec disque")
    _cleanup()

func test_future_version_rejected(t: TestSupport) -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify({"version": 2, "terrain": {}, "relay_connected": false, "cycle_state": 0, "objective_reached": false}))
    file.close()
    var save := preload("res://src/save/save_system.gd").new()
    t.equal(save.load_from_path(SAVE_PATH), {}, "version future rejetée")

func _cleanup() -> void:
    for path in [SAVE_PATH, TEMP_PATH]:
        if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
