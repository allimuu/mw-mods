-- The default configuration values.
local defaultConfig = {}

-- Load our config file, and fill in default values for missing elements.
local config = mwse.loadConfig("More Interesting Combat")
if (config == nil) then
	config = defaultConfig
else
	for k, v in pairs(defaultConfig) do
		if (config[k] == nil) then
			config[k] = v
		end
	end
end

local multistrike = require("More Interesting Combat.multistrike")
local player
local multistrikeCounters

-- Load player and init multistrike counters
local function onLoaded(e)
	player = tes3.getPlayerRef()
	multistrikeCounters = {}
end
event.register("loaded", onLoaded)

local function onCombatEnd(e)
    if (e.actor.reference == player) then
        -- reset multistrike counters
        multistrikeCounters = {}
    end
end
event.register("combatStopped", onCombatEnd)


local function onAttack(e)
	--
	local source = e.reference
    local target = e.targetReference
	local action = e.mobile.actionData
	local weapon = e.mobile.readiedWeapon

    if e.mobile.actorType == 0 then
        -- ignore creatures
        return
    end

    -- handle player/NPC attacks
    if source and weapon and target then
        if action.physicalDamage == 0 then
			-- ignore misses
		elseif weapon.object.type > 8 then
			-- ignore ranged
        elseif action.physicalDamage > 0 then
            -- we have a hit with damage
            if weapon.object.type > 6 then
                -- axe
            elseif weapon.object.type > 5 then
                -- spear
            elseif weapon.object.type > 2 then
                -- blunt
            elseif weapon.object.type > 0 then
                -- long blade
                multistrikeCounters = multistrike.checkCounters(source.id, multistrikeCounters)
                if multistrikeCounters[source.id] == 3 then
                    multistrike.perform(source, action.physicalDamage, target)
                    multistrikeCounters[source.id] = 0
                end
            elseif weapon.object.type > -1 then
                -- short blade
            end
        end

		return
    end
end

event.register("attack", onAttack)