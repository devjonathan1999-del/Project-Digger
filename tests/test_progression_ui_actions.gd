extends SceneTree

const Support = preload("res://tests/test_support.gd")
const Discovery = preload("res://src/industry/industry_discovery.gd")
const PATH := "user://tests/progression_ui_actions.json"

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

    for resource_id in session.game.resources:
        session.game.resources[resource_id] = 2000.0
    session.game.depth = 90
    session.game.drill_level = 4
    session.game.center_level = 4
    session.game.discoveries["30:0"] = Discovery.generate(123, 30, 0, 0.0)
    session.game.permanent_sites["90:site"] = {
        "type": "crystal_cavern",
        "active": false,
        "capacity": 2,
        "depth": 90,
        "level": 1,
        "rate": 0.03,
    }
    session.changed.emit()
    await process_frame

    var mine_world = screen.find_child("MineWorld", true, false)
    t.check(mine_world != null, "monde mine disponible pour les actions contextuelles")

    mine_world.focus_depth(0)
    await process_frame
    await _click(screen.find_child("Mine_iron", true, false))
    var primary = screen.find_child("ContextPrimary", true, false)
    t.check(primary.visible and not primary.disabled, "amélioration de mine proposée dans le contexte")
    var mine_level_before := int(session.game.mine_levels["iron"])
    await _click(primary)
    t.equal(session.game.mine_levels["iron"], mine_level_before + 1, "clic contextuel améliore réellement la mine")

    mine_world.focus_depth(90)
    await process_frame
    await _click(screen.find_child("Drill", true, false))
    primary = screen.find_child("ContextPrimary", true, false)
    t.check(primary.visible and not primary.disabled, "forage proposé dans le contexte foreuse")
    await _click(primary)
    t.check(session.game.jobs.has("drill"), "clic contextuel démarre réellement le forage")
    t.check(screen.find_child("Timer_Drill", true, false) != null, "timer forage affiché dans le monde")

    mine_world.focus_depth(30)
    await process_frame
    await _click(screen.find_child("Discovery_30_0", true, false))
    primary = screen.find_child("ContextPrimary", true, false)
    t.check(primary.visible and not primary.disabled, "exploration proposée dans le contexte découverte")
    await _click(primary)
    t.check(session.game.explorations.has("30:0"), "clic contextuel démarre réellement l'exploration")
    t.check(screen.find_child("Timer_Exploration_30_0", true, false) != null, "timer exploration affiché dans le monde")

    mine_world.focus_depth(90)
    await process_frame
    await _click(screen.find_child("Site_90_site", true, false))
    primary = screen.find_child("ContextPrimary", true, false)
    t.check(primary.visible and not primary.disabled, "activation du site proposée")
    await _click(primary)
    t.equal(session.game.permanent_sites["90:site"]["active"], true, "clic contextuel active le site")
    t.check(screen.find_child("Status_Site_90_site", true, false) != null, "production active signalée dans le monde")
    t.equal(primary.text, "DÉSACTIVER", "action contextuelle bascule après activation")
    await _click(primary)
    t.equal(session.game.permanent_sites["90:site"]["active"], false, "second clic contextuel désactive le site")

    screen.queue_free()
    await process_frame
    _cleanup()
    print("Progression UI actions: %s" % ("PASS" if t.failures == 0 else "FAIL"))
    quit(t.finish())

func _click(button: Button) -> void:
    t.check(button != null, "bouton présent avant clic contextuel")
    if button == null:
        return
    var scroll = button.find_parent("PageScroll") as ScrollContainer
    if scroll != null:
        scroll.ensure_control_visible(button)
    await process_frame
    await process_frame
    t.check(not button.disabled, "%s disponible avant clic contextuel" % button.name)
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
    if FileAccess.file_exists(PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
    if FileAccess.file_exists(PATH + ".tmp") or DirAccess.dir_exists_absolute(PATH + ".tmp"):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + ".tmp"))
