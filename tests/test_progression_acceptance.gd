extends RefCounted

const Game = preload("res://src/industry/industry_game.gd")
const Save = preload("res://src/industry/industry_save.gd")
const Discovery = preload("res://src/industry/industry_discovery.gd")
const PATH := "user://tests/progression_v03_acceptance.json"

func run(t: TestSupport) -> void:
    _cleanup()
    DirAccess.make_dir_recursive_absolute("user://tests")

    var game = Game.new()
    var event_seed := _seed_with_unstable_cavity_at_40()
    t.check(event_seed > 0, "seed déterministe avec cavité instable à 40 m trouvé")
    if event_seed > 0:
        game.world_seed = event_seed

    var initial_iron := float(game.resources["iron"])
    game.advance(10.0)
    t.check(float(game.resources["iron"]) > initial_iron, "production de base active avant toute progression")
    _fund(game)

    _complete_drill(game, t, 10)
    _complete_drill(game, t, 20)
    _complete_drill(game, t, 30)
    t.check(game.upgrade_drill(), "tête I installée après déblocage à 30 m")
    t.equal(game.depth, 30, "palier 30 m atteint par forage")
    t.check(game.discoveries.has("30:0"), "découverte garantie 30 m détectée")
    t.equal(game.discoveries["30:0"]["type"], "rich_vein", "filon riche garanti à 30 m")
    t.check(game.start_exploration("30:0"), "filon riche exploré via API publique")
    _complete_exploration(game, "30:0")
    t.equal(game.discoveries["30:0"]["state"], "exhausted", "filon riche épuisé une seule fois")
    t.check(game.upgrade_center(), "Centre niveau 2 construit à 30 m")
    t.equal(game.center_level, 2, "Centre niveau 2 confirmé")

    _complete_drill(game, t, 40)
    t.check(game.discoveries.has("40:0"), "découverte intermédiaire 40 m générée")
    if game.discoveries.has("40:0"):
        t.equal(game.discoveries["40:0"]["type"], "unstable_cavity", "cavité instable déterministe à 40 m")
        t.check(game.start_exploration("40:0"), "cavité instable explorée")
        _complete_exploration(game, "40:0")
    t.equal(game.pending_events.size(), 1, "Filon instable obtenu naturellement après exploration")

    _complete_drill(game, t, 50)
    _complete_drill(game, t, 60)
    t.check(game.upgrade_drill(), "tête II installée après déblocage à 60 m")
    t.check(game.upgrade_center(), "Centre niveau 3 construit à 60 m")
    t.equal(game.center_level, 3, "Centre niveau 3 confirmé")

    _complete_drill(game, t, 70)
    _complete_drill(game, t, 80)
    _complete_drill(game, t, 90)
    t.equal(game.tech_points, 1, "premier point technologique obtenu à 90 m")
    t.check(game.upgrade_center(), "Centre niveau 4 construit à 90 m")
    t.equal(game.center_level, 4, "Centre niveau 4 confirmé")
    t.check(game.discoveries.has("90:0"), "cavité cristalline garantie détectée")
    t.equal(game.discoveries["90:0"]["type"], "crystal_cavern", "palier 90 m donne la cavité cristalline")
    t.check(game.start_exploration("90:0"), "cavité cristalline explorée")
    _complete_exploration(game, "90:0")
    t.check(game.permanent_sites.has("90:0"), "cavité convertie en site permanent")
    t.equal(game.permanent_sites["90:0"]["active"], true, "site cristallin activé dans la capacité disponible")
    var crystal_before := float(game.resources["crystal"])
    game.advance(10.0)
    t.check(float(game.resources["crystal"]) > crystal_before, "site cristallin produit réellement")
    t.check(game.set_site_active("90:0", false), "site cristallin désactivable")
    t.check(game.set_site_active("90:0", true), "site cristallin réactivable selon capacité")

    t.check(game.set_priority("production"), "priorité Production choisie")
    t.equal(game.priority_branch, "production", "priorité Production active")
    t.check(game.unlock_technology("production_1"), "technologie Production I débloquée")
    t.check(game.build_technology("production_1"), "technologie Production I construite")
    t.check("production_1" in game.built_technologies, "technologie construite conservée dans l'état")

    _complete_drill(game, t, 100)
    _complete_drill(game, t, 110)
    _complete_drill(game, t, 120)
    t.check(game.upgrade_center(), "Centre niveau 5 construit à 120 m")
    t.equal(game.center_level, 5, "Centre niveau 5 confirmé")
    t.check(game.discoveries.has("120:0"), "structure ancienne garantie détectée")
    t.equal(game.discoveries["120:0"]["type"], "ancient_structure", "palier 120 m donne la structure ancienne")
    var tech_before_structure: int = int(game.tech_points)
    t.check(game.start_exploration("120:0"), "structure ancienne explorée")
    _complete_exploration(game, "120:0")
    t.check(game.tech_points > tech_before_structure, "structure ancienne accorde un point technologique")
    t.check(game.permanent_sites.has("120:0"), "structure ancienne reste comme site permanent")

    _complete_drill(game, t, 130)
    _complete_drill(game, t, 140)
    _complete_drill(game, t, 150)
    t.equal(game.depth, 150, "profondeur 150 m atteinte sans mutation directe")
    t.check(150 in game.claimed_milestones, "palier profond 150 m validé")
    t.check(game.upgrade_center(), "Centre niveau 6 construit à 150 m")
    t.equal(game.center_level, 6, "Centre niveau 6 confirmé")

    t.equal(game.pending_events.size(), 1, "Filon instable est resté en attente pendant la progression")
    t.check(game.present_pending_event(), "Filon instable présenté à la demande")
    var iron_rate_before_choice := game.mine_rate("iron")
    t.check(game.choose_event_resource("iron"), "Fer choisi comme priorité du Filon instable")
    t.check(game.mine_rate("iron") > iron_rate_before_choice, "Filon instable double temporairement l'extraction choisie")

    var expected := game.snapshot()
    t.check(Save.new().save_game(PATH, game, 1000.0), "parcours v0.3 sauvegardé")
    var first_load: Dictionary = Save.new().load_game(PATH, 1000.0)
    var second_load: Dictionary = Save.new().load_game(PATH, 1000.0)
    t.equal(first_load["error"], "", "sauvegarde v0.3 relue sans erreur")
    t.check(_equivalent_value(first_load["game"].snapshot(), expected), "rechargement conserve toute la progression")
    t.check(_equivalent_value(second_load["game"].snapshot(), first_load["game"].snapshot()), "rechargements répétés ne dupliquent aucune récompense")
    t.equal(first_load["game"].permanent_sites.size(), game.permanent_sites.size(), "sites permanents non dupliqués")
    t.equal(first_load["game"].tech_points, game.tech_points, "points technologiques non dupliqués")

    _cleanup()

