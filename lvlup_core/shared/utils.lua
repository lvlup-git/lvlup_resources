-- Initialize character sets once
local NumberCharset = {}
local Charset = {}

for i = 48, 57 do table.insert(NumberCharset, string.char(i)) end -- '0'-'9'
for i = 65, 90 do table.insert(Charset, string.char(i)) end -- 'A'-'Z'
for i = 97, 122 do table.insert(Charset, string.char(i)) end -- 'a'-'z'

-- Seed random once at resource start
math.randomseed(GetGameTimer())

-- Generate random numeric string of given length
local function generateRandomNumber(length)
    local result = {}
    for _ = 1, length do table.insert(result, NumberCharset[math.random(#NumberCharset)]) end
    return table.concat(result)
end
exports('generateRandomNumber', generateRandomNumber)

-- Generate random alphabetic string of given length (upper and lower case)
local function generateRandomLetter(length)
    local result = {}
    for _ = 1, length do table.insert(result, Charset[math.random(#Charset)]) end
    return table.concat(result)
end
exports('generateRandomLetter', generateRandomLetter)

-- Generate a plate based off standard GTA plates (00AAA000)
local function generateGTAPlate()
    return generateRandomNumber(2) .. generateRandomLetter(3) .. generateRandomNumber(2)
end
exports('generateGTAPlate', generateGTAPlate)

-- Generate plate with auto-adjusting numbers depending on prefix chosen
local function generatePlatePrefix(prefix)
    prefix = (prefix or ""):upper():sub(1, 8)
    local remaining = 8 - #prefix
    if remaining <= 0 then return prefix end
    local number = tostring(math.random(10 ^ (remaining - 1), (10 ^ remaining) - 1))
    return (prefix .. number):upper()
end
exports('generatePlatePrefix', generatePlatePrefix)

local function spawnPed(model, coords, heading, targetOptions)
    if not model or not coords then
        print("^1[Error]^7 Missing required parameters for spawnPed (model, coords)")
        return nil
    end

    lib.requestModel(model)
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z - 1.0, heading or 0.0, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetModelAsNoLongerNeeded(model)

    if targetOptions and type(targetOptions) == "table" then
        local success, err = pcall(function() exports.ox_target:addLocalEntity(ped, targetOptions) end)
        if not success then print(("^1[Error]^7 Failed to register target for ped: %s"):format(err)) end
    end

    return ped
end
exports('spawnPed', spawnPed)

local function deletePed(ped)
    if not ped or not DoesEntityExist(ped) then
        print("^1[Error]^7 Invalid ped passed to deletePed")
        return false
    end

    local success, err = pcall(function() exports.ox_target:removeLocalEntity(ped) end)
    if not success then print(("^1[Warning]^7 Failed to remove ox_target from ped: %s"):format(err)) end

    DeleteEntity(ped)
    return true
end
exports('deletePed', deletePed)
