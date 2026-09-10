class_name MaterialDef
extends RefCounted

var id: StringName
var diggable: bool
var mass: float
var strength: float
var stability_bonus: float
var conductive: bool

func _init(
    p_id: StringName = &"",
    p_diggable: bool = false,
    p_mass: float = 0.0,
    p_strength: float = 0.0,
    p_stability_bonus: float = 0.0,
    p_conductive: bool = false
) -> void:
    id = p_id
    diggable = p_diggable
    mass = p_mass
    strength = p_strength
    stability_bonus = p_stability_bonus
    conductive = p_conductive
