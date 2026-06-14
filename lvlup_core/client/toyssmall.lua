local lastSmallPropName = nil
local attachedSmallProp = 0

local function loadModel(model)
    model = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(model) then return end

    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(0) end
    return HasModelLoaded(model) and model or nil
end

local function removeAttachedSmallProp()
    if DoesEntityExist(attachedSmallProp) then
        DeleteEntity(attachedSmallProp)
        attachedSmallProp = 0
    end
    ClearPedTasks(PlayerPedId())
    ClearPedSecondaryTask(PlayerPedId())
    lastSmallPropName = nil
end

local function attachSmallProp(name)
    removeAttachedSmallProp()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local data = lvlup_config_toys.SmallToys[name]
    if not data then return end
    local model = loadModel(data.model)
    if not model then return end

    attachedSmallProp = CreateObject(model, pos.x, pos.y, pos.z, true, true, true)
    AttachEntityToEntity(attachedSmallProp, ped, GetPedBoneIndex(ped, 45509), data.x, data.y, data.z, data.xR, data.yR, data.zR, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(model)
    lastSmallPropName = name
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then removeAttachedSmallProp() end
end)

RegisterNetEvent('core:client:UseSmallToy')
AddEventHandler('core:client:UseSmallToy', function(name)
    if lastSmallPropName ~= name then
        attachSmallProp(name)
    else
        removeAttachedSmallProp()
    end
end)
