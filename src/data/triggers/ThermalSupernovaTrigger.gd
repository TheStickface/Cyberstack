class_name ThermalSupernovaTrigger
extends RefCounted

## Trigger script: Melts 40% of target armor and burns for thermal damage on ability cast

static func on_ability_cast(caster_stats: Dictionary, target: Dictionary) -> void:
	if target.has("armor"):
		target["armor"] = maxf(0.0, float(target["armor"]) * 0.6)
	if target.has("hp"):
		target["hp"] = maxf(0.0, float(target["hp"]) - 35.0)
