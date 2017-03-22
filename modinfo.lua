name = "Rezecib's Rebalance"
description = "Makes many modifications to the game in an attempt to rebalance weak or annoying mechanics, and tone down some of the overpowered ones."
author = "rezecib"
version = "1.2.7"

--[[
Major miscellaneous changes:
	WX-78's overcharge now stacks with diminishing returns (1 strike is about the same, but 10 strikes only gives about 3 days)
	WX-78 now drops all gears except one on death, instead of way fewer
	Players can no longer attack each other's minions/followers unless PvP is on (Maxwell's shadows, Abigail, etc)
	Attack-command now works properly; followers will get the same target at you as soon as you target, instead of at the start of your attack animation
	Saplings are protected from disease by deciduous turf
	Fixed beardlings/beardlords to show up at 40% sanity instead of 15%
	Thermal Measurer now gives the exact temperature and a description when examined
	Shadow creatures cannot despawn within 15s of being attacked
	Cave ferns respawn like flowers
	Fireflies respawn like carrots (but not if you place them down again)
	Abigail can be disengaged/engaged (making her passive)
	Extra-Adorable Lavae have health regen, do not die from starvation, do not light things on fire, and do not die when frozen

Maxwell:
	Can now change his minion types by giving them items, or make them stop working, but starts with 5 fuel instead of 6
	Minions now all have 75 health, and non-duelists have 1/5 of the duelist regen, but cost 5 fuel
	Minions match Maxwell's speed
	Chopper minions no longer run away from poison birchnuts (they will run away from the birchnutters, though)
	Duelist minions have improved kiting (will still have trouble with groups of enemies)
	Has two new minion types: torchbearer, porter
	Minions can now be armored by football helmets or battle helms, for 25% armor and taking a maximum of 45 damage per hit

Willow:
	Can craft a Shadow Lighter with the Shadow Manipulator, a Lighter, and 2 Nightmare Fuel
	The Shadow Lighter can only be used by Willow, lasts longer, and can be refueled with Nightmare Fuel (30%)
	Can light shadowfires with the shadow lighter for 2.5% durability and 15 sanity
	Shadowfires work like houndfire but do not propagate, and burn longer (extinguish after dealing 200 damage)
	Shadowfires have some special interactions with flingomatics :)
	Willow is 100% immune to shadowfire damage (in PvE, all players are immune)
	If she has gone 2 days without lighting a (shadow)fire, gradually loses more sanity over time

Woodie:
	No sanity loss as werebeaver, but transform back with low stats (like single-player)
	Damage taken as the werebeaver is removed from the log meter before health, with 60% reduction
	Werebeaver insulation doubled and water resistance increased to 90%
	Werebeaver deals 51 base damage again (still has bonus wood damage)
	Werebeaver deals axe damage in PvP
	Removed pinecone sanity gain
	
Wolfgang:
	Instead of gradually scaling in his wimpy/mighty states, he has one set of stats for each
	His hunger drain is 2x in all states, instead of scaling from 1x-3x
	His sanity drain multiplier is increased from 1.1x to 1.5x
	Wimpy: 0.9 scale, 0.75x damage, 150 health
	Mighty: 1.25 scale, 2x damage, 300 health
	His powerup/powerdown animations can now be canceled

Beefalo domestication:
	While riding beefalo, a little widget on the HUD pops up to show beefalo stats
	A beefalo's domestication is stored separately for each player
	Domestication loss over time is reduced (full loss in 20 days rather than 9 days)
	Being attacked by a player only deducts domestication for that player
	Gain domestication while sleeping next to a player
	Beefalo can no longer be brushed until they are ready to be brushed
	Saddles can be repaired with a sewing kit, but also lose durability while riding TODO TODO
	Partially or fully domesticated beefalo near a player save and load with the player
	Beefalo are faster on roads (even while not being ridden... watch out!)
	Beefalo now show their favorite player and tendency (when domesticated)
	Beefalo collar can be crafted. When given to a fully domesticated beefalo, let you name it.
	Collared beefalo, instead of dying, lie on the ground in a near-death state for a day
	You can revive a near-death beefalo by giving it a booster shot (comes back with 25% health)
	In PvP only, collared beefalo can only be ridden by the player who collared them
	Domesticated beefalo no longer share aggro like other beefalo

Ancient Guardian:
	When the nightmare cycle peaks, if the Ancient Guardian has been dead for 20 days then a ghost of it spawns
	The Ancient Guardian Ghost can be revived by infusing it with an Ancient Guardian Horn and 8 meat
	Every Summer, the Ancient Guardian respawns fully in the ruins
	
Magic Items:
	The Night Light costs 2 more red gems and 4 more nightmare fuel,
		but now functions like a Nightmare Fissure while lit, spawning nightmares that attack sane players
	The Bat Bat can be repaired with Batilisk Wings, and has a little bit more durability
	The One Man Band no longer grabs pig or bunnyman followers, but instead speeds all followers by 1.25x to 3x,
		lasts for 5 days, and can be refueled with nightmare fuel for 1 day of use,
		and the recipe is now 4 gold, 6 nightmare fuel, 4 pig skin;
		Webber can befriend pigs/bunnymen while wearing it
	Sleepytime Stories has 15 (half) range against players
	Rabbit Earmuffs now give substantial resistance to Sleepytime Stories and Pan Flutes
	The Weather Pain now 1-shots rocks and trees, but does less to structures

Ancient Items:
	Lazy Explorer can now be refueled by orange gems (1 for a full refuel)
	The Pick/Axe gains back 80% of the durability it would've used to kill an enemy if one dies near it
	The Lazy Forager can be refueled by nightmare fuel (1 fuel per 25 item pickups)
	The Lazy Forager's range is doubled (from 4 to 8, or 1 tile to 2 tiles)
	The Lazy Forager, Lazy Explorer, and Magiluminescence don't break when they run out
	
Minor miscellaneous changes:
	Insulated Pack is no longer flammable, and has the same number of slots as a normal backpack, and costs 1 gear instead of 3
	Deciduous turf now spawns the same birds as forest turf
	Beefalo no longer eat off of turf that has no grass (bad beefalo... dirt is for moleworms)
	Disease now kills things in 2-3 days rather than 30s to 1 day
	Lanterns can now be turned off and on by haunting (50% chance)

==> TODO:

Ancient Guardian:
	Ancient Guardian has several zoning/ranged shadow attacks instead of just boring rhino AI
	
==> Thinking about, but not sure:

Bernie takes no damage from shadows, but can only pull one at a time
Twiggy trees can only have one twig on the ground, drop it randomly when at full size, and don't check the area
Smallbirds
More insulated pack buffs?

]]

icon_atlas = "RezecibsRebalance.xml"
icon = "RezecibsRebalance.tex"

forumthread = ""

api_version = 10

priority = -9000 --needs to load after character mods

server_filter_tags = {"rezecib's rebalance"}

dst_compatible = true

client_only_mod = false
all_clients_require_mod = true