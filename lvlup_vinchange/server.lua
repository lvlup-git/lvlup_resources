local Config = lib.require('config')
local QBCore = exports['qb-core']:GetCoreObject()

local MAX_SERVICE_DISTANCE = 5.0

local function cleanPlate(plate)
    if type(plate) ~= 'string' then return end

    plate = plate:gsub('%s+', ''):upper()
    if plate == '' or #plate > 8 then return end

    return plate
end

local function isNearServiceLocation(source)
    local ped = GetPlayerPed(source)
    if ped <= 0 then return false end

    local coords = GetEntityCoords(ped)
    for _, location in ipairs(Config.Locations) do
        if #(coords - location.coords) <= MAX_SERVICE_DISTANCE then
            return true
        end
    end

    return false
end

local function getCurrentVehiclePlate(source)
    if not isNearServiceLocation(source) then return end

    local ped = GetPlayerPed(source)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle <= 0 then return end

    return cleanPlate(GetVehicleNumberPlateText(vehicle))
end

local function getVehicle(plate)
    return MySQL.single.await([[
        SELECT plate, is_stolen
        FROM player_vehicles
        WHERE plate = ?
    ]], { plate })
end

lib.callback.register('lvlup:server:checkStolenVehicle', function(source, plate)
    plate = cleanPlate(plate)
    if not plate or plate ~= getCurrentVehiclePlate(source) then return end

    local vehicle = getVehicle(plate)
    if not vehicle then
        return { exists = false, isStolen = 0 }
    end

    return { exists = true, isStolen = tonumber(vehicle.is_stolen) or 0 }
end)

lib.callback.register('lvlup:server:cleanVehicle', function(source, plate)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false, 'no_player' end

    plate = cleanPlate(plate)
    if not plate or plate ~= getCurrentVehiclePlate(source) then return false, 'invalid_vehicle' end

    local vehicle = getVehicle(plate)
    if not vehicle then return false, 'vehicle_not_found' end
    if tonumber(vehicle.is_stolen) ~= 1 then return false, 'not_stolen' end

    local balance = tonumber(exports.ox_inventory:GetItemCount(source, Config.BlackMoneyItem)) or 0
    if balance < Config.CleanPrice then return false, 'not_enough_black_money' end

    local updatedRows = MySQL.update.await([[
        UPDATE player_vehicles
        SET is_stolen = 0
        WHERE plate = ? AND is_stolen = 1
    ]], { plate })

    if (updatedRows or 0) < 1 then return false, 'not_stolen' end

    local removed = exports.ox_inventory:RemoveItem(source, Config.BlackMoneyItem, Config.CleanPrice)
    if removed == true then return true end

    MySQL.update.await('UPDATE player_vehicles SET is_stolen = 1 WHERE plate = ? AND is_stolen = 0', { plate })
    return false, 'not_enough_black_money'
end)
