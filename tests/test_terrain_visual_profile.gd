extends RefCounted

const PROFILE_PATH := "res://src/view/terrain_visual_profile.gd"

func run(t: TestSupport) -> void:
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
