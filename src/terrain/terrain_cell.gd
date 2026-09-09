class_name TerrainCell
extends RefCounted

var material_id: StringName
var stability_modifier: float = 0.0

func _init(p_material_id: StringName = &"", p_stability_modifier: float = 0.0) -> void:
    material_id = p_material_id
    stability_modifier = p_stability_modifier
