local Config = lib.require('config')

local spawnedPeds = {}
local isCleaning = false

local function cleanPlate(plate)
    if type(plate) ~= 'string' then return end

    plate = plate:gsub('%s+', ''):upper()
    if plate == '' or #plate > 8 then return end

    return plate
end

local function notify(description, notificationType)
    lib.notify({
        description = description,
        type = notificationType
    })
end

local function recoverVehicle()
    if isCleaning then return end

    local vehicle = cache.vehicle
    if not vehicle or vehicle == 0 then
        return notify('Why are you just standing here?', 'error')
    end

    local plate = cleanPlate(GetVehicleNumberPlateText(vehicle))
    if not plate then return end

    isCleaning = true
    local result = lib.callback.await('lvlup:server:checkStolenVehicle', false, plate)

    if not result then
        isCleaning = false
        return notify('Unable to verify vehicle status.', 'error')
    end

    if not result.exists then
        isCleaning = false
        return notify('Do you even own this vehicle?', 'error')
    end

    if result.isStolen == 0 then
        isCleaning = false
        return notify('What do you want me to do with this?')
    end

    local success, reason = lib.callback.await('lvlup:server:cleanVehicle', false, plate)
    isCleaning = false

    if not success then
        local message = 'Vehicle cleaning failed.'

        if reason == 'not_enough_black_money' then
            message = "You don't have what I need."
        elseif reason == 'not_stolen' then
            message = "This vehicle doesn't need my service."
        elseif reason == 'vehicle_not_found' then
            message = 'Vehicle not found.'
        elseif reason == 'invalid_vehicle' then
            message = 'Bring the vehicle closer so I can inspect it.'
        end

        return notify(message, 'error')
    end

    notify('Clean title added successfully! You should no longer have any issues with the police.', 'success')
end

local function cleanupPeds()
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            exports.ox_target:removeLocalEntity(ped, 'vehicle_recovery')
            DeleteEntity(ped)
        end
    end

    table.wipe(spawnedPeds)
end

CreateThread(function()
    for _, location in ipairs(Config.Locations) do
        local model = joaat(location.pedModel)
        lib.requestModel(model, 5000)

        local ped = CreatePed(4, model, location.coords.x, location.coords.y, location.coords.z - 1.0, location.heading or 0.0, false, true)
        SetEntityAsMissionEntity(ped, true, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetModelAsNoLongerNeeded(model)

        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'vehicle_recovery',
                icon = 'fas fa-screwdriver-wrench',
                label = 'Speak',
                onSelect = recoverVehicle,
                distance = 2.5
            }
        })

        spawnedPeds[#spawnedPeds + 1] = ped
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    cleanupPeds()
end)
