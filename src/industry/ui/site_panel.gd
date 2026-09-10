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
var _built := false

func _ready() -> void:
    name = "ContextPanel"
    custom_minimum_size = Vector2(260, 180)
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_theme_stylebox_override("panel", Style.panel(Color("111f2c"), Color("3e6374"), 14))
    _ensure_built()
    visible = false

func show_selection(kind: String, id: String, session) -> void:
    _session = session
    _kind = kind
    _id = id
    _ensure_built()
    visible = true
    refresh()

func clear_selection() -> void:
    _kind = ""
    _id = ""
    _disconnect_button(_primary)
    _disconnect_button(_secondary)
    visible = false

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
            _body.text = "Niveau %d\nProduction : %.1f / min\nCoût : %s" % [game.mine_levels[_id], game.mine_rate(_id) * 60.0, _cost(game.mine_upgrade_cost(_id))]
            if mine_reason != "":
                _body.text += "\n" + mine_reason
            _configure_action(_primary, "AMÉLIORER", mine_reason, Callable(_session, "upgrade_mine").bind(_id))
        "drill":
            _title.text = "Foreuse"
            var excavation_reason: String = str(game.excavation_block_reason())
            _body.text = "Niveau %d / %d\nProchaine cible : −%d m\nDurée : %s" % [game.drill_level, Catalog.MAX_DRILL_LEVEL, game.depth + 10, _duration(game.excavation_duration())]
            if game.jobs.has("drill"):
                var job: Dictionary = game.jobs["drill"]
                excavation_reason = "Forage en cours"
                _body.text += "\nEn cours : %s restantes" % _duration(float(job["remaining"]))
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
            _body.text = "Profondeur : −%d m\nÉtat : %s\nQualité : %d %%" % [int(discovery.get("depth", 0)), str(discovery.get("state", "detected")).capitalize(), roundi(float(discovery.get("quality", 0.0)) * 100.0)]
            if not definition.is_empty():
                _body.text += "\nExploration : %s · %s" % [_duration(float(definition.get("seconds", 0.0))), _cost(definition.get("cost", {}))]
            if game.explorations.has(_id):
                var exploration: Dictionary = game.explorations[_id]
                _body.text += "\nReste : %s" % _duration(float(exploration["remaining"]))
            var exploration_reason: String = str(game.exploration_block_reason(_id))
            _configure_action(_primary, "EXPLORER", exploration_reason, Callable(_session, "start_exploration").bind(_id))
        "site":
            if not game.permanent_sites.has(_id):
                clear_selection()
                return
            var site: Dictionary = game.permanent_sites[_id]
            var active := bool(site.get("active", false))
            _title.text = str(site.get("type", "Site")).replace("_", " ").capitalize()
            _body.text = "Profondeur : −%d m\nCapacité : %d\nÉtat : %s" % [int(site.get("depth", 0)), int(site.get("capacity", 0)), "Actif" if active else "Inactif"]
            if float(site.get("rate", 0.0)) > 0.0:
                _body.text += "\nProduction : %.2f / min" % (float(site.get("rate", 0.0)) * 60.0)
            var target_state := not active
            var site_reason: String = str(game.site_toggle_block_reason(_id, target_state))
            _configure_action(_primary, "DÉSACTIVER" if active else "ACTIVER", site_reason, Callable(_session, "set_site_active").bind(_id, target_state))
        _:
            clear_selection()

func _reset_actions() -> void:
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

func _ensure_built() -> void:
    if _built:
        return
    _built = true
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 10)
    add_child(content)
    var header := HBoxContainer.new()
    content.add_child(header)
    _title = _label(header, "SÉLECTION", 18, Style.ACCENT)
    var close := Button.new()
    close.name = "ContextClose"
    close.text = "×"
    close.custom_minimum_size = Vector2(38, 38)
    close.pressed.connect(clear_selection)
    header.add_child(close)
    _body = _label(content, "", 14, Style.TEXT)
    _body.custom_minimum_size.y = 88
    _primary = Button.new()
    _primary.name = "ContextPrimary"
    _primary.text = "Action"
    _primary.custom_minimum_size.y = 40
    content.add_child(_primary)
    _secondary = Button.new()
    _secondary.name = "ContextSecondary"
    _secondary.text = "Action secondaire"
    _secondary.custom_minimum_size.y = 40
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
    label.text = value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(label)
    return label
