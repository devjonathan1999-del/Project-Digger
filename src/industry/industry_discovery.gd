class_name IndustryDiscovery
extends RefCounted

const Catalog = preload("res://src/industry/industry_catalog.gd")

static func generate(seed: int, depth: int, slot: int, quality_floor: float) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = hash([seed, depth, slot])
    var forced := ""
    if Catalog.MILESTONES.has(depth):
        forced = str(Catalog.MILESTONES[depth].get("guaranteed_pocket", ""))
    var type_id := forced
    if type_id == "":
        var candidates := ["rich_vein", "unstable_cavity"]
        if depth >= 90:
            candidates.append("crystal_cavern")
        type_id = candidates[rng.randi_range(0, candidates.size() - 1)]
    var quality := maxf(clampf(quality_floor, 0.0, 0.8), rng.randf())
    var definition: Dictionary = Catalog.POCKET_TYPES[type_id]
    var reward := _reward_for(type_id, quality)
    return {
        "id": "%d:%d" % [depth, slot],
        "depth": depth,
        "slot": slot,
        "type": type_id,
        "kind": definition["kind"],
        "hint": definition["hint"],
        "quality": quality,
        "reward": reward,
        "state": "detected",
        "active": false,
    }

static func _reward_for(type_id: String, quality: float) -> Dictionary:
    match type_id:
        "rich_vein":
            return {"resource": "iron", "amount": 40 + int(round(quality * 40.0))}
        "unstable_cavity":
            return {"event": "unstable_vein"}
        "crystal_cavern":
            return {"resource": "crystal", "rate": 0.025 + quality * 0.015}
        "ancient_structure":
            return {"tech_points": 1}
    return {}
