extends SceneTree

const Support = preload("res://tests/test_support.gd")
const Discovery = preload("res://src/industry/industry_discovery.gd")
const PATH := "user://tests/visual_v04_captures.json"

var t = Support.new()

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var args := OS.get_cmdline_user_args()
    var folder := "/tmp/digger-ui"
    if "--screenshots" in args:
        folder = args[args.find("--screenshots") + 1]
    DirAccess.make_dir_recursive_absolute(folder)
    DirAccess.make_dir_recursive_absolute("user://tests")
    _cleanup()

    root.size = Vector2i(1280, 800)
    var screen = load("res://scenes/industry.tscn").instantiate()
    var session = screen.get_node("IndustrySession")
    session.save_path = PATH
    root.add_child(screen)
    session.set_process(false)
    await process_frame
    await process_frame

    _prepare_showcase(session)
    session.changed.emit()
    await process_frame
    await process_frame

    var world = screen.find_child("MineWorld", true, false)
    t.check(world != null, "MineWorld disponible pour les captures v0.4")
    if world != null:
        world.set("zoom", 0.75)
        world.focus_depth(38)
    await process_frame
    await process_frame

    var context = screen.find_child("ContextPanel", true, false)
    if context != null:
        context.call("clear_selection")
    await _capture(Vector2i(1280, 800), folder.path_join("industry-wide.png"))

    var discovery = screen.find_child("Discovery_30_0", true, false) as Button
    t.check(discovery != null, "découverte visible pour le contexte wide")
    if discovery != null:
        await _click(discovery)
    await _capture(Vector2i(1280, 800), folder.path_join("industry-wide-context.png"))

    if context != null:
        context.call("clear_selection")
    await _capture(Vector2i(720, 1000), folder.path_join("industry-narrow.png"))

    discovery = screen.find_child("Discovery_30_0", true, false) as Button
    if discovery != null:
        await _click(discovery)
    await _capture(Vector2i(720, 1000), folder.path_join("industry-narrow-context.png"))

    screen.queue_free()
    await process_frame
    _cleanup()
    print("Visual v0.4 captures: %s" % ("PASS" if t.failures == 0 else "FAIL"))
    quit(t.finish())

func _prepare_showcase(session) -> void:
    var game = session.game
    game.depth = 90
    game.center_level = 4
    game.drill_level = 4
    game.resources["iron"] = 58911.0
    game.resources["coal"] = 35420.0
    game.resources["copper"] = 29808.0
    game.resources["iron_ingot"] = 23.0
    game.resources["copper_ingot"] = 14.0
    game.resources["cable"] = 8.0
    game.resources["crystal"] = 3.0
    game.discoveries["30:0"] = Discovery.generate(123, 30, 0, 0.0)
    game.discoveries["60:0"] = Discovery.generate(123, 60, 0, 0.0)
    game.permanent_sites["90:site"] = {
        "type": "crystal_cavern",
        "active": true,
        "capacity": 2,
        "depth": 90,
        "level": 1,
        "rate": 0.03,
    }

func _click(button: Button) -> void:
    if button == null:
        return
    await process_frame
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
    await process_frame

func _capture(dimensions: Vector2i, path: String) -> void:
    root.size = dimensions
    await process_frame
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var picture := root.get_texture().get_image()
    t.check(not picture.is_empty(), "capture v0.4 non vide")
    t.equal(picture.save_png(path), OK, "capture v0.4 enregistrée : %s" % path.get_file())

func _cleanup() -> void:
    if FileAccess.file_exists(PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
    if FileAccess.file_exists(PATH + ".tmp") or DirAccess.dir_exists_absolute(PATH + ".tmp"):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + ".tmp"))
