class_name DiggerHUD
extends CanvasLayer

signal prepare_pressed
signal trigger_pressed
signal cancel_pressed
signal undo_pressed

var _state_label: Label
var _energy_label: Label
var _tool_label: Label
var _relay_label: Label
var _objective_label: Label
var _prepare_button: Button
var _trigger_button: Button
var _cancel_button: Button
var _undo_button: Button
var _state := SimulationController.OBSERVER

func _ready() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 16)
    panel.custom_minimum_size = Vector2(310, 0)
    add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_bottom", 12)
    panel.add_child(margin)

    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 6)
    margin.add_child(content)

    _state_label = _make_label(content, "Observer")
    _energy_label = _make_label(content, "Énergie : 0")
    _tool_label = _make_label(content, "Outil : Creuser")
    _relay_label = _make_label(content, "Relais : coupé")
    _objective_label = _make_label(content, "Objectif : atteindre la sortie")
    _objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    var buttons := HBoxContainer.new()
    buttons.add_theme_constant_override("separation", 6)
    content.add_child(buttons)

    _prepare_button = _make_button(buttons, "Préparer", func() -> void: prepare_pressed.emit())
    _trigger_button = _make_button(buttons, "Déclencher", func() -> void: trigger_pressed.emit())
    _cancel_button = _make_button(buttons, "Annuler", func() -> void: cancel_pressed.emit())
    _undo_button = _make_button(buttons, "Undo", func() -> void: undo_pressed.emit())
    _refresh_buttons()

func set_state(value: int) -> void:
    _state = value
    if _state_label == null:
        return
    match value:
        SimulationController.OBSERVER:
            _state_label.text = "Observer"
        SimulationController.PREPARE:
            _state_label.text = "Préparer"
        SimulationController.RESOLVING:
            _state_label.text = "Résolution"
        _:
            _state_label.text = "Observer"
    _refresh_buttons()

func set_energy(value: int) -> void:
    if _energy_label != null:
        _energy_label.text = "Énergie : %d" % value

func set_tool(tool: StringName) -> void:
    if _tool_label == null:
        return
    var label := "Creuser"
    if tool == &"move":
        label = "Déplacer"
    elif tool == &"fuse":
        label = "Fusionner"
    _tool_label.text = "Outil : %s" % label

func set_relay_connected(connected: bool) -> void:
    if _relay_label != null:
        _relay_label.text = "Relais : connecté" if connected else "Relais : coupé"

func set_objective_text(text: String) -> void:
    if _objective_label != null:
        _objective_label.text = text

func _make_label(parent: Control, text: String) -> Label:
    var label := Label.new()
    label.text = text
    parent.add_child(label)
    return label

func _make_button(parent: Control, text: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.pressed.connect(callback)
    parent.add_child(button)
    return button

func _refresh_buttons() -> void:
    if _prepare_button == null:
        return
    _prepare_button.visible = _state == SimulationController.OBSERVER
    _trigger_button.visible = _state == SimulationController.PREPARE
    _cancel_button.visible = _state == SimulationController.PREPARE
    _undo_button.visible = _state == SimulationController.PREPARE
