local function ensurePaycheckRow(cid)
    if not cid then return end

    local result = MySQL.single.await('SELECT amount FROM paychecks WHERE citizenid = ?', { cid })
    if not result then
        MySQL.insert.await('INSERT INTO paychecks (citizenid, amount) VALUES (?, ?)', { cid, 0 })
        return { amount = 0 }
    end

    result.amount = tonumber(result.amount) or 0
    return result
end

local function AddToPaycheck(cid, amount)
    local deposit = tonumber(amount)
    if not cid or not deposit or deposit <= 0 then return end

    MySQL.update.await(
        [[INSERT INTO paychecks (citizenid, amount) VALUES (?, ?) ON DUPLICATE KEY UPDATE amount = amount + ?]],
        { cid, deposit, deposit }
    )

    local result = ensurePaycheckRow(cid)
    if not result then return end

    local src = GetSourceFromIdentifier(cid)
    if src then
        DoNotification(
            src,
            ('Your paycheck of $%s was deposited, bringing your total to $%s'):format(deposit, result.amount),
            'New Deposit'
        )
    end
end
exports('AddToPaycheck', AddToPaycheck)

lib.callback.register('randol_paycheck:server:withdraw', function(source, amount, accountType)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return false end

    local withdrawAmount = math.floor(tonumber(amount) or 0)
    if withdrawAmount <= 0 then
        DoNotification(src, 'Invalid withdraw amount.', 'Transaction Error')
        return false
    end

    local cid = GetPlyIdentifier(Player)
    local paycheck = ensurePaycheckRow(cid)
    if not paycheck or paycheck.amount < withdrawAmount then
        DoNotification(src, 'Insufficient funds in your paycheck.', 'Transaction Error')
        return false
    end

    local newAmount = paycheck.amount - withdrawAmount
    MySQL.update.await('UPDATE paychecks SET amount = ? WHERE citizenid = ?', { newAmount, cid })

    local moneyType = accountType == 'cash' and 'cash' or 'bank'
    AddMoney(Player, moneyType, withdrawAmount)

    if moneyType == 'cash' then
        DoNotification(src, ('You withdrew $%s from your paycheck.'):format(withdrawAmount), 'New Withdraw')
    else
        DoNotification(src, ('You deposited $%s from your paycheck into your bank account.'):format(withdrawAmount), 'New Withdraw')
    end

    return true
end)

lib.callback.register('randol_paycheck:server:checkPaycheck', function(source)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return 0 end

    local cid = GetPlyIdentifier(Player)
    local result = ensurePaycheckRow(cid)
    return result and result.amount or 0
end)

AddEventHandler('onServerResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        MySQL.query([=[CREATE TABLE IF NOT EXISTS paychecks (
            citizenid varchar(100) NOT NULL,
            amount varchar(50) DEFAULT NULL,
            PRIMARY KEY (citizenid)
        );]=])
    end
end)
