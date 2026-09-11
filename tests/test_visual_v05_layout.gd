extends RefCounted

const Layout = preload("res://src/industry/ui/mine_visual_layout.gd")

func run(t: TestSupport) -> void:
    var first := Layout.gallery_profile(60, 0, 150, 6)
    var again := Layout.gallery_profile(60, 0, 150, 6)
    t.equal(first, again, "même profondeur/côté => même profil")

    var variants: Dictionary = {}
    for depth in [12, 30, 60, 90, 120, 150]:
        for side in [0, 1]:
            var profile := Layout.gallery_profile(depth, side, 150, 6)
            variants[str(profile["variant"])] = true
            t.check(float(profile["width_scale"]) >= 0.45 and float(profile["width_scale"]) <= 1.0, "largeur de galerie valide")
            t.check(float(profile["height"]) >= 34.0 and float(profile["height"]) <= 76.0, "hauteur de galerie valide")
            t.check(int(profile["support_spacing"]) >= 40, "espacement des supports valide")
            t.check(int(profile["lamp_stride"]) >= 1, "densité de lampes valide")
    t.check(variants.size() >= 4, "plusieurs silhouettes observables dans un parcours profond")

    var shallow := Layout.geology_profile(30)
    var deep := Layout.geology_profile(150)
    t.check(float(deep["cyan_strength"]) > float(shallow["cyan_strength"]), "profondeur plus cyan")
    t.check(int(deep["fracture_count"]) >= int(shallow["fracture_count"]), "profondeur au moins aussi détaillée")

    var surface_1 := Layout.surface_profile(1)
    var surface_6 := Layout.surface_profile(6)
    t.check(surface_6["modules"].size() > surface_1["modules"].size(), "surface évolutive avec le Centre")
