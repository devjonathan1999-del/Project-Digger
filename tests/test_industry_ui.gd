extends SceneTree

const Support = preload("res://tests/test_support.gd")
const Save = preload("res://src/industry/industry_save.gd")
const Game = preload("res://src/industry/industry_game.gd")
const PATH := "user://tests/industry_ui.json"
var t = Support.new()

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    t.check(ResourceLoader.exists("res://scenes/industry.tscn"), "la scène de gestion jouable existe")
    if not ResourceLoader.exists("res://scenes/industry.tscn"):
        quit(t.finish())
        return
    root.size = Vector2i(1280, 800)
    var main = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
    var screen = main.get_node_or_null("Industry")
    t.check(screen != null, "le lancement ouvre la gestion industrielle")
    if screen == null:
        main.free()
        quit(t.finish())
        return
    DirAccess.make_dir_recursive_absolute("user://tests")
    Save.new().save_game(PATH, Game.new(), Time.get_unix_time_from_system() - 10.0)
    var session = screen.get_node("IndustrySession")
    session.save_path = PATH
    root.add_child(main)
    session.set_process(false)
    await process_frame
    await process_frame
    t.check(screen.find_child("OfflineNotice", true, false).visible, "bilan de retour affiché après dix secondes")
    var quantity = screen.find_child("FurnaceQuantity", true, false)
    quantity.value = 3
    var start = screen.find_child("FurnaceStart", true, false)
    await _click(start)
    t.check(session.game.jobs.has("furnace"), "le vrai bouton démarre la fonderie")
    t.check(start.disabled, "bouton fonderie désactivé pendant la fonte")
    session.advance_to(session.last_seen_unix + 30.0)
    t.check(screen.find_child("FurnaceProgress", true, false).value >= 50.0, "la jauge suit le temps du modèle")
    session.advance_to(session.last_seen_unix + 31.0)
    t.equal(screen.find_child("Stock_iron_ingot", true, false).text, "3", "le stock reflète les lingots terminés")
    var recipe = screen.find_child("FurnaceRecipe", true, false)
    recipe.select(1)
    recipe.item_selected.emit(1)
    quantity.value = 2
    await _click(start)
    session.advance_to(session.last_seen_unix + 51.0)
    await _click(screen.find_child("WorkshopStart", true, false))
    session.advance_to(session.last_seen_unix + 41.0)
    await _click(screen.find_child("DrillUpgrade", true, false))
    t.equal(session.game.drill_level, 2, "le bouton améliore la foreuse après fabrication")
    await _click(screen.find_child("ExcavationStart", true, false))
    session.advance_to(session.last_seen_unix + 16.0)
    t.equal(session.game.depth, 10, "le bouton chantier permet de gagner dix mètres")
    t.check(session.persist(), "parcours UI enregistré")
    t.equal(Save.new().load_game(PATH, session.last_seen_unix)["game"].depth, 10, "parcours UI rechargé")
    await _click(screen.find_child("MineUpgrade_iron", true, false))
    t.equal(session.game.mine_levels["iron"], 2, "le bouton mine améliore le débit")
    t.equal(recipe.selected, 1, "la mise à jour conserve la recette sélectionnée")
    t.equal(int(quantity.value), 2, "la mise à jour conserve la quantité")
    session.save_error = "Impossible d'écrire la sauvegarde industrielle"
    session.notice_changed.emit()
    t.check(screen.find_child("SaveNotice", true, false).visible, "erreur de sauvegarde visible")
    session.save_error = ""
    session.notice_changed.emit()
    await _dimensions(screen, Vector2i(1280, 800), false)
    await _dimensions(screen, Vector2i(720, 1000), true)
    var args := OS.get_cmdline_user_args()
    if "--screenshots" in args:
        var folder: String = args[args.find("--screenshots") + 1]
        DirAccess.make_dir_recursive_absolute(folder)
        await _capture(screen, Vector2i(1280, 800), folder.path_join("industry-wide.png"))
        await _capture(screen, Vector2i(720, 1000), folder.path_join("industry-narrow.png"))
        await _capture(screen, Vector2i(720, 1000), folder.path_join("industry-narrow-workshops.png"), true)
    main.queue_free()
    await process_frame
    DirAccess.remove_absolute(PATH)
    print("Industry UI: %s" % ("PASS" if t.failures == 0 else "FAIL"))
    quit(t.finish())

func _click(button: Button) -> void:
    var scroll = button.find_parent("PageScroll") as ScrollContainer
    if scroll != null:
        scroll.ensure_control_visible(button)
    await process_frame
    await process_frame
    t.check(not button.disabled, "%s disponible avant clic" % button.name)
    var at := button.get_global_rect().get_center()
    var press := InputEventMouseButton.new()
    press.button_index = MOUSE_BUTTON_LEFT
    press.position = at
    press.pressed = true
    root.push_input(press)
    var release := InputEventMouseButton.new()
    release.button_index = MOUSE_BUTTON_LEFT
    release.position = at
    release.pressed = false
    root.push_input(release)
    await process_frame

func _dimensions(screen, dimensions: Vector2i, stacked: bool) -> void:
    root.size = dimensions
    await process_frame
    await process_frame
    await process_frame
    t.equal(screen.find_child("ManagementColumns", true, false).vertical, stacked, "empilement adapté à %s" % dimensions)
    var scroll = screen.find_child("PageScroll", true, false)
    t.check(scroll.get_h_scroll_bar().max_value <= dimensions.x + 1, "aucun débordement horizontal à %s" % dimensions)

func _capture(screen, dimensions: Vector2i, path: String, bottom: bool = false) -> void:
    root.size = dimensions
    screen.find_child("PageScroll", true, false).scroll_vertical = 0
    await process_frame
    await process_frame
    if bottom:
        screen.find_child("PageScroll", true, false).scroll_vertical = 100000
        await process_frame
    await RenderingServer.frame_post_draw
    var picture := root.get_texture().get_image()
    t.check(not picture.is_empty(), "capture graphique non vide")
    t.equal(picture.save_png(path), OK, "capture enregistrée")
