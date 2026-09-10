class_name FeedbackClassifier
extends RefCounted

enum { NONE, LIGHT, HEAVY }

static func classify_movements(movements: Array[Dictionary]) -> int:
    if movements.is_empty():
        return NONE
    for movement in movements:
        if StringName(movement.get("material_id", &"")) == &"rock_dense":
            return HEAVY
    return LIGHT
