extends RefCounted

const AUDIO_PATH := "res://src/feedback/procedural_audio.gd"

func run(t: TestSupport) -> void:
    var exists := ResourceLoader.exists(AUDIO_PATH)
    t.equal(exists, true, "générateur audio procédural disponible")
    if not exists:
        return

    var audio_script = load(AUDIO_PATH)
    var stream = audio_script.call("make_tone", 440.0, 0.08, 0.20)
    t.check(stream != null, "cue procédural créé")
    if stream == null:
        return
    t.equal(stream.mix_rate, 22050, "mix rate stable")
    t.check(stream.data.size() > 100, "cue contient des échantillons")
