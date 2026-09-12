extends SceneTree
const Game = preload("res://src/industry/industry_game.gd")
const Legacy = preload("res://src/industry/industry_legacy_game.gd")
const Catalog = preload("res://src/industry/industry_catalog.gd")
const Save = preload("res://src/industry/industry_save.gd")
var failures: Array[String] = []
func check(value: bool, message: String) -> void:
    if not value:
        failures.append(message)
        push_error(message)
func _init():
    call_deferred("run")
func run():
    var game = Game.new()
    check(game.has_method("excavation_cost"), "Equipment gate cost API required")
    var wire: Dictionary = Catalog.RECIPES["copper_wire"]
    for id in wire["inputs"]:
        game.resources[id] = float(wire["inputs"][id]) * 3.0
    check(game.start_batch("copper_wire", 3), "Three wire batches start")
    check(int(game.jobs[wire["facility"]]["output_quantity"]) == 12, "Committed multiyield is twelve")
    game.advance(float(wire["seconds"]) * 3)
    check(game.resources["copper_wire"] == 12, "Three wire batches deliver twelve")
    var before: Dictionary = game.snapshot()
    check(not game.start_batch("drill_head_1", 1), "Deep recipe blocked")
    check(game.snapshot() == before, "Locked production never pays")
    check(game.mine_rate("silica") == 0, "Depth-locked mine produces zero")
    game.depth = 150
    for facility in Catalog.FACILITIES:
        for recipe_id in Catalog.RECIPES:
            var recipe: Dictionary = Catalog.RECIPES[recipe_id]
            if recipe["facility"] != facility or int(recipe["depth"]) > game.depth:
                continue
            for id in recipe["inputs"]:
                game.resources[id] = 100000.0
            check(game.start_batch(recipe_id, 1), "Parallel facility " + facility)
            break
    check(game.jobs.size() == 6, "Six independent production slots")
    var clone = Game.new()
    check(clone.restore(game.snapshot()), "Parallel job snapshot roundtrip")
    game.advance(10000)
    for index in range(100):
        clone.advance(100)
    for id in game.resources:
        check(is_equal_approx(float(game.resources[id]), float(clone.resources[id])), "Segmented parallel output " + id)
    game = Game.new()
    game.depth = 50
    var gate: Dictionary = game.excavation_cost()
    for id in gate:
        game.resources[id] = gate[id]
    game.resources["winch"] = 0
    before = game.snapshot()
    check(not game.start_excavation(), "Incomplete equipment gate blocked")
    check(game.snapshot() == before, "Equipment payment atomic")
    game.resources["winch"] = 1
    game.resources["drill_head_1"] = 1
    check(game.upgrade_drill(), "Head upgrades speed")
    check(not game.excavation_cost().has("drill_head_1"), "Installed head omitted from gate")
    check(game.start_excavation(), "Equipment gate starts")
    check(game.resources["drill_head_1"] == 0 and game.resources["winch"] == 0, "Head and gate paid once")
    clone = Game.new()
    check(clone.restore(game.snapshot()), "Paid gate roundtrip")
    var malformed: Dictionary = game.snapshot()
    malformed["jobs"]["drill"]["equipment"].erase("winch")
    before = clone.snapshot()
    check(not clone.restore(malformed) and clone.snapshot() == before, "Unpaid gate rejected without mutation")
    game.advance(game.jobs["drill"]["remaining"])
    check(game.depth == 60 and game.installed_equipment.has("winch"), "Gate installs permanently")
    check(game.start_excavation(), "Intermediate depth does not require old level rule")
    game = Game.new()
    game.depth = 1000
    game.apply_retroactive_milestones()
    check(game.discoveries.has("1000:0") and game.discoveries["1000:0"]["type"] == "ancient_structure", "Guaranteed real ancient discovery")
    before = game.snapshot()
    check(not game.start_fragment_recovery("1000:0") and game.snapshot() == before, "Unopened structure cannot recover")
    for id in Catalog.POCKET_TYPES["ancient_structure"]["cost"]:
        game.resources[id] = Catalog.POCKET_TYPES["ancient_structure"]["cost"][id]
    check(game.start_exploration("1000:0"), "Ancient structure exploration")
    game.advance(game.explorations["1000:0"]["remaining"])
    check(game.start_fragment_recovery("1000:0"), "Opened active ancient structure recovery")
    check(not game.start_fragment_recovery("1000:0"), "Shared recovery slot occupied")
    clone = Game.new()
    check(clone.restore(game.snapshot()), "Recovery roundtrip")
    var bad_recovery: Dictionary = game.snapshot()
    bad_recovery["permanent_sites"] = []
    check(not clone.restore(bad_recovery), "Malformed recovery site map rejected safely")
    bad_recovery = game.snapshot()
    bad_recovery["jobs"]["recovery"]["output_quantity"] = 2
    check(not clone.restore(bad_recovery), "Recovery committed yield cannot be forged")
    clone.advance(299)
    check(clone.resources["ancient_fragment"] == 0, "No early fragment")
    clone.advance(1)
    game.advance(300)
    check(game.resources["ancient_fragment"] == 1 and clone.resources["ancient_fragment"] == 1, "Exactly one fragment per recovery")
    game.advance(1000)
    check(game.resources["ancient_fragment"] == 1, "No repeated fragment from completed operation")
    check(game.start_fragment_recovery("1000:0"), "Recovery relaunch")
    DirAccess.make_dir_recursive_absolute("user://tests")
    var save_path := "user://tests/economy-simulation.json"
    check(Save.new().save_game(save_path, game, 1000), "Save active recovery")
    var loaded: Dictionary = Save.new().load_game(save_path, 1300)
    check(loaded["error"] == "" and loaded["game"].resources["ancient_fragment"] == 2, "Offline recovery finishes once")
    var legacy = Legacy.new()
    legacy.resources["iron_ingot"] = 5
    legacy.depth = 50
    legacy.drill_level = 3
    check(legacy.start_batch("iron_ingot", 2), "Legacy batch fixture")
    check(legacy.start_excavation(), "Legacy drill fixture")
    var historical: Dictionary = legacy.snapshot()
    game = Game.new()
    check(game.restore_v2(historical), "Valid v2 migration")
    check(game.resources.size() == Catalog.RESOURCES.size(), "Migration expands full resource schema")
    check(game.jobs["furnace"]["duration"] == 40 and game.jobs["furnace"]["output_quantity"] == 2, "Historical paid duration and yield preserved")
    game.advance(1000)
    check(game.resources["iron_ingot"] == 7 and game.depth == 60, "Historical batch and drill complete")
    var invalid: Dictionary = historical.duplicate(true)
    invalid["resources"]["silica"] = 0
    before = game.snapshot()
    check(not game.restore_v2(invalid) and game.snapshot() == before, "Unknown v2 resources rejected before migration")
    invalid = historical.duplicate(true)
    invalid["jobs"]["furnace"]["duration"] = Catalog.RECIPES["iron_ingot"]["seconds"] * 2
    if invalid["jobs"]["furnace"]["duration"] != historical["jobs"]["furnace"]["duration"]:
        check(not game.restore_v2(invalid), "New recipe duration invalid in legacy schema")
    invalid = historical.duplicate(true)
    invalid["mine_levels"]["iron"] = 1.5
    check(not game.restore_v2(invalid), "Fractional legacy mine rejected")
    var v1 := {}
    for key in ["resources", "mine_levels", "drill_level", "depth", "jobs"]:
        v1[key] = historical[key].duplicate(true) if typeof(historical[key]) == TYPE_DICTIONARY else historical[key]
    v1["resources"].erase("crystal")
    check(game.restore_v1(v1, 123), "Valid v1 migration")
    for version in [1, 2]:
        var file := FileAccess.open(save_path, FileAccess.WRITE)
        file.store_string(JSON.stringify({"version": version, "saved_at_unix": 1000, "industry": v1 if version == 1 else historical}))
        file.close()
        loaded = Save.new().load_game(save_path, 1040)
        check(loaded["error"] == "" and loaded["game"].resources["iron_ingot"] == 7 and loaded["game"].depth == 60, "Offline migration v%d preserves paid batch/drill" % version)
        var bad: Dictionary = (v1 if version == 1 else historical).duplicate(true)
        bad["resources"]["silica"] = 0
        file = FileAccess.open(save_path, FileAccess.WRITE)
        file.store_string(JSON.stringify({"version": version, "saved_at_unix": 1000, "industry": bad}))
        file.close()
        loaded = Save.new().load_game(save_path, 1040)
        check(loaded["error"] != "", "Invalid file schema v%d never silently migrates" % version)
    legacy = Legacy.new()
    legacy.depth = 1000
    legacy._ensure_discovery(1000, 0)
    var original: Dictionary = legacy.discoveries["1000:0"].duplicate(true)
    check(game.restore_v2(legacy.snapshot()), "Deep legacy snapshot migration")
    game.apply_retroactive_milestones()
    check(game.discoveries["1000:0"] == original, "Existing historical discovery preserved exactly")
    check(game.discoveries.has("1000:1") and game.discoveries["1000:1"]["type"] == "ancient_structure", "Legacy depth receives additional guaranteed ancient site")

    invalid = v1.duplicate(true)
    invalid["resources"]["crystal"] = 0
    before = game.snapshot()
    check(not game.restore_v1(invalid, 123) and game.snapshot() == before, "Invalid v1 rejected without mutation")
    invalid = v1.duplicate(true)
    invalid["jobs"]["drill"]["target_depth"] = 70
    check(not game.restore_v1(invalid, 123), "Invalid v1 committed target rejected")
    legacy = Legacy.new()
    legacy.depth = 1510
    legacy.drill_level = 5
    check(legacy.start_excavation(), "Historical engine allowed beyond new endpoint")
    check(game.restore_v2(legacy.snapshot()), "Valid historical depth beyond endpoint preserved")
    check(Save.new().save_game(save_path, game, 1000), "Save historical deep job as v3")
    loaded = Save.new().load_game(save_path, 2000)
    check(loaded["error"] == "" and loaded["game"].depth == 1520 and not loaded["game"].start_excavation(), "Historical deep job roundtrip offline; new endpoint enforced")
    invalid = game.snapshot()
    invalid["jobs"]["drill"]["legacy"] = false
    check(not clone.restore(invalid), "New drill job beyond endpoint rejected")
    DirAccess.remove_absolute(save_path)
    if failures.is_empty():
        print("PASS economy simulation: multiyield, six slots, gates, recovery, offline and strict legacy migration")
    quit(0 if failures.is_empty() else 1)
