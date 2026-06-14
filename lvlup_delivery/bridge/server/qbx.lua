if GetResourceState('qbx_core') ~= 'started' then return end

function GetPlayer(id) return exports.qbx_core:GetPlayer(id) end
function DoNotification(src, text, nType) exports.qbx_core:Notify(src, text, nType) end

local tipChance = 35
local tipMin = 1
local tipMax = 100
function AddMoney(Player, amount, paycheckLabel)
    paycheckLabel = paycheckLabel or 'Delivery'

    if math.random(100) <= tipChance then
        local tip = math.random(tipMin, tipMax)
        local total = amount + tip
        exports.randol_paycheck:AddToPaycheck(Player.PlayerData.citizenid, total, paycheckLabel)
        DoNotification(Player.PlayerData.source, ("You received $%s (including a $%s tip)"):format(total, tip), "success" )
    else
        exports.randol_paycheck:AddToPaycheck(Player.PlayerData.citizenid, amount, paycheckLabel)
        DoNotification(Player.PlayerData.source, ("You received $%s"):format(amount), "success" )
    end
end

RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(source) ServerOnLogout(source) end)
