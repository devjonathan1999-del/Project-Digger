extends RefCounted

func run(t: TestSupport) -> void:
    var input := GameInput.new()
    var hud := DiggerHUD.new()

    t.equal(input.has_signal("hover_changed"), true, "GameInput expose hover_changed")
    t.equal(hud.has_signal("tool_pressed"), true, "HUD expose tool_pressed")
    t.equal(hud.has_method("set_context"), true, "HUD expose set_context")
    t.equal(hud.has_method("clear_context"), true, "HUD expose clear_context")
    t.equal(hud.has_method("set_busy"), true, "HUD expose set_busy")

    input.free()
    hud.free()
