extends Node

## Centralized Audio Manager & Procedural Synth Audio Generator

enum SoundType {
	UI_CLICK,
	UI_HOVER,
	AUGMENT_SLOT,
	AUGMENT_UNSLOT,
	PURCHASE,
	REROLL,
	LOCK_IN,
	VICTORY,
	DEFEAT
}

var master_volume: float = 1.0
var sfx_volume: float = 1.0
var sfx_players: Array[AudioStreamPlayer] = []
var max_concurrent_players: int = 8

func _ready() -> void:
	for i in range(max_concurrent_players):
		var player = AudioStreamPlayer.new()
		add_child(player)
		sfx_players.append(player)

func play_sound(sound_type: SoundType) -> void:
	var stream = _generate_synth_sound(sound_type)
	if stream == null:
		return
		
	var player = _get_available_player()
	if player:
		player.stream = stream
		player.volume_db = linear_to_db(master_volume * sfx_volume)
		if is_inside_tree() and player.is_inside_tree():
			player.play()

func play_ui_click() -> void:
	play_sound(SoundType.UI_CLICK)

func play_ui_hover() -> void:
	play_sound(SoundType.UI_HOVER)

func play_augment_slot() -> void:
	play_sound(SoundType.AUGMENT_SLOT)

func play_augment_unslot() -> void:
	play_sound(SoundType.AUGMENT_UNSLOT)

func play_purchase() -> void:
	play_sound(SoundType.PURCHASE)

func play_reroll() -> void:
	play_sound(SoundType.REROLL)

func play_lock_in() -> void:
	play_sound(SoundType.LOCK_IN)

func play_victory() -> void:
	play_sound(SoundType.VICTORY)

func play_defeat() -> void:
	play_sound(SoundType.DEFEAT)

func _get_available_player() -> AudioStreamPlayer:
	for p in sfx_players:
		if not p.playing:
			return p
	return sfx_players[0]

## Generates procedural PCM wav synth sounds for cyberpunk audio feedback
func _generate_synth_sound(sound_type: SoundType) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var duration = 0.08
	var base_freq = 440.0
	var sweep_freq = 440.0
	
	match sound_type:
		SoundType.UI_CLICK:
			duration = 0.04
			base_freq = 1200.0
			sweep_freq = 600.0
		SoundType.UI_HOVER:
			duration = 0.02
			base_freq = 2400.0
			sweep_freq = 2000.0
		SoundType.AUGMENT_SLOT:
			duration = 0.14
			base_freq = 520.0
			sweep_freq = 1040.0
		SoundType.AUGMENT_UNSLOT:
			duration = 0.10
			base_freq = 880.0
			sweep_freq = 320.0
		SoundType.PURCHASE:
			duration = 0.16
			base_freq = 660.0
			sweep_freq = 1320.0
		SoundType.REROLL:
			duration = 0.12
			base_freq = 350.0
			sweep_freq = 700.0
		SoundType.LOCK_IN:
			duration = 0.30
			base_freq = 220.0
			sweep_freq = 110.0
		SoundType.VICTORY:
			duration = 0.35
			base_freq = 523.25
			sweep_freq = 1046.50
		SoundType.DEFEAT:
			duration = 0.40
			base_freq = 300.0
			sweep_freq = 75.0
			
	var sample_count = int(duration * wav.mix_rate)
	var data = PackedByteArray()
	data.resize(sample_count * 2) # 16-bit = 2 bytes per sample
	
	for i in range(sample_count):
		var t = float(i) / float(wav.mix_rate)
		var progress = float(i) / float(sample_count)
		var freq = lerp(base_freq, sweep_freq, progress)
		
		# Envelope (fast attack, linear decay)
		var env = 1.0 - progress
		if progress < 0.1:
			env = progress / 0.1
			
		# Waveform (square / sine blend for synth texture)
		var val = sin(t * freq * TAU)
		if sound_type == SoundType.LOCK_IN or sound_type == SoundType.DEFEAT:
			val = sign(val) * 0.7 # Square wave distortion
			
		var sample_val = int(clamp(val * env * 0.5, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav
