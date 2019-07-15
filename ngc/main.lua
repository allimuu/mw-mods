--
local version = 1.0

-- modules
local common = require('ngc.common')
local multistrike
local critical
local bleed
local stun
local momentum
local attackBonusSpell = "ngc_ready_to_strike"

local function onLoadGame(e)
    if not mwscript.getSpellEffects({reference = tes3.player, spell = attackBonusSpell}) then
        mwscript.addSpell({reference = tes3.player, spell = attackBonusSpell})
    end
end

local function onActorActivated(e)
    local hasSpell = mwscript.getSpellEffects({reference = e.reference, spell = attackBonusSpell})
    if not hasSpell then
        mwscript.addSpell({reference = e.reference, spell = attackBonusSpell})
        if common.showDebugMessages then
            tes3.messageBox({ message = "Adding ready to strike to " .. e.reference.id })
        end
    end
end

local function onCombatEnd(e)
    if (e.actor.reference == tes3.player) then
        -- reset multistrike counters
        common.multistrikeCounters = {}
        common.currentArmorCache = {}
        -- remove expose weakness on all currently exposed
        for targetId,spellId in pairs(common.currentlyExposed) do
            mwscript.removeSpell({reference = targetId, spell = spellId})
        end
        common.currentlyExposed = {}
        -- remove all bleeds and cancel all timers
        for targetId,_ in pairs(common.currentlyBleeding) do
            common.currentlyBleeding[targetId].timer:cancel()
        end
        common.currentlyBleeding = {}
    end
end

local function damageMessage(damageType, damageDone)
    if common.config.showMessages then
        local msgString = damageType
        if (common.config.showDamageNumbers and damageDone) then
            msgString = msgString .. " Extra damage: " .. math.round(damageDone, 2)
        end
        tes3.messageBox({ message = msgString })
    end
end

local function onAttack(e)
	--
	local source = e.reference
    local sourceActor = source.mobile
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
            local damageDone
            -- get damage after strength mod
            local damageMod = action.physicalDamage * (0.5 + (sourceActor.strength.current / 100))
            if weapon.object.type > 6 then
                -- axe
                damageDone = bleed.perform(source, damageMod, target)
                if (damageDone ~= nil and source == tes3.player) then
                    damageMessage("Bleeding!", damageDone)
                end
            elseif weapon.object.type > 5 then
                -- spear
                damageDone = momentum.perform(source, damageMod, target)
                if (damageDone ~= nil and source == tes3.player and common.config.showDamageNumbers) then
                    damageMessage("Momentum!", damageDone)
                end
            elseif weapon.object.type > 2 then
                -- blunt
                local stunned
                stunned, damageDone = stun.perform(source, damageMod, target)
                if (stunned and source == tes3.player) then
                    damageMessage("Stunned!", damageDone)
                elseif (source == tes3.player and common.config.showDamageNumbers) then
                    -- just show extra damage for blunt weapon if no stun
                    damageMessage("", damageDone)
                end
            elseif weapon.object.type > 0 then
                -- long blade
                common.multistrikeCounters = multistrike.checkCounters(source.id)
                if common.multistrikeCounters[source.id] == 3 then
                    damageDone = multistrike.perform(source, damageMod, target)
                    common.multistrikeCounters[source.id] = 0
                    if source == tes3.player then
                        damageMessage("Multistrike!", damageDone)
                    end
                end
            elseif weapon.object.type > -1 then
                -- short blade
                damageDone = critical.perform(source, damageMod, target)
                if (damageDone ~= nil and source == tes3.player) then
                    damageMessage("Critical strike!", damageDone)
                end
            end
        end
    end
end

local function initialized(e)
	if tes3.isModActive("Next Generation Combat.esp") then
        common.loadConfig()

        -- load modules
        multistrike = require("ngc.perks.multistrike")
        critical = require("ngc.perks.critical")
        bleed = require("ngc.perks.bleed")
        stun = require("ngc.perks.stun")
        momentum = require("ngc.perks.momentum")

        -- register events
        event.register("loaded", onLoadGame)
        event.register("mobileActivated", onActorActivated)
        event.register("combatStopped", onCombatEnd)
        event.register("attack", onAttack)

		mwse.log("[Next Generation Combat] Initialized version v%d", version)
        mwse.log(json.encode(common.config, {indent=true}))
	end
end
event.register("initialized", initialized)