class_name SitePanel
extends PanelContainer

const Catalog = preload("res://src/industry/industry_catalog.gd")
const Style = preload("res://src/industry/ui/industry_theme.gd")

var _session
var _kind := ""
var _id := ""
var _title: Label
var _body: Label
var _primary: Button
var _secondary: Button
var _event_choices: HBoxContainer
var _event_buttons: Dictionary = {}
var _built := false

func _ready() -> void:
    name = "ContextPanel"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_theme_stylebox_override("panel", Style.panel(Color("101b25e8"), Style.COPPER, 12))
    _ensure_built()
    set_layout_mode("floating_right")
    visible = false

func set_layout_mode(mode: String) -> void:
    if mode not in ["floating_right", "bottom_sheet"]:
        return
    set_meta("layout_mode", mode)
    if mode == "floating_right":
        custom_minimum_size = Vector2(300, 0)
        set_anchor(SIDE_LEFT, 1.0)
        set_anchor(SIDE_RIGHT, 1.0)
        set_anchor(SIDE_TOP, 0.12)
        set_anchor(SIDE_BOTTOM, 0.72)
        offset_left = -336.0
        offset_right = -16.0
        offset_top = 0.0
        offset_bottom = 0.0
    else:
        custom_minimum_size = Vector2(0, 220)
        set_anchor(SIDE_LEFT, 0.03)
        set_anchor(SIDE_RIGHT, 0.97)
        set_anchor(SIDE_TOP, 1.0)
        set_anchor(SIDE_BOTTOM, 1.0)
        offset_left = 0.0
        offset_right = 0.0
        offset_top = -300.0
        offset_bottom = -12.0

func show_selection(kind: String, id: String, session) -> void:
    _session = session
    _kind = kind
    _id = id
    _ensure_built()
    visible = true
    refresh()

func show_event(session) -> void:
    _session = session
    _kind = "event"
    _id = "unstable_vein"
    _ensure_built()
    visible = true
    refresh()

func clear_selection() -> void:
    _kind = ""
    _id = ""
    _disconnect_button(_primary)
    _disconnect_button(_secondary)
    if _event_choices != null:
        _event_choices.visible = false
    visible = false
    _clear_world_marker_selection()

func _clear_world_marker_selection() -> void:
    if not is_inside_tree():
        return
    var presenter = get_tree().root.find_child("MineInteractionPresenter", true, false)
    if presenter != null and presenter.has_method("set_selected_key"):
        presenter.call("set_selected_key", "")

func refresh() -> void:
    if _session == null or _kind == "" or not _built:
        return
    var game = _session.game
    _reset_actions()
    match _kind:
        "mine":
            if not Catalog.MINES.has(_id):
                clear_selection()
                return
            var maximum: bool = int(game.mine_levels[_id]) >= Catalog.MAX_MINE_LEVEL
            var affordable: bool = game.can_afford(game.mine_upgrade_cost(_id))
            var mine_reason := ""
            if maximum:
                mine_reason = "Niveau maximum"
            elif not affordable:
                mine_reason = "Ressources insuffisantes"
            _title.text = Catalog.MINES[_id]["label"]
            _body.text = "Niveau %d · %.1f / min\nCoût : %s" % [game.mine_levels[_id], game.mine_rate(_id) * 60.0, _cost(game.mine_upgrade_cost(_id))]
            if mine_reason != "":
                _body.text += "\n" + mine_reason
            _configure_action(_primary, "AMÉLIORER", mine_reason, Callable(_session, "upgrade_mine").bind(_id))
        "drill":
            _title.text = "Foreuse"
            var excavation_reason: String = str(game.excavation_block_reason())
            _body.text = "Niv. %d / %d · cible −%d m\nDurée : %s" % [game.drill_level, Catalog.MAX_DRILL_LEVEL, game.depth + 10, _duration(game.excavation_duration())]
            if game.jobs.has("drill"):
                var job: Dictionary = game.jobs["drill"]
                excavation_reason = "Forage en cours"
                _body.text += "\nReste %s" % _duration(float(job["remaining"]))
            elif excavation_reason != "":
                _body.text += "\n" + excavation_reason
            _configure_action(_primary, "FORER", excavation_reason, Callable(_session, "start_excavation"))
            var upgrade_reason := ""
            if int(game.drill_level) >= Catalog.MAX_DRILL_LEVEL:
                upgrade_reason = "Niveau maximum"
            elif not game.can_afford(game.drill_upgrade_cost()):
                upgrade_reason = "Ressources insuffisantes"
            _configure_action(_secondary, "AMÉLIORER", upgrade_reason, Callable(_session, "upgrade_drill"))
        "discovery":
            if not game.discoveries.has(_id):
                clear_selection()
                return
            var discovery: Dictionary = game.discoveries[_id]
            var type_id := str(discovery.get("type", ""))
            var definition: Dictionary = Catalog.POCKET_TYPES.get(type_id, {})
            _title.text = str(discovery.get("hint", "Découverte"))
            _body.text = "−%d m · %s · qualité %d %%" % [int(discovery.get("depth", 0)), str(discovery.get("state", "detected")).capitalize(), roundi(float(discovery.get("quality", 0.0)) * 100.0)]
            if not definition.is_empty():
                _body.text += "\n%s · %s" % [_duration(float(definition.get("seconds", 0.0))), _cost(definition.get("cost", {}))]
            if game.explorations.has(_id):
                var exploration: Dictionary = game.explorations[_id]
                _body.text += "\nReste %s" % _duration(float(exploration["remaining"]))
            var exploration_reason: String = str(game.exploration_block_reason(_id))
            _configure_action(_primary, "EXPLORER", exploration_reason, Callable(_session, "start_exploration").bind(_id))
        "site":
            if not game.permanent_sites.has(_id):
                clear_selection()
                return
            var site: Dictionary = game.permanent_sites[_id]
            var active := bool(site.get("active", false))
            _title.text = str(site.get("type", "Site")).replace("_", " ").capitalize()
            _body.text = "−%d m · capacité %d · %s" % [int(site.get("depth", 0)), int(site.get("capacity", 0)), "Actif" if active else "Inactif"]
            if float(site.get("rate", 0.0)) > 0.0:
                _body.text += "\nProduction %.2f / min" % (float(site.get("rate", 0.0)) * 60.0)
            var target_state := not active
            var site_reason: String = str(game.site_toggle_block_reason(_id, target_state))
            _configure_action(_primary, "DÉSACTIVER" if active else "ACTIVER", site_reason, Callable(_session, "set_site_active").bind(_id, target_state))
        "event":
            if game.active_event.is_empty():
                clear_selection()
                return
            var resource_id := str(game.active_event.get("resource", ""))
            _title.text = "Filon instable"
            if resource_id == "":
                _body.text = "Choisis la ressource à privilégier.\nLe compte à rebours démarre après ton choix."
                _event_choices.visible = true
            else:
                var resource_label := str(Catalog.RESOURCES[resource_id]["label"])
                _body.text = "Priorité : %s\nBonus actif · reste %s" % [resource_label, _duration(float(game.active_event.get("remaining", 0.0)))]
        _:
            clear_selection()

