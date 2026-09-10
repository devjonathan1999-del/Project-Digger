class_name CenterPanel
extends VBoxContainer

const Catalog = preload("res://src/industry/industry_catalog.gd")
const Style = preload("res://src/industry/ui/industry_theme.gd")

var session
var _level: Label
var _capacity: Label
var _upgrade_cost: Label
var _upgrade: Button
var _sites: VBoxContainer
var _built := false

func _ready() -> void:
    _ensure_built()

func bind_session(value) -> void:
    session = value
    _ensure_built()
    if session != null and not session.changed.is_connected(refresh):
        session.changed.connect(refresh)
    refresh()

func _ensure_built() -> void:
    if _built:
        return
    _built = true
    name = "CenterPanel"
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_theme_constant_override("separation", 14)
    _label(self, "CENTRE D'OPÉRATIONS", 22)
    _label(self, "Capacité d'exploitation et sites permanents", 14, Style.MUTED)
    var summary := _card(self)
    _level = _label(summary, "", 20, Style.ACCENT)
    _capacity = _label(summary, "", 15)
    _upgrade_cost = _label(summary, "", 14, Style.COPPER)
    _upgrade = _button(summary, "Améliorer le Centre", "CenterUpgrade")
    _upgrade.pressed.connect(_upgrade_center)
    _label(self, "SITES PERMANENTS", 14, Style.MUTED)
    _sites = VBoxContainer.new()
    _sites.name = "PermanentSites"
    _sites.add_theme_constant_override("separation", 10)
    add_child(_sites)

func refresh() -> void:
    if session == null or not _built:
        return
    var game = session.game
    _level.text = "Centre niveau %d" % game.center_level
    _capacity.text = "Capacité : %d / %d utilisée" % [game.used_capacity(), game.total_capacity()]
    var reason := game.center_upgrade_block_reason()
    _upgrade.disabled = reason != ""
    if game.center_level < Catalog.CENTER_LEVELS.size():
        var next_level := game.center_level + 1
        _upgrade_cost.text = "Niveau %d · %s" % [next_level, _cost(Catalog.CENTER_LEVELS[next_level]["cost"])]
        if reason != "":
            _upgrade_cost.text += "\n" + reason
    else:
        _upgrade_cost.text = "Niveau maximum"
    _rebuild_sites()

func _rebuild_sites() -> void:
    for child in _sites.get_children():
        child.queue_free()
    var game = session.game
    if game.permanent_sites.is_empty():
        _label(_sites, "Aucun site permanent ouvert pour le moment.", 14, Style.MUTED)
        return
    var ids: Array = game.permanent_sites.keys()
    ids.sort()
    for id in ids:
        var site: Dictionary = game.permanent_sites[id]
        var box := _card(_sites, 12)
        var type_id := str(site.get("type", ""))
        var title := type_id.replace("_", " ").capitalize()
        _label(box, "%s · −%d m" % [title, int(site.get("depth", 0))], 17)
        _label(box, "Capacité %d · %s" % [int(site.get("capacity", 0)), "Actif" if bool(site.get("active", false)) else "Inactif"], 13, Style.MUTED)
        var button := _button(box, "Désactiver" if bool(site.get("active", false)) else "Activer", "SiteToggle_" + str(id).replace(":", "_"))
        var target_state := not bool(site.get("active", false))
        button.disabled = game.site_toggle_block_reason(str(id), target_state) != ""
        button.pressed.connect(_toggle_site.bind(str(id), target_state))

func _upgrade_center() -> void:
    if session != null:
        session.upgrade_center()

func _toggle_site(id: String, active: bool) -> void:
    if session != null:
        session.set_site_active(id, active)

func _cost(cost: Dictionary) -> String:
    var parts := PackedStringArray()
    for id in cost:
        parts.append("%d %s" % [int(cost[id]), Catalog.RESOURCES[id]["label"]])
    return " · ".join(parts) if not parts.is_empty() else "Aucune ressource"

func _card(parent: Node, padding: int = 16) -> VBoxContainer:
    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", Style.panel(Style.PANEL, Color("294052"), padding))
    parent.add_child(panel)
    var content := VBoxContainer.new()
    panel.add_child(content)
    return content

func _label(parent: Node, value: String, font_size: int = 16, color: Color = Style.TEXT) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(label)
    return label

func _button(parent: Node, title: String, node_name: String) -> Button:
    var button := Button.new()
    button.name = node_name
    button.text = title
    button.custom_minimum_size.y = 40
    parent.add_child(button)
    return button
