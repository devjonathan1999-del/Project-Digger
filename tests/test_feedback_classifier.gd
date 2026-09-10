extends RefCounted

const CLASSIFIER_PATH := "res://src/feedback/feedback_classifier.gd"

func run(t: TestSupport) -> void:
    var exists := ResourceLoader.exists(CLASSIFIER_PATH)
    t.equal(exists, true, "classificateur de feedback disponible")
    if not exists:
        return

    var classifier_script = load(CLASSIFIER_PATH)
    var classifier = classifier_script.new()

    var none: Array[Dictionary] = []
    t.equal(classifier.call("classify_movements", none), 0, "aucun mouvement = aucun impact")

    var light: Array[Dictionary] = [
        {"from": Vector2i(1, 1), "to": Vector2i(1, 2), "material_id": &"rock_common"},
    ]
    t.equal(classifier.call("classify_movements", light), 1, "petit effondrement = impact léger")

    var heavy: Array[Dictionary] = [
        {"from": Vector2i(2, 2), "to": Vector2i(2, 3), "material_id": &"rock_dense"},
    ]
    t.equal(classifier.call("classify_movements", heavy), 2, "roche dense = impact lourd")
