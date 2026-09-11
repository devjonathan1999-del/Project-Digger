class_name IndustryPanel
extends VBoxContainer

const Catalog = preload("res://src/industry/industry_catalog.gd")
const Style = preload("res://src/industry/ui/industry_theme.gd")

var session
var _mines: Dictionary = {}
var _facilities: Dictionary = {}
var _columns: BoxContainer
var _mine_row: BoxContainer
var _factory_row: BoxContainer
var _built := false

func _ready() -> void:
    _ensure_built()
    resized.connect(_responsive)
    _responsive()

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
    name = "IndustryPanel"
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_theme_constant_override("separation", 16)
    _label(self, "INDUSTRIE", 22)
    _label(self, "Extraction continue, fonderie et atelier", 14, Style.MUTED)

    _columns = BoxContainer.new()
    _columns.name = "ManagementColumns"
    _columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _columns.add_theme_constant_override("separation", 18)
    add_child(_columns)

    var extraction := VBoxContainer.new()
    extraction.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    extraction.add_theme_constant_override("separation", 12)
    _columns.add_child(extraction)
    _label(extraction, "EXTRACTION CONTINUE", 14, Style.MUTED)
    _mine_row = BoxContainer.new()
    _mine_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    extraction.add_child(_mine_row)
    for id in Catalog.MINES:
        var box := _card(_mine_row, 12)
        _label(box, Catalog.RESOURCES[id]["label"], 19)
        var info := _label(box, "", 14, Style.ACCENT)
        var cost := _label(box, "", 13, Style.MUTED)
        cost.custom_minimum_size.y = 40
        var upgrade := _button(box, "Améliorer", "MineUpgrade_" + id)
        upgrade.pressed.connect(_upgrade_mine.bind(id))
        _mines[id] = {"info": info, "cost": cost, "button": upgrade}

    var factory := VBoxContainer.new()
    factory.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    factory.add_theme_constant_override("separation", 12)
    _columns.add_child(factory)
    _label(factory, "TRANSFORMATION", 14, Style.MUTED)
    _factory_row = BoxContainer.new()
    _factory_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    factory.add_child(_factory_row)
    _build_factory("furnace", "Fonderie", ["iron_ingot", "copper_ingot"], "Furnace")
    _build_factory("workshop", "Atelier", ["cable"], "Workshop")

    var help := _card(self, 12)
    _label(help, "CAP SUR LE PROCHAIN HORIZON", 14, Style.ACCENT)
    _label(help, "Les mines produisent en continu. Lance des lots pour préparer les améliorations et l'exploration.", 14, Style.MUTED)

func refresh() -> void:
    if session == null or not _built:
        return
    var game = session.game
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

func _build_factory(facility: String, title: String, recipes: Array, prefix: String) -> void:
    var box := _card(_factory_row)
    _label(box, title, 19)
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
    var caption := _label(row, "Quantité", 14, Style.MUTED)
    caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var quantity := SpinBox.new()
    quantity.name = prefix + "Quantity"
    quantity.min_value = 1
    quantity.max_value = 10
    quantity.value = 1
    quantity.custom_minimum_size = Vector2(92, 40)
    row.add_child(quantity)
    quantity.value_changed.connect(_quantity_changed)
    var cost := _label(box, "", 13, Style.COPPER)
    cost.custom_minimum_size.y = 38
    var state := _label(box, "", 13, Style.MUTED)
    state.custom_minimum_size.y = 36
    var progress := _progress(box, prefix + "Progress")
    var button := _button(box, "Lancer le lot", prefix + "Start")
    button.pressed.connect(_start_batch.bind(facility))
    _facilities[facility] = {"select": select, "quantity": quantity, "recipes": recipes, "cost": cost, "state": state, "progress": progress, "button": button}

func _responsive() -> void:
    if _columns == null:
        return
    _columns.vertical = size.x < 1000
    _mine_row.vertical = size.x < 620
    _factory_row.vertical = size.x < 620

func _start_batch(facility: String) -> void:
    if session == null:
        return
    var widgets: Dictionary = _facilities[facility]
    session.start_batch(widgets["recipes"][widgets["select"].selected], int(widgets["quantity"].value))

func _upgrade_mine(id: String) -> void:
    if session != null:
        session.upgrade_mine(id)

func _selection_changed(_index: int) -> void:
    refresh()

func _quantity_changed(_value: float) -> void:
    refresh()

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
