local this = {}

local common = require("ngc.common")

function this.attackPressed(e)

    if tes3.menuMode() then
        return
    end

    local player = tes3.mobilePlayer
    local weapon = player.readiedWeapon

    if (weapon.object.type == 9 and player.actionData.attackSwing > 0) then
        -- only for bows during an attack
        if common.config.showDebugMessages then
            tes3.messageBox({ message = "Start full draw!" })
        end
        common.playerFullDrawTimer = timer.start({
            duration = 3,
            callback = function ()
                common.playerCurrentlyFullDrawn = true
                if player.isSneaking then
                    mge.setZoom({ amount = common.config.bowZoomLevel })
                end
                if common.config.showMessages then
                    tes3.messageBox({ message = "Full draw!" })
                end
            end,
            iterations = 1
        })
    end
end

function this.attackReleased(e)
    -- we delay this a bit so the attack event has time to track it
    timer.start({
        duration = 1,
        callback = function ()
            common.playerCurrentlyFullDrawn = false
        end,
        iterations = 1
    })
    mge.setZoom({ amount = 0 })
    if common.playerFullDrawTimer then
        common.playerFullDrawTimer:cancel()
        common.playerFullDrawTimer = nil
    end
end

function this.playerFullDrawBonus(weaponSkill)
    local bonusMultiplier

    if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
        bonusMultiplier = common.config.weaponTier4.bowFullDrawMultiplier
    elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
        bonusMultiplier = common.config.weaponTier3.bowFullDrawMultiplier
    elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
        bonusMultiplier = common.config.weaponTier2.bowFullDrawMultiplier
    elseif weaponSkill >= common.config.weaponTier1.weaponSkillMin then
        bonusMultiplier = common.config.weaponTier1.bowFullDrawMultiplier
    end

    return bonusMultiplier
end

function this.NPCFullDrawBonus(weaponSkill)
    local bonusMultiplier

    if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
        bonusMultiplier = common.config.weaponTier4.bowNPCDrawMultiplier
    elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
        bonusMultiplier = common.config.weaponTier3.bowNPCDrawMultiplier
    elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
        bonusMultiplier = common.config.weaponTier2.bowNPCDrawMultiplier
    elseif weaponSkill >= common.config.weaponTier1.weaponSkillMin then
        bonusMultiplier = common.config.weaponTier1.bowNPCDrawMultiplier
    end

    return bonusMultiplier
end

local function setTargetHamstring(source, target)
    if (common.config.showMessages and source == tes3.player) then
        tes3.messageBox({ message = "Hamstrung!" })
    end
    if (common.currentlyHamstrung[target.id] == nil) then
        common.currentlyHamstrung[target.id] = timer.start({
            duration = 3,
            callback = function ()
                common.currentlyHamstrung[target.id] = nil
            end,
            iterations = 1
        })
    elseif common.currentlyHamstrung[target.id].state == timer.expired then
        common.currentlyHamstrung[target.id] = timer.start({
            duration = 3,
            callback = function ()
                common.currentlyHamstrung[target.id] = nil
            end,
            iterations = 1
        })
    else
        common.currentlyHamstrung[target.id]:reset()
    end
end

function this.performHamstring(weaponSkill, source, target)
    local hamstringChanceRoll = math.random(100)
    if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
        if common.config.weaponTier4.hamstringChance >= hamstringChanceRoll then
            setTargetHamstring(source, target)
        end
    elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
        if common.config.weaponTier3.hamstringChance >= hamstringChanceRoll then
            setTargetHamstring(source, target)
        end
    elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
        if common.config.weaponTier2.hamstringChance >= hamstringChanceRoll then
            setTargetHamstring(source, target)
        end
    end
end

return this