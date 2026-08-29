extends SceneTree

## Headless Unit Test Runner for Cyberstack

var tests_passed: int = 0
var tests_failed: int = 0
var assertions_passed: int = 0
var assertions_failed: int = 0

func _init() -> void:
	print("\n========================================================")
	print("          CYBERSTACK AUTOMATED TEST SUITE               ")
	print("========================================================\n")
	
	var test_files = [
		"res://tests/test_synergy_engine.gd",
		"res://tests/test_crew_validator.gd",
		"res://tests/test_data_integrity.gd",
		"res://tests/test_shop_manager.gd",
		"res://tests/test_crew_manager.gd",
		"res://tests/test_run_manager.gd",
		"res://tests/test_event_system.gd",
		"res://tests/test_game_manager.gd",
		"res://tests/test_save_system.gd",
		"res://tests/test_meta_manager.gd",
		"res://tests/test_audio_and_shaders.gd",
		"res://tests/test_debug_console.gd",
		"res://tests/test_balance_exporter.gd",
		"res://tests/test_telemetry_analytics.gd",
		"res://tests/test_balance_simulator.gd",
		"res://tests/test_ui_dimensions.gd",
		"res://tests/test_district_thematics.gd",
		"res://tests/test_tactical_grid.gd",
		"res://tests/test_tactical_drag_and_tethers.gd",
		"res://tests/test_description_formatting.gd"
	]


	
	for file_path in test_files:
		_run_test_file(file_path)
		
	print("\n========================================================")
	print("TEST RESULTS:")
	print("  Test Suites Run: %d" % (tests_passed + tests_failed))
	print("  Passed: %d | Failed: %d" % [tests_passed, tests_failed])
	print("  Assertions: %d Passed | %d Failed" % [assertions_passed, assertions_failed])
	print("========================================================\n")
	
	if tests_failed > 0 or assertions_failed > 0:
		quit(1)
	else:
		print(">> ALL TESTS PASSED SUCCESSFULLY! <<\n")
		quit(0)

func _run_test_file(file_path: String) -> void:
	var script = load(file_path)
	if not script:
		printerr("[FAIL] Could not load test script: %s" % file_path)
		tests_failed += 1
		return
		
	var test_obj = script.new()
	var test_name = file_path.get_file().get_basename()
	print("[SUITE] %s" % test_name)
	
	var methods = test_obj.get_method_list()
	var file_has_failure = false
	
	for method in methods:
		var m_name: String = method["name"]
		if m_name.begins_with("test_"):
			var result = test_obj.call(m_name)
			if result is Dictionary:
				var passed = result.get("passed", false)
				var msg = result.get("message", "")
				var count = result.get("assertions", 1)
				if passed:
					assertions_passed += count
					print("  [PASS] %s" % m_name)
				else:
					assertions_failed += count
					file_has_failure = true
					printerr("  [FAIL] %s - %s" % [m_name, msg])
			else:
				assertions_passed += 1
				print("  [PASS] %s" % m_name)
				
	if file_has_failure:
		tests_failed += 1
	else:
		tests_passed += 1
