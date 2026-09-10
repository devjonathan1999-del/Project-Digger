class_name IndustryGame
extends RefCounted

const Catalog = preload("res://src/industry/industry_catalog.gd")
const FACILITIES: Array[String] = ["furnace", "workshop", "drill"]
const EPSILON := 0.000001

var resources: Dictionary = {
    "iron": 12.0,
    "coal": 8.0,
    "copper": 8.0,
    "iron_ingot": 0.0,
    "copper_ingot": 0.0,
    "cable": 0.0,
}
var mine_levels: Dictionary = {"iron": 1, "coal": 1, "copper": 1}
var drill_level: int = 1
var depth: int = 0
var jobs: Dictionary = {}

func advance(seconds: float) -> Dictionary:
    var report := {"produced": {}, "completed": [], "depth_gained": 0}
    if not is_finite(seconds) or seconds <= 0.0:
        return report

    var elapsed_remaining := seconds
    while elapsed_remaining > 0.0:
        if jobs.is_empty():
            _produce_minerals(elapsed_remaining, report["produced"])
            break

        var segment := elapsed_remaining
        for job in jobs.values():
            segment = minf(segment, float(job["remaining"]))

        _produce_minerals(segment, report["produced"])
        for job in jobs.values():
            job["remaining"] = maxf(0.0, float(job["remaining"]) - segment)
        elapsed_remaining -= segment

        for facility in FACILITIES:
            if not jobs.has(facility) or float(jobs[facility]["remaining"]) > 0.0:
                continue
            var completed_job: Dictionary = jobs[facility]
            jobs.erase(facility)
            report["completed"].append(facility)
            if facility == "drill":
                var previous_depth := depth
                depth = int(completed_job["target_depth"])
                report["depth_gained"] += depth - previous_depth
            else:
                var recipe: Dictionary = Catalog.RECIPES[completed_job["recipe"]]
                var output: String = recipe["output"]
                var amount: int = int(completed_job["quantity"])
                resources[output] = float(resources[output]) + amount
                _add_produced(report["produced"], output, amount)

    return report

func snapshot() -> Dictionary:
    return {
        "resources": resources.duplicate(true),
        "mine_levels": mine_levels.duplicate(true),
        "drill_level": drill_level,
        "depth": depth,
        "jobs": jobs.duplicate(true),
    }

func restore(data: Dictionary) -> bool:
    if not _valid_snapshot(data):
        return false

    var restored_resources: Dictionary = data["resources"].duplicate(true)
    for id in restored_resources:
        restored_resources[id] = float(restored_resources[id])
    var restored_levels: Dictionary = data["mine_levels"].duplicate(true)
    for id in restored_levels:
        restored_levels[id] = int(restored_levels[id])
    var restored_jobs: Dictionary = data["jobs"].duplicate(true)
    for facility in restored_jobs:
        restored_jobs[facility]["remaining"] = float(restored_jobs[facility]["remaining"])
        restored_jobs[facility]["duration"] = float(restored_jobs[facility]["duration"])
        if facility == "drill":
            restored_jobs[facility]["target_depth"] = int(restored_jobs[facility]["target_depth"])
        else:
            restored_jobs[facility]["quantity"] = int(restored_jobs[facility]["quantity"])

    resources = restored_resources
    mine_levels = restored_levels
    drill_level = int(data["drill_level"])
    depth = int(data["depth"])
    jobs = restored_jobs
    return true

func can_afford(cost: Dictionary) -> bool:
    for id in cost:
        if not resources.has(id) or not _finite_number(resources[id]) or not _finite_number(cost[id]) or float(cost[id]) < 0.0:
            return false
        if float(resources[id]) < float(cost[id]):
            return false
    return true

func mine_rate(id: String) -> float:
    if not Catalog.MINES.has(id) or not mine_levels.has(id):
        return 0.0
    var depth_bonus := 1.0 + 0.15 * floori(float(depth) / 30.0)
    return float(Catalog.MINES[id]["base_rate"]) * int(mine_levels[id]) * depth_bonus

func mine_upgrade_cost(id: String) -> Dictionary:
    if not Catalog.MINES.has(id) or not mine_levels.has(id):
        return {}
    var level := int(mine_levels[id])
    return {"iron": 8 * level * level, "coal": 4 * level * level}

func drill_upgrade_cost() -> Dictionary:
    return {"iron_ingot": 2 * drill_level, "cable": drill_level}

func batch_block_reason(recipe: String, quantity: int) -> String:
    if not Catalog.RECIPES.has(recipe):
        return "Recette inconnue"
    if quantity < 1 or quantity > 10:
        return "La quantité doit être comprise entre 1 et 10"
    var definition: Dictionary = Catalog.RECIPES[recipe]
    var facility: String = definition["facility"]
    if jobs.has(facility):
        return "Installation occupée"
    var cost := _scaled_cost(definition["inputs"], quantity)
    if not can_afford(cost):
        return "Ressources insuffisantes"
    return ""

func excavation_block_reason() -> String:
    if jobs.has("drill"):
        return "Foreuse occupée"
    var required_level := mini(Catalog.MAX_DRILL_LEVEL, 1 + floori(float(depth + 10) / 30.0))
    if drill_level < required_level:
        return "Niveau de foreuse insuffisant"
    return ""

func excavation_duration() -> float:
    return (30.0 + depth * 0.5) / drill_level

func start_batch(recipe: String, quantity: int) -> bool:
    if batch_block_reason(recipe, quantity) != "":
        return false
    var definition: Dictionary = Catalog.RECIPES[recipe]
    var cost := _scaled_cost(definition["inputs"], quantity)
    _spend(cost)
    var duration := float(definition["seconds"]) * quantity
    jobs[definition["facility"]] = {
        "recipe": recipe,
        "quantity": quantity,
        "remaining": duration,
        "duration": duration,
    }
    return true

