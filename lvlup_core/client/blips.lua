local QBCore = exports['qb-core']:GetCoreObject()

local AddBlipForCoord = AddBlipForCoord
local RemoveBlip = RemoveBlip
local SetBlipSprite = SetBlipSprite
local SetBlipDisplay = SetBlipDisplay
local SetBlipColour = SetBlipColour
local SetBlipScale = SetBlipScale
local SetBlipAsShortRange = SetBlipAsShortRange
local BeginTextCommandSetBlipName = BeginTextCommandSetBlipName
local AddTextComponentString = AddTextComponentString
local EndTextCommandSetBlipName = EndTextCommandSetBlipName
local Wait = Wait

local Blips = {
    {
        title = 'Bus station',
        sprite = 513,
        coords = { vec2(450.05, -650.92) },
        jobs = { 'bus' }
    },

    -- Development / hidden blip
    {
        title = 'z',
        sprite = 37, scale = 0.0,
        coords = { vec2(5771.59, -6211.9) }
    }
}

local ActiveBlips = {}

local function RemoveAllBlips()
    for i = 1, #ActiveBlips do
        if DoesBlipExist(ActiveBlips[i]) then
            RemoveBlip(ActiveBlips[i])
        end
    end
    ActiveBlips = {}
end

local function HasJobAccess(playerJob, allowedJobs)
    if not allowedJobs then return true end
    for i = 1, #allowedJobs do
        if allowedJobs[i] == playerJob then return true end
    end
    return false
end

local function CreateBlipsForJob(jobName)
    if not jobName then return end

    RemoveAllBlips()

    for i = 1, #Blips do
        local data = Blips[i]
        if HasJobAccess(jobName, data.jobs) then
            for c = 1, #data.coords do
                local coord = data.coords[c]
                local blip = AddBlipForCoord(coord.x, coord.y, 0.0)

                SetBlipSprite(blip, data.sprite or 66)
                SetBlipDisplay(blip, data.display or 2)
                SetBlipColour(blip, data.colour or 0)
                SetBlipScale(blip, data.scale or 0.7)
                SetBlipAsShortRange(blip, data.shortRange ~= false)

                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString(data.title or 'Unnamed Blip')
                EndTextCommandSetBlipName(blip)

                ActiveBlips[#ActiveBlips + 1] = blip
            end
        end
    end
end

CreateThread(function()
    local playerData
    repeat
        playerData = QBCore.Functions.GetPlayerData()
        Wait(200)
    until playerData and playerData.job and playerData.job.name

    CreateBlipsForJob(playerData.job.name)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    if job and job.name then
        CreateBlipsForJob(job.name)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        RemoveAllBlips()
    end
end)
