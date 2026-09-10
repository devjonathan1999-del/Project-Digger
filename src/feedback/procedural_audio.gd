class_name ProceduralAudio
extends RefCounted

const MIX_RATE := 22050

static func make_tone(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_8_BITS
    stream.mix_rate = MIX_RATE
    stream.stereo = false

    var sample_count: int = maxi(1, int(duration * float(MIX_RATE)))
    var bytes := PackedByteArray()
    bytes.resize(sample_count)
    var amplitude: float = clampf(volume, 0.0, 1.0) * 127.0
    for i in range(sample_count):
        var envelope: float = 1.0 - float(i) / float(sample_count)
        var sample: float = sin(TAU * frequency * float(i) / float(MIX_RATE)) * amplitude * envelope
        bytes[i] = int(clampf(sample + 128.0, 0.0, 255.0))
    stream.data = bytes
    return stream
