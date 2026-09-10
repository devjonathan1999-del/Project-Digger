extends RefCounted

func run(t: TestSupport) -> void:
    var packed := load("res://scenes/vertical_slice.tscn") as PackedScene
    t.check(packed != null, "scene vertical slice chargeable")
    if packed == null:
        return
    var scene := packed.instantiate()
    t.check(scene.get_node_or_null("CaveBackdrop") != null, "fond de caverne présent")
    t.check(scene.get_node_or_null("TerrainRenderer") != null, "renderer terrain présent")
    t.check(scene.get_node_or_null("AncientOverlay") != null, "overlay ancien présent")
    t.check(scene.get_node_or_null("ResolutionFx") != null, "FX de résolution présents")
    scene.free()