func _reset_actions() -> void:
    if _event_choices != null:
        _event_choices.visible = false
    for button in [_primary, _secondary]:
        _disconnect_button(button)
        button.visible = false
        button.disabled = true
        button.tooltip_text = ""

func _configure_action(button: Button, title: String, reason: String, action: Callable) -> void:
    button.visible = true
    button.text = title
    button.disabled = reason != ""
    button.tooltip_text = reason
    if reason == "" and action.is_valid():
        button.pressed.connect(action)

func _disconnect_button(button: Button) -> void:
    if button == null:
        return
    for connection in button.pressed.get_connections():
        var callable: Callable = connection["callable"]
        if button.pressed.is_connected(callable):
            button.pressed.disconnect(callable)

func _choose_event_resource(resource_id: String) -> void:
    if _session != null:
        _session.choose_event_resource(resource_id)

func _ensure_built() -> void:
    if _built:
        return
    _built = true
    var content := VBoxContainer.new()
    content.mouse_filter = Control.MOUSE_FILTER_IGNORE
    content.add_theme_constant_override("separation", 8)
    add_child(content)
    var header := HBoxContainer.new()
    header.mouse_filter = Control.MOUSE_FILTER_IGNORE
    content.add_child(header)
    _title = _label(header, "SÉLECTION", 17, Style.ACCENT)
    var close := Button.new()
    close.name = "ContextClose"
    close.text = "×"
    close.custom_minimum_size = Vector2(34, 34)
    close.pressed.connect(clear_selection)
    header.add_child(close)
    _body = _label(content, "", 13, Style.TEXT)
    _body.custom_minimum_size.y = 60
    _event_choices = HBoxContainer.new()
    _event_choices.name = "EventChoices"
    _event_choices.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _event_choices.visible = false
    _event_choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_child(_event_choices)
    for resource_id in ["iron", "copper", "coal"]:
        var choice := Button.new()
        choice.name = "Event_" + resource_id
        choice.text = Catalog.RESOURCES[resource_id]["label"]
        choice.custom_minimum_size.y = 36
        choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        choice.pressed.connect(_choose_event_resource.bind(resource_id))
        _event_choices.add_child(choice)
        _event_buttons[resource_id] = choice
    _primary = Button.new()
    _primary.name = "ContextPrimary"
    _primary.text = "Action"
    _primary.custom_minimum_size.y = 38
    content.add_child(_primary)
    _secondary = Button.new()
    _secondary.name = "ContextSecondary"
    _secondary.text = "Action secondaire"
    _secondary.custom_minimum_size.y = 38
    content.add_child(_secondary)

func _cost(cost: Dictionary) -> String:
    if cost.is_empty():
        return "Aucun coût"
    var parts := PackedStringArray()
    for resource_id in cost:
        var label := str(Catalog.RESOURCES.get(resource_id, {"label": resource_id}).get("label", resource_id))
        parts.append("%d %s" % [int(cost[resource_id]), label])
    return " · ".join(parts)

func _duration(seconds: float) -> String:
    var rounded := ceili(seconds)
    if rounded >= 60:
        return "%d:%02d" % [rounded / 60, rounded % 60]
    return "%d s" % rounded

func _label(parent: Node, value: String, font_size: int = 16, color: Color = Style.TEXT) -> Label:
    var label := Label.new()
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.text = value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(label)
    return label
