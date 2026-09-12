extends RefCounted

const IndustryGameScript = preload("res://src/industry/industry_game.gd")

func run(t: TestSupport) -> void:
    test_milestone_completion_generates_discovery_once(t)
    test_retroactive_generation_is_independent_from_claimed_rewards(t)
    test_milestone_rewards_are_idempotent_to_150m(t)
    test_same_seed_rebuilds_same_depth_history(t)

func test_milestone_completion_generates_discovery_once(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    game.depth = 20
    game.drill_level = 2
    game.resources["mechanical_chassis"] = 1.0
    t.check(game.start_excavation(), "forage vers 30 m lancé")
    game.advance(game.jobs["drill"]["remaining"])

    t.equal(game.depth, 30, "palier 30 m atteint")
    t.check(30 in game.claimed_milestones, "palier 30 m marqué")
    t.check(game.discoveries.has("30:0"), "découverte garantie 30 m générée")
    t.equal(game.discoveries["30:0"]["type"], "rich_vein", "première poche garantie correcte")

    var before := game.snapshot()
    game.apply_retroactive_milestones()
    t.equal(game.snapshot(), before, "rejouer les paliers ne duplique rien")

func test_retroactive_generation_is_independent_from_claimed_rewards(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    game.depth = 90
    game.drill_level = 4
    game.world_seed = 424242
    game.claimed_milestones = [30, 60, 90]
    game.tech_points = 1
    game.discoveries = {}

    game.apply_retroactive_milestones()
    t.equal(game.tech_points, 1, "récompense techno déjà réclamée non dupliquée")
    t.check(game.discoveries.has("30:0"), "poche historique 30 m recréée malgré palier déjà marqué")
    t.check(game.discoveries.has("90:0"), "cavité historique 90 m recréée malgré palier déjà marqué")
    t.equal(game.discoveries["90:0"]["type"], "crystal_cavern", "cavité cristalline 90 m garantie")

func test_milestone_rewards_are_idempotent_to_150m(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    game.depth = 150
    game.drill_level = 5
    game.apply_retroactive_milestones()

    t.equal(game.tech_points, 3, "trois points technologiques garantis jusqu'à 150 m")
    for depth in [30, 60, 90, 120, 150]:
        t.check(depth in game.claimed_milestones, "palier %d m marqué" % depth)

    game.apply_retroactive_milestones()
    t.equal(game.tech_points, 3, "points technologiques rétroactifs attribués une seule fois")

func test_same_seed_rebuilds_same_depth_history(t: TestSupport) -> void:
    var a = IndustryGameScript.new()
    a.depth = 150
    a.drill_level = 5
    a.world_seed = 987654
    a.apply_retroactive_milestones()

    var b = IndustryGameScript.new()
    b.depth = 150
    b.drill_level = 5
    b.world_seed = 987654
    b.apply_retroactive_milestones()

    t.equal(a.discoveries, b.discoveries, "même seed = même historique de découvertes")
    t.equal(a.discoveries_for_depth(90), b.discoveries_for_depth(90), "lecture par profondeur reproductible")
