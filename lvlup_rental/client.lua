local QBCore = exports['qb-core']:GetCoreObject()
local spawnedPeds = {}

CreateThread(function()
    for _, loc in pairs(Config.Locations) do
        if loc.pedModel and loc.coords then
            local ped = exports['lvlup_core']:spawnPed(loc.pedModel, vec3(loc.coords.x, loc.coords.y, loc.coords.z), loc.heading or 0.0,
                {
                    {label = 'Rent a Vehicle', icon = 'fas fa-car', onSelect = function() openRentalMenu(loc.spawn) end},
                    {label = 'Return Rental', icon = 'fas fa-undo', onSelect = function() tryReturnVehicle() end}
                }
            )
            if ped then spawnedPeds[#spawnedPeds + 1] = ped end
            if loc.blip then
                local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
                SetBlipSprite(blip, loc.blip.sprite or 225)
                SetBlipColour(blip, loc.blip.color or 3)
                SetBlipScale(blip, loc.blip.scale or 0.8)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString(loc.label or 'Rental')
                EndTextCommandSetBlipName(blip)
            end
        end
    end
end)

function openRentalMenu(spawnCoords)
    if not spawnCoords then return end
    local hasRental = lib.callback.await('lvlup:server:hasRental', false)
    local options = {}
    if hasRental then
        options[#options + 1] = {title = 'You already have an active rental!', icon = 'fas fa-exclamation-triangle', onSelect = function() end}
    else
        for _, vehicle in pairs(Config.Vehicles) do
            local priceText = (vehicle.price == 0) and 'FREE' or ('$' .. vehicle.price)
            options[#options + 1] = {title = ('%s - %s'):format(vehicle.label or 'Vehicle', priceText), icon = 'fas fa-car-side', onSelect = function() rentVehicle(vehicle, spawnCoords) end}
        end
    end

    lib.registerContext({id = 'vehRentalMenu', title = 'Vehicle Rental', options = options})
    lib.showContext('vehRentalMenu')
end

function rentVehicle(vehicle, spawnCoords)
    if not vehicle or not spawnCoords then return end
    lib.registerContext({
        id = 'vehRentalConfirm',
        title = 'Confirm Rental',
        options = {
            {
                title = ('%s - %s'):format(vehicle.label, (vehicle.price == 0 and 'FREE' or '$' .. vehicle.price)),
                icon = 'fas fa-check',
                onSelect = function()
                    local prefix = (Config.PlatePrefix or 'RENT'):upper():sub(1, 8)
                    local remaining = math.max(1, 8 - #prefix)
                    local number = tostring(math.random(10 ^ (remaining - 1), (10 ^ remaining) - 1))
                    local plate = (prefix .. number):upper()
                    local ok, reason = lib.callback.await('lvlup:server:rent', false, plate, vehicle.model, vehicle.price, vehicle.label)
                    if not ok then
                        local msg = reason == 'not_enough_cash' and 'You don\'t have enough cash!' or
                                    reason == 'already_has_rental' and 'You already have an active rental!' or
                                    'Rental failed!'
                        return lib.notify({ title = 'Rental Failed', description = msg, type = 'error' })
                    end
                    QBCore.Functions.SpawnVehicle(vehicle.model, function(veh)
                        if not veh or veh == 0 then return end
                        SetEntityHeading(veh, spawnCoords.w or 0.0)
                        SetVehicleNumberPlateText(veh, plate)
                        TriggerEvent('vehiclekeys:client:SetOwner', plate)
                        lib.notify({ title = 'Rental Successful', description = ('%s rented for %s'):format(vehicle.label, (vehicle.price == 0 and 'FREE' or '$' .. vehicle.price)), type = 'success' })
                    end, vec3(spawnCoords.x, spawnCoords.y, spawnCoords.z), true)
                end
            },
            {title = 'Cancel', icon = 'fas fa-times', onSelect = function() end}
        }
    })
    lib.showContext('vehRentalConfirm')
end

exports.ox_inventory:displayMetadata({renter = 'Renter', plate = 'Plate', vehicle = 'Vehicle'})

function tryReturnVehicle()
    local ped = PlayerPedId()

    local veh = GetVehiclePedIsIn(ped, false)
    if not veh or veh == 0 then return lib.notify({ title = 'Return Failed', description = 'You must be in a vehicle to return it.', type = 'error' }) end

    local plateRaw = GetVehicleNumberPlateText(veh)
    local plate = plateRaw and plateRaw:gsub('%s+', ''):upper()
    if not plate or plate == '' then return end

    local data = lib.callback.await('lvlup:server:getRental', false, plate)
    if not data or not data.price then return lib.notify({ title = 'Not a Rental', description = 'This vehicle was not rented through us, or you are not the renter.', type = 'error' }) end

    local health = GetEntityHealth(veh)
    local body = GetVehicleBodyHealth(veh)
    local engine = GetVehicleEngineHealth(veh)
    local avg = (health + body + engine) / 3
    local conditionFactor = math.max(0.1, avg / 1000)
    local baseRefund = data.price * (Config.RefundPercent or 0.5)
    local finalRefund = math.floor(baseRefund * conditionFactor)

    TriggerServerEvent('lvlup:server:return', plate, finalRefund)
    DeleteVehicle(veh)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then exports['lvlup_core']:deletePed(ped) end
    end
    spawnedPeds = {}
end)
