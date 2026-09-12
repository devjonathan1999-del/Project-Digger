extends RefCounted

const IndustryGameScript = preload("res://src/industry/industry_game.gd")

func run(t: TestSupport) -> void:
    test_center_progression_and_capacity(t)
    test_capacity_rejection_is_atomic(t)
    test_exhaustible_pocket_consumes_cost_and_rewards_once(t)
    test_crystal_cavern_becomes_permanent_producer(t)

func test_center_progression_and_capacity(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    game.depth = 90
    _fund(game)

    t.check(game.upgrade_center(), "Centre niveau 2 acheté")
    t.check(game.upgrade_center(), "Centre niveau 3 acheté")
    t.check(game.upgrade_center(), "Centre niveau 4 acheté")
    t.equal(game.center_level, 4, "Centre atteint le niveau autorisé par 90 m")
    t.equal(game.total_capacity(), 6, "Centre niveau 4 fournit six points")
    t.check(game.center_upgrade_block_reason() != "", "Centre niveau 5 verrouillé avant 120 m")

func test_capacity_rejection_is_atomic(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    game.permanent_sites = {
        "a": {"type": "crystal_cavern", "active": true, "capacity": 2, "depth": 90, "level": 1, "rate": 0.03},
        "b": {"type": "crystal_cavern", "active": false, "capacity": 2, "depth": 100, "level": 1, "rate": 0.03},
    }
    t.equal(game.used_capacity(), 2, "deux points utilisés")
    var before := game.snapshot()
    t.check(game.site_toggle_block_reason("b", true) != "", "activation au-delà de la capacité expliquée")
    t.equal(game.set_site_active("b", true), false, "activation impossible refusée")
    t.equal(game.snapshot(), before, "refus capacité sans mutation")

func test_exhaustible_pocket_consumes_cost_and_rewards_once(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    game.depth = 30
    game.world_seed = 12345
    game.apply_retroactive_milestones()
    game.resources["iron"] = 100.0
    var initial_reward := int(game.discoveries["30:0"]["reward"]["amount"])

    t.check(game.start_exploration("30:0"), "exploration du filon riche lancée")
    t.equal(game.resources["iron"], 90.0, "coût d'exploration prélevé au départ")
    t.equal(game.discoveries["30:0"]["state"], "exploring", "poche marquée en exploration")
    var duration := float(game.explorations["30:0"]["remaining"])
    game.advance(duration)

    t.equal(game.discoveries["30:0"]["state"], "exhausted", "filon épuisable terminé")
    t.equal(game.explorations.has("30:0"), false, "job d'exploration retiré")
    t.check(game.resources["iron"] >= 90.0 + initial_reward, "récompense du filon créditée")
    var after := game.snapshot()
    t.equal(game.start_exploration("30:0"), false, "poche épuisée non relançable")
    t.equal(game.snapshot(), after, "poche épuisée sans double récompense")

func test_crystal_cavern_becomes_permanent_producer(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    game.depth = 90
    game.world_seed = 777
    game.apply_retroactive_milestones()
    _fund(game)

    t.check(game.discoveries.has("90:0"), "cavité cristalline garantie présente")
    t.check(game.start_exploration("90:0"), "exploration cavité lancée")
    game.advance(game.explorations["90:0"]["remaining"])

    t.check(game.permanent_sites.has("90:0"), "cavité convertie en site permanent")
    t.equal(game.permanent_sites["90:0"]["capacity"], 2, "cavité coûte deux points de capacité")
    t.equal(game.permanent_sites["90:0"]["active"], true, "cavité activée si capacité disponible")
    var before := float(game.resources["crystal"])
    game.advance(100.0)
    t.check(game.resources["crystal"] > before, "site cristallin actif produit du cristal")

func _fund(game) -> void:
    for resource_id in game.resources:
        game.resources[resource_id] = 1000.0
    game.resources["iron"] = 1000.0
    game.resources["coal"] = 1000.0
    game.resources["copper"] = 1000.0
    game.resources["iron_ingot"] = 100.0
    game.resources["copper_ingot"] = 100.0
    game.resources["cable"] = 100.0
    game.resources["crystal"] = 100.0
