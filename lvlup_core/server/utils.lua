local MAX_FIELD_LENGTH = 4000

local function normalizeText(value)
    value = tostring(value or ''):gsub('[%c]', ' ')
    return value:sub(1, MAX_FIELD_LENGTH)
end

local function SendToDiscord(webhook, username, avatarUrl, color, title, message)
    if type(webhook) ~= 'string' or not webhook:match('^https://') then return false end

    local embed = {{
        title = ('**%s**'):format(normalizeText(title)),
        description = normalizeText(message),
        color = tonumber(color) or 0
    }}
    local payload = {
        username = normalizeText(username):sub(1, 80),
        avatar_url = type(avatarUrl) == 'string' and avatarUrl or '',
        embeds = embed,
        allowed_mentions = {parse = {}}
    }

    PerformHttpRequest(webhook, function() end, 'POST', json.encode(payload), {['Content-Type'] = 'application/json'})
    return true
end

exports('SendToDiscord', SendToDiscord)
