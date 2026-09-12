extends SceneTree
const Catalog = preload("res://src/industry/industry_catalog.gd")
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
    if not ok:
        failures.append(message)
        push_error(message)
func _initialize() -> void:
    check(Catalog.RECIPES.size() == 100, "Approved economy must have exactly 100 recipes")
    var facilities: Dictionary = {}
    var seen: Dictionary = {}
    var products: Dictionary = {}
    for id in Catalog.RECIPES:
        var r: Dictionary = Catalog.RECIPES[id]
        facilities[r.facility] = true
        check(Catalog.FACILITIES.has(r.facility), "Known facility: " + id)
        if Catalog.FACILITIES.has(r.facility):
            check(int(Catalog.FACILITIES[r.facility].depth) <= int(r.depth), "Facility available by recipe depth: " + id)
        check(int(r.depth) == [0, 30, 60, 90, 150, 240, 360, 500, 700, 1000][int((int(r.number) - 1) / 10)], "Approved zone depth: " + id)
        products[r.output] = r
        check(float(r.seconds) > 0, "Positive duration: " + id)
        check(int(r.get("yield", 0)) > 0, "Positive yield: " + id)
        check(Catalog.RESOURCES.has(r.output), "Known output: " + id)
        check(int(r.get("number", 0)) >= 1 and int(r.get("number", 0)) <= 100 and not seen.has(r.get("number", 0)), "Unique recipe number: " + id)
        seen[r.get("number", 0)] = true
        for ingredient in r.inputs:
            check(Catalog.RESOURCES.has(ingredient) and int(r.inputs[ingredient]) > 0, "Known positive ingredient: " + id)
    check(facilities.size() == 6, "Six working production buildings")
    var available: Dictionary = {}
    for id in Catalog.RESOURCES:
        if Catalog.RESOURCES[id].raw:
            available[id] = true
    for pass_index in range(100):
        for id in Catalog.RECIPES:
            var r: Dictionary = Catalog.RECIPES[id]
            var reachable := true
            for ingredient in r.inputs:
                if not available.has(ingredient):
                    reachable = false
                if products.has(ingredient):
                    check(int(products[ingredient].get("depth", 0)) <= int(r.get("depth", 0)), "Ingredient unlocked by recipe depth: " + id)
                else:
                    check(int(Catalog.RESOURCES[ingredient].get("depth", 0)) <= int(r.get("depth", 0)), "Raw unlocked by recipe depth: " + id)
            if reachable:
                available[r.output] = true
    for id in Catalog.RECIPES:
        check(available.has(Catalog.RECIPES[id].output), "Acyclic accessible recipe: " + id)
    check(Catalog.MINES.size() == 3, "Historical visual mines unchanged")
    check(Catalog.FACILITIES.size() == 6, "Exactly six facilities")
    check(Catalog.MAX_DEPTH == 1500, "Depth limit 1500")
    var expected_yields := {"copper_wire": 4, "bolts": 4, "bearings": 2, "industrial_glass": 2, "steel_pipes": 2, "valves": 2, "precision_bearings": 2, "stainless_tubes": 2, "carbide_tooth": 2}
    for id in Catalog.RECIPES:
        check(int(Catalog.RECIPES[id]["yield"]) == int(expected_yields.get(id, 1)), "Approved yield: " + id)
    var merged: Dictionary = Catalog.mine_definitions()
    check(merged.size() == 12 and not merged.has("ancient_fragment"), "Guaranteed mineral extraction excludes recovered fragments")
    for id in Catalog.DEEP_MINES:
        check(Catalog.RESOURCES.has(id) and Catalog.RESOURCES[id].raw, "Raw extraction: " + id)
        check(int(Catalog.DEEP_MINES[id].depth) == int(Catalog.RESOURCES[id].depth), "Extraction unlock depth: " + id)
        check(float(Catalog.DEEP_MINES[id].base_rate) > 0, "Positive extraction rate: " + id)
    for depth in Catalog.GATES:
        for ingredient in Catalog.GATES[depth]:
            check(products.has(ingredient), "Gate equipment exists: " + ingredient)
            check(int(products[ingredient].depth) < int(depth), "Gate equipment available before transition: " + ingredient)
            check(int(Catalog.GATES[depth][ingredient]) == 1, "One installed equipment per gate: " + ingredient)
    check(Catalog.GATES[1500] == {"autonomous_excavator": 1}, "Final gate requires excavator")
    for level in range(1, 5):
        check(Catalog.DRILL_UPGRADES[level].cost == {"drill_head_%d" % level: 1}, "Head upgrade cost: %d" % level)
    for level in Catalog.CENTER_LEVELS:
        for ingredient in Catalog.CENTER_LEVELS[level].cost:
            check(products.has(ingredient), "Center component exists: " + ingredient)
            check(int(products[ingredient].depth) <= int(Catalog.CENTER_LEVELS[level].depth), "Center component accessible: " + ingredient)
    check(Catalog.MILESTONES.keys() == [30, 60, 90, 120, 150], "Historical discovery milestones unchanged")
    print("CATALOG: %d recipes, %d failures" % [Catalog.RECIPES.size(), failures.size()])
    quit(0 if failures.is_empty() else 1)