func _complete_drill(game, t: TestSupport, expected_depth: int) -> void:
    t.check(game.start_excavation(), "forage vers %d m lancé" % expected_depth)
    if not game.jobs.has("drill"):
        return
    var remaining := float(game.jobs["drill"]["remaining"])
    game.advance(remaining)
    t.equal(game.depth, expected_depth, "forage vers %d m terminé" % expected_depth)

func _complete_exploration(game, discovery_id: String) -> void:
    if not game.explorations.has(discovery_id):
        return
    game.advance(float(game.explorations[discovery_id]["remaining"]))

func _seed_with_unstable_cavity_at_40() -> int:
    for seed in range(1, 10000):
        if not Discovery.should_generate(seed, 40, 0):
            continue
        var discovery: Dictionary = Discovery.generate(seed, 40, 0, 0.0)
        if str(discovery.get("type", "")) == "unstable_cavity":
            return seed
    return 0

func _equivalent_value(actual: Variant, expected: Variant) -> bool:
    var actual_type := typeof(actual)
    var expected_type := typeof(expected)
    var numeric_types := [TYPE_INT, TYPE_FLOAT]
    if actual_type in numeric_types and expected_type in numeric_types:
        return is_equal_approx(float(actual), float(expected))
    if actual_type == TYPE_DICTIONARY and expected_type == TYPE_DICTIONARY:
        var actual_dict: Dictionary = actual
        var expected_dict: Dictionary = expected
        if actual_dict.size() != expected_dict.size():
            return false
        for key in expected_dict:
            if not actual_dict.has(key) or not _equivalent_value(actual_dict[key], expected_dict[key]):
                return false
        return true
    if actual_type == TYPE_ARRAY and expected_type == TYPE_ARRAY:
        var actual_array: Array = actual
        var expected_array: Array = expected
        if actual_array.size() != expected_array.size():
            return false
        for index in range(expected_array.size()):
            if not _equivalent_value(actual_array[index], expected_array[index]):
                return false
        return true
    return actual == expected

func _fund(game) -> void:
    # Fixture for discovery/event integration; real crafting is exercised by economy_route.
    for resource_id in game.resources:
        game.resources[resource_id] = 10000.0
    game.resources["iron"] = 10000.0
    game.resources["coal"] = 10000.0
    game.resources["copper"] = 10000.0
    game.resources["iron_ingot"] = 1000.0
    game.resources["copper_ingot"] = 1000.0
    game.resources["cable"] = 1000.0
    game.resources["crystal"] = 1000.0

func _cleanup() -> void:
    for path in [PATH, PATH + ".tmp"]:
        if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
