class_name IndustryTheme
extends RefCounted

const BACKGROUND := Color("0b1219")
const PANEL := Color("17232d")
const ACCENT := Color("e6ad59")
const COPPER := Color("f2bd78")
const TEXT := Color("edf0ea")
const MUTED := Color("9cabb3")
const ROCK_SHALLOW := Color("343b40")
const ROCK_DENSE := Color("252f38")
const ROCK_CRYSTAL := Color("1b2933")
const ROCK_DEEP := Color("14212b")
const INDUSTRIAL_AMBER := Color("d59758")
const CRYSTAL_CYAN := Color("44d9d2")
const STEEL := Color("72848d")
const STEEL_DARK := Color("42545d")
const DEEP_TURQUOISE := Color("2fb7ad")
const ANOMALY_VIOLET := Color("b56cff")
const WORKER_DARK := Color("182129")
const WORKER_LIGHT := Color("b6c4c9")

static func panel(color: Color = PANEL, border: Color = Color("354650"), padding: int = 16) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border
    style.set_border_width_all(1)
    style.set_corner_radius_all(7)
    style.content_margin_left = padding
    style.content_margin_right = padding
    style.content_margin_top = padding
    style.content_margin_bottom = padding
    return style

static func create() -> Theme:
    var result := Theme.new()
    result.default_font_size = 16
    result.set_color("font_color", "Label", TEXT)
    result.set_color("font_color", "Button", TEXT)
    result.set_color("font_disabled_color", "Button", MUTED)
    result.set_stylebox("panel", "PanelContainer", panel())
    for type in ["Button", "OptionButton"]:
        result.set_stylebox("normal", type, panel(Color("182a35"), Color("435762"), 10))
        result.set_stylebox("hover", type, panel(Color("283a43"), ACCENT, 10))
        result.set_stylebox("pressed", type, panel(Color("584023"), ACCENT, 10))
        result.set_stylebox("disabled", type, panel(Color("141f28"), Color("2e3e48"), 10))
        result.set_stylebox("focus", type, panel(Color(0, 0, 0, 0), ACCENT, 0))
        result.set_color("font_color", type, TEXT)
    result.set_stylebox("normal", "LineEdit", panel(Color("0e1d2a"), Color("3e6374"), 10))
    result.set_stylebox("background", "ProgressBar", panel(Color("091823"), Color("354650"), 0))
    result.set_stylebox("fill", "ProgressBar", panel(ACCENT, ACCENT, 0))
    result.set_constant("separation", "VBoxContainer", 10)
    result.set_constant("separation", "HBoxContainer", 12)
    result.set_constant("h_separation", "GridContainer", 12)
    result.set_constant("v_separation", "GridContainer", 12)
    return result
