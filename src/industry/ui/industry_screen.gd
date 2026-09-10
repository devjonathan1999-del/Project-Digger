class_name IndustryScreen
extends Control

const Catalog = preload("res://src/industry/industry_catalog.gd")
const Style = preload("res://src/industry/ui/industry_theme.gd")
const Overview = preload("res://src/industry/ui/mine_overview.gd")

var session
var _wallet: Dictionary = {}
var _mines: Dictionary = {}
var _facilities: Dictionary = {}
var _columns: BoxContainer
var _mine_row: BoxContainer
var _factory_row: BoxContainer
var _wallet_grid: GridContainer
var _overview: Control
var _depth: Label
var _drill_info: Label
var _drill_cost: Label
var _drill_upgrade: Button
var _dig: Button
var _dig_info: Label
var _dig_progress: ProgressBar
var _offline: Label
var _save_notice: Label
var _save_status: Label

func _ready() -> void:
    session = get_node("IndustrySession")
    theme = Style.create()
    _build()
    session.changed.connect(_refresh)
    session.notice_changed.connect(_refresh_notices)
    resized.connect(_responsive)
    _responsive()
    _refresh()
    _refresh_notices()

func _build() -> void:
    var background := ColorRect.new()
    background.color = Style.BACKGROUND
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var scroll := ScrollContainer.new()
    scroll.name = "PageScroll"
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(scroll)
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var margin := MarginContainer.new()
    margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 22)
    scroll.add_child(margin)
    var page := VBoxContainer.new()
    page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    page.add_theme_constant_override("separation", 16)
    margin.add_child(page)
    var header := HBoxContainer.new()
    page.add_child(header)
    var title := VBoxContainer.new()
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_constant_override("separation", 2)
    header.add_child(title)
    _label(title, "D I G G E R  /  INDUSTRIES", 24)
    _label(title, "Du minerai aux profondeurs", 15, Style.MUTED)
    _depth = _label(header, "", 30, Style.ACCENT)
    _wallet_grid = GridContainer.new()
    _wallet_grid.columns = 6
    page.add_child(_wallet_grid)
    for id in Catalog.RESOURCES:
        var box := _card(_wallet_grid, 10)
        _label(box, Catalog.RESOURCES[id]["label"], 14, Style.MUTED)
        var number := _label(box, "0", 24, Style.ACCENT if Catalog.RESOURCES[id]["raw"] else Style.COPPER)
        number.name = "Stock_" + id
        _wallet[id] = number
    _offline = _label(page, "", 15, Style.ACCENT)
    _offline.name = "OfflineNotice"
    _save_notice = _label(page, "", 15, Style.COPPER)
    _save_notice.name = "SaveNotice"
    _columns = BoxContainer.new()
    _columns.name = "ManagementColumns"
    _columns.add_theme_constant_override("separation", 18)
    page.add_child(_columns)
    var left := VBoxContainer.new()
    left.custom_minimum_size.x = 290
    left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    left.size_flags_stretch_ratio = 0.85
    _columns.add_child(left)
    var survey := _card(left)
    _label(survey, "01  /  LE SOUS-SOL", 15, Style.MUTED)
    _overview = Overview.new()
    survey.add_child(_overview)
    var drill := _card(left)
    _label(drill, "Foreuse", 21)
    _drill_info = _label(drill, "", 15, Style.MUTED)
    _drill_cost = _label(drill, "", 14, Style.COPPER)
    _drill_upgrade = _button(drill, "Améliorer la foreuse", "DrillUpgrade")
    _drill_upgrade.pressed.connect(_upgrade_drill)
    _dig_info = _label(drill, "", 14, Style.MUTED)
    _dig_progress = _progress(drill, "ExcavationProgress")
    _dig = _button(drill, "", "ExcavationStart")
    _dig.pressed.connect(_start_excavation)
    var right := VBoxContainer.new()
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.size_flags_stretch_ratio = 2.0
    right.add_theme_constant_override("separation", 16)
    _columns.add_child(right)
    _label(right, "02  /  EXTRACTION CONTINUE", 15, Style.MUTED)
    _mine_row = BoxContainer.new()
    right.add_child(_mine_row)
    for id in Catalog.MINES:
        var box := _card(_mine_row, 12)
        _label(box, Catalog.RESOURCES[id]["label"], 20)
        var info := _label(box, "", 15, Style.ACCENT)
        var cost := _label(box, "", 14, Style.MUTED)
        cost.custom_minimum_size.y = 42
        var upgrade := _button(box, "Améliorer", "MineUpgrade_" + id)
        upgrade.pressed.connect(_upgrade_mine.bind(id))
        _mines[id] = {"info": info, "cost": cost, "button": upgrade}
    _label(right, "03  /  TRANSFORMATION", 15, Style.MUTED)
    _factory_row = BoxContainer.new()
    right.add_child(_factory_row)
    _build_factory("furnace", "Fonderie", ["iron_ingot", "copper_ingot"], "Furnace")
    _build_factory("workshop", "Atelier", ["cable"], "Workshop")
    var help := _card(right, 12)
    _label(help, "CAP SUR LE PROCHAIN HORIZON", 14, Style.ACCENT)
    _label(help, "Les mines produisent en continu. Lance des lots pour préparer ta prochaine amélioration.", 15, Style.MUTED)
    _label(help, "Chaque palier de 30 m augmente le débit des mines de 15 %. Une foreuse renforcée ouvre les horizons suivants.", 14, Style.MUTED)
    _save_status = _label(page, "", 13, Style.MUTED)
    _save_status.name = "SaveStatus"

