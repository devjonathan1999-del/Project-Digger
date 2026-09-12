extends SceneTree

const Game = preload("res://src/industry/industry_game.gd")
const Catalog = preload("res://src/industry/industry_catalog.gd")
const Save = preload("res://src/industry/industry_save.gd")
const SAVE_PATH := "user://tests/economy-route-v09.json"

var game
var elapsed := 0.0
var crafts := 0
var failures: Array[String] = []
var timings: Dictionary = {}
var stack: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> bool:
    failures.append(message)
    push_error(message)
    return false

func _tick(seconds: float) -> void:
    elapsed += seconds
    game.advance(seconds)

func _run() -> void:
    game = Game.new()
    if Catalog.RECIPES.size() != 100 or not game.has_method("excavation_cost"):
        _fail("The real crafting route requires the approved 100-recipe engine")
        quit(1)
        return
    # No stocks, finished components, depth or installed equipment are gifted.
    while game.depth < 1500 and failures.is_empty():
        var costs: Dictionary = game.excavation_cost()
        _inputs_ready(costs)
        if not failures.is_empty():
            break
        if not game.start_excavation():
            _fail("Cannot excavate from %dm: %s" % [game.depth, game.excavation_block_reason()])
            break
        _tick(float(game.jobs["drill"]["remaining"]))
        if game.depth in [30, 90, 500, 1000, 1500]:
            timings[str(game.depth)] = elapsed
    # Recipe100 is the actual final fabrication goal, not a stock injection.
    if failures.is_empty():
        for definition in Catalog.RECIPES.values():
            if int(definition.get("number", 0)) == 100:
                _ensure(str(definition["output"]), 1.0)
                timings["abyssal_goal"] = elapsed
                break
    if failures.is_empty():
        DirAccess.make_dir_recursive_absolute("user://tests")
        if not Save.new().save_game(SAVE_PATH, game, 1000.0):
            _fail("Completed route cannot be saved")
        else:
            var loaded: Dictionary = Save.new().load_game(SAVE_PATH, 1000.0)
            if str(loaded.get("error", "")) != "" or loaded["game"].depth != 1500:
                _fail("Completed deep progression does not survive save/load")
            if loaded["game"].installed_equipment != game.installed_equipment:
                _fail("Installed route equipment changed after reload")
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
    print("ECONOMY_ROUTE_SERIAL_SECONDS=", JSON.stringify(timings))
    print("ECONOMY_ROUTE_CRAFT_JOBS=", crafts)
    print("ECONOMY_ROUTE_FAILURES=", failures.size())
    quit(0 if failures.is_empty() else 1)

func _ensure(resource_id: String, needed: float) -> bool:
    if float(game.resources.get(resource_id, 0.0)) >= needed:
        return true
    if resource_id in stack:
        return _fail("Circular crafting dependency: %s -> %s" % [stack, resource_id])
    var resource: Dictionary = Catalog.RESOURCES.get(resource_id, {})
    if resource.is_empty():
        return _fail("Unknown route ingredient: " + resource_id)
    if bool(resource.get("raw", false)):
        if resource_id == "crystal":
            if _activate_site("crystal_cavern") == "":
                return false
            var rate := 0.0
            for site in game.permanent_sites.values():
                if site["type"] == "crystal_cavern" and bool(site["active"]):
                    rate += float(site["rate"])
            if rate <= 0.0:
                return _fail("No working crystal extraction at %dm" % game.depth)
            _tick((needed - float(game.resources[resource_id])) / rate + 0.01)
            return float(game.resources[resource_id]) >= needed
        if str(resource["label"]).contains("Fragment"):
            var site_id := _activate_site("ancient_structure")
            if site_id == "":
                return false
            while float(game.resources[resource_id]) < needed:
                if not game.start_fragment_recovery(site_id):
                    return _fail("Recovery cannot start: " + game.fragment_recovery_block_reason(site_id))
                _tick(float(game.jobs["recovery"]["remaining"]))
            return true
        var rate := float(game.mine_rate(resource_id))
        if rate <= 0.0:
            return _fail("Raw ingredient locked at %dm: %s" % [game.depth, resource_id])
        _tick((needed - float(game.resources[resource_id])) / rate + 0.01)
        return float(game.resources[resource_id]) >= needed
    var recipe_id := ""
    var definition: Dictionary = {}
    for id in Catalog.RECIPES:
        if str(Catalog.RECIPES[id]["output"]) == resource_id:
            recipe_id = str(id)
            definition = Catalog.RECIPES[id]
            break
    if recipe_id == "":
        return _fail("No recipe for route ingredient: " + resource_id)
    if int(definition["depth"]) > game.depth:
        return _fail("Route requires %s before its %dm unlock" % [resource_id, definition["depth"]])
    stack.append(resource_id)
    while float(game.resources[resource_id]) < needed:
        var batches := mini(10, ceili((needed - float(game.resources[resource_id])) / float(definition["yield"])))
        var inputs := {}
        for input_id in definition["inputs"]:
            inputs[input_id] = float(definition["inputs"][input_id]) * batches
        if not _inputs_ready(inputs):
            stack.pop_back()
            return false
        if not game.start_batch(recipe_id, batches):
            stack.pop_back()
            return _fail("Route batch refused: %s (%s)" % [recipe_id, game.batch_block_reason(recipe_id, batches)])
        crafts += 1
        _tick(float(game.jobs[definition["facility"]]["remaining"]))
        if crafts > 100000:
            stack.pop_back()
            return _fail("Route exceeded its bounded crafting budget")
    stack.pop_back()
    return true

func _inputs_ready(costs: Dictionary) -> bool:
    # A later ingredient may consume an earlier ingredient (e.g. a reinforced
    # cable consumes a steel plate also required separately by a drilling head).
    # Reconcile the complete input set before paying the recipe atomically.
    for attempt in range(100):
        if game.can_afford(costs):
            return true
        for id in costs:
            if not _ensure(str(id), float(costs[id])):
                return false
    return _fail("Craft planner cannot reconcile inputs: " + str(costs))

func _activate_site(type_id: String) -> String:
    var site_id := ""
    for id in game.permanent_sites:
        if str(game.permanent_sites[id]["type"]) == type_id:
            site_id = str(id)
            break
    if site_id == "":
        for id in game.discoveries:
            var discovery: Dictionary = game.discoveries[id]
            if discovery["type"] != type_id or discovery["state"] != "detected":
                continue
            var exploration_cost: Dictionary = Catalog.POCKET_TYPES[type_id]["cost"]
            if not _inputs_ready(exploration_cost):
                return ""
            if not game.start_exploration(str(id)):
                _fail("Cannot open required site: " + str(id))
                return ""
            _tick(float(game.explorations[id]["remaining"]))
            site_id = str(id)
            break
    if site_id == "":
        _fail("No guaranteed accessible " + type_id)
        return ""
    if not bool(game.permanent_sites[site_id]["active"]):
        for id in game.permanent_sites:
            if id != site_id and bool(game.permanent_sites[id]["active"]):
                game.set_site_active(str(id), false)
        if not game.set_site_active(site_id, true):
            _fail("Cannot activate required site: " + site_id)
            return ""
    return site_id
