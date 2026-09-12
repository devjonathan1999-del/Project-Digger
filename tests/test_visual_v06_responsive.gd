extends SceneTree

const Support = preload("res://tests/test_support.gd")
const PATH := "user://tests/visual_v06_responsive.json"

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

    session.game.depth = 150
    session.game.center_level = 6
    session.changed.emit()
    await _settle()

    var world = screen.find_child("MineWorld", true, false)
    var module = screen.find_child("MineModuleRenderer", true, false)
    var context = screen.find_child("ContextPanel", true, false)
    var presenter = screen.find_child("MineInteractionPresenter", true, false)
    t.check(world != null, "MineWorld responsive présent")
    t.check(module != null, "renderer final monté dans le monde")
    t.check(context != null, "contexte responsive présent")
    t.check(presenter != null, "présentateur responsive présent")

    if module != null and world != null:
        var wide: Dictionary = module.metrics()
        t.equal(bool(wide.get("narrow_mode", true)), false, "mode large détecté")
        t.check(float(wide.get("shaft_width", 0.0)) >= 110.0 and float(wide.get("shaft_width", 0.0)) <= 150.0, "puits borné sur desktop")
        t.check(absf(float(wide.get("shaft_center_x", -100.0)) - world.size.x * 0.5) <= 2.0, "puits centré sur desktop")
        t.equal(bool(wide.get("surface_bounds_ok", false)), true, "modules surface dans les bornes desktop")
        t.equal(bool(wide.get("surface_vertical_bounds_ok", false)), true, "modules surface non rognés verticalement sur desktop")
        t.check(float(wide.get("surface_visual_ground_y", 0.0)) >= 110.0, "surface desktop garde de l'air au-dessus du chevalement")
        t.check(int(wide.get("rock_relief_count", 0)) >= 6, "relief rocheux final assez dense pour casser les bandes plates")
        t.check(int(wide.get("decorative_detail_level", 0)) >= 2, "niveau de détail desktop complet")

    for target_name in ["Mine_iron", "Mine_coal", "Mine_copper", "Drill"]:
        var target = screen.find_child(target_name, true, false) as Button
        t.check(target != null, "cible tactile %s présente" % target_name)
        if target != null:
            t.check(target.size.x >= 44.0 and target.size.y >= 44.0, "cible tactile %s >= 44 px" % target_name)

    root.size = Vector2i(720, 1000)
    await _settle()

    if module != null and world != null:
        var narrow: Dictionary = module.metrics()
        t.equal(bool(narrow.get("narrow_mode", false)), true, "mode étroit détecté")
        t.check(float(narrow.get("shaft_width", 999.0)) <= 110.0, "puits plafonné sur mobile")
        t.check(absf(float(narrow.get("shaft_center_x", -100.0)) - world.size.x * 0.5) <= 2.0, "puits centré sur mobile")
        t.equal(bool(narrow.get("surface_bounds_ok", false)), true, "modules surface dans les bornes mobile")
        t.equal(bool(narrow.get("surface_vertical_bounds_ok", false)), true, "modules surface non rognés verticalement sur mobile")
        t.check(int(narrow.get("rock_relief_count", 0)) >= 6, "relief rocheux conservé sur mobile")
        t.equal(int(narrow.get("decorative_detail_level", 0)), 1, "détails tertiaires réduits sur mobile")

    if world != null:
        world.focus_depth(0)
        await _settle()
    var iron = screen.find_child("Mine_iron", true, false) as Button
    await _click(iron)
    if context != null and world != null:
        t.check(context.visible, "contexte visible après clic mobile")
        t.equal(str(context.get_meta("layout_mode", "")), "bottom_sheet", "contexte mobile en bottom-sheet")
        t.check(context.size.y <= world.size.y * 0.45, "bottom-sheet laisse la majorité de la mine visible")
        t.check(context.size.y <= 320.0, "bottom-sheet reste compact")
        context.clear_selection()
        await _settle()
    if presenter != null:
        t.check(float(presenter.marker_alpha("iron")) < 0.5, "marqueur revient au repos après fermeture")

    screen.queue_free()
    await process_frame
    _cleanup()
    print("Visual v0.6 responsive: %s" % ("PASS" if t.failures == 0 else "FAIL"))
    quit(t.finish())

func _click(button: Button) -> void:
    t.check(button != null, "bouton présent avant clic responsive")
    if button == null:
        return
    var scroll = button.find_parent("PageScroll") as ScrollContainer
    if scroll != null:
        scroll.ensure_control_visible(button)
    await _settle()
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
    await _settle()

func _settle() -> void:
    await process_frame
    await process_frame
    await process_frame

func _cleanup() -> void:
    if FileAccess.file_exists(PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
    if FileAccess.file_exists(PATH + ".tmp") or DirAccess.dir_exists_absolute(PATH + ".tmp"):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + ".tmp"))
