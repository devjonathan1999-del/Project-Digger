class_name IndustryIcons
extends RefCounted

# Small vector pictograms remain sharp at every UI scale and need no imported atlas.
static var _cache: Dictionary = {}

static func texture(id: String) -> Texture2D:
    if _cache.has(id):
        return _cache[id]
    var shapes := {
        "iron": '<path fill="#8e9da7" stroke="#d5dce0" d="M5 23 8 11 19 4 28 13 25 27 13 30Z"/><path fill="#596974" d="m8 11 11-7-6 15-8 4Zm5 8 15-6-3 14-12 3Z"/>',
        "coal": '<path fill="#29333d" stroke="#83919b" d="m3 23 5-13 10-6 11 8-2 13-13 5Z"/><path fill="#48545e" d="m8 10 10-6-4 13-11 6Zm6 7 15-5-2 13Z"/>',
        "copper": '<path fill="#db8547" stroke="#ffc88a" d="m4 23 4-12 11-7 10 10-5 14-12 2Z"/><path fill="#a95d30" d="m8 11 11-7-6 15-9 4Zm5 8 16-5-5 14Z"/>',
        "iron_ingot": '<path fill="#a8afb0" stroke="#d8dedb" d="m3 19 18-10 9 5-18 11Z"/><path fill="#64737c" d="m3 19 9 6v5l-9-6Zm9 6 18-11v5L12 30Z"/>',
        "copper_ingot": '<path fill="#eea26b" stroke="#ffd2a4" d="m3 19 18-10 9 5-18 11Z"/><path fill="#b96537" d="m3 19 9 6v5l-9-6Zm9 6 18-11v5L12 30Z"/>',
        "cable": '<g fill="#1b2932" stroke="#84959e" stroke-width="2"><ellipse cx="16" cy="23" rx="12" ry="5"/><ellipse cx="16" cy="19" rx="12" ry="5"/><ellipse cx="16" cy="15" rx="12" ry="5"/><ellipse cx="16" cy="11" rx="12" ry="5"/><ellipse cx="16" cy="11" rx="5" ry="2"/></g>',
        "crystal": '<path fill="#50c7d2" stroke="#b4f3f2" d="m16 2 7 10-2 13-5 6-8-11 1-10Z"/><path fill="#238b9f" d="m16 2-1 18 1 11 5-6 2-13Z"/><path fill="#87e2df" d="m3 12 7 5 6 14-9-6Z"/>',
        "mine": '<path fill="none" stroke="#d7b47d" stroke-width="3" stroke-linecap="round" d="M7 4q16-2 21 12M19 7 5 28"/><path fill="#d7b47d" d="m8 3-4 6 13-2Z"/>',
        "industry": '<path fill="#9caeb6" d="M3 29V17l8-6v8l8-6v6h10v10ZM22 4h5v15h-5Z"/><path fill="#18242d" d="M7 22h4v4H7Zm9 0h4v4h-4Zm8 0h3v4h-3Z"/>',
        "center": '<path fill="none" stroke="#a3b4bc" stroke-width="2" d="m16 3 12 7v14l-12 7-12-7V10Zm0 0v14m-12-7 12 7 12-7M16 17v14"/>',
        "technology": '<path fill="none" stroke="#a3b4bc" stroke-width="2.5" stroke-linejoin="round" d="M11 3h10m-8 0v10L4 29h24l-9-16V3M9 23h14"/><path fill="#d7b47d" d="m15 16-4 6h10l-4-6Z"/>',
    }
    var body: String = shapes.get(id, shapes["mine"])
    var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">' + body + '</svg>'
    var image := Image.new()
    if image.load_svg_from_string(svg) != OK:
        return null
    var result := ImageTexture.create_from_image(image)
    _cache[id] = result
    return result
