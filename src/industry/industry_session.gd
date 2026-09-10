class_name IndustrySession
extends Node

const IndustryGameScript = preload("res://src/industry/industry_game.gd")
const IndustrySaveScript = preload("res://src/industry/industry_save.gd")
const AUTOSAVE_SECONDS := 10.0

signal changed
signal notice_changed

var game = IndustryGameScript.new()
var save_path: String = IndustrySaveScript.DEFAULT_PATH
var save_error := ""
var offline_seconds := 0.0
var offline_report: Dictionary = {}
var save_blocked := false
var last_seen_unix := 0.0

var _initialized := false
var _autosave_elapsed := 0.0

func _ready() -> void:
    if not _initialized:
        initialize(Time.get_unix_time_from_system())

func initialize(now_unix: float) -> void:
    if _initialized:
        return
    var loaded: Dictionary = IndustrySaveScript.new().load_game(save_path, now_unix)
    game = loaded["game"]
    last_seen_unix = loaded["saved_at_unix"]
    offline_seconds = loaded["offline_seconds"]
    offline_report = loaded["offline_report"]
    save_error = loaded["error"]
    save_blocked = save_error != ""
    _initialized = true
    if save_blocked:
        notice_changed.emit()
    else:
        persist()
    changed.emit()

func advance_to(now_unix: float) -> void:
    if not _initialized or not is_finite(now_unix) or now_unix < 0.0 or now_unix <= last_seen_unix:
        return
    game.advance(now_unix - last_seen_unix)
    last_seen_unix = now_unix
    changed.emit()

func persist() -> bool:
    if not _initialized or save_blocked:
        return false
    var saved := IndustrySaveScript.new().save_game(save_path, game, last_seen_unix)
    if not saved:
        save_error = "Impossible d'écrire la sauvegarde industrielle"
        notice_changed.emit()
        return false
    if save_error != "":
        save_error = ""
        notice_changed.emit()
    return true

func start_batch(recipe: String, quantity: int) -> bool:
    return _apply_action(Callable(game, "start_batch").bind(recipe, quantity))

func upgrade_mine(id: String) -> bool:
    return _apply_action(Callable(game, "upgrade_mine").bind(id))

func upgrade_drill() -> bool:
    return _apply_action(Callable(game, "upgrade_drill"))

func start_excavation() -> bool:
    return _apply_action(Callable(game, "start_excavation"))

func upgrade_center() -> bool:
    return _apply_action(Callable(game, "upgrade_center"))

func start_exploration(id: String) -> bool:
    return _apply_action(Callable(game, "start_exploration").bind(id))

func set_site_active(id: String, active: bool) -> bool:
    return _apply_action(Callable(game, "set_site_active").bind(id, active))

func unlock_technology(id: String) -> bool:
    return _apply_action(Callable(game, "unlock_technology").bind(id))

func build_technology(id: String) -> bool:
    return _apply_action(Callable(game, "build_technology").bind(id))

func set_priority(branch: String) -> bool:
    return _apply_action(Callable(game, "set_priority").bind(branch))

func present_pending_event() -> bool:
    return _apply_action(Callable(game, "present_pending_event"))

func choose_event_resource(id: String) -> bool:
    return _apply_action(Callable(game, "choose_event_resource").bind(id))

func _apply_action(callable: Callable) -> bool:
    advance_to(Time.get_unix_time_from_system())
    if not callable.call():
        return false
    persist()
    changed.emit()
    return true

func _process(delta: float) -> void:
    advance_to(Time.get_unix_time_from_system())
    if not is_finite(delta) or delta <= 0.0:
        return
    _autosave_elapsed += delta
    if _autosave_elapsed >= AUTOSAVE_SECONDS:
        _autosave_elapsed = fmod(_autosave_elapsed, AUTOSAVE_SECONDS)
        persist()

func _notification(what: int) -> void:
    if not _initialized:
        return
    if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST]:
        advance_to(Time.get_unix_time_from_system())
        persist()
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        var tree := get_tree()
        if tree != null and not tree.auto_accept_quit:
            tree.quit()

func _exit_tree() -> void:
    if _initialized:
        advance_to(Time.get_unix_time_from_system())
        persist()
