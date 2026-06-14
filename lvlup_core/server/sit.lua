local seatsTaken = {}
local playerSeats = {}

local function normalizeSeatId(seatId)
    if type(seatId) ~= 'string' and type(seatId) ~= 'number' then return end

    seatId = tostring(seatId)
    if seatId == '' or #seatId > 64 then return end

    return seatId
end

local function releaseSeat(source)
    local seatId = playerSeats[source]
    if not seatId then return end

    if seatsTaken[seatId] == source then
        seatsTaken[seatId] = nil
    end
    playerSeats[source] = nil
end

lib.callback.register('lvlup:getSeatState', function(_, seatId)
    seatId = normalizeSeatId(seatId)
    return seatId and seatsTaken[seatId] or nil
end)

RegisterNetEvent('lvlup:takeSeat', function(seatId)
    seatId = normalizeSeatId(seatId)
    if not seatId then return end

    local owner = seatsTaken[seatId]
    if owner and owner ~= source then return end

    releaseSeat(source)
    seatsTaken[seatId] = source
    playerSeats[source] = seatId
end)

RegisterNetEvent('lvlup:leaveSeat', function(seatId)
    seatId = normalizeSeatId(seatId)
    if not seatId or seatsTaken[seatId] ~= source then return end

    releaseSeat(source)
end)

AddEventHandler('playerDropped', function()
    releaseSeat(source)
end)
