extends SceneTree

const Support = preload("res://tests/test_support.gd")
const PATH := "user://tests/visual_v05_world.json"

var t = Support.new()

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(1280, 800)
    DirAccess.make_dir_recursive_absolute("user://tests")
    _cleanup()

    var screen = load("res://scenes/industry.tscn").instantiate()
    var session = screen.get_node("IndustrySession")
    session.save_path = PATH
    root.add_child(screen)
    session.set_process(false)
    await process_frame
    await process_frame

    session.game.depth = 150
    session.game.center_level = 6
    session.changed.emit()
    await process_frame
    await process_frame

    var renderer = screen.find_child("MineSceneRenderer", true, false)
    t.check(renderer != null, "renderer v0.5 présent")
    if renderer != null:
        var variants = renderer.get("gallery_variants_seen")
        var silhouettes = renderer.get("gallery_silhouette_count")
        var broken = renderer.get("broken_rail_count")
        var alcoves = renderer.get("alcove_count")
        t.check(variants is Dictionary and variants.size() >= 4, "au moins quatre variantes visibles/connues")
        t.check(silhouettes is int and silhouettes >= 8, "silhouettes gauche/droite générées")
        t.check(broken is int and broken >= 1, "au moins une rupture de rails")
        t.check(alcoves is int and alcoves >= 1, "au moins un renfoncement")

        var shaft_platforms = renderer.get("shaft_platform_count")
        var shaft_utilities = renderer.get("shaft_utility_count")
        var surface_features = renderer.get("surface_feature_count")
        var ventilation = renderer.get("ventilation_visible")
        t.check(shaft_platforms is int and shaft_platforms >= 5, "plateformes de puits aux horizons")
        t.check(shaft_utilities is int and shaft_utilities >= 3, "câbles/conduites/contrepoids visibles")
        t.check(surface_features is int and surface_features >= 7, "base de surface fonctionnellement riche")
        t.equal(ventilation, true, "ventilation identifiable")

        var deep_surface_count := int(surface_features) if surface_features is int else 0
        renderer.set_scene_state(_state_for(150, 1))
        var shallow_surface = renderer.get("surface_feature_count")
        t.check(shallow_surface is int and shallow_surface < deep_surface_count, "surface plus riche avec le niveau du Centre")

        renderer.set_scene_state(_state_for(30, 2))
        var shallow_cyan = renderer.get("deep_cyan_strength")
        var shallow_details = renderer.get("geology_detail_count")
        renderer.set_scene_state(_state_for(150, 6))
        var deep_cyan = renderer.get("deep_cyan_strength")
        var deep_details = renderer.get("geology_detail_count")
        var fractures = renderer.get("visible_fracture_count")
        var cavities = renderer.get("visible_cavity_count")
        t.check(shallow_cyan is float and deep_cyan is float and deep_cyan > shallow_cyan, "cyan renforcé en profondeur")
        t.check(shallow_details is int and deep_details is int and deep_details > shallow_details, "géologie plus riche en profondeur")
        t.check(fractures is int and fractures >= 4, "fissures visibles")
        t.check(cavities is int and cavities >= 2, "petites cavités visibles")

    var world = screen.find_child("MineWorld", true, false)
    t.check(world != null, "monde mine disponible")
    if world != null:
        for target_name in ["Mine_iron", "Mine_coal", "Mine_copper", "Drill"]:
            t.check(world.find_child(target_name, true, false) != null, "zone tactile %s conservée" % target_name)

    screen.queue_free()
    await process_frame
    _cleanup()
    print("Visual v0.5 world: %s" % ("PASS" if t.failures == 0 else "FAIL"))
    quit(t.finish())

func _state_for(depth: int, center_level: int) -> Dictionary:
    return {
        "depth": depth,
        "center_level": center_level,
        "mine_levels": {},
        "discoveries": {},
        "permanent_sites": {},
        "jobs": {},
        "scroll_depth": maxf(0.0, float(depth) - 45.0),
        "zoom": 1.0,
        "animation_phase": 0.0,
    }

func _cleanup() -> void:
    if FileAccess.file_exists(PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
    if FileAccess.file_exists(PATH + ".tmp") or DirAccess.dir_exists_absolute(PATH + ".tmp"):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + ".tmp"))
