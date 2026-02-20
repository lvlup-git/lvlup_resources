local Config = {
    AppID = '',
    LargeImage = { name = '', hoverText = '' },
    SmallImage = { name = '', hoverText = '' },
    DiscordButtons = {
        { index = 0, name = 'Join our Discord', url = 'https://discord.gg/' },
        { index = 1, name = 'Join the Server', url = 'https://cfx.re/join/' }
    },
    DefaultPresence = 'Roleplaying'
}

local WhichPresence = 'all'
local CustomText = Config.DefaultPresence
local StartDiscordPresence = true

local function getZoneName(x, y, z)
    local zoneCode = GetNameOfZone(x, y, z)
    local zoneName = GetLabelText(zoneCode)
    return zoneName == 'NULL' or zoneName == '' and 'San Andreas' or zoneName
end

local function getHeadingDirection(heading)
    heading = heading % 360
    local directions = {'North', 'North East', 'East', 'South East', 'South', 'South West', 'West', 'North West'}
    return directions[math.floor((heading + 22.5) / 45) % 8 + 1]
end

local function getVehicleLabel(vehicle)
    if not vehicle or vehicle == 0 then return '' end
    local label = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    return label == 'NULL' or label == 'CARNOTFOUND' and '' or label
end

local function getPlayerCount()
    return #GetActivePlayers()
end

local function setRichPresence(text)
    SetRichPresence(text)
end

local function updateAssets()
    SetDiscordAppId(Config.AppID)
    SetDiscordRichPresenceAsset(Config.LargeImage.name)
    SetDiscordRichPresenceAssetText(Config.LargeImage.hoverText)
    SetDiscordRichPresenceAssetSmall(Config.SmallImage.name)
    SetDiscordRichPresenceAssetSmallText(Config.SmallImage.hoverText)
end

local function buildPresenceText()
    local playerPed = PlayerPedId()
    local x, y, z = table.unpack(GetEntityCoords(playerPed, true))
    local streetHash = GetStreetNameAtCoord(x, y, z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local zoneName = getZoneName(x, y, z)
    local heading = getHeadingDirection(GetEntityHeading(playerPed))
    local vehicle = GetVehiclePedIsUsing(playerPed)
    local vehicleLabel = getVehicleLabel(vehicle)
    local speedMph = vehicle and math.ceil(GetEntitySpeed(vehicle) * 2.236936) or 0

    if zoneName == 'Cayo Perico' then
        return 'Hanging out on Cayo Perico'
    elseif IsPedOnFoot(playerPed) and not IsEntityInWater(playerPed) then
        if IsPedStill(playerPed) then
            return 'Standing on ' .. streetName .. ' [' .. zoneName .. ']'
        elseif IsPedWalking(playerPed) then
            return 'Walking ' .. heading .. ' on ' .. streetName .. ' [' .. zoneName .. ']'
        elseif IsPedRunning(playerPed) then
            return 'Running ' .. heading .. ' on ' .. streetName .. ' [' .. zoneName .. ']'
        elseif IsPedSprinting(playerPed) then
            return 'Sprinting ' .. heading .. ' on ' .. streetName .. ' [' .. zoneName .. ']'
        end
    elseif vehicle and not IsPedOnFoot(playerPed) and
           not IsPedInAnyHeli(playerPed) and not IsPedInAnyPlane(playerPed) and
           not IsPedInAnyBoat(playerPed) and not IsPedInAnySub(playerPed) then
        if speedMph < 2 then
            return 'Parked on ' .. streetName .. ' [' .. zoneName .. '] in a ' .. vehicleLabel
        else
            return 'Driving ' .. heading .. ' on ' .. streetName .. ' [' .. zoneName .. '] in a ' .. vehicleLabel
        end
    elseif IsPedInAnyHeli(playerPed) or IsPedInAnyPlane(playerPed) then
        if IsEntityInAir(vehicle) or GetEntityHeightAboveGround(vehicle) > 5.0 then
            return 'Flying near ' .. streetName .. ' [' .. zoneName .. '] in a ' .. vehicleLabel
        else
            return 'Landed on ' .. streetName .. ' [' .. zoneName .. '] in a ' .. vehicleLabel
        end
    elseif IsEntityInWater(playerPed) then
        return 'Swimming near ' .. zoneName
    elseif IsPedInAnyBoat(playerPed) and IsEntityInWater(vehicle) then
        return 'Boating near ' .. zoneName .. ' in a ' .. vehicleLabel
    elseif IsPedInAnySub(playerPed) and IsEntityInWater(vehicle) then
        return 'Diving in a submersible'
    end

    return Config.DefaultPresence
end

local function initDiscordButtons()
    if StartDiscordPresence then
        for _, button in ipairs(Config.DiscordButtons) do
            SetDiscordRichPresenceAction(button.index, button.name, button.url)
        end
        StartDiscordPresence = false
    end
end

local function setPresenceMode(mode, customText)
    if mode == 'show' then
        WhichPresence = 'all'
    elseif mode == 'hide' then
        WhichPresence = 'hide'
    elseif mode == 'custom' then
        WhichPresence = 'custom'
        if customText then CustomText = customText end
    end
end

local function startPresenceLoop()
    updateAssets()
    CreateThread(function()
        while true do
            local sleep = 5000
            if WhichPresence == 'all' then
                setRichPresence(buildPresenceText())
            elseif WhichPresence == 'custom' then
                setRichPresence(CustomText)
            elseif WhichPresence == 'hide' then
                setRichPresence('In server with ' .. getPlayerCount() .. ' other players')
                sleep = 10000
            else
                setRichPresence(Config.DefaultPresence)
                sleep = 10000
            end
            Wait(sleep)
        end
    end)
end

AddEventHandler('playerSpawned', initDiscordButtons)

RegisterCommand('discord', function(src, args)
    local option = args[1]
    local ctext = args[2]
    setPresenceMode(option, ctext)
end, false)

TriggerEvent('chat:addSuggestion', '/discord', 'Set your Discord Rich Presence status', {{name = "options", help = "show/hide/custom"}})

startPresenceLoop()