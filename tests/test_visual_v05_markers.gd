extends SceneTree

const Support = preload("res://tests/test_support.gd")
const PATH := "user://tests/visual_v05_markers.json"

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

    var presenter = screen.find_child("MineInteractionPresenter", true, false)
    var context = screen.find_child("ContextPanel", true, false)
    var iron = screen.find_child("Mine_iron", true, false)
    var copper = screen.find_child("Mine_copper", true, false)
    t.check(presenter != null, "présentateur de marqueurs disponible")
    t.check(context != null, "panneau contextuel disponible")
    t.check(iron != null and copper != null, "zones tactiles minerais présentes")
    if presenter != null and iron != null and copper != null:
        var rest_alpha = presenter.marker_alpha("iron") if presenter.has_method("marker_alpha") else null
        t.check(rest_alpha is float and rest_alpha <= 0.45, "Fer discret au repos")

        if presenter.has_method("set_selected_key"):
            presenter.set_selected_key("iron")
        await process_frame
        var selected_alpha = presenter.marker_alpha("iron") if presenter.has_method("marker_alpha") else null
        t.check(selected_alpha is float and selected_alpha >= 0.90, "Fer renforcé quand sélectionné")
        t.check(presenter.marker_is_emphasized("iron") if presenter.has_method("marker_is_emphasized") else false, "marqueur sélectionné signalé")

        if presenter.has_method("set_selected_key"):
            presenter.set_selected_key("")
        copper.grab_focus()
        await process_frame
        var focus_alpha = presenter.marker_alpha("copper") if presenter.has_method("marker_alpha") else null
        t.check(focus_alpha is float and focus_alpha >= 0.90, "Cuivre renforcé au focus")

        copper.release_focus()
        iron.pressed.emit()
        await process_frame
        t.check(presenter.marker_is_emphasized("iron") if presenter.has_method("marker_is_emphasized") else false, "clic monde conserve le marqueur sélectionné")
        t.check(iron.modulate.a <= 0.08, "bouton tactile Fer reste invisible")

        if context != null:
            context.call("clear_selection")
            await process_frame
            t.check(not presenter.marker_is_emphasized("iron") if presenter.has_method("marker_is_emphasized") else false, "fermeture du contexte remet le marqueur au repos")
            var cleared_alpha = presenter.marker_alpha("iron") if presenter.has_method("marker_alpha") else null
            t.check(cleared_alpha is float and cleared_alpha <= 0.45, "alpha de repos restauré après fermeture")

    screen.queue_free()
    await process_frame
    _cleanup()
    print("Visual v0.5 markers: %s" % ("PASS" if t.failures == 0 else "FAIL"))
    quit(t.finish())

func _cleanup() -> void:
    if FileAccess.file_exists(PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
    if FileAccess.file_exists(PATH + ".tmp") or DirAccess.dir_exists_absolute(PATH + ".tmp"):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + ".tmp"))
