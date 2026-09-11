extends SceneTree

# Import contract for the local final-graphics asset pack.
const Support = preload("res://tests/test_support.gd")
const Renderer = preload("res://src/industry/ui/mine_module_renderer.gd")
const Assets = preload("res://src/industry/ui/mine_v06_assets.gd")

var t = Support.new()

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(1280, 800)
    _check_assets()

    var node := Renderer.new()
    root.add_child(node)
    node.size = Vector2(1280, 800)
    node.set_scene_state({
        "depth": 60,
        "center_level": 4,
        "animation_phase": 0.0,
        "viewport_size": Vector2(1280, 800),
    })
    await process_frame

    var metrics: Dictionary = node.metrics()
    t.equal(str(node.name), "MineModuleRenderer", "renderer de modules nommé")
    t.check(int(metrics.get("surface_module_count", 0)) >= 4, "modules de surface comptés")
    t.check(int(metrics.get("shaft_station_count", 0)) >= 2, "stations du puits comptées")
    t.check(int(metrics.get("resource_installation_count", 0)) >= 3, "installations de ressources comptées")

    node.queue_free()
    await process_frame
    print("Visual v0.6 modules: %s" % ("PASS" if t.failures == 0 else "FAIL"))
    quit(t.finish())

func _check_assets() -> void:
    for id in [
        "surface_workshop",
        "surface_silo",
        "surface_control",
        "surface_ventilation",
        "surface_crane",
        "shaft_station",
        "iron_module",
        "coal_module",
        "copper_module",
        "crystal_module",
    ]:
        t.check(Assets.has_asset(id), "asset existe: %s" % id)
        t.check(Assets.texture_for(id) != null, "texture charge: %s" % id)
