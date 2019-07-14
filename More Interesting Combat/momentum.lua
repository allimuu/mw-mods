local this = {}

local common = require('More Interesting Combat.common')

local function bonusDamageForFatigue(targetActor, sourceActor, damage, damageMod)
    -- calculate the bonus damage based on fatigue of target
    local bonusDamage
    local targetDiff = (targetActor.fatigue.current / targetActor.fatigue.base) * 100
    local sourceDiff = (sourceActor.fatigue.current / sourceActor.fatigue.base) * 100
    if sourceDiff > targetDiff then
        -- source has higher fatigue % than target, so we do more damage
        bonusDamage = damage * damageMod
    end

    return bonusDamage
end

local function castAdrenalineRush(source)
    -- cast Arenaline Rush spell on source actor
    local adrenalineRushSpell = 'mic_adrenaline_rush'
    mwscript.addSpell({reference = source, spell = adrenalineRushSpell})
    timer.start({
        duration = 3,
        callback = function ()
            mwscript.removeSpell({reference = source, spell = adrenalineRushSpell})
        end,
    })
    if common.config.showMessages then
        tes3.messageBox({ message = "Adrenaline Rush!" })
    end
end

--[[ Perform momentum damage
--]]
function this.perform(source, damage, target)
    local sourceActor = source.mobile
    local targetActor = target.mobile
    local weaponSkill = sourceActor.spear.current
    local damageDone

    local rushChanceRoll = math.random(100)
    if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
        damageDone = bonusDamageForFatigue(targetActor, sourceActor, damage, common.config.weaponTier4.bonusDamageForFatigueMultiplier)
        if common.config.weaponTier4.adrenalineRushChance >= rushChanceRoll then
            castAdrenalineRush(source)
        end
    elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
        damageDone = bonusDamageForFatigue(targetActor, sourceActor, damage, common.config.weaponTier3.bonusDamageForFatigueMultiplier)
        if common.config.weaponTier3.adrenalineRushChance >= rushChanceRoll then
            castAdrenalineRush(source)
        end
    elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
        damageDone = bonusDamageForFatigue(targetActor, sourceActor, damage, common.config.weaponTier2.bonusDamageForFatigueMultiplier)
        if common.config.weaponTier2.adrenalineRushChance >= rushChanceRoll then
            castAdrenalineRush(source)
        end
    elseif weaponSkill >= common.config.weaponTier1.weaponSkillMin then
        damageDone = bonusDamageForFatigue(targetActor, sourceActor, damage, common.config.weaponTier1.bonusDamageForFatigueMultiplier)
    end

    if damageDone ~= nil then
        -- Apply the extra damage to the actor if we have it
        targetActor:applyHealthDamage(damageDone, false, true, false)
    end

    return damageDone
end

return this