func _build_factory(facility: String, title: String, recipes: Array, prefix: String) -> void:
    var box := _card(_factory_row)
    _label(box, title, 21)
    var select := OptionButton.new()
    select.name = prefix + "Recipe"
    select.custom_minimum_size.y = 40
    select.fit_to_longest_item = false
    for recipe in recipes:
        select.add_item(Catalog.RECIPES[recipe]["label"])
    box.add_child(select)
    select.item_selected.connect(_selection_changed)
    var row := HBoxContainer.new()
    box.add_child(row)
    var caption := _label(row, "Quantité", 15, Style.MUTED)
    caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var quantity := SpinBox.new()
    quantity.name = prefix + "Quantity"
    quantity.min_value = 1
    quantity.max_value = 10
    quantity.value = 1
    quantity.custom_minimum_size = Vector2(92, 40)
    row.add_child(quantity)
    quantity.value_changed.connect(_quantity_changed)
    var cost := _label(box, "", 14, Style.COPPER)
    cost.custom_minimum_size.y = 38
    var state := _label(box, "", 14, Style.MUTED)
    state.custom_minimum_size.y = 36
    var progress := _progress(box, prefix + "Progress")
    var button := _button(box, "Lancer le lot", prefix + "Start")
    button.pressed.connect(_start_batch.bind(facility))
    _facilities[facility] = {"select": select, "quantity": quantity, "recipes": recipes, "cost": cost, "state": state, "progress": progress, "button": button}

func _refresh() -> void:
    var game = session.game
    _depth.text = "−%d m" % game.depth
    for id in _wallet:
        _wallet[id].text = str(floori(game.resources[id]))
    for id in _mines:
        var widgets: Dictionary = _mines[id]
        var maximum: bool = game.mine_levels[id] >= Catalog.MAX_MINE_LEVEL
        var affordable: bool = game.can_afford(game.mine_upgrade_cost(id))
        widgets["info"].text = "Niv. %d  ·  %.1f / min" % [game.mine_levels[id], game.mine_rate(id) * 60.0]
        widgets["cost"].text = "Niveau maximum" if maximum else "%s\n%s" % [_cost(game.mine_upgrade_cost(id)), "Amélioration disponible" if affordable else "Ressources insuffisantes"]
        widgets["button"].disabled = maximum or not affordable
    for facility in _facilities:
        var widgets: Dictionary = _facilities[facility]
        var recipe: String = widgets["recipes"][widgets["select"].selected]
        var quantity := int(widgets["quantity"].value)
        var definition: Dictionary = Catalog.RECIPES[recipe]
        var reason: String = game.batch_block_reason(recipe, quantity)
        widgets["cost"].text = "%s\n%d × %s · %s" % [_cost(definition["inputs"], quantity), quantity, definition["label"], _duration(definition["seconds"] * quantity)]
        widgets["button"].disabled = reason != ""
        widgets["progress"].value = 0
        if game.jobs.has(facility):
            var job: Dictionary = game.jobs[facility]
            widgets["state"].text = "%d × %s\nEn cours · reste %s" % [job["quantity"], Catalog.RECIPES[job["recipe"]]["label"], _duration(job["remaining"])]
            widgets["progress"].value = _percent(job)
        else:
            widgets["state"].text = "Prêt à produire" if reason == "" else reason
    var maximum: bool = game.drill_level >= Catalog.MAX_DRILL_LEVEL
    var affordable: bool = game.can_afford(game.drill_upgrade_cost())
    _drill_info.text = "Niveau %d / %d · Objectif : −%d m" % [game.drill_level, Catalog.MAX_DRILL_LEVEL, game.depth + 10]
    _drill_cost.text = "Niveau maximum" if maximum else "%s\n%s" % [_cost(game.drill_upgrade_cost()), "Amélioration disponible" if affordable else "Ressources insuffisantes"]
    _drill_upgrade.disabled = maximum or not affordable
    var reason: String = game.excavation_block_reason()
    _dig.disabled = reason != ""
    _dig.text = "Ouvrir le chantier · %s" % _duration(game.excavation_duration())
    _dig_progress.value = 0
    if game.jobs.has("drill"):
        _dig_info.text = "Forage en cours · reste %s" % _duration(game.jobs["drill"]["remaining"])
        _dig_progress.value = _percent(game.jobs["drill"])
    else:
        _dig_info.text = "Chantier disponible · +10 m" if reason == "" else reason
    _overview.set_progress(game.depth, game.drill_level, game.jobs.get("drill", {}))

