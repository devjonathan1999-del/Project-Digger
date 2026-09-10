class_name IndustryCatalog
extends RefCounted

const RESOURCES: Dictionary = {
    "iron": {"label": "Fer", "raw": true},
    "coal": {"label": "Charbon", "raw": true},
    "copper": {"label": "Cuivre", "raw": true},
    "iron_ingot": {"label": "Lingot de fer", "raw": false},
    "copper_ingot": {"label": "Lingot de cuivre", "raw": false},
    "cable": {"label": "Câble", "raw": false},
}

const MINES: Dictionary = {
    "iron": {"label": "Mine de fer", "base_rate": 0.20},
    "coal": {"label": "Mine de charbon", "base_rate": 0.12},
    "copper": {"label": "Mine de cuivre", "base_rate": 0.10},
}

const RECIPES: Dictionary = {
    "iron_ingot": {
        "label": "Lingot de fer",
        "facility": "furnace",
        "inputs": {"iron": 4, "coal": 1},
        "output": "iron_ingot",
        "seconds": 20.0,
    },
    "copper_ingot": {
        "label": "Lingot de cuivre",
        "facility": "furnace",
        "inputs": {"copper": 3, "coal": 1},
        "output": "copper_ingot",
        "seconds": 25.0,
    },
    "cable": {
        "label": "Câble",
        "facility": "workshop",
        "inputs": {"copper_ingot": 2, "iron_ingot": 1},
        "output": "cable",
        "seconds": 40.0,
    },
}

const CENTER_LEVELS: Dictionary = {
    1: {"depth": 0, "capacity": 3, "cost": {}},
    2: {"depth": 30, "capacity": 4, "cost": {"iron": 24, "coal": 10}},
    3: {"depth": 60, "capacity": 5, "cost": {"iron_ingot": 4, "cable": 1}},
    4: {"depth": 90, "capacity": 6, "cost": {"iron_ingot": 6, "copper_ingot": 4, "cable": 2}},
    5: {"depth": 120, "capacity": 7, "cost": {"iron_ingot": 10, "copper_ingot": 8, "cable": 4, "crystal": 6}},
    6: {"depth": 150, "capacity": 8, "cost": {"iron_ingot": 16, "copper_ingot": 12, "cable": 6, "crystal": 12}},
}

const MILESTONES: Dictionary = {
    30: {"center_level": 2, "tech_points": 0, "guaranteed_pocket": "rich_vein"},
    60: {"center_level": 3, "tech_points": 0, "requires_drill": 2},
    90: {"center_level": 4, "tech_points": 1, "guaranteed_pocket": "crystal_cavern"},
    120: {"center_level": 5, "tech_points": 1, "guaranteed_pocket": "ancient_structure"},
    150: {"center_level": 6, "tech_points": 1, "biome": "deep_zone"},
}

const POCKET_TYPES: Dictionary = {
    "rich_vein": {"kind": "exhaustible", "hint": "Forte signature minérale", "capacity": 0},
    "unstable_cavity": {"kind": "exhaustible", "hint": "Cavité instable", "capacity": 0},
    "crystal_cavern": {"kind": "permanent", "hint": "Anomalie minérale", "capacity": 2},
    "ancient_structure": {"kind": "permanent", "hint": "Structure inconnue", "capacity": 2},
}

const TECHNOLOGIES: Dictionary = {
    "production_1": {"branch": "production", "tech_points": 1, "cost": {"iron_ingot": 6, "cable": 2}, "effect": 0.10},
    "logistics_1": {"branch": "logistics", "tech_points": 1, "cost": {"iron_ingot": 5, "copper_ingot": 4, "cable": 2}, "effect": 1},
    "exploration_1": {"branch": "exploration", "tech_points": 1, "cost": {"copper_ingot": 5, "cable": 3, "crystal": 4}, "effect": 0.20},
}

const PRIORITY_BONUSES: Dictionary = {
    "production": {"production_rate": 0.10},
    "logistics": {"capacity": 1},
    "exploration": {"quality_floor": 0.20},
}

const EVENTS: Dictionary = {
    "unstable_vein": {"duration": 300.0, "rate_bonus": 1.0, "choices": ["iron", "copper", "coal"]},
}

const MAX_MINE_LEVEL := 10
const MAX_DRILL_LEVEL := 5
