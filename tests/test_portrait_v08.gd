extends SceneTree

const SCREEN_PATH := "res://scenes/industry.tscn"
const RENDERER_PATH := "res://src/industry/ui/mine_asset_renderer.gd"

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String, failures: Array[String]) -> void:
    push_error(message)
    failures.append(message)

func _run() -> void:
    var failures: Array[String] = []

    var viewport := Vector2i(
        int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)),
        int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
    )
    if viewport != Vector2i(720, 1280):
        _fail("v0.8 base viewport must be portrait 720x1280, got %s" % viewport, failures)

    var override_size := Vector2i(
        int(ProjectSettings.get_setting("display/window/size/window_width_override", 0)),
        int(ProjectSettings.get_setting("display/window/size/window_height_override", 0))
    )
    if override_size != Vector2i(720, 1280):
        _fail("desktop preview must open in portrait 720x1280, got %s" % override_size, failures)

    if int(ProjectSettings.get_setting("display/window/handheld/orientation", 0)) != 1:
        _fail("mobile orientation must be locked to portrait", failures)
    if str(ProjectSettings.get_setting("display/window/stretch/mode", "")) != "canvas_items":
        _fail("portrait layout must use canvas_items stretch mode", failures)
    if str(ProjectSettings.get_setting("display/window/stretch/aspect", "")) != "expand":
        _fail("portrait layout must use expand stretch aspect", failures)

    root.size = Vector2i(720, 1280)
    var screen = load(SCREEN_PATH).instantiate()
    root.add_child(screen)
    await process_frame
    await process_frame
    await process_frame

    var hud := screen.find_child("CompactHUD", true, false) as GridContainer
    if hud == null or hud.columns != 5:
        _fail("portrait HUD must use five columns / two compact rows", failures)

    var mine_panel := screen.find_child("MinePanel", true, false) as Control
    if mine_panel == null or mine_panel.custom_minimum_size.y < 820.0:
        _fail("portrait mine viewport must reserve at least 820 px vertically", failures)

    var bottom_navigation := screen.find_child("BottomNavigation", true, false) as HBoxContainer
    if bottom_navigation == null or bottom_navigation.custom_minimum_size.y < 52.0:
        _fail("portrait bottom navigation must reserve a 52 px touch strip", failures)

    for tab_name in ["TabMine", "TabIndustrie", "TabCentre", "TabTechnologie"]:
        var tab := screen.find_child(tab_name, true, false) as Button
        if tab == null or tab.custom_minimum_size.y < 48.0:
            _fail("%s must expose a portrait touch target >= 48 px" % tab_name, failures)

    var camera_shortcuts := screen.find_child("MineCameraShortcuts", true, false) as HFlowContainer
    if camera_shortcuts == null or camera_shortcuts.custom_minimum_size.x < 480.0 or camera_shortcuts.size.y > 48.0:
        _fail("portrait depth shortcuts must stay on one compact row", failures)

    var page_scroll := screen.find_child("PageScroll", true, false) as ScrollContainer
    if page_scroll == null or page_scroll.get_h_scroll_bar().max_value > 721.0:
        _fail("portrait UI must not overflow horizontally", failures)

    var session = screen.get_node("IndustrySession")
    session.set_process(false)
    session.game.depth = 150
    session.game.center_level = 6
    session.changed.emit()
    await process_frame

    var renderer_script := load(RENDERER_PATH)
    var renderer = renderer_script.new()
    renderer.size = Vector2(720, 1280)
    renderer.set_scene_state({
        "depth": 150,
        "center_level": 6,
        "mine_levels": {"iron": 5, "coal": 5, "copper": 5},
        "discoveries": {},
        "permanent_sites": [],
        "jobs": {},
        "scroll_depth": 0.0,
        "zoom": 1.0,
        "animation_phase": 0.0,
        "viewport_size": Vector2(720, 1280),
    })

    if not renderer.has_method("_resource_v07_rects"):
        _fail("portrait renderer must expose resource layout targets", failures)
    else:
        var rects: Dictionary = renderer._resource_v07_rects(Vector2(720, 1280), 150, true)
        for id in ["iron_installation", "coal_installation", "copper_installation", "crystal_installation"]:
            if not rects.has(id):
                _fail("portrait resource layout missing %s" % id, failures)

        if failures.is_empty():
            var iron: Rect2 = rects["iron_installation"]
            var coal: Rect2 = rects["coal_installation"]
            var copper: Rect2 = rects["copper_installation"]
            var crystal: Rect2 = rects["crystal_installation"]
            var left_limit := 300.0
            var right_limit := 420.0
            if iron.end.x > left_limit or copper.end.x > left_limit:
                _fail("iron and copper must stay in the left portrait lane", failures)
            if coal.position.x < right_limit or crystal.position.x < right_limit:
                _fail("coal and crystal must stay in the right portrait lane", failures)
            if not (iron.get_center().y + 120.0 < coal.get_center().y and coal.get_center().y + 120.0 < copper.get_center().y and copper.get_center().y + 120.0 < crystal.get_center().y):
                _fail("portrait resource installations must be staggered vertically by depth", failures)

    renderer.free()

    var args := OS.get_cmdline_user_args()
    if "--screenshots" in args:
        var folder := args[args.find("--screenshots") + 1]
        DirAccess.make_dir_recursive_absolute(folder)
        var mine_world = screen.find_child("MineWorld", true, false)
        mine_world.focus_depth(0)
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        var surface_image := root.get_texture().get_image()
        surface_image.save_png(folder.path_join("v08-portrait-surface.png"))
        mine_world.focus_depth(90)
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        var deep_image := root.get_texture().get_image()
        deep_image.save_png(folder.path_join("v08-portrait-90m.png"))

    screen.queue_free()
    await process_frame
    quit(1 if not failures.is_empty() else 0)
