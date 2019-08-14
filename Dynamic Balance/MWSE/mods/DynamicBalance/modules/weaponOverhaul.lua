local utils = require("DynamicBalance.utils")

local steelBaseline = {
    -- short blades
    dagger = {
        weight = 3,
        value = 20,
        enchantCapacity = 2,
        maxCondition = 480,
        reach = 0.8,
        chopMin = 4,
        chopMax = 5,
        slashMin = 4,
        slashMax = 5,
        thrustMin = 5,
        thrustMax = 6,
    },
    tanto = {
        weight = 4,
        value = 30,
        enchantCapacity = 2.2,
        maxCondition = 720,
        reach = 0.8,
        chopMin = 4,
        chopMax = 7,
        slashMin = 6,
        slashMax = 11,
        thrustMin = 5,
        thrustMax = 10,
    },
    shortsword = {
        weight = 8,
        value = 40,
        enchantCapacity = 4,
        maxCondition = 820,
        reach = 1,
        chopMin = 5,
        chopMax = 10,
        slashMin = 5,
        slashMax = 10,
        thrustMin = 7,
        thrustMax = 12,
    },
    wakizashi = {
        weight = 7,
        value = 50,
        enchantCapacity = 4.5,
        maxCondition = 850,
        reach = 1,
        chopMin = 7,
        chopMax = 12,
        slashMin = 8,
        slashMax = 15,
        thrustMin = 2,
        thrustMax = 7,
    },
    -- long blades
    saber = {
        weight = 12,
        value = 70,
        enchantCapacity = 55,
        maxCondition = 1000,
        reach = 1.3,
        chopMin = 5,
        chopMax = 20,
        slashMin = 4,
        slashMax = 18,
        thrustMin = 1,
        thrustMax = 5,
    },
    scimitar = {
        weight = 14,
        value = 80,
        enchantCapacity = 60,
        maxCondition = 1000,
        reach = 1.3,
        chopMin = 4,
        chopMax = 18,
        slashMin = 5,
        slashMax = 20,
        thrustMin = 1,
        thrustMax = 5,
    },
    broadsword = {
        weight = 16,
        value = 50,
        enchantCapacity = 50,
        maxCondition = 800,
        reach = 1.3,
        chopMin = 4,
        chopMax = 14,
        slashMin = 4,
        slashMax = 14,
        thrustMin = 2,
        thrustMax = 14,
    },
    longsword = {
        weight = 14,
        value = 80,
        enchantCapacity = 60,
        maxCondition = 1250,
        reach = 1.3,
        chopMin = 4,
        chopMax = 20,
        slashMin = 2,
        slashMax = 14,
        thrustMin = 1,
        thrustMax = 18,
    },
    katana = {
        weight = 12,
        value = 100,
        enchantCapacity = 60,
        maxCondition = 1500,
        reach = 1.3,
        chopMin = 2,
        chopMax = 18,
        slashMin = 3,
        slashMax = 20,
        thrustMin = 1,
        thrustMax = 6,
    },
    -- 2h Long blade
    claymore = {
        weight = 25,
        value = 160,
        enchantCapacity = 70,
        maxCondition = 2100,
        reach = 1.6,
        chopMin = 1,
        chopMax = 27,
        slashMin = 1,
        slashMax = 23,
        thrustMin = 1,
        thrustMax = 16,
    },
    daikatana = {
        weight = 20,
        value = 240,
        enchantCapacity = 70,
        maxCondition = 2700,
        reach = 1.6,
        chopMin = 2,
        chopMax = 23,
        slashMin = 3,
        slashMax = 27,
        thrustMin = 1,
        thrustMax = 14,
    },
    -- 1h blunt
    club = {
        weight = 12,
        value = 20,
        enchantCapacity = 40,
        maxCondition = 600,
        reach = 1,
        chopMin = 4,
        chopMax = 5,
        slashMin = 3,
        slashMax = 4,
        thrustMin = 3,
        thrustMax = 4,
    },
    mace = {
        weight = 15,
        value = 50,
        enchantCapacity = 50,
        maxCondition = 1800,
        reach = 1,
        chopMin = 3,
        chopMax = 14,
        slashMin = 3,
        slashMax = 14,
        thrustMin = 1,
        thrustMax = 2,
    },
    -- 2h blunt
    warhammer = {
        weight = 35,
        value = 150,
        enchantCapacity = 55,
        maxCondition = 3000,
        reach = 1.3,
        chopMin = 1,
        chopMax = 32,
        slashMin = 1,
        slashMax = 27,
        thrustMin = 1,
        thrustMax = 2,
    },
    staff = {
        weight = 6,
        value = 50,
        enchantCapacity = 70,
        maxCondition = 300,
        reach = 1.6,
        chopMin = 2,
        chopMax = 7,
        slashMin = 3,
        slashMax = 7,
        thrustMin = 1,
        thrustMax = 5,
    },
    -- spear
    spear = {
        weight = 11,
        value = 60,
        enchantCapacity = 50,
        maxCondition = 1000,
        reach = 1.8,
        chopMin = 2,
        chopMax = 5,
        slashMin = 2,
        slashMax = 5,
        thrustMin = 6,
        thrustMax = 17,
    },
    halbred = {
        weight = 16,
        value = 80,
        enchantCapacity = 50,
        maxCondition = 1500,
        reach = 1.8,
        chopMin = 3,
        chopMax = 12,
        slashMin = 1,
        slashMax = 10,
        thrustMin = 5,
        thrustMax = 20,
    },
    -- axes
    waraxe = {
        weight = 20,
        value = 60,
        enchantCapacity = 50,
        maxCondition = 1200,
        reach = 1,
        chopMin = 1,
        chopMax = 20,
        slashMin = 1,
        slashMax = 11,
        thrustMin = 1,
        thrustMax = 3,
    },
    battleaxe = {
        weight = 30,
        value = 120,
        enchantCapacity = 55,
        maxCondition = 1800,
        reach = 1.3,
        chopMin = 1,
        chopMax = 36,
        slashMin = 1,
        slashMax = 27,
        thrustMin = 1,
        thrustMax = 4,
    },
}

