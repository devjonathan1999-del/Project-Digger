extends SceneTree

const TEST_SUITES := [
    preload("res://tests/test_material_catalog.gd"),
    preload("res://tests/test_terrain_model.gd"),
    preload("res://tests/test_terrain_actions.gd"),
    preload("res://tests/test_stability_system.gd"),
    preload("res://tests/test_ancient_network.gd"),
    preload("res://tests/test_simulation_controller.gd"),
    preload("res://tests/test_save_system.gd"),
    preload("res://tests/test_vertical_slice_acceptance.gd"),
    preload("res://tests/test_industry_game.gd"),
    preload("res://tests/test_industry_save.gd"),
    preload("res://tests/test_industry_session.gd"),
    preload("res://tests/test_industry_acceptance.gd"),
    preload("res://tests/test_industry_discovery.gd"),
    preload("res://tests/test_industry_schema_v2.gd"),
    preload("res://tests/test_progression_milestones.gd"),
    preload("res://tests/test_progression_operations.gd"),
    preload("res://tests/test_progression_technology.gd"),
]

var _exit_code := 1

func _initialize() -> void:
    var support = preload("res://tests/test_support.gd").new()
    support.check(ProjectSettings.has_setting("application/config/name"), "project.godot chargé")
    for suite_script in TEST_SUITES:
        var suite = suite_script.new()
        suite.run(support)
        suite = null
    _exit_code = support.finish()
    support = null
    call_deferred("_finish_and_quit")

func _finish_and_quit() -> void:
    # Leave _initialize() first so temporary GDScript references are released
    # before SceneTree shutdown checks ObjectDB/resource ownership.
    quit(_exit_code)
