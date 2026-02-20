local showServerId = false
local playerDistances = {}

CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local px, py, pz = table.unpack(GetEntityCoords(playerPed, true))
        for _, playerId in ipairs(GetActivePlayers()) do
            local targetPed = GetPlayerPed(playerId)
            local tx, ty, tz = table.unpack(GetEntityCoords(targetPed, true))
            local dist = math.floor(GetDistanceBetweenCoords(px, py, pz, tx, ty, tz, true))
            playerDistances[playerId] = dist
        end
        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        if showServerId then
            for _, playerId in ipairs(GetActivePlayers()) do
                local dist = playerDistances[playerId]
                if dist and dist < 50 then
                    local ped = GetPlayerPed(playerId)
                    if ped and DoesEntityExist(ped) then
                        local headCoords = GetPedBoneCoords(ped, 12844)
                        local x, y, z = table.unpack(headCoords)
                        z = z + 0.2
                        local playerName = GetPlayerName(playerId)
                        local serverId = GetPlayerServerId(playerId)
                        local isTalking = NetworkIsPlayerTalking(playerId)
                        local displayText = (isTalking and "[Talking] " or "") .. '[' .. serverId .. '] '.. playerName
                        local color = isTalking and 'blue' or nil
                        DrawText3D(x, y, z, displayText, color)
                    end
                end
            end
        end
        Wait(0)
    end
end)

RegisterCommand('showplayerid', function() showServerId = not showServerId end, false)
RegisterKeyMapping('showplayerid', 'Toggle player IDs', 'keyboard', '')

function DrawText3D(x, y, z, text, color)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    if color == 'blue' then
        SetTextColour(90, 90, 180, 255)
    else
        SetTextColour(255, 255, 255, 255)
    end
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    local width = EndTextCommandGetWidth(1)
    local height = 0.02
    EndTextCommandDisplayText(_x - width / 2, _y - height / 2)
end