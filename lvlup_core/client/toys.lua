local lastPropName = nil
local attachedProp = 0

local function removeAttachedProp()
    if DoesEntityExist(attachedProp) then
        DeleteEntity(attachedProp)
        attachedProp = 0
    end
    ClearPedTasks(PlayerPedId())
    ClearPedSecondaryTask(PlayerPedId())
    lastPropName = nil
end

local function loadAnimationDict(dict)
    if HasAnimDictLoaded(dict) then return true end

    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(0) end
    return HasAnimDictLoaded(dict)
end

local function loadModel(model)
    model = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(model) then return end

    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(0) end
    return HasModelLoaded(model) and model or nil
end

local function attachProp(name)
    removeAttachedProp()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local data = lvlup_config_toys.Toys[name]
    if not data then return end
    if not loadAnimationDict(data.animName) then return end
    TaskPlayAnim(ped, data.animName, data.animDict, 5.0, -1, -1, 50, 0, false, false, false)
    local model = loadModel(data.model)
    if not model then return removeAttachedProp() end

    attachedProp = CreateObject(model, pos.x, pos.y, pos.z, true, true, true)
    AttachEntityToEntity(attachedProp, ped, GetPedBoneIndex(ped, 57005), data.x, data.y, data.z, data.xR, data.yR, data.zR, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(model)
    lastPropName = name
    if data.emoteLoop then TriggerEvent('core:client:loop', data) end
end

RegisterNetEvent('core:client:loop')
AddEventHandler('core:client:loop', function(data)
    local ped = PlayerPedId()
    while lastPropName ~= nil do
        Wait(550)
        if not IsEntityPlayingAnim(ped, data.animName, data.animDict, 3) then
            if lastPropName ~= nil then TaskPlayAnim(ped, data.animName, data.animDict, 5.0, -1, -1, 50, 0, false, false, false) end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then removeAttachedProp() end
end)

RegisterNetEvent('core:client:UseToy')
AddEventHandler('core:client:UseToy', function(name)
    if lastPropName ~= name then
        attachProp(name)
    else
        removeAttachedProp()
    end
end)
