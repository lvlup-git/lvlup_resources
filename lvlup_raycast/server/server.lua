RegisterCommand('raycast', function(source, args, rawCommand)
    TriggerClientEvent('v-raycast:client:toggle', source)
end, false)