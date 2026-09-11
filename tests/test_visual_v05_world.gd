extends SceneTree

const Support = preload("res://tests/test_support.gd")
const PATH := "user://tests/visual_v05_world.json"

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

    session.game.depth = 150
    session.game.center_level = 6
    session.changed.emit()
    await process_frame
    await process_frame

    var renderer = screen.find_child("MineSceneRenderer", true, false)
    t.check(renderer != null, "renderer v0.5 présent")
    if renderer != null:
        var variants = renderer.get("gallery_variants_seen")
        var silhouettes = renderer.get("gallery_silhouette_count")
        var broken = renderer.get("broken_rail_count")
        var alcoves = renderer.get("alcove_count")
        t.check(variants is Dictionary and variants.size() >= 4, "au moins quatre variantes visibles/connues")
        t.check(silhouettes is int and silhouettes >= 8, "silhouettes gauche/droite générées")
        t.check(broken is int and broken >= 1, "au moins une rupture de rails")
        t.check(alcoves is int and alcoves >= 1, "au moins un renfoncement")

    var world = screen.find_child("MineWorld", true, false)
    t.check(world != null, "monde mine disponible")
    if world != null:
        for target_name in ["Mine_iron", "Mine_coal", "Mine_copper", "Drill"]:
            t.check(world.find_child(target_name, true, false) != null, "zone tactile %s conservée" % target_name)

    screen.queue_free()
    await process_frame
    _cleanup()
    print("Visual v0.5 world: %s" % ("PASS" if t.failures == 0 else "FAIL"))
    quit(t.finish())

func _cleanup() -> void:
    if FileAccess.file_exists(PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
    if FileAccess.file_exists(PATH + ".tmp") or DirAccess.dir_exists_absolute(PATH + ".tmp"):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + ".tmp"))
