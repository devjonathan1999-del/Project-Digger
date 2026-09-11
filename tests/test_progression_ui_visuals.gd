extends SceneTree

const Support = preload("res://tests/test_support.gd")
const PATH := "user://tests/progression_ui_visuals.json"

var t = Support.new()

# Task 12 verrouille des états visuels, jamais des récompenses économiques.
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
    session.game.depth = 120
    session.game.drill_level = 5
    session.game.center_level = 5
    session.game.permanent_sites["90:crystal"] = {
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
    t.check(mine_world != null, "monde mine disponible pour les états visuels")
    t.check(screen.find_child("ElevatorVisual", true, false) != null, "ascenseur visuel présent")
    t.check(screen.find_child("ConveyorLeft", true, false) != null, "premier convoyeur présent")
    t.check(screen.find_child("ConveyorRight", true, false) != null, "second convoyeur présent")
    t.check(screen.find_child("MineCart", true, false) != null, "wagonnet visuel présent")
    var worker_count := 0
    for child in mine_world.find_children("Worker_*", "Control", true, false):
        worker_count += 1
    t.check(worker_count >= 3 and worker_count <= 6, "densité d'équipes limitée à 3–6 silhouettes")

    var has_visual_process: bool = mine_world.has_method("_process")
    t.check(has_visual_process, "boucle d'animation visuelle présente")
    if has_visual_process:
        var phase_before := float(mine_world.get("animation_phase"))
        mine_world._process(0.5)
        var phase_after := float(mine_world.get("animation_phase"))
        t.check(phase_after > phase_before, "phase d'animation purement visuelle progresse")

    var mine_activity = screen.find_child("MineActivity_iron", true, false)
    t.check(mine_activity != null and mine_activity.visible, "mine active signalée visuellement")

    var drill_activity = screen.find_child("DrillActivity", true, false)
    t.check(drill_activity != null and not drill_activity.visible, "foreuse au repos sans animation active")
    t.check(session.start_excavation(), "chantier démarré pour l'état visuel")
    await process_frame
    drill_activity = screen.find_child("DrillActivity", true, false)
    t.check(drill_activity != null and drill_activity.visible, "forage actif signalé visuellement")

    var crystal_activity = screen.find_child("CrystalActivity_90_crystal", true, false)
    t.check(crystal_activity != null, "cavité cristalline représentée")
    var inactive_alpha: float = crystal_activity.modulate.a if crystal_activity != null else 0.0
    t.check(session.set_site_active("90:crystal", true), "cavité activée pour le rendu")
    await process_frame
    crystal_activity = screen.find_child("CrystalActivity_90_crystal", true, false)
    t.check(crystal_activity != null and bool(crystal_activity.get_meta("active", false)), "cavité active expose son état visuel")
    t.check(crystal_activity != null and crystal_activity.modulate.a > inactive_alpha, "cavité active renforcée visuellement")

    mine_world.focus_depth(150)
    mine_world.queue_redraw()
    await process_frame
    t.check(bool(mine_world.get("deep_zone_visible")), "zone profonde 150 m expose un état graphique dédié")

    screen.queue_free()
    await process_frame
    _cleanup()
    print("Progression UI visuals: %s" % ("PASS" if t.failures == 0 else "FAIL"))
    quit(t.finish())

func _cleanup() -> void:
    for path in [PATH, PATH + ".tmp"]:
        if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
