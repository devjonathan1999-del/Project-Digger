extends SceneTree

const TEST_SUITES := [
    preload("res://tests/test_material_catalog.gd"),
    preload("res://tests/test_terrain_model.gd"),
    preload("res://tests/test_terrain_actions.gd"),
    preload("res://tests/test_stability_system.gd"),
    preload("res://tests/test_ancient_network.gd"),
    preload("res://tests/test_simulation_controller.gd"),
    preload("res://tests/test_save_system.gd"),
    preload("res://tests/test_terrain_visual_profile.gd"),
    preload("res://tests/test_ui_contract.gd"),
    preload("res://tests/test_scene_contract.gd"),
    preload("res://tests/test_feedback_classifier.gd"),
    preload("res://tests/test_vertical_slice_acceptance.gd"),
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
    quit(_exit_code)
