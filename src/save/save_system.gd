class_name SaveSystem
extends RefCounted

const SAVE_VERSION := 1
const DEFAULT_PATH := "user://save_v1.json"

func save_default(model: TerrainModel, extra: Dictionary) -> bool:
    return save_to_path(DEFAULT_PATH, model, extra)

func load_default() -> Dictionary:
    return load_from_path(DEFAULT_PATH)

func save_to_path(path: String, model: TerrainModel, extra: Dictionary) -> bool:
    if model == null:
        push_error("SaveSystem: terrain model is required")
        return false

    var cycle_state := int(extra.get("cycle_state", SimulationController.OBSERVER))
    # A transient resolving state is a normal validation rejection, not an
    # engine/runtime error. The caller receives false and decides what to do.
    if cycle_state != SimulationController.OBSERVER and cycle_state != SimulationController.PREPARE:
        return false

    var data := {
        "version": SAVE_VERSION,
        "terrain": model.snapshot(),
        "relay_connected": bool(extra.get("relay_connected", false)),
        "cycle_state": cycle_state,
        "objective_reached": bool(extra.get("objective_reached", false)),
    }

    # Keep the last committed save untouched until its replacement is complete.
    # A sibling file keeps the final rename on the same filesystem.
    var temp_path := path + ".tmp"
    var file := FileAccess.open(temp_path, FileAccess.WRITE)
    if file == null:
        return false
    var written := file.store_string(JSON.stringify(data))
    file.flush()
    var write_error := file.get_error()
    file.close()
    if not written or write_error != OK:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
        return false

    # Never remove the destination first: a failed replacement must retain it.
    var replace_error := DirAccess.rename_absolute(
        ProjectSettings.globalize_path(temp_path),
        ProjectSettings.globalize_path(path)
    )
    if replace_error != OK:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
        return false
    return true

func load_from_path(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}

    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("SaveSystem: cannot read save path: %s" % path)
        return {}

    var parsed = JSON.parse_string(file.get_as_text())
    file.close()
    if not parsed is Dictionary:
        push_error("SaveSystem: invalid JSON save")
        return {}

    var data: Dictionary = parsed
    var version := int(data.get("version", -1))
    # A save from another schema version is an expected compatibility case.
    # Reject it without polluting the engine error log.
    if version != SAVE_VERSION:
        return {}

    if not data.get("terrain", null) is Dictionary:
        push_error("SaveSystem: missing terrain snapshot")
        return {}

    var cycle_state := int(data.get("cycle_state", SimulationController.OBSERVER))
    if cycle_state != SimulationController.OBSERVER and cycle_state != SimulationController.PREPARE:
        push_error("SaveSystem: invalid persisted cycle state")
        return {}

    return data
