extends SceneTree

const Support = preload("res://tests/test_support.gd")
const Discovery = preload("res://src/industry/industry_discovery.gd")
const PATH := "user://tests/visual_v06_captures.json"

var t = Support.new()
var _screen
var _session
var _world
var _context
var _presenter

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
    _screen = load("res://scenes/industry.tscn").instantiate()
    _session = _screen.get_node("IndustrySession")
    _session.save_path = PATH
    root.add_child(_screen)
    _session.set_process(false)
    await _settle()

    _world = _screen.find_child("MineWorld", true, false)
    _context = _screen.find_child("ContextPanel", true, false)
    _presenter = _screen.find_child("MineInteractionPresenter", true, false)
    t.check(_world != null, "MineWorld disponible pour les captures v0.6")
    t.check(_context != null, "panneau contextuel disponible pour les captures v0.6")
    t.check(_presenter != null, "présentateur disponible pour les captures v0.6")

    await _prepare_state(150, 6)
    _world.set("zoom", 0.75)
    _world.focus_depth(0)
    _context.clear_selection()
    await _capture(Vector2i(1280, 800), folder.path_join("v06-wide-surface.png"))

    await _prepare_state(60, 3)
    _world.set("zoom", 0.75)
    _world.focus_depth(60)
    _context.clear_selection()
    await _capture(Vector2i(1280, 800), folder.path_join("v06-wide-60m.png"))

    await _prepare_state(150, 6)
    _world.set("zoom", 0.75)
    _world.focus_depth(150)
    _context.clear_selection()
    await _capture(Vector2i(1280, 800), folder.path_join("v06-wide-150m.png"))

    await _prepare_state(150, 6)
    _world.set("zoom", 0.75)
    _world.focus_depth(120)
    _context.clear_selection()
    await _settle()
    var deep_discovery := _screen.find_child("Discovery_120_0", true, false) as Button
    t.check(deep_discovery != null, "découverte profonde disponible pour la capture v0.6 sélectionnée")
    if deep_discovery != null:
        deep_discovery.pressed.emit()
        await _settle()
        t.check(_context.visible, "contexte profond visible pour la capture v0.6 sélectionnée")
        if _presenter.has_method("marker_is_emphasized"):
            t.check(_presenter.marker_is_emphasized("Discovery_120_0"), "marqueur profond v0.6 accentué")
    await _capture(Vector2i(1280, 800), folder.path_join("v06-wide-selected.png"))

    await _prepare_state(90, 4)
    _world.set("zoom", 0.75)
    _world.focus_depth(90)
    _context.clear_selection()
    await _capture(Vector2i(720, 1000), folder.path_join("v06-narrow-90m.png"))

    _screen.queue_free()
    await process_frame
    _cleanup()
    print("Visual v0.6 captures: %s" % ("PASS" if t.failures == 0 else "FAIL"))
    quit(t.finish())

func _prepare_state(depth: int, center_level: int) -> void:
    var game = _session.game
    game.depth = depth
    game.center_level = center_level
    game.drill_level = mini(5, maxi(1, 1 + depth / 30))
    game.resources["iron"] = 58911.0
    game.resources["coal"] = 35420.0
    game.resources["copper"] = 29808.0
    game.resources["iron_ingot"] = 23.0
    game.resources["copper_ingot"] = 14.0
    game.resources["cable"] = 8.0
    game.resources["crystal"] = 12.0 if depth >= 90 else 0.0
    game.discoveries.clear()
    game.permanent_sites.clear()
    game.explorations.clear()
    game.jobs.clear()
    game.pending_events.clear()
    game.active_event.clear()

    if depth >= 30:
        game.discoveries["30:0"] = Discovery.generate(123, 30, 0, 0.0)
    if depth >= 60:
        game.discoveries["60:1"] = Discovery.generate(123, 60, 1, 0.0)
    if depth >= 90:
        game.permanent_sites["90:site"] = {
            "type": "crystal_cavern",
            "active": true,
            "capacity": 2,
            "depth": 90,
            "level": 1,
            "rate": 0.03,
        }
    if depth >= 120:
        game.discoveries["120:0"] = Discovery.generate(987, 120, 0, 0.0)
    if depth >= 150:
        game.permanent_sites["150:site"] = {
            "type": "crystal_cavern",
            "active": false,
            "capacity": 2,
            "depth": 150,
            "level": 1,
            "rate": 0.04,
        }

    _session.changed.emit()
    await _settle()

func _settle() -> void:
    await process_frame
    await process_frame
    await process_frame

func _capture(dimensions: Vector2i, path: String) -> void:
    root.size = dimensions
    await _settle()
    await RenderingServer.frame_post_draw
    var picture := root.get_texture().get_image()
    t.check(not picture.is_empty(), "capture v0.6 non vide : %s" % path.get_file())
    t.equal(picture.save_png(path), OK, "capture v0.6 enregistrée : %s" % path.get_file())

func _cleanup() -> void:
    if FileAccess.file_exists(PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
    if FileAccess.file_exists(PATH + ".tmp") or DirAccess.dir_exists_absolute(PATH + ".tmp"):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + ".tmp"))
