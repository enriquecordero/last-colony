extends Node

# Procedural ambient music via AudioStreamGenerator.
# Modes: MENU, BUILD, WAVE, BOSS — call set_mode() to transition.

enum Mode { MENU, BUILD, WAVE, BOSS, SILENT }

const SAMPLE_RATE := 22050.0
const VOLUME_DB   := -10.0

var _player:  AudioStreamPlayer = null
var _pb:      AudioStreamGeneratorPlayback = null
var _mode:    int   = Mode.SILENT
var _target_mode: int = Mode.SILENT
var _blend:   float = 0.0    # 0 = fully _mode, 1 = fully _target_mode
var _t:       float = 0.0

# Per-oscillator phase accumulators [mode0_oscs..., mode1_oscs...]
var _phases_a: Array = []
var _phases_b: Array = []


func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate      = SAMPLE_RATE
	gen.buffer_length = 0.15
	_player = AudioStreamPlayer.new()
	_player.stream    = gen
	_player.volume_db = VOLUME_DB
	add_child(_player)
	_player.play()
	_pb = _player.get_stream_playback()
	_phases_a.resize(6)
	_phases_b.resize(6)
	for i in 6:
		_phases_a[i] = 0.0
		_phases_b[i] = 0.0


func set_mode(mode: int) -> void:
	if mode == _target_mode:
		return
	# Swap: old target becomes current with current blend mix, start fading to new
	_mode         = _target_mode
	_target_mode  = mode
	_blend        = 1.0 - _blend
	# Reset phase B for fresh start on incoming mode
	for i in _phases_b.size():
		_phases_b[i] = 0.0


func _process(delta: float) -> void:
	_t += delta
	# Smoothly blend modes
	var blend_spd := 1.2
	if _blend < 1.0:
		_blend = minf(_blend + delta * blend_spd, 1.0)
		if _blend >= 1.0:
			_mode    = _target_mode
			_blend   = 1.0
			_phases_a = _phases_b.duplicate()

	if _pb == null or not _player.playing:
		return

	var frames := _pb.get_frames_available()
	var inv_sr := 1.0 / SAMPLE_RATE
	for _i in frames:
		var s := 0.0
		if _blend < 1.0:
			var sa := _sample_mode(_mode,        _phases_a, _t)
			var sb := _sample_mode(_target_mode, _phases_b, _t)
			s = lerpf(sa, sb, _blend)
		else:
			s = _sample_mode(_mode, _phases_a, _t)
		_t += inv_sr
		_pb.push_frame(Vector2(s, s))


func _sample_mode(mode: int, phases: Array, t: float) -> float:
	var s := 0.0
	match mode:
		Mode.MENU:
			# Calm A-minor drone — slow evolving
			var lfo1: float = 0.55 + 0.45 * sin(t * 0.14)
			var lfo2: float = 0.55 + 0.45 * sin(t * 0.19 + 1.3)
			s += _osc(phases, 0, 55.0)   * 0.14 * lfo1
			s += _osc(phases, 1, 82.5)   * 0.065 * lfo2
			s += _osc(phases, 2, 110.0)  * 0.038 * lfo1
			s += _osc(phases, 3, 165.0)  * 0.022 * lfo2
			s += _osc(phases, 4, 220.0 + 18.0 * sin(t * 0.06)) * 0.012 * lfo1
			s += _osc(phases, 5, 27.5)   * 0.06  * lfo2

		Mode.BUILD:
			# Tense atmospheric — minor 2nd dissonance
			var lfo: float = 0.52 + 0.48 * sin(t * 0.28)
			s += _osc(phases, 0, 55.0)   * 0.12 * lfo
			s += _osc(phases, 1, 58.27)  * 0.07  # half-step above — tension
			s += _osc(phases, 2, 110.0)  * 0.05 * lfo
			s += _osc(phases, 3, 146.8)  * 0.03
			s += _osc(phases, 4, 27.5)   * 0.08 * (1.0 - lfo)
			s += _osc(phases, 5, 220.0)  * 0.015

		Mode.WAVE:
			# Driving bass pulse at 2 Hz + harmonics
			var pulse: float = maxf(0.0, sin(t * TAU * 2.0))
			pulse = pulse * pulse  # square the envelope for snap
			s += _osc(phases, 0, 40.0)   * (0.16 + 0.14 * pulse)
			s += _osc(phases, 1, 55.0)   * (0.10 + 0.09 * pulse)
			s += _osc(phases, 2, 73.4)   * 0.055
			s += _osc(phases, 3, 110.0)  * (0.03 + 0.03 * pulse)
			var trem: float = 0.65 + 0.35 * sin(t * TAU * 5.0)
			s += _osc(phases, 4, 220.0)  * 0.018 * trem
			s += _osc(phases, 5, 27.5)   * (0.12 + 0.10 * pulse)
			# Soft clip for grit
			s = clampf(s * 1.2, -1.0, 1.0) * 0.85

		Mode.BOSS:
			# Heavy sub bass + pulsing dissonance + screech
			var pulse: float = maxf(0.0, sin(t * TAU * 2.5))
			pulse = pow(pulse, 1.5)
			var raw: float = _osc(phases, 0, 36.7) * (0.22 + 0.18 * pulse)
			s += clampf(raw * 1.6, -1.0, 1.0) * 0.65  # distort sub
			s += _osc(phases, 1, 55.0)   * (0.08 + 0.12 * pulse)
			s += _osc(phases, 2, 73.4)   * 0.06
			s += _osc(phases, 3, 110.0)  * (0.04 + 0.04 * pulse)
			var screech_lfo: float = 0.3 + 0.7 * abs(sin(t * 0.41))
			s += _osc(phases, 4, 293.7 + 15.0 * sin(t * 0.8)) * 0.022 * screech_lfo
			s += _osc(phases, 5, 27.5)   * (0.18 + 0.15 * pulse)
			s = clampf(s * 1.3, -1.0, 1.0) * 0.80

		Mode.SILENT:
			pass

	return clampf(s, -1.0, 1.0)


# Returns sin of oscillator i at its current phase, then advances phase.
func _osc(phases: Array, idx: int, freq: float) -> float:
	var ph: float = phases[idx]
	var v  := sin(TAU * ph)
	phases[idx] = fmod(ph + freq / SAMPLE_RATE, 1.0)
	return v
