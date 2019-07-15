local this = {}

local common = require('ngc.common')


local function getARforTarget(target)
    local totalAR = 0
    for id, slot in pairs(tes3.armorSlot) do
        local equippedSlot = tes3.getEquippedItem({ actor = target, objectType = tes3.objectType.armor, slot = slot })
        if equippedSlot then
            totalAR = totalAR + equippedSlot.object.armorRating
        end
    end

    return totalAR
end

local function bonusArmorDamage(target, damageDone, arMod)
    -- calculate the bonus armor damage
    local bonusDamage
    local totalAR = common.currentArmorCache[target.id]
    if totalAR == nil then
        -- no cache, calculate total armor
        totalAR = getARforTarget(target)
        -- prime cache
        common.currentArmorCache[target.id] = totalAR
    end

    bonusDamage = damageDone * ((totalAR * arMod) / 100)
    return bonusDamage
end

local function castStun(targetActor)
    -- attempt to paralyze the target if they aren't already
    if targetActor.paralyze == 0 then
        targetActor.paralyze = 1
        timer.start({
            duration = 1,
            callback = function ()
                targetActor.paralyze = 0
            end,
        })
    end
end

--[[ Perform a stun and bonus armor damage (blunt weapon)
     A stun is a 1 second paralyze with higher chance per weapon tier.
     And bonus damage depending on how high the target's armor rating is (not including shields).
     At weapon skill 100, bonus damage is 0.33% per point of AR.
     So at 300 AR it rounds out to 100% bonus damage (very rare and only the tankiest).
     At 150 AR (far more common), roughly 50% bonus damage.
     At 100 or less AR (very common), 33% bonus damage right down to 0% bonus damage
     for unarmored targets.
--]]
function this.perform(source, damage, target)
    local sourceActor = source.mobile
    local targetActor = target.mobile
    local weaponSkill = sourceActor.bluntWeapon.current
    local damageDone
    local stunned = false

    local stunChanceRoll = math.random(100)
    if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
        damageDone = bonusArmorDamage(target, damage, common.config.weaponTier4.bonusArmorDamageMultiplier)
        if common.config.weaponTier4.stunChance >= stunChanceRoll then
            castStun(targetActor)
            stunned = true
        end
    elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
        damageDone = bonusArmorDamage(target, damage, common.config.weaponTier3.bonusArmorDamageMultiplier)
        if common.config.weaponTier3.stunChance >= stunChanceRoll then
            castStun(targetActor)
            stunned = true
        end
    elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
        damageDone = bonusArmorDamage(target, damage, common.config.weaponTier2.bonusArmorDamageMultiplier)
        if common.config.weaponTier2.stunChance >= stunChanceRoll then
            castStun(targetActor)
            stunned = true
        end
    elseif weaponSkill >= common.config.weaponTier1.weaponSkillMin then
        if common.config.weaponTier1.stunChance >= stunChanceRoll then
            castStun(targetActor)
            stunned = true
        end
    end

    if damageDone ~= nil then
    -- Apply the extra damage to the actor if we have it
        targetActor:applyHealthDamage(damageDone, false, true, false)
    end

    return stunned, damageDone
end

return this