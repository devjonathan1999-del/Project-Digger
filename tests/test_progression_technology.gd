extends RefCounted

const IndustryGameScript = preload("res://src/industry/industry_game.gd")

func run(t: TestSupport) -> void:
    test_unlock_build_and_production_priority(t)
    test_logistics_capacity_and_priority_safety(t)
    test_exploration_quality_floor(t)
    test_priority_cooldown_advances_with_time(t)

func test_unlock_build_and_production_priority(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    game.depth = 90
    game.tech_points = 3
    _fund(game)

    var base_rate := game.mine_rate("iron")
    t.check(game.unlock_technology("production_1"), "Production I débloquée")
    t.equal(game.tech_points, 2, "un point technologique consommé")
    t.check(game.build_technology("production_1"), "Production I construite")
    t.check(is_equal_approx(game.mine_rate("iron"), base_rate * 1.10), "Production I ajoute dix pour cent")

    t.check(game.set_priority("production"), "priorité Production choisie")
    t.check(is_equal_approx(game.mine_rate("iron"), base_rate * 1.20), "priorité Production ajoute dix pour cent supplémentaires")
    t.equal(game.set_priority("exploration"), false, "cooldown empêche le changement immédiat")

func test_logistics_capacity_and_priority_safety(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    game.depth = 90
    game.tech_points = 2
    _fund(game)
    game.center_level = 1

    t.check(game.unlock_technology("logistics_1"), "Logistique I débloquée")
    t.check(game.build_technology("logistics_1"), "Logistique I construite")
    t.equal(game.total_capacity(), 4, "Logistique I ajoute un point permanent")
    t.check(game.set_priority("logistics"), "priorité Logistique choisie")
    t.equal(game.total_capacity(), 5, "priorité Logistique ajoute un point temporaire")

    game.permanent_sites = {
        "a": {"type": "crystal_cavern", "active": true, "capacity": 2, "depth": 90, "level": 1, "rate": 0.03},
        "b": {"type": "ancient_structure", "active": true, "capacity": 2, "depth": 120, "level": 1, "rate": 0.0},
        "c": {"type": "crystal_cavern", "active": true, "capacity": 1, "depth": 100, "level": 1, "rate": 0.02},
    }
    game.priority_cooldown_remaining = 0.0
    t.check(game.priority_block_reason("production") != "", "quitter Logistique refusé si cinq points sont encore utilisés")
    t.equal(game.set_priority("production"), false, "priorité ne crée pas un état au-dessus de la capacité")

func test_exploration_quality_floor(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    game.depth = 90
    game.tech_points = 2
    _fund(game)

    t.check(game.unlock_technology("exploration_1"), "Exploration I débloquée")
    t.check(game.build_technology("exploration_1"), "Exploration I construite")
    t.check(is_equal_approx(game.quality_floor(), 0.20), "Exploration I fixe un plancher de vingt pour cent")
    t.check(game.set_priority("exploration"), "priorité Exploration choisie")
    t.check(is_equal_approx(game.quality_floor(), 0.40), "priorité Exploration cumule le plancher")

func test_priority_cooldown_advances_with_time(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    game.depth = 90
    t.check(game.set_priority("production"), "première priorité choisie")
    t.check(is_equal_approx(game.priority_cooldown_remaining, 300.0), "cooldown démarré à cinq minutes")
    game.advance(299.0)
    t.equal(game.set_priority("exploration"), false, "changement encore bloqué avant cinq minutes")
    game.advance(1.0)
    t.check(game.set_priority("exploration"), "changement autorisé après cinq minutes")

func _fund(game) -> void:
    game.resources["iron"] = 1000.0
    game.resources["coal"] = 1000.0
    game.resources["copper"] = 1000.0
    game.resources["iron_ingot"] = 100.0
    game.resources["copper_ingot"] = 100.0
    game.resources["cable"] = 100.0
    game.resources["crystal"] = 100.0
