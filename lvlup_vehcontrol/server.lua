local function registerToggleEvent(eventBaseName)
    RegisterServerEvent(eventBaseName .. "_s")
    AddEventHandler(eventBaseName .. "_s", function(param) TriggerClientEvent(eventBaseName .. "_c", -1, source, param) end)
end

registerToggleEvent("TogDfltSrnMuted")
registerToggleEvent("SetLxSirenState")
registerToggleEvent("TogPwrcallState")
registerToggleEvent("SetAirManuState")
registerToggleEvent("TogIndicState")