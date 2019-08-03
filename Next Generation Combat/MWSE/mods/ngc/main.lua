--
local version = 1.0

-- modules
local common = require('ngc.common')
local multistrike
local critical
local bleed
local stun
local momentum
local block
-- locals
local attackBonusSpell = "ngc_ready_to_strike"
local handToHandReferences = {}
local currentlyKnockedDown = {}
local knockdownPlayer = false
local enemyHealthBar
local fadeTimer
local playerKnockdownTimer

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

-- setup hit chance and block chance
local function alwaysHit(e)
    if common.config.toggleAlwaysHit then
        e.hitChance = 100
    end

    if common.config.toggleActiveBlocking then
        if e.target == tes3.player then
            if block.currentlyActiveBlocking then
                if common.config.showDebugMessages then
                    tes3.messageBox({ message = "Setting max block!" })
                end
                block.setMaxBlock()

                -- check if reduced min fatigue for active blocking
                local fatigueMin = tes3.mobilePlayer.fatigue.base * common.config.activeBlockingFatigueMin
                if tes3.mobilePlayer.fatigue.current < fatigueMin then
                    block.activeBlockingOff()
                end
            else
                block.resetMaxBlock()
            end
        end

        if e.target ~= tes3.player then
            block.resetMaxBlock()
        end
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
    -- vanilla hand to hand disabled
    local minHandToHand = tes3.findGMST("fMinHandToHandMult")
    local maxHandToHand = tes3.findGMST("fMaxHandToHandMult")
    minHandToHand.value = 0
    maxHandToHand.value = 0

    -- tweak knockdown values
    local knockdownMult = tes3.findGMST("fKnockDownMult")
    local knockdownOddsMult = tes3.findGMST("iKnockDownOddsMult")
    knockdownMult.value = common.config.knockdownMultGMST
    knockdownOddsMult.value = common.config.knockdownOddsMultGMST

    -- tweak fatigue combat values
    local fatigueAttackMult = tes3.findGMST("fFatigueAttackMult")
    fatigueAttackMult.value = common.config.fatigueAttackMultGMST

    -- get block default GMSTs
    local blockMaxGMST = tes3.findGMST("iBlockMaxChance")
    local blockMinGMST = tes3.findGMST("iBlockMinChance")
    block.maxBlockDefault = blockMaxGMST.value
    block.minBlockDefault = blockMinGMST.value
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
        -- clean up knockdown tracking
        currentlyKnockedDown = {}
        knockdownPlayer = false
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

-- Core damage features
-- Attack bonus modifier for damage
local function attackBonusMod(attackBonus)
    return ((attackBonus * common.config.attackBonusModifier) / 100)
end

-- Bonus damage for weapon skill and attack bonus (if always hit)
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

-- Calculate the reduction from the defenders sanctuary bonus
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

-- custom knockdown event
local function playKnockdown(targetReference, source)
    if (common.config.showMessages and source == tes3.player) then
        tes3.messageBox({ message = "Knockdown!" })
    end
    currentlyKnockedDown[targetReference.id] = true
    tes3.playAnimation({
        reference = targetReference,
        group = 0x22,
        startFlag = 1,
    })
    timer.start({
        duration = 3,
        callback = function ()
            currentlyKnockedDown[targetReference.id] = nil
            tes3.playAnimation({
                reference = targetReference,
                group = 0x0,
                startFlag = 0,
            })
        end,
        iterations = 1
    })
end

-- Calculate the knockdown chance modifier scaling with agility
local function agilityKnockdownChance(targetActor)
    local agilityChanceMod = 1
    -- full knockdown chance unless Agility is higher than 30
    if (targetActor.agility.current >= 30 and targetActor.agility.current < 100) then
        agilityChanceMod = ((100 - targetActor.agility.current) / 100)
    end
    if agilityChanceMod < common.config.agilityKnockdownChanceMinMod then
        agilityChanceMod = common.config.agilityKnockdownChanceMinMod
    end

    return agilityChanceMod
end