return {
    weaponModifiers = {
        materialClass = {
            steel = {
                meshContains = steelBaseline
            },
            chitin = {
                meshContains = utils.materialFactor(steelBaseline, {
                    weight = 0.8,
                    value = 0.5,
                    enchantCapacity = 0.5,
                    maxCondition = 0.5,
                    damage = 0.5,
                })
            },
            iron = {
                meshContains = utils.materialFactor(steelBaseline, {
                    weight = 1.2,
                    value = 0.8,
                    enchantCapacity = 0.8,
                    maxCondition = 1,
                    damage = 0.8,
                })
            },
            silver = {
                meshContains = utils.materialFactor(steelBaseline, {
                    weight = 1,
                    value = 2,
                    enchantCapacity = 1.5,
                    maxCondition = 0.8,
                    damage = 1,
                })
            },
            dwemer = {
                meshContains = utils.materialFactor(steelBaseline, {
                    weight = 1.5,
                    value = 8,
                    enchantCapacity = 1.5,
                    maxCondition = 2,
                    damage = 1.2,
                })
            },
            glass = {
                meshContains = utils.materialFactor(steelBaseline, {
                    weight = 0.6,
                    value = 20,
                    enchantCapacity = 2,
                    maxCondition = 0.8,
                    damage = 1.5,
                })
            },
            ebony = {
                meshContains = utils.materialFactor(steelBaseline, {
                    weight = 2,
                    value = 25,
                    enchantCapacity = 1.5,
                    maxCondition = 2,
                    damage = 2,
                })
            },
            adamantium = {
                meshContains = utils.materialFactor(steelBaseline, {
                    weight = 2,
                    value = 20,
                    enchantCapacity = 1.2,
                    maxCondition = 1.9,
                    damage = 2.25,
                })
            },
            nordicSilver = {
                meshContains = utils.materialFactor(steelBaseline, {
                    weight = 1.5,
                    value = 15,
                    enchantCapacity = 2,
                    maxCondition = 2.25,
                    damage = 2,
                })
            },
            daedric = {
                meshContains = utils.materialFactor(steelBaseline, {
                    weight = 3,
                    value = 75,
                    enchantCapacity = 3,
                    maxCondition = 3,
                    damage = 2.5,
                })
            },
            stalhrim = {
                meshContains = utils.materialFactor(steelBaseline, {
                    weight = 1.9,
                    value = 40,
                    enchantCapacity = 2.5,
                    maxCondition = 2.8,
                    damage = 2.1,
                })
            },
            huntsman = {
                meshContains = utils.materialFactor(steelBaseline, {
                    weight = 1.1,
                    value = 5,
                    enchantCapacity = 1.8,
                    maxCondition = 1.5,
                    damage = 1.8,
                })
            },
            nordic = {
                meshContains = utils.materialFactor(steelBaseline, {
                    weight = 1,
                    value = 2.5,
                    enchantCapacity = 2,
                    maxCondition = 1.5,
                    damage = 1.4,
                })
            },
            orcish = {
                meshContains = utils.materialFactor(steelBaseline, {
                    weight = 1,
                    value = 30,
                    enchantCapacity = 2.5,
                    maxCondition = 2,
                    damage = 1.8,
                })
            }
        },
    }
}
