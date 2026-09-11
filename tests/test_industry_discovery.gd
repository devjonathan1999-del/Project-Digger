extends RefCounted

const Discovery = preload("res://src/industry/industry_discovery.gd")

func run(t) -> void:
    var a := Discovery.generate(123456, 30, 0, 0.0)
    var b := Discovery.generate(123456, 30, 0, 0.0)
    t.check(a == b, "même seed/profondeur/slot = même découverte")
    t.check(a.has("id") and a.has("kind") and a.has("hint") and a.has("reward"), "découverte sérialisable complète")

    var low := Discovery.generate(123456, 90, 1, 0.0)
    var boosted := Discovery.generate(123456, 90, 1, 0.4)
    t.check(float(boosted["quality"]) >= float(low["quality"]), "le plancher Exploration ne baisse jamais la qualité")
    t.check(float(boosted["quality"]) >= 0.4, "plancher de qualité respecté")