func upgrade_mine(id: String) -> bool:
    if not Catalog.MINES.has(id) or not mine_levels.has(id):
        return false
    if int(mine_levels[id]) >= Catalog.MAX_MINE_LEVEL:
        return false
    var cost := mine_upgrade_cost(id)
    if not can_afford(cost):
        return false
    _spend(cost)
    mine_levels[id] = int(mine_levels[id]) + 1
    return true

func upgrade_drill() -> bool:
    if drill_level >= Catalog.MAX_DRILL_LEVEL:
        return false
    var cost := drill_upgrade_cost()
    if not can_afford(cost):
        return false
    _spend(cost)
    drill_level += 1
    return true

func start_excavation() -> bool:
    if excavation_block_reason() != "":
        return false
    var duration := excavation_duration()
    jobs["drill"] = {
        "target_depth": depth + 10,
        "remaining": duration,
        "duration": duration,
    }
    return true

func _produce_minerals(seconds: float, produced: Dictionary) -> void:
    for id in Catalog.MINES:
        var amount := mine_rate(id) * seconds
        resources[id] = float(resources[id]) + amount
        _add_produced(produced, id, amount)

func _add_produced(produced: Dictionary, id: String, amount: float) -> void:
    produced[id] = float(produced.get(id, 0.0)) + amount

func _scaled_cost(inputs: Dictionary, quantity: int) -> Dictionary:
    var cost := {}
    for id in inputs:
        cost[id] = int(inputs[id]) * quantity
    return cost

func _spend(cost: Dictionary) -> void:
    for id in cost:
        resources[id] = float(resources[id]) - float(cost[id])

func _valid_snapshot(data: Dictionary) -> bool:
    if not _has_exact_keys(data, ["resources", "mine_levels", "drill_level", "depth", "jobs"]):
        return false
    if typeof(data["resources"]) != TYPE_DICTIONARY or not _has_exact_keys(data["resources"], Catalog.RESOURCES.keys()):
        return false
    for value in data["resources"].values():
        if not _finite_number(value) or float(value) < 0.0:
            return false

    if typeof(data["mine_levels"]) != TYPE_DICTIONARY or not _has_exact_keys(data["mine_levels"], Catalog.MINES.keys()):
        return false
    for value in data["mine_levels"].values():
        if not _valid_integer(value, 1, Catalog.MAX_MINE_LEVEL):
            return false
    if not _valid_integer(data["drill_level"], 1, Catalog.MAX_DRILL_LEVEL):
        return false
    if not _valid_integer(data["depth"], 0) or int(data["depth"]) % 10 != 0:
        return false
    if typeof(data["jobs"]) != TYPE_DICTIONARY:
        return false

    var restored_depth := int(data["depth"])
    var restored_drill_level := int(data["drill_level"])
    for facility in data["jobs"]:
        if facility not in FACILITIES or typeof(data["jobs"][facility]) != TYPE_DICTIONARY:
            return false
        var job: Dictionary = data["jobs"][facility]
        if facility == "drill":
            if not _valid_drill_job(job, restored_depth, restored_drill_level):
                return false
        elif not _valid_batch_job(facility, job):
            return false
    return true

func _valid_batch_job(facility: String, job: Dictionary) -> bool:
    if not _has_exact_keys(job, ["recipe", "quantity", "remaining", "duration"]):
        return false
    if typeof(job["recipe"]) != TYPE_STRING or not Catalog.RECIPES.has(job["recipe"]):
        return false
    var recipe: Dictionary = Catalog.RECIPES[job["recipe"]]
    if recipe["facility"] != facility or not _valid_integer(job["quantity"], 1, 10):
        return false
    if not _valid_job_times(job):
        return false
    var expected_duration := float(recipe["seconds"]) * int(job["quantity"])
    return is_equal_approx(float(job["duration"]), expected_duration)

func _valid_drill_job(job: Dictionary, restored_depth: int, restored_drill_level: int) -> bool:
    if not _has_exact_keys(job, ["target_depth", "remaining", "duration"]):
        return false
    if not _valid_integer(job["target_depth"], 10):
        return false
    if int(job["target_depth"]) != restored_depth + 10 or not _valid_job_times(job):
        return false
    var required_level := mini(Catalog.MAX_DRILL_LEVEL, 1 + floori(float(restored_depth + 10) / 30.0))
    if restored_drill_level < required_level:
        return false
    for committed_level in range(required_level, restored_drill_level + 1):
        var committed_duration := (30.0 + restored_depth * 0.5) / committed_level
        if is_equal_approx(float(job["duration"]), committed_duration):
            return true
    return false

func _valid_job_times(job: Dictionary) -> bool:
    if not _finite_number(job["remaining"]) or not _finite_number(job["duration"]):
        return false
    var remaining := float(job["remaining"])
    var duration := float(job["duration"])
    return remaining > 0.0 and duration > 0.0 and remaining <= duration + EPSILON

func _finite_number(value: Variant) -> bool:
    return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))

func _valid_integer(value: Variant, minimum: int, maximum: int = 2147483647) -> bool:
    if not _finite_number(value):
        return false
    var numeric := float(value)
    return numeric == floor(numeric) and numeric >= minimum and numeric <= maximum

func _has_exact_keys(value: Dictionary, expected: Array) -> bool:
    if value.size() != expected.size():
        return false
    for key in expected:
        if not value.has(key):
            return false
    return true
