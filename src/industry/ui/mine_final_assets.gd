extends RefCounted

const ROOT := "res://assets/industry/final/"
const FILES := {
    "rock": "rock.png", "surface": "surface.png", "shaft": "shaft.png",
    "iron_installation": "chambers.png", "coal_installation": "chambers.png",
    "copper_installation": "chambers.png", "crystal_installation": "chambers.png",
    "drill": "rigs.png", "elevator": "rigs.png",
    "copper_seam": "seams.png", "cyan_seam": "seams.png",
}
const REGIONS := {
    "copper_seam": Rect2(0.0, 0.27, 0.5, 0.44),
    "cyan_seam": Rect2(0.5, 0.27, 0.5, 0.44),
    "iron_installation": Rect2(0.0, 0.14, 0.5, 0.31),
    "coal_installation": Rect2(0.5, 0.14, 0.5, 0.31),
    "copper_installation": Rect2(0.0, 0.55, 0.5, 0.31),
    "crystal_installation": Rect2(0.5, 0.55, 0.5, 0.31),
    "elevator": Rect2(0.17, 0.20, 0.23, 0.71),
    "drill": Rect2(0.61, 0.10, 0.23, 0.87),
    "surface": Rect2(0.0, 0.0, 1.0, 0.825),
    "shaft": Rect2(0.11, 0.0, 0.78, 1.0),
}
static var _cache: Dictionary = {}
static var _sources: Dictionary = {}

static func has_asset(id: String) -> bool:
    return FILES.has(id) and (ResourceLoader.exists(ROOT + str(FILES[id])) or FileAccess.file_exists(ROOT + str(FILES[id])))

static func texture_for(id: String) -> Texture2D:
    if _cache.has(id):
        return _cache[id] as Texture2D
    if not has_asset(id):
        return null
    var path := ROOT + str(FILES[id])
    if not _sources.has(path):
        var source: Image
        if ResourceLoader.exists(path):
            var imported := load(path) as Texture2D
            if imported != null:
                source = imported.get_image()
                if source != null and source.is_compressed():
                    source.decompress()
        if source == null:
            source = Image.load_from_file(path)
        if source == null or source.is_empty():
            return null
        _sources[path] = source
    var image: Image = (_sources[path] as Image).duplicate()
    if REGIONS.has(id):
        var region: Rect2 = REGIONS[id]
        image = image.get_region(Rect2i(Vector2i(region.position * Vector2(image.get_size())), Vector2i(region.size * Vector2(image.get_size()))))
    if id.ends_with("_installation") or id.ends_with("_seam") or id in ["drill", "elevator"]:
        image = _import_sprite(image)
    var texture := ImageTexture.create_from_image(image)
    _cache[id] = texture
    return texture

static func _import_sprite(image: Image) -> Image:
    # Generated source atlases may include a preview matte. Import only the
    # neutral light background connected to the border, preserving enclosed
    # steel highlights and all cave interiors. Source PNGs remain untouched.
    image.convert(Image.FORMAT_RGBA8)
    var data := image.get_data()
    var width := image.get_width()
    var height := image.get_height()
    var visited := PackedByteArray()
    visited.resize(width * height)
    var queue := PackedInt32Array()
    for x in range(width):
        queue.append(x)
        queue.append((height - 1) * width + x)
    for y in range(1, height - 1):
        queue.append(y * width)
        queue.append(y * width + width - 1)
    var cursor := 0
    while cursor < queue.size():
        var pixel := queue[cursor]
        cursor += 1
        if visited[pixel] != 0:
            continue
        visited[pixel] = 1
        var offset := pixel * 4
        var low := mini(data[offset], mini(data[offset + 1], data[offset + 2]))
        var high := maxi(data[offset], maxi(data[offset + 1], data[offset + 2]))
        if data[offset + 3] != 0 and (low < 125 or high - low > 24):
            continue
        data[offset + 3] = 0
        var x := pixel % width
        var y := pixel / width
        if x > 0 and visited[pixel - 1] == 0:
            queue.append(pixel - 1)
        if x < width - 1 and visited[pixel + 1] == 0:
            queue.append(pixel + 1)
        if y > 0 and visited[pixel - width] == 0:
            queue.append(pixel - width)
        if y < height - 1 and visited[pixel + width] == 0:
            queue.append(pixel + width)
    return Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, data)
