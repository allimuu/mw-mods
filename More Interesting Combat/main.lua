-- The default configuration values.
local common = require('More Interesting Combat.common')
local multistrike
local critical

local player
local multistrikeCounters

-- Load player and init multistrike counters
local function onLoaded(e)
	player = tes3.getPlayerRef()
	multistrikeCounters = {}
end

local function onCombatEnd(e)
    if (e.actor.reference == player) then
        -- reset multistrike counters
        multistrikeCounters = {}
    end
end

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
                    local damageDone
                    damageDone = multistrike.perform(source, action.physicalDamage, target)
                    multistrikeCounters[source.id] = 0
                    if common.config.showMessages then
                        local msgString = "Multistrike!"
                        if common.config.showDamageNumbers then
                            msgString = msgString .. " Extra damage: " .. math.round(damageDone, 2)
                        end
                        tes3.messageBox({ message = msgString })
                    end
                end
            elseif weapon.object.type > -1 then
                -- short blade
            end
        end

		return
    end
end

local function initialized(e)
	if tes3.isModActive("More Interesting Combat.esp") then
        common.loadConfig()

        -- load modules
        multistrike = require("More Interesting Combat.multistrike")
        critical = require("More Interesting Combat.critical")

		-- register events
        event.register("loaded", onLoaded)
        event.register("combatStopped", onCombatEnd)
        event.register("attack", onAttack)

		mwse.log("[More Interesting Combat] Initialized version v%d", common.config.version)
		mwse.log(json.encode(common.config, {indent=true}))
	end
end
event.register("initialized", initialized)