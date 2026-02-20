--[[ HOW-TO:
    exports['meh-core']:SendToDiscord(hook, '', , '', , '', '')
    example: exports['meh-core']:SendToDiscord('https://discord.com/api/webhooks/...', 'Alert Bot', 'https://i.imgur.com/avatar.png', 16711680, 'Server Alert', 'A player has joined the server.', 'FiveM Logs')
    use this to get decimal color: https://www.mathsisfun.com/hexadecimal-decimal-colors.html
]]
function SendToDiscord(webhook, username, avatarUrl, color, title, message)
    local embed = {{title = '**' .. title .. '**', description = message, color = color}}
    local payload = {username = username, avatar_url = avatarUrl, embeds = embed}
    PerformHttpRequest(webhook, function() end, 'POST', json.encode(payload), {['Content-Type'] = 'application/json'})
end
exports('SendToDiscord', SendToDiscord)
