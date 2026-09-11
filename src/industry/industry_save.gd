class_name IndustrySave
extends RefCounted

const IndustryGameScript = preload("res://src/industry/industry_game.gd")
const SAVE_VERSION := 2
const LEGACY_VERSION := 1
const MAX_SAFE_SEED := 2147483646
const DEFAULT_PATH := "user://industry_v1.json"

func save_game(path: String, game, saved_at_unix: float) -> bool:
    if game == null or not is_finite(saved_at_unix) or saved_at_unix < 0.0:
        return false

    var payload := {
        "version": SAVE_VERSION,
        "saved_at_unix": saved_at_unix,
        "industry": game.snapshot(),
    }
    var temp_path := path + ".tmp"
    var file := FileAccess.open(temp_path, FileAccess.WRITE)
    if file == null:
        return false
    var written := file.store_string(JSON.stringify(payload))
    file.flush()
    var write_error := file.get_error()
    file.close()
    if not written or write_error != OK:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
        return false

    var replace_error := DirAccess.rename_absolute(
        ProjectSettings.globalize_path(temp_path),
        ProjectSettings.globalize_path(path)
    )
    if replace_error != OK:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
        return false
    return true

func load_game(path: String, now_unix: float) -> Dictionary:
    var logical_now := now_unix if is_finite(now_unix) and now_unix >= 0.0 else 0.0
    if not FileAccess.file_exists(path):
        return _new_result(logical_now, "")

    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return _new_result(logical_now, "Impossible de lire la sauvegarde industrielle")
    var contents := file.get_as_text()
    var read_error := file.get_error()
    file.close()
    if read_error != OK:
        return _new_result(logical_now, "Lecture de la sauvegarde industrielle incomplète")

    var json := JSON.new()
    if json.parse(contents) != OK:
        return _new_result(logical_now, "Sauvegarde industrielle illisible")
    var parsed = json.data
    if typeof(parsed) != TYPE_DICTIONARY:
        return _new_result(logical_now, "Sauvegarde industrielle illisible")
    var payload: Dictionary = parsed
    if not _has_exact_keys(payload, ["version", "saved_at_unix", "industry"]):
        return _new_result(logical_now, "Structure de sauvegarde industrielle invalide")
    if not _valid_version(payload["version"]):
        return _new_result(logical_now, "Version de sauvegarde industrielle incompatible")
    if not _valid_timestamp(payload["saved_at_unix"]):
        return _new_result(logical_now, "Date de sauvegarde industrielle invalide")
    if typeof(payload["industry"]) != TYPE_DICTIONARY:
        return _new_result(logical_now, "État industriel invalide")

    if int(payload["version"]) == LEGACY_VERSION:
        return _migrate_v1(payload, logical_now)

    var candidate = IndustryGameScript.new()
    if not candidate.restore(payload["industry"]):
        return _new_result(logical_now, "État industriel incohérent")
    return _finish_load(candidate, float(payload["saved_at_unix"]), logical_now)

func _migrate_v1(payload: Dictionary, logical_now: float) -> Dictionary:
    var candidate = IndustryGameScript.new()
    var seed := _normalized_seed(hash(JSON.stringify(payload)))
    if not candidate.restore_v1(payload["industry"], seed):
        return _new_result(logical_now, "État industriel v1 incohérent")
    return _finish_load(candidate, float(payload["saved_at_unix"]), logical_now)

func _finish_load(candidate, saved_at: float, logical_now: float) -> Dictionary:
    var offline_seconds := maxf(0.0, logical_now - saved_at)
    var paused_event: Dictionary = {}
    if not candidate.active_event.is_empty() and str(candidate.active_event.get("resource", "")) == "":
        paused_event = candidate.active_event.duplicate(true)
    var report: Dictionary = candidate.advance(offline_seconds)
    if not paused_event.is_empty():
        candidate.active_event = paused_event
    # Task 3 intégrera les paliers directement à la fin des forages. Ce passage
    # idempotent garantit déjà les récompenses rétroactives pendant la migration.
    candidate.apply_retroactive_milestones()
    return {
        "game": candidate,
        "saved_at_unix": maxf(saved_at, logical_now),
        "offline_seconds": offline_seconds,
        "offline_report": report,
        "error": "",
    }

func _new_result(saved_at_unix: float, error: String) -> Dictionary:
    var game = IndustryGameScript.new()
    if error == "":
        game.world_seed = _seed_from(saved_at_unix)
    return {
        "game": game,
        "saved_at_unix": saved_at_unix,
        "offline_seconds": 0.0,
        "offline_report": game.advance(0.0),
        "error": error,
    }

func _seed_from(value: float) -> int:
    return _normalized_seed(hash(str(value)))

func _normalized_seed(value: int) -> int:
    return abs(value % MAX_SAFE_SEED) + 1

func _valid_version(value: Variant) -> bool:
    if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
        return false
    if float(value) != floor(float(value)):
        return false
    return int(value) in [LEGACY_VERSION, SAVE_VERSION]

func _valid_timestamp(value: Variant) -> bool:
    return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0.0

func _has_exact_keys(value: Dictionary, keys: Array) -> bool:
    if value.size() != keys.size():
        return false
    for key in keys:
        if not value.has(key):
            return false
    return true
