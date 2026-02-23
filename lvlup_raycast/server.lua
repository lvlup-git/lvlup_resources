RegisterCommand('raycast', function(source, args, rawCommand)
    TriggerClientEvent('raycast:client:toggle', source)
end, false)