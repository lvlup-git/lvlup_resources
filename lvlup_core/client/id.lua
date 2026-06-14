local showServerId = false
local playerDistances = {}
local drawDistance = 50

CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerPos = GetEntityCoords(playerPed)
        for _, playerId in ipairs(GetActivePlayers()) do
            local targetPed = GetPlayerPed(playerId)
            if targetPed and DoesEntityExist(targetPed) then
                local targetPos = GetEntityCoords(targetPed)
                playerDistances[playerId] = math.floor(#(playerPos - targetPos))
            end
        end
        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        if showServerId then
            local players = GetActivePlayers()
            for _, playerId in ipairs(players) do
                local dist = playerDistances[playerId]
                if dist and dist < drawDistance then
                    local ped = GetPlayerPed(playerId)
                    if ped and DoesEntityExist(ped) then
                        local headCoords = GetPedBoneCoords(ped, 12844)
                        local x, y, z = table.unpack(headCoords)
                        z = z + 0.2
                        local serverId = GetPlayerServerId(playerId)
                        local name = GetPlayerName(playerId)
                        local talking = NetworkIsPlayerTalking(playerId)
                        local displayText = (talking and '[Talking] ' or '') .. '[' .. serverId .. '] ' .. name
                        DrawText3D(x, y, z, displayText, talking and 'blue' or nil)
                    end
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

RegisterCommand('showplayerid', function() showServerId = not showServerId end, false)

RegisterKeyMapping('showplayerid', 'Toggle player IDs', 'keyboard', '')

function DrawText3D(x, y, z, text, color)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextCentre(true)
    if color == 'blue' then
        SetTextColour(90, 90, 180, 255)
    else
        SetTextColour(255, 255, 255, 255)
    end
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    EndTextCommandDisplayText(_x, _y)
end
