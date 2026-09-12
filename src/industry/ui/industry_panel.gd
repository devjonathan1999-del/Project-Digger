class_name IndustryPanel
extends VBoxContainer

const Catalog = preload("res://src/industry/industry_catalog.gd")
const Style = preload("res://src/industry/ui/industry_theme.gd")
var session
var _mines: Dictionary = {}
var _facilities: Dictionary = {}
var _inventory: Dictionary = {}
var _search: LineEdit
var _accessible: CheckButton
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
    name = "IndustryPanel"
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_theme_constant_override("separation", 14)
    _label(self, "INDUSTRIE", 22)
    var extraction := VBoxContainer.new()
    extraction.name = "ExtractionSection"
    extraction.add_theme_constant_override("separation", 12)
    add_child(extraction)
    _label(extraction, "EXTRACTION CONTINUE", 16, Style.ACCENT)
    for id in Catalog.mine_definitions():
        var box := _card(extraction)
        _label(box, Catalog.RESOURCES[id]["label"], 18)
        var info := _label(box, "", 14)
        var cost := _label(box, "", 13, Style.MUTED)
        var button := _button(box, "Améliorer", "MineUpgrade_" + id)
        button.pressed.connect(_upgrade_mine.bind(id))
        _mines[id] = {"info": info, "cost": cost, "button": button}
    _label(self, "PRODUCTION", 18, Style.ACCENT)
    _search = LineEdit.new()
    _search.name = "RecipeSearch"
    _search.placeholder_text = "Rechercher recette ou ingrédient"
    _search.custom_minimum_size.y = 44
    add_child(_search)
    _search.text_changed.connect(_filter_changed)
    _accessible = CheckButton.new()
    _accessible.name = "AccessibleRecipes"
    _accessible.text = "Recettes accessibles à cette profondeur"
    _accessible.custom_minimum_size.y = 44
    add_child(_accessible)
    _accessible.toggled.connect(_accessible_changed)
    for facility in Catalog.FACILITIES:
        var definition: Dictionary = Catalog.FACILITIES[facility]
        var prefix := str(definition["prefix"])
        var box := _card(self)
        _label(box, definition["label"], 19)
        var select := OptionButton.new()
        select.name = prefix + "Recipe"
        select.fit_to_longest_item = false
        select.custom_minimum_size.y = 44
        box.add_child(select)
        var recipes: Array = []
        for id in Catalog.RECIPES:
            if Catalog.RECIPES[id]["facility"] == facility:
                recipes.append(id)
                select.add_item("Palier %d · %s" % [int(Catalog.RECIPES[id].get("tier", 1)), Catalog.RECIPES[id]["label"]])
        select.item_selected.connect(_selection_changed.bind(facility))
        var row := HBoxContainer.new()
        box.add_child(row)
        _label(row, "Lots", 14, Style.MUTED)
        var quantity := SpinBox.new()
        quantity.name = prefix + "Quantity"
        quantity.min_value = 1
        quantity.max_value = 10
        quantity.value = 1
        quantity.custom_minimum_size = Vector2(92, 44)
        row.add_child(quantity)
        quantity.value_changed.connect(_quantity_changed)
        var cost := _label(box, "", 13, Style.COPPER)
        var state := _label(box, "", 13, Style.MUTED)
        var progress := ProgressBar.new()
        progress.name = prefix + "Progress"
        progress.custom_minimum_size.y = 8
        progress.show_percentage = false
        box.add_child(progress)
        var button := _button(box, "Lancer le lot", prefix + "Start")
        button.pressed.connect(_start_batch.bind(facility))
        _facilities[facility] = {"select": select, "quantity": quantity, "recipes": recipes.duplicate(), "all_recipes": recipes, "selected_recipe": str(recipes[0]) if not recipes.is_empty() else "", "cost": cost, "state": state, "progress": progress, "button": button}
    move_child(extraction, get_child_count() - 1)
    _label(self, "INVENTAIRE", 18, Style.ACCENT)
    var inventory := _card(self)
    inventory.name = "IndustryInventory"
    for id in Catalog.RESOURCES:
        var amount := _label(inventory, "", 14)
        amount.name = "Inventory_" + id
        _inventory[id] = amount

