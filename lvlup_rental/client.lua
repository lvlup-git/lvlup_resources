local QBCore = exports['qb-core']:GetCoreObject()
local spawnedPeds = {}

CreateThread(function()
    for _, loc in pairs(Config.Locations) do
        local ped = exports['meh-core']:spawnPed(loc.pedModel, vec3(loc.coords.x, loc.coords.y, loc.coords.z), loc.heading, {
            {label = 'Rent a Vehicle', icon = 'fas fa-car', onSelect = function() openRentalMenu(loc.spawn) end},
            {label = 'Return Rental', icon = 'fas fa-undo', onSelect = function() tryReturnVehicle(loc.spawn) end}
        })
        if ped then spawnedPeds[#spawnedPeds + 1] = ped end

        if not loc.hideBlip then
            local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
            SetBlipSprite(blip, loc.blip.sprite)
            SetBlipColour(blip, loc.blip.color)
            SetBlipScale(blip, loc.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(loc.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            exports['meh-core']:deletePed(ped)
        end
    end

    spawnedPeds = {}
end)

function openRentalMenu(spawnCoords)
    local options = {}

    for _, vehicle in pairs(Config.Vehicles) do
        options[#options + 1] = {
            title = ("%s - $%d"):format(vehicle.label, vehicle.price),
            icon  = 'fas fa-car-side',
            onSelect = function()
                rentVehicle(vehicle, spawnCoords)
            end
        }
    end

    lib.registerContext({
        id = 'vehicle_rental_menu',
        title = 'Vehicle Rental',
        options = options
    })

    lib.showContext('vehicle_rental_menu')
end

function rentVehicle(vehicle, spawnCoords)
    local prefix = Config.PlatePrefix:upper():sub(1, 8)
    local remaining = 8 - #prefix
    local number = tostring(math.random(10 ^ (remaining - 1), (10 ^ remaining) - 1))
    local plate = (prefix .. number):upper()

    local ok = lib.callback.await('qb-vehiclerental:server:rent', false, plate, vehicle.model, vehicle.price)
    if not ok then
        return lib.notify({ title = 'Rental Failed', description = 'You don\'t have enough cash!', type = 'error' })
    end

    QBCore.Functions.SpawnVehicle(vehicle.model, function(veh)
        SetEntityHeading(veh, spawnCoords.w)
        SetVehicleNumberPlateText(veh, plate)
        TriggerEvent('vehiclekeys:client:SetOwner', plate)
    end, vec3(spawnCoords.x, spawnCoords.y, spawnCoords.z), true)
end

function tryReturnVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        return lib.notify({ title = 'Return Failed', description = 'You must be in a vehicle to return it.', type = 'error' })
    end

    local plateRaw = GetVehicleNumberPlateText(veh)
    local plate = plateRaw:gsub("%s+", ""):upper()

    local data = lib.callback.await('qb-vehiclerental:server:getRental', false, plate)
    if not data or not data.price then
        return lib.notify({ title = 'Not a Rental', description = 'This vehicle was not rented through us, or you are not the renter.', type = 'error' })
    end

    local health = GetEntityHealth(veh)
    local body = GetVehicleBodyHealth(veh)
    local engine = GetVehicleEngineHealth(veh)
    local avg = (health + body + engine) / 3
    local conditionFactor = math.max(0.1, avg / 1000)
    local baseRefund = data.price * Config.RefundPercent
    local finalRefund = math.floor(baseRefund * conditionFactor)

    TriggerServerEvent('qb-vehiclerental:server:return', plate, finalRefund)
    DeleteVehicle(veh)
end