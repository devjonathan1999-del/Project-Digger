extends RefCounted

func run(t: TestSupport) -> void:
    var input := GameInput.new()
    var hud := DiggerHUD.new()
    var renderer := TerrainRenderer.new()

    t.equal(input.has_signal("hover_changed"), true, "GameInput expose hover_changed")
    t.equal(hud.has_signal("tool_pressed"), true, "HUD expose tool_pressed")
    t.equal(hud.has_method("set_context"), true, "HUD expose set_context")
    t.equal(hud.has_method("clear_context"), true, "HUD expose clear_context")
    t.equal(hud.has_method("set_busy"), true, "HUD expose set_busy")
    t.equal(renderer.has_method("analysis_visible_for"), true, "renderer expose analyse locale")

    if renderer.has_method("analysis_visible_for"):
        renderer.set_prepare_mode(true)
        renderer.set_hovered_cell(Vector2i(10, 10))
        t.equal(renderer.call("analysis_visible_for", Vector2i(10, 10)), true, "analyse visible sous le curseur")
        t.equal(renderer.call("analysis_visible_for", Vector2i(13, 11)), true, "analyse visible près du curseur")
        t.equal(renderer.call("analysis_visible_for", Vector2i(20, 20)), false, "analyse masquée loin du curseur")
        renderer.clear_hovered_cell()
        t.equal(renderer.call("analysis_visible_for", Vector2i(10, 10)), false, "analyse masquée sans focus")

    input.free()
    hud.free()
    renderer.free()
