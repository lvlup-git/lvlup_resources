local zoneIds = {}
local lastOpen = 0
local openCooldown = 500

local function openTray(job, trayIndex)
    local now = GetGameTimer()
    if now - lastOpen < openCooldown then return end
    lastOpen = now

    local stashId = ('business_tray_%s_%s'):format(job, trayIndex)
    if not exports.ox_inventory:openInventory('stash', stashId) then
        lib.notify({description = 'This tray is unavailable.', type = 'error'})
    end
end

local function removeZones()
    for _, id in ipairs(zoneIds) do
        exports.ox_target:removeZone(id)
    end
    zoneIds = {}
end

CreateThread(function()
    removeZones()

    for job, business in pairs(Config.Businesses or {}) do
        for trayIndex, tray in ipairs(business.trays or {}) do
            local currentJob = job
            local currentTrayIndex = trayIndex
            local zoneId = exports.ox_target:addSphereZone({
                coords = tray.coords,
                radius = tray.radius or 0.4,
                debug = business.debug or false,
                options = {
                    {
                        label = tray.label or 'Tray',
                        icon = 'fas fa-cube',
                        distance = (tray.radius or 0.4) + 2.8,
                        onSelect = function()
                            openTray(currentJob, currentTrayIndex)
                        end
                    }
                }
            })

            if zoneId then
                zoneIds[#zoneIds + 1] = zoneId
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    removeZones()
end)
