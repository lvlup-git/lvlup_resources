local function registerTrays()
    for job, data in pairs(Config.Businesses or {}) do
        for i, tray in ipairs(data.trays or {}) do
            local stashId = ('business_tray_%s_%s'):format(job, i)
            exports.ox_inventory:RegisterStash(
                stashId,
                tray.label or ('Business Tray %s'):format(i),
                tray.slots or 12,
                (tray.weight or 20) * 1000,
                nil,
                nil,
                tray.coords
            )
        end
    end
end

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName ~= 'ox_inventory' and resourceName ~= GetCurrentResourceName() then return end

    registerTrays()
end)
