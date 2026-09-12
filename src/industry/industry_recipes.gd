class_name IndustryRecipes
extends RefCounted

# Approved recipe table; IDs double as output resource IDs.
const RECIPES: Dictionary = {
    "iron_ingot": {
        "label": "Lingot de fer",
        "facility": "furnace",
        "inputs": {
            "iron": 4,
            "coal": 1
        },
        "output": "iron_ingot",
        "seconds": 20.0,
        "yield": 1,
        "depth": 0,
        "tier": 1,
        "number": 1
    },
    "copper_ingot": {
        "label": "Lingot de cuivre",
        "facility": "furnace",
        "inputs": {
            "copper": 3,
            "coal": 1
        },
        "output": "copper_ingot",
        "seconds": 25.0,
        "yield": 1,
        "depth": 0,
        "tier": 1,
        "number": 2
    },
    "cable": {
        "label": "Câble",
        "facility": "workshop",
        "inputs": {
            "copper_ingot": 2,
            "iron_ingot": 1
        },
        "output": "cable",
        "seconds": 40.0,
        "yield": 1,
        "depth": 0,
        "tier": 1,
        "number": 3
    },
    "iron_plate": {
        "label": "Plaque de fer",
        "facility": "workshop",
        "inputs": {
            "iron_ingot": 2
        },
        "output": "iron_plate",
        "seconds": 30.0,
        "yield": 1,
        "depth": 0,
        "tier": 1,
        "number": 4
    },
    "copper_wire": {
        "label": "Fil de cuivre",
        "facility": "workshop",
        "inputs": {
            "copper_ingot": 1
        },
        "output": "copper_wire",
        "seconds": 30.0,
        "yield": 4,
        "depth": 0,
        "tier": 1,
        "number": 5
    },
    "gear": {
        "label": "Engrenage",
        "facility": "workshop",
        "inputs": {
            "iron_ingot": 2
        },
        "output": "gear",
        "seconds": 45.0,
        "yield": 1,
        "depth": 0,
        "tier": 1,
        "number": 6
    },
    "bolts": {
        "label": "Boulons",
        "facility": "workshop",
        "inputs": {
            "iron_ingot": 1
        },
        "output": "bolts",
        "seconds": 25.0,
        "yield": 4,
        "depth": 0,
        "tier": 1,
        "number": 7
    },
    "chain": {
        "label": "Chaîne",
        "facility": "workshop",
        "inputs": {
            "iron_ingot": 2
        },
        "output": "chain",
        "seconds": 50.0,
        "yield": 1,
        "depth": 0,
        "tier": 1,
        "number": 8
    },
    "graphite": {
        "label": "Graphite",
        "facility": "furnace",
        "inputs": {
            "coal": 4
        },
        "output": "graphite",
        "seconds": 40.0,
        "yield": 1,
        "depth": 0,
        "tier": 1,
        "number": 9
    },
    "mechanical_chassis": {
        "label": "Châssis mécanique",
        "facility": "workshop",
        "inputs": {
            "iron_plate": 2,
            "gear": 1,
            "bolts": 2
        },
        "output": "mechanical_chassis",
        "seconds": 90.0,
        "yield": 1,
        "depth": 0,
        "tier": 1,
        "number": 10
    },
    "steel": {
        "label": "Acier",
        "facility": "furnace",
        "inputs": {
            "iron_ingot": 2,
            "graphite": 1
        },
        "output": "steel",
        "seconds": 60.0,
        "yield": 1,
        "depth": 30,
        "tier": 2,
        "number": 11
    },
    "steel_plate": {
        "label": "Plaque d'acier",
        "facility": "workshop",
        "inputs": {
            "steel": 2
        },
        "output": "steel_plate",
        "seconds": 75.0,
        "yield": 1,
        "depth": 30,
        "tier": 2,
        "number": 12
    },
    "bearings": {
        "label": "Roulements",
        "facility": "machining",
        "inputs": {
            "steel": 1,
            "copper_ingot": 1
        },
        "output": "bearings",
        "seconds": 60.0,
        "yield": 2,
        "depth": 30,
        "tier": 2,
        "number": 13
    },
    "copper_coil": {
        "label": "Bobine de cuivre",
        "facility": "workshop",
        "inputs": {
            "copper_wire": 3,
            "iron_plate": 1
        },
        "output": "copper_coil",
        "seconds": 90.0,
        "yield": 1,
        "depth": 30,
        "tier": 2,
        "number": 14
    },
    "pulley": {
        "label": "Poulie",
        "facility": "machining",
        "inputs": {
            "steel_plate": 1,
            "bearings": 1
        },
        "output": "pulley",
        "seconds": 120.0,
        "yield": 1,
        "depth": 30,
        "tier": 2,
        "number": 15
    },
    "reinforced_cable": {
        "label": "Câble renforcé",
        "facility": "workshop",
        "inputs": {
            "cable": 2,
            "steel_plate": 1
        },
        "output": "reinforced_cable",
        "seconds": 120.0,
        "yield": 1,
        "depth": 30,
        "tier": 2,
        "number": 16
    },
    "conveyor": {
        "label": "Convoyeur",
        "facility": "machining",
        "inputs": {
            "chain": 2,
            "bearings": 2,
            "mechanical_chassis": 1
        },
        "output": "conveyor",
        "seconds": 180.0,
        "yield": 1,
        "depth": 30,
        "tier": 2,
        "number": 17
    },
    "simple_motor": {
        "label": "Moteur simple",
        "facility": "machining",
        "inputs": {
            "copper_coil": 2,
            "gear": 2,
            "steel_plate": 1
        },
        "output": "simple_motor",
        "seconds": 180.0,
        "yield": 1,
        "depth": 30,
        "tier": 2,
        "number": 18
    },
    "winch": {
        "label": "Treuil",
        "facility": "machining",
        "inputs": {
            "simple_motor": 1,
            "pulley": 2,
            "chain": 2
        },
        "output": "winch",
        "seconds": 300.0,
        "yield": 1,
        "depth": 30,
        "tier": 2,
        "number": 19
    },
    "drill_head_1": {
        "label": "Tête de forage I",
        "facility": "machining",
        "inputs": {
            "steel_plate": 3,
            "gear": 2,
            "reinforced_cable": 1
        },
        "output": "drill_head_1",
        "seconds": 300.0,
        "yield": 1,
        "depth": 30,
        "tier": 2,
        "number": 20
    },
    "industrial_glass": {
        "label": "Verre industriel",
        "facility": "furnace",
        "inputs": {
            "silica": 5,
            "coal": 1
        },
        "output": "industrial_glass",
        "seconds": 90.0,
        "yield": 2,
        "depth": 60,
        "tier": 3,
        "number": 21
    },
    "steel_pipes": {
        "label": "Tuyaux acier",
        "facility": "machining",
        "inputs": {
            "steel_plate": 1
        },
        "output": "steel_pipes",
        "seconds": 75.0,
        "yield": 2,
        "depth": 60,
        "tier": 3,
        "number": 22
    },
    "valves": {
        "label": "Vannes",
        "facility": "machining",
        "inputs": {
            "steel": 1,
            "bearings": 1
        },
        "output": "valves",
        "seconds": 90.0,
        "yield": 2,
        "depth": 60,
        "tier": 3,
        "number": 23
    },
    "fan": {
        "label": "Ventilateur",
        "facility": "machining",
        "inputs": {
            "simple_motor": 1,
            "steel_plate": 2,
            "cable": 1
        },
        "output": "fan",
        "seconds": 240.0,
        "yield": 1,
        "depth": 60,
        "tier": 3,
        "number": 24
    },
    "pump": {
        "label": "Pompe",
        "facility": "machining",
        "inputs": {
            "simple_motor": 1,
            "steel_pipes": 2,
            "valves": 1
        },
        "output": "pump",
        "seconds": 300.0,
        "yield": 1,
        "depth": 60,
        "tier": 3,
        "number": 25
    },
    "rotor": {
        "label": "Rotor",
        "facility": "machining",
        "inputs": {
            "steel": 2,
            "copper_coil": 1,
            "bearings": 1
        },
        "output": "rotor",
        "seconds": 180.0,
        "yield": 1,
        "depth": 60,
        "tier": 3,
        "number": 26
    },
    "dynamo": {
        "label": "Dynamo",
        "facility": "workshop",
        "inputs": {
            "rotor": 1,
            "copper_coil": 2,
            "cable": 1
        },
        "output": "dynamo",
        "seconds": 360.0,
        "yield": 1,
        "depth": 60,
        "tier": 3,
        "number": 27
    },
    "pressure_unit": {
        "label": "Groupe de pression",
        "facility": "machining",
        "inputs": {
            "pump": 1,
            "valves": 2,
            "reinforced_cable": 1
        },
        "output": "pressure_unit",
        "seconds": 480.0,
        "yield": 1,
        "depth": 60,
        "tier": 3,
        "number": 28
    },
    "ventilation_module": {
        "label": "Module de ventilation",
        "facility": "machining",
        "inputs": {
            "fan": 1,
            "steel_pipes": 2,
            "mechanical_chassis": 1
        },
        "output": "ventilation_module",
        "seconds": 600.0,
        "yield": 1,
        "depth": 60,
        "tier": 3,
        "number": 29
    },
    "drill_head_2": {
        "label": "Tête de forage II",
        "facility": "machining",
        "inputs": {
            "drill_head_1": 1,
            "steel_plate": 2,
            "rotor": 1
        },
        "output": "drill_head_2",
        "seconds": 600.0,
        "yield": 1,
        "depth": 60,
        "tier": 3,
        "number": 30
    },
    "cut_crystal": {
        "label": "Cristal taillé",
        "facility": "crystal_lab",
        "inputs": {
            "crystal": 4
        },
        "output": "cut_crystal",
        "seconds": 120.0,
        "yield": 1,
        "depth": 90,
        "tier": 4,
        "number": 31
    },
    "crystal_lens": {
        "label": "Lentille cristalline",
        "facility": "crystal_lab",
        "inputs": {
            "cut_crystal": 2,
            "industrial_glass": 1
        },
        "output": "crystal_lens",
        "seconds": 240.0,
        "yield": 1,
        "depth": 90,
        "tier": 4,
        "number": 32
    },
    "crystal_conductor": {
        "label": "Conducteur cristallin",
        "facility": "crystal_lab",
        "inputs": {
            "cut_crystal": 1,
            "copper_wire": 4
        },
        "output": "crystal_conductor",
        "seconds": 300.0,
        "yield": 1,
        "depth": 90,
        "tier": 4,
        "number": 33
    },
    "sensor": {
        "label": "Capteur",
        "facility": "electronics",
        "inputs": {
            "crystal_lens": 1,
            "copper_coil": 1,
            "reinforced_cable": 1
        },
        "output": "sensor",
        "seconds": 360.0,
        "yield": 1,
        "depth": 90,
        "tier": 4,
        "number": 34
    },
    "circuit": {
        "label": "Circuit",
        "facility": "electronics",
        "inputs": {
            "copper_wire": 2,
            "graphite": 1,
            "industrial_glass": 1
        },
        "output": "circuit",
        "seconds": 300.0,
        "yield": 1,
        "depth": 90,
        "tier": 4,
        "number": 35
    },
    "control_unit": {
        "label": "Unité de contrôle",
        "facility": "electronics",
        "inputs": {
            "circuit": 2,
            "sensor": 1,
            "cable": 1
        },
        "output": "control_unit",
        "seconds": 600.0,
        "yield": 1,
        "depth": 90,
        "tier": 4,
        "number": 36
    },
    "servomotor": {
        "label": "Servomoteur",
        "facility": "machining",
        "inputs": {
            "simple_motor": 1,
            "control_unit": 1,
            "bearings": 1
        },
        "output": "servomotor",
        "seconds": 720.0,
        "yield": 1,
        "depth": 90,
        "tier": 4,
        "number": 37
    },
    "automatic_sorter": {
        "label": "Trieur automatique",
        "facility": "electronics",
        "inputs": {
            "servomotor": 1,
            "sensor": 1,
            "conveyor": 1
        },
        "output": "automatic_sorter",
        "seconds": 900.0,
        "yield": 1,
        "depth": 90,
        "tier": 4,
        "number": 38
    },
    "deep_scanner": {
        "label": "Scanner profond",
        "facility": "electronics",
        "inputs": {
            "sensor": 2,
            "control_unit": 1,
            "crystal_lens": 1
        },
        "output": "deep_scanner",
        "seconds": 1200.0,
        "yield": 1,
        "depth": 90,
        "tier": 4,
        "number": 39
    },
    "drill_controller_1": {
        "label": "Contrôleur de forage I",
        "facility": "electronics",
        "inputs": {
            "control_unit": 1,
            "servomotor": 1,
            "crystal_conductor": 1
        },
        "output": "drill_controller_1",
        "seconds": 1200.0,
        "yield": 1,
        "depth": 90,
        "tier": 4,
        "number": 40
    },
    "aluminium": {
        "label": "Aluminium",
        "facility": "furnace",
        "inputs": {
            "bauxite": 4,
            "coal": 1
        },
        "output": "aluminium",
        "seconds": 90.0,
        "yield": 1,
        "depth": 150,
        "tier": 5,
        "number": 41
    },
    "aluminium_plate": {
        "label": "Plaque aluminium",
        "facility": "workshop",
        "inputs": {
            "aluminium": 2
        },
        "output": "aluminium_plate",
        "seconds": 120.0,
        "yield": 1,
        "depth": 150,
        "tier": 5,
        "number": 42
    },
    "refined_sulfur": {
        "label": "Soufre raffiné",
        "facility": "chemistry",
        "inputs": {
            "sulfur": 4
        },
        "output": "refined_sulfur",
        "seconds": 90.0,
        "yield": 1,
        "depth": 150,
        "tier": 5,
        "number": 43
    },
    "electrolyte": {
        "label": "Électrolyte",
        "facility": "chemistry",
        "inputs": {
            "refined_sulfur": 1,
            "graphite": 1,
            "industrial_glass": 1
        },
        "output": "electrolyte",
        "seconds": 240.0,
        "yield": 1,
        "depth": 150,
        "tier": 5,
        "number": 44
    },
    "battery_cell": {
        "label": "Cellule batterie",
        "facility": "electronics",
        "inputs": {
            "aluminium_plate": 1,
            "electrolyte": 1,
            "copper_wire": 2
        },
        "output": "battery_cell",
        "seconds": 300.0,
        "yield": 1,
        "depth": 150,
        "tier": 5,
        "number": 45
    },
    "industrial_battery": {
        "label": "Batterie industrielle",
        "facility": "electronics",
        "inputs": {
            "battery_cell": 4,
            "reinforced_cable": 1,
            "steel_plate": 1
        },
        "output": "industrial_battery",
        "seconds": 600.0,
        "yield": 1,
        "depth": 150,
        "tier": 5,
        "number": 46
    },
    "light_chassis": {
        "label": "Châssis léger",
        "facility": "workshop",
        "inputs": {
            "aluminium_plate": 3,
            "steel_pipes": 2
        },
        "output": "light_chassis",
        "seconds": 480.0,
        "yield": 1,
        "depth": 150,
        "tier": 5,
        "number": 47
    },
    "heat_sink": {
        "label": "Dissipateur thermique",
        "facility": "workshop",
        "inputs": {
            "aluminium_plate": 2,
            "copper_ingot": 1
        },
        "output": "heat_sink",
        "seconds": 300.0,
        "yield": 1,
        "depth": 150,
        "tier": 5,
        "number": 48
    },
    "cooling_module": {
        "label": "Module refroidissement",
        "facility": "machining",
        "inputs": {
            "fan": 1,
            "heat_sink": 2,
            "pump": 1
        },
        "output": "cooling_module",
        "seconds": 900.0,
        "yield": 1,
        "depth": 150,
        "tier": 5,
        "number": 49
    },
    "drill_head_3": {
        "label": "Tête de forage III",
        "facility": "machining",
        "inputs": {
            "drill_head_2": 1,
            "light_chassis": 2,
            "drill_controller_1": 1
        },
        "output": "drill_head_3",
        "seconds": 1200.0,
        "yield": 1,
        "depth": 150,
        "tier": 5,
        "number": 50
    },
    "nickel_ingot": {
        "label": "Lingot de nickel",
        "facility": "furnace",
        "inputs": {
            "nickel": 4,
            "coal": 1
        },
        "output": "nickel_ingot",
        "seconds": 120.0,
        "yield": 1,
        "depth": 240,
        "tier": 6,
        "number": 51
    },
    "stainless_steel": {
        "label": "Acier inoxydable",
        "facility": "furnace",
        "inputs": {
            "steel": 2,
            "nickel_ingot": 1
        },
        "output": "stainless_steel",
        "seconds": 240.0,
        "yield": 1,
        "depth": 240,
        "tier": 6,
        "number": 52
    },
    "stainless_plate": {
        "label": "Plaque inox",
        "facility": "workshop",
        "inputs": {
            "stainless_steel": 2
        },
        "output": "stainless_plate",
        "seconds": 240.0,
        "yield": 1,
        "depth": 240,
        "tier": 6,
        "number": 53
    },
    "precision_bearings": {
        "label": "Roulements précision",
        "facility": "machining",
        "inputs": {
            "stainless_steel": 1,
            "copper_ingot": 1
        },
        "output": "precision_bearings",
        "seconds": 300.0,
        "yield": 2,
        "depth": 240,
        "tier": 6,
        "number": 54
    },
    "electromagnet": {
        "label": "Électroaimant",
        "facility": "electronics",
        "inputs": {
            "copper_coil": 2,
            "nickel_ingot": 1,
            "graphite": 1
        },
        "output": "electromagnet",
        "seconds": 480.0,
        "yield": 1,
        "depth": 240,
        "tier": 6,
        "number": 55
    },
    "industrial_motor": {
        "label": "Moteur industriel",
        "facility": "machining",
        "inputs": {
            "electromagnet": 2,
            "rotor": 1,
            "precision_bearings": 2,
            "drill_controller_1": 1
        },
        "output": "industrial_motor",
        "seconds": 1200.0,
        "yield": 1,
        "depth": 240,
        "tier": 6,
        "number": 56
    },
    "stainless_tubes": {
        "label": "Tubes inox",
        "facility": "machining",
        "inputs": {
            "stainless_plate": 1
        },
        "output": "stainless_tubes",
        "seconds": 240.0,
        "yield": 2,
        "depth": 240,
        "tier": 6,
        "number": 57
    },
    "hydraulic_cylinder": {
        "label": "Vérin hydraulique",
        "facility": "machining",
        "inputs": {
            "stainless_tubes": 2,
            "valves": 1,
            "pressure_unit": 1
        },
        "output": "hydraulic_cylinder",
        "seconds": 900.0,
        "yield": 1,
        "depth": 240,
        "tier": 6,
        "number": 58
    },
    "industrial_actuator": {
        "label": "Actionneur industriel",
        "facility": "machining",
        "inputs": {
            "hydraulic_cylinder": 1,
            "servomotor": 1,
            "control_unit": 1
        },
        "output": "industrial_actuator",
        "seconds": 1200.0,
        "yield": 1,
        "depth": 240,
        "tier": 6,
        "number": 59
    },
    "elevator_drive": {
        "label": "Entraînement d'ascenseur",
        "facility": "machining",
        "inputs": {
            "industrial_motor": 1,
            "industrial_actuator": 1,
            "reinforced_cable": 2
        },
        "output": "elevator_drive",
        "seconds": 1800.0,
        "yield": 1,
        "depth": 240,
        "tier": 6,
        "number": 60
    },
    "tungsten_ingot": {
        "label": "Lingot tungstène",
        "facility": "furnace",
        "inputs": {
            "tungsten": 5,
            "coal": 2
        },
        "output": "tungsten_ingot",
        "seconds": 180.0,
        "yield": 1,
        "depth": 360,
        "tier": 7,
        "number": 61
    },
    "tungsten_carbide": {
        "label": "Carbure de tungstène",
        "facility": "furnace",
        "inputs": {
            "tungsten_ingot": 2,
            "graphite": 1
        },
        "output": "tungsten_carbide",
        "seconds": 360.0,
        "yield": 1,
        "depth": 360,
        "tier": 7,
        "number": 62
    },
    "cobalt_ingot": {
        "label": "Lingot cobalt",
        "facility": "furnace",
        "inputs": {
            "cobalt": 4,
            "coal": 1
        },
        "output": "cobalt_ingot",
        "seconds": 180.0,
        "yield": 1,
        "depth": 360,
        "tier": 7,
        "number": 63
    },
    "superalloy": {
        "label": "Superalliage",
        "facility": "furnace",
        "inputs": {
            "stainless_steel": 2,
            "cobalt_ingot": 1,
            "tungsten_ingot": 1
        },
        "output": "superalloy",
        "seconds": 600.0,
        "yield": 1,
        "depth": 360,
        "tier": 7,
        "number": 64
    },
    "carbide_tooth": {
        "label": "Dent carbure",
        "facility": "machining",
        "inputs": {
            "tungsten_carbide": 1,
            "steel_plate": 1
        },
        "output": "carbide_tooth",
        "seconds": 360.0,
        "yield": 2,
        "depth": 360,
        "tier": 7,
        "number": 65
    },
    "heavy_drill_crown": {
        "label": "Couronne de forage lourd",
        "facility": "machining",
        "inputs": {
            "carbide_tooth": 4,
            "superalloy": 2,
            "drill_head_3": 1
        },
        "output": "heavy_drill_crown",
        "seconds": 1800.0,
        "yield": 1,
        "depth": 360,
        "tier": 7,
        "number": 66
    },
    "high_temperature_coil": {
        "label": "Bobine haute température",
        "facility": "electronics",
        "inputs": {
            "copper_coil": 2,
            "cobalt_ingot": 1,
            "aluminium_plate": 1
        },
        "output": "high_temperature_coil",
        "seconds": 720.0,
        "yield": 1,
        "depth": 360,
        "tier": 7,
        "number": 67
    },
    "heavy_motor": {
        "label": "Moteur lourd",
        "facility": "machining",
        "inputs": {
            "high_temperature_coil": 2,
            "rotor": 1,
            "precision_bearings": 2,
            "drill_controller_1": 1
        },
        "output": "heavy_motor",
        "seconds": 1800.0,
        "yield": 1,
        "depth": 360,
        "tier": 7,
        "number": 68
    },
    "thermal_shield": {
        "label": "Bouclier thermique",
        "facility": "workshop",
        "inputs": {
            "superalloy": 2,
            "heat_sink": 2,
            "graphite": 1
        },
        "output": "thermal_shield",
        "seconds": 1200.0,
        "yield": 1,
        "depth": 360,
        "tier": 7,
        "number": 69
    },
    "deep_drilling_unit": {
        "label": "Groupe de forage profond",
        "facility": "machining",
        "inputs": {
            "heavy_motor": 1,
            "heavy_drill_crown": 1,
            "thermal_shield": 1,
            "cooling_module": 1
        },
        "output": "deep_drilling_unit",
        "seconds": 2700.0,
        "yield": 1,
        "depth": 360,
        "tier": 7,
        "number": 70
    },
    "lithium_concentrate": {
        "label": "Concentré de lithium",
        "facility": "chemistry",
        "inputs": {
            "lithium": 5
        },
        "output": "lithium_concentrate",
        "seconds": 240.0,
        "yield": 1,
        "depth": 500,
        "tier": 8,
        "number": 71
    },
    "lithium_cell": {
        "label": "Cellule lithium",
        "facility": "electronics",
        "inputs": {
            "lithium_concentrate": 1,
            "aluminium_plate": 1,
            "electrolyte": 1
        },
        "output": "lithium_cell",
        "seconds": 480.0,
        "yield": 1,
        "depth": 500,
        "tier": 8,
        "number": 72
    },
    "high_density_battery": {
        "label": "Batterie haute densité",
        "facility": "electronics",
        "inputs": {
            "lithium_cell": 4,
            "drill_controller_1": 1,
            "thermal_shield": 1
        },
        "output": "high_density_battery",
        "seconds": 1500.0,
        "yield": 1,
        "depth": 500,
        "tier": 8,
        "number": 73
    },
    "titanium_ingot": {
        "label": "Lingot titane",
        "facility": "furnace",
        "inputs": {
            "titanium": 5,
            "coal": 2
        },
        "output": "titanium_ingot",
        "seconds": 300.0,
        "yield": 1,
        "depth": 500,
        "tier": 8,
        "number": 74
    },
    "titanium_plate": {
        "label": "Plaque titane",
        "facility": "workshop",
        "inputs": {
            "titanium_ingot": 2
        },
        "output": "titanium_plate",
        "seconds": 360.0,
        "yield": 1,
        "depth": 500,
        "tier": 8,
        "number": 75
    },
    "titanium_chassis": {
        "label": "Châssis titane",
        "facility": "machining",
        "inputs": {
            "titanium_plate": 3,
            "stainless_tubes": 2
        },
        "output": "titanium_chassis",
        "seconds": 1200.0,
        "yield": 1,
        "depth": 500,
        "tier": 8,
        "number": 76
    },
    "precision_servo": {
        "label": "Servo de précision",
        "facility": "machining",
        "inputs": {
            "industrial_actuator": 1,
            "sensor": 1,
            "drill_controller_1": 1
        },
        "output": "precision_servo",
        "seconds": 1500.0,
        "yield": 1,
        "depth": 500,
        "tier": 8,
        "number": 77
    },
    "advanced_circuit": {
        "label": "Circuit avancé",
        "facility": "electronics",
        "inputs": {
            "circuit": 2,
            "crystal_conductor": 1,
            "sensor": 1
        },
        "output": "advanced_circuit",
        "seconds": 1200.0,
        "yield": 1,
        "depth": 500,
        "tier": 8,
        "number": 78
    },
    "navigation_core": {
        "label": "Noyau de navigation",
        "facility": "electronics",
        "inputs": {
            "advanced_circuit": 2,
            "deep_scanner": 1,
            "high_density_battery": 1
        },
        "output": "navigation_core",
        "seconds": 2700.0,
        "yield": 1,
        "depth": 500,
        "tier": 8,
        "number": 79
    },
    "drill_head_4": {
        "label": "Tête de forage IV",
        "facility": "machining",
        "inputs": {
            "heavy_drill_crown": 1,
            "titanium_plate": 2,
            "navigation_core": 1
        },
        "output": "drill_head_4",
        "seconds": 3600.0,
        "yield": 1,
        "depth": 500,
        "tier": 8,
        "number": 80
    },
    "rare_earth_concentrate": {
        "label": "Concentré de terres rares",
        "facility": "chemistry",
        "inputs": {
            "rare_earths": 5
        },
        "output": "rare_earth_concentrate",
        "seconds": 300.0,
        "yield": 1,
        "depth": 700,
        "tier": 9,
        "number": 81
    },
    "permanent_magnet": {
        "label": "Aimant permanent",
        "facility": "electronics",
        "inputs": {
            "rare_earth_concentrate": 1,
            "cobalt_ingot": 1
        },
        "output": "permanent_magnet",
        "seconds": 720.0,
        "yield": 1,
        "depth": 700,
        "tier": 9,
        "number": 82
    },
    "flux_regulator": {
        "label": "Régulateur de flux",
        "facility": "electronics",
        "inputs": {
            "permanent_magnet": 2,
            "crystal_conductor": 1,
            "advanced_circuit": 1
        },
        "output": "flux_regulator",
        "seconds": 1800.0,
        "yield": 1,
        "depth": 700,
        "tier": 9,
        "number": 83
    },
    "resonance_coil": {
        "label": "Bobine de résonance",
        "facility": "crystal_lab",
        "inputs": {
            "high_temperature_coil": 2,
            "cut_crystal": 1,
            "permanent_magnet": 1
        },
        "output": "resonance_coil",
        "seconds": 1800.0,
        "yield": 1,
        "depth": 700,
        "tier": 9,
        "number": 84
    },
    "resonant_sensor": {
        "label": "Capteur résonant",
        "facility": "crystal_lab",
        "inputs": {
            "crystal_lens": 1,
            "resonance_coil": 1,
            "advanced_circuit": 1
        },
        "output": "resonant_sensor",
        "seconds": 2400.0,
        "yield": 1,
        "depth": 700,
        "tier": 9,
        "number": 85
    },
    "logic_core": {
        "label": "Noyau logique",
        "facility": "electronics",
        "inputs": {
            "advanced_circuit": 3,
            "resonant_sensor": 2,
            "high_density_battery": 1
        },
        "output": "logic_core",
        "seconds": 3600.0,
        "yield": 1,
        "depth": 700,
        "tier": 9,
        "number": 86
    },
    "vector_motor": {
        "label": "Moteur vectoriel",
        "facility": "machining",
        "inputs": {
            "permanent_magnet": 2,
            "heavy_motor": 1,
            "logic_core": 1
        },
        "output": "vector_motor",
        "seconds": 4500.0,
        "yield": 1,
        "depth": 700,
        "tier": 9,
        "number": 87
    },
    "active_cooling": {
        "label": "Refroidissement actif",
        "facility": "machining",
        "inputs": {
            "cooling_module": 1,
            "high_density_battery": 1,
            "logic_core": 1,
            "heat_sink": 2
        },
        "output": "active_cooling",
        "seconds": 3600.0,
        "yield": 1,
        "depth": 700,
        "tier": 9,
        "number": 88
    },
    "autonomous_drill_module": {
        "label": "Module de forage autonome",
        "facility": "machining",
        "inputs": {
            "vector_motor": 1,
            "drill_head_4": 1,
            "logic_core": 1,
            "active_cooling": 1
        },
        "output": "autonomous_drill_module",
        "seconds": 7200.0,
        "yield": 1,
        "depth": 700,
        "tier": 9,
        "number": 89
    },
    "deep_command_core": {
        "label": "Noyau de commande profond",
        "facility": "electronics",
        "inputs": {
            "logic_core": 2,
            "navigation_core": 1,
            "resonant_sensor": 1,
            "high_density_battery": 1
        },
        "output": "deep_command_core",
        "seconds": 7200.0,
        "yield": 1,
        "depth": 700,
        "tier": 9,
        "number": 90
    },
    "ancient_alloy": {
        "label": "Alliage ancien",
        "facility": "crystal_lab",
        "inputs": {
            "ancient_fragment": 3,
            "titanium_ingot": 1,
            "cobalt_ingot": 1
        },
        "output": "ancient_alloy",
        "seconds": 1800.0,
        "yield": 1,
        "depth": 1000,
        "tier": 10,
        "number": 91
    },
    "resonant_crystal": {
        "label": "Cristal résonant",
        "facility": "crystal_lab",
        "inputs": {
            "crystal": 3,
            "rare_earth_concentrate": 1,
            "ancient_fragment": 1
        },
        "output": "resonant_crystal",
        "seconds": 2700.0,
        "yield": 1,
        "depth": 1000,
        "tier": 10,
        "number": 92
    },
    "resonance_matrix": {
        "label": "Matrice de résonance",
        "facility": "crystal_lab",
        "inputs": {
            "resonant_crystal": 2,
            "advanced_circuit": 2,
            "permanent_magnet": 1
        },
        "output": "resonance_matrix",
        "seconds": 3600.0,
        "yield": 1,
        "depth": 1000,
        "tier": 10,
        "number": 93
    },
    "ancient_conductor": {
        "label": "Conducteur ancien",
        "facility": "crystal_lab",
        "inputs": {
            "ancient_alloy": 1,
            "crystal_conductor": 1,
            "copper_wire": 2
        },
        "output": "ancient_conductor",
        "seconds": 3600.0,
        "yield": 1,
        "depth": 1000,
        "tier": 10,
        "number": 94
    },
    "stabilization_core": {
        "label": "Noyau de stabilisation",
        "facility": "electronics",
        "inputs": {
            "resonance_matrix": 1,
            "ancient_conductor": 2,
            "high_density_battery": 1
        },
        "output": "stabilization_core",
        "seconds": 7200.0,
        "yield": 1,
        "depth": 1000,
        "tier": 10,
        "number": 95
    },
    "inertial_compensator": {
        "label": "Compensateur inertiel",
        "facility": "machining",
        "inputs": {
            "stabilization_core": 1,
            "titanium_chassis": 2,
            "vector_motor": 1
        },
        "output": "inertial_compensator",
        "seconds": 10800.0,
        "yield": 1,
        "depth": 1000,
        "tier": 10,
        "number": 96
    },
    "deep_reactor": {
        "label": "Réacteur profond",
        "facility": "crystal_lab",
        "inputs": {
            "stabilization_core": 2,
            "resonance_matrix": 2,
            "active_cooling": 1
        },
        "output": "deep_reactor",
        "seconds": 14400.0,
        "yield": 1,
        "depth": 1000,
        "tier": 10,
        "number": 97
    },
    "drilling_core_5": {
        "label": "Cœur de forage V",
        "facility": "machining",
        "inputs": {
            "drill_head_4": 1,
            "carbide_tooth": 4,
            "ancient_alloy": 2,
            "deep_reactor": 1
        },
        "output": "drilling_core_5",
        "seconds": 21600.0,
        "yield": 1,
        "depth": 1000,
        "tier": 10,
        "number": 98
    },
    "autonomous_excavator": {
        "label": "Excavateur autonome",
        "facility": "machining",
        "inputs": {
            "drilling_core_5": 1,
            "vector_motor": 1,
            "deep_command_core": 1,
            "inertial_compensator": 1
        },
        "output": "autonomous_excavator",
        "seconds": 28800.0,
        "yield": 1,
        "depth": 1000,
        "tier": 10,
        "number": 99
    },
    "abyssal_core": {
        "label": "Cœur abyssal",
        "facility": "crystal_lab",
        "inputs": {
            "deep_reactor": 2,
            "resonance_matrix": 2,
            "ancient_alloy": 2,
            "deep_command_core": 1
        },
        "output": "abyssal_core",
        "seconds": 43200.0,
        "yield": 1,
        "depth": 1000,
        "tier": 10,
        "number": 100
    }
}
