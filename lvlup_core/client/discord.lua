local Config = {
    AppID = '',

    LargeImage = {
        name = '',
        hoverText = ''
    },

    SmallImage = {
        name = '',
        hoverText = ''
    },

    DiscordButtons = {
        { index = 0, name = 'Join the Discord', url = 'https://discord.gg/' },
        { index = 1, name = 'Join the Server', url = 'https://cfx.re/join/' }
    },

    DefaultPresence = 'Roleplaying'
}

local PresenceMode = 'all'
local CustomText = Config.DefaultPresence

local PlayerPedId = PlayerPedId
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local GetVehiclePedIsUsing = GetVehiclePedIsUsing
local GetEntitySpeed = GetEntitySpeed
local GetEntityModel = GetEntityModel

local function getHeadingDirection(heading)
    local directions = {
        'North', 'North East', 'East', 'South East',
        'South', 'South West', 'West', 'North West'
    }

    return directions[math.floor((heading % 360 + 22.5) / 45) % 8 + 1]
end

local function getVehicleLabel(vehicle)
    if not vehicle or vehicle == 0 then
        return 'a vehicle'
    end

    local model = GetEntityModel(vehicle)
    local label = GetLabelText(GetDisplayNameFromVehicleModel(model))

    if label == 'NULL' or label == 'CARNOTFOUND' then
        return 'a vehicle'
    end

    return label
end

local function getCurrentZone()
    if exports['xt-zones'] and exports['xt-zones'].getCurrentZoneName then
        return exports['xt-zones']:getCurrentZoneName() or 'Los Santos'
    end

    local coords = GetEntityCoords(PlayerPedId())
    return GetNameOfZone(coords.x, coords.y, coords.z) or 'Los Santos'
end

local function buildRichPresence()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)

    local zone = getCurrentZone()
    local heading = getHeadingDirection(GetEntityHeading(ped))

    local vehicle = GetVehiclePedIsUsing(ped)
    local vehicleLabel = getVehicleLabel(vehicle)
    local speed = (vehicle ~= 0) and math.ceil(GetEntitySpeed(vehicle) * 2.236936) or 0

    -- On foot
    if IsPedOnFoot(ped) then
        if IsEntityInWater(ped) then
            return ('Swimming near %s'):format(zone)
        end

        if IsPedStill(ped) then
            return ('Standing on %s [%s]'):format(street, zone)
        end

        if IsPedSprinting(ped) then
            return ('Sprinting %s on %s [%s]'):format(heading, street, zone)
        end

        if IsPedRunning(ped) then
            return ('Running %s on %s [%s]'):format(heading, street, zone)
        end

        return ('Walking %s on %s [%s]'):format(heading, street, zone)
    end

    -- In vehicle
    if vehicle ~= 0 then
        -- Air vehicles
        if IsPedInAnyHeli(ped) or IsPedInAnyPlane(ped) then
            if IsEntityInAir(vehicle) or GetEntityHeightAboveGround(vehicle) > 5.0 then
                return ('Flying near %s [%s] in a %s'):format(street, zone, vehicleLabel)
            else
                return ('Landed on %s [%s] in a %s'):format(street, zone, vehicleLabel)
            end
        end

        -- Boats
        if IsPedInAnyBoat(ped) or IsPedInAnySub(ped) then
            return ('Boating near %s in a %s'):format(zone, vehicleLabel)
        end

        -- Land vehicles
        if speed < 3 then
            return ('Parked on %s [%s] in a %s'):format(street, zone, vehicleLabel)
        end

        return ('Driving %s on %s [%s] in a %s'):format(heading, street, zone, vehicleLabel)
    end

    return Config.DefaultPresence
end

local function updateDiscordPresence()
    if PresenceMode == 'hide' then
        local players = #GetActivePlayers() - 1
        SetRichPresence(('Hanging out with %d other player%s'):format(
            players,
            players == 1 and '' or 's'
        ))
        return
    end

    if PresenceMode == 'custom' then
        SetRichPresence(CustomText)
        return
    end

    SetRichPresence(buildRichPresence())
end

local function updateAssets()
    SetDiscordAppId(Config.AppID)

    SetDiscordRichPresenceAsset(Config.LargeImage.name)
    SetDiscordRichPresenceAssetText(Config.LargeImage.hoverText)

    SetDiscordRichPresenceAssetSmall(Config.SmallImage.name)
    SetDiscordRichPresenceAssetSmallText(Config.SmallImage.hoverText)

    for i = 1, #Config.DiscordButtons do
        local btn = Config.DiscordButtons[i]
        SetDiscordRichPresenceAction(i - 1, btn.name, btn.url)
    end
end

CreateThread(function()
    updateAssets()

    while true do
        updateDiscordPresence()
        Wait(PresenceMode == 'hide' and 15000 or 5000)
    end
end)

RegisterCommand('discord', function(_, args)
    local mode = args[1] and args[1]:lower()

    if mode == 'show' or mode == 'all' then
        PresenceMode = 'all'
        lib.notify({
            title = 'Discord RPC',
            description = 'Rich Presence: Full status enabled',
            type = 'success'
        })

    elseif mode == 'hide' then
        PresenceMode = 'hide'
        lib.notify({
            title = 'Discord RPC',
            description = 'Rich Presence: Hidden (player count only)',
            type = 'success'
        })

    elseif mode == 'custom' and args[2] then
        PresenceMode = 'custom'
        CustomText = table.concat(args, ' ', 2)

        lib.notify({
            title = 'Discord RPC',
            description = 'Rich Presence: Custom text set',
            type = 'success'
        })

    else
        lib.notify({
            title = 'Discord RPC',
            description = 'Usage: /discord [show | hide | custom "your text"]',
            type = 'inform'
        })
    end
end, false)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetRichPresence(Config.DefaultPresence)
end)
