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

local function LoadAnimationDic(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local timeout = 0
        while not HasAnimDictLoaded(dict) and timeout < 100 do
            timeout = timeout + 1
            Wait(0)
        end
    end
end

local function attachProp(name)
    removeAttachedProp()

    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local data = Config.Toys[name]
    if not data then return end

    LoadAnimationDic(data.animName)
    TaskPlayAnim(ped, data.animName, data.animDict, 5.0, -1, -1, 50, 0, false, false, false)

    local model = data.model or GetHashKey(data.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    attachedProp = CreateObject(model, pos.x, pos.y, pos.z, true, true, true)
    AttachEntityToEntity(
        attachedProp, ped, GetPedBoneIndex(ped, 57005),
        data.x, data.y, data.z,
        data.xR, data.yR, data.zR,
        true, true, false, true, 1, true
    )

    lastPropName = name

    if data.emoteLoop then
        TriggerEvent('core:client:loop', data)
    end
end

RegisterNetEvent('core:client:loop')
AddEventHandler('core:client:loop', function(data)
    local ped = PlayerPedId()
    while lastPropName ~= nil do
        Wait(550)
        if not IsEntityPlayingAnim(ped, data.animName, data.animDict, 3) then
            if lastPropName ~= nil then
                TaskPlayAnim(ped, data.animName, data.animDict, 5.0, -1, -1, 50, 0, false, false, false)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        removeAttachedProp()
    end
end)

RegisterNetEvent('core:client:UseToy')
AddEventHandler('core:client:UseToy', function(name)
    if lastPropName ~= name then
        attachProp(name)
    else
        removeAttachedProp()
    end
end)
