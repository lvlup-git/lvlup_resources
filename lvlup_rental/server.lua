local QBCore = exports['qb-core']:GetCoreObject()

MySQL.ready(function()
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS vehicle_rentals (
            plate VARCHAR(8) NOT NULL PRIMARY KEY,
            owner VARCHAR(64) NOT NULL,
            model VARCHAR(50) NOT NULL,
            price INT NOT NULL,
            rented_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]], {})

    if Config.ClearRentalsOnRestart then
        MySQL.Sync.execute('DELETE FROM vehicle_rentals', {})
    end
end)

local function getPlayerId(source)
    local Player = QBCore.Functions.GetPlayer(source)
    return Player and Player.PlayerData.citizenid or nil
end

lib.callback.register('lvlup:server:hasRental', function(source)
    local ownerId = getPlayerId(source)
    if not ownerId then return false end
    local result = MySQL.Sync.fetchScalar([[
        SELECT COUNT(*) FROM vehicle_rentals WHERE owner = @owner
    ]], { ['@owner'] = ownerId })
    return result > 0
end)

lib.callback.register('lvlup:server:rent', function(source, plate, model, price, label)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false, 'no_player' end

    local ownerId = getPlayerId(source)
    if not ownerId then return false, 'no_owner' end

    local hasRental = MySQL.Sync.fetchScalar([[
        SELECT COUNT(*) FROM vehicle_rentals WHERE owner = @owner
    ]], { ['@owner'] = ownerId })
    if hasRental > 0 then return false, 'already_has_rental' end

    local removed = Player.Functions.RemoveMoney('bank', price)
    if not removed then return false, 'not_enough_cash' end

    MySQL.Async.execute([[
        INSERT INTO vehicle_rentals (plate, owner, model, price)
        VALUES (@plate, @owner, @model, @price)
    ]], {
        ['@plate'] = plate,
        ['@owner'] = ownerId,
        ['@model'] = model,
        ['@price'] = price
    })

    local charinfo = Player.PlayerData.charinfo
    local fullName = (charinfo.firstname .. ' ' .. charinfo.lastname)
    exports.ox_inventory:AddItem(source, 'rental_papers', 1, {
        renterName = fullName,
        vehPlate = plate,
        vehModel = model
    })

    return true
end)

lib.callback.register('lvlup:server:getRental', function(source, plate)
    local ownerId = getPlayerId(source)
    if not ownerId then return nil end

    local result = MySQL.Sync.fetchAll([[
        SELECT price FROM vehicle_rentals
        WHERE plate = @plate AND owner = @owner
    ]], {
        ['@plate'] = plate,
        ['@owner'] = ownerId
    })
    if result and result[1] then return { price = result[1].price } end

    return nil
end)

RegisterNetEvent('lvlup:server:return', function(plate, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local ownerId = getPlayerId(src)
    if not ownerId then return end

    local result = MySQL.query.await([[
        SELECT * FROM vehicle_rentals WHERE plate = ? AND owner = ?
    ]], { plate, ownerId })
    if not result or not result[1] then return end

    local items = exports.ox_inventory:GetInventoryItems(src)
    for _, item in pairs(items) do
        if item.name == 'rental_papers' then
            exports.ox_inventory:RemoveItem(src, 'rental_papers', 1, nil, item.slot)
            break
        end
    end

    Player.Functions.AddMoney('bank', amount, 'rental-refund')

    MySQL.update.await([[
        DELETE FROM vehicle_rentals WHERE plate = ?
    ]], { plate })
end)
