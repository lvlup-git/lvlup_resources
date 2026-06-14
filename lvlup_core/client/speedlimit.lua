local SPEED_LIMIT_MPH = 170.0
local SPEED_LIMIT = SPEED_LIMIT_MPH * 0.44704

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if GetPedInVehicleSeat(veh, -1) == ped then
                SetEntityMaxSpeed(veh, SPEED_LIMIT)
            end
        end
        Wait(500)
    end
end)
