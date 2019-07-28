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
local handToHandReferences = {}
local enemyHealthBar
local fadeTimer

-- this function is just here to clean up the old ability from legacy saves
local function updatePlayer()
    if mwscript.getSpellEffects({reference = tes3.player, spell = attackBonusSpell}) then
        mwscript.removeSpell({reference = tes3.player, spell = attackBonusSpell})
    end
end

-- this function is just here to clean up the old ability from legacy saves
local function onActorActivated(e)
    local hasSpell = mwscript.getSpellEffects({reference = e.reference, spell = attackBonusSpell})
    if hasSpell then
        mwscript.removeSpell({reference = e.reference, spell = attackBonusSpell})
    end
end

-- setup hit chance
local function alwaysHit(e)
    if common.config.toggleAlwaysHit then
        e.hitChance = 100
    end
end

-- on game load
local function onLoaded(e)
    updatePlayer()

    -- get enemy health bar widget for hand to hand
    local menu_multi = tes3ui.registerID("MenuMulti")
    local health_bar = tes3ui.registerID("MenuMulti_npc_health_bar")
    enemyHealthBar = tes3ui.findMenu(menu_multi):findChild(health_bar)

    -- set GMSTs
    local minHandToHand = tes3.findGMST("fMinHandToHandMult")
    local maxHandToHand = tes3.findGMST("fMaxHandToHandMult")
    minHandToHand.value = 0
    maxHandToHand.value = 0
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
        -- clean up hand to hand tracking
        handToHandReferences = {}
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
local function attackBonusMod(attackBonus)
    return ((attackBonus * common.config.attackBonusModifier) / 100)
end

local function coreBonusDamage(damage, weaponoSkillLevel, attackBonus)
    local damageMod
    local fortifyAttackMod = 0

    -- modify damage for weapon skill bonus
    local weaponSkillMod = ((weaponoSkillLevel * common.config.weaponSkillModifier) / 100)

    -- modify damage for Fortify Attack bonus
    if common.config.toggleAlwaysHit then
        fortifyAttackMod = attackBonusMod(attackBonus)
    end

    damageMod = damage * (weaponSkillMod + fortifyAttackMod)

    return damageMod
end

-- vanilla game strength modifier
local function strengthModifier(damage, strength)
    return damage * (0.5 + (strength / 100))
end

local function damageReductionFromSanctuary(defender, damageTaken)
    local damageReduced
    -- reduction from sanctuary
    local scantuaryMod = (((defender.agility.current + defender.luck.current) - 30) * common.config.sanctuaryModifier) / 100
    local reductionFromSanctuary
    if (scantuaryMod >= 0.1) then
        reductionFromSanctuary = (defender.sanctuary * scantuaryMod) / 100
    else
        reductionFromSanctuary = (defender.sanctuary * 0.1) / 100 -- minimum sanctuary reduction
    end

    if reductionFromSanctuary then
        damageReduced = damageTaken * reductionFromSanctuary
    end

    return damageReduced
end

-- custom knockdown
local function playKnockdown(targetReference, source)
    if (common.config.showMessages and source == tes3.player) then
        tes3.messageBox({ message = "Knockdown!" })
    end
    tes3.playAnimation({
        reference = targetReference,
        group = 0x22,
        startFlag = 1,
    })
    timer.start({
        duration = 3,
        callback = function ()
            tes3.playAnimation({
                reference = targetReference,
                group = 0x0,
                startFlag = 0,
            })
        end,
        iterations = 1
    })
end

