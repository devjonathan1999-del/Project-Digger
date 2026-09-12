extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(720, 1280)
    var screen = load("res://scenes/industry.tscn").instantiate()
    var session = screen.get_node("IndustrySession")
    session.save_path = "user://economy-ui-isolated-test.json"
    session._initialized = true
    session.last_seen_unix = Time.get_unix_time_from_system()
    session.set_process(false)
    root.add_child(screen)
    session.set_process(false)
    session.save_blocked = true
    await process_frame
    await process_frame
    var panel = screen._industry_panel
    var failures: Array[String] = []
    if panel._facilities.size() != 6:
        failures.append("Industry must expose six working facilities")
    if screen.find_child("RecipeSearch", true, false) == null:
        failures.append("Industry must provide recipe search")
    if screen.find_child("AccessibleRecipes", true, false) == null:
        failures.append("Industry must provide accessible recipe filtering")
    if screen.find_child("Inventory_iron", true, false) == null:
        failures.append("Industry must show dedicated inventory quantities")
    var search = screen.find_child("RecipeSearch", true, false)
    var accessible = screen.find_child("AccessibleRecipes", true, false)
    if search != null and accessible != null:
        var workshop: Dictionary = panel._facilities["workshop"]
        var cable_index: int = workshop["recipes"].find("cable")
        workshop["select"].select(cable_index)
        panel.refresh()
        var held_button = workshop["button"]
        var selected: int = workshop["select"].selected
        for i in 4:
            session.changed.emit()
        if workshop["button"] != held_button or workshop["select"].selected != selected:
            failures.append("Per-frame refresh must retain buttons and selected recipes")
        search.text = "zzzz-no-recipe"
        search.text_changed.emit(search.text)
        for facility in panel._facilities:
            if not panel._facilities[facility]["recipes"].is_empty() or not panel._facilities[facility]["button"].disabled:
                failures.append("Empty search must safely disable every production action")
        search.text = ""
        search.text_changed.emit("")
        if workshop["recipes"][workshop["select"].selected] != "cable":
            failures.append("Clearing an empty filter must restore selection")
        search.text = "Engrenage"
        search.text_changed.emit(search.text)
        session.changed.emit()
        search.text = ""
        search.text_changed.emit("")
        if workshop["recipes"][workshop["select"].selected] != "cable":
            failures.append("Nonempty filters must retain preferred recipe through per-frame refresh")
        accessible.button_pressed = true
        panel.refresh()
        for facility in panel._facilities:
            for id in panel._facilities[facility]["recipes"]:
                if int(panel.Catalog.RECIPES[id]["depth"]) > session.game.depth:
                    failures.append("Accessible filter must hide recipes locked by depth")
        accessible.button_pressed = false
        session.game.resources["iron"] = 123.0
        session.game.depth = 1000
        panel.refresh()
        if not screen.find_child("Inventory_iron", true, false).text.contains("123"):
            failures.append("Inventory must display owned quantity")
        var wire: Dictionary = panel._facilities["workshop"]
        wire["select"].select(wire["recipes"].find("copper_wire"))
        wire["quantity"].value = 3
        panel.refresh()
        if not wire["cost"].text.contains("12 ×"):
            failures.append("Three copper-wire lots must display twelve output units")
        for id in session.game.resources:
            session.game.resources[id] = 1000.0
        for facility in panel._facilities:
            var factory: Dictionary = panel._facilities[facility]
            factory["select"].select(0)
            panel.refresh()
            factory["button"].pressed.emit()
            if not session.game.jobs.has(facility):
                failures.append("Facility %s must start a real production job" % facility)
        session.game.advance(1.0)
        panel.refresh()
        for facility in panel._facilities:
            if panel._facilities[facility]["progress"].value <= 0:
                failures.append("Running facility %s must display progress" % facility)
        session.game.permanent_sites["1000:0"] = {"type": "ancient_structure", "depth": 1000, "capacity": 1, "active": true, "level": 1, "rate": 0.0}
        session.game.discoveries["1000:0"] = load("res://src/industry/industry_discovery.gd").generate(1, 1000, 0, 0)
        session.game.discoveries["1000:0"]["type"] = "ancient_structure"
        session.game.discoveries["1000:0"]["state"] = "opened"
        screen._center_panel.refresh()
        var recovery = screen.find_child("SiteRecovery_1000_0", true, false)
        if recovery == null or recovery.disabled:
            failures.append("Opened active ancient site must expose recovery action")
        else:
            screen._select_view("center")
            await process_frame
            await process_frame
            var press := InputEventMouseButton.new()
            press.button_index = MOUSE_BUTTON_LEFT
            press.position = recovery.get_global_rect().get_center()
            press.pressed = true
            root.push_input(press)
            session.changed.emit()
            if not is_instance_valid(recovery) or recovery != screen.find_child("SiteRecovery_1000_0", true, false):
                failures.append("Held recovery action must retain its button through refresh")
            var release := InputEventMouseButton.new()
            release.button_index = MOUSE_BUTTON_LEFT
            release.position = press.position
            release.pressed = false
            root.push_input(release)
            await process_frame
            if not session.game.jobs.has("recovery"):
                failures.append("Recovery button must start session recovery job")
        screen._select_view("industry")
        for width in [480, 720]:
            root.size = Vector2i(width, 1280)
            await process_frame
            await process_frame
            if panel.get_combined_minimum_size().x > width - 28:
                failures.append("Industry must fit width %d without horizontal overflow" % width)
    if not screen._mine_renderer.has_method("next_progression_caption"):
        failures.append("Deep drilling must describe the new equipment progression")
    else:
        if screen._mine_renderer.next_progression_caption(1000) != "Palier 1500 m":
            failures.append("Drilling at 1000m must identify the final transition")
        if screen._mine_renderer.next_progression_caption(1500) != "Objectif atteint":
            failures.append("Drilling at 1500m must identify completed progression")
    var ancient_target = screen.find_child("Site_1000_0", true, false)
    if ancient_target == null or screen._interaction_presenter._label_for_target(ancient_target) != "Structure ancienne":
        failures.append("Ancient structures must retain their economic identity in the mine")
    var ancient_status = screen.find_child("Status_Site_1000_0", true, false)
    if ancient_status == null or not ancient_status.text.contains("Récupération"):
        failures.append("Ancient structures must show recovery instead of a fake zero production rate")
    var args := OS.get_cmdline_user_args()
    var capture_index := args.find("--screenshots")
    if capture_index >= 0 and capture_index + 1 < args.size():
        var folder := args[capture_index + 1]
        DirAccess.make_dir_recursive_absolute(folder)
        root.size = Vector2i(720, 1280)
        screen._select_view("industry")
        screen.find_child("PageScroll", true, false).scroll_vertical = 0
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder.path_join("economy-industry-720.png"))
        screen._select_view("mine")
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder.path_join("economy-surface-720.png"))
        screen._mine_world.focus_depth(1000)
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder.path_join("economy-deep-720.png"))
    for failure in failures:
        push_error(failure)
    screen.queue_free()
    await process_frame
    if failures.is_empty():
        print("Economy UI tests passed")
    quit(0 if failures.is_empty() else 1)
