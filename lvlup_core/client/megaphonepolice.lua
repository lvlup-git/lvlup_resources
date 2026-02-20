local QBCore = exports['qb-core']:GetCoreObject()

local function IsPlayerInPoliceVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then return false end
    return GetVehicleClass(vehicle) == 18
end

RegisterCommand('+Megaphone', function()
    if IsPlayerInPoliceVehicle() then
        exports['pma-voice']:overrideProximityRange(100.0, true)
        QBCore.Functions.Notify('Megaphone on', 'success')
    end
end, false)

RegisterCommand('-Megaphone', function()
    if IsPlayerInPoliceVehicle() then
        exports['pma-voice']:clearProximityOverride()
        QBCore.Functions.Notify('Megaphone off', 'error')
    end
end, false)

RegisterKeyMapping('+Megaphone', 'Police vehicle megaphone', 'keyboard', '')