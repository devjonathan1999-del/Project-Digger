extends SceneTree

const Presenter = preload("res://src/industry/ui/mine_interaction_presenter.gd")
const Renderer = preload("res://src/industry/ui/mine_asset_renderer.gd")

class FakeWorld:
    extends Control
    signal selection_changed(kind: String, id: String)
    var session = null
    var scroll_depth: float = 0.0
    var zoom: float = 1.0
    var animation_phase: float = 0.0

func _init() -> void:
    var failures := 0
    var world := FakeWorld.new()
    world.name = "FakeMineWorld"
    world.size = Vector2(1280, 800)
    get_root().add_child(world)

    var renderer := Renderer.new()
    world.add_child(renderer)
    # This SceneTree test runs before the normal first-frame ready pass.
    # Run the visual-only initialization explicitly so input ownership is measurable.
    renderer._ready()

    var iron := Button.new()
    iron.name = "Mine_iron"
    iron.text = "Mine de fer"
    iron.position = Vector2(70, 180)
    iron.size = Vector2(90, 24)
    world.add_child(iron)

    var presenter := Presenter.new()
    world.add_child(presenter)
    presenter._ready()
    presenter.bind(world)

    if presenter._module_renderer != renderer:
        push_error("v0.7 presenter must reuse the existing MineAssetRenderer")
        failures += 1
    if renderer.mouse_filter != Control.MOUSE_FILTER_IGNORE:
        push_error("v0.7 renderer must never capture pointer input")
        failures += 1
    if iron.size.y < 44.0 or iron.custom_minimum_size.y < 44.0:
        push_error("resource hit targets must retain at least 44 px touch height")
        failures += 1

    world.size = Vector2(720, 1000)
    presenter._sync()
    presenter._ensure_module_renderer()
    if iron.size.y < 44.0:
        push_error("narrow layout must preserve 44 px resource hit targets")
        failures += 1
    if presenter._module_renderer != renderer:
        push_error("narrow sync must keep the same v0.7 visual renderer")
        failures += 1

    world.free()
    quit(1 if failures > 0 else 0)
