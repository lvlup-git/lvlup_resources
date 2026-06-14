local isMegaphoneActive = false
local lastToggle = 0
local toggleCooldown = 300

local function IsPlayerInEmergencyVehicle()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return false end
    return GetVehicleClass(vehicle) == 18
end

local function ToggleMegaphone(state)
    local now = GetGameTimer()
    if now - lastToggle < toggleCooldown then return end
    lastToggle = now

    if state then
        if IsPlayerInEmergencyVehicle() and not isMegaphoneActive then
            exports['pma-voice']:overrideProximityRange(100.0, true)
            isMegaphoneActive = true
            lib.notify({ title = 'Megaphone', description = 'Megaphone Activated (100m)', type = 'success' })
        end
    else
        if isMegaphoneActive then
            exports['pma-voice']:clearProximityOverride()
            isMegaphoneActive = false
            lib.notify({ title = 'Megaphone', description = 'Megaphone Deactivated', type = 'error' })
        end
    end
end

RegisterCommand('+Megaphone', function()
    ToggleMegaphone(true)
end, false)

RegisterCommand('-Megaphone', function()
    ToggleMegaphone(false)
end, false)

RegisterKeyMapping('+Megaphone', 'Emergency Megaphone (Hold)', 'keyboard', 'LSHIFT')

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isMegaphoneActive then
        exports['pma-voice']:clearProximityOverride()
    end
end)
