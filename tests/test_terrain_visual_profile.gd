extends RefCounted

func run(t: TestSupport) -> void:
    var pos := Vector2i(12, 31)
    t.equal(TerrainVisualProfile.display_name(&"rock_common"), "Roche commune", "nom roche commune")
    t.equal(TerrainVisualProfile.display_name(&"rock_fragile"), "Roche fragile", "nom roche fragile")
    t.equal(TerrainVisualProfile.display_name(&"rock_dense"), "Roche dense", "nom roche dense")
    t.equal(TerrainVisualProfile.display_name(&"stabilizer"), "Minerai stabilisateur", "nom stabilisant")

    var first := TerrainVisualProfile.edge_inset(pos, 0)
    var second := TerrainVisualProfile.edge_inset(pos, 0)
    t.equal(first, second, "variation d'arête déterministe")
    t.check(first >= 0.0 and first <= 3.0, "inset reste local à la cellule")

    var variant := TerrainVisualProfile.detail_variant(pos, &"rock_fragile")
    t.check(variant >= 0 and variant <= 3, "variante de détail bornée")
