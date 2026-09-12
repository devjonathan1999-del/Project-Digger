extends SceneTree

const Support = preload("res://tests/test_support.gd")
const Save = preload("res://src/industry/industry_save.gd")
const Game = preload("res://src/industry/industry_game.gd")
const Discovery = preload("res://src/industry/industry_discovery.gd")
const PATH := "user://tests/industry_ui.json"
const INVALID_PATH := "user://tests/industry_ui_invalid.json"

var t = Support.new()

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    t.check(ResourceLoader.exists("res://scenes/industry.tscn"), "la scène de gestion jouable existe")
    if not ResourceLoader.exists("res://scenes/industry.tscn"):
        quit(t.finish())
        return

    # This legacy test drives raw window coordinates at multiple artificial sizes.
    # Disable project content scaling here so its historical click/layout assertions
    # continue to measure those requested dimensions directly.
    root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
    root.size = Vector2i(1280, 800)
    DirAccess.make_dir_recursive_absolute("user://tests")
    _cleanup()

    var main = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
    var screen = main.get_node_or_null("Industry")
    t.check(screen != null, "le lancement ouvre la gestion industrielle")
    if screen == null:
        main.free()
        quit(t.finish())
        return

    Save.new().save_game(PATH, Game.new(), Time.get_unix_time_from_system() - 10.0)
    var session = screen.get_node("IndustrySession")
    session.save_path = PATH
    root.add_child(main)
    session.set_process(false)
    await process_frame
    await process_frame

    var tab_mine = screen.find_child("TabMine", true, false)
    var tab_industry = screen.find_child("TabIndustrie", true, false)
    var tab_center = screen.find_child("TabCentre", true, false)
    var tab_technology = screen.find_child("TabTechnologie", true, false)
    t.check(tab_mine != null, "onglet Mine présent")
    t.check(tab_industry != null, "onglet Industrie présent")
    t.check(tab_center != null, "onglet Centre présent")
    t.check(tab_technology != null, "onglet Technologie présent")

    var mine_panel = screen.find_child("MinePanel", true, false)
    var industry_panel = screen.find_child("IndustryPanel", true, false)
    var center_panel = screen.find_child("CenterPanel", true, false)
    var technology_panel = screen.find_child("TechnologyPanel", true, false)
    t.check(mine_panel != null and mine_panel.visible, "Mine sélectionnée au démarrage")
    t.check(industry_panel != null and not industry_panel.visible, "Industrie masquée au démarrage")
    t.check(center_panel != null and not center_panel.visible, "Centre masqué au démarrage")
    t.check(technology_panel != null and not technology_panel.visible, "Technologie masquée au démarrage")

    var mine_world = screen.find_child("MineWorld", true, false)
    t.check(mine_world != null, "vue mine verticale présente")
    if mine_world != null:
        t.check(float(mine_world.get("min_zoom")) >= 0.7, "zoom minimum borné")
        t.check(float(mine_world.get("max_zoom")) <= 1.25, "zoom maximum borné")

    session.game.discoveries["30:0"] = Discovery.generate(123, 30, 0, 0.0)
    session.changed.emit()
    await process_frame
    var discovery_target = screen.find_child("Discovery_30_0", true, false)
    t.check(discovery_target != null, "cible de découverte présente dans le monde")
    if discovery_target != null:
        await _click(discovery_target)
    var context_panel = screen.find_child("ContextPanel", true, false)
    t.check(context_panel != null and context_panel.visible, "clic découverte ouvre le panneau contextuel")

    await _click(tab_industry)
    t.check(industry_panel.visible, "clic Industrie affiche le panneau industriel")
    t.check(screen.find_child("FurnaceStart", true, false) != null, "fonderie conservée dans Industrie")
    t.check(screen.find_child("WorkshopStart", true, false) != null, "atelier conservé dans Industrie")
    t.check(screen.find_child("MineUpgrade_iron", true, false) != null, "amélioration de mine conservée dans Industrie")
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

    await _click(tab_mine)
    mine_world.focus_depth(session.game.depth)
    await process_frame
    await _click(screen.find_child("Drill", true, false))
    var secondary = screen.find_child("ContextSecondary", true, false)
    t.check(secondary != null and secondary.visible and secondary.disabled, "amélioration foreuse verrouillée avant 30 m")
    t.equal(session.game.drill_level, 1, "la fabrication initiale ne débloque pas prématurément la tête I")
    var primary = screen.find_child("ContextPrimary", true, false)
    t.check(primary != null and primary.visible, "forage disponible dans le contexte")
    await _click(primary)
    session.advance_to(session.last_seen_unix + 31.0)
    t.equal(session.game.depth, 10, "le contexte permet de gagner dix mètres")
    t.check(session.persist(), "parcours UI enregistré")
    t.equal(Save.new().load_game(PATH, session.last_seen_unix)["game"].depth, 10, "parcours UI rechargé")

    await _click(tab_industry)
    await _click(screen.find_child("MineUpgrade_iron", true, false))
    t.equal(session.game.mine_levels["iron"], 2, "le bouton mine améliore le débit")
    t.equal(recipe.selected, 1, "la mise à jour conserve la recette sélectionnée")
    t.equal(int(quantity.value), 2, "la mise à jour conserve la quantité")
    t.check(_page_text(screen).contains("Progression enregistrée automatiquement"), "confirmation de sauvegarde en état normal")

    session.save_path = PATH.path_join("retry.json")
    t.check(not session.persist(), "échec réel d'écriture pour tester la notice temporaire")
    t.check(not session.save_blocked, "échec temporaire distinct d'un chargement invalide")
    t.check(screen.find_child("SaveNotice", true, false).visible, "erreur de sauvegarde visible")
    t.check(_page_text(screen).contains("nouvelle tentative") or _page_text(screen).contains("Nouvelle tentative"), "échec temporaire indique une nouvelle tentative")
    session.save_path = PATH
    t.check(session.persist(), "une nouvelle tentative réelle rétablit la sauvegarde")
    t.check(not screen.find_child("SaveNotice", true, false).visible, "la notice disparaît après sauvegarde réussie")

    await _dimensions(screen, Vector2i(1280, 800), false)
    await _dimensions(screen, Vector2i(720, 1000), true)

    var args := OS.get_cmdline_user_args()
    var folder := ""
    if "--screenshots" in args:
        folder = args[args.find("--screenshots") + 1]
        DirAccess.make_dir_recursive_absolute(folder)

    await _invalid_load(screen, folder)

    if folder != "":
        await _capture(screen, Vector2i(1280, 800), folder.path_join("industry-wide.png"))
        await _capture(screen, Vector2i(720, 1000), folder.path_join("industry-narrow.png"))
        await _capture(screen, Vector2i(720, 1000), folder.path_join("industry-narrow-workshops.png"), true)

    main.queue_free()
    await process_frame
    _cleanup()
    print("Industry UI: %s" % ("PASS" if t.failures == 0 else "FAIL"))
    quit(t.finish())