local function onDamage(e)
    local attacker = e.attacker
    local defender = e.mobile

    local source = e.attackerReference
    local target = e.reference
    local sourceActor = attacker
    local targetActor = defender

    local damageTaken = e.damage
    local damageAdded
    local damageReduced

    if e.source == 'attack' then
        if attacker and common.config.toggleAlwaysHit then
            -- roll for blind first
            if attacker.blind > 0 then
                local missChanceRoll = math.random(100)
                if attacker.blind >= missChanceRoll then
                    -- you blind, you miss
                    if (common.config.showMessages and source == tes3.player) then
                        tes3.messageBox({ message = "Missed!" })
                    end
                    -- no damage
                    return
                end
            end
        end

        if defender and common.config.toggleAlwaysHit then
            -- reduction from sanctuary
            local reductionFromSanctuary = damageReductionFromSanctuary(defender, damageTaken)
            if reductionFromSanctuary then
                damageTaken = damageTaken - reductionFromSanctuary
                damageReduced = reductionFromSanctuary
            end
        end

        if attacker then
            -- core damage values
            local weapon = e.attacker.readiedWeapon
            local sourceAttackBonus = sourceActor.attackBonus

            if attacker.actorType == 0 then
                -- standard creature bonus
                local fortifyAttackMod = 0
                if common.config.toggleAlwaysHit then
                    fortifyAttackMod = attackBonusMod(sourceAttackBonus)
                end
                local creatureStrengthMod = ((sourceActor.strength.current * common.config.creatureBonusModifier) / 100)
                damageAdded = damageTaken * (fortifyAttackMod + creatureStrengthMod)
            elseif weapon then
                -- handle player/NPC attacks with weapons

                if weapon.object.type > 8 then
                    -- ranged hit
                    local weaponSkill = sourceActor.marksman.current
                    -- core bonus damage for ranged hits
                    damageAdded = coreBonusDamage(damageTaken, weaponSkill, sourceAttackBonus)
                elseif weapon.object.type > 6 then
                    -- axe
                    local weaponSkill = sourceActor.axe.current
                    damageAdded = coreBonusDamage(damageTaken, weaponSkill, sourceAttackBonus)

                    if common.config.toggleWeaponPerks then
                        local damageDone = bleed.perform(damageTaken, target, targetActor, weaponSkill)
                        if (damageDone ~= nil and source == tes3.player) then
                            damageMessage("Bleeding!", damageDone)
                        end
                    end
                elseif weapon.object.type > 5 then
                    -- spear
                    local weaponSkill = sourceActor.spear.current
                    damageAdded = coreBonusDamage(damageTaken, weaponSkill, sourceAttackBonus)

                    if common.config.toggleWeaponPerks then
                        local damageDone = momentum.perform(damageTaken, source, sourceActor, targetActor, weaponSkill)
                        if damageDone ~= nil then
                            if (source == tes3.player and common.config.showDamageNumbers) then
                                damageMessage("Momentum!", damageDone)
                            end
                            damageAdded = damageAdded + damageDone
                        end
                    end
                elseif weapon.object.type > 2 then
                    -- blunt
                    local weaponSkill = sourceActor.bluntWeapon.current
                    local stunned
                    local damageDone
                    damageAdded = coreBonusDamage(damageTaken, weaponSkill, sourceAttackBonus)

                    if common.config.toggleWeaponPerks then
                        stunned, damageDone = stun.perform(damageTaken, target, targetActor, weaponSkill)
                        if (stunned and source == tes3.player) then
                            damageMessage("Stunned!", damageDone)
                        elseif (source == tes3.player and common.config.showDamageNumbers) then
                            -- just show extra damage for blunt weapon if no stun
                            damageMessage("", damageDone)
                        end
                        damageAdded = damageAdded + damageDone
                    end
                elseif weapon.object.type > 0 then
                    -- long blade
                    local weaponSkill = sourceActor.longBlade.current
                    damageAdded = coreBonusDamage(damageTaken, weaponSkill, sourceAttackBonus)

                    if common.config.toggleWeaponPerks then
                        common.multistrikeCounters = multistrike.checkCounters(source.id)
                        if common.multistrikeCounters[source.id] == 3 then
                            local damageDone = multistrike.perform(damageTaken, source, weaponSkill)
                            common.multistrikeCounters[source.id] = 0
                            if source == tes3.player then
                                damageMessage("Multistrike!", damageDone)
                            end
                            damageAdded = damageAdded + damageDone
                        end
                    end
                elseif weapon.object.type > -1 then
                    -- short blade
                    local weaponSkill = sourceActor.shortBlade.current
                    damageAdded = coreBonusDamage(damageTaken, weaponSkill, sourceAttackBonus)

                    if common.config.toggleWeaponPerks then
                        local damageDone = critical.perform(damageTaken, target, weaponSkill)
                        if damageDone ~= nil then
                            if source == tes3.player then
                                damageMessage("Critical strike!", damageDone)
                            end
                            damageAdded = damageAdded + damageDone
                        end
                    end
                end
            end
        end
    end

    if e.source == nil and handToHandReferences[target.id] then
        -- nil sources of damage come from bleed and hand to hand so are special cases
        local handToHandAttacker = handToHandReferences[target.id]
        -- reset the attacker refernece
        handToHandReferences[target.id] = nil

        if common.config.toggleAlwaysHit then
            -- roll for blind first
            if handToHandAttacker.blind > 0 then
                local missChanceRoll = math.random(100)
                if handToHandAttacker.blind >= missChanceRoll then
                    -- you blind, you miss
                    if (common.config.showMessages and source == tes3.player) then
                        tes3.messageBox({ message = "Missed!" })
                    end
                    -- no damage
                    return
                end
            end
        end

        if defender and common.config.toggleAlwaysHit then
            -- reduction from sanctuary
            local reductionFromSanctuary = damageReductionFromSanctuary(defender, damageTaken)
            if reductionFromSanctuary then
                damageTaken = damageTaken - reductionFromSanctuary
                damageReduced = reductionFromSanctuary
            end
        end

        damageAdded = coreBonusDamage(damageTaken, handToHandAttacker.weaponSkill, handToHandAttacker.attackBonus)
    end

    if damageAdded then
        -- we already have damageReduced taken into account with damageTaken
        e.damage = damageTaken + damageAdded
        if common.config.showDebugMessages then
            local showReducedDamage = 0
            if damageReduced then
                showReducedDamage = damageReduced
            end
            tes3.messageBox({ message = "Final damage: " .. math.round(e.damage, 2) .. ". Reduced: " .. math.round(showReducedDamage, 2) .. ". Added: " .. math.round(damageAdded, 2)  })
        end
    elseif damageReduced then
        -- we don't have any damage added but we still have damage reduced
        e.damage = e.damage - damageReduced
        if common.config.showDebugMessages then
            tes3.messageBox({ message = "Reduced: " .. math.round(damageReduced, 2) })
        end
    end
