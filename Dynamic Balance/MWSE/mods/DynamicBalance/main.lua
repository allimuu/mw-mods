local config = {}

local weaponTypeMapping = {
    [0] = "Short Blade One Hand",
    [1] = "Long Blade One Hand",
    [2] = "Long Blade Two Close",
    [3]	= "Blunt One Hand",
    [4]	= "Blunt Two Close",
    [5]	= "Blunt Two Wide",
    [6]	= "Spear Two Wide",
    [7]	= "Axe One Hand",
    [8]	= "Axe Two Hand",
    [9]	= "Marksman Bow",
    [10] = "Marksman Crossbow",
    [11] = "Marksman Thrown",
    [12] = "Arrow",
    [13] = "Bolt",
}

local function loadConfig()
	local configJson = mwse.loadConfig("DynamicBalance")
	if not configJson then
        mwse.log("[Dynamic Balance] Error! Missing balance config!")
        return
	end

    mwse.log("[Dynamic Balance] Initialized!")
    return configJson
end

local function dynamicUpdate(weapon, values)
    for key, value in pairs(values) do
        if key ~= "type" then
            local baseMod = weapon[key] * value.mod
            if value.min and baseMod < value.min then
                weapon[key] = value.min
            elseif value.max and baseMod > value.max then
                weapon[key] = value.max
            else
                weapon[key] = baseMod
            end
        end
    end
end

local function staticUpdate(weapon, values)
    for k, v in pairs(values) do
        if k ~= "type" then
            weapon[k] = v
        end
    end
end

local function initialized(e)
    config = loadConfig()
    if not config then
        return
    end

    for weapon in tes3.iterateObjects(tes3.objectType.weapon) do
        -- ID overrides
        if config.idOverrides[weapon.id] then
            local weaponConfig = config.idOverrides[weapon.id]
            if weaponConfig.type == "static" then
                -- static values
                staticUpdate(weapon, weaponConfig)
            else
                dynamicUpdate(weapon, weaponConfig)
            end
        end
        -- Weapon modifiers
        if config.weaponModifiers then
            local weaponType = weaponTypeMapping[weapon.type]
            if config.weaponModifiers[weaponType] then
                local weaponConfig = config.weaponModifiers[weaponType]
                dynamicUpdate(weapon, weaponConfig)
            end
        end
    end
end
event.register("initialized", initialized)