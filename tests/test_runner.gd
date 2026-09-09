extends SceneTree

const TEST_SUITES := [
    preload("res://tests/test_material_catalog.gd"),
    preload("res://tests/test_terrain_model.gd"),
    preload("res://tests/test_terrain_actions.gd"),
    preload("res://tests/test_stability_system.gd"),
    preload("res://tests/test_ancient_network.gd"),
]

func _initialize() -> void:
    var support = preload("res://tests/test_support.gd").new()
    support.check(ProjectSettings.has_setting("application/config/name"), "project.godot chargé")
    for suite_script in TEST_SUITES:
        suite_script.new().run(support)
    quit(support.finish())
