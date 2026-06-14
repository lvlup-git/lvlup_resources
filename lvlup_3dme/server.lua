local CONFIG = {
    maxText = 200,
    nearbyDistance = 50.0,
    meCooldown = 3000
}

local cooldowns = {}

local function getPlayerPosition(source)
    local ped = GetPlayerPed(source)
    if not ped or ped <= 0 or not DoesEntityExist(ped) then return end

    return GetEntityCoords(ped)
end

local function getNearbyPlayers(source)
    local sourcePos = getPlayerPosition(source)
    local nearby = {}
    if not sourcePos then return nearby end

    for _, playerIdString in ipairs(GetPlayers()) do
        local playerId = tonumber(playerIdString)
        if playerId and playerId ~= source then
            local playerPos = getPlayerPosition(playerId)
            if playerPos and #(sourcePos - playerPos) <= CONFIG.nearbyDistance then
                nearby[#nearby + 1] = playerId
            end
        end
    end

    return nearby
end

local function getCitizenId(source)
    local player = exports.qbx_core:GetPlayer(source)
    return player and player.PlayerData and player.PlayerData.citizenid or 'unknown'
end

local function sanitizeText(text)
    text = text:gsub('[%c]', ' '):gsub('~', ''):gsub('%s+', ' '):match('^%s*(.-)%s*$')
    if #text > CONFIG.maxText then
        text = text:sub(1, CONFIG.maxText - 3) .. '...'
    end

    return text
end

local function sanitizeDiscordText(text)
    return text:gsub('@', '@\226\128\139')
end

local function notify(source, message, color)
    TriggerClientEvent('chat:addMessage', source, {
        color = color,
        args = {'System', message}
    })
end

RegisterCommand('me', function(source, args)
    if source <= 0 then return end

    local text = sanitizeText(table.concat(args, ' '))
    if text == '' then
        return notify(source, 'Usage: /me [action]', {255, 0, 0})
    end

    local now = GetGameTimer()
    if cooldowns[source] and now - cooldowns[source] < CONFIG.meCooldown then
        return notify(source, 'Slow down! Wait a few seconds.', {255, 165, 0})
    end
    cooldowns[source] = now

    local name = GetPlayerName(source) or 'Unknown'
    local citizenId = getCitizenId(source)
    local nearbyPlayers = getNearbyPlayers(source)

    TriggerClientEvent('lvlup_3dme:client:shareDisplay', source, text, source)
    for _, nearbyId in ipairs(nearbyPlayers) do
        TriggerClientEvent('lvlup_3dme:client:shareDisplay', nearbyId, text, source)
    end

    if exports.lvlup_core then
        local webhook = GetConvar('3dme_webhook', '')
        if not webhook or webhook == '' then
            print(('[lvlup_3dme] No webhook configured, go to your server.cfg and add `3dme_webhook "<webhook_url>"`'))
            return
        end

        local message = table.concat({
            '**Player:**',
            ('- %s [ID: %d] (CID: %s)'):format(sanitizeDiscordText(name), source, sanitizeDiscordText(citizenId)),
            '',
            '**Action:**',
            ('- %s'):format(sanitizeDiscordText(text)),
            '',
            '**Visible To:**',
            ('- %d players'):format(1 + #nearbyPlayers)
        }, '\n')

        exports.lvlup_core:SendToDiscord(webhook, 'lvlup_3dme', '', 3093151, '/me log', message)
    else
        print(('[lvlup_3dme] Player: %s [ID: %d] (CID: %s) | Action: %s | Visible To: %d players'):format(name, source, citizenId, text, 1 + #nearbyPlayers))
    end
end, false)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)
