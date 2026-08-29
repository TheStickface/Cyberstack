import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DISTRICTS_DIR = os.path.join(ROOT, "data", "districts")

# Enums.AugmentTag: NONE=0, VIRAL=1, THERMAL=2, NEURAL=3, KINETIC=4

DISTRICTS = [
    {
        "file": "district_1_slum_market.tres",
        "id": "district_1_slum_market",
        "display_name": "Slum Market",
        "description": "Rain-slicked alleyways illuminated by flickering neon signs, populated by agile Street Runners and black-market arms dealers.",
        "theme_color": "Color(0, 0.95, 0.83, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_slum_enforcer",
        "preferred_tag": 0,
        "reroll_cost_override": -1,
        "bonus_crew_slots": 1,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 0,
        "payout_bonus": 0
    },
    {
        "file": "district_2_corp_arcology.tres",
        "id": "district_2_corp_arcology",
        "display_name": "Corp Arcology",
        "description": "Gleaming monolithic high-rises guarded by armored Corp Enforcers with state-of-the-art synthetic security grids.",
        "theme_color": "Color(0, 0.7, 0.85, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_corp_commander",
        "preferred_tag": 0,
        "reroll_cost_override": -1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 0,
        "payout_bonus": 2
    },
    {
        "file": "district_3_server_vault.tres",
        "id": "district_3_server_vault",
        "display_name": "Server Vault",
        "description": "Subterranean cryo-cooled mainframe labyrinth where sentient Rogue AIs deploy aggressive cybersecurity subroutines.",
        "theme_color": "Color(0.6, 0.2, 1, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_ai_prime_overmind",
        "preferred_tag": 3, # NEURAL
        "reroll_cost_override": -1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 1,
        "scrap_refund_bonus": 0,
        "payout_bonus": 0
    },
    {
        "file": "district_4_black_site.tres",
        "id": "district_4_black_site",
        "display_name": "Black Site",
        "description": "Redacted corporate military stronghold hiding black-market military prototypes, legendary augments, and autonomous combat units.",
        "theme_color": "Color(1, 0.1, 0.35, 1)",
        "is_final_boss": True,
        "boss_unit_id": "boss_nemesis_synthetic",
        "preferred_tag": 0,
        "reroll_cost_override": -1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 0,
        "payout_bonus": 0
    },
    {
        "file": "thermal_foundry.tres",
        "id": "thermal_foundry",
        "display_name": "Thermal Foundry",
        "description": "Industrial blast-furnace district bathed in molten orange heat, sparking rail lines, and thermal hazard vents.",
        "theme_color": "Color(1, 0.4, 0.1, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_foundry_overseer",
        "preferred_tag": 2, # THERMAL
        "reroll_cost_override": -1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 0,
        "payout_bonus": 0
    },
    {
        "file": "kinetic_yards.tres",
        "id": "kinetic_yards",
        "display_name": "Kinetic Yards",
        "description": "Sprawling scrapyard and magnetic freight terminal with scrap salvage bonuses and heavy kinetic railgun weaponry.",
        "theme_color": "Color(1, 0.85, 0.1, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_railmaster",
        "preferred_tag": 4, # KINETIC
        "reroll_cost_override": -1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 1,
        "payout_bonus": 0
    },
    {
        "file": "neural_exchange.tres",
        "id": "neural_exchange",
        "display_name": "Neural Exchange",
        "description": "Electric-blue data exchange specializing in wetware brainwave auctions, neural leeching, and psionic augments.",
        "theme_color": "Color(0.2, 0.8, 1, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_mindbreaker",
        "preferred_tag": 3, # NEURAL
        "reroll_cost_override": -1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 1,
        "scrap_refund_bonus": 0,
        "payout_bonus": 0
    },
    {
        "file": "skyline_casino.tres",
        "id": "skyline_casino",
        "display_name": "Skyline Casino",
        "description": "High-altitude magenta pleasure hub offering low-cost shop rerolls and high-stakes probability manipulation.",
        "theme_color": "Color(1, 0.1, 0.8, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_house_dealer",
        "preferred_tag": 0,
        "reroll_cost_override": 1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 0,
        "payout_bonus": 0
    },
    {
        "file": "contract_row.tres",
        "id": "contract_row",
        "display_name": "Contract Row",
        "description": "Rain-slicked noir district populated by info brokers, bounty contractors, and underground Fixer syndicates.",
        "theme_color": "Color(0.85, 0.65, 0.3, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_broker_prime",
        "preferred_tag": 0,
        "reroll_cost_override": -1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 0,
        "payout_bonus": 1
    },
    {
        "file": "precinct_ruins.tres",
        "id": "precinct_ruins",
        "display_name": "Precinct Ruins",
        "description": "Abandoned police headquarters squatted by rogue security bots and bounty hunters holding riot armor armories.",
        "theme_color": "Color(0.5, 0.6, 0.75, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_warrant_bot",
        "preferred_tag": 4, # KINETIC
        "reroll_cost_override": -1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 0,
        "payout_bonus": 0
    },
    {
        "file": "undercity_transit.tres",
        "id": "undercity_transit",
        "display_name": "Undercity Transit",
        "description": "Flickering subterranean metro tunnels connecting the city underworld with cheap operative recruitment hubs.",
        "theme_color": "Color(0.9, 0.5, 0.2, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_transit_warden",
        "preferred_tag": 0,
        "reroll_cost_override": -1,
        "bonus_crew_slots": 1,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 0,
        "payout_bonus": 0
    },
    {
        "file": "chop_shop_row.tres",
        "id": "chop_shop_row",
        "display_name": "Chop Shop Row",
        "description": "Surgical cybernetics strip bathed in sickly-green neon, specializing in viral implants and augment recycling.",
        "theme_color": "Color(0.3, 1, 0.2, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_chop_doc",
        "preferred_tag": 1, # VIRAL
        "reroll_cost_override": -1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 1,
        "payout_bonus": 0
    },
    {
        "file": "freight_docks.tres",
        "id": "freight_docks",
        "display_name": "Freight Docks",
        "description": "Cargo port smuggling zone under sodium-orange floodlights, rewarding steady payout dividends from container contracts.",
        "theme_color": "Color(0.9, 0.6, 0.2, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_dock_foreman",
        "preferred_tag": 0,
        "reroll_cost_override": -1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 0,
        "payout_bonus": 1
    },
    {
        "file": "megachurch_of_the_machine.tres",
        "id": "megachurch_of_the_machine",
        "display_name": "Megachurch of the Machine",
        "description": "Grand cathedral server hall with glowing holographic halos, devoted to synthetic digital transcendence and neural tech.",
        "theme_color": "Color(1, 0.9, 0.4, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_machine_prophet",
        "preferred_tag": 3, # NEURAL
        "reroll_cost_override": -1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 0,
        "payout_bonus": 0
    },
    {
        "file": "the_undernet.tres",
        "id": "the_undernet",
        "display_name": "The Undernet",
        "description": "Deep darknet zone with corrupted constructs and virulent data packets, offering expanded black-market armory offerings.",
        "theme_color": "Color(0.1, 0.9, 0.4, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_ghost_daemon",
        "preferred_tag": 1, # VIRAL
        "reroll_cost_override": -1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 1,
        "scrap_refund_bonus": 0,
        "payout_bonus": 0
    },
    {
        "file": "skyway_overpass.tres",
        "id": "skyway_overpass",
        "display_name": "Skyway Overpass",
        "description": "Elevated highway slum above the clouds with rapid shop cycle refreshes and high-velocity road drone raiders.",
        "theme_color": "Color(0.2, 0.8, 1, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_highway_reaper",
        "preferred_tag": 0,
        "reroll_cost_override": 1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 0,
        "payout_bonus": 0
    },
    {
        "file": "the_vault_exchange.tres",
        "id": "the_vault_exchange",
        "display_name": "The Vault Exchange",
        "description": "Corporate trading exchange with floating ticker-tape holograms that pays out premium liquidity dividends.",
        "theme_color": "Color(1, 0.85, 0.2, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_algo_arbitrageur",
        "preferred_tag": 0,
        "reroll_cost_override": -1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 0,
        "payout_bonus": 2
    },
    {
        "file": "sunken_district.tres",
        "id": "sunken_district",
        "display_name": "Sunken District",
        "description": "Flooded lower city district where scavengers salvage high-value tech and scrap from submerged corporate ruins.",
        "theme_color": "Color(0, 0.7, 0.7, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_salvage_baron",
        "preferred_tag": 0,
        "reroll_cost_override": -1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 1,
        "payout_bonus": 0
    },
    {
        "file": "the_panopticon.tres",
        "id": "the_panopticon",
        "display_name": "The Panopticon",
        "description": "Stark-white corporate surveillance tower tracking all neural networks with red scanlines and predictive targeting arrays.",
        "theme_color": "Color(0.9, 0.2, 0.3, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_director_panopticon",
        "preferred_tag": 3, # NEURAL
        "reroll_cost_override": -1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 0,
        "payout_bonus": 0
    },
    {
        "file": "graveyard_yards.tres",
        "id": "graveyard_yards",
        "display_name": "Graveyard Yards",
        "description": "Decommissioned mech cemetery in the fog, rich in kinetic alloy salvage and reanimated combat chassis.",
        "theme_color": "Color(0.6, 0.6, 0.7, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_scrap_titan",
        "preferred_tag": 4, # KINETIC
        "reroll_cost_override": -1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 1,
        "payout_bonus": 0
    },
    {
        "file": "the_bazaar_of_static.tres",
        "id": "the_bazaar_of_static",
        "display_name": "The Bazaar of Static",
        "description": "Black-market technology bazaar in a permanent dead-signal zone offering expanded augment armories.",
        "theme_color": "Color(0.7, 0.3, 0.9, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_static_warlord",
        "preferred_tag": 0,
        "reroll_cost_override": -1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 1,
        "scrap_refund_bonus": 0,
        "payout_bonus": 0
    },
    {
        "file": "uptown_gala.tres",
        "id": "uptown_gala",
        "display_name": "Uptown Gala",
        "description": "Opulent high-society corporate ballroom heist venue offering tremendous credit payouts for successful breaches.",
        "theme_color": "Color(1, 0.8, 0.4, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_gala_security_chief",
        "preferred_tag": 0,
        "reroll_cost_override": -1,
        "bonus_crew_slots": 0,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 0,
        "payout_bonus": 2
    },
    {
        "file": "the_warrens.tres",
        "id": "the_warrens",
        "display_name": "The Warrens",
        "description": "Cramped amber-lantern tunnel slum teeming with street operatives looking for a crew to join.",
        "theme_color": "Color(0.8, 0.5, 0.2, 1)",
        "is_final_boss": False,
        "boss_unit_id": "boss_warren_overlord",
        "preferred_tag": 0,
        "reroll_cost_override": -1,
        "bonus_crew_slots": 1,
        "bonus_augment_slots": 0,
        "scrap_refund_bonus": 0,
        "payout_bonus": 0
    }
]

def main():
    print("Updating 23 district resource files with thematic properties...")
    for d in DISTRICTS:
        path = os.path.join(DISTRICTS_DIR, d["file"])
        content = f"""[gd_resource type="Resource" script_class="DistrictResource" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/data/resources/DistrictResource.gd" id="1_dist"]

[resource]
script = ExtResource("1_dist")
id = "{d['id']}"
display_name = "{d['display_name']}"
description = "{d['description']}"
theme_color = {d['theme_color']}
is_final_boss = {str(d['is_final_boss']).lower()}
node_sequence = Array[int]([0, 1, 0, 2, 1, 3])
boss_unit_id = "{d['boss_unit_id']}"
preferred_tag = {d['preferred_tag']}
reroll_cost_override = {d['reroll_cost_override']}
bonus_crew_slots = {d['bonus_crew_slots']}
bonus_augment_slots = {d['bonus_augment_slots']}
scrap_refund_bonus = {d['scrap_refund_bonus']}
payout_bonus = {d['payout_bonus']}
"""
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"  + Updated {d['file']}")

if __name__ == "__main__":
    main()
