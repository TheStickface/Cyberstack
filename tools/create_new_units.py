import os

UNITS = [
    # Bio-Synthetics (Faction 5)
    {
        "id": "bio_chimera",
        "name": "Bio-Chimera",
        "title": "Grafted Brawler",
        "bio": "Bio-engineered frontliner reinforced with grafted subdermal plates.",
        "role": 4, # MEATSHIELD
        "faction": 5, # BIO_HACKERS
        "cost": 1,
        "hp": 720.0, "ad": 34.0, "ap": 0.0, "as": 0.85, "arm": 14.0, "shd": 0.0, "s_mana": 0.0, "m_mana": 80.0, "spd": 45.0, "crit": 0.05, "eva": 0.0,
        "ab_name": "Carapace Harden", "ab_desc": "150 Shield self (4s)", "ab_id": "carapace_harden",
        "dir_target": 3, "dir_desc": "Subdermal Mesh", "dir_mods": "{0: 80.0}"
    },
    {
        "id": "bio_leech",
        "name": "Bio-Leech",
        "title": "Viral Infiltrator",
        "bio": "Parasitic bio-hacker siphoning energy from host networks.",
        "role": 1, # HACKER
        "faction": 5,
        "cost": 1,
        "hp": 500.0, "ad": 24.0, "ap": 28.0, "as": 0.95, "arm": 5.0, "shd": 0.0, "s_mana": 20.0, "m_mana": 60.0, "spd": 55.0, "crit": 0.05, "eva": 0.0,
        "ab_name": "Spore Drain", "ab_desc": "drain 40 HP from target", "ab_id": "spore_drain",
        "dir_target": 5, "dir_desc": "Spore Vector", "dir_mods": "{2: 10.0}"
    },
    {
        "id": "bio_viper",
        "name": "Bio-Viper",
        "title": "Neuro-Toxic Marksman",
        "bio": "Precision sharpshooter firing pressurized biological neuro-toxin darts.",
        "role": 2, # SNIPER
        "faction": 5,
        "cost": 1,
        "hp": 480.0, "ad": 46.0, "ap": 10.0, "as": 1.05, "arm": 4.0, "shd": 0.0, "s_mana": 0.0, "m_mana": 60.0, "spd": 60.0, "crit": 0.10, "eva": 0.0,
        "ab_name": "Venom Dart", "ab_desc": "110 physical dmg, 30 poison (3s)", "ab_id": "venom_dart",
        "dir_target": 6, "dir_desc": "Venom Coating", "dir_mods": "{1: 10.0}"
    },
    {
        "id": "bio_symbiote",
        "name": "Bio-Symbiote",
        "title": "Organic Transfuser",
        "bio": "Mutated combat medic channeling living tissue to regenerate wounded crewmates.",
        "role": 3, # FIXER
        "faction": 5,
        "cost": 1,
        "hp": 560.0, "ad": 30.0, "ap": 20.0, "as": 0.90, "arm": 8.0, "shd": 0.0, "s_mana": 20.0, "m_mana": 70.0, "spd": 50.0, "crit": 0.05, "eva": 0.0,
        "ab_name": "Organic Infusion", "ab_desc": "heal 140 HP (lowest-HP ally)", "ab_id": "organic_infusion",
        "dir_target": 5, "dir_desc": "Symbiotic Pulse", "dir_mods": "{0: 60.0}"
    },
    {
        "id": "bio_gorgon",
        "name": "Bio-Gorgon",
        "title": "Scleroderm Titan",
        "bio": "Heavily calcified bio-construct capable of neutralizing attackers with kinetic slams.",
        "role": 0, # TANK
        "faction": 5,
        "cost": 2,
        "hp": 880.0, "ad": 36.0, "ap": 0.0, "as": 0.80, "arm": 20.0, "shd": 0.0, "s_mana": 0.0, "m_mana": 90.0, "spd": 40.0, "crit": 0.05, "eva": 0.0,
        "ab_name": "Calcified Slam", "ab_desc": "80 physical dmg, stun (1.5s)", "ab_id": "calcified_slam",
        "dir_target": 9, "dir_desc": "Calcified Wall", "dir_mods": "{4: 12.0}"
    },
    {
        "id": "bio_plague_doctor",
        "name": "Bio-Plague Doctor",
        "title": "Miasma Specialist",
        "bio": "Underground viral engineer releasing caustic bio-aerosols across combat zones.",
        "role": 1, # HACKER
        "faction": 5,
        "cost": 2,
        "hp": 540.0, "ad": 25.0, "ap": 40.0, "as": 0.90, "arm": 6.0, "shd": 0.0, "s_mana": 25.0, "m_mana": 75.0, "spd": 52.0, "crit": 0.05, "eva": 0.0,
        "ab_name": "Miasma Cloud", "ab_desc": "120 viral dmg over 4s (all frontline enemies)", "ab_id": "miasma_cloud",
        "dir_target": 4, "dir_desc": "Toxic Aura", "dir_mods": "{2: 15.0}"
    },
    {
        "id": "bio_manticore",
        "name": "Bio-Manticore",
        "title": "Venom Stinger",
        "bio": "Bio-weapon platform utilizing spine launchers that cripple target attack speed.",
        "role": 2, # SNIPER
        "faction": 5,
        "cost": 3,
        "hp": 620.0, "ad": 68.0, "ap": 15.0, "as": 1.00, "arm": 8.0, "shd": 0.0, "s_mana": 20.0, "m_mana": 70.0, "spd": 58.0, "crit": 0.20, "eva": 0.0,
        "ab_name": "Neurotoxin Spine", "ab_desc": "180 piercing dmg, -25% Attack Speed (target)", "ab_id": "neurotoxin_spine",
        "dir_target": 6, "dir_desc": "Predator Focus", "dir_mods": "{8: 0.12}"
    },
    {
        "id": "bio_fleshweaver",
        "name": "Bio-Fleshweaver",
        "title": "Cellular Reconstructor",
        "bio": "Elite biological architect capable of rapidly restructuring cellular damage across adjacent allies.",
        "role": 5, # COMMANDER
        "faction": 5,
        "cost": 3,
        "hp": 750.0, "ad": 38.0, "ap": 45.0, "as": 0.95, "arm": 14.0, "shd": 0.0, "s_mana": 30.0, "m_mana": 75.0, "spd": 50.0, "crit": 0.05, "eva": 0.0,
        "ab_name": "Cellular Reconstruct", "ab_desc": "heal 200 HP (2 adjacent allies)", "ab_id": "cellular_reconstruct",
        "dir_target": 5, "dir_desc": "Tissue Regeneration", "dir_mods": "{3: 0.15}"
    },
    {
        "id": "bio_hydra",
        "name": "Bio-Hydra",
        "title": "Regenerative Behemoth",
        "bio": "Multi-chambered mutagenic monstrosity that recovers health at an alarming rate.",
        "role": 4, # MEATSHIELD
        "faction": 5,
        "cost": 4,
        "hp": 1250.0, "ad": 55.0, "ap": 0.0, "as": 0.80, "arm": 22.0, "shd": 0.0, "s_mana": 0.0, "m_mana": 100.0, "spd": 42.0, "crit": 0.05, "eva": 0.0,
        "ab_name": "Regenerative Surge", "ab_desc": "heal 30% missing HP (3s)", "ab_id": "regenerative_surge",
        "dir_target": 9, "dir_desc": "Hydra Vitality", "dir_mods": "{0: 150.0, 4: 10.0}"
    },
    {
        "id": "bio_abomination",
        "name": "Bio-Abomination",
        "title": "Apex Bio-Cannon",
        "bio": "The pinnacle of black-market gene modification, unleashing overwhelming biological devastation.",
        "role": 2, # SNIPER
        "faction": 5,
        "cost": 5,
        "hp": 780.0, "ad": 96.0, "ap": 55.0, "as": 1.10, "arm": 12.0, "shd": 0.0, "s_mana": 30.0, "m_mana": 90.0, "spd": 65.0, "crit": 0.15, "eva": 0.0,
        "ab_name": "Apex Bio-Cannon", "ab_desc": "320 toxic dmg (column)", "ab_id": "apex_biocannon",
        "dir_target": 8, "dir_desc": "Apex Pheromones", "dir_mods": "{1: 15.0, 3: 0.10}"
    },
    # Net-Phantoms (Faction 6)
    {
        "id": "phantom_spectre",
        "name": "Phantom Spectre",
        "title": "Shadow Carbine",
        "bio": "Ghost operative armed with soundless particle carbine delivering guaranteed critical strikes.",
        "role": 2, # SNIPER
        "faction": 6,
        "cost": 1,
        "hp": 470.0, "ad": 48.0, "ap": 0.0, "as": 1.05, "arm": 4.0, "shd": 0.0, "s_mana": 0.0, "m_mana": 60.0, "spd": 62.0, "crit": 0.12, "eva": 0.08,
        "ab_name": "Ghost Shot", "ab_desc": "120 physical dmg, guaranteed crit", "ab_id": "ghost_shot",
        "dir_target": 6, "dir_desc": "Spectre Sight", "dir_mods": "{8: 0.08}"
    },
    {
        "id": "phantom_wraith",
        "name": "Phantom Wraith",
        "title": "Data Cloak Infiltrator",
        "bio": "Electronic warfare ghost who disrupts enemy targeting sensors with active data decoys.",
        "role": 1, # HACKER
        "faction": 6,
        "cost": 1,
        "hp": 490.0, "ad": 22.0, "ap": 30.0, "as": 0.95, "arm": 4.0, "shd": 0.0, "s_mana": 20.0, "m_mana": 60.0, "spd": 56.0, "crit": 0.05, "eva": 0.10,
        "ab_name": "Blind Glitch", "ab_desc": "-40% hit chance (target) (3s)", "ab_id": "blind_glitch",
        "dir_target": 5, "dir_desc": "Wraith Step", "dir_mods": "{9: 10.0}"
    },
    {
        "id": "phantom_bulwark",
        "name": "Phantom Bulwark",
        "title": "Phase Deflector",
        "bio": "Phasing defensive chassis that bends incoming projectile trajectories into sub-space.",
        "role": 0, # TANK
        "faction": 6,
        "cost": 1,
        "hp": 700.0, "ad": 32.0, "ap": 0.0, "as": 0.85, "arm": 12.0, "shd": 0.0, "s_mana": 0.0, "m_mana": 80.0, "spd": 46.0, "crit": 0.05, "eva": 0.08,
        "ab_name": "Phase Barrier", "ab_desc": "120 Shield, +25% Evasion (3s)", "ab_id": "phase_barrier",
        "dir_target": 9, "dir_desc": "Phase Distortion", "dir_mods": "{10: 0.10}"
    },
    {
        "id": "phantom_whisper",
        "name": "Phantom Whisper",
        "title": "Sub-Net Cipher",
        "bio": "Silent comms broker cleansing allied debuffs and routing untracked power packets.",
        "role": 3, # FIXER
        "faction": 6,
        "cost": 1,
        "hp": 530.0, "ad": 28.0, "ap": 22.0, "as": 0.95, "arm": 6.0, "shd": 0.0, "s_mana": 25.0, "m_mana": 70.0, "spd": 54.0, "crit": 0.05, "eva": 0.06,
        "ab_name": "Tactical Blackout", "ab_desc": "dispel debuffs (allies), +10 mana", "ab_id": "tactical_blackout",
        "dir_target": 6, "dir_desc": "Sub-Net Frequency", "dir_mods": "{6: 10.0}"
    },
    {
        "id": "phantom_assassin",
        "name": "Phantom Assassin",
        "title": "Ghost Blade",
        "bio": "Deadly strike operative who teleports behind enemy lines for lethal critical assassinations.",
        "role": 4, # MEATSHIELD
        "faction": 6,
        "cost": 2,
        "hp": 620.0, "ad": 66.0, "ap": 0.0, "as": 1.15, "arm": 8.0, "shd": 0.0, "s_mana": 20.0, "m_mana": 65.0, "spd": 68.0, "crit": 0.25, "eva": 0.12,
        "ab_name": "Shadow Strike", "ab_desc": "teleport backline, 160 crit dmg", "ab_id": "shadow_strike",
        "dir_target": 10, "dir_desc": "Ambush Stance", "dir_mods": "{8: 0.15}"
    },
    {
        "id": "phantom_nullifier",
        "name": "Phantom Nullifier",
        "title": "Black-Ice Silencer",
        "bio": "Deep-net hacker delivering concentrated black-ice surges that silence enemy cyberware.",
        "role": 1, # HACKER
        "faction": 6,
        "cost": 2,
        "hp": 550.0, "ad": 26.0, "ap": 42.0, "as": 0.90, "arm": 6.0, "shd": 0.0, "s_mana": 25.0, "m_mana": 75.0, "spd": 55.0, "crit": 0.05, "eva": 0.08,
        "ab_name": "Black-Ice Pulse", "ab_desc": "silence target (2.5s), -25 mana", "ab_id": "black_ice_pulse",
        "dir_target": 5, "dir_desc": "Null Field", "dir_mods": "{2: 15.0}"
    },
    {
        "id": "phantom_aegis",
        "name": "Phantom Aegis",
        "title": "Phase Commander",
        "bio": "Tactical officer generating holographic distortion fields that reflect incoming damage.",
        "role": 5, # COMMANDER
        "faction": 6,
        "cost": 3,
        "hp": 850.0, "ad": 40.0, "ap": 25.0, "as": 0.85, "arm": 16.0, "shd": 0.0, "s_mana": 20.0, "m_mana": 85.0, "spd": 48.0, "crit": 0.05, "eva": 0.12,
        "ab_name": "Phase Shift Cloak", "ab_desc": "untargetable (1.5s), reflect 50 dmg", "ab_id": "phase_shift_cloak",
        "dir_target": 9, "dir_desc": "Aegis Cloak", "dir_mods": "{4: 15.0, 10: 0.10}"
    },
    {
        "id": "phantom_mirage",
        "name": "Phantom Mirage",
        "title": "Holographic Decoy",
        "bio": "Illusionist who projects solid-light holograms that intercept enemy attacks.",
        "role": 3, # FIXER
        "faction": 6,
        "cost": 3,
        "hp": 660.0, "ad": 36.0, "ap": 44.0, "as": 1.00, "arm": 8.0, "shd": 0.0, "s_mana": 30.0, "m_mana": 75.0, "spd": 56.0, "crit": 0.08, "eva": 0.15,
        "ab_name": "Holographic Decoy", "ab_desc": "2 decoys distract 2 enemy attacks", "ab_id": "holographic_decoy",
        "dir_target": 8, "dir_desc": "Holo Projection", "dir_mods": "{10: 0.10}"
    },
    {
        "id": "phantom_nightshade",
        "name": "Phantom Nightshade",
        "title": "Void Infiltrator",
        "bio": "Infiltration specialist executing high-value targets with armor-shredding true damage.",
        "role": 4, # MEATSHIELD
        "faction": 6,
        "cost": 4,
        "hp": 800.0, "ad": 90.0, "ap": 20.0, "as": 1.20, "arm": 14.0, "shd": 0.0, "s_mana": 20.0, "m_mana": 70.0, "spd": 70.0, "crit": 0.30, "eva": 0.15,
        "ab_name": "Void Execute", "ab_desc": "280 true dmg (lowest-HP enemy)", "ab_id": "void_execute",
        "dir_target": 6, "dir_desc": "Void Resonance", "dir_mods": "{1: 20.0, 8: 0.15}"
    },
    {
        "id": "phantom_eidolon",
        "name": "Phantom Eidolon",
        "title": "Singularity Process",
        "bio": "A legendary ghost entity capable of collapsing localized network architecture.",
        "role": 1, # HACKER
        "faction": 6,
        "cost": 5,
        "hp": 720.0, "ad": 40.0, "ap": 95.0, "as": 1.00, "arm": 10.0, "shd": 0.0, "s_mana": 40.0, "m_mana": 100.0, "spd": 62.0, "crit": 0.10, "eva": 0.12,
        "ab_name": "Net Singularity", "ab_desc": "pull backline to center, 300 AP dmg", "ab_id": "net_singularity",
        "dir_target": 8, "dir_desc": "Singularity Core", "dir_mods": "{2: 25.0, 6: 15.0}"
    }
]

out_dir = r"C:\dev\cyberstack\data\units"
for u in UNITS:
    content = f"""[gd_resource type="Resource" script_class="UnitResource" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/data/resources/UnitResource.gd" id="1_unit"]

[resource]
script = ExtResource("1_unit")
id = "{u['id']}"
display_name = "{u['name']}"
title = "{u['title']}"
bio = "{u['bio']}"
role = {u['role']}
faction = {u['faction']}
base_cost = {u['cost']}
base_max_health = {u['hp']}
base_attack_damage = {u['ad']}
base_ability_power = {u['ap']}
base_attack_speed = {u['as']}
base_armor = {u['arm']}
base_shield = {u['shd']}
base_starting_mana = {u['s_mana']}
base_max_mana = {u['m_mana']}
base_speed = {u['spd']}
base_crit_chance = {u['crit']}
base_evasion = {u['eva']}
ability_name = "{u['ab_name']}"
ability_description = "{u['ab_desc']}"
ability_effect_id = "{u['ab_id']}"
directional_target = {u['dir_target']}
directional_passive_description = "{u['dir_desc']}"
directional_modifiers = {u['dir_mods']}
"""
    fpath = os.path.join(out_dir, f"{u['id']}.tres")
    with open(fpath, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Created {fpath}")
