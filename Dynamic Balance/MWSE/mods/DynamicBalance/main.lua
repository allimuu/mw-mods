local config = {}

local weaponTypeMapping = {
    [0] = "ShortBlade1H",
    [1] = "LongBlade1H",
    [2] = "LongBlade2H",
    [3]	= "Blunt1H",
    [4]	= "Blunt2H",
    [5]	= "Blunt2HStaff",
    [6]	= "Spear2H",
    [7]	= "Axe1H",
    [8]	= "Axe2H",
    [9]	= "MarksmanBow",
    [10] = "MarksmanCrossbow",
    [11] = "MarksmanThrown",
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
