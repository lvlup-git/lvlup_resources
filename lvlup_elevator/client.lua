local QBCore = exports['qb-core']:GetCoreObject()
local config = require('config')

CreateThread(function()
    for elevatorName, floors in pairs(config.elevators) do
        for i, floor in ipairs(floors) do
            local zoneId = ('%s_%d'):format(elevatorName, i)
            local info = {
                elevator = elevatorName,
                FloorName = floor.FloorName or ''
            }

            exports.ox_target:addSphereZone({
                coords = vec3(floor.TargetCoords.x, floor.TargetCoords.y, floor.TargetCoords.z),
                radius = floor.TargetRadius,
                debug = config.debug,
                options = {{
                    name = zoneId,
                    icon = 'fa-solid fa-arrow-up-right-from-square',
                    label = 'Use Elevator',
                    onSelect = function()
                        TriggerEvent('meh-elevators:showOptions', info)
                    end
                }}
            })
        end
    end
end)

RegisterNetEvent('meh-elevators:showOptions', function(data)
    local floors = config.elevators[data.elevator]
    if not floors then return end

    local options = {}
    local playerJob = QBCore.Functions.GetPlayerData().job.name

    for _, floor in ipairs(floors) do
        local sameFloor = floor.FloorName == data.FloorName
        local hasAccess = true

        if floor.joblock then
            hasAccess = false
            for _, allowedJob in ipairs(floor.joblock) do
                if playerJob == allowedJob then
                    hasAccess = true
                    break
                end
            end
        end

        if not sameFloor and hasAccess then
            options[#options + 1] = {
                title = floor.FloorName or 'Unknown Floor',
                description = floor.FloorDesc or 'No description available.',
                onSelect = function()
                    TriggerEvent('meh-elevators:use', floor)
                end
            }
        end
    end

    if #options == 0 then
        return lib.notify({
            title = 'Elevator',
            description = 'No accessible floors available.',
            type = 'error'
        })
    end

    lib.registerContext({
        id = 'meh_elevator_menu',
        title = data.elevator,
        options = options
    })

    lib.showContext('meh_elevator_menu')
end)

RegisterNetEvent('meh-elevators:use', function(floor)
    local ped = PlayerPedId()
    local currentCoords = GetEntityCoords(ped)

    ExecuteCommand('e atm')
    DoScreenFadeOut(1500)
    Wait(1500)

    SetEntityCoords(ped, currentCoords.x, currentCoords.y, currentCoords.z - 200.0)
    FreezeEntityPosition(ped, true)
    ExecuteCommand('e c')

    lib.progressBar({
        duration = config.elevatorTime,
        label = 'Using Elevator',
        useWhileDead = false,
        canCancel = false
    })

    SetEntityCoords(ped, floor.TeleLocation.x, floor.TeleLocation.y, floor.TeleLocation.z)
    SetEntityHeading(ped, floor.TeleHeading or 0.0)
    FreezeEntityPosition(ped, false)
    Wait(500)
    DoScreenFadeIn(2000)
end)
