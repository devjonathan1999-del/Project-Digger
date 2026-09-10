class_name DiggerHUD
extends CanvasLayer

signal prepare_pressed
signal trigger_pressed
signal cancel_pressed
signal undo_pressed
signal tool_pressed(tool: StringName)

var _state_label: Label
var _energy_label: Label
var _relay_label: Label
var _objective_label: Label
var _prepare_button: Button
var _trigger_button: Button
var _cancel_button: Button
var _undo_button: Button
var _tool_buttons: Dictionary = {}
var _context_panel: PanelContainer
var _context_label: Label
var _state := SimulationController.OBSERVER
var _active_tool: StringName = &"dig"
var _busy := false

func _ready() -> void:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    var status_panel := PanelContainer.new()
    status_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
    status_panel.offset_left = 16
    status_panel.offset_top = 16
    status_panel.offset_right = -16
    status_panel.offset_bottom = 62
    status_panel.add_theme_stylebox_override("panel", _panel_style())
    root.add_child(status_panel)

    var status_margin := _margin_container(12, 8)
    status_panel.add_child(status_margin)
    var status_row := HBoxContainer.new()
    status_row.add_theme_constant_override("separation", 18)
    status_margin.add_child(status_row)

    _state_label = _make_label(status_row, "Observer")
    _state_label.add_theme_font_size_override("font_size", 16)
    _energy_label = _make_label(status_row, "Énergie : 0")
    _relay_label = _make_label(status_row, "Relais : coupé")
    _objective_label = _make_label(status_row, "Objectif : ouvrir la descente")
    _objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    _context_panel = PanelContainer.new()
    _context_panel.position = Vector2(16, 72)
    _context_panel.custom_minimum_size = Vector2(250, 52)
    _context_panel.add_theme_stylebox_override("panel", _panel_style())
    _context_panel.visible = false
    root.add_child(_context_panel)
    var context_margin := _margin_container(10, 7)
    _context_panel.add_child(context_margin)
    _context_label = _make_label(context_margin, "")

    var tool_panel := PanelContainer.new()
    tool_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    tool_panel.offset_left = -440
    tool_panel.offset_top = -74
    tool_panel.offset_right = 440
    tool_panel.offset_bottom = -16
    tool_panel.add_theme_stylebox_override("panel", _panel_style())
    root.add_child(tool_panel)

    var tool_margin := _margin_container(10, 8)
    tool_panel.add_child(tool_margin)
    var tool_row := HBoxContainer.new()
    tool_row.alignment = BoxContainer.ALIGNMENT_CENTER
    tool_row.add_theme_constant_override("separation", 7)
    tool_margin.add_child(tool_row)

    _tool_buttons[&"dig"] = _make_tool_button(tool_row, "1  Creuser", &"dig")
    _tool_buttons[&"move"] = _make_tool_button(tool_row, "2  Déplacer", &"move")
    _tool_buttons[&"fuse"] = _make_tool_button(tool_row, "3  Fusionner", &"fuse")

    var separator := VSeparator.new()
    separator.custom_minimum_size.x = 8
    tool_row.add_child(separator)

    _prepare_button = _make_button(tool_row, "Préparer", func() -> void: prepare_pressed.emit())
    _trigger_button = _make_button(tool_row, "Déclencher", func() -> void: trigger_pressed.emit())
    _cancel_button = _make_button(tool_row, "Annuler", func() -> void: cancel_pressed.emit())
    _undo_button = _make_button(tool_row, "Undo", func() -> void: undo_pressed.emit())

    _refresh_tool_state()
    _refresh_buttons()

func set_state(value: int) -> void:
    _state = value
    if _state_label != null:
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
    _active_tool = tool
    _refresh_tool_state()

func set_relay_connected(connected: bool) -> void:
    if _relay_label == null:
        return
    _relay_label.text = "Relais : connecté" if connected else "Relais : coupé"
    _relay_label.add_theme_color_override("font_color", Color("#72e2d6") if connected else Color("#e08a78"))

func set_objective_text(text: String) -> void:
    if _objective_label != null:
        _objective_label.text = text

func set_context(material_name: String, action_name: String, cost: int, actionable: bool) -> void:
    if _context_panel == null or _context_label == null:
        return
    _context_panel.visible = true
    if actionable:
        _context_label.text = "%s\n%s · Énergie %d" % [material_name, action_name, cost]
    else:
        _context_label.text = "%s\nAction indisponible" % material_name

func clear_context() -> void:
    if _context_panel != null:
        _context_panel.visible = false

func set_busy(value: bool) -> void:
    _busy = value
    _refresh_buttons()

func _make_label(parent: Control, text: String) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_color_override("font_color", Color("#d9e7ec"))
    parent.add_child(label)
    return label

func _make_button(parent: Control, text: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(108, 38)
    button.add_theme_font_size_override("font_size", 13)
    button.add_theme_stylebox_override("normal", _button_style(Color("#13212a"), Color(0.22, 0.47, 0.54, 0.65)))
    button.add_theme_stylebox_override("hover", _button_style(Color("#19313a"), Color(0.35, 0.72, 0.76, 0.85)))
    button.add_theme_stylebox_override("pressed", _button_style(Color("#17434a"), Color("#61d4cf")))
    button.add_theme_stylebox_override("disabled", _button_style(Color(0.06, 0.09, 0.11, 0.72), Color(0.18, 0.25, 0.28, 0.55)))
    button.pressed.connect(callback)
    parent.add_child(button)
    return button

func _make_tool_button(parent: Control, text: String, tool: StringName) -> Button:
    var button := _make_button(parent, text, func() -> void: tool_pressed.emit(tool))
    button.toggle_mode = true
    return button

func _margin_container(horizontal: int, vertical: int) -> MarginContainer:
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", horizontal)
    margin.add_theme_constant_override("margin_right", horizontal)
    margin.add_theme_constant_override("margin_top", vertical)
    margin.add_theme_constant_override("margin_bottom", vertical)
    return margin

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.035, 0.055, 0.07, 0.90)
    style.border_color = Color(0.18, 0.55, 0.62, 0.45)
    style.set_border_width_all(1)
    style.set_corner_radius_all(6)
    return style

func _button_style(background: Color, border: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(1)
    style.set_corner_radius_all(5)
    style.content_margin_left = 10
    style.content_margin_right = 10
    return style

func _refresh_tool_state() -> void:
    for tool in _tool_buttons.keys():
        var button: Button = _tool_buttons[tool]
        button.set_pressed_no_signal(tool == _active_tool)

func _refresh_buttons() -> void:
    if _prepare_button == null:
        return

    _prepare_button.visible = _state == SimulationController.OBSERVER
    _trigger_button.visible = _state == SimulationController.PREPARE
    _cancel_button.visible = _state == SimulationController.PREPARE
    _undo_button.visible = _state == SimulationController.PREPARE

    _prepare_button.disabled = _busy
    _trigger_button.disabled = _busy
    _cancel_button.disabled = _busy
    _undo_button.disabled = _busy
    for button in _tool_buttons.values():
        (button as Button).disabled = _busy
