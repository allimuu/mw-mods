# Next Generation Combat

Brings Morrowind combat into the next generation! 

**Features**

* 100% chance to hit
* All attributes and skills in the game are still useful with 100% hit! (See below)
* Complete compatibility - no patches needed for weapoon, race, NPC mods, anything.
* Unique and interesting weapon perks to make combat more interesting! (See below)
* Works with ranged weapons.
* Everything works for all NPCs and creatures the same, creating a uniform and balanced combat experience.
* Creatures have a unique damage scaling formula where the more Strength they have the more damage they do - this makes creatures a little more balanced with all the other changes

## Attributes and skills

* __Weapon skill__ along with the weapon perks every 25 levels (see below), will now give a small damage boost equivalent to 20% extra damage at 100 (0.2% per level). (This affects NPCs/creatures too)
* __Fortify Attack__ will now give a flat damage bonus, 1pt is 0.5% more damage. Making Fortify Attack still very valuable! This will affect NPCs/creatures too, so combat will feel a little faster overall.
* __Sanctuary__ now reduces the damage taken by instead. The more Agility and Luck you have the more effect Sanctuary will have. (Example: At 50 Agility and 30 Luck, a 30pt Sanctuary spell will give you 5% damage reduction. At 100 Agility and 70 Luck, 30pt Sanctuary is 15% damage reduction)
* __Blind__ will still reduce chance to hit, so you can still miss due to being blinded (you will see a message if you do). But this is far more understandable, if you are blinded, missing at point blank makes more sense. Miss rate at 1% per pt like vanilla, 30 pt Blind will cause someone to have a 30% chance to miss.

## Weapon perks

Weapon perks give you unique bonuses for each weapon at skill level 25, 50, 75 and 100.

**Short blade** 

Short blades are about fast and deadly strikes, they now have a chance to Critical Strike (100% bonus damage) and cause Weakness to Weapons on each hit.

**Skill Level 25**

    10% chance to Critical Strike

**Skill Level 50** 

    20% chance to Critical Strike
    5% Weakness to Weapons On Hit

**Skill Level 75**
  
    35% chance to Critical Strike
    10% Weakness to Weapons On Hit

**Skill Level 100**
  
    50% chance to Critical Strike
    20% Weakness to Weapons On Hit


**Long blade**

Long blades are about precise powerful attacks, they now Multistrike on each 3rd hit causing more damage, with a chance to to do double damage on that hit.

**Skill Level 25**

    10% bonus damage every on third hit

**Skill Level 50** 

    20% bonus damage every on third hit
    5% chance for double damage

**Skill Level 75**
  
    35% bonus damage every on third hit
    10% chance for double damage

**Skill Level 100**
  
    50% bonus damage every on third hit
    20% chance for double damage

**Blunt weapon**

Blunt weapons are naturally stronger against armored targets (doing bonus damage on hit the more armor an enemy has) and have a chance to temporarily stun the enemy with their brute force (paralyze the enemy for 1 sec).

**Skill Level 25**

    10% chance to stun

**Skill Level 50** 

    15% chance to stun
    0.2% bonus damage per point of enemy Armor Rating

**Skill Level 75**
  
    20% chance to stun
    0.25% bonus damage per point of enemy Armor Rating

**Skill Level 100**
  
    30% chance to stun
    0.33% bonus damage per point of enemy Armor Rating

**Axe**

Axes will slash and tear the enemy causing bleeding (30% bonus damage over 5 seconds).

**Skill Level 25**

    10% chance to bleed

**Skill Level 50** 

    20% chance to bleed
    Bleed stacks up to 2 times

**Skill Level 75**
  
    30% chance to bleed
    Bleed stacks up to 3 times

**Skill Level 100**
  
    35% chance to bleed
    Bleed stacks up to 4 times

**Spear**

Spear is a tactical weapon with it you can maintain advantage by gaining Momentum (bonus damage per hit if you have more total percentage fatigue than your enemy) and a chance to gain Adrenaline Rush on hit (50pts Restore Fatigue for 3 seconds).

**Skill Level 25**

    15% bonus damage per hit if you have Momentum

**Skill Level 50** 

    30% bonus damage per hit if you have Momentum
    10% chance to gain Adrenaline Rush

**Skill Level 75**
  
    45% bonus damage per hit if you have Momentum
    20% chance to gain Adrenaline Rush

**Skill Level 100**
  
    60% bonus damage per hit if you have Momentum
    30% chance to gain Adrenaline Rush

## Installation

To install the mod, extract the archive into your Morrowind Data Files folder or use a mod organiser like MO2. 

Activate the .esp, it can be anywhere in your load order.

Requires latest MGE XE﻿ and the latest MWSE 2.1﻿ (if you already have MWSE installed, run MWSE-Update.exe inside your Morrowind folder to update it to the latest. This is NOT optional, you need the latest MWSE).

## Configuration

Important! Please only edit this if you know what you are doing editing JSON!

You can configure the mod by editing the configuration file in:

Data Files/MWSE/config/ngc.json

Here you can turn on more messaging:

showDamageNumbers - shows you extra info about how much extra damage you do
showDebugMessages - Note this is very spammy! But it will show everything if you want to debug something.

Tweak damage values:

weaponSkillModifier and attackBonusModifier control how much bonus damage you get from having weapon skill and attack bonus (scaled up to 100)
creatureBonusModifier is how much bonus damage from strength creatures get
All weapon perks are seperated into weaponTier1, 2, 3 and 4 for each respective tier
You can edit roll chances and modifiers here