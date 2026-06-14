local Config = lib.require('config')

local isHired, holdingItem, itemDelivered, activeOrder = false, false, false, false
local carryProp, jobVehicle, currZone
local currentJobId, currentJob, currentDeliveryVec
local jobBlip
local bosses, startZones = {}, {}
local deliverItem

local function getEnabledJob(jobId)
    local job = Config.Jobs[jobId]
    if not job or job.enabled == false then return end
    return job
end

local function removeVehicleTarget()
    if not jobVehicle or not DoesEntityExist(jobVehicle) then return end

    local netId = NetworkGetNetworkIdFromEntity(jobVehicle)
    exports.ox_target:removeEntity(netId, {
        'lvlup_delivery_take_item',
        'lvlup_delivery_return_item'
    })
end

local function doCarry(bool)
    local ped = cache.ped
    local carry = currentJob and currentJob.carry

    if bool then
        if not carry then return end

        local model = carry.model
        lib.requestModel(model)

        local coords = GetEntityCoords(ped)
        carryProp = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)

        AttachEntityToEntity(
            carryProp, ped, GetPedBoneIndex(ped, carry.bone or 28422),
            carry.placement[1], carry.placement[2], carry.placement[3],
            carry.placement[4], carry.placement[5], carry.placement[6],
            true, true, false, true, 0, true
        )

        lib.requestAnimDict(carry.animDict)
        TaskPlayAnim(ped, carry.animDict, carry.animName, 5.0, 5.0, -1, 51, 0, 0, 0, 0)

        SetModelAsNoLongerNeeded(model)

        CreateThread(function()
            while carryProp and DoesEntityExist(carryProp) do
                if not IsEntityPlayingAnim(ped, carry.animDict, carry.animName, 3) then
                    TaskPlayAnim(ped, carry.animDict, carry.animName, 5.0, 5.0, -1, 51, 0, 0, 0, 0)
                end
                Wait(1000)
            end
            RemoveAnimDict(carry.animDict)
        end)
    else
        if carryProp and DoesEntityExist(carryProp) then
            DeleteEntity(carryProp)
        end

        carryProp = nil
        ClearPedTasksImmediately(ped)
    end

    holdingItem = bool
end

local function resetDelivery()
    if currZone then
        exports.ox_target:removeZone(currZone)
        currZone = nil
    end

    if jobBlip then
        RemoveBlip(jobBlip)
        jobBlip = nil
    end
end

local function deleteBoss(jobId)
    local boss = bosses[jobId]
    if not boss or not DoesEntityExist(boss) then return end

    local job = getEnabledJob(jobId)
    if job then
        exports.ox_target:removeLocalEntity(boss, {
            ('lvlup_delivery_start_%s'):format(jobId),
            ('lvlup_delivery_finish_%s'):format(jobId)
        })
    end

    DeleteEntity(boss)
    bosses[jobId] = nil
end

local function resetJob()
    resetDelivery()

    if currentJob then
        removeVehicleTarget()
    end

    for jobId in pairs(bosses) do
        deleteBoss(jobId)
    end

    for jobId, point in pairs(startZones) do
        point:remove()
        startZones[jobId] = nil
    end

    if holdingItem then
        doCarry(false)
    end

    isHired = false
    holdingItem = false
    itemDelivered = false
    activeOrder = false
    currentJobId = nil
    currentJob = nil
    jobVehicle = nil
end

local function takeItem()
    local ped = cache.ped

    if holdingItem or IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) then return end

    local pos = GetEntityCoords(ped)

    if #(pos - currentDeliveryVec) >= 30.0 then
        return DoNotification(currentJob.notCloseMessage, 'error')
    end

    if lib.callback.await('lvlup_delivery:server:takeItem', false) then
        doCarry(true)
    end
end

local function returnItem()
    if not holdingItem then return end

    if lib.callback.await('lvlup_delivery:server:returnItem', false) then
        doCarry(false)
    end
end

local function waitForNextMission()
    local delay = (currentJob.missionDelay or 0) * 1000
    if delay <= 0 then return end

    Wait(delay)
end

function NextDelivery(data)
    if activeOrder then return end

    currentDeliveryVec = vec3(data.current.x, data.current.y, data.current.z)

    jobBlip = AddBlipForCoord(currentDeliveryVec)

    SetBlipSprite(jobBlip, 1)
    SetBlipDisplay(jobBlip, 4)
    SetBlipScale(jobBlip, 0.8)
    SetBlipFlashes(jobBlip, true)
    SetBlipAsShortRange(jobBlip, true)
    SetBlipColour(jobBlip, 2)
    SetBlipRoute(jobBlip, true)
    SetBlipRouteColour(jobBlip, 2)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(currentJob.blipLabel or currentJob.label)
    EndTextCommandSetBlipName(jobBlip)

    currZone = exports.ox_target:addSphereZone({
        coords = currentDeliveryVec,
        radius = 1.3,
        debug = false,
        options = {
            {
                icon = currentJob.icon,
                label = currentJob.deliverLabel,
                onSelect = deliverItem,
                distance = 1.5
            }
        }
    })

    activeOrder = true

    DoNotification(currentJob.newDeliveryMessage, 'success')
end

