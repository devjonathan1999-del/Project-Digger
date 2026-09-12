extends SceneTree

const Support = preload("res://tests/test_support.gd")
const Renderer = preload("res://src/industry/ui/mine_module_renderer.gd")

var t = Support.new()

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(1280, 800)
    var renderer := Renderer.new()
    root.add_child(renderer)
    renderer.size = Vector2(1280, 800)

    var shallow_state := _state_for(30, 2, 10.0)
    var shallow_before := shallow_state.duplicate(true)
    renderer.set_scene_state(shallow_state)
    await process_frame
    var shallow: Dictionary = renderer.metrics()
    t.check(int(shallow.get("rock_mass_score", 0)) >= 6, "masse rocheuse déjà présente en surface")
    var shallow_rock := int(shallow.get("rock_mass_score", 0))
    var shallow_cyan := float(shallow.get("deep_cyan_strength", 0.0))
    t.equal(shallow_state, shallow_before, "renderer ne mute pas l'état peu profond")

    var deep_state := _state_for(150, 6, 115.0)
    var deep_before := deep_state.duplicate(true)
    renderer.set_scene_state(deep_state)
    await process_frame
    var deep: Dictionary = renderer.metrics()
    t.check(int(deep.get("rock_mass_score", 0)) > shallow_rock, "masse rocheuse plus riche en profondeur")
    t.check(int(deep.get("large_cavity_count", 0)) >= 2, "grandes cavités profondes")
    t.check(int(deep.get("light_pool_count", 0)) >= 4, "bassins de lumière locaux")
    t.check(int(deep.get("atmosphere_effect_count", 0)) >= 4, "atmosphère industrielle visible")
    t.check(float(deep.get("deep_cyan_strength", 0.0)) > shallow_cyan, "cyan renforcé avec la profondeur")
    t.equal(deep_state, deep_before, "renderer ne mute pas l'état profond")

    renderer.queue_free()
    await process_frame
    print("Visual v0.6 geology: %s" % ("PASS" if t.failures == 0 else "FAIL"))
    quit(t.finish())

func _state_for(depth: int, center_level: int, scroll_depth: float) -> Dictionary:
    return {
        "depth": depth,
        "center_level": center_level,
        "animation_phase": 1.25,
        "viewport_size": Vector2(1280, 800),
        "scroll_depth": scroll_depth,
        "zoom": 1.0,
        "mine_levels": {},
        "discoveries": {},
        "permanent_sites": {},
        "jobs": {},
    }