-- Damage events for weapon perks
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

    -- on hand to hand attacks that are not from werewolves
    if (weapon == nil and targetActor and sourceActor.werewolf == false and common.config.toggleWeaponPerks) then
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

            local bonusKnockdownMod
            local knockdownChance = math.random(100)
            local agilityChanceMod = agilityKnockdownChance(targetActor)
            if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
                if (common.config.weaponTier4.handToHandKnockdownChance * agilityChanceMod) >= knockdownChance then
                    if target == tes3.player then
                        knockdownPlayer = true
                    else
                        playKnockdown(target, source)
                    end
                end
                bonusDamage = math.random(common.config.weaponTier4.handToHandBaseDamageMin, common.config.weaponTier4.handToHandBaseDamageMax)
                if currentlyKnockedDown[target.id] or knockdownPlayer then
                    bonusKnockdownMod = common.config.weaponTier4.handToHandKnockdownDamageMultiplier
                end
            elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
                if (common.config.weaponTier3.handToHandKnockdownChance * agilityChanceMod) >= knockdownChance then
                    if target == tes3.player then
                        knockdownPlayer = true
                    else
                        playKnockdown(target, source)
                    end
                end
                bonusDamage = math.random(common.config.weaponTier3.handToHandBaseDamageMin, common.config.weaponTier3.handToHandBaseDamageMax)
                if currentlyKnockedDown[target.id] or knockdownPlayer then
                    bonusKnockdownMod = common.config.weaponTier3.handToHandKnockdownDamageMultiplier
                end
            elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
                if (common.config.weaponTier2.handToHandKnockdownChance * agilityChanceMod) >= knockdownChance then
                    if target == tes3.player then
                        knockdownPlayer = true
                    else
                        playKnockdown(target, source)
                    end
                end
                bonusDamage = math.random(common.config.weaponTier2.handToHandBaseDamageMin, common.config.weaponTier2.handToHandBaseDamageMax)
                if currentlyKnockedDown[target.id] or knockdownPlayer then
                    bonusKnockdownMod = common.config.weaponTier2.handToHandKnockdownDamageMultiplier
                end
            elseif weaponSkill >= common.config.weaponTier1.weaponSkillMin then
                if (common.config.weaponTier1.handToHandKnockdownChance * agilityChanceMod) >= knockdownChance then
                    if target == tes3.player then
                        knockdownPlayer = true
                    else
                        playKnockdown(target, source)
                    end
                end
                bonusDamage = math.random(common.config.weaponTier1.handToHandBaseDamageMin, common.config.weaponTier1.handToHandBaseDamageMax)
                if currentlyKnockedDown[target.id] or knockdownPlayer then
                    bonusKnockdownMod = common.config.weaponTier1.handToHandKnockdownDamageMultiplier
                end
            else
                bonusDamage = math.random(common.config.handToHandBaseDamageMin, common.config.handToHandBaseDamageMax)
            end

            if bonusDamage then
                bonusDamage = bonusDamage + strengthModifier(bonusDamage, sourceActor.strength.current)
                if bonusKnockdownMod then
                    local bonusKnockdownDamage = (bonusDamage * bonusKnockdownMod)
                    bonusDamage = bonusDamage + bonusKnockdownDamage
                    if (source == tes3.player and common.config.showDamageNumbers) then
                        -- just show extra damage for knockdown
                        damageMessage("", bonusDamage)
                    end
                end
                local armorGMST = tes3.findGMST("fCombatArmorMinMult")
                local totalAR = common.getARforTarget(target)
                local damageMod = bonusDamage / (bonusDamage + totalAR)
                if damageMod <= armorGMST.value then
                    damageMod = armorGMST.value
                end
                bonusDamage = bonusDamage * damageMod
                if knockdownPlayer then
                    -- we want to knckdown the player
                    if common.config.showDebugMessages then
                        tes3.messageBox({ message = "Knocking down player!" })
                    end
                    local currentFatigue = tes3.mobilePlayer.fatigue.current
                    tes3.setStatistic({ reference = tes3.player, name = "fatigue", current = -100 })
                    if playerKnockdownTimer == nil or playerKnockdownTimer.state == timer.expired  then
                        playerKnockdownTimer = timer.start({
                            duration = 2,
                            callback = function ()
                                knockdownPlayer = false
                                tes3.setStatistic({ reference = tes3.player, name = "fatigue", current = currentFatigue })
                            end,
                            iterations = 1
                        })
                    end
                end
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

local function onExerciseSkill(e)
    local weaponSkills = {
        [0] = true, -- block
        [4] = true, -- blunt
        [5] = true, -- long blade
        [6] = true, -- axe
        [7] = true, -- spear
        [22] = true, -- short blade
        [26] = true, -- hand to hand
    }
    local armorSkills = {
        [2] = true, -- medium armor
        [3] = true, -- heavy armor
        [17] = true, -- unarmored
        [21] = true, -- light armor
    }
    local modifier

    if weaponSkills[e.skill] then
        -- this is a weapon skill
        local weaponSkillLevel = tes3.mobilePlayer.skills[e.skill+1].base
        modifier = common.config.weaponSkillGainBaseModifier
        if weaponSkillLevel >= common.config.weaponTier4.weaponSkillMin then
            modifier = common.config.weaponTier4.weaponSkillGainModifier
        elseif weaponSkillLevel >= common.config.weaponTier3.weaponSkillMin then
            modifier = common.config.weaponTier3.weaponSkillGainModifier
        elseif weaponSkillLevel >= common.config.weaponTier2.weaponSkillMin then
            modifier = common.config.weaponTier2.weaponSkillGainModifier
        elseif weaponSkillLevel >= common.config.weaponTier1.weaponSkillMin then
            modifier = common.config.weaponTier1.weaponSkillGainModifier
        end
    end

    if armorSkills[e.skill] then
        modifier = common.config.armorSkillGainBaseModifier
    end

    if modifier then
        if common.config.showSkillGainDebugMessages then
            tes3.messageBox({ message = "Base skill exp: " .. e.progress .. " Modified skill exp: " .. (e.progress * modifier)})
        end
        e.progress = e.progress * modifier
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
        block = require("ngc.block")

        -- register events
        event.register("loaded", onLoaded)
        event.register("calcHitChance", alwaysHit)
        event.register("combatStopped", onCombatEnd)
        event.register("mobileActivated", onActorActivated)
        event.register("attack", onAttack)
        event.register("damage", onDamage)
        event.register("exerciseSkill", onExerciseSkill)
        if common.config.toggleActiveBlocking then
            event.register("keyDown", block.keyPressed, { filter = common.config.activeBlockKeyCode } )
            event.register("keyUp", block.keyReleased, { filter = common.config.activeBlockKeyCode } )
            -- release block on any menu mode enter
            event.register("menuEnter", block.keyReleased)
            event.register("uiCreated", block.createBlockUI, { filter = "MenuMulti" })
        end

		mwse.log("[Next Generation Combat] Initialized version v%d", version)
	end
end
event.register("initialized", initialized)