extends RefCounted

const IndustryCatalogScript = preload("res://src/industry/industry_catalog.gd")
const IndustryGameScript = preload("res://src/industry/industry_game.gd")

func run(t: TestSupport) -> void:
    test_initial_stock_and_automatic_extraction(t)
    test_batch_reserves_inputs_and_credits_output_once(t)
    test_facilities_run_concurrent_jobs(t)
    test_batch_rejections_do_not_mutate(t)
    test_upgrade_costs_limits_and_rates(t)
    test_excavation_requirements_and_rate_threshold(t)
    test_large_advance_matches_small_steps_across_excavation(t)
    test_sub_epsilon_advances_preserve_elapsed_time(t)
    test_snapshot_restore_active_jobs_and_deep_copy(t)
    test_restore_rejects_invalid_data_without_mutation(t)

func test_initial_stock_and_automatic_extraction(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    t.equal(game.resources, {
        "iron": 12.0,
        "coal": 8.0,
        "copper": 8.0,
        "iron_ingot": 0.0,
        "copper_ingot": 0.0,
        "cable": 0.0,
        "crystal": 0.0,
    }, "stocks initiaux complets")

    var report: Dictionary = game.advance(10.0)
    t.check(is_equal_approx(game.resources["iron"], 14.0), "dix secondes produisent deux fers")
    t.check(is_equal_approx(game.resources["coal"], 9.2), "dix secondes produisent 1,2 charbon")
    t.check(is_equal_approx(game.resources["copper"], 9.0), "dix secondes produisent un cuivre")
    t.check(is_equal_approx(report["produced"]["iron"], 2.0), "rapport de production du fer")
    t.equal(report["completed"], [], "aucun travail terminé")
    t.equal(report["depth_gained"], 0, "aucune profondeur gagnée")

func test_batch_reserves_inputs_and_credits_output_once(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    game.advance(10.0)
    var before: Dictionary = game.snapshot()
    t.equal(game.start_batch("cable", 1), false, "câble sans lingots refusé")
    t.equal(game.snapshot(), before, "aucune dépense en cas de refus")
    t.check(game.start_batch("iron_ingot", 2), "deux lingots lancés")
    t.check(is_equal_approx(game.resources["iron"], 6.0), "huit fers réservés")
    t.check(is_equal_approx(game.resources["coal"], 7.2), "deux charbons réservés")
    game.advance(39.0)
    t.equal(game.resources["iron_ingot"], 0.0, "lot incomplet")
    var report: Dictionary = game.advance(1.0)
    t.equal(game.resources["iron_ingot"], 2.0, "lot livré une fois")
    t.equal(report["completed"], ["furnace"], "four signalé terminé")
    t.equal(report["produced"]["iron_ingot"], 2.0, "sortie du lot rapportée")
    game.advance(100.0)
    t.equal(game.resources["iron_ingot"], 2.0, "pas de double crédit")

func test_facilities_run_concurrent_jobs(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    game.resources["iron_ingot"] = 4.0
    game.resources["copper_ingot"] = 4.0
    t.check(game.start_batch("iron_ingot", 1), "four démarré")
    t.check(game.start_batch("cable", 1), "atelier démarré en parallèle")
    t.check(game.start_excavation(), "forage démarré en parallèle")
    t.equal(game.jobs.size(), 3, "trois installations occupées")

    var first: Dictionary = game.advance(20.0)
    t.equal(first["completed"], ["furnace"], "seul le four termine après vingt secondes")
    t.equal(game.resources["iron_ingot"], 4.0, "le four remplace le lingot réservé par l'atelier")
    t.check(is_equal_approx(game.jobs["workshop"]["remaining"], 20.0), "atelier encore actif")
    t.check(is_equal_approx(game.jobs["drill"]["remaining"], 10.0), "forage encore actif")

    var second: Dictionary = game.advance(20.0)
    t.equal(second["completed"], ["drill", "workshop"], "forage puis atelier terminent")
    t.equal(game.resources["cable"], 1.0, "atelier livre le câble")
    t.equal(game.depth, 10, "forage gagne dix mètres")
    t.equal(second["depth_gained"], 10, "profondeur gagnée rapportée")
    t.equal(game.jobs, {}, "installations libérées")

func test_batch_rejections_do_not_mutate(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    for request in [["missing", 1], ["iron_ingot", 0], ["iron_ingot", 11]]:
        var before: Dictionary = game.snapshot()
        t.check(game.batch_block_reason(request[0], request[1]) != "", "lot invalide explique son refus")
        t.equal(game.start_batch(request[0], request[1]), false, "lot invalide refusé")
        t.equal(game.snapshot(), before, "lot invalide sans mutation")

    game.resources["iron"] = 0.0
    var poor_before: Dictionary = game.snapshot()
    t.check(game.batch_block_reason("iron_ingot", 1) != "", "stock insuffisant expliqué")
    t.equal(game.start_batch("iron_ingot", 1), false, "stock insuffisant refusé")
    t.equal(game.snapshot(), poor_before, "stock insuffisant sans mutation")

    game.resources["iron"] = 100.0
    t.check(game.start_batch("iron_ingot", 1), "premier lot accepté")
    var busy_before: Dictionary = game.snapshot()
    t.check(game.batch_block_reason("copper_ingot", 1) != "", "four occupé expliqué")
    t.equal(game.start_batch("copper_ingot", 1), false, "second lot du four refusé")
    t.equal(game.snapshot(), busy_before, "four occupé sans mutation")

func test_upgrade_costs_limits_and_rates(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    t.equal(game.mine_upgrade_cost("iron"), {"iron": 8, "coal": 4}, "coût mine niveau un")
    t.equal(game.drill_upgrade_cost(), {"iron_ingot": 2, "cable": 1}, "coût foreuse niveau un")
    t.check(game.upgrade_mine("iron"), "mine de fer améliorée")
    t.equal(game.mine_levels["iron"], 2, "niveau mine incrémenté")
    t.equal(game.resources["iron"], 4.0, "fer du coût prélevé")
    t.equal(game.resources["coal"], 4.0, "charbon du coût prélevé")
    t.check(is_equal_approx(game.mine_rate("iron"), 0.4), "nouveau débit de mine")
    game.advance(10.0)
    t.check(is_equal_approx(game.resources["iron"], 8.0), "mine améliorée produit au nouveau débit")

    game.mine_levels["iron"] = IndustryCatalogScript.MAX_MINE_LEVEL
    var mine_before: Dictionary = game.snapshot()
    t.equal(game.upgrade_mine("iron"), false, "niveau mine maximum refusé")
    t.equal(game.snapshot(), mine_before, "refus mine maximum sans mutation")
    t.equal(game.upgrade_mine("missing"), false, "id mine inconnu refusé")

    game.drill_level = IndustryCatalogScript.MAX_DRILL_LEVEL
    var drill_before: Dictionary = game.snapshot()
    t.equal(game.upgrade_drill(), false, "niveau foreuse maximum refusé")
    t.equal(game.snapshot(), drill_before, "refus foreuse maximum sans mutation")

func test_excavation_requirements_and_rate_threshold(t: TestSupport) -> void:
    var blocked = IndustryGameScript.new()
    blocked.depth = 20
    t.check(blocked.excavation_block_reason() != "", "chantier vers trente mètres bloqué au niveau un")
    var blocked_before: Dictionary = blocked.snapshot()
    t.equal(blocked.start_excavation(), false, "forage insuffisant refusé")
    t.equal(blocked.snapshot(), blocked_before, "forage refusé sans mutation")

    var game = IndustryGameScript.new()
    game.depth = 20
    game.drill_level = 2
    t.check(is_equal_approx(game.excavation_duration(), 20.0), "durée dépend profondeur et niveau")
    t.check(game.start_excavation(), "chantier vers trente mètres autorisé niveau deux")
    game.advance(20.0)
    t.equal(game.depth, 30, "chantier atteint trente mètres")
    t.check(is_equal_approx(game.mine_rate("iron"), 0.23), "palier de débit ouvert à trente mètres")

func test_large_advance_matches_small_steps_across_excavation(t: TestSupport) -> void:
    var large = IndustryGameScript.new()
    large.depth = 20
    large.drill_level = 2
    t.check(large.start_excavation(), "forage long pas démarré")
    var large_report: Dictionary = large.advance(3600.0)

    var stepped = IndustryGameScript.new()
    stepped.depth = 20
    stepped.drill_level = 2
    t.check(stepped.start_excavation(), "forage pas à pas démarré")
    var stepped_depth_gained := 0
    for index in range(360):
        var report: Dictionary = stepped.advance(10.0)
        stepped_depth_gained += int(report["depth_gained"])

    for id in IndustryCatalogScript.RESOURCES:
        t.check(is_equal_approx(large.resources[id], stepped.resources[id]), "grand intervalle égale petits intervalles pour %s" % id)
    t.equal(large.depth, stepped.depth, "profondeur identique quel que soit le pas")
    t.equal(large.jobs, stepped.jobs, "travaux identiques quel que soit le pas")
    t.equal(large_report["depth_gained"], stepped_depth_gained, "rapport profondeur indépendant du pas")

func test_sub_epsilon_advances_preserve_elapsed_time(t: TestSupport) -> void:
    var whole = IndustryGameScript.new()
    whole.advance(0.0000012)

    var split = IndustryGameScript.new()
    var first: Dictionary = split.advance(0.0000006)
    var second: Dictionary = split.advance(0.0000006)
    var split_iron := float(first["produced"].get("iron", 0.0)) + float(second["produced"].get("iron", 0.0))

    t.check(split_iron > 0.0, "les intervalles positifs sous epsilon produisent")
    t.check(absf(float(split.resources["iron"]) - float(whole.resources["iron"])) < 0.000000000001, "fractionner un petit intervalle ne perd pas de temps")

func test_snapshot_restore_active_jobs_and_deep_copy(t: TestSupport) -> void:
    var source = IndustryGameScript.new()
    source.resources["iron_ingot"] = 4.0
    source.resources["copper_ingot"] = 4.0
    t.check(source.start_batch("cable", 2), "lot actif créé pour restauration")
    t.check(source.start_excavation(), "forage actif créé pour restauration")
    source.advance(5.0)
    var saved: Dictionary = source.snapshot()

    var restored = IndustryGameScript.new()
    t.check(restored.restore(saved), "snapshot valide restauré")
    t.equal(restored.snapshot(), saved, "état et travaux actifs restaurés")
    saved["resources"]["iron"] = 999.0
    saved["jobs"]["workshop"]["remaining"] = 1.0
    t.check(not is_equal_approx(restored.resources["iron"], 999.0), "ressources restaurées copiées profondément")
    t.check(not is_equal_approx(restored.jobs["workshop"]["remaining"], 1.0), "travaux restaurés copiés profondément")
    var detached: Dictionary = restored.snapshot()
    detached["mine_levels"]["iron"] = 9
    t.equal(restored.mine_levels["iron"], 1, "snapshot retourné détaché du modèle")

func test_restore_rejects_invalid_data_without_mutation(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    t.check(game.start_batch("iron_ingot", 1), "travail de référence démarré")
    var baseline: Dictionary = game.snapshot()
    var invalid_states: Array[Dictionary] = []

    var negative: Dictionary = baseline.duplicate(true)
    negative["resources"]["iron"] = -1.0
    invalid_states.append(negative)
    var nan_stock: Dictionary = baseline.duplicate(true)
    nan_stock["resources"]["coal"] = NAN
    invalid_states.append(nan_stock)
    var infinite_stock: Dictionary = baseline.duplicate(true)
    infinite_stock["resources"]["copper"] = INF
    invalid_states.append(infinite_stock)
    var missing_id: Dictionary = baseline.duplicate(true)
    missing_id["resources"].erase("iron")
    invalid_states.append(missing_id)
    var extra_id: Dictionary = baseline.duplicate(true)
    extra_id["resources"]["uranium"] = 1.0
    invalid_states.append(extra_id)
    var bad_level: Dictionary = baseline.duplicate(true)
    bad_level["mine_levels"]["iron"] = 0
    invalid_states.append(bad_level)
    var bad_drill_level: Dictionary = baseline.duplicate(true)
    bad_drill_level["drill_level"] = 6
    invalid_states.append(bad_drill_level)
    var bad_depth: Dictionary = baseline.duplicate(true)
    bad_depth["depth"] = -10
    invalid_states.append(bad_depth)
    var bad_facility: Dictionary = baseline.duplicate(true)
    bad_facility["jobs"]["smelter"] = bad_facility["jobs"]["furnace"]
    invalid_states.append(bad_facility)
    var bad_recipe: Dictionary = baseline.duplicate(true)
    bad_recipe["jobs"]["furnace"]["recipe"] = "cable"
    invalid_states.append(bad_recipe)
    var bad_remaining: Dictionary = baseline.duplicate(true)
    bad_remaining["jobs"]["furnace"]["remaining"] = -1.0
    invalid_states.append(bad_remaining)
    var nan_remaining: Dictionary = baseline.duplicate(true)
    nan_remaining["jobs"]["furnace"]["remaining"] = NAN
    invalid_states.append(nan_remaining)
    var infinite_remaining: Dictionary = baseline.duplicate(true)
    infinite_remaining["jobs"]["furnace"]["remaining"] = INF
    invalid_states.append(infinite_remaining)
    var negative_duration: Dictionary = baseline.duplicate(true)
    negative_duration["jobs"]["furnace"]["duration"] = -1.0
    invalid_states.append(negative_duration)
    var nan_duration: Dictionary = baseline.duplicate(true)
    nan_duration["jobs"]["furnace"]["duration"] = NAN
    invalid_states.append(nan_duration)
    var bad_duration: Dictionary = baseline.duplicate(true)
    bad_duration["jobs"]["furnace"]["duration"] = INF
    invalid_states.append(bad_duration)
    var bad_quantity: Dictionary = baseline.duplicate(true)
    bad_quantity["jobs"]["furnace"]["quantity"] = 11
    invalid_states.append(bad_quantity)
    var bad_target: Dictionary = baseline.duplicate(true)
    bad_target["jobs"] = {"drill": {"remaining": 10.0, "duration": 30.0, "target_depth": 40}}
    invalid_states.append(bad_target)
    var bad_drill_duration: Dictionary = baseline.duplicate(true)
    bad_drill_duration["drill_level"] = 2
    bad_drill_duration["jobs"] = {"drill": {"remaining": 10.0, "duration": 17.0, "target_depth": 10}}
    invalid_states.append(bad_drill_duration)

    for invalid in invalid_states:
        t.equal(game.restore(invalid), false, "état invalide refusé")
        t.equal(game.snapshot(), baseline, "restauration invalide sans mutation")
