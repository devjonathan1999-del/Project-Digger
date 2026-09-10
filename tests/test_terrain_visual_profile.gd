extends RefCounted

const PROFILE_PATH := "res://src/view/terrain_visual_profile.gd"

func run(t: TestSupport) -> void:
    test_profile(t)
    test_renderer_coordinate_conversion(t)

func test_profile(t: TestSupport) -> void:
    var exists := ResourceLoader.exists(PROFILE_PATH)
    t.equal(exists, true, "profil visuel terrain disponible")
    if not exists:
        return

    var profile_script = load(PROFILE_PATH)
    var profile = profile_script.new()
    var pos := Vector2i(12, 31)

    t.equal(profile.call("display_name", &"rock_common"), "Roche commune", "nom roche commune")
    t.equal(profile.call("display_name", &"rock_fragile"), "Roche fragile", "nom roche fragile")
    t.equal(profile.call("display_name", &"rock_dense"), "Roche dense", "nom roche dense")
    t.equal(profile.call("display_name", &"stabilizer"), "Minerai stabilisateur", "nom stabilisant")

    var first: float = profile.call("edge_inset", pos, 0)
    var second: float = profile.call("edge_inset", pos, 0)
    t.equal(first, second, "variation d'arête déterministe")
    t.check(first >= 0.0 and first <= 3.0, "inset reste local à la cellule")

    var variant: int = profile.call("detail_variant", pos, &"rock_fragile")
    t.check(variant >= 0 and variant <= 3, "variante de détail bornée")

func test_renderer_coordinate_conversion(t: TestSupport) -> void:
    var renderer := TerrainRenderer.new()
    var has_api := renderer.has_method("cell_from_local")
    t.equal(has_api, true, "conversion locale du renderer disponible")
    if not has_api:
        renderer.free()
        return
    t.equal(renderer.call("cell_from_local", Vector2(0.0, 0.0)), Vector2i(0, 0), "origine vers cellule 0,0")
    t.equal(renderer.call("cell_from_local", Vector2(31.9, 48.1)), Vector2i(1, 3), "conversion locale respecte CELL_SIZE")
    renderer.free()
