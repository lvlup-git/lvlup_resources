local NoSpawns = {
    {coords = vec3(1851.8, 3681.54, 32.95), radius = 12.0}
}

local debugDraw = false

local function drawSphere(coords, radius)
    DrawMarker(28, coords.x, coords.y, coords.z, 0, 0, 0, 0, 0, 0, radius, radius, radius, 100, 200, 255, 120, false, false, 2, false)
end

CreateThread(function()
    while true do
        for _, zone in ipairs(NoSpawns) do
            ClearAreaOfPeds(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius, 1)
            ClearAreaOfVehicles(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius, false, false, false, false, false)
            if debugDraw then drawSphere(zone.coords, zone.radius) end
        end
        if debugDraw then Wait(0) else Wait(500) end
    end
end)
