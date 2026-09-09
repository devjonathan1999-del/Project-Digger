extends RefCounted

func run(t: TestSupport) -> void:
    test_allowed_transitions_and_cancel(t)
    test_resolution_cycle(t)

func _cell(id: StringName) -> TerrainCell:
    return preload("res://src/terrain/terrain_cell.gd").new(id)

func test_allowed_transitions_and_cancel(t: TestSupport) -> void:
    var model := preload("res://src/terrain/terrain_model.gd").new(4, 4)
    model.set_cell(Vector2i(1, 1), _cell(&"rock_common"))
    var controller := preload("res://src/simulation/simulation_controller.gd").new(model, Vector2i(0, 3), Vector2i(3, 3), 5)
    var transitions: Array[int] = []
    controller.state_changed.connect(func(value: int) -> void: transitions.append(value))

    t.equal(controller.state, SimulationController.OBSERVER, "état initial Observer")
    t.equal(controller.trigger_resolution(), false, "résolution refusée hors Préparer")
    t.equal(controller.enter_prepare(), true, "entrée en Préparer")
    t.equal(controller.state, SimulationController.PREPARE, "état Préparer")
    controller.terrain_actions.dig(Vector2i(1, 1))
    t.equal(controller.cancel_prepare(), true, "annulation Préparer")
    t.equal(controller.state, SimulationController.OBSERVER, "retour Observer après annulation")
    t.check(model.get_cell(Vector2i(1, 1)) != null, "annulation restaure le terrain")
    t.equal(transitions, [SimulationController.PREPARE, SimulationController.OBSERVER], "transitions annulation")

func test_resolution_cycle(t: TestSupport) -> void:
    var model := preload("res://src/terrain/terrain_model.gd").new(4, 5)
    model.set_cell(Vector2i(2, 0), _cell(&"rock_common"))
    var controller := preload("res://src/simulation/simulation_controller.gd").new(model, Vector2i(0, 4), Vector2i(3, 4), 5)
    var transitions: Array[int] = []
    var resolved_moves: Array = []
    controller.state_changed.connect(func(value: int) -> void: transitions.append(value))
    controller.resolution_finished.connect(func(movements: Array[Dictionary]) -> void: resolved_moves.assign(movements))

    controller.enter_prepare()
    t.equal(controller.trigger_resolution(), true, "Déclencher lance la résolution")
    t.equal(controller.state, SimulationController.OBSERVER, "retour Observer après résolution")
    t.equal(transitions, [SimulationController.PREPARE, SimulationController.RESOLVING, SimulationController.OBSERVER], "cycle complet des états")
    t.check(not resolved_moves.is_empty(), "résolution publie les mouvements")
    t.check(model.get_cell(Vector2i(2, 4)) != null, "effondrement appliqué au modèle")
