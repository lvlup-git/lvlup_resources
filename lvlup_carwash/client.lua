local meh = require('config')

local isWashing = false
local currentVehicle = nil

local function washVehicle(vehicle)
    for _, part in pairs(meh.parts) do
        if part.doorIndex then
            SetVehicleDoorOpen(vehicle, part.doorIndex, false, false)
        end
    end

    local dirt = GetVehicleDirtLevel(vehicle)
    local duration = math.floor(5000 + dirt * 500)

    lib.progressBar({
        duration = duration,
        label = ("Washing vehicle (Dirt: %.1f)..."):format(dirt),
        useWhileDead = false,
        canCancel = false
    })

    ClearPedTasks(PlayerPedId())

    for _, part in pairs(meh.parts) do
        if part.doorIndex then SetVehicleDoorShut(vehicle, part.doorIndex, false) end
    end

    SetVehicleDirtLevel(vehicle, 0.0)

    if meh.UseR14Evidence then
        local plate = GetVehicleNumberPlateText(vehicle)
        if plate then
            TriggerServerEvent('evidence:server:RemoveCarEvidence', plate)
        end
    end

    meh.notify("Your vehicle is now sparkling clean!", "success")
end

local function getClosestVehicle(radius)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local vehicles = GetGamePool('CVehicle')
    local closestVehicle = nil
    local closestDistance = radius + 1

    for _, veh in pairs(vehicles) do
        local vehCoords = GetEntityCoords(veh)
        local dist = #(playerCoords - vehCoords)
        if dist < closestDistance then
            closestVehicle = veh
            closestDistance = dist
        end
    end

    return closestVehicle, closestDistance
end

local function getWashPrice(dirt)
    local basePrice = meh.basePrice or 10
    local multiplier = meh.dirtPriceMultiplier or 15
    return math.floor(basePrice + dirt * multiplier)
end

local function getWashDuration(dirt)
    local baseDuration = 5000
    local extraPerDirt = 500
    return math.floor(baseDuration + dirt * extraPerDirt)
end

local carWashPeds = {}
local pedStates = {}
local pedModel = joaat('s_m_y_valet_01')

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())

        for i, washLocation in ipairs(meh.carWashLocations) do
            local dist = #(playerCoords - vec3(washLocation.x, washLocation.y, washLocation.z))

            if dist < 150.0 then
                if not pedStates[i] then
                    lib.requestModel(pedModel)

                    local ped = CreatePed(0, pedModel, washLocation.x, washLocation.y, washLocation.z - 1.0, washLocation.w, false, true)
                    FreezeEntityPosition(ped, true)
                    SetEntityInvincible(ped, true)
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)

                    carWashPeds[i] = ped
                    pedStates[i] = true

                    exports.ox_target:addLocalEntity(ped, {
                        {
                            name = 'carwash_npc_' .. i,
                            icon = 'fas fa-broom',
                            label = 'Car Wash Attendant',
                            distance = 2.5,
                            onSelect = function()
                                if isWashing then
                                    meh.notify("A car wash is already in progress", "info")
                                    return
                                end

                                local playerPed = PlayerPedId()
                                if IsPedInAnyVehicle(playerPed, false) then
                                    meh.notify("Please exit your vehicle", "error")
                                    return
                                end

                                local vehicle, closestDistance = getClosestVehicle(5.0)
                                if not vehicle or closestDistance > 5.0 then
                                    meh.notify("You must be near a vehicle", "error")
                                    return
                                end

                                local dirt = GetVehicleDirtLevel(vehicle)
                                local price = getWashPrice(dirt)
                                local duration = getWashDuration(dirt) / 1000

                                local paymentChoice = lib.inputDialog("Car Wash", {
                                    {
                                        type = "select",
                                        label = "Payment Method",
                                        options = {
                                            { value = "cash", label = "Cash" },
                                            { value = "bank", label = "Bank" }
                                        }
                                    },
                                })

                                if not paymentChoice or not paymentChoice[1] then return end

                                local method = paymentChoice[1]

                                lib.callback('meh:carwash:pay', false, function(success, msg)
                                    if not success then
                                        meh.notify(msg or "Payment failed", "error")
                                        return
                                    end

                                    meh.notify(msg or "Payment successful", "success")

                                    isWashing = true
                                    currentVehicle = vehicle
                                    washVehicle(vehicle)

                                    isWashing = false
                                    currentVehicle = nil
                                end, price, method)
                            end
                        }
                    })
                end
            else
                if pedStates[i] then
                    local ped = carWashPeds[i]
                    if ped and DoesEntityExist(ped) then DeleteEntity(ped) end
                    carWashPeds[i] = nil
                    pedStates[i] = false
                end
            end
        end
        Wait(5000)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for _, ped in pairs(carWashPeds) do
        if ped and DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)

