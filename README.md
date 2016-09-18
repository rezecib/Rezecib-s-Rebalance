# Rezecib's Rebalance
A mod for [Don't Starve Together](http://store.steampowered.com/app/322330/) that extensively rebalances the game.

_**Feedback is welcome, no one person can be omniscient about balance, and I'm certainly not the best.**_

**Note: If you want to remove the mod, move far away from any beefalo you've domesticated before closing the server and disabling the mod. They may get deleted otherwise.**

My main design goal here is to transform game mechanics that were weak, useless, or annoying into useful mechanics that are fun. I'm less concerned with reducing things that are a little overpowered, although I do want to patch some of the ones that are ridiculously overpowered. I have not been doing extensive client-server testing yet, so it's very likely there are several crashes right now.

# Installation
I really recommend [subscribing on Steam](http://steamcommunity.com/sharedfiles/filedetails/?id=741879530) instead. It doesn't give me anything or cost you anything, and it will automatically update it and provide it to people joining your server. However, if you really want to install it from here, download a release and put it in your mods folder, and make sure anyone else joining has done so too.

# Current change list:

**Major miscellaneous changes:**
- WX-78 drops all gears except one on death, but his overcharge stacks less
- Players can't attack other's minions/followers unless PvP is on
- Followers will get the same target at you as soon as you target, not at the start of the attack animation
- Saplings are protected from disease by deciduous turf
- Thermal Measurer now gives the exact temperature, along with a description, when examined
- Shadow creatures cannot despawn within 15s of being attacked
- Cave ferns respawn like flowers
- Fireflies respawn like carrots (but not if you put them back down and catch them again)
- Extra-Adorable Lavae have health regen, do not die from starvation, do not light things on fire, and do not die when frozen
- Abigail can now be disengaged/engaged (making her passive)

**Maxwell:**
- Can now change his minion types by giving them items, or make them stop working, but starts with 4 fuel instead of 6
- Minions all have 75 health, and non-duelists have 1/5 of the duelist regen
- Minions now match Maxwell's movement speed
- Chopper minions no longer run away from poison birchnuts
- Duelist minions have improved kiting (will still have trouble with groups of enemies)
- Two new minion types: torchbearer, porter (picks items up)
- Minions can be given hats. Armor hats give 60% reduction, all other hats are cosmetic.

**Willow**
- Can craft a Shadow Lighter at the Shadow Manipulator for a Lighter and 2 Nightmare Fuel
- The Shadow Lighter can only be used by Willow, lasts longer, and can be refueled with Nightmare Fuel (for 30%)
- Can light shadowfires with her Shadow Lighter for 10% durability and 15 sanity
- Shadowfires work like houndfires but are barely warm, and burn longer (extinguish after dealing 200 damage)
- Shadowfires last longer with flingomatics (fire farms)
- Willow is immune to shadowfire damage (as are other players outside of PvP)
- After having gone 2 days without lighting a (shadow)fire, she gradually loses more sanity over time (small drain).

**Woodie:**
- No sanity loss as the werebeaver, but he transforms back with low stats (like single-player)
- No sanity gain from planting pinecones
- Werebeaver insulation doubled and water resistance increased to 90%
- Werebeaver deals 51 damage, keeps the bonus against wood things, still deals axe damage to players
- Damage done to the werebeaver is taken from the log meter before health
- When eating, the werebeaver gains 20% of the log meter gains as health

**Wolfgang:**
- Wimpy/mighty states have set stats (no scaling), with 2x hunger drain in all states
- Wimpy: 0.9 scale, 0.75x damage, 150 health
- Mighty: 1.25 scale, 1.75x damage, 300 health
- His transform animations can now be canceled

**Beefalo domestication:**
- While riding beefalo, a widget on the HUD shows beefalo stats
- A beefalo's domestication is stored separately for each player
- Domestication loss over time is reduced (full loss in 20 days rather than 9 days)
- Being attacked by a player only deducts domestication for that player
- Gain domestication while sleeping next to a player
- Beefalo can no longer be brushed until they are ready to be brushed
- Saddles can be repaired with a sewing kit, but lose durability while riding
- Partially or fully domesticated beefalo near a player save and load with the player (also go to caves)
- Beefalo are faster on roads
- Beefalo now show their favorite player and tendency (when domesticated)
- Beefalo collar can now be crafted for 8 silk, 2 moonrocks, and 2 pigskin (art by TheLetterW)
- Giving a collar to a beefalo lets you name it, and prevents the beefalo from dying immediately on health loss.
- Instead of dying, collared beefalo lie in a near-death state for up to a day. Giving them a booster shot revives them at 25% health
- In PvP only, collared beefalo can only be ridden by the player who collared them
- Domesticated beefalo don't share aggro like other beefalo

**Ancient Guardian:**
- When the nightmare cycle peaks, if the Ancient Guardian has been dead for 20 days then a ghost of it spawns
- The Ancient Guardian Ghost can be revived by infusing it with an Ancient Guardian Horn and 8 meat
- Every Summer, the Ancient Guardian respawns fully in the ruins

**Magic Items:**
- The Night Light now costs 8 gold, 4 nightmare fuel, and 3 red gems, but functions like a Nightmare Fissure when lit, spawning Nightmares that attack sane players
- The Bat Bat has more durability (75 uses -> 100 uses), and can be repaired for 33 uses by Batilisk Wings
- The One Man Band now costs 4 gold, 6 nightmare fuel, and 4 pig skin. It no longer grabs followers, and has a low constant sanity drain. It lasts 5 days, can be refueled by nightmare fuel (1 day per fuel), and speeds up followers (slower followers speed up more). Pigs/Bunnymen are friendly to Webber while he is using it
- Sleepytime Stories now has half range against players (15 range)
- Rabbit Earmuffs now give substantial resistance to Sleepytime Stories and Pan Flutes
- The Weather Pain now 1-shots rocks and trees, but does reduced damage to structures

**Ancient Items:**
- The Lazy Explorer, Lazy Forager, and Magiluminescence don't break when they are spent
- The Lazy Forager can be refueled by nightmare fuel (1 fuel per 25 pickups)
- The Lazy Forager's range has been doubled (from 4 to 8, or 1 tile to 2 tiles)
- The Lazy Explorer can be refueled by orange gems (1 gem for a full refuel)
- The Pick/Axe gains back 80% of the durability it would've used to kill an enemy if an enemy dies near it, allowing you to repair it by killing enemies with other weapons

**Minor miscellaneous changes:**
- Insulated Pack is no longer flammable, has the same number of slots as normal backpacks, and costs 1 gear instead of 3
- Deciduous turf now spawns the same birds as forest turf
- Beefalo no longer eat off of turf that has no grass
- Disease now kills things in 2-3 days instead of 30s to 1 day
- Lanterns can now be turned off and on by haunting (50% chance)

# List of changes I'm thinking about:
- Revamp the ancient guardian fight so it's not just boring rhino AI
- Make worldgen configuration options not suck? Might be beyond my abilities, though
- A Bernie buff?
- Changes to make smallbirds useful?