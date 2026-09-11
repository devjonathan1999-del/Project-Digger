extends SceneTree

const Support = preload("res://tests/test_support.gd")
const PATH := "user://tests/visual_v04_world.json"

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

    session.game.center_level = 3
    session.game.depth = 100
    session.changed.emit()
    await process_frame
    await process_frame

    var renderer = screen.find_child("MineSceneRenderer", true, false)
    t.check(renderer != null, "renderer industriel dédié présent")
    if renderer != null:
        t.check(int(renderer.get("surface_module_count")) >= 4, "surface industrielle lisible")
        t.check(int(renderer.get("gallery_detail_count")) >= 3, "galeries structurées")
        var shallow := float(renderer.call("accent_strength_for_depth", 30))
        var deep := float(renderer.call("accent_strength_for_depth", 100))
        t.check(deep > shallow * 1.5, "accent cyan renforcé avec la profondeur")
        t.check(float(renderer.get("deep_accent_strength")) >= 0.40, "état profond transmis au renderer")

    var world = screen.find_child("MineWorld", true, false)
    t.check(world != null, "monde mine disponible")
    if world != null:
        for id in ["iron", "coal", "copper"]:
            var target = world.find_child("Mine_" + id, true, false)
            t.check(target != null, "zone tactile %s conservée" % id)
            if target != null:
                t.check(target.modulate.a <= 0.08, "zone %s quasi invisible" % id)
                t.check(target.size.x >= 44.0 and target.size.y >= 34.0, "zone %s reste tactile" % id)
            var decor_label = world.find_child("Label_" + id, true, false)
            t.check(decor_label != null, "étiquette décorative %s séparée" % id)

        var drill_target = world.find_child("Drill", true, false)
        t.check(drill_target != null, "zone tactile foreuse conservée")
        if drill_target != null:
            t.check(drill_target.modulate.a <= 0.08, "zone foreuse intégrée au décor")
        t.check(world.find_child("Label_Drill", true, false) != null, "étiquette foreuse séparée")

    screen.queue_free()
    await process_frame
    _cleanup()
    print("Visual v0.4 world: %s" % ("PASS" if t.failures == 0 else "FAIL"))
    quit(t.finish())

func _cleanup() -> void:
    if FileAccess.file_exists(PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
    if FileAccess.file_exists(PATH + ".tmp") or DirAccess.dir_exists_absolute(PATH + ".tmp"):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + ".tmp"))
