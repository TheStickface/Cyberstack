class_name TestBalanceExporter
extends RefCounted

const DataRepoScript = preload("res://src/systems/DataRepository.gd")
const BalanceExporterScript = preload("res://src/tools/BalanceExporter.gd")

var repo: Object

func _init() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")

func test_balance_markdown_generation() -> Dictionary:
	var md = BalanceExporterScript.generate_markdown_matrix(repo)
	
	if md.is_empty():
		return {"passed": false, "message": "Generated balance matrix is empty", "assertions": 1}
	if not md.contains("Operative Roster"):
		return {"passed": false, "message": "Missing Operative Roster table in manifest", "assertions": 2}
	if not md.contains("Augment Gear Catalog"):
		return {"passed": false, "message": "Missing Augment Catalog table in manifest", "assertions": 3}
	if not md.contains("District Progression"):
		return {"passed": false, "message": "Missing District Progression table in manifest", "assertions": 4}
	if not md.contains("Faction Trait Thresholds"):
		return {"passed": false, "message": "Missing Faction Thresholds section in manifest", "assertions": 5}
	if not md.contains("runner_blitz") or not md.contains("common_kinetic_accelerator"):
		return {"passed": false, "message": "Expected resource IDs not found in table rows", "assertions": 6}
		
	return {"passed": true, "assertions": 6}
