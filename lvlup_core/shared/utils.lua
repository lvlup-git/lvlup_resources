local NumberCharset = {}
local LetterCharset = {}

for i = 48, 57 do NumberCharset[#NumberCharset + 1] = string.char(i) end -- '0'-'9'
for i = 65, 90 do LetterCharset[#LetterCharset + 1] = string.char(i) end -- 'A'-'Z'
for i = 97, 122 do LetterCharset[#LetterCharset + 1] = string.char(i) end -- 'a'-'z'

math.randomseed(GetGameTimer())

local function generateRandomNumber(length)
    local t = {}
    for i = 1, length do
        t[i] = NumberCharset[math.random(#NumberCharset)]
    end
    return table.concat(t)
end
exports('generateRandomNumber', generateRandomNumber)

local function generateRandomLetter(length)
    local t = {}
    for i = 1, length do
        t[i] = LetterCharset[math.random(#LetterCharset)]
    end
    return table.concat(t)
end
exports('generateRandomLetter', generateRandomLetter)

local function generateGTAPlate()
    return generateRandomNumber(2) .. generateRandomLetter(3) .. generateRandomNumber(2)
end
exports('generateGTAPlate', generateGTAPlate)

local function generatePlatePrefix(prefix)
    prefix = (prefix or ""):upper():sub(1, 8)
    local remaining = 8 - #prefix
    if remaining <= 0 then return prefix end
    local min = 10 ^ (remaining - 1)
    local max = (10 ^ remaining) - 1
    return prefix .. tostring(math.random(min, max))
end
exports('generatePlatePrefix', generatePlatePrefix)