end

local function onAttack(e)
    -- this is mainly for hand to hand
    local source = e.reference
    local sourceActor = e.mobile
    local target = e.targetReference
    local targetActor = e.targetMobile
    local weapon = sourceActor.readiedWeapon

    if weapon == nil and targetActor then
        -- this must be a hand to hand attack
        if sourceActor.handToHand then
            local bonusDamage
            local weaponSkill = sourceActor.handToHand.current

            handToHandReferences[target.id] = {
                attackerReference = source,
                weaponSkill = weaponSkill,
                attackBonus = sourceActor.attackBonus,
                blind = sourceActor.blind
            }

            local knockdownChance = math.random(100)
            local agilityChanceMod = common.config.agilityKnockdownChanceBaseModifier
            if targetActor.agility.current < 100 then
                agilityChanceMod = common.config.agilityKnockdownChanceBaseModifier * ((100 - targetActor.agility.current) / 100)
            end
            if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
                if (common.config.weaponTier4.handToHandKnockdownChance * agilityChanceMod) >= knockdownChance then
                    playKnockdown(target, source)
                end
                bonusDamage = math.random(common.config.weaponTier4.handToHandBaseDamageMin, common.config.weaponTier4.handToHandBaseDamageMax)
            elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
                if (common.config.weaponTier3.handToHandKnockdownChance * agilityChanceMod) >= knockdownChance then
                    playKnockdown(target, source)
                end
                bonusDamage = math.random(common.config.weaponTier3.handToHandBaseDamageMin, common.config.weaponTier3.handToHandBaseDamageMax)
            elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
                if (common.config.weaponTier2.handToHandKnockdownChance * agilityChanceMod) >= knockdownChance then
                    playKnockdown(target, source)
                end
                bonusDamage = math.random(common.config.weaponTier2.handToHandBaseDamageMin, common.config.weaponTier2.handToHandBaseDamageMax)
            elseif weaponSkill >= common.config.weaponTier1.weaponSkillMin then
                if (common.config.weaponTier1.handToHandKnockdownChance * agilityChanceMod) >= knockdownChance then
                    playKnockdown(target, source)
                end
                bonusDamage = math.random(common.config.weaponTier1.handToHandBaseDamageMin, common.config.weaponTier1.handToHandBaseDamageMax)
            else
                bonusDamage = math.random(common.config.handToHandBaseDamageMin, common.config.handToHandBaseDamageMax)
            end

            if bonusDamage then
                bonusDamage = bonusDamage + strengthModifier(bonusDamage, sourceActor.strength.current)
                local armorGMST = tes3.findGMST("fCombatArmorMinMult")
                local totalAR = common.getARforTarget(target)
                local damageMod = bonusDamage / (bonusDamage + totalAR)
                if damageMod <= armorGMST.value then
                    damageMod = armorGMST.value
                end
                bonusDamage = bonusDamage * damageMod
                targetActor:applyHealthDamage(bonusDamage, false, true, false)

                if source == tes3.player then
                    -- show enemy health bar
                    enemyHealthBar.visible = true
                    enemyHealthBar:setPropertyFloat("PartFillbar_current", targetActor.health.current)
                    enemyHealthBar:setPropertyFloat("PartFillbar_max", targetActor.health.base)

                    if fadeTimer == nil or fadeTimer.state == timer.expired  then
                        fadeTimer = timer.start({
                            duration = 3,
                            callback = function ()
                                enemyHealthBar.visible = false
                            end,
                            iterations = 1
                        })
                    elseif fadeTimer.state == timer.active then
                        fadeTimer:reset()
                    end
                end
            end
        end
    end
end

local function onDamaged(e)
    -- disable knockdowns
    if (common.config.toggleAlwaysHit and common.config.disableDefaultKnockdowns) then
        e.checkForKnockdown = false
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
        event.register("loaded", onLoaded)
        event.register("calcHitChance", alwaysHit)
        event.register("combatStopped", onCombatEnd)
        event.register("mobileActivated", onActorActivated)
        event.register("attack", onAttack)
        event.register("damage", onDamage)
        event.register("damaged", onDamaged)

		mwse.log("[Next Generation Combat] Initialized version v%d", version)
	end
end
event.register("initialized", initialized)