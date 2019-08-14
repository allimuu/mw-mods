local this = {}

function this.materialFactor(baseline, adjustmentTable)
    local finalTable = {}
    for meshKey, statTable in pairs(baseline) do
        finalTable[meshKey] = {}
        for field, value in pairs(statTable) do
            if adjustmentTable[field] then
                finalTable[meshKey][field] = value * adjustmentTable[field]
            end
        end
    end
    return finalTable
end

return this