func refresh() -> void:
    if session == null or not _built:
        return
    var game = session.game
    var mines: Dictionary = Catalog.mine_definitions()
    for id in _mines:
        var widgets: Dictionary = _mines[id]
        var locked: bool = game.depth < int(mines[id].get("depth", 0))
        var maximum: bool = game.mine_levels[id] >= Catalog.MAX_MINE_LEVEL
        var affordable: bool = game.can_afford(game.mine_upgrade_cost(id))
        widgets["info"].text = "Niv. %d · %.1f / min" % [game.mine_levels[id], game.mine_rate(id) * 60.0]
        widgets["cost"].text = "Accessible à −%d m" % mines[id]["depth"] if locked else ("Niveau maximum" if maximum else _cost(game.mine_upgrade_cost(id)))
        widgets["button"].disabled = locked or maximum or not affordable
    for id in _inventory:
        _inventory[id].text = "%s : %.1f" % [Catalog.RESOURCES[id]["label"], float(game.resources.get(id, 0))]
    for facility in _facilities:
        var w: Dictionary = _facilities[facility]
        _update_options(w)
        var index: int = w["select"].selected
        var recipe: String = str(w["recipes"][index]) if index >= 0 and index < w["recipes"].size() else ""
        var reason := "Aucune recette sélectionnée"
        if recipe == "":
            w["cost"].text = "Aucune recette ne correspond au filtre."
        else:
            var d: Dictionary = Catalog.RECIPES[recipe]
            var quantity := int(w["quantity"].value)
            reason = game.batch_block_reason(recipe, quantity)
            w["cost"].text = "%s\n%d lots → %d × %s · %s\nAccessible à −%d m" % [_cost(d["inputs"], quantity), quantity, quantity * int(d.get("yield", 1)), Catalog.RESOURCES[d["output"]]["label"], _duration(d["seconds"] * quantity), int(d.get("depth", 0))]
        w["button"].disabled = reason != ""
        w["progress"].value = 0
        if game.jobs.has(facility):
            var job: Dictionary = game.jobs[facility]
            w["state"].text = "%d lots · %s\nEn cours · reste %s" % [job["quantity"], Catalog.RECIPES[job["recipe"]]["label"], _duration(job["remaining"])]
            w["progress"].value = 100.0 * (1.0 - float(job["remaining"]) / float(job["duration"]))
        else:
            w["state"].text = "Prêt à produire" if reason == "" else reason

func _update_options(w: Dictionary) -> void:
    var select: OptionButton = w["select"]
    var previous: String = w["selected_recipe"]
    var recipes: Array = []
    var query := _search.text.strip_edges().to_lower()
    for id in w["all_recipes"]:
        var d: Dictionary = Catalog.RECIPES[id]
        if _accessible.button_pressed and session.game.depth < int(d.get("depth", 0)):
            continue
        var text := str(d["label"]).to_lower()
        for resource in d["inputs"]:
            text += " " + str(Catalog.RESOURCES[resource]["label"]).to_lower()
        if query == "" or text.contains(query):
            recipes.append(id)
    if recipes == w["recipes"]:
        return
    w["selected_recipe"] = previous
    w["recipes"] = recipes
    select.clear()
    for id in recipes:
        select.add_item("Palier %d · %s" % [int(Catalog.RECIPES[id].get("tier", 1)), Catalog.RECIPES[id]["label"]])
    if not recipes.is_empty():
        select.select(maxi(0, recipes.find(previous)))
    select.disabled = recipes.is_empty()

func _responsive() -> void:
    pass

func _start_batch(facility: String) -> void:
    if session == null:
        return
    var w: Dictionary = _facilities[facility]
    var index: int = w["select"].selected
    if index >= 0 and index < w["recipes"].size():
        session.start_batch(w["recipes"][index], int(w["quantity"].value))

func _upgrade_mine(id: String) -> void:
    if session != null:
        session.upgrade_mine(id)

func _selection_changed(index: int, facility: String) -> void:
    var widgets: Dictionary = _facilities[facility]
    if index >= 0 and index < widgets["recipes"].size():
        widgets["selected_recipe"] = widgets["recipes"][index]
    refresh()
func _quantity_changed(_value: float) -> void:
    refresh()
func _filter_changed(_text: String) -> void:
    refresh()
func _accessible_changed(_pressed: bool) -> void:
    refresh()

func _cost(cost: Dictionary, multiplier: int = 1) -> String:
    var parts := PackedStringArray()
    for id in cost:
        parts.append("%s : %.1f / %d" % [Catalog.RESOURCES[id]["label"], float(session.game.resources.get(id, 0)) if session != null else 0.0, int(cost[id]) * multiplier])
    return " · ".join(parts) if not parts.is_empty() else "Aucun coût"
func _duration(seconds: float) -> String:
    var rounded := ceili(seconds)
    return "%d min %02d s" % [rounded / 60, rounded % 60] if rounded >= 60 else "%d s" % rounded
func _card(parent: Node) -> VBoxContainer:
    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", Style.panel(Style.PANEL, Color("294052"), 12))
    parent.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    panel.add_child(box)
    return box
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
    button.custom_minimum_size.y = 44
    parent.add_child(button)
    return button
