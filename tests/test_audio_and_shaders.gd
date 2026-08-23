class_name TestAudioAndShaders
extends RefCounted

const AudioManagerScript = preload("res://src/core/AudioManager.gd")
const CRTOverlayScene = preload("res://src/ui/components/CRTOverlay.tscn")

func test_shader_and_overlay() -> Dictionary:
	var overlay = CRTOverlayScene.instantiate()
	if overlay == null:
		return {"passed": false, "message": "Failed to instantiate CRTOverlay", "assertions": 1}
		
	if overlay.enabled:
		return {"passed": false, "message": "CRTOverlay should be disabled by default", "assertions": 2}
		
	var mat = overlay.material as ShaderMaterial
	if mat == null or mat.shader == null:
		return {"passed": false, "message": "CRTOverlay missing valid ShaderMaterial", "assertions": 3}
		
	# Test toggle
	var new_state = overlay.toggle_crt()
	if not new_state or not overlay.enabled:
		return {"passed": false, "message": "toggle_crt failed to enable overlay", "assertions": 4}
		
	overlay.queue_free()
	return {"passed": true, "assertions": 4}

func test_audio_manager_synth_generation() -> Dictionary:
	var audio_mgr = AudioManagerScript.new()
	audio_mgr._ready()
	
	# Test all sound types generate valid audio buffers
	for s_type in range(13):
		var wav = audio_mgr._generate_synth_sound(s_type)
		if wav == null:
			return {"passed": false, "message": "Failed to generate synth sound type %d" % s_type, "assertions": 1}
		if wav.data.is_empty():
			return {"passed": false, "message": "Synthesized audio data is empty for type %d" % s_type, "assertions": 2}
		if wav.mix_rate != 22050:
			return {"passed": false, "message": "Unexpected sample rate %d" % wav.mix_rate, "assertions": 3}
			
	# Test trigger methods
	audio_mgr.play_ui_click()
	audio_mgr.play_augment_slot()
	audio_mgr.play_purchase()
	audio_mgr.play_reroll()
	audio_mgr.play_lock_in()
	audio_mgr.play_victory()
	audio_mgr.play_defeat()
	audio_mgr.play_combat_hit()
	audio_mgr.play_combat_crit()
	audio_mgr.play_ability_cast()
	audio_mgr.play_star_upgrade()
	
	for p in audio_mgr.sfx_players:
		p.queue_free()
	audio_mgr.queue_free()
	
	return {"passed": true, "assertions": 10}
