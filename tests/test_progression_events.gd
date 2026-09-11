extends RefCounted

const IndustryGameScript = preload("res://src/industry/industry_game.gd")
const IndustrySaveScript = preload("res://src/industry/industry_save.gd")
const IndustrySessionScript = preload("res://src/industry/industry_session.gd")
const PATH := "user://progression_event_test.json"

func run(t: TestSupport) -> void:
    test_pending_event_waits_for_presentation(t)
    test_event_big_step_matches_small_steps(t)
    test_offline_session_keeps_unseen_event_pending(t)
    _cleanup()

func test_pending_event_waits_for_presentation(t: TestSupport) -> void:
    var game = IndustryGameScript.new()
    game.pending_events.append({"type": "unstable_vein", "presented": false})
    game.advance(3600.0)
    t.check(game.active_event.is_empty(), "événement non présenté ne démarre pas hors ligne")
    t.equal(game.pending_events.size(), 1, "événement reste en attente")

    t.check(game.present_pending_event(), "événement présenté")
    t.check(is_equal_approx(game.active_event["remaining"], 300.0), "timer démarre à cinq minutes lors de la présentation")
    t.check(game.choose_event_resource("copper"), "choix cuivre accepté")
    var boosted := game.mine_rate("copper")
    game.advance(299.0)
    t.check(is_equal_approx(game.mine_rate("copper"), boosted), "bonus reste actif avant expiration")
    var report: Dictionary = game.advance(1.0)
    t.check(game.active_event.is_empty(), "événement expire à cinq minutes")
    t.check("unstable_vein" in report["events_expired"], "expiration rapportée")

func test_event_big_step_matches_small_steps(t: TestSupport) -> void:
    var large = IndustryGameScript.new()
    large.pending_events.append({"type": "unstable_vein", "presented": false})
    t.check(large.present_pending_event(), "événement grand pas présenté")
    t.check(large.choose_event_resource("iron"), "choix fer grand pas")
    large.advance(600.0)

    var stepped = IndustryGameScript.new()
    stepped.pending_events.append({"type": "unstable_vein", "presented": false})
    t.check(stepped.present_pending_event(), "événement petits pas présenté")
    t.check(stepped.choose_event_resource("iron"), "choix fer petits pas")
    for index in range(10):
        stepped.advance(60.0)

    for id in large.resources:
        t.check(is_equal_approx(float(large.resources[id]), float(stepped.resources[id])), "grand/petits pas identiques pour %s" % id)
    t.equal(large.active_event, stepped.active_event, "état événement indépendant du pas")

func test_offline_session_keeps_unseen_event_pending(t: TestSupport) -> void:
    _cleanup()
    var game = IndustryGameScript.new()
    game.pending_events.append({"type": "unstable_vein", "presented": false})
    var save = IndustrySaveScript.new()
    t.check(save.save_game(PATH, game, 1000.0), "événement en attente sauvegardé")

    var session = IndustrySessionScript.new()
    session.save_path = PATH
    session.initialize(4600.0)
    t.equal(session.game.pending_events.size(), 1, "absence ne consomme pas événement invisible")
    t.check(session.game.active_event.is_empty(), "absence ne démarre pas le timer")
    t.check(session.present_pending_event(), "session peut présenter l'événement au retour")
    t.check(is_equal_approx(session.game.active_event["remaining"], 300.0), "timer session démarre au retour")
    session.free()
    _cleanup()

func _cleanup() -> void:
    for path in [PATH, PATH + ".tmp"]:
        if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
