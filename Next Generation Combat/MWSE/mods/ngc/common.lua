local this = {
    config = {},
    currentlyExposed = {},
    currentlyBleeding = {},
    currentArmorCache = {},
    multistrikeCounters = {},
    currentlyRushed = {},
}
local defaultConfig = {
    showMessages = true,
    showActiveBlockMessages = true,
    showDamageNumbers = false,
    showDebugMessages = false,
    showSkillGainDebugMessages = false,
    toggleAlwaysHit = true,
    toggleWeaponPerks = true,
    toggleActiveBlocking = true,
    toggleHandToHandPerks = true,
    toggleBalanceGMSTs = true,
    creatureBonusModifier = 0.3,
    weaponSkillModifier = 0.2,
    attackBonusModifier = 0.5,
    sanctuaryModifier = 0.35,
    multistrikeStrikesNeeded = 3,
    multistrikeBonuseDamageMultiplier = 1,
    criticalStrikeMultiplier = 1,
    bleedMultiplier = 0.35,
    handToHandBaseDamageMin = 2,
    handToHandBaseDamageMax = 3,
    agilityKnockdownChanceMinMod = 0.25,
    activeBlockingFatigueMin = 0.25,
    activeBlockingFatiguePercentBase = 0.25,
    weaponSkillGainBaseModifier = 0.6,
    armorSkillGainBaseModifier = 0.8,
    fatigueReductionModifier = 0.3,
    activeBlockKey = {
        keyCode = 44,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },
    gmst = {
        knockdownMult = 0.8,
        knockdownOddsMult = 70,
        fatigueAttackMult = 0.2,
        fatigueAttackBase = 0,
        weaponFatigueMult = 0,
    },
    weaponTier1 = {
        weaponSkillMin = 25,
        criticalStrikeChance = 10,
        multistrikeDamageMultiplier = 0.1,
        bleedChance = 15,
        stunChance = 5,
        bonusDamageForFatigueMultiplier = 0.15,
        handToHandBaseDamageMin = 3,
        handToHandBaseDamageMax = 4,
        handToHandKnockdownChance = 10,
        handToHandKnockdownDamageMultiplier = 0.1,
        activeBlockingFatiguePercent = 0.2,
        weaponSkillGainModifier = 0.65,
    },
    weaponTier2 = {
        weaponSkillMin = 50,
        criticalStrikeChance = 20,
        multistrikeBonusChance = 5,
        multistrikeDamageMultiplier = 0.2,
        bleedChance = 25,
        maxBleedStack = 2,
        stunChance = 10,
        bonusArmorDamageMultiplier = 0.2,
        bonusDamageForFatigueMultiplier = 0.3,
        adrenalineRushChance = 10,
        handToHandBaseDamageMin = 5,
        handToHandBaseDamageMax = 7,
        handToHandKnockdownChance = 20,
        handToHandKnockdownDamageMultiplier = 0.2,
        activeBlockingFatiguePercent = 0.15,
        weaponSkillGainModifier = 0.7,
    },
    weaponTier3 = {
        weaponSkillMin = 75,
        criticalStrikeChance = 35,
        multistrikeBonusChance = 10,
        multistrikeDamageMultiplier = 0.35,
        bleedChance = 30,
        maxBleedStack = 3,
        stunChance = 15,
        bonusArmorDamageMultiplier = 0.25,
        bonusDamageForFatigueMultiplier = 0.45,
        adrenalineRushChance = 20,
        handToHandBaseDamageMin = 8,
        handToHandBaseDamageMax = 11,
        handToHandKnockdownChance = 25,
        handToHandKnockdownDamageMultiplier = 0.35,
        activeBlockingFatiguePercent = 0.1,
        weaponSkillGainModifier = 0.8,
    },
    weaponTier4 = {
        weaponSkillMin = 100,
        criticalStrikeChance = 50,
        multistrikeBonusChance = 20,
        multistrikeDamageMultiplier = 0.5,
        bleedChance = 35,
        maxBleedStack = 4,
        stunChance = 20,
        bonusArmorDamageMultiplier = 0.33,
        bonusDamageForFatigueMultiplier = 0.6,
        adrenalineRushChance = 30,
        handToHandBaseDamageMin = 11,
        handToHandBaseDamageMax = 14,
        handToHandKnockdownChance = 30,
        handToHandKnockdownDamageMultiplier = 0.5,
        activeBlockingFatiguePercent = 0.05,
        weaponSkillGainModifier = 1,
    },
}

-- Loads the configuration file for use.
function this.loadConfig()
	this.config = defaultConfig

	local configJson = mwse.loadConfig('ngc')
	if (configJson ~= nil) then
		this.config = configJson
	end

	mwse.log("[Next Generation Combat] Loaded configuration:")
	mwse.log(json.encode(this.config, { indent = true }))
end

-- common util functions
function this.getARforTarget(target)
    local totalAR = 0
    for id, slot in pairs(tes3.armorSlot) do
        local equippedSlot = tes3.getEquippedItem({ actor = target, objectType = tes3.objectType.armor, slot = slot })
        if equippedSlot then
            totalAR = totalAR + equippedSlot.object.armorRating
        end
    end

    return totalAR
end

function this.keybindTest(b, e)
    return (b.keyCode == e.keyCode) and
    (b.isShiftDown == e.isShiftDown) and
    (b.isAltDown == e.isAltDown) and
    (b.isControlDown == e.isControlDown)
end

return this