extends RefCounted

const IndustryGameScript = preload("res://src/industry/industry_game.gd")
const IndustrySaveScript = preload("res://src/industry/industry_save.gd")
const PATH := "user://industry_test_save.json"
const TEMP_PATH := PATH + ".tmp"

func run(t: TestSupport) -> void:
    test_offline_progress_is_applied_once(t)
    test_drill_upgrade_during_excavation_survives_reload(t)
    test_affordability_never_spends_below_zero(t)
    test_clock_rollback_keeps_saved_instant(t)
    test_invalid_files_are_preserved(t)
    test_failed_staging_write_preserves_save(t)
    test_invalid_timestamps_are_rejected_before_open(t)
    _cleanup()

func test_offline_progress_is_applied_once(t: TestSupport) -> void:
    _cleanup()
    var game = IndustryGameScript.new()
    t.check(game.start_batch("iron_ingot", 1), "travail enregistré")
    var save = IndustrySaveScript.new()
    t.check(save.save_game(PATH, game, 1000.0), "sauvegarde industrielle écrite")

    var result: Dictionary = save.load_game(PATH, 1060.0)
    t.equal(result["error"], "", "sauvegarde industrielle valide")
    t.equal(result["offline_seconds"], 60.0, "absence calculée")
    t.equal(result["saved_at_unix"], 1060.0, "instant réconcilié")
    t.equal(result["game"].resources["iron_ingot"], 1.0, "lot terminé pendant absence")
    t.equal(result["offline_report"]["completed"], ["furnace"], "four terminé pendant absence")
    t.check(save.save_game(PATH, result["game"], result["saved_at_unix"]), "retour validé")

    var reopened: Dictionary = save.load_game(PATH, 1060.0)
    t.equal(reopened["offline_seconds"], 0.0, "aucune seconde rejouée")
    t.equal(reopened["game"].snapshot(), result["game"].snapshot(), "aucun double gain")
    _cleanup()

func test_drill_upgrade_during_excavation_survives_reload(t: TestSupport) -> void:
    _cleanup()
    var game = IndustryGameScript.new()
    t.check(game.start_excavation(), "forage enregistré avant amélioration")
    game.advance(5.0)
    var committed_job: Dictionary = game.jobs["drill"].duplicate(true)
    game.resources["iron_ingot"] = 2.0
    game.resources["cable"] = 1.0
    t.check(game.upgrade_drill(), "foreuse améliorée pendant le forage")
    t.equal(game.jobs["drill"], committed_job, "amélioration conserve le minuteur engagé")

    var save = IndustrySaveScript.new()
    t.check(save.save_game(PATH, game, 1000.0), "forage amélioré sauvegardé")
    var loaded: Dictionary = save.load_game(PATH, 1025.0)
    t.equal(loaded["error"], "", "forage amélioré restauré")
    t.equal(loaded["offline_report"]["completed"], ["drill"], "forage restauré terminé une fois")
    t.equal(loaded["game"].depth, 10, "forage restauré gagne sa profondeur")
    t.equal(loaded["game"].jobs.has("drill"), false, "forage terminé retiré")

    t.check(save.save_game(PATH, loaded["game"], 1025.0), "état terminé sauvegardé")
    var reopened: Dictionary = save.load_game(PATH, 1025.0)
    t.equal(reopened["error"], "", "état terminé rouvert")
    t.equal(reopened["offline_report"]["completed"], [], "forage non crédité deux fois")
    t.equal(reopened["game"].depth, 10, "profondeur créditée une seule fois")
    _cleanup()

func test_affordability_never_spends_below_zero(t: TestSupport) -> void:
    _cleanup()
    var game = IndustryGameScript.new()
    game.resources["iron"] = 3.9999999
    game.resources["coal"] = 1.0
    var insufficient: Dictionary = game.snapshot()
    t.equal(game.start_batch("iron_ingot", 1), false, "stock juste insuffisant refusé")
    t.equal(game.snapshot(), insufficient, "refus limite sans ressource négative")

    var exact = IndustryGameScript.new()
    exact.resources["iron"] = 4.0
    exact.resources["coal"] = 1.0
    t.check(exact.start_batch("iron_ingot", 1), "stock exact accepté")
    t.equal(exact.resources["iron"], 0.0, "stock exact dépensé sans création")
    t.equal(exact.resources["coal"], 0.0, "second intrant exact dépensé")
    var save = IndustrySaveScript.new()
    t.check(save.save_game(PATH, exact, 1000.0), "résultat limite sauvegardé")
    var loaded: Dictionary = save.load_game(PATH, 1000.0)
    t.equal(loaded["error"], "", "résultat limite restauré")
    t.equal(loaded["game"].snapshot(), exact.snapshot(), "résultat limite persistant intact")
    _cleanup()

func test_clock_rollback_keeps_saved_instant(t: TestSupport) -> void:
    _cleanup()
    var save = IndustrySaveScript.new()
    var game = IndustryGameScript.new()
    t.check(save.save_game(PATH, game, 1000.0), "horloge de référence sauvegardée")
    var loaded: Dictionary = save.load_game(PATH, 900.0)
    t.equal(loaded["error"], "", "recul horloge accepté sans erreur")
    t.equal(loaded["offline_seconds"], 0.0, "recul sans production")
    t.equal(loaded["saved_at_unix"], 1000.0, "instant sauvegardé conservé")
    t.equal(loaded["game"].snapshot(), game.snapshot(), "état inchangé lors du recul")
    _cleanup()

func test_invalid_files_are_preserved(t: TestSupport) -> void:
    var invalid_payloads: Array[String] = [
        "octets illisibles",
        JSON.stringify({"version": 3, "saved_at_unix": 1000.0, "industry": IndustryGameScript.new().snapshot()}),
        JSON.stringify({"version": "2", "saved_at_unix": 1000.0, "industry": IndustryGameScript.new().snapshot()}),
        JSON.stringify({"version": 2.5, "saved_at_unix": 1000.0, "industry": IndustryGameScript.new().snapshot()}),
        JSON.stringify({"version": 2, "saved_at_unix": -1.0, "industry": IndustryGameScript.new().snapshot()}),
        JSON.stringify({"version": 2, "saved_at_unix": 1000.0, "industry": {}}),
        JSON.stringify({"version": 2, "saved_at_unix": 1000.0, "industry": IndustryGameScript.new().snapshot(), "extra": true}),
    ]
    var save = IndustrySaveScript.new()
    for bytes in invalid_payloads:
        _cleanup()
        _write_text(PATH, bytes)
        var before := FileAccess.get_file_as_bytes(PATH)
        var loaded: Dictionary = save.load_game(PATH, 1060.0)
        t.check(loaded["error"] != "", "sauvegarde invalide expliquée")
        t.equal(loaded["offline_seconds"], 0.0, "sauvegarde invalide sans absence")
        t.equal(loaded["game"].snapshot(), IndustryGameScript.new().snapshot(), "partie provisoire neuve")
        t.equal(FileAccess.get_file_as_bytes(PATH), before, "sauvegarde invalide préservée octet pour octet")
    _cleanup()

func test_failed_staging_write_preserves_save(t: TestSupport) -> void:
    _cleanup()
    var save = IndustrySaveScript.new()
    var game = IndustryGameScript.new()
    t.check(save.save_game(PATH, game, 1000.0), "ancienne sauvegarde créée")
    var previous_bytes := FileAccess.get_file_as_bytes(PATH)
    t.equal(DirAccess.make_dir_absolute(TEMP_PATH), OK, "temporaire rendu inaccessible")
    game.advance(10.0)
    t.equal(save.save_game(PATH, game, 1010.0), false, "échec temporaire signalé")
    t.equal(FileAccess.get_file_as_bytes(PATH), previous_bytes, "ancienne sauvegarde conservée")
    _cleanup()

func test_invalid_timestamps_are_rejected_before_open(t: TestSupport) -> void:
    _cleanup()
    t.equal(DirAccess.make_dir_absolute(TEMP_PATH), OK, "chemin temporaire sentinelle créé")
    var save = IndustrySaveScript.new()
    var game = IndustryGameScript.new()
    for timestamp in [-1.0, NAN, INF]:
        t.equal(save.save_game(PATH, game, timestamp), false, "timestamp non valide refusé")
        t.check(DirAccess.dir_exists_absolute(TEMP_PATH), "timestamp refusé avant ouverture")
        t.equal(FileAccess.file_exists(PATH), false, "timestamp invalide ne crée rien")
    _cleanup()

func _write_text(path: String, contents: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(contents)
    file.close()

func _cleanup() -> void:
    for path in [PATH, TEMP_PATH]:
        if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
