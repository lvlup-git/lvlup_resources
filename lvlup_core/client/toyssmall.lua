local lastSmallPropName = nil
local attachedSmallProp = 0

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
    removeAttachedSmallProp() -- call after definition

    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local data = Config.SmallToys[name]
    if not data then return end

    local model = data.model or GetHashKey(data.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    attachedSmallProp = CreateObject(model, pos.x, pos.y, pos.z, true, true, true)
    AttachEntityToEntity(
        attachedSmallProp, ped, GetPedBoneIndex(ped, 45509),
        data.x, data.y, data.z,
        data.xR, data.yR, data.zR,
        true, true, false, true, 1, true
    )

    lastSmallPropName = name
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        removeAttachedSmallProp()
    end
end)

RegisterNetEvent('core:client:UseSmallToy')
AddEventHandler('core:client:UseSmallToy', function(name)
    if lastSmallPropName ~= name then
        attachSmallProp(name)
    else
        removeAttachedSmallProp()
    end
end)