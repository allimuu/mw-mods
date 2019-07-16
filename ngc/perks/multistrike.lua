local this = {}

local common = require('ngc.common')

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
--]]
function this.perform(damage, target, weaponSkill)
    local targetActor = target.mobile
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