extends SceneTree

const ASSET_PATH := "res://src/industry/ui/mine_final_assets.gd"
const SCREEN_PATH := "res://scenes/industry.tscn"
const RENDERER_PATH := "res://src/industry/ui/mine_asset_renderer.gd"
const ASSET_IDS := ["rock", "surface", "shaft", "copper_seam", "cyan_seam", "iron_installation", "coal_installation", "copper_installation", "crystal_installation", "drill", "elevator"]

func _initialize() -> void:
    call_deferred("_run")

func _check(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition:
        push_error(message)
        failures.append(message)

func _run() -> void:
    var failures: Array[String] = []
    # Runtime loading gives a useful RED result before the new loader is implemented.
    if not FileAccess.file_exists(ASSET_PATH):
        push_error("Final art direction raster loader is missing: " + ASSET_PATH)
        quit(1)
        return
    var assets = load(ASSET_PATH)
    for id in ASSET_IDS:
        _check(assets.has_asset(id), "Final raster asset unavailable: " + id, failures)
        var texture = assets.texture_for(id)
        _check(texture is Texture2D, "Final raster asset must return a Texture2D: " + id, failures)
        if texture is Texture2D:
            _check(texture.get_width() > 0 and texture.get_height() > 0, "Final raster must have positive dimensions: " + id, failures)
            if id.ends_with("_installation") or id.ends_with("_seam") or id in ["drill", "elevator"]:
                var image: Image = texture.get_image()
                _check(image != null and image.detect_alpha() != Image.ALPHA_NONE, "Chamber sprite must preserve transparent cutout pixels: " + id, failures)

    root.size = Vector2i(720, 1280)
    var screen = load(SCREEN_PATH).instantiate()
    var session = screen.get_node("IndustrySession")
    session.save_path = "user://final-art-direction-test-save.json"
    session.set_process(false)
    root.add_child(screen)
    session.set_process(false)
    await process_frame
    await process_frame
    screen._dismiss_offline()
    session.game.depth = 150
    session.game.center_level = 6
    session.changed.emit()
    await process_frame
    var world = screen.find_child("MineWorld", true, false)
    var renderer = screen.find_child("MineAssetRenderer", true, false)
    var context = screen.find_child("ContextPanel", true, false)
    var resources_before: Dictionary = session.game.resources.duplicate(true)
    var jobs_before: Dictionary = session.game.jobs.duplicate(true)
    var depth_before: int = session.game.depth
    _check(renderer.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Final renderer must let resource input pass through", failures)

    for camera_depth in [0, 90]:
        for test_zoom in [1.0, 1.2]:
            world.zoom = test_zoom
            world.focus_depth(camera_depth)
            world.refresh()
            await process_frame
            await process_frame
            var targets: Dictionary = renderer._resource_v07_rects(world.size, 150, true)
            var shaft_half := float(renderer.Layout.shaft_profile(world.size.x, 150)["width"]) * 0.5
            for resource_id in ["iron", "coal", "copper"]:
                var button := world.find_child("Mine_" + resource_id, false, false) as Button
                _check(button != null, "Final scene must retain resource button: " + resource_id, failures)
                if button == null:
                    continue
                var target: Rect2 = targets[resource_id + "_installation"]
                _check(button.get_rect().get_center().distance_to(target.get_center()) <= 1.0, "Final %s input must match chamber at focus %d / zoom %.1f" % [resource_id, camera_depth, test_zoom], failures)
                _check(button.size.y >= 44.0, "Final resource touch target must remain >=44px: " + resource_id, failures)
                _check(target.end.x <= world.size.x * 0.5 - shaft_half or target.position.x >= world.size.x * 0.5 + shaft_half, "Final chamber must stay outside central shaft: " + resource_id, failures)
            _check(absf(world._depth_to_y(60.0) - renderer._depth_to_y(60.0)) <= 0.5, "Final camera and zoom must share renderer depth coordinates", failures)
            var drill := world.find_child("Drill", false, false) as Button
            _check(drill != null, "Final scene must retain the drill input target", failures)
            if drill != null:
                var rig_rect: Rect2 = renderer.final_drill_rect()
                _check(drill.get_rect().get_center().distance_to(rig_rect.get_center()) <= 1.0, "Final drill input must match visible rig at focus %d / zoom %.1f" % [camera_depth, test_zoom], failures)
                _check(drill.size.x >= 44.0 and drill.size.y >= 44.0, "Final drill must retain a >=44px touch target on both axes", failures)
                # At deep focus the actual rig is visible; click the artwork's
                # center so an offset oversized Button cannot hide the defect.
                if drill.visible and Rect2(Vector2.ZERO, world.size).has_point(rig_rect.get_center()):
                    context.clear_selection()
                    var rig_at: Vector2 = world.global_position + rig_rect.get_center()
                    var rig_press := InputEventMouseButton.new()
                    rig_press.button_index = MOUSE_BUTTON_LEFT
                    rig_press.position = rig_at
                    rig_press.pressed = true
                    root.push_input(rig_press)
                    var rig_release := InputEventMouseButton.new()
                    rig_release.button_index = MOUSE_BUTTON_LEFT
                    rig_release.position = rig_at
                    rig_release.pressed = false
                    root.push_input(rig_release)
                    await process_frame
                    _check(context.visible and context._kind == "drill" and context._id == "drill", "Final real pointer click on visible rig must select drill at focus %d / zoom %.1f" % [camera_depth, test_zoom], failures)
                    context.clear_selection()

        # Exercise Godot pointer routing rather than emitting the button signal.
        context.clear_selection()
        world.zoom = 1.0
        world.focus_depth(camera_depth)
        world.refresh()
        await process_frame
        await process_frame
        var resource_id: String = "iron" if camera_depth == 0 else "copper"
        var button := world.find_child("Mine_" + resource_id, false, false) as Button
        if button != null:
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
            _check(context.visible and context._kind == "mine" and context._id == resource_id, "Final real pointer click must select %s at focus %d" % [resource_id, camera_depth], failures)
        context.clear_selection()

    renderer.set_scene_state({"viewport_size": world.size, "depth": 50, "scroll_depth": 90.0, "zoom": 1.2, "animation_phase": 7.0})
    _check(session.game.depth == depth_before and session.game.resources == resources_before and session.game.jobs == jobs_before, "Rendering, camera and selection must not mutate game depth, resource wallet or jobs", failures)
    # An opened permanent crystal site must be drawn and selected at its real
    # depth, rather than at a decorative fixed chamber depth.
    var discovery_script = load("res://src/industry/industry_discovery.gd")
    session.game.discoveries["90:0"] = discovery_script.generate(session.game.world_seed, 90, 0, 0.0)
    session.game.permanent_sites.erase("90:0")
    session.changed.emit()
    world.zoom = 1.0
    world.focus_depth(90)
    await process_frame
    await process_frame
    var unopened_binding: Dictionary = renderer.final_crystal_binding()
    _check(unopened_binding.get("kind", "") == "discovery" and unopened_binding.get("id", "") == "90:0", "Unopened crystal artwork must bind to its real discovery", failures)
    var unopened_rects: Dictionary = renderer._resource_v07_rects(world.size, 150, true)
    var unopened_button := world.find_child("Discovery_90_0", false, false) as Button
    if unopened_button != null and unopened_rects.has("crystal_installation"):
        var unopened_rect: Rect2 = unopened_rects["crystal_installation"]
        _check(unopened_button.get_rect().get_center().distance_to(unopened_rect.get_center()) <= 1.0, "Unopened crystal input must match its illustrated cave", failures)
        context.clear_selection()
        var unopened_at: Vector2 = world.global_position + unopened_rect.get_center()
        var unopened_press := InputEventMouseButton.new()
        unopened_press.button_index = MOUSE_BUTTON_LEFT
        unopened_press.position = unopened_at
        unopened_press.pressed = true
        root.push_input(unopened_press)
        var unopened_release := InputEventMouseButton.new()
        unopened_release.button_index = MOUSE_BUTTON_LEFT
        unopened_release.position = unopened_at
        root.push_input(unopened_release)
        await process_frame
        _check(context.visible and context._kind == "discovery" and context._id == "90:0", "Real pointer on unopened crystal artwork must select its discovery", failures)
        context.clear_selection()
    else:
        _check(false, "Unopened crystal must expose its discovery button and cave geometry", failures)
    session.game.discoveries["90:0"]["state"] = "opened"
    session.game.permanent_sites["90:0"] = {"type": "crystal_cavern", "depth": 90, "active": false, "capacity": 2, "level": 1, "rate": 0.03}
    session.changed.emit()
    world.zoom = 1.0
    world.focus_depth(90)
    await process_frame
    await process_frame
    var sites_before: Dictionary = session.game.permanent_sites.duplicate(true)
    var discoveries_before: Dictionary = session.game.discoveries.duplicate(true)
    var crystal_targets: Dictionary = renderer._resource_v07_rects(world.size, 150, true)
    _check(crystal_targets.has("crystal_installation"), "Opened crystal site must have chamber geometry", failures)
    var crystal_button := world.find_child("Site_90_0", false, false) as Button
    _check(crystal_button != null, "Opened crystal site must retain its real input target", failures)
    if crystal_button != null and crystal_targets.has("crystal_installation"):
        var crystal_rect: Rect2 = crystal_targets["crystal_installation"]
        _check(crystal_button.get_rect().get_center().distance_to(crystal_rect.get_center()) <= 1.0, "Opened crystal site input must match its illustrated chamber at actual 90m depth", failures)
        _check(crystal_button.size.x >= 44.0 and crystal_button.size.y >= 44.0, "Crystal site must retain a >=44px touch target on both axes", failures)
        context.clear_selection()
        var crystal_at: Vector2 = world.global_position + crystal_rect.get_center()
        var crystal_press := InputEventMouseButton.new()
        crystal_press.button_index = MOUSE_BUTTON_LEFT
        crystal_press.position = crystal_at
        crystal_press.pressed = true
        root.push_input(crystal_press)
        var crystal_release := InputEventMouseButton.new()
        crystal_release.button_index = MOUSE_BUTTON_LEFT
        crystal_release.position = crystal_at
        crystal_release.pressed = false
        root.push_input(crystal_release)
        await process_frame
        _check(context.visible and context._kind == "site" and context._id == "90:0", "Real pointer click on crystal chamber must select the actual permanent site", failures)
        context.clear_selection()
    _check(session.game.permanent_sites == sites_before and session.game.discoveries == discoveries_before and session.game.resources == resources_before, "Crystal rendering and selection must preserve site, discovery and resource state", failures)
    _check(renderer.has_method("final_crystal_binding"), "Final crystal painter must expose its binding to real discovery/site state", failures)
    if renderer.has_method("final_crystal_binding"):
        var binding: Dictionary = renderer.final_crystal_binding()
        _check(binding.get("kind") == "site" and binding.get("id") == "90:0" and int(binding.get("depth", -1)) == 90 and not bool(binding.get("active", true)), "Crystal binding must identify the real inactive permanent site at 90m", failures)
        _check(session.game.set_site_active("90:0", true), "Crystal fixture must be activatable through the existing gameplay API", failures)
        session.changed.emit()
        await process_frame
        await process_frame
        binding = renderer.final_crystal_binding()
        _check(bool(binding.get("active", false)), "Final crystal artwork must reflect activated real site state", failures)
    # Desktop keeps the historical renderer and public geometry available.
    var desktop = load(RENDERER_PATH).new()
    desktop.size = Vector2(1000, 800)
    desktop.set_scene_state({"viewport_size": desktop.size, "depth": 150, "scroll_depth": 90.0, "zoom": 1.0})
    var desktop_targets: Dictionary = desktop._resource_v07_rects(desktop.size, 150, false)
    for resource_id in ["iron", "coal", "copper"]:
        _check(desktop_targets.has(resource_id + "_installation"), "Desktop fallback must retain resource geometry: " + resource_id, failures)
    _check(is_finite(desktop._depth_to_y(60.0)), "Desktop fallback must retain finite depth mapping", failures)
    desktop.free()
    screen.queue_free()
    await process_frame
    quit(1 if not failures.is_empty() else 0)
