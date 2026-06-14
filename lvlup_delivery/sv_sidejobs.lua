local Config = lib.require('config')
local players = {}

local function isNear(source, coords, maxDistance)
    local ped = GetPlayerPed(source)
    if ped <= 0 or not DoesEntityExist(ped) then return false end

    return #(GetEntityCoords(ped) - vec3(coords.x, coords.y, coords.z)) <= maxDistance
end

local function getEnabledJob(jobId)
    local job = Config.Jobs[jobId]
    if not job or job.enabled == false then return end
    return job
end

local function getRouteData(src)
    local data = players[src]
    if not data then return end

    return {
        job = data.job,
        current = data.current
    }
end

local function deletePlayerVehicle(src)
    local data = players[src]
    if not data then return end

    local ent = data.entity
    if DoesEntityExist(ent) then DeleteEntity(ent) end
end

local function createJobVehicle(source, job)
    local veh = CreateVehicle(
        job.vehicle,
        job.vehicleSpawn.x,
        job.vehicleSpawn.y,
        job.vehicleSpawn.z,
        job.vehicleSpawn.w,
        true,
        true
    )
    local ped = GetPlayerPed(source)
    if ped <= 0 or not DoesEntityExist(ped) then
        if DoesEntityExist(veh) then DeleteEntity(veh) end
        return
    end

    local timeout = GetGameTimer() + 5000
    while not DoesEntityExist(veh) and GetGameTimer() < timeout do Wait(0) end
    if not DoesEntityExist(veh) then return end

    timeout = GetGameTimer() + 5000
    while GetVehiclePedIsIn(ped, false) ~= veh and GetGameTimer() < timeout do
        TaskWarpPedIntoVehicle(ped, veh, -1)
        Wait(0)
    end
    if GetVehiclePedIsIn(ped, false) ~= veh then
        DeleteEntity(veh)
        return
    end

    return veh, NetworkGetNetworkIdFromEntity(veh)
end

local function generateRoute(job)
    local generatedLocs = {}
    local addedLocs = {}
    local totalDeliveries = math.min(job.deliveries, #job.locations)

    if totalDeliveries < 1 then return end

    while #generatedLocs < totalDeliveries do
        local index = math.random(#job.locations)

        if not addedLocs[index] then
            local randomLoc = job.locations[index]
            generatedLocs[#generatedLocs + 1] = randomLoc
            addedLocs[index] = true
        end
    end

    local currentLocIndex = math.random(#generatedLocs)
    local currentLoc = generatedLocs[currentLocIndex]
    table.remove(generatedLocs, currentLocIndex)

    return currentLoc, generatedLocs
end

lib.callback.register('lvlup_delivery:server:spawnVehicle', function(source, jobId)
    if players[source] then return false end

    local job = getEnabledJob(jobId)
    if not job or not isNear(source, job.bossCoords, 10.0) then return false end

    local src = source
    local currentLoc, generatedLocs = generateRoute(job)
    if not currentLoc then return false end
    local entity, netId = createJobVehicle(src, job)
    if not entity or not netId or netId == 0 then return false end

    local payout = math.random(job.payout.min, job.payout.max)

    players[src] = {
        job = jobId,
        entity = entity,
        locations = generatedLocs,
        payment = payout,
        current = currentLoc,
        pickedUp = false,
        completed = false
    }

    return netId, getRouteData(src)
end)

lib.callback.register('lvlup_delivery:server:clockOut', function(source)
    local src = source
    local route = players[src]
    local job = route and getEnabledJob(route.job)
    if route and job and isNear(src, job.bossCoords, 10.0) then
        deletePlayerVehicle(src)
        players[src] = nil
        return true
    end
    return false
end)

lib.callback.register('lvlup_delivery:server:takeItem', function(source)
    local route = players[source]
    if not route or route.completed or route.pickedUp then return false end
    if not DoesEntityExist(route.entity) or not isNear(source, GetEntityCoords(route.entity), 5.0) then return false end

    route.pickedUp = true
    route.readyAt = os.time() + math.max(2, math.floor(#(GetEntityCoords(route.entity) - route.current) / 100))
    return true
end)

lib.callback.register('lvlup_delivery:server:returnItem', function(source)
    local route = players[source]
    if not route or not route.pickedUp then return false end
    if not DoesEntityExist(route.entity) or not isNear(source, GetEntityCoords(route.entity), 5.0) then return false end

    route.pickedUp = false
    return true
end)

lib.callback.register('lvlup_delivery:server:payment', function(source)
    local src = source
    local route = players[src]
    if not route or route.completed or not route.pickedUp or not DoesEntityExist(route.entity) then return false end

    local job = getEnabledJob(route.job)
    if not job then return false end

    local Player = GetPlayer(src)
    if not Player then return false end
    if not isNear(src, route.current, 5.0) or os.time() < (route.readyAt or 0) then return false end

    route.pickedUp = false
    route.readyAt = nil
    AddMoney(Player, route.payment, job.paycheckLabel or job.label)

    if #route.locations == 0 then
        route.completed = true
        route.current = nil
        DoNotification(src, 'Route complete. Return the vehicle to finish your shift.')
        return true
    end

    DoNotification(src, ('Deliveries left: %s'):format(#route.locations))

    local index = math.random(#route.locations)
    local newLoc = route.locations[index]
    local payout = math.random(job.payout.min, job.payout.max)
    table.remove(route.locations, index)

    route.current = newLoc
    route.payment = payout

    return true, getRouteData(src)
end)

RegisterNetEvent('lvlup_delivery:server:cleanup', function()
    if players[source] then
        deletePlayerVehicle(source)
        players[source] = nil
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if players[src] then
        deletePlayerVehicle(src)
        players[src] = nil
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for src in pairs(players) do
        deletePlayerVehicle(src)
    end
end)

function ServerOnLogout(source)
    if players[source] then
        deletePlayerVehicle(source)
        players[source] = nil
    end
end