func _refresh_notices() -> void:
    _save_notice.visible = session.save_blocked or session.save_error != ""
    if session.save_blocked:
        _save_notice.text = "Sauvegarde : %s\nLa sauvegarde d'origine est préservée. La progression de cette session provisoire ne sera pas enregistrée." % session.save_error
        _save_status.text = "Enregistrement désactivé · Session provisoire."
    elif session.save_error != "":
        _save_notice.text = "Sauvegarde : %s\nNouvelle tentative automatique. La progression récente n'est pas encore enregistrée." % session.save_error
        _save_status.text = "Enregistrement en attente · Nouvelle tentative automatique."
    else:
        _save_notice.text = ""
        _save_status.text = "Progression enregistrée automatiquement · Les mines restent actives pendant ton absence."
    _offline.visible = session.offline_seconds >= 5.0
    if _offline.visible:
        var report: Dictionary = session.offline_report
        var completed: Array = report.get("completed", [])
        _offline.text = "Bon retour · %s d'absence\nRécolté : %s · %d travaux terminés · +%d m" % [_duration(session.offline_seconds), _cost(report.get("produced", {})), completed.size(), report.get("depth_gained", 0)]

func _responsive() -> void:
    if _columns == null:
        return
    var narrow := size.x < 1000
    _columns.vertical = narrow
    _wallet_grid.columns = 3 if narrow else 6
    _mine_row.vertical = size.x < 620
    _factory_row.vertical = size.x < 620

func _cost(cost: Dictionary, multiplier: int = 1) -> String:
    var parts := PackedStringArray()
    for id in cost:
        parts.append("%d %s" % [floori(float(cost[id]) * multiplier), Catalog.RESOURCES[id]["label"]])
    return " · ".join(parts) if not parts.is_empty() else "Aucune ressource"

func _duration(seconds: float) -> String:
    var rounded := ceili(seconds)
    if rounded >= 3600:
        return "%d h %02d min" % [rounded / 3600, (rounded % 3600) / 60]
    if rounded >= 60:
        return "%d min %02d s" % [rounded / 60, rounded % 60]
    return "%d s" % rounded

func _percent(job: Dictionary) -> float:
    return 100.0 * (1.0 - float(job["remaining"]) / float(job["duration"]))

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

func _progress(parent: Node, node_name: String) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.name = node_name
    bar.custom_minimum_size.y = 8
    bar.show_percentage = false
    parent.add_child(bar)
    return bar

func _selection_changed(_index: int) -> void:
    _refresh()

func _quantity_changed(_value: float) -> void:
    _refresh()

func _start_batch(facility: String) -> void:
    var widgets: Dictionary = _facilities[facility]
    session.start_batch(widgets["recipes"][widgets["select"].selected], int(widgets["quantity"].value))

func _upgrade_mine(id: String) -> void:
    session.upgrade_mine(id)

func _upgrade_drill() -> void:
    session.upgrade_drill()

func _start_excavation() -> void:
    session.start_excavation()
