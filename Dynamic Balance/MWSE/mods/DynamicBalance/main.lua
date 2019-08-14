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
local weightClassMapping = {
    [0] = "Light",
    [1] = "Medium",
    [2] = "Heavy",
}
local materialClassMapping

-- Utils
local function isFunction(func)
    return type(func) == "function"
end
local function isTable(table)
    return type(table) == "table"
end

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
            if isFunction(value) then
                local returnValue = value(weapon[key], weapon)
                if returnValue then
                    weapon[key] = returnValue
                end
            elseif isTable(value) then
                local baseMod = weapon[key] * value.mod
                if value.min and baseMod < value.min then
                    weapon[key] = value.min
                elseif value.max and baseMod > value.max then
                    weapon[key] = value.max
                else
                    weapon[key] = baseMod
                end
            else
                weapon[key] = value
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

local function dynamicUpdateForMesh(weapon, moduleConfig)
    for meshKey, value in pairs(moduleConfig) do
        if string.find(string.lower(weapon.mesh), string.lower(meshKey)) then
            dynamicUpdate(weapon, value)
        end
    end
end

local function findArrayInStr(array, str)
    for _,v in pairs(array) do
        if string.find(string.lower(str), string.lower(v)) then
          return true
        end
    end
    return false
end

local function serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep(" ", depth)

    if name then tmp = tmp .. name .. " = " end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp =  tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end

local function updateWeapons(moduleConfig, debug)
    for weapon in tes3.iterateObjects(tes3.objectType.weapon) do
        local weaponType = weaponTypeMapping[weapon.type]
        -- ID overrides
        if moduleConfig.idOverrides and moduleConfig.idOverrides[weapon.id] then
            local weaponConfig = moduleConfig.idOverrides[weapon.id]
            if weaponConfig.type == "static" then
                -- static values
                staticUpdate(weapon, weaponConfig)
            else
                dynamicUpdate(weapon, weaponConfig)
            end
        else
            -- Weapon modifiers
            if moduleConfig.weaponModifiers then
                -- all
                if moduleConfig.weaponModifiers.all then
                    local weaponConfig = moduleConfig.weaponModifiers.all
                    dynamicUpdate(weapon, weaponConfig)
                end
                -- weapon type
                if moduleConfig.weaponModifiers[weaponType] then
                    local weaponConfig = moduleConfig.weaponModifiers[weaponType]
                    dynamicUpdate(weapon, weaponConfig)
                end
                -- mesh contains
                if moduleConfig.weaponModifiers.meshContains then
                    dynamicUpdateForMesh(weapon, moduleConfig.weaponModifiers.meshContains)
                end
                -- material class
                if moduleConfig.weaponModifiers.materialClass then
                    for materialKey, value in pairs(moduleConfig.weaponModifiers.materialClass) do
                        if materialClassMapping[materialKey] then
                            local meshValues = materialClassMapping[materialKey]
                            if findArrayInStr(materialClassMapping.excludeMesh, weapon.mesh) then
                                -- do nothing for excluded mesh keys
                            elseif findArrayInStr(materialClassMapping.excludeId, weapon.id) then
                                -- do nothing for excluded id keys
                            elseif findArrayInStr(meshValues, weapon.mesh) then
                                mwse.log("Found material mesh for " .. serializeTable(meshValues) .. " in " .. weapon.mesh)
                                -- and weapon type
                                if value[weaponType] then
                                    local weaponConfig = value[weaponType]
                                    dynamicUpdate(weapon, weaponConfig)
                                end
                                -- and mesh contains
                                if value.meshContains then
                                    dynamicUpdateForMesh(weapon, value.meshContains)
                                end
                            end
                        end
                    end
                end
            end
        end

        if debug then
            mwse.log("ID: " .. weapon.id .. " Name: " .. weapon.id .. " Weight: " .. weapon.weight .. " Value: " .. weapon.value .. " Reach: " .. weapon.reach)
        end
    end
end

local function updateArmor(moduleConfig)
    for armor in tes3.iterateObjects(tes3.objectType.armor) do
        -- ID overrides
        if moduleConfig.idOverrides and moduleConfig.idOverrides[armor.id] then
            local armorConfig = config.idOverrides[armor.id]
            if armorConfig.type == "static" then
                -- static values
                staticUpdate(armor, armorConfig)
            else
                dynamicUpdate(armor, armorConfig)
            end
        else
            -- Armor modifiers modifiers
            if moduleConfig.armorModifiers then
                local armorClass = weightClassMapping[armor.weightClass]
                if config.armorModifiers[armorClass] then
                    local armorConfig = config.armorModifiers[armorClass]
                    dynamicUpdate(armor, armorConfig)
                end
            end
        end
    end
end

local function initialized(e)
    config = loadConfig()
    if not config.modules then
        return
    end
    materialClassMapping = config.materialClassMapping

    for _, moduleString in ipairs(config.modules) do
        local module = require("DynamicBalance.modules." .. moduleString)
        if module then
            updateWeapons(module, config.debug)
            -- updateArmor(module)
        end
    end
end
event.register("initialized", initialized)
