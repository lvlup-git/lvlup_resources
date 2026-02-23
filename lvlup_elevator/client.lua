local QBCore = exports['qb-core']:GetCoreObject()
local config = require('config')

local cachedPlayerJob = nil
local lastJobUpdate = 0
local jobCacheDuration = config.jobCacheDuration or 5000

CreateThread(function()
    for elevatorName, floors in pairs(config.elevators) do
        for floorIndex, floor in ipairs(floors) do
            if floor.interaction and floor.interaction.coords then
                local zoneId = ('%s_%d'):format(elevatorName, floorIndex)
                exports.ox_target:addSphereZone({
                    coords = floor.interaction.coords,
                    radius = floor.interaction.radius or 1.0,
                    debug = config.debug or false,
                    options = {{
                        name = zoneId,
                        icon = 'fa-solid fa-arrow-up-right-from-square',
                        label = elevatorName,
                        onSelect = function()
                            TriggerEvent('lvlup:client:showOptions', {elevator = elevatorName, currentFloor = floor.name, floorIndex = floorIndex})
                        end
                    }}
                })
            end
        end
    end
end)

local function getPlayerJob()
    local currentTime = GetGameTimer()
    if cachedPlayerJob and (currentTime - lastJobUpdate) < jobCacheDuration then return cachedPlayerJob end
    local playerData = QBCore.Functions.GetPlayerData()
    cachedPlayerJob = playerData and playerData.job and playerData.job.name or nil
    lastJobUpdate = currentTime
    return cachedPlayerJob
end

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(jobInfo)
    cachedPlayerJob = jobInfo.name
    lastJobUpdate = GetGameTimer()
end)

local function hasJobAccess(requiredJobs, playerJob)
    if not requiredJobs or type(requiredJobs) ~= 'table' or #requiredJobs == 0 then return true end
    if not playerJob then return false end
    for _, job in ipairs(requiredJobs) do if playerJob == job then return true end end
    return false
end

RegisterNetEvent('lvlup:client:showOptions', function(data)
    local floors = config.elevators[data.elevator]
    if not floors then return end
    local options = {}
    local playerJob = getPlayerJob()
    for _, floor in ipairs(floors) do
        if floor.name ~= data.currentFloor then
            if hasJobAccess(floor.requiredJobs, playerJob) then
                options[#options + 1] = {
                    title = floor.name or 'Unknown Floor',
                    description = floor.description or 'No description available',
                    metadata = {{label = 'Access', value = (floor.requiredJobs and #floor.requiredJobs > 0) and 'Restricted' or 'Public'}},
                    onSelect = function() TriggerEvent('lvlup:client:use', floor) end
                }
            end
        end
    end
    if #options == 0 then
        return lib.notify({title = 'Elevator', description = 'No accessible floors available', type = 'error'})
    end
    lib.registerContext({id = 'ElevatorMenu', title = data.elevator, options = options})
    lib.showContext('ElevatorMenu')
end)

RegisterNetEvent('lvlup:client:use', function(floor)
    if not floor or not floor.destination or not floor.destination.coords then return end
    local ped = PlayerPedId()
    local currentCoords = GetEntityCoords(ped)
    ExecuteCommand('e atm')
    DoScreenFadeOut(1500)
    Wait(1500)
    SetEntityCoords(ped, currentCoords.x, currentCoords.y, currentCoords.z - 200.0, false, false, false, false)
    FreezeEntityPosition(ped, true)
    ExecuteCommand('e c')
    lib.progressBar({duration = config.elevatorTime or 6000, label = 'Using Elevator', useWhileDead = false, canCancel = false})
    SetEntityCoords(ped, floor.destination.coords.x, floor.destination.coords.y, floor.destination.coords.z, false, false, false, false)
    SetEntityHeading(ped, floor.destination.heading or 0.0)
    FreezeEntityPosition(ped, false)
    Wait(500)
    DoScreenFadeIn(2000)
end)
