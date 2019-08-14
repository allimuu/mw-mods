return {
    weaponModifiers = {
        all = {
            flags = function(field, weapon)
                if field == 3 then
                    return
                end
                if weapon.value > 300 then
                    return 1
                else
                    return 0
                end
            end,
        },
    },
}