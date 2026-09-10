extends RefCounted

func run(t: TestSupport) -> void:
    var backdrop := CaveBackdrop.new()
    backdrop.configure(Vector2i(64, 72), 16)

    t.equal(backdrop.has_method("geology_masses"), true, "fond expose les masses géologiques décoratives")
    if not backdrop.has_method("geology_masses"):
        backdrop.free()
        return

    var masses: Array = backdrop.geology_masses()
    t.check(masses.size() >= 6, "fond contient plusieurs masses géologiques")

    var left_anchored := 0
    var right_anchored := 0
    for polygon in masses:
        t.check(polygon is PackedVector2Array, "masse géologique représentée par un polygone")
        if not (polygon is PackedVector2Array):
            continue
        var points := polygon as PackedVector2Array
        t.check(points.size() >= 4, "masse géologique suffisamment détaillée")
        for point in points:
            if point.x <= 0.0:
                left_anchored += 1
                break
        for point in points:
            if point.x >= 1024.0:
                right_anchored += 1
                break

    t.check(left_anchored >= 2, "plusieurs masses visuelles ancrées à gauche")
    t.check(right_anchored >= 2, "plusieurs masses visuelles ancrées à droite")
    backdrop.free()
