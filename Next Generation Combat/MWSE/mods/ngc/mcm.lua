local this = {}
local common = require('ngc.common')

local function createBlockCategory(page)
    local category = page:createCategory{
        label = "Block Settings"
    }

    -- Create option to capture hotkey.
    category:createKeyBinder{
        label = "Assign key for Active Blocking Hotkey",
        description = "Use this option to set the hotkey for Active Blocking. Click on the option and follow the prompt.",
        allowCombinations = true,
        variable = mwse.mcm.createTableVariable{
            id = "activeBlockKey",
            table = common.config,
            defaultSetting = {
                keyCode = common.config.activeBlockKey.keyCode,
                isShiftDown = common.config.activeBlockKey.isShiftDown,
                isAltDown = common.config.activeBlockKey.isAltDown,
                isControlDown = common.config.activeBlockKey.isControlDown,
            },
            restartRequired = true
        }
    }

    category:createTextField{
        label = "Minimum fatigue threshold",
        description = "This is the minimum percentage of fatigue you can have before active blocking will not active/turn off. Default: 0.25 or 25%",
        variable = mwse.mcm.createTableVariable{
            id = "activeBlockingFatigueMin",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Base fatigue drain",
        description = "Base fatigue percentage drain while active blocking. Default: 0.25 or 25%",
        variable = mwse.mcm.createTableVariable{
            id = "activeBlockingFatiguePercentBase",
            table = common.config,
            numbersOnly = true
        },
    }
end

local function createFeatureCategory(page)
    local category = page:createCategory{
        label = "Feature Settings"
    }

    -- Toggles
    category:createOnOffButton{
        label = "Toggle Weapon Perks",
        description = "Use this to turn on/off all weapon perks.",
        variable = mwse.mcm.createTableVariable{
            id = "toggleWeaponPerks",
            table = common.config
        }
    }

    category:createOnOffButton{
        label = "Toggle Always Hit",
        description = "Use this to turn on/off always hit feature. This reverts Blind, Sanctuary and Attack Bonus to vanilla functionality.",
        variable = mwse.mcm.createTableVariable{
            id = "toggleAlwaysHit",
            table = common.config
        }
    }

    category:createOnOffButton{
        label = "Toggle Active Blocking",
        description = "Use this to turn on/off the active blocking feature.",
        variable = mwse.mcm.createTableVariable{
            id = "toggleActiveBlocking",
            table = common.config
        }
    }

    category:createOnOffButton{
        label = "Toggle Hand to Hand Feature",
        description = "Use this to turn on/off the hand to hand feature. This reverts hand to hand to vanilla functionality with no additional perks.",
        variable = mwse.mcm.createTableVariable{
            id = "toggleHandToHandPerks",
            table = common.config
        }
    }

    category:createOnOffButton{
        label = "Toggle GMST Balance Feature",
        description = "Use this to turn on/off the balance GMSTs. This allows other mods to control these GMSTs.",
        variable = mwse.mcm.createTableVariable{
            id = "toggleBalanceGMSTs",
            table = common.config
        }
    }
end

local function createMessageSettings(page)
    local category = page:createCategory{
        label = "Message Settings"
    }

    -- Toggles
    category:createOnOffButton{
        label = "Show messages",
        description = "Turn on/off the standard perk messages.",
        variable = mwse.mcm.createTableVariable{
            id = "showMessages",
            table = common.config
        }
    }

    category:createOnOffButton{
        label = "Show active blocking messages",
        description = "Turn on/off messages that show you when your guard is up or down.",
        variable = mwse.mcm.createTableVariable{
            id = "showActiveBlockMessages",
            table = common.config
        }
    }

    category:createOnOffButton{
        label = "Show extra damage numbers",
        description = "Turn on/off to show the extra damage you are doing with your weapon perks.",
        variable = mwse.mcm.createTableVariable{
            id = "showDamageNumbers",
            table = common.config
        }
    }

    category:createOnOffButton{
        label = "Show debug messages",
        description = "ONLY FOR DEBUGGING. This is a very spammy option that will show all sorts of messages including all damage taken/reduced.",
        variable = mwse.mcm.createTableVariable{
            id = "showDebugMessages",
            table = common.config
        }
    }

    category:createOnOffButton{
        label = "Show skill gain debug messages",
        description = "ONLY FOR DEBUGGING. This shows the experience you gain every time you gain experience for a skill.",
        variable = mwse.mcm.createTableVariable{
            id = "showSkillGainDebugMessages",
            table = common.config
        }
    }
end

local function createGeneralSettings(page)
    local category = page:createCategory{
        label = "General Settings"
    }

    category:createTextField{
        label = "Creature bonus damage modifier",
        description = "The modifier to scale crature bonus damage by strength. Default: 0.3 or 30% at strenth 100.",
        variable = mwse.mcm.createTableVariable{
            id = "creatureBonusModifier",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Weapon skill damage modifier",
        description = "The modifier to scale damage per weapon skill. Default: 0.2 or 20% at weapon skill 100.",
        variable = mwse.mcm.createTableVariable{
            id = "weaponSkillModifier",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Attack bonus damage modifier",
        description = "The modifier to scale how much damage attack bonus gives. Default: 0.5 or 50% at attack bonus 100.",
        variable = mwse.mcm.createTableVariable{
            id = "attackBonusModifier",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Sanctuary reduction modifier",
        description = "The modifier to scale how much sanctuary reduces damage. Default: 0.35 or roughly 15% damage reduction at sanctuary 30 with high Agility and Luck.",
        variable = mwse.mcm.createTableVariable{
            id = "sanctuaryModifier",
            table = common.config,
            numbersOnly = true
        },
    }
end

local function createBaseWeaponPerkSettings(page)
    local category = page:createCategory{
        label = "Base Weapon Perk Settings"
    }

    category:createTextField{
        label = "Multistrike strikes required",
        description = "The number of strikes required to perform a multistrike (long blade) attack. Default: 3",
        variable = mwse.mcm.createTableVariable{
            id = "multistrikeStrikesNeeded",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Multistrike double strike multiplier",
        description = "Damage multiplier for performing a double strike on a multistrike (long blade) attack. Default: 1 or 100%",
        variable = mwse.mcm.createTableVariable{
            id = "multistrikeBonuseDamageMultiplier",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Bleed damage multiplier",
        description = "Damage multiplier for bleed damage per stack. Default: 0.35 or 35% of damage per stack",
        variable = mwse.mcm.createTableVariable{
            id = "bleedMultiplier",
            table = common.config,
            numbersOnly = true
        },
    }
end

local function createHandToHandPerkSettings(page)
    local category = page:createCategory{
        label = "Base Hand to Hand Perk Settings"
    }

    category:createTextField{
        label = "Base hand to hand minimum damage",
        description = "Minimum base damage for hand to hand. Default: 2",
        variable = mwse.mcm.createTableVariable{
            id = "handToHandBaseDamageMin",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Base hand to hand maximum damage",
        description = "Maximum base damage for hand to hand. Default: 3",
        variable = mwse.mcm.createTableVariable{
            id = "handToHandBaseDamageMax",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Minimum modifier for knockdown chance",
        description = "The minimum modifier for knockdown chance when scaled with agility. Default: 0.25 or 25% of the knockdown chance of that tier",
        variable = mwse.mcm.createTableVariable{
            id = "agilityKnockdownChanceMinMod",
            table = common.config,
            numbersOnly = true
        },
    }
end

local function createSkillGainSettings(page)
    local category = page:createCategory{
        label = "Skill Experience Gain Settings"
    }

    category:createTextField{
        label = "Base weapon skill gain modifier",
        description = "The base modifier for all weapon skill gain. Default: 0.6 or 60% of vanilla gain so 40% less than vanilla",
        variable = mwse.mcm.createTableVariable{
            id = "weaponSkillGainBaseModifier",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Base armor skill gain modifier",
        description = "The base modifier for all armor skill gain. Default: 0.8 or 80% of vanilla gain so 20% less than vanilla",
        variable = mwse.mcm.createTableVariable{
            id = "armorSkillGainBaseModifier",
            table = common.config,
            numbersOnly = true
        },
    }
end

local function createGMSTSettings(page)
    local category = page:createCategory{
        label = "GMST Settings"
    }

    category:createTextField{
        label = "Knockdown chance damage multiplier (iKnockdownMult)",
        description = "The damage multiplier for the vanilla knockdown chance. Default: 0.8",
        variable = mwse.mcm.createTableVariable{
            id = "knockdownMult",
            table = common.config.gmst,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Knockdown odds multiplier (iKnockdownOddsMult)",
        description = "The odds of getting a vanilla knockdown on damage. Default: 70",
        variable = mwse.mcm.createTableVariable{
            id = "knockdownOddsMult",
            table = common.config.gmst,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Fatigue attack multiplier (fFatigueAttackMult)",
        description = "",
        variable = mwse.mcm.createTableVariable{
            id = "fatigueAttackMult",
            table = common.config.gmst,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Fatigue attack base (fFatigueAttackBase)",
        description = "",
        variable = mwse.mcm.createTableVariable{
            id = "fatigueAttackBase",
            table = common.config.gmst,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Weapon fatigue multiplier (fWeaponFatigueMult)",
        description = "",
        variable = mwse.mcm.createTableVariable{
            id = "weaponFatigueMult",
            table = common.config.gmst,
            numbersOnly = true
        },
    }
end

-- Handle mod config menu.
function this.registerModConfig()
    mwse.log("Registering MCM")
    local template = mwse.mcm.createTemplate("Next Generation Combat")
    template:saveOnClose("ngc", common.config)

    local page = template:createSideBarPage{
        label = "Settings",
        description = "Toggle and configure features."
    }

    createFeatureCategory(page)
    createBlockCategory(page)
    createMessageSettings(page)
    createGeneralSettings(page)
    createBaseWeaponPerkSettings(page)
    createHandToHandPerkSettings(page)
    createSkillGainSettings(page)
    createGMSTSettings(page)

    mwse.mcm.register(template)
end

return this