local whitelist = {
    'FLATBED', 'FLATBED2', 'biftowmfd2', 'SLAMTRUCK', 'ONXTOWKING', 'ONXTOWKING2'
}

local function notify(description, type)
    lib.notify({description = description, type = type or 'inform'})
end

local function GetVehicleBelowMe(fromCoords, toCoords)
    local ray = CastRayPointToPoint(fromCoords.x, fromCoords.y, fromCoords.z, toCoords.x, toCoords.y, toCoords.z, 10, PlayerPedId(), 0)
    local _, _, _, _, vehicle = GetRaycastResult(ray)
    return vehicle
end

local function contains(value, list)
    for i = 1, #list do
        if list[i] == value then return true end
    end
    return false
end

RegisterCommand('attach', function()
    local ped = PlayerPedId()

    if not IsPedInAnyVehicle(ped, false) then
        return notify("You're not in a vehicle.", 'error')
    end

    local vehicle = GetVehiclePedIsIn(ped, false)

    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return notify('You must be in the driver seat.', 'error')
    end

    if IsEntityAttached(vehicle) then
        return notify('Vehicle is already attached.', 'error')
    end

    local vehCoords = GetEntityCoords(vehicle)
    local belowOffset = GetOffsetFromEntityInWorldCoords(vehicle, 1.0, 0.0, -1.5)
    local belowEntity = GetVehicleBelowMe(vehCoords, belowOffset)

    if not belowEntity or belowEntity == 0 then
        return notify('No valid vehicle below.', 'error')
    end

    local belowModel = GetEntityModel(belowEntity)
    local belowName = GetDisplayNameFromVehicleModel(belowModel)

    if not contains(belowName, whitelist) then
        return notify(("Can't attach to this vehicle: %s"):format(belowName), 'error')
    end

    local vehRot = GetEntityRotation(vehicle, 2)
    local belowRot = GetEntityRotation(belowEntity, 2)
    local offset = GetOffsetFromEntityGivenWorldCoords(belowEntity, vehCoords)

    local pitch = vehRot.x - belowRot.x
    local yaw = vehRot.z - belowRot.z
    AttachEntityToEntity(vehicle, belowEntity, GetEntityBoneIndexByName(belowEntity, 'chassis'), offset.x, offset.y, offset.z, pitch, 0.0, yaw, false, false, true, false, 0, true)
    notify('Vehicle attached successfully.', 'success')
end)

RegisterCommand('detach', function()
    local ped = PlayerPedId()

    if not IsPedInAnyVehicle(ped, false) then
        return notify('You are not in a vehicle.', 'error')
    end

    local vehicle = GetVehiclePedIsIn(ped, false)

    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return notify('You must be in the driver seat.', 'error')
    end

    if not IsEntityAttached(vehicle) then
        return notify("Vehicle isn't attached to anything.", 'error')
    end

    DetachEntity(vehicle, false, true)
    notify('Vehicle detached successfully.', 'success')
end)
