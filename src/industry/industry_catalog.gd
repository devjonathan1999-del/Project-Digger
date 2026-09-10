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

const MAX_MINE_LEVEL := 10
const MAX_DRILL_LEVEL := 5
