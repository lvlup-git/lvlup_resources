RegisterCommand('raycast', function(source, args, rawCommand)
    TriggerClientEvent('lvlup:client:toggle', source)
end, false)