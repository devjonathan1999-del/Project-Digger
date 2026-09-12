class_name IndustryCatalog
extends RefCounted

const RESOURCES: Dictionary = {
    "iron": {
        "label": "Fer",
        "raw": true,
        "depth": 0
    },
    "coal": {
        "label": "Charbon",
        "raw": true,
        "depth": 0
    },
    "copper": {
        "label": "Cuivre",
        "raw": true,
        "depth": 0
    },
    "crystal": {
        "label": "Cristal brut",
        "raw": true,
        "depth": 90
    },
    "silica": {
        "label": "Silice",
        "raw": true,
        "depth": 60
    },
    "bauxite": {
        "label": "Bauxite",
        "raw": true,
        "depth": 150
    },
    "sulfur": {
        "label": "Soufre",
        "raw": true,
        "depth": 150
    },
    "nickel": {
        "label": "Nickel",
        "raw": true,
        "depth": 240
    },
    "tungsten": {
        "label": "Tungstène",
        "raw": true,
        "depth": 360
    },
    "cobalt": {
        "label": "Cobalt",
        "raw": true,
        "depth": 360
    },
    "lithium": {
        "label": "Lithium",
        "raw": true,
        "depth": 500
    },
    "titanium": {
        "label": "Titane",
        "raw": true,
        "depth": 500
    },
    "rare_earths": {
        "label": "Terres rares",
        "raw": true,
        "depth": 700
    },
    "ancient_fragment": {
        "label": "Fragment ancien",
        "raw": true,
        "depth": 1000
    },
    "iron_ingot": {
        "label": "Lingot de fer",
        "raw": false,
        "depth": 0
    },
    "copper_ingot": {
        "label": "Lingot de cuivre",
        "raw": false,
        "depth": 0
    },
    "cable": {
        "label": "Câble",
        "raw": false,
        "depth": 0
    },
    "iron_plate": {
        "label": "Plaque de fer",
        "raw": false,
        "depth": 0
    },
    "copper_wire": {
        "label": "Fil de cuivre",
        "raw": false,
        "depth": 0
    },
    "gear": {
        "label": "Engrenage",
        "raw": false,
        "depth": 0
    },
    "bolts": {
        "label": "Boulons",
        "raw": false,
        "depth": 0
    },
    "chain": {
        "label": "Chaîne",
        "raw": false,
        "depth": 0
    },
    "graphite": {
        "label": "Graphite",
        "raw": false,
        "depth": 0
    },
    "mechanical_chassis": {
        "label": "Châssis mécanique",
        "raw": false,
        "depth": 0
    },
    "steel": {
        "label": "Acier",
        "raw": false,
        "depth": 30
    },
    "steel_plate": {
        "label": "Plaque d'acier",
        "raw": false,
        "depth": 30
    },
    "bearings": {
        "label": "Roulements",
        "raw": false,
        "depth": 30
    },
    "copper_coil": {
        "label": "Bobine de cuivre",
        "raw": false,
        "depth": 30
    },
    "pulley": {
        "label": "Poulie",
        "raw": false,
        "depth": 30
    },
    "reinforced_cable": {
        "label": "Câble renforcé",
        "raw": false,
        "depth": 30
    },
    "conveyor": {
        "label": "Convoyeur",
        "raw": false,
        "depth": 30
    },
    "simple_motor": {
        "label": "Moteur simple",
        "raw": false,
        "depth": 30
    },
    "winch": {
        "label": "Treuil",
        "raw": false,
        "depth": 30
    },
    "drill_head_1": {
        "label": "Tête de forage I",
        "raw": false,
        "depth": 30
    },
    "industrial_glass": {
        "label": "Verre industriel",
        "raw": false,
        "depth": 60
    },
    "steel_pipes": {
        "label": "Tuyaux acier",
        "raw": false,
        "depth": 60
    },
    "valves": {
        "label": "Vannes",
        "raw": false,
        "depth": 60
    },
    "fan": {
        "label": "Ventilateur",
        "raw": false,
        "depth": 60
    },
    "pump": {
        "label": "Pompe",
        "raw": false,
        "depth": 60
    },
    "rotor": {
        "label": "Rotor",
        "raw": false,
        "depth": 60
    },
    "dynamo": {
        "label": "Dynamo",
        "raw": false,
        "depth": 60
    },
    "pressure_unit": {
        "label": "Groupe de pression",
        "raw": false,
        "depth": 60
    },
    "ventilation_module": {
        "label": "Module de ventilation",
        "raw": false,
        "depth": 60
    },
    "drill_head_2": {
        "label": "Tête de forage II",
        "raw": false,
        "depth": 60
    },
    "cut_crystal": {
        "label": "Cristal taillé",
        "raw": false,
        "depth": 90
    },
    "crystal_lens": {
        "label": "Lentille cristalline",
        "raw": false,
        "depth": 90
    },
    "crystal_conductor": {
        "label": "Conducteur cristallin",
        "raw": false,
        "depth": 90
    },
    "sensor": {
        "label": "Capteur",
        "raw": false,
        "depth": 90
    },
    "circuit": {
        "label": "Circuit",
        "raw": false,
        "depth": 90
    },
    "control_unit": {
        "label": "Unité de contrôle",
        "raw": false,
        "depth": 90
    },
    "servomotor": {
        "label": "Servomoteur",
        "raw": false,
        "depth": 90
    },
    "automatic_sorter": {
        "label": "Trieur automatique",
        "raw": false,
        "depth": 90
    },
    "deep_scanner": {
        "label": "Scanner profond",
        "raw": false,
        "depth": 90
    },
    "drill_controller_1": {
        "label": "Contrôleur de forage I",
        "raw": false,
        "depth": 90
    },
    "aluminium": {
        "label": "Aluminium",
        "raw": false,
        "depth": 150
    },
    "aluminium_plate": {
        "label": "Plaque aluminium",
        "raw": false,
        "depth": 150
    },
    "refined_sulfur": {
        "label": "Soufre raffiné",
        "raw": false,
        "depth": 150
    },
    "electrolyte": {
        "label": "Électrolyte",
        "raw": false,
        "depth": 150
    },
    "battery_cell": {
        "label": "Cellule batterie",
        "raw": false,
        "depth": 150
    },
    "industrial_battery": {
        "label": "Batterie industrielle",
        "raw": false,
        "depth": 150
    },
    "light_chassis": {
        "label": "Châssis léger",
        "raw": false,
        "depth": 150
    },
    "heat_sink": {
        "label": "Dissipateur thermique",
        "raw": false,
        "depth": 150
    },
    "cooling_module": {
        "label": "Module refroidissement",
        "raw": false,
        "depth": 150
    },
    "drill_head_3": {
        "label": "Tête de forage III",
        "raw": false,
        "depth": 150
    },
    "nickel_ingot": {
        "label": "Lingot de nickel",
        "raw": false,
        "depth": 240
    },
    "stainless_steel": {
        "label": "Acier inoxydable",
        "raw": false,
        "depth": 240
    },
    "stainless_plate": {
        "label": "Plaque inox",
        "raw": false,
        "depth": 240
    },
    "precision_bearings": {
        "label": "Roulements précision",
        "raw": false,
        "depth": 240
    },
    "electromagnet": {
        "label": "Électroaimant",
        "raw": false,
        "depth": 240
    },
    "industrial_motor": {
        "label": "Moteur industriel",
        "raw": false,
        "depth": 240
    },
    "stainless_tubes": {
        "label": "Tubes inox",
        "raw": false,
        "depth": 240
    },
    "hydraulic_cylinder": {
        "label": "Vérin hydraulique",
        "raw": false,
        "depth": 240
    },
    "industrial_actuator": {
        "label": "Actionneur industriel",
        "raw": false,
        "depth": 240
    },
    "elevator_drive": {
        "label": "Entraînement d'ascenseur",
        "raw": false,
        "depth": 240
    },
    "tungsten_ingot": {
        "label": "Lingot tungstène",
        "raw": false,
        "depth": 360
    },
    "tungsten_carbide": {
        "label": "Carbure de tungstène",
        "raw": false,
        "depth": 360
    },
    "cobalt_ingot": {
        "label": "Lingot cobalt",
        "raw": false,
        "depth": 360
    },
    "superalloy": {
        "label": "Superalliage",
        "raw": false,
        "depth": 360
    },
    "carbide_tooth": {
        "label": "Dent carbure",
        "raw": false,
        "depth": 360
    },
    "heavy_drill_crown": {
        "label": "Couronne de forage lourd",
        "raw": false,
        "depth": 360
    },
    "high_temperature_coil": {
        "label": "Bobine haute température",
        "raw": false,
        "depth": 360
    },
    "heavy_motor": {
        "label": "Moteur lourd",
        "raw": false,
        "depth": 360
    },
    "thermal_shield": {
        "label": "Bouclier thermique",
        "raw": false,
        "depth": 360
    },
    "deep_drilling_unit": {
        "label": "Groupe de forage profond",
        "raw": false,
        "depth": 360
    },
    "lithium_concentrate": {
        "label": "Concentré de lithium",
        "raw": false,
        "depth": 500
    },
    "lithium_cell": {
        "label": "Cellule lithium",
        "raw": false,
        "depth": 500
    },
    "high_density_battery": {
        "label": "Batterie haute densité",
        "raw": false,
        "depth": 500
    },
    "titanium_ingot": {
        "label": "Lingot titane",
        "raw": false,
        "depth": 500
    },
    "titanium_plate": {
        "label": "Plaque titane",
        "raw": false,
        "depth": 500
    },
    "titanium_chassis": {
        "label": "Châssis titane",
        "raw": false,
        "depth": 500
    },
    "precision_servo": {
        "label": "Servo de précision",
        "raw": false,
        "depth": 500
    },
    "advanced_circuit": {
        "label": "Circuit avancé",
        "raw": false,
        "depth": 500
    },
    "navigation_core": {
        "label": "Noyau de navigation",
        "raw": false,
        "depth": 500
    },
    "drill_head_4": {
        "label": "Tête de forage IV",
        "raw": false,
        "depth": 500
    },
    "rare_earth_concentrate": {
        "label": "Concentré de terres rares",
        "raw": false,
        "depth": 700
    },
    "permanent_magnet": {
        "label": "Aimant permanent",
        "raw": false,
        "depth": 700
    },
    "flux_regulator": {
        "label": "Régulateur de flux",
        "raw": false,
        "depth": 700
    },
    "resonance_coil": {
        "label": "Bobine de résonance",
        "raw": false,
        "depth": 700
    },
    "resonant_sensor": {
        "label": "Capteur résonant",
        "raw": false,
        "depth": 700
    },
    "logic_core": {
        "label": "Noyau logique",
        "raw": false,
        "depth": 700
    },
    "vector_motor": {
        "label": "Moteur vectoriel",
        "raw": false,
        "depth": 700
    },
    "active_cooling": {
        "label": "Refroidissement actif",
        "raw": false,
        "depth": 700
    },
    "autonomous_drill_module": {
        "label": "Module de forage autonome",
        "raw": false,
        "depth": 700
    },
    "deep_command_core": {
        "label": "Noyau de commande profond",
        "raw": false,
        "depth": 700
    },
    "ancient_alloy": {
        "label": "Alliage ancien",
        "raw": false,
        "depth": 1000
    },
    "resonant_crystal": {
        "label": "Cristal résonant",
        "raw": false,
        "depth": 1000
    },
    "resonance_matrix": {
        "label": "Matrice de résonance",
        "raw": false,
        "depth": 1000
    },
    "ancient_conductor": {
        "label": "Conducteur ancien",
        "raw": false,
        "depth": 1000
    },
    "stabilization_core": {
        "label": "Noyau de stabilisation",
        "raw": false,
        "depth": 1000
    },
    "inertial_compensator": {
        "label": "Compensateur inertiel",
        "raw": false,
        "depth": 1000
    },
    "deep_reactor": {
        "label": "Réacteur profond",
        "raw": false,
        "depth": 1000
    },
    "drilling_core_5": {
        "label": "Cœur de forage V",
        "raw": false,
        "depth": 1000
    },
    "autonomous_excavator": {
        "label": "Excavateur autonome",
        "raw": false,
        "depth": 1000
    },
    "abyssal_core": {
        "label": "Cœur abyssal",
        "raw": false,
        "depth": 1000
    }
}

const MINES: Dictionary = {
    "iron": {"label": "Mine de fer", "base_rate": 0.20},
    "coal": {"label": "Mine de charbon", "base_rate": 0.12},
    "copper": {"label": "Mine de cuivre", "base_rate": 0.10},
}

const RECIPES: Dictionary = preload("res://src/industry/industry_recipes.gd").RECIPES

const CENTER_LEVELS: Dictionary = {
    1: {
        "depth": 0,
        "capacity": 3,
        "cost": {}
    },
    2: {
        "depth": 30,
        "capacity": 4,
        "cost": {
            "mechanical_chassis": 1
        }
    },
    3: {
        "depth": 60,
        "capacity": 5,
        "cost": {
            "conveyor": 1
        }
    },
    4: {
        "depth": 90,
        "capacity": 6,
        "cost": {
            "ventilation_module": 1
        }
    },
    5: {
        "depth": 120,
        "capacity": 7,
        "cost": {
            "control_unit": 1
        }
    },
    6: {
        "depth": 150,
        "capacity": 8,
        "cost": {
            "deep_scanner": 1
        }
    },
    7: {
        "depth": 240,
        "capacity": 10,
        "cost": {
            "light_chassis": 1,
            "industrial_battery": 1
        }
    },
    8: {
        "depth": 360,
        "capacity": 12,
        "cost": {
            "industrial_actuator": 1
        }
    },
    9: {
        "depth": 500,
        "capacity": 14,
        "cost": {
            "thermal_shield": 1
        }
    },
    10: {
        "depth": 700,
        "capacity": 16,
        "cost": {
            "navigation_core": 1
        }
    },
    11: {
        "depth": 1000,
        "capacity": 18,
        "cost": {
            "deep_command_core": 1
        }
    },
    12: {
        "depth": 1500,
        "capacity": 20,
        "cost": {
            "autonomous_excavator": 1
        }
    }
}

const MILESTONES: Dictionary = {
    30: {"center_level": 2, "tech_points": 0, "guaranteed_pocket": "rich_vein"},
    60: {"center_level": 3, "tech_points": 0, "requires_drill": 2},
    90: {"center_level": 4, "tech_points": 1, "guaranteed_pocket": "crystal_cavern"},
    120: {"center_level": 5, "tech_points": 1, "guaranteed_pocket": "ancient_structure"},
    150: {"center_level": 6, "tech_points": 1, "biome": "deep_zone"},
}

const POCKET_TYPES: Dictionary = {
    "rich_vein": {
        "kind": "exhaustible",
        "hint": "Forte signature minérale",
        "capacity": 0,
        "cost": {"iron": 10},
        "seconds": 60.0,
    },
    "unstable_cavity": {
        "kind": "exhaustible",
        "hint": "Cavité instable",
        "capacity": 0,
        "cost": {"iron": 12, "coal": 4},
        "seconds": 90.0,
    },
    "crystal_cavern": {
        "kind": "permanent",
        "hint": "Anomalie minérale",
        "capacity": 2,
        "cost": {"iron_ingot": 3, "cable": 1},
        "seconds": 180.0,
    },
    "ancient_structure": {
        "kind": "permanent",
        "hint": "Structure inconnue",
        "capacity": 2,
        "cost": {"iron_ingot": 5, "copper_ingot": 3, "cable": 2},
        "seconds": 300.0,
    },
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


const MAX_DEPTH := 1500

const FACILITIES: Dictionary = {
    "furnace": {
        "label": "Fonderie",
        "depth": 0,
        "prefix": "Furnace"
    },
    "workshop": {
        "label": "Atelier",
        "depth": 0,
        "prefix": "Workshop"
    },
    "machining": {
        "label": "Usinage",
        "depth": 30,
        "prefix": "Machining"
    },
    "crystal_lab": {
        "label": "Laboratoire cristallin",
        "depth": 90,
        "prefix": "CrystalLab"
    },
    "electronics": {
        "label": "Électronique",
        "depth": 90,
        "prefix": "Electronics"
    },
    "chemistry": {
        "label": "Chimie",
        "depth": 150,
        "prefix": "Chemistry"
    }
}

const DEEP_MINES: Dictionary = {
    "silica": {
        "label": "Mine de silice",
        "base_rate": 0.08,
        "depth": 60
    },
    "bauxite": {
        "label": "Mine de bauxite",
        "base_rate": 0.08,
        "depth": 150
    },
    "sulfur": {
        "label": "Mine de soufre",
        "base_rate": 0.08,
        "depth": 150
    },
    "nickel": {
        "label": "Mine de nickel",
        "base_rate": 0.08,
        "depth": 240
    },
    "tungsten": {
        "label": "Mine de tungstène",
        "base_rate": 0.08,
        "depth": 360
    },
    "cobalt": {
        "label": "Mine de cobalt",
        "base_rate": 0.08,
        "depth": 360
    },
    "lithium": {
        "label": "Mine de lithium",
        "base_rate": 0.08,
        "depth": 500
    },
    "titanium": {
        "label": "Mine de titane",
        "base_rate": 0.08,
        "depth": 500
    },
    "rare_earths": {
        "label": "Mine de terres rares",
        "base_rate": 0.08,
        "depth": 700
    }
}

const GATES: Dictionary = {
    30: {
        "mechanical_chassis": 1
    },
    60: {
        "drill_head_1": 1,
        "winch": 1
    },
    90: {
        "drill_head_2": 1,
        "ventilation_module": 1
    },
    150: {
        "drill_controller_1": 1,
        "deep_scanner": 1
    },
    240: {
        "drill_head_3": 1,
        "cooling_module": 1
    },
    360: {
        "elevator_drive": 1,
        "industrial_motor": 1
    },
    500: {
        "deep_drilling_unit": 1
    },
    700: {
        "drill_head_4": 1,
        "high_density_battery": 1
    },
    1000: {
        "autonomous_drill_module": 1,
        "deep_command_core": 1
    },
    1500: {
        "autonomous_excavator": 1
    }
}

const DRILL_UPGRADES: Dictionary = {
    1: {
        "depth": 30,
        "cost": {
            "drill_head_1": 1
        }
    },
    2: {
        "depth": 60,
        "cost": {
            "drill_head_2": 1
        }
    },
    3: {
        "depth": 150,
        "cost": {
            "drill_head_3": 1
        }
    },
    4: {
        "depth": 500,
        "cost": {
            "drill_head_4": 1
        }
    }
}

static func mine_definitions() -> Dictionary:
    var definitions: Dictionary = MINES.duplicate(true)
    definitions.merge(DEEP_MINES, true)
    return definitions
