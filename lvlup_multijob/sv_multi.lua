local Config = lib.require('config')

local function canSetJob(player, jobName)
    if jobName == "unemployed" then return true end
    local jobs = player.PlayerData.jobs or {}
    return jobs[jobName] ~= nil
end

local function hasJob(player, jobName)
    local jobs = player.PlayerData.jobs or {}
    return player.PlayerData.job.name == jobName or jobs[jobName] ~= nil
end

local function canSetGang(player, gangName)
    local gangs = player.PlayerData.gangs or {}
    return gangs[gangName] ~= nil
end

local function hasGang(player, gangName)
    local gangs = player.PlayerData.gangs or {}
    return player.PlayerData.gang.name == gangName or gangs[gangName] ~= nil
end

local function getPlayer(src)
    local player = qbx:GetPlayer(src)
    if not player then
        lib.print.warn(('randol_multijob: Failed to find player for source %s'):format(src))
    end
    return player
end

RegisterNetEvent('randol_multijob:server:changeJob', function(job)
    local src = source
    if type(job) ~= 'string' or job == '' then return end

    local player = getPlayer(src)
    if not player or not player.PlayerData.job then return end

    if player.PlayerData.job.name == job then
        qbx:Notify(src, "You're already employed here", 'error')
        return
    end

    local jobInfo = qbx:GetJob(job)
    if not jobInfo then
        qbx:Notify(src, 'Invalid job.', 'error')
        return
    end

    if not canSetJob(player, job) then
        qbx:Notify(src, "You don't have access to this job", 'error')
        return
    end

    qbx:SetPlayerPrimaryJob(player.PlayerData.citizenid, job)
    qbx:Notify(src, ("You're hired at %s"):format(jobInfo.label))
    if player.Functions and player.Functions.SetJobDuty then
        player.Functions.SetJobDuty(false)
    end
end)

RegisterNetEvent('randol_multijob:server:changeGang', function(gang)
    local src = source
    if type(gang) ~= 'string' or gang == '' then return end

    local player = getPlayer(src)
    if not player or not player.PlayerData.gang then return end

    if player.PlayerData.gang.name == gang then
        qbx:Notify(src, "You're already a part of this gang", 'error')
        return
    end

    local gangInfo = qbx:GetGang(gang)
    if not gangInfo then
        qbx:Notify(src, 'Invalid gang.', 'error')
        return
    end

    if not canSetGang(player, gang) then
        qbx:Notify(src, "You don't have access to this gang", 'error')
        return
    end

    qbx:SetPlayerPrimaryGang(player.PlayerData.citizenid, gang)
    qbx:Notify(src, ("You're now a part of %s"):format(gangInfo.label))
end)

RegisterNetEvent('randol_multijob:server:deleteJob', function(job)
    local src = source
    if type(job) ~= 'string' or job == '' then return end

    local player = getPlayer(src)
    if not player or not player.PlayerData.job then return end

    local jobInfo = qbx:GetJob(job)

    if not jobInfo then
        qbx:Notify(src, 'Invalid job.', 'error')
        return
    end

    if not hasJob(player, job) then
        qbx:Notify(src, "You don't currently work here", 'error')
        return
    end

    qbx:RemovePlayerFromJob(player.PlayerData.citizenid, job)
    qbx:Notify(src, ("You quit %s"):format(jobInfo.label))
end)

RegisterNetEvent('randol_multijob:server:deleteGang', function(gang)
    local src = source
    if type(gang) ~= 'string' or gang == '' then return end

    local player = getPlayer(src)
    if not player or not player.PlayerData.gang then return end

    local gangInfo = qbx:GetGang(gang)

    if not gangInfo then
        qbx:Notify(src, 'Invalid gang.', 'error')
        return
    end

    if not hasGang(player, gang) then
        qbx:Notify(src, "You're not a part of this gang", 'error')
        return
    end

    qbx:RemovePlayerFromGang(player.PlayerData.citizenid, gang)
    qbx:Notify(src, ("You left %s"):format(gangInfo.label))
end)
