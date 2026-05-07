extends Node

var _players: Dictionary = {}

func _ready() -> void:
	_add("shoot",   880.0, 660.0,  0.055, 0.28)
	_add("death",   420.0, 100.0,  0.18,  0.52)
	_add("damage",  130.0,  90.0,  0.13,  0.60)
	_add("wave",    200.0, 520.0,  0.38,  0.42)
	_add("wave2",   520.0, 260.0,  0.22,  0.35)
	_add("explode",  55.0,  18.0,  0.45,  1.00)
	_add("spawn",   310.0,  75.0,  0.20,  0.42)

func play(key: String) -> void:
	if _players.has(key):
		_players[key].play()

func play_wave() -> void:
	play("wave")
	await get_tree().create_timer(0.3).timeout
	play("wave2")

func _add(key: String, f1: float, f2: float, dur: float, vol: float) -> void:
	var p := AudioStreamPlayer.new()
	p.stream     = _gen(f1, f2, dur, vol)
	p.volume_db  = -6.0
	add_child(p)
	_players[key] = p

func _gen(f1: float, f2: float, dur: float, vol: float) -> AudioStreamWAV:
	const SR := 22050
	var wav  := AudioStreamWAV.new()
	wav.format   = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SR
	wav.stereo   = false
	var n    := int(SR * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t    := float(i) / float(n)
		var freq := lerpf(f1, f2, t)
		var env  := minf(t * 15.0, 1.0) * (1.0 - t)
		var s    := sin(TAU * phase) * vol * env
		data.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
		phase = fmod(phase + freq / SR, 1.0)
	wav.data = data
	return wav
