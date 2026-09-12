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
    var session = screen.get_node("IndustrySession")
    session.save_path = "user://portrait-v081-test-save.json"
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

    # Resource input must follow the illustrated portrait lanes, including camera motion.
    var world = screen.find_child("MineWorld", true, false)
    var presenter = screen.find_child("MineInteractionPresenter", true, false)
    var asset_renderer = screen.find_child("MineAssetRenderer", true, false)
    var shortcut_panel := screen.find_child("MineShortcutPanel", true, false) as Control
    if world.get_global_rect().position.y < shortcut_panel.get_global_rect().end.y + 4.0:
        _fail("the portrait mine must start below the dedicated shortcut strip", failures)
    for shortcut in camera_shortcuts.get_children():
        if shortcut is Button and shortcut.custom_minimum_size.y < 44.0:
            _fail("depth shortcuts must retain comfortable portrait touch targets", failures)
    for test_width in [480.0, 720.0]:
        var surface_rects: Dictionary = asset_renderer._surface_v07_rects(test_width, 112.0, ["workshop", "silo", "ventilation", "crane"], true)
        var shaft_half := float(asset_renderer.Layout.shaft_profile(test_width, 150)["width"]) * 0.5
        for id in surface_rects:
            var rect: Rect2 = surface_rects[id]
            if rect.end.x > test_width or (rect.position.x < test_width * 0.5 + shaft_half and rect.end.x > test_width * 0.5 - shaft_half):
                _fail("surface assets must stay in their side lanes at %d px" % test_width, failures)
        var ids := surface_rects.keys()
        for i in range(ids.size()):
            for j in range(i + 1, ids.size()):
                if surface_rects[ids[i]].intersects(surface_rects[ids[j]]):
                    _fail("surface assets must not overlap at %d px" % test_width, failures)
    for camera_depth in [0, 90]:
        world.focus_depth(camera_depth)
        await process_frame
        await process_frame
        var targets: Dictionary = asset_renderer._resource_v07_rects(world.size, 150, true)
        for resource_id in ["iron", "coal", "copper"]:
            var button := world.find_child("Mine_" + resource_id, false, false) as Button
            var target: Rect2 = targets[resource_id + "_installation"]
            if button.get_rect().get_center().distance_to(target.get_center()) > 1.0:
                _fail("portrait %s input must follow its asset after focusing %d m" % [resource_id, camera_depth], failures)
            if button.size.y < 44.0:
                _fail("portrait resource input must remain comfortable", failures)
        if absf(world._depth_to_y(60.0) - asset_renderer._depth_to_y(60.0)) > 0.5:
            _fail("depth markers, timers and input must share the same portrait origin", failures)
        if presenter.marker_alpha("iron") < 0.75:
            _fail("portrait resource labels must be readable without hover", failures)

    # Check both world breakpoints without relying on container resize ordering.
    var original_world_width: float = world.size.x
    for test_width in [720.0, 1000.0, original_world_width]:
        world.size.x = test_width
        asset_renderer.set_scene_state({"viewport_size": world.size, "scroll_depth": world.scroll_depth, "zoom": world.zoom, "depth": 150})
        if absf(world._depth_to_y(60.0) - asset_renderer._depth_to_y(60.0)) > 0.5:
            _fail("world and renderer origins must agree across width breakpoints", failures)
    world.refresh()
    world.focus_depth(0)
    await process_frame
    await process_frame
    var held_button := world.find_child("Mine_iron", false, false) as Button
    var held_at := held_button.get_global_rect().get_center()
    var press := InputEventMouseButton.new()
    press.button_index = MOUSE_BUTTON_LEFT
    press.position = held_at
    press.pressed = true
    root.push_input(press)
    world.refresh()
    if not is_instance_valid(held_button):
        _fail("a production refresh must not destroy a held touch target", failures)
    var release := InputEventMouseButton.new()
    release.button_index = MOUSE_BUTTON_LEFT
    release.position = held_at
    release.pressed = false
    root.push_input(release)
    await process_frame
    if not presenter.marker_is_emphasized("iron"):
        _fail("the held tap must select its mine after a production refresh", failures)
    screen.find_child("ContextPanel", true, false).clear_selection()

    var args := OS.get_cmdline_user_args()
    if "--screenshots" in args:
        var folder := args[args.find("--screenshots") + 1]
        DirAccess.make_dir_recursive_absolute(folder)
        screen._dismiss_offline()
        var mine_world = screen.find_child("MineWorld", true, false)
        session.game.depth = 50
        session.game.center_level = 2
        session.changed.emit()
        mine_world.focus_depth(0)
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder.path_join("v081-portrait-50m.png"))
        root.size = Vector2i(480, 854)
        await process_frame
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder.path_join("v081-portrait-480px.png"))
        root.size = Vector2i(720, 1280)
        session.game.depth = 150
        session.game.center_level = 6
        session.changed.emit()
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
