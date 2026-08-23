class_name TestCrewValidator
extends RefCounted

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var repo: Object

func _init() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")

func test_slot_type_restrictions() -> Dictionary:
	var sentinel_res = repo.get_unit("corp_sentinel") # Tank: Defensive, Defensive, Passive
	var sentinel = UnitInstance.new(sentinel_res)
	
	var offensive_aug = repo.get_augment("common_kinetic_accelerator") # Offensive
	var defensive_aug = repo.get_augment("common_thermal_core") # Defensive
	
	# Slot 0 is Defensive -> Offensive augment MUST fail
	var can_equip_wrong = sentinel.can_equip_augment(0, offensive_aug)
	if can_equip_wrong:
		return {"passed": false, "message": "Tank should not be able to equip Offensive augment in Defensive slot 0", "assertions": 1}
		
	# Slot 0 is Defensive -> Defensive augment MUST succeed
	var can_equip_right = sentinel.can_equip_augment(0, defensive_aug)
	if not can_equip_right:
		return {"passed": false, "message": "Tank should be able to equip Defensive augment in Defensive slot 0", "assertions": 2}
		
	var equip_ok = sentinel.equip_augment(0, defensive_aug)
	if not equip_ok:
		return {"passed": false, "message": "equip_augment failed for valid slot", "assertions": 3}
		
	return {"passed": true, "assertions": 3}

func test_district_size_limits() -> Dictionary:
	var blitz = UnitInstance.new(repo.get_unit("runner_blitz"))
	var ghost = UnitInstance.new(repo.get_unit("street_ghost"))
	var sentinel = UnitInstance.new(repo.get_unit("corp_sentinel"))
	
	var crew_valid: Array[UnitInstance] = [blitz, ghost]
	var res_1 = CrewValidator.validate_crew_size(crew_valid, 1)
	if not res_1.valid:
		return {"passed": false, "message": "District 1 should allow 2 units", "assertions": 1}
		
	var crew_invalid: Array[UnitInstance] = [blitz, ghost, sentinel]
	var res_2 = CrewValidator.validate_crew_size(crew_invalid, 1)
	if res_2.valid:
		return {"passed": false, "message": "District 1 should reject 3 units", "assertions": 2}
		
	# But District 2 should allow 3 units (limit is 4)
	var res_3 = CrewValidator.validate_crew_size(crew_invalid, 2)
	if not res_3.valid:
		return {"passed": false, "message": "District 2 should allow 3 units", "assertions": 3}
		
	return {"passed": true, "assertions": 3}

func test_full_crew_validation() -> Dictionary:
	var blitz = UnitInstance.new(repo.get_unit("runner_blitz"))
	var ghost = UnitInstance.new(repo.get_unit("street_ghost"))
	
	# Equip valid items
	blitz.equip_augment(0, repo.get_augment("common_thermal_core")) # Tank slot 0: Defensive
	ghost.equip_augment(0, repo.get_augment("common_kinetic_accelerator")) # Sniper slot 0: Offensive
	
	var crew: Array[UnitInstance] = [blitz, ghost]
	var report = CrewValidator.validate_crew(crew, 1)
	
	if not report.valid:
		return {"passed": false, "message": "Valid crew failed validation: %s" % str(report.errors), "assertions": 1}
		
	return {"passed": true, "assertions": 1}
