extends RefCounted

const IndustryGameScript = preload("res://src/industry/industry_game.gd")
const IndustrySaveScript = preload("res://src/industry/industry_save.gd")
const PATH := "user://industry_schema_v2_test.json"

func run(t: TestSupport) -> void:
    test_v03_state_round_trip(t)
    test_schema_v1_migrates_to_v2(t)
    _cleanup()

func test_v03_state_round_trip(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    t.equal(game.resources.get("crystal", -1.0), 0.0, "cristal initialisé à zéro")
    t.equal(game.get("center_level"), 1, "Centre niveau 1 par défaut")
    t.equal(game.get("tech_points"), 0, "aucun point techno au départ")
    t.check(game.get("discoveries") is Dictionary and game.get("discoveries").is_empty(), "aucune découverte au départ")
    t.check(game.get("explorations") is Dictionary and game.get("explorations").is_empty(), "aucune exploration au départ")
    t.check(int(game.get("world_seed")) != 0, "seed de partie initialisée")

    var snapshot := game.snapshot()
    var restored = IndustryGameScript.new()
    t.check(restored.restore(snapshot), "snapshot v0.3 restaurable")
    t.equal(restored.snapshot(), snapshot, "snapshot v0.3 restauré sans perte")
    t.equal(restored.get("world_seed"), game.get("world_seed"), "seed persistée")

func test_schema_v1_migrates_to_v2(t: TestSupport) -> void:
    _cleanup()
    var v1_industry := {
        "resources": {
            "iron": 42.0,
            "coal": 8.0,
            "copper": 8.0,
            "iron_ingot": 2.0,
            "copper_ingot": 1.0,
            "cable": 1.0,
        },
        "mine_levels": {"iron": 2, "coal": 1, "copper": 1},
        "drill_level": 4,
        "depth": 90,
        "jobs": {},
    }
    _write_text(PATH, JSON.stringify({"version": 1, "saved_at_unix": 1000.0, "industry": v1_industry}))

    var save = IndustrySaveScript.new()
    var loaded: Dictionary = save.load_game(PATH, 1000.0)
    t.equal(loaded["error"], "", "schema v1 migré")
    t.equal(loaded["game"].resources["iron"], 42.0, "stock v1 conservé")
    t.equal(loaded["game"].resources.get("crystal", -1.0), 0.0, "cristal ajouté sans gain")
    t.equal(loaded["game"].get("center_level"), 1, "Centre initialisé à la migration")
    t.check(int(loaded["game"].get("world_seed")) != 0, "seed créée à la migration")
    t.equal(loaded["game"].get("tech_points"), 1, "point technologique de 90 m crédité une fois")
    t.check(90 in loaded["game"].get("claimed_milestones"), "palier 90 m marqué comme réclamé")

    t.check(save.save_game(PATH, loaded["game"], 1000.0), "état migré sauvegardé en v2")
    var reopened: Dictionary = save.load_game(PATH, 1000.0)
    t.equal(reopened["error"], "", "schema v2 rouvert")
    t.equal(reopened["game"].get("tech_points"), 1, "point rétroactif non dupliqué")

func _write_text(path: String, contents: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(contents)
    file.close()

func _cleanup() -> void:
    for path in [PATH, PATH + ".tmp"]:
        if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
