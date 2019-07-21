--
local version = 1.0

-- modules
local common = require('ngc.common')
local multistrike
local critical
local bleed
local stun
local momentum
local attackBonusSpell = "ngc_ready_to_strike"

-- set up the always hit spell for player
local function updatePlayer(e)
    if not mwscript.getSpellEffects({reference = tes3.player, spell = attackBonusSpell}) then
        mwscript.addSpell({reference = tes3.player, spell = attackBonusSpell})
    end
end

-- set up the always hit spell for NPCs
local function onActorActivated(e)
    local hasSpell = mwscript.getSpellEffects({reference = e.reference, spell = attackBonusSpell})
    if not hasSpell then
        mwscript.addSpell({reference = e.reference, spell = attackBonusSpell})
        if common.showDebugMessages then
            tes3.messageBox({ message = "Adding ready to strike to " .. e.reference.id })
        end
    end
end

-- clean up after combat
local function onCombatEnd(e)
    if (e.actor.reference == tes3.player) then
        -- reset multistrike counters
        common.multistrikeCounters = {}
        common.currentArmorCache = {}
        -- remove expose weakness on all currently exposed
        for targetId,spellId in pairs(common.currentlyExposed) do
            mwscript.removeSpell({reference = targetId, spell = spellId})
        end
        common.currentlyExposed = {}
        -- remove all bleeds and cancel all timers
        for targetId,_ in pairs(common.currentlyBleeding) do
            common.currentlyBleeding[targetId].timer:cancel()
        end
        common.currentlyBleeding = {}
    end
end

local function damageMessage(damageType, damageDone)
    if common.config.showMessages then
        local msgString = damageType
        if (common.config.showDamageNumbers and damageDone) then
            msgString = msgString .. " Extra damage: " .. math.round(damageDone, 2)
        end
        tes3.messageBox({ message = msgString })
    end
end

-- core damage features
local function coreBonusDamage(damage, targetActor, weaponoSkillLevel, attackBonus)
    local damageMod

    -- modify damage for weapon skill bonus
    local weaponSkillMod = ((weaponoSkillLevel * common.config.weaponSkillModifier) / 100)

    -- modify damage for Fortify Attack bonus
    local fortifyAttackMod = (((attackBonus - 100) * common.config.attackBonusModifier) / 100)

    damageMod = damage * (weaponSkillMod + fortifyAttackMod)

    if common.config.showDebugMessages then
        tes3.messageBox({ message = "Bonus normal hit damage: " .. damageMod })
    end

    targetActor:applyHealthDamage(damageMod, false, true, false)
end

-- vanilla game strength modifier
local function strengthModifier(physicalDamage, strength)
    return physicalDamage * (0.5 + (strength / 100))
end

