extends RefCounted

func run(t: TestSupport) -> void:
    var packed := load("res://scenes/vertical_slice.tscn") as PackedScene
    t.check(packed != null, "scene vertical slice chargeable")
    if packed == null:
        return

    var scene := packed.instantiate()
    for node_path in [
        "CaveBackdrop",
        "TerrainRenderer",
        "AncientOverlay",
        "ResolutionFx",
        "GameCamera",
        "GameInput",
        "FeedbackController",
        "HUD",
    ]:
        t.check(scene.get_node_or_null(node_path) != null, "node requis: %s" % node_path)

    var camera := scene.get_node_or_null("GameCamera") as Camera2D
    if camera != null:
        t.check(camera.zoom.x >= 1.6, "cadrage initial immersif v0.2")
        t.equal(camera.has_method("configure_bounds"), true, "caméra bornée à la caverne")
    scene.free()
