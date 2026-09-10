extends RefCounted

const Game = preload("res://src/industry/industry_game.gd")
const Save = preload("res://src/industry/industry_save.gd")
const PATH := "user://tests/industry_acceptance.json"

func run(t) -> void:
    var game = Game.new()
    t.check(game.start_batch("iron_ingot", 3), "premier lot de trois lingots")
    game.advance(60.0)
    t.check(game.start_batch("copper_ingot", 2), "lot de cuivre après fonte")
    game.advance(50.0)
    t.check(game.start_batch("cable", 1), "câble disponible grâce aux deux fontes")
    game.advance(40.0)
    t.check(game.upgrade_drill(), "première amélioration préparée en 150 secondes")
    t.check(game.start_excavation(), "premier chantier")
    game.advance(15.0)
    t.equal(game.depth, 10, "premier horizon atteint")
    DirAccess.make_dir_recursive_absolute("user://tests")
    t.check(Save.new().save_game(PATH, game, 1000.0), "persistance du parcours")
    var loaded: Dictionary = Save.new().load_game(PATH, 1000.0)
    t.equal(loaded["game"].depth, 10, "profondeur conservée au retour")
    t.equal(loaded["game"].drill_level, 2, "foreuse conservée au retour")
    DirAccess.remove_absolute(PATH)
