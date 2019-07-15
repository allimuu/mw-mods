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
    showDamageNumbers = true,
    showDebugMessages = true,
    multistrikeStrikesNeeded = 3,
    multistrikeBonuseDamageMultiplier = 1,
    criticalStrikeMultiplier = 1,
    bleedMultiplier = 0.3,
    weaponTier1 = {
        weaponSkillMin = 25,
        criticalStrikeChance = 5,
        multistrikeDamageMultiplier = 0.1,
        bleedChance = 10,
        stunChance = 10,
        bonusDamageForFatigueMultiplier = 0.15,
    },
    weaponTier2 = {
        weaponSkillMin = 50,
        criticalStrikeChance = 10,
        multistrikeBonusChance = 5,
        multistrikeDamageMultiplier = 0.2,
        bleedChance = 20,
        maxBleedStack = 2,
        stunChance = 15,
        bonusArmorDamageMultiplier = 0.2,
        bonusDamageForFatigueMultiplier = 0.3,
        adrenalineRushChance = 10,
    },
    weaponTier3 = {
        weaponSkillMin = 75,
        criticalStrikeChance = 20,
        multistrikeBonusChance = 10,
        multistrikeDamageMultiplier = 0.35,
        bleedChance = 30,
        maxBleedStack = 3,
        stunChance = 20,
        bonusArmorDamageMultiplier = 0.25,
        bonusDamageForFatigueMultiplier = 0.45,
        adrenalineRushChance = 20,
    },
    weaponTier4 = {
        weaponSkillMin = 100,
        criticalStrikeChance = 30,
        multistrikeBonusChance = 20,
        multistrikeDamageMultiplier = 0.5,
        bleedChance = 30,
        maxBleedStack = 4,
        stunChance = 30,
        bonusArmorDamageMultiplier = 0.33,
        bonusDamageForFatigueMultiplier = 0.6,
        adrenalineRushChance = 30,
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


return this