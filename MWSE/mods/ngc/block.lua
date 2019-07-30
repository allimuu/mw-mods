local this = {
    minBlockDefault = 10,
    maxBlockDefault = 50,
    currentlyActiveBlocking = false,
}

local common = require("ngc.common")

function this.setMaxBlock()
    local blockMaxGMST = tes3.findGMST("iBlockMaxChance")
    local blockMinGMST = tes3.findGMST("iBlockMinChance")
    blockMaxGMST.value = 100
    blockMinGMST.value = 100
end

function this.resetMaxBlock()
    local blockMaxGMST = tes3.findGMST("iBlockMaxChance")
    local blockMinGMST = tes3.findGMST("iBlockMinChance")
    blockMaxGMST.value = this.maxBlockDefault
    blockMinGMST.value = this.minBlockDefault
end

-- Block events
function this.keyPressed(e)
    local player = tes3.mobilePlayer
    local readiedShield = player.readiedShield

    if readiedShield then
        if common.config.showMessages then
            tes3.messageBox({ message = "Guard up!" })
        end
        this.currentlyActiveBlocking = true
    end
end

function this.keyReleased(e)
    if common.config.showMessages then
        tes3.messageBox({ message = "Guard down!" })
    end
    this.currentlyActiveBlocking = false
    this.resetMaxBlock()
end

return this