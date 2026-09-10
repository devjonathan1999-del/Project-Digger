class_name MaterialCatalog
extends RefCounted

var _materials: Dictionary = {}

func _init() -> void:
    _materials[&"rock_common"] = MaterialDef.new(&"rock_common", true, 1.0, 2.0, 0.0, false)
    _materials[&"rock_fragile"] = MaterialDef.new(&"rock_fragile", true, 0.8, 0.8, 0.0, false)
    _materials[&"rock_dense"] = MaterialDef.new(&"rock_dense", false, 2.0, 5.0, 0.0, false)
    _materials[&"stabilizer"] = MaterialDef.new(&"stabilizer", true, 1.0, 1.5, 3.0, true)

func get_def(id: StringName) -> MaterialDef:
    return _materials.get(id)