func _page_text(screen: Control) -> String:
    var texts := PackedStringArray()
    for label in screen.find_children("*", "Label", true, false):
        if label.visible:
            texts.append(label.text)
    return "\n".join(texts)

func _invalid_load(normal_screen: Control, folder: String) -> void:
    var original := "{sauvegarde industrielle interrompue\n".to_utf8_buffer()
    var file := FileAccess.open(INVALID_PATH, FileAccess.WRITE)
    file.store_buffer(original)
    file.close()

    var blocked_screen = load("res://scenes/industry.tscn").instantiate()
    var blocked_session = blocked_screen.get_node("IndustrySession")
    blocked_session.save_path = INVALID_PATH
    normal_screen.hide()
    root.add_child(blocked_screen)
    blocked_session.set_process(false)
    await process_frame
    await process_frame

    t.check(blocked_session.save_blocked, "le vrai chargement invalide bloque l'enregistrement")
    var notice = blocked_screen.find_child("SaveNotice", true, false)
    t.check(notice.visible, "la sauvegarde invalide affiche sa notice")
    t.check(_page_text(blocked_screen).contains("fichier d'origine préservé"), "la notice confirme la préservation du fichier original")
    t.check(_page_text(blocked_screen).contains("Session provisoire") or _page_text(blocked_screen).contains("session provisoire"), "la notice explique la session provisoire")
    t.check(not blocked_session.persist(), "aucun enregistrement de la session provisoire")
    t.equal(FileAccess.get_file_as_bytes(INVALID_PATH), original, "les octets invalides sont préservés")

    if folder != "":
        await _capture(blocked_screen, Vector2i(720, 1000), folder.path_join("industry-save-blocked.png"))

    blocked_screen.queue_free()
    await process_frame
    DirAccess.remove_absolute(INVALID_PATH)
    normal_screen.show()

func _click(button: Button) -> void:
    t.check(button != null, "bouton présent avant clic")
    if button == null:
        return
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
    var columns = screen.find_child("ManagementColumns", true, false)
    if columns != null:
        t.equal(columns.vertical, stacked, "empilement adapté à %s" % dimensions)
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

func _cleanup() -> void:
    for path in [PATH, INVALID_PATH, PATH + ".tmp"]:
        if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
