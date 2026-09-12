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
        "scroll_depth": 0.0,
        "zoom": 1.0,
    })
    await process_frame

    var metrics: Dictionary = node.metrics()
    t.equal(str(node.name), "MineModuleRenderer", "renderer de modules nommé")
    t.check(int(metrics.get("surface_module_count", 0)) >= 4, "modules de surface comptés")
    t.check(int(metrics.get("shaft_station_count", 0)) >= 2, "stations du puits comptées")
    t.check(int(metrics.get("resource_installation_count", 0)) >= 3, "installations de ressources comptées")
    t.check(int(metrics.get("iron_identity_score", 0)) >= 4, "identité visuelle fer")
    t.check(int(metrics.get("coal_identity_score", 0)) >= 4, "identité visuelle charbon")
    t.check(int(metrics.get("copper_identity_score", 0)) >= 4, "identité visuelle cuivre")

    node.set_scene_state({
        "depth": 120,
        "center_level": 6,
        "animation_phase": 0.0,
        "viewport_size": Vector2(1280, 800),
        "scroll_depth": 0.0,
        "zoom": 1.0,
        "permanent_sites": {
            "90:site": {
                "type": "crystal_cavern",
                "active": true,
                "depth": 90,
            },
        },
    })
    await process_frame
    metrics = node.metrics()
    t.check(float(metrics.get("shaft_width", 0.0)) >= 120.0, "puits central élargi")
    t.check(float(metrics.get("shaft_width", 999.0)) <= 150.0, "largeur du puits bornée")
    t.check(int(metrics.get("surface_feature_count", 0)) >= 6, "surface lisible comme base minière")
    t.equal(bool(metrics.get("elevator_visible", false)), true, "cage ascenseur visible")
    t.check(int(metrics.get("shaft_station_count", 0)) >= 4, "stations visibles aux horizons débloqués")
    t.check(int(metrics.get("utility_line_count", 0)) >= 4, "câbles et conduites du puits présents")
    t.check(int(metrics.get("crystal_identity_score", 0)) >= 3, "identité visuelle cristal profond")

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
        var texture := Assets.texture_for(id)
        t.check(texture != null, "texture charge: %s" % id)
        if texture == null:
            continue
        var image := texture.get_image()
        t.check(image != null and not image.is_empty(), "image lisible: %s" % id)
        if image == null or image.is_empty():
            continue
        var max_x := maxi(0, image.get_width() - 1)
        var max_y := maxi(0, image.get_height() - 1)
        for corner in [Vector2i(0, 0), Vector2i(max_x, 0), Vector2i(0, max_y), Vector2i(max_x, max_y)]:
            t.check(image.get_pixelv(corner).a <= 0.10, "fond transparent %s coin %s" % [id, str(corner)])
