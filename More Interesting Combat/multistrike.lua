this = {}

--[[ Check the counters for each referenced source
     increment or reset if already reached 3 hits
--]]
function this.checkCounters(ref, multistrikeCounters)
    local counters = multistrikeCounters
    
    if counters[ref] ~= nil then
        if counters[ref] < 3 then
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
    return damage * 2
end

--[[ Perform multistrike
     A multistrike is 10%, 20%, 30% or 50% more damage depending
     on weapon level tier. With 5%, 10% or 20% chance to be 100% more 
     damage instead, in the last three tiers.
--]]
function this.perform(source, damage, target)
    local sourceActor = source.mobile
    local targetActor = target.mobile
    local weaponSkill = sourceActor.longBlade.current
    local damageDone = damage

    bonusDamageRoll = math.random(100)
    if weaponSkill >= 100 then
        if 20 >= bonusDamageRoll then
            damageDone = bonuseDamage(damageDone)
        else
            damageDone = damageDone * 0.5
        end
    elseif weaponSkill >= 75 then
        if 10 >= bonusDamageRoll then
            damageDone = bonuseDamage(damageDone)
        else
            damageDone = damageDone * 0.3
        end
    elseif weaponSkill >= 50 then
        if 5 >= bonusDamageRoll then
            damageDone = bonuseDamage(damageDone)
        else
            damageDone = damageDone * 0.2
        end
    elseif weaponSkill >= 25 then
        if 5 >= bonusDamageRoll then
            damageDone = bonuseDamage(damageDone)
        else
            damageDone = damageDone * 0.1
        end
    else
        return
    end

    -- Apply the extra damage to the actor
    targetActor:applyHealthDamage(damageDone, false, false, false)
    tes3.messageBox({ message = "Multistrike damage " .. damageDone })
end


return this