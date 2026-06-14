local CONFIG = {
    headBone     = 31086,
    zOffset      = 0.2,
    maxDistance  = 50.0,
    duration     = 7000,   -- ms
    updateIntervalPlayer = 150,  -- ms
    losFlag      = 17,
    textScale    = 0.35,
    closeLosDist = 15.0,
    losCheckInterval = 200,  -- ms
    maxTextLength = 200,
}

local State = {
    activeDisplays = {},
    playerPed      = PlayerPedId(),
    playerPos      = vec3(0, 0, 0),
}

CreateThread(function()
    while true do
        State.playerPed = PlayerPedId()
        State.playerPos = GetEntityCoords(State.playerPed)
        Wait(CONFIG.updateIntervalPlayer)
    end
end)

local function draw3dText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    SetTextScale(CONFIG.textScale, CONFIG.textScale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(_x, _y)
end

CreateThread(function()
    while true do
        local now = GetGameTimer()

        for ped, data in pairs(State.activeDisplays) do
            if not DoesEntityExist(ped) then
                State.activeDisplays[ped] = nil
                goto continue
            end

            local elapsed = now - data.startTime
            if elapsed > CONFIG.duration then
                State.activeDisplays[ped] = nil
                goto continue
            end

            local targetPos = GetEntityCoords(ped)
            local dist = #(State.playerPos - targetPos)

            if dist <= CONFIG.maxDistance then
                local shouldCheckLos = (dist <= CONFIG.closeLosDist) or (elapsed % CONFIG.losCheckInterval < 16)

                if not shouldCheckLos or HasEntityClearLosToEntity(State.playerPed, ped, CONFIG.losFlag) then
                    local headCoords = GetPedBoneCoords(ped, CONFIG.headBone, 0.0, 0.0, 0.0)
                    draw3dText(headCoords.x, headCoords.y, headCoords.z + CONFIG.zOffset, data.text)
                end
            end

            ::continue::
        end

        Wait(next(State.activeDisplays) and 0 or 250)
    end
end)

local function displayText(ped, text)
    if not DoesEntityExist(ped) then return end

    State.activeDisplays[ped] = {
        text      = text,
        startTime = GetGameTimer()
    }
end

RegisterNetEvent('lvlup_3dme:client:shareDisplay', function(text, targetServerId)
    if type(text) ~= 'string' or type(targetServerId) ~= 'number' then return end

    text = text:gsub('[%c]', ' '):gsub('~', ''):gsub('%s+', ' '):match('^%s*(.-)%s*$')
    if text == '' then return end
    if #text > CONFIG.maxTextLength then
        text = text:sub(1, CONFIG.maxTextLength - 3) .. '...'
    end

    local player = GetPlayerFromServerId(targetServerId)
    local isSelf = targetServerId == GetPlayerServerId(PlayerId())

    if player == -1 and not isSelf then return end
    if isSelf then player = PlayerId() end

    local ped = GetPlayerPed(player)
    if not DoesEntityExist(ped) then return end

    displayText(ped, text)
end)

TriggerEvent("chat:addSuggestion", "/me", "Perform an action", {
    { name = "action", help = "e.g., scratches nose or wipes hands" }
})

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    State.activeDisplays = {}
    TriggerEvent('chat:removeSuggestion', '/me')
end)
