this = {}

local common = require('More Interesting Combat.common')

local function castExposeWeakness(target, level)
    mwscript.addSpell({reference = target, spell = 'mic_expose_weakness_' .. level})
    common.currentlyExposed[target.id] = 'mic_expose_weakness_' .. level
end


--[[ Perform critical strike (short blades)
     A critical strike 50% more damage on a hit. 
     And 5%, 10% and 20% depending on weapon tier expose weakness
     (Weakness to Normal Weapons).
--]]
function this.perform(source, damage, target, exposeWeaknessRefs)
    local sourceActor = source.mobile
    local targetActor = target.mobile
    local weaponSkill = sourceActor.shortBlade.current
    local damageDone
    local spellRef

    critChanceRoll = math.random(100)
    if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
        if common.config.weaponTier4.criticalStrikeChance >= critChanceRoll then
            damageDone = damage * common.config.criticalStrikeMultiplier
            castExposeWeakness(target, 3)
            -- simulate the damage done by the critical strike scalilng with expose weakness level
            damageDone = damageDone * 1.2
        end
    elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
        if common.config.weaponTier3.criticalStrikeChance >= critChanceRoll then
            damageDone = damage * common.config.criticalStrikeMultiplier
            castExposeWeakness(target, 2)
            -- simulate the damage done by the critical strike scalilng with expose weakness level
            damageDone = damageDone * 1.1
        end
    elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
        if common.config.weaponTier2.criticalStrikeChance >= critChanceRoll then
            damageDone = damage * common.config.criticalStrikeMultiplier
            castExposeWeakness(target, 1)
            -- simulate the damage done by the critical strike scalilng with expose weakness level
            damageDone = damageDone * 1.05
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
        targetActor:applyHealthDamage(damageDone, false, false, false)
        return damageDone
    else
        return
    end
end

return this