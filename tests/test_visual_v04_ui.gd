extends SceneTree

const Support = preload("res://tests/test_support.gd")
const PATH := "user://tests/visual_v04_ui.json"

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

    var hud = screen.find_child("CompactHUD", true, false)
    var world = screen.find_child("MineWorld", true, false)
    var context = screen.find_child("ContextPanel", true, false)
    var nav = screen.find_child("BottomNavigation", true, false)
    var overlay = screen.find_child("MineOverlayLayer", true, false)

    t.check(hud != null, "HUD compact présent")
    t.check(world != null, "MineWorld présent")
    t.check(context != null, "ContextPanel présent")
    t.check(nav != null, "navigation basse présente")
    t.check(overlay != null, "overlays intégrés à la Mine")

    if hud != null:
        t.check(hud.size.y <= 70.0, "HUD <= 70 px")
    if nav != null:
        t.check(nav.size.y <= 50.0, "navigation <= 50 px")
    if context != null:
        t.check(not context.visible, "contexte caché par défaut")
        t.equal(str(context.get_meta("layout_mode", "")), "floating_right", "contexte desktop flottant")
    if world != null:
        t.check(world.size.x >= screen.size.x * 0.70, "MineWorld >= 70 % de la largeur")

    t.check(screen.find_child("DrillCommandCard", true, false) == null, "pas de panneau foreuse permanent")

    root.size = Vector2i(720, 1000)
    await process_frame
    await process_frame
    await process_frame

    if context != null:
        t.equal(str(context.get_meta("layout_mode", "")), "bottom_sheet", "contexte mobile en bottom-sheet")
    var scroll = screen.find_child("PageScroll", true, false) as ScrollContainer
    if scroll != null:
        t.check(scroll.get_h_scroll_bar().max_value <= 721.0, "aucun débordement horizontal")

    screen.queue_free()
    await process_frame
    _cleanup()
    print("Visual v0.4 UI: %s" % ("PASS" if t.failures == 0 else "FAIL"))
    quit(t.finish())

func _cleanup() -> void:
    if FileAccess.file_exists(PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
    if FileAccess.file_exists(PATH + ".tmp") or DirAccess.dir_exists_absolute(PATH + ".tmp"):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + ".tmp"))
