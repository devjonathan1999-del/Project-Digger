class_name SaveSystem
extends RefCounted

const SAVE_VERSION := 1
const DEFAULT_PATH := "user://save_v1.json"

func save_default(model: TerrainModel, extra: Dictionary) -> bool:
    return save_to_path(DEFAULT_PATH, model, extra)

func load_default() -> Dictionary:
    return load_from_path(DEFAULT_PATH)

func load_default_for_content(content_id: String) -> Dictionary:
    return load_from_path_for_content(DEFAULT_PATH, content_id)

func load_from_path_for_content(path: String, content_id: String) -> Dictionary:
    var data := load_from_path(path)
    if data.is_empty():
        return {}
    if String(data.get("content_id", "")) != content_id:
        return {}
    return data

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
        "content_id": String(extra.get("content_id", "")),
    }

    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("SaveSystem: cannot open save path: %s" % path)
        return false
    file.store_string(JSON.stringify(data))
    file.close()
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
