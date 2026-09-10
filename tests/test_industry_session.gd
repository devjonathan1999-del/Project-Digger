extends RefCounted

const IndustrySessionScript = preload("res://src/industry/industry_session.gd")
const IndustryGameScript = preload("res://src/industry/industry_game.gd")
const IndustrySaveScript = preload("res://src/industry/industry_save.gd")
const PATH := "user://industry_test_session.json"
const TEMP_PATH := PATH + ".tmp"

func run(t: TestSupport) -> void:
    test_explicit_session_round_trip(t)
    test_initialize_commits_offline_progress_once(t)
    test_clock_rollback_is_ignored(t)
    test_invalid_load_blocks_all_writes(t)
    test_write_failure_exposes_notice_and_preserves_save(t)
    test_successful_action_is_persisted(t)
    _cleanup()

func test_explicit_session_round_trip(t: TestSupport) -> void:
    _cleanup()
    var session = IndustrySessionScript.new()
    session.save_path = PATH
    session.initialize(1000.0)
    t.equal(session.save_error, "", "session neuve initialisée")
    t.equal(session.last_seen_unix, 1000.0, "instant initial mémorisé")
    t.check(session.game.start_batch("iron_ingot", 1), "lot déterministe démarré")
    session.advance_to(1060.0)
    t.equal(session.offline_seconds, 0.0, "avancement actif distinct de l'absence chargée")
    t.equal(session.game.resources["iron_ingot"], 1.0, "lot terminé dans la session")
    t.check(session.persist(), "session avancée persistée")

    var reopened = IndustrySessionScript.new()
    reopened.save_path = PATH
    reopened.initialize(1060.0)
    t.equal(reopened.game.snapshot(), session.game.snapshot(), "réouverture sans double production")
    t.equal(reopened.offline_seconds, 0.0, "réouverture au même instant")
    session.free()
    reopened.free()
    _cleanup()

func test_clock_rollback_is_ignored(t: TestSupport) -> void:
    _cleanup()
    var session = IndustrySessionScript.new()
    session.save_path = PATH
    session.initialize(1000.0)
    var before: Dictionary = session.game.snapshot()
    for invalid_time in [900.0, -1.0, NAN, INF]:
        session.advance_to(invalid_time)
        t.equal(session.last_seen_unix, 1000.0, "instant logique ne recule pas")
        t.equal(session.game.snapshot(), before, "temps invalide sans production")
    session.free()
    _cleanup()

func test_initialize_commits_offline_progress_once(t: TestSupport) -> void:
    _cleanup()
    var game = IndustryGameScript.new()
    t.check(game.start_batch("iron_ingot", 1), "lot hors ligne préparé")
    t.check(IndustrySaveScript.new().save_game(PATH, game, 1000.0), "session hors ligne préparée")

    var session = IndustrySessionScript.new()
    session.save_path = PATH
    session.initialize(1060.0)
    t.equal(session.offline_seconds, 60.0, "absence exposée par la session")
    t.equal(session.game.resources["iron_ingot"], 1.0, "production hors ligne appliquée")
    var committed: Dictionary = session.game.snapshot()

    var reopened = IndustrySessionScript.new()
    reopened.save_path = PATH
    reopened.initialize(1060.0)
    t.equal(reopened.offline_seconds, 0.0, "absence validée non rejouée")
    t.equal(reopened.game.snapshot(), committed, "production hors ligne créditée une fois")
    session.free()
    reopened.free()
    _cleanup()

func test_invalid_load_blocks_all_writes(t: TestSupport) -> void:
    _cleanup()
    _write_text(PATH, "fichier industriel invalide")
    var previous_bytes := FileAccess.get_file_as_bytes(PATH)
    var session = IndustrySessionScript.new()
    session.save_path = PATH
    session.initialize(1000.0)
    t.check(session.save_error != "", "erreur de chargement exposée")
    t.equal(session.save_blocked, true, "écriture bloquée après chargement invalide")
    session.game.advance(60.0)
    t.equal(session.persist(), false, "sauvegarde manuelle bloquée")
    session._exit_tree()
    t.equal(FileAccess.get_file_as_bytes(PATH), previous_bytes, "fichier invalide jamais écrasé")
    session.free()
    _cleanup()

func test_write_failure_exposes_notice_and_preserves_save(t: TestSupport) -> void:
    _cleanup()
    var session = IndustrySessionScript.new()
    session.save_path = PATH
    session.initialize(1000.0)
    var previous_bytes := FileAccess.get_file_as_bytes(PATH)
    t.equal(DirAccess.make_dir_absolute(TEMP_PATH), OK, "écriture session rendue inaccessible")
    var notices := [0]
    session.notice_changed.connect(func() -> void: notices[0] += 1)
    session.game.advance(10.0)
    t.equal(session.persist(), false, "échec de session retourné")
    t.check(session.save_error != "", "échec de session exposé")
    t.equal(notices[0], 1, "bandeau d'erreur demandé")
    t.equal(FileAccess.get_file_as_bytes(PATH), previous_bytes, "échec session conserve la sauvegarde")
    session.free()
    _cleanup()

func test_successful_action_is_persisted(t: TestSupport) -> void:
    _cleanup()
    var now := Time.get_unix_time_from_system()
    var session = IndustrySessionScript.new()
    session.save_path = PATH
    session.initialize(now)
    t.check(session.start_batch("iron_ingot", 1), "action session acceptée")

    var reopened = IndustrySessionScript.new()
    reopened.save_path = PATH
    reopened.initialize(Time.get_unix_time_from_system())
    t.check(reopened.game.jobs.has("furnace"), "action session sauvegardée immédiatement")
    session.free()
    reopened.free()
    _cleanup()

func _write_text(path: String, contents: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(contents)
    file.close()

func _cleanup() -> void:
    for path in [PATH, TEMP_PATH]:
        if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
