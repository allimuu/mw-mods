local this = {}

local common = require('More Interesting Combat.common')

--[[ Check the counters for each referenced source
     increment or reset if already reached 3 hits
--]]
function this.checkCounters(ref)
    local counters = common.multistrikeCounters

    if counters[ref] ~= nil then
        if counters[ref] < common.config.multistrikeStrikesNeeded then
            counters[ref] = counters[ref] + 1
        else
            counters[ref] = 0
        end
    else
        counters[ref] = 0
    end

    return counters
end

local function bonusDamage(damage)
    return damage * common.config.multistrikeBonuseDamageMultiplier
end

--[[ Perform multistrike (long blades)
     A multistrike is 10%, 20%, 30% or 50% more damage depending
     on weapon tier. With 5%, 10% or 20% chance to be 100% more 
     damage instead, in the last three tiers.
--]]
function this.perform(source, damage, target)
    local sourceActor = source.mobile
    local targetActor = target.mobile
    local weaponSkill = sourceActor.longBlade.current
    local damageDone = damage

    local bonusDamageRoll = math.random(100)
    if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
        if common.config.weaponTier4.multistrikeBonusChance >= bonusDamageRoll then
            damageDone = bonusDamage(damageDone)
        else
            damageDone = damageDone * common.config.weaponTier4.multistrikeDamageMultiplier
        end
    elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
        if common.config.weaponTier3.multistrikeBonusChance >= bonusDamageRoll then
            damageDone = bonusDamage(damageDone)
        else
            damageDone = damageDone * common.config.weaponTier3.multistrikeDamageMultiplier
        end
    elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
        if common.config.weaponTier2.multistrikeBonusChance >= bonusDamageRoll then
            damageDone = bonusDamage(damageDone)
        else
            damageDone = damageDone * common.config.weaponTier2.multistrikeDamageMultiplier
        end
    elseif weaponSkill >= common.config.weaponTier1.weaponSkillMin then
        damageDone = damageDone * common.config.weaponTier1.multistrikeDamageMultiplier
    else
        return
    end

    -- Apply the extra damage to the actor
    targetActor:applyHealthDamage(damageDone, false, true, false)
    return damageDone
end


return this