extends RefCounted

func run(t: TestSupport) -> void:
    test_catalog(t)

func test_catalog(t: TestSupport) -> void:
    var catalog = preload("res://src/core/material_catalog.gd").new()
    t.equal(catalog.get_def(&"rock_common").diggable, true, "roche commune creusable")
    t.equal(catalog.get_def(&"rock_dense").diggable, false, "roche dense non creusable")
    t.equal(catalog.get_def(&"rock_fragile").mass, 0.8, "masse roche friable")
    t.check(catalog.get_def(&"stabilizer").stability_bonus > 0.0, "stabilisant ajoute de la stabilité")
    t.equal(catalog.get_def(&"stabilizer").conductive, true, "stabilisant conducteur")
