class_name TechnologyPanel
extends VBoxContainer

const Catalog = preload("res://src/industry/industry_catalog.gd")
const Style = preload("res://src/industry/ui/industry_theme.gd")

const BRANCH_LABELS := {
    "production": "Production",
    "logistics": "Logistique",
    "exploration": "Exploration",
}

var session
var _points: Label
var _cooldown: Label
var _tech_widgets: Dictionary = {}
var _priority_buttons: Dictionary = {}
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
    name = "TechnologyPanel"
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_theme_constant_override("separation", 14)
    _label(self, "TECHNOLOGIE", 22)
    _label(self, "Trois axes de spécialisation à partir de 90 m", 14, Style.MUTED)
    _points = _label(self, "", 18, Style.ACCENT)
    _cooldown = _label(self, "", 13, Style.MUTED)

    var grid := GridContainer.new()
    grid.columns = 3
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_child(grid)
    for id in Catalog.TECHNOLOGIES:
        var definition: Dictionary = Catalog.TECHNOLOGIES[id]
        var branch := str(definition["branch"])
        var box := _card(grid, 12)
        _label(box, BRANCH_LABELS.get(branch, branch.capitalize()), 18)
        var state := _label(box, "", 13, Style.MUTED)
        var cost := _label(box, _cost(definition["cost"]), 13, Style.COPPER)
        var unlock := _button(box, "Débloquer", "TechUnlock_" + id)
        unlock.pressed.connect(_unlock.bind(id))
        var build := _button(box, "Construire", "TechBuild_" + id)
        build.pressed.connect(_build_technology.bind(id))
        var priority := _button(box, "Priorité " + BRANCH_LABELS.get(branch, branch.capitalize()), "Priority_" + branch)
        priority.pressed.connect(_set_priority.bind(branch))
        _tech_widgets[id] = {"state": state, "cost": cost, "unlock": unlock, "build": build, "priority": priority}
        _priority_buttons[branch] = priority

func refresh() -> void:
    if session == null or not _built:
        return
    var game = session.game
    _points.text = "Points technologiques : %d" % game.tech_points
    _cooldown.text = "Priorité : %s" % (BRANCH_LABELS.get(game.priority_branch, "Aucune") if game.priority_branch != "" else "Aucune")
    if game.priority_cooldown_remaining > 0.0:
        _cooldown.text += " · changement disponible dans %s" % _duration(game.priority_cooldown_remaining)
    for id in _tech_widgets:
        var widgets: Dictionary = _tech_widgets[id]
        var definition: Dictionary = Catalog.TECHNOLOGIES[id]
        var branch := str(definition["branch"])
        var unlocked := id in game.unlocked_technologies
        var built := id in game.built_technologies
        widgets["state"].text = "Construite" if built else ("Débloquée" if unlocked else game.technology_unlock_block_reason(id))
        widgets["unlock"].visible = not unlocked
        widgets["unlock"].disabled = game.technology_unlock_block_reason(id) != ""
        widgets["build"].visible = unlocked and not built
        widgets["build"].disabled = game.technology_build_block_reason(id) != ""
        widgets["priority"].disabled = game.priority_block_reason(branch) != ""
        widgets["priority"].text = "Priorité active" if game.priority_branch == branch else "Priorité " + BRANCH_LABELS.get(branch, branch.capitalize())

func _unlock(id: String) -> void:
    if session != null:
        session.unlock_technology(id)

func _build_technology(id: String) -> void:
    if session != null:
        session.build_technology(id)

func _set_priority(branch: String) -> void:
    if session != null:
        session.set_priority(branch)

func _cost(cost: Dictionary) -> String:
    var parts := PackedStringArray()
    for id in cost:
        parts.append("%d %s" % [int(cost[id]), Catalog.RESOURCES[id]["label"]])
    return " · ".join(parts) if not parts.is_empty() else "Aucune ressource"

func _duration(seconds: float) -> String:
    var rounded := ceili(seconds)
    return "%d:%02d" % [rounded / 60, rounded % 60]

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
