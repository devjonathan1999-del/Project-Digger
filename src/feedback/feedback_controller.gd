class_name FeedbackController
extends Node

const AudioFactory := preload("res://src/feedback/procedural_audio.gd")
const Classifier := preload("res://src/feedback/feedback_classifier.gd")
const TerrainView := preload("res://src/view/terrain_renderer.gd")

var _camera: Camera2D
var _fx: Variant = null
var _ancient_overlay: Variant = null
var _audio: AudioStreamPlayer

func _ready() -> void:
    _audio = AudioStreamPlayer.new()
    _audio.volume_db = -6.0
    add_child(_audio)

func configure(camera: Camera2D, fx: Variant, ancient_overlay: Variant) -> void:
    _camera = camera
    _fx = fx
    _ancient_overlay = ancient_overlay

func play_action(tool: StringName, material_id: StringName) -> void:
    var frequency := 250.0
    if tool == &"fuse" or material_id == &"stabilizer":
        frequency = 720.0
    elif material_id == &"rock_fragile":
        frequency = 360.0
    elif tool == &"move":
        frequency = 180.0
    elif material_id == &"rock_dense":
        frequency = 135.0
    _play_tone(frequency, 0.055, 0.12)

func play_trigger_anticipation() -> void:
    if _ancient_overlay != null:
        _ancient_overlay.call("pulse")
    _play_tone(520.0, 0.09, 0.10)

func play_resolution(
    movements: Array[Dictionary],
    relay_connected: bool,
    objective_reached: bool,
    success_cell: Vector2i
) -> void:
    var intensity: int = Classifier.classify_movements(movements)
    if _ancient_overlay != null:
        _ancient_overlay.call("set_connected", relay_connected)
    if _fx != null:
        _fx.call("play_movements", movements, TerrainView.CELL_SIZE)

    if intensity == Classifier.HEAVY:
        if _camera != null:
            _camera.call("play_impulse", 6.0)
        _play_tone(105.0, 0.18, 0.22)
    elif intensity == Classifier.LIGHT:
        if _camera != null:
            _camera.call("play_impulse", 2.0)
        _play_tone(180.0, 0.11, 0.14)

    if objective_reached:
        if _fx != null:
            _fx.call("play_success", success_cell, TerrainView.CELL_SIZE)
        _play_tone(760.0, 0.20, 0.15)

func _play_tone(frequency: float, duration: float, volume: float) -> void:
    if _audio == null:
        return
    _audio.stream = AudioFactory.make_tone(frequency, duration, volume)
    _audio.play()