local function pullOutVehicle(jobId, netId, data)
    local job = getEnabledJob(jobId)
    if not job then return end

    currentJobId = jobId
    currentJob = job

    jobVehicle = lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netId) then return NetToVeh(netId) end
    end, 'Could not load entity in time.', 1000)

    if not jobVehicle or jobVehicle == 0 then
        TriggerServerEvent('lvlup_delivery:server:cleanup')
        return DoNotification('Error spawning the vehicle.', 'error')
    end

    SetVehicleNumberPlateText(jobVehicle, ('%s%s'):format(job.vehiclePlatePrefix or 'JOB', math.random(100, 999)))
    TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(jobVehicle))
    SetVehicleDirtLevel(jobVehicle, 1)
    SetVehicleEngineOn(jobVehicle, true, true)

    Wait(500)
    Entity(jobVehicle).state.fuel = 100

    isHired = true
    NextDelivery(data)

    exports.ox_target:addEntity(netId, {
        {
            name = 'lvlup_delivery_take_item',
            icon = job.icon,
            label = job.takeLabel,
            onSelect = takeItem,
            canInteract = function()
                return isHired and activeOrder and not holdingItem
            end,
            distance = 2.5
        },
        {
            name = 'lvlup_delivery_return_item',
            icon = job.icon,
            label = job.returnLabel,
            onSelect = returnItem,
            canInteract = function()
                return isHired and activeOrder and holdingItem
            end,
            distance = 2.5
        }
    })
end

local function finishWork()
    if not isHired or not currentJob then return end

    local ped = cache.ped
    local pos = GetEntityCoords(ped)
    local finishSpot = currentJob.bossCoords.xyz

    if #(pos - finishSpot) > 10.0 then return end

    removeVehicleTarget()

    local success = lib.callback.await('lvlup_delivery:server:clockOut', false)

    if success then
        resetDelivery()
        doCarry(false)

        isHired = false
        activeOrder = false
        currentJobId = nil
        currentJob = nil
        jobVehicle = nil

        DoNotification('You ended your shift.', 'success')
    end
end

local function spawnBoss(jobId)
    local job = getEnabledJob(jobId)
    if not job or bosses[jobId] and DoesEntityExist(bosses[jobId]) then return end

    lib.requestModel(job.bossModel)

    local boss = CreatePed(0, job.bossModel, job.bossCoords, false, false)
    bosses[jobId] = boss

    SetEntityAsMissionEntity(boss)
    SetPedFleeAttributes(boss, 0, 0)
    SetBlockingOfNonTemporaryEvents(boss, true)
    SetEntityInvincible(boss, true)
    FreezeEntityPosition(boss, true)

    lib.requestAnimDict('amb@world_human_leaning@female@wall@back@holding_elbow@idle_a')
    TaskPlayAnim(boss,
        'amb@world_human_leaning@female@wall@back@holding_elbow@idle_a',
        'idle_a', 8.0, 1.0, -1, 1, 0, 0, 0, 0
    )
    RemoveAnimDict('amb@world_human_leaning@female@wall@back@holding_elbow@idle_a')
    SetModelAsNoLongerNeeded(job.bossModel)

    exports.ox_target:addLocalEntity(boss, {
        {
            name = ('lvlup_delivery_start_%s'):format(jobId),
            icon = job.icon,
            label = job.startLabel,
            onSelect = function()
                local netId, data = lib.callback.await('lvlup_delivery:server:spawnVehicle', false, jobId)
                if netId and data then pullOutVehicle(jobId, netId, data) end
            end,
            canInteract = function()
                return not isHired
            end,
            distance = 1.5
        },
        {
            name = ('lvlup_delivery_finish_%s'):format(jobId),
            icon = job.icon,
            label = job.finishLabel,
            onSelect = finishWork,
            canInteract = function()
                return isHired and currentJobId == jobId
            end,
            distance = 1.5
        }
    })
end

function deliverItem()
    if not (holdingItem and isHired and not itemDelivered) then
        return DoNotification(currentJob.missingItemMessage, 'error')
    end

    itemDelivered = true

    if lib.progressCircle({
        duration = 5000,
        position = 'bottom',
        label = currentJob.progressLabel,
        useWhileDead = true,
        canCancel = false,
        disable = { move = true, car = true, mouse = false, combat = true }
    }) then
        local success, data = lib.callback.await('lvlup_delivery:server:payment', false)

        if not success then
            itemDelivered = false
            return
        end

        resetDelivery()

        activeOrder = false
        itemDelivered = false

        doCarry(false)

        if data then
            waitForNextMission()

            if isHired and currentJobId == data.job then
                NextDelivery(data)
            end
        end
    end
end

local function startJobPoints()
    for jobId, job in pairs(Config.Jobs) do
        if job.enabled ~= false and not startZones[jobId] then
            local routeJobId = jobId

            startZones[jobId] = lib.points.new({
                coords = job.bossCoords.xyz,
                distance = 50,
                onEnter = function()
                    spawnBoss(routeJobId)
                end,
                onExit = function()
                    deleteBoss(routeJobId)
                end
            })
        end
    end
end

function OnPlayerLoaded() startJobPoints() end
function OnPlayerUnload() resetJob() end

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource or not hasPlyLoaded() then return end
    startJobPoints()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    TriggerServerEvent('lvlup_delivery:server:cleanup')
    resetJob()
end)
