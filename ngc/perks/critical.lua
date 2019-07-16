local this = {}

local common = require('ngc.common')

local function castExposeWeakness(target, level)
    mwscript.addSpell({reference = target, spell = 'mic_expose_weakness_' .. level})
    common.currentlyExposed[target.id] = 'mic_expose_weakness_' .. level
end


--[[ Perform critical strike (short blades)
--]]
function this.perform(source, damage, target)
    local sourceActor = source.mobile
    local targetActor = target.mobile
    local weaponSkill = sourceActor.shortBlade.current
    local damageDone

    local critChanceRoll = math.random(100)
    if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
        if common.config.weaponTier4.criticalStrikeChance >= critChanceRoll then
            damageDone = damage * (common.config.criticalStrikeMultiplier + 0.2)
            castExposeWeakness(target, 3)
        end
    elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
        if common.config.weaponTier3.criticalStrikeChance >= critChanceRoll then
            damageDone = damage * (common.config.criticalStrikeMultiplier + 0.1)
            castExposeWeakness(target, 2)
        end
    elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
        if common.config.weaponTier2.criticalStrikeChance >= critChanceRoll then
            damageDone = damage * (common.config.criticalStrikeMultiplier + 0.05)
            castExposeWeakness(target, 1)
        end
    elseif weaponSkill >= common.config.weaponTier1.weaponSkillMin then
        if common.config.weaponTier1.criticalStrikeChance >= critChanceRoll then
            damageDone = damage * common.config.criticalStrikeMultiplier
        end
    else
        return
    end

    if damageDone ~= nil then
    -- Apply the extra damage to the actor if we have got a crit
        targetActor:applyHealthDamage(damageDone, false, true, false)
        return damageDone
    else
        return
    end
end

return this