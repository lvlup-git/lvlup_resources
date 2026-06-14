local config = require 'config'

local cachedPlayerJob
local lastJobUpdate = 0
local targetZones = {}
local transitioning = false
local jobCacheDuration = config.jobCacheDuration or 5000

local function getPlayerJob()
    local currentTime = GetGameTimer()
    if cachedPlayerJob and currentTime - lastJobUpdate < jobCacheDuration then return cachedPlayerJob end

    local playerData = QBX and QBX.PlayerData
    cachedPlayerJob = playerData and playerData.job and playerData.job.name or nil
    lastJobUpdate = currentTime
    return cachedPlayerJob
end

local function hasJobAccess(requiredJobs)
    if not requiredJobs or type(requiredJobs) ~= 'table' or #requiredJobs == 0 then return true end

    local playerJob = getPlayerJob()
    if not playerJob then return false end

    for i = 1, #requiredJobs do
        if playerJob == requiredJobs[i] then return true end
    end

    return false
end

local function getFloor(elevatorName, floorIndex)
    local floors = config.elevators[elevatorName]
    return floors and floors[floorIndex] or nil
end

local function isNearFloor(floor)
    local coords = floor and floor.interaction and floor.interaction.coords
    if not coords then return false end

    return #(GetEntityCoords(cache.ped) - coords) <= math.max((floor.interaction.radius or 1.0) + 1.0, 2.0)
end

local function useElevator(elevatorName, sourceFloorIndex, destinationFloorIndex)
    if transitioning then return end

    local sourceFloor = getFloor(elevatorName, sourceFloorIndex)
    local destinationFloor = getFloor(elevatorName, destinationFloorIndex)
    if not sourceFloor or not destinationFloor or sourceFloorIndex == destinationFloorIndex then return end
    if not isNearFloor(sourceFloor) or not hasJobAccess(sourceFloor.requiredJobs) or not hasJobAccess(destinationFloor.requiredJobs) then return end
    if not destinationFloor.destination or not destinationFloor.destination.coords then return end

    transitioning = true
    local ped = cache.ped
    local currentCoords = GetEntityCoords(ped)
    ExecuteCommand('e atm')
    DoScreenFadeOut(1500)
    Wait(1500)
    SetEntityCoords(ped, currentCoords.x, currentCoords.y, currentCoords.z - 200.0, false, false, false, false)
    FreezeEntityPosition(ped, true)
    ExecuteCommand('e c')
    lib.progressBar({duration = config.elevatorTime or 6000, label = 'Using Elevator', useWhileDead = false, canCancel = false})
    RequestCollisionAtCoord(destinationFloor.destination.coords.x, destinationFloor.destination.coords.y, destinationFloor.destination.coords.z)
    SetEntityCoords(ped, destinationFloor.destination.coords.x, destinationFloor.destination.coords.y, destinationFloor.destination.coords.z, false, false, false, false)
    SetEntityHeading(ped, destinationFloor.destination.heading or 0.0)
    FreezeEntityPosition(ped, false)
    Wait(500)
    DoScreenFadeIn(2000)
    transitioning = false
end

local function showOptions(elevatorName, currentFloorIndex)
    local floors = config.elevators[elevatorName]
    local currentFloor = floors and floors[currentFloorIndex]
    if not currentFloor or not isNearFloor(currentFloor) or not hasJobAccess(currentFloor.requiredJobs) then return end

    local options = {}
    for floorIndex, floor in ipairs(floors) do
        if floorIndex ~= currentFloorIndex and hasJobAccess(floor.requiredJobs) then
            options[#options + 1] = {
                title = floor.name or 'Unknown Floor',
                description = floor.description or 'No description available',
                metadata = {{label = 'Access', value = floor.requiredJobs and #floor.requiredJobs > 0 and 'Restricted' or 'Public'}},
                onSelect = function()
                    useElevator(elevatorName, currentFloorIndex, floorIndex)
                end
            }
        end
    end

    if #options == 0 then
        return lib.notify({title = 'Elevator', description = 'No accessible floors available', type = 'error'})
    end

    lib.registerContext({id = 'lvlup_elevators_menu', title = elevatorName, options = options})
    lib.showContext('lvlup_elevators_menu')
end

local function removeTargetZones()
    for i = 1, #targetZones do
        exports.ox_target:removeZone(targetZones[i])
    end

    targetZones = {}
end

local function setupTargetZones()
    removeTargetZones()

    for elevatorName, floors in pairs(config.elevators) do
        for floorIndex, floor in ipairs(floors) do
            if floor.interaction and floor.interaction.coords then
                local currentElevator = elevatorName
                local currentFloor = floorIndex
                targetZones[#targetZones + 1] = exports.ox_target:addSphereZone({
                    coords = floor.interaction.coords,
                    radius = floor.interaction.radius or 1.0,
                    debug = config.debug or false,
                    options = {{
                        name = ('lvlup_elevators_%s_%d'):format(elevatorName, floorIndex),
                        icon = 'fa-solid fa-arrow-up-right-from-square',
                        label = elevatorName,
                        canInteract = function()
                            return not transitioning and hasJobAccess(floor.requiredJobs)
                        end,
                        onSelect = function()
                            showOptions(currentElevator, currentFloor)
                        end
                    }}
                })
            end
        end
    end
end

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(jobInfo)
    cachedPlayerJob = jobInfo and jobInfo.name or nil
    lastJobUpdate = GetGameTimer()
end)

AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= cache.resource then return end

    setupTargetZones()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    removeTargetZones()
    transitioning = false
    FreezeEntityPosition(cache.ped, false)
    DoScreenFadeIn(0)
end)
