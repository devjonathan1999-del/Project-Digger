extends SceneTree

const Support = preload("res://tests/test_support.gd")
const PATH := "user://tests/progression_ui_events.json"

var t = Support.new()

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(1280, 800)
    DirAccess.make_dir_recursive_absolute("user://tests")
    _cleanup()

    var screen = load("res://scenes/industry.tscn").instantiate()
    var session = screen.get_node("IndustrySession")
    session.save_path = PATH
    root.add_child(screen)
    session.set_process(false)
    await process_frame
    await process_frame

    session.game.pending_events = [{"type": "unstable_vein", "presented": false}]
    session.changed.emit()
    await process_frame

    var banner = screen.find_child("PendingEventBanner", true, false)
    t.check(banner != null and banner.visible, "bannière Filon instable visible sans masquer la mine")
    t.check(screen.find_child("MineWorld", true, false).visible, "mine reste visible pendant l'événement")
    var view_button = screen.find_child("PendingEventView", true, false)
    t.check(view_button != null and view_button.visible, "bouton VOIR disponible")
    if view_button != null:
        await _click(view_button)

    t.check(not session.game.active_event.is_empty(), "VOIR présente l'événement")
    t.equal(session.game.active_event.get("resource", "missing"), "", "aucune ressource choisie à la présentation")
    var initial_remaining := float(session.game.active_event.get("remaining", -1.0))
    session.advance_to(session.last_seen_unix + 60.0)
    t.check(absf(float(session.game.active_event.get("remaining", -1.0)) - initial_remaining) <= 0.001, "timer suspendu tant que le choix n'est pas fait")

    for resource_id in ["iron", "copper", "coal"]:
        var choice = screen.find_child("Event_" + resource_id, true, false)
        t.check(choice != null and choice.visible, "choix %s visible" % resource_id)
    var iron_choice = screen.find_child("Event_iron", true, false)
    if iron_choice != null:
        await _click(iron_choice)
    t.equal(session.game.active_event.get("resource", ""), "iron", "choix Fer appliqué via la session")
    session.advance_to(session.last_seen_unix + 60.0)
    t.check(absf(float(session.game.active_event.get("remaining", -1.0)) - (initial_remaining - 60.0)) <= 0.001, "timer démarre après le choix")

    session.offline_seconds = 125.0
    session.offline_report = {
        "produced": {"iron": 25.0, "coal": 9.0},
        "completed": ["furnace", "drill"],
        "depth_gained": 10,
        "events_expired": [],
    }
    session.game.pending_events = [{"type": "unstable_vein", "presented": false}]
    session.notice_changed.emit()
    session.changed.emit()
    await process_frame

    var offline_card = screen.find_child("OfflineCard", true, false)
    var offline_notice = screen.find_child("OfflineNotice", true, false)
    t.check(offline_card != null and offline_card.visible, "bilan hors ligne compact visible")
    t.check(offline_notice != null and offline_notice.text.contains("2 min 05 s"), "durée d'absence affichée")
    t.check(offline_notice != null and offline_notice.text.contains("2 travaux"), "travaux terminés affichés")
    t.check(offline_notice != null and offline_notice.text.contains("+10 m"), "profondeur gagnée affichée")
    t.check(offline_notice != null and offline_notice.text.contains("1 événement"), "événements en attente affichés")
    var offline_close = screen.find_child("OfflineClose", true, false)
    t.check(offline_close != null, "fermeture manuelle du bilan disponible")
    if offline_close != null:
        await _click(offline_close)
    t.check(offline_card != null and not offline_card.visible, "bilan hors ligne fermable sans bloquer le jeu")

    screen.queue_free()
    await process_frame
    _cleanup()
    print("Progression UI events: %s" % ("PASS" if t.failures == 0 else "FAIL"))
    quit(t.finish())

func _click(button: Button) -> void:
    t.check(button != null, "bouton présent avant clic événement")
    if button == null:
        return
    var scroll = button.find_parent("PageScroll") as ScrollContainer
    if scroll != null:
        scroll.ensure_control_visible(button)
    await process_frame
    await process_frame
    t.check(not button.disabled, "%s disponible avant clic événement" % button.name)
    var at := button.get_global_rect().get_center()
    var press := InputEventMouseButton.new()
    press.button_index = MOUSE_BUTTON_LEFT
    press.position = at
    press.pressed = true
    root.push_input(press)
    var release := InputEventMouseButton.new()
    release.button_index = MOUSE_BUTTON_LEFT
    release.position = at
    release.pressed = false
    root.push_input(release)
    await process_frame

func _cleanup() -> void:
    for path in [PATH, PATH + ".tmp"]:
        if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
