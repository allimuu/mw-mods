this = {
	config = {},
}
local defaultConfig = {
    version = 1,
    showMessages = true,
    showDamageNumbers = true,
    multistrikeStrikesNeeded = 3,
    multistrikeBonuseDamageMultiplier = 2,
    weaponTier1 = {
        weaponSkillMin = 25,
        criticalStrikeChance = 10,
        multistrikeDamageMultiplier = 0.1,
    },
    weaponTier2 = {
        weaponSkillMin = 50,
        criticalStrikeChance = 20,
        multistrikeBonusChance = 5,
        multistrikeDamageMultiplier = 0.2,
    },
    weaponTier3 = {
        weaponSkillMin = 75,
        criticalStrikeChance = 30,
        multistrikeBonusChance = 10,
        multistrikeDamageMultiplier = 0.35,
    },
    weaponTier4 = {
        weaponSkillMin = 100,
        criticalStrikeChance = 30,
        multistrikeBonusChance = 20,
        multistrikeDamageMultiplier = 0.5,
    },
}

-- Loads the configuration file for use.
function this.loadConfig()
	this.config = defaultConfig

	local configJson = mwse.loadConfig("More Interesting Combat")
	if (configJson ~= nil) then
		this.config = configJson
	end

	mwse.log("[More Interesting Combat] Loaded configuration:")
	mwse.log(json.encode(this.config, { indent = true }))
end


return this