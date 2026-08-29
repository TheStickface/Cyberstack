import os
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UNITS_DIR = os.path.join(ROOT, "data", "units")
DISTRICTS_DIR = os.path.join(ROOT, "data", "districts")

BOSSES = [
    {
        "id": "boss_slum_enforcer",
        "display_name": "Slum Enforcer",
        "title": "Slum Market Apex Enforcer",
        "bio": "A cyber-grafted heavyweight reigning over the neon bazaar with crushing kinetic force.",
        "role": 0, # TANK
        "faction": 1, # STREET_RUNNERS
        "base_cost": 5,
        "base_max_health": 950.0,
        "base_attack_damage": 45.0,
        "base_ability_power": 25.0,
        "base_attack_speed": 0.85,
        "base_armor": 30.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 40.0,
        "base_crit_chance": 0.05,
        "base_evasion": 0.05,
        "ability_name": "Shockwave Cleave",
        "ability_description": "Strikes the frontline for 180 damage and deploys a 250 HP kinetic barrier to self.",
        "ability_effect_id": "boss_shockwave_cleave"
    },
    {
        "id": "boss_corp_commander",
        "display_name": "Corp Commander",
        "title": "Arcology Security Overseer",
        "bio": "Elite corporate commander equipped with tactical targeting uplinks and high-altitude orbital lances.",
        "role": 2, # SNIPER
        "faction": 2, # CORP_ENFORCERS
        "base_cost": 5,
        "base_max_health": 800.0,
        "base_attack_damage": 65.0,
        "base_ability_power": 35.0,
        "base_attack_speed": 0.90,
        "base_armor": 25.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 55.0,
        "base_crit_chance": 0.20,
        "base_evasion": 0.10,
        "ability_name": "Orbital Lase",
        "ability_description": "Calls down an orbital strike dealing 320 piercing damage to the weakest enemy operative.",
        "ability_effect_id": "boss_orbital_lase"
    },
    {
        "id": "boss_ai_prime_overmind",
        "display_name": "Prime Overmind",
        "title": "Server Vault Sentient Core",
        "bio": "A rogue supercomputing entity capable of collapsing cyberware networks and neural pathways.",
        "role": 1, # HACKER
        "faction": 3, # ROGUE_AIS
        "base_cost": 5,
        "base_max_health": 850.0,
        "base_attack_damage": 35.0,
        "base_ability_power": 70.0,
        "base_attack_speed": 0.95,
        "base_armor": 20.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 50.0,
        "base_crit_chance": 0.05,
        "base_evasion": 0.08,
        "ability_name": "System Cascade",
        "ability_description": "Overloads hostile cyberware, dealing 200 AP damage to 2 enemies and draining 30 mana.",
        "ability_effect_id": "boss_system_cascade"
    },
    {
        "id": "boss_nemesis_synthetic",
        "display_name": "Nemesis Synthetic",
        "title": "Black Site Autonomous Apex",
        "bio": "Top-secret black site prototype fusing sentient machine intelligence with bleeding-edge chassis plating.",
        "role": 1, # HACKER
        "faction": 3, # ROGUE_AIS
        "base_cost": 5,
        "base_max_health": 1200.0,
        "base_attack_damage": 55.0,
        "base_ability_power": 80.0,
        "base_attack_speed": 1.05,
        "base_armor": 40.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 60.0,
        "base_crit_chance": 0.15,
        "base_evasion": 0.12,
        "ability_name": "Singularity Rupture",
        "ability_description": "Unleashes a catastrophic singularity burst dealing 280 AP damage across all enemies.",
        "ability_effect_id": "boss_singularity_rupture"
    },
    {
        "id": "boss_foundry_overseer",
        "display_name": "Foundry Overseer",
        "title": "Thermal Foundry Heavy Master",
        "bio": "Furnace boss clad in heat-sync armor plates capable of withstanding molten slag.",
        "role": 0, # TANK
        "faction": 1, # STREET_RUNNERS
        "base_cost": 5,
        "base_max_health": 1000.0,
        "base_attack_damage": 50.0,
        "base_ability_power": 40.0,
        "base_attack_speed": 0.80,
        "base_armor": 35.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 35.0,
        "base_crit_chance": 0.05,
        "base_evasion": 0.05,
        "ability_name": "Magma Surge",
        "ability_description": "Superheats the floor, dealing 150 damage and generating a 300 HP thermal shield.",
        "ability_effect_id": "boss_magma_surge"
    },
    {
        "id": "boss_railmaster",
        "display_name": "Railmaster",
        "title": "Kinetic Yards Scrapyard Sniper",
        "bio": "Veteran heavy railgunner whose magnetically accelerated slugs punch through titanium hulls.",
        "role": 2, # SNIPER
        "faction": 4, # FIXERS
        "base_cost": 5,
        "base_max_health": 850.0,
        "base_attack_damage": 70.0,
        "base_ability_power": 20.0,
        "base_attack_speed": 0.85,
        "base_armor": 30.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 50.0,
        "base_crit_chance": 0.25,
        "base_evasion": 0.08,
        "ability_name": "Hyperkinetic Railgun",
        "ability_description": "Fires a high-caliber slug dealing 350 damage that ignores 50% target armor.",
        "ability_effect_id": "boss_hyperkinetic_railgun"
    },
    {
        "id": "boss_mindbreaker",
        "display_name": "Mindbreaker",
        "title": "Neural Exchange Psionic Leech",
        "bio": "Illegal neural hacker specialized in frying wetware synaptic networks.",
        "role": 1, # HACKER
        "faction": 3, # ROGUE_AIS
        "base_cost": 5,
        "base_max_health": 820.0,
        "base_attack_damage": 30.0,
        "base_ability_power": 65.0,
        "base_attack_speed": 0.95,
        "base_armor": 20.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 55.0,
        "base_crit_chance": 0.10,
        "base_evasion": 0.10,
        "ability_name": "Synaptic Overload",
        "ability_description": "Shocks the enemy mind, dealing 240 AP damage and silencing ability charge for 3s.",
        "ability_effect_id": "boss_synaptic_overload"
    },
    {
        "id": "boss_house_dealer",
        "display_name": "House Dealer",
        "title": "Skyline High-Roller Pit Boss",
        "bio": "Calculating casino boss who tilts every fight with high-stakes probability manipulation.",
        "role": 3, # FIXER
        "faction": 4, # FIXERS
        "base_cost": 5,
        "base_max_health": 900.0,
        "base_attack_damage": 45.0,
        "base_ability_power": 50.0,
        "base_attack_speed": 0.90,
        "base_armor": 25.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 45.0,
        "base_crit_chance": 0.15,
        "base_evasion": 0.10,
        "ability_name": "High-Roller Roulette",
        "ability_description": "Gambles on luck: heals self for 250 HP or deals 260 AP damage to a random target.",
        "ability_effect_id": "boss_high_roller_roulette"
    },
    {
        "id": "boss_broker_prime",
        "display_name": "Broker Prime",
        "title": "Contract Row Syndicate Architect",
        "bio": "Master of city-wide black market bounties who orchestrates lethal focus-fire assassinations.",
        "role": 3, # FIXER
        "faction": 4, # FIXERS
        "base_cost": 5,
        "base_max_health": 880.0,
        "base_attack_damage": 50.0,
        "base_ability_power": 45.0,
        "base_attack_speed": 0.90,
        "base_armor": 25.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 50.0,
        "base_crit_chance": 0.10,
        "base_evasion": 0.08,
        "ability_name": "Bounty Execution",
        "ability_description": "Marks the highest-AD enemy, dealing 260 damage and granting allies 100 shield.",
        "ability_effect_id": "boss_bounty_execution"
    },
    {
        "id": "boss_warrant_bot",
        "display_name": "Warrant Bot",
        "title": "Precinct Ruins Riot Enforcer",
        "bio": "Repurposed law enforcement automaton built for riot suppression and heavy defensive lockdown.",
        "role": 0, # TANK
        "faction": 2, # CORP_ENFORCERS
        "base_cost": 5,
        "base_max_health": 1050.0,
        "base_attack_damage": 45.0,
        "base_ability_power": 30.0,
        "base_attack_speed": 0.80,
        "base_armor": 40.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 35.0,
        "base_crit_chance": 0.05,
        "base_evasion": 0.05,
        "ability_name": "Riot Suppression",
        "ability_description": "Deploys heavy riot barrier gaining 320 shield and reflecting 40 damage.",
        "ability_effect_id": "boss_riot_suppression"
    },
    {
        "id": "boss_transit_warden",
        "display_name": "Transit Warden",
        "title": "Undercity Tunnel Controller",
        "bio": "Subterranean rail controller who fries approaching crews with massive gridlock EMP discharges.",
        "role": 1, # HACKER
        "faction": 1, # STREET_RUNNERS
        "base_cost": 5,
        "base_max_health": 860.0,
        "base_attack_damage": 40.0,
        "base_ability_power": 55.0,
        "base_attack_speed": 1.00,
        "base_armor": 25.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 60.0,
        "base_crit_chance": 0.10,
        "base_evasion": 0.12,
        "ability_name": "Gridlock EMP",
        "ability_description": "Detonates an electromagnetic pulse dealing 220 AP damage to 2 fastest enemies.",
        "ability_effect_id": "boss_gridlock_emp"
    },
    {
        "id": "boss_chop_doc",
        "display_name": "Chop Doc",
        "title": "Chop Shop Row Chief Surgeon",
        "bio": "Notorious black clinic doctor who harvests vital organs and siphons health mid-combat.",
        "role": 3, # FIXER
        "faction": 4, # FIXERS
        "base_cost": 5,
        "base_max_health": 890.0,
        "base_attack_damage": 42.0,
        "base_ability_power": 55.0,
        "base_attack_speed": 0.90,
        "base_armor": 26.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 48.0,
        "base_crit_chance": 0.10,
        "base_evasion": 0.08,
        "ability_name": "Black Clinic Siphon",
        "ability_description": "Siphons 200 HP from the nearest operative to repair damaged cyberware.",
        "ability_effect_id": "boss_clinic_siphon"
    },
    {
        "id": "boss_dock_foreman",
        "display_name": "Dock Foreman",
        "title": "Freight Docks Crane Master",
        "bio": "Towering cargo handler equipped with powered industrial exoskeletons.",
        "role": 0, # TANK
        "faction": 1, # STREET_RUNNERS
        "base_cost": 5,
        "base_max_health": 980.0,
        "base_attack_damage": 48.0,
        "base_ability_power": 25.0,
        "base_attack_speed": 0.82,
        "base_armor": 32.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 38.0,
        "base_crit_chance": 0.05,
        "base_evasion": 0.05,
        "ability_name": "Cargo Smash",
        "ability_description": "Drops heavy freight container dealing 200 damage and granting 250 shield.",
        "ability_effect_id": "boss_cargo_smash"
    },
    {
        "id": "boss_machine_prophet",
        "display_name": "Machine Prophet",
        "title": "Megachurch Digital Hierophant",
        "bio": "Fanatical preacher of synthetic transcendence who shields cult constructs with holy static.",
        "role": 1, # HACKER
        "faction": 3, # ROGUE_AIS
        "base_cost": 5,
        "base_max_health": 870.0,
        "base_attack_damage": 32.0,
        "base_ability_power": 68.0,
        "base_attack_speed": 0.92,
        "base_armor": 22.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 52.0,
        "base_crit_chance": 0.08,
        "base_evasion": 0.10,
        "ability_name": "Digital Rapture",
        "ability_description": "Channels digital psalm granting 200 shield to all allies and dealing 180 AP damage.",
        "ability_effect_id": "boss_digital_rapture"
    },
    {
        "id": "boss_ghost_daemon",
        "display_name": "Ghost Daemon",
        "title": "The Undernet Darknet Specter",
        "bio": "Deep-layer malicious program lurking in unregistered subnets to corrupt hostile firmware.",
        "role": 1, # HACKER
        "faction": 3, # ROGUE_AIS
        "base_cost": 5,
        "base_max_health": 810.0,
        "base_attack_damage": 30.0,
        "base_ability_power": 75.0,
        "base_attack_speed": 1.05,
        "base_armor": 18.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 62.0,
        "base_crit_chance": 0.12,
        "base_evasion": 0.14,
        "ability_name": "Recursive Null",
        "ability_description": "Corrupts operative code, dealing 250 AP damage and preventing mana gain for 3s.",
        "ability_effect_id": "boss_recursive_null"
    },
    {
        "id": "boss_highway_reaper",
        "display_name": "Highway Reaper",
        "title": "Skyway Overpass Drone Sniper",
        "bio": "High-altitude road pirate picking off corporate transports with hyper-velocity rifles.",
        "role": 2, # SNIPER
        "faction": 1, # STREET_RUNNERS
        "base_cost": 5,
        "base_max_health": 820.0,
        "base_attack_damage": 68.0,
        "base_ability_power": 30.0,
        "base_attack_speed": 0.90,
        "base_armor": 24.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 58.0,
        "base_crit_chance": 0.22,
        "base_evasion": 0.12,
        "ability_name": "Nitro Ricochet",
        "ability_description": "Fires accelerated sniper round bouncing between 2 targets for 260 damage each.",
        "ability_effect_id": "boss_nitro_ricochet"
    },
    {
        "id": "boss_algo_arbitrageur",
        "display_name": "Algo Arbitrageur",
        "title": "Vault Exchange Market Assassin",
        "bio": "High-frequency corporate algorithmic trader weaponizing financial disruption and asset liquidation.",
        "role": 1, # HACKER
        "faction": 2, # CORP_ENFORCERS
        "base_cost": 5,
        "base_max_health": 840.0,
        "base_attack_damage": 36.0,
        "base_ability_power": 65.0,
        "base_attack_speed": 0.95,
        "base_armor": 24.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 54.0,
        "base_crit_chance": 0.10,
        "base_evasion": 0.08,
        "ability_name": "Hostile Liquidation",
        "ability_description": "Liquidates enemy assets, dealing 230 AP damage and reducing enemy attack damage.",
        "ability_effect_id": "boss_hostile_liquidation"
    },
    {
        "id": "boss_salvage_baron",
        "display_name": "Salvage Baron",
        "title": "Sunken District Deep Scavenger",
        "bio": "Subsea warlord harvesting wreckage from the flooded lower city beneath impenetrable pressure suits.",
        "role": 0, # TANK
        "faction": 4, # FIXERS
        "base_cost": 5,
        "base_max_health": 1020.0,
        "base_attack_damage": 46.0,
        "base_ability_power": 32.0,
        "base_attack_speed": 0.80,
        "base_armor": 38.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 36.0,
        "base_crit_chance": 0.05,
        "base_evasion": 0.05,
        "ability_name": "Bathyscaphe Slam",
        "ability_description": "Slams submersible plating, gaining 300 shield and dealing 170 splash damage.",
        "ability_effect_id": "boss_bathyscaphe_slam"
    },
    {
        "id": "boss_director_panopticon",
        "display_name": "Director Panopticon",
        "title": "Panopticon Surveillance Director",
        "bio": "Chief surveillance architect watching every movement across the city with lethal predictive lasers.",
        "role": 2, # SNIPER
        "faction": 2, # CORP_ENFORCERS
        "base_cost": 5,
        "base_max_health": 830.0,
        "base_attack_damage": 66.0,
        "base_ability_power": 38.0,
        "base_attack_speed": 0.90,
        "base_armor": 26.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 52.0,
        "base_crit_chance": 0.20,
        "base_evasion": 0.10,
        "ability_name": "Surveillance Strike",
        "ability_description": "Focuses total surveillance array, dealing 330 piercing damage to highest-HP enemy.",
        "ability_effect_id": "boss_surveillance_strike"
    },
    {
        "id": "boss_scrap_titan",
        "display_name": "Scrap Titan",
        "title": "Graveyard Yards Reanimated Behemoth",
        "bio": "Colossal war-mech reanimated by rogue autonomous subroutines in the mech scrapyard.",
        "role": 0, # TANK
        "faction": 3, # ROGUE_AIS
        "base_cost": 5,
        "base_max_health": 1100.0,
        "base_attack_damage": 52.0,
        "base_ability_power": 20.0,
        "base_attack_speed": 0.75,
        "base_armor": 42.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 30.0,
        "base_crit_chance": 0.05,
        "base_evasion": 0.04,
        "ability_name": "Reanimated Core",
        "ability_description": "Overclocks scrap core, regenerating 300 HP and dealing 160 area damage.",
        "ability_effect_id": "boss_reanimated_core"
    },
    {
        "id": "boss_static_warlord",
        "display_name": "Static Warlord",
        "title": "Bazaar of Static Signal Chieftain",
        "bio": "Dead-signal zone warlord utilizing white-noise jammers and high-voltage static coils.",
        "role": 1, # HACKER
        "faction": 4, # FIXERS
        "base_cost": 5,
        "base_max_health": 860.0,
        "base_attack_damage": 40.0,
        "base_ability_power": 60.0,
        "base_attack_speed": 0.95,
        "base_armor": 24.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 50.0,
        "base_crit_chance": 0.12,
        "base_evasion": 0.10,
        "ability_name": "Whiteout Discharge",
        "ability_description": "Discharges electromagnetic static dealing 210 AP damage and blinding enemies for 2s.",
        "ability_effect_id": "boss_whiteout_discharge"
    },
    {
        "id": "boss_gala_security_chief",
        "display_name": "Security Chief",
        "title": "Uptown Gala Chief Bodyguard",
        "bio": "High-society corporate bodyguard commanding an arsenal of heavy kinetic protection barriers.",
        "role": 0, # TANK
        "faction": 2, # CORP_ENFORCERS
        "base_cost": 5,
        "base_max_health": 1040.0,
        "base_attack_damage": 48.0,
        "base_ability_power": 28.0,
        "base_attack_speed": 0.85,
        "base_armor": 36.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 40.0,
        "base_crit_chance": 0.08,
        "base_evasion": 0.06,
        "ability_name": "Aegis Lockdown",
        "ability_description": "Deploys corporate aegis field granting 280 shield to self and adjacent ally.",
        "ability_effect_id": "boss_aegis_lockdown"
    },
    {
        "id": "boss_warren_overlord",
        "display_name": "Warren Overlord",
        "title": "The Warrens Tunnel Kingpin",
        "bio": "Cunning tunnel chieftain ruling the subterranean slums through ambush and extortion.",
        "role": 3, # FIXER
        "faction": 1, # STREET_RUNNERS
        "base_cost": 5,
        "base_max_health": 920.0,
        "base_attack_damage": 48.0,
        "base_ability_power": 48.0,
        "base_attack_speed": 0.90,
        "base_armor": 28.0,
        "base_shield": 0.0,
        "base_starting_mana": 0.0,
        "base_max_mana": 80.0,
        "base_speed": 46.0,
        "base_crit_chance": 0.12,
        "base_evasion": 0.08,
        "ability_name": "Tunnel Ambush",
        "ability_description": "Summons hidden ambush dealing 240 damage and applying 15% speed slow.",
        "ability_effect_id": "boss_tunnel_ambush"
    }
]

def main():
    print(f"Creating {len(BOSSES)} boss unit resource files...")
    for b in BOSSES:
        path = os.path.join(UNITS_DIR, f"{b['id']}.tres")
        content = f"""[gd_resource type="Resource" script_class="UnitResource" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/data/resources/UnitResource.gd" id="1_unit"]

[resource]
script = ExtResource("1_unit")
id = "{b['id']}"
display_name = "{b['display_name']}"
title = "{b['title']}"
bio = "{b['bio']}"
role = {b['role']}
faction = {b['faction']}
base_cost = {b['base_cost']}
base_max_health = {b['base_max_health']}
base_attack_damage = {b['base_attack_damage']}
base_ability_power = {b['base_ability_power']}
base_attack_speed = {b['base_attack_speed']}
base_armor = {b['base_armor']}
base_shield = {b['base_shield']}
base_starting_mana = {b['base_starting_mana']}
base_max_mana = {b['base_max_mana']}
base_speed = {b['base_speed']}
base_crit_chance = {b['base_crit_chance']}
base_evasion = {b['base_evasion']}
ability_name = "{b['ability_name']}"
ability_description = "{b['ability_description']}"
ability_effect_id = "{b['ability_effect_id']}"
"""
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"  + Created {b['id']}.tres")

if __name__ == "__main__":
    main()