-- perform weapon perks
local function onAttack(e)
	--
	local source = e.reference
    local sourceActor = source.mobile
    local target = e.targetReference
	local action = e.mobile.actionData
    local weapon = e.mobile.readiedWeapon

    -- core damage values
    local sourceAttackBonus = sourceActor.attackBonus

    if (source and target and e.mobile.actorType == 0) then
        local targetActor = target.mobile
        -- standard creature bonus
        local damageMod = strengthModifier(action.physicalDamage, sourceActor.strength.current)
        local damageDone = damageMod * ((sourceActor.strength.current * common.config.creatureBonusModifier) / 100)
        if common.config.showDebugMessages then
            tes3.messageBox({ message = "Bonus creature hit damage: " .. damageDone })
        end
        targetActor:applyHealthDamage(damageDone, false, true, false)
        return
    end

    -- handle player/NPC attacks
    if source and weapon and target then
        local targetActor = target.mobile

        if action.physicalDamage == 0 then
			-- ignore misses
        elseif weapon.object.type > 8 then
            -- ranged hit
            local weaponSkill = sourceActor.marksman.current
            -- get damage after strength mod
            local damageMod = strengthModifier(action.physicalDamage, sourceActor.strength.current)
            -- core bonus damage for ranged hits
            coreBonusDamage(damageMod, targetActor, weaponSkill, sourceAttackBonus)
        elseif action.physicalDamage > 0 then
            -- we have a hit with damage
            local damageDone
            -- get damage after strength mod
            local damageMod = strengthModifier(action.physicalDamage, sourceActor.strength.current)

            if weapon.object.type > 6 then
                -- axe
                local weaponSkill = sourceActor.axe.current
                coreBonusDamage(damageMod, targetActor, weaponSkill, sourceAttackBonus)

                if common.config.toggleWeaponPerks then
                    damageDone = bleed.perform(damageMod, target, weaponSkill)
                    if (damageDone ~= nil and source == tes3.player) then
                        damageMessage("Bleeding!", damageDone)
                    end
                end
            elseif weapon.object.type > 5 then
                -- spear
                local weaponSkill = sourceActor.spear.current
                coreBonusDamage(damageMod, targetActor, weaponSkill, sourceAttackBonus)

                if common.config.toggleWeaponPerks then
                    damageDone = momentum.perform(source, damageMod, target, weaponSkill)
                    if (damageDone ~= nil and source == tes3.player and common.config.showDamageNumbers) then
                        damageMessage("Momentum!", damageDone)
                    end
                end
            elseif weapon.object.type > 2 then
                -- blunt
                local weaponSkill = sourceActor.bluntWeapon.current
                local stunned
                coreBonusDamage(damageMod, targetActor, weaponSkill, sourceAttackBonus)

                if common.config.toggleWeaponPerks then
                    stunned, damageDone = stun.perform(damageMod, target, weaponSkill)
                    if (stunned and source == tes3.player) then
                        damageMessage("Stunned!", damageDone)
                    elseif (source == tes3.player and common.config.showDamageNumbers) then
                        -- just show extra damage for blunt weapon if no stun
                        damageMessage("", damageDone)
                    end
                end
            elseif weapon.object.type > 0 then
                -- long blade
                local weaponSkill = sourceActor.longBlade.current
                coreBonusDamage(damageMod, targetActor, weaponSkill, sourceAttackBonus)

                if common.config.toggleWeaponPerks then
                    common.multistrikeCounters = multistrike.checkCounters(source.id)
                    if common.multistrikeCounters[source.id] == 3 then
                        damageDone = multistrike.perform(source, damageMod, target, weaponSkill)
                        common.multistrikeCounters[source.id] = 0
                        if source == tes3.player then
                            damageMessage("Multistrike!", damageDone)
                        end
                    end
                end
            elseif weapon.object.type > -1 then
                -- short blade
                local weaponSkill = sourceActor.shortBlade.current
                coreBonusDamage(damageMod, targetActor, weaponSkill, sourceAttackBonus)

                if common.config.toggleWeaponPerks then
                    damageDone = critical.perform(damageMod, target, weaponSkill)
                    if (damageDone ~= nil and source == tes3.player) then
                        damageMessage("Critical strike!", damageDone)
                    end
                end
            end
        end
    end
end

local function onDamage(e)
    local attacker = e.attacker
    local defender = e.mobile
    local damageReduced

    if attacker and e.source == 'attack' then
        -- roll for blind first
        if attacker.blind > 0 then
            local missChanceRoll = math.random(100)
            if attacker.blind >= missChanceRoll then
                -- you blind, you miss
                if (common.config.showMessages and e.attackerReference == tes3.player) then
                    tes3.messageBox({ message = "Missed!" })
                end
                -- no damage
                return
            end
        end
    end

    if defender and e.source == 'attack' then
        -- reduction from sanctuary
        local scantuaryMod = (((defender.agility.current + defender.luck.current) - 30) * common.config.sanctuaryModifier) / 100
        local reductionFromSanctuary
        if (scantuaryMod >= 0.1) then
            reductionFromSanctuary = (defender.sanctuary * scantuaryMod) / 100
        else
            reductionFromSanctuary = (defender.sanctuary * 0.1) / 100 -- minimum sanctuary reduction
        end

        if reductionFromSanctuary then
            damageReduced = e.damage * reductionFromSanctuary
        end
    end

    -- if we have damage reduction
    if damageReduced and e.source == 'attack' then
        e.damage = e.damage - damageReduced
        if common.config.showDebugMessages then
            tes3.messageBox({ message = "Damage reduced: " .. damageReduced })
        end
    end
end

local function initialized(e)
	if tes3.isModActive("Next Generation Combat.esp") then
        common.loadConfig()

        -- load modules
        multistrike = require("ngc.perks.multistrike")
        critical = require("ngc.perks.critical")
        bleed = require("ngc.perks.bleed")
        stun = require("ngc.perks.stun")
        momentum = require("ngc.perks.momentum")

        -- register events
        event.register("loaded", updatePlayer)
        event.register("cellChanged", updatePlayer)
        event.register("mobileActivated", onActorActivated)
        event.register("combatStopped", onCombatEnd)
        event.register("attack", onAttack)
        event.register("damage", onDamage)

		mwse.log("[Next Generation Combat] Initialized version v%d", version)
        mwse.log(json.encode(common.config, {indent=true}))
	end
end
event.register("initialized", initialized)