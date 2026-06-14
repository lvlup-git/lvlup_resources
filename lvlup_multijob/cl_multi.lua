local Config = lib.require('config')
local qbx = exports.qbx_core

local defaultIcon = 'fa-solid fa-briefcase'
local defaultGangIcon = 'fa-solid fa-user-ninja'

local function getGradeData(groupData, grade)
    if not groupData or not groupData.grades then return end
    return groupData.grades[grade] or groupData.grades[tostring(grade)] or groupData.grades[tonumber(grade)]
end

local function sortedKeys(tbl)
    local keys = {}
    for key in pairs(tbl or {}) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

local function ensurePlayerData()
    local playerData = QBX.PlayerData
    if not playerData or not playerData.job or not playerData.gang then
        lib.notify({
            title = 'Job Management',
            description = 'Player data has not loaded yet.',
            type = 'error'
        })
        return nil
    end

    playerData.jobs = playerData.jobs or {}
    playerData.gangs = playerData.gangs or {}
    return playerData
end

local function registerAndShow(context)
    lib.registerContext(context)
    lib.showContext(context.id)
end

local function viewGangs()
    local PlayerData = ensurePlayerData()
    if not PlayerData then return end

    local sharedGangs = qbx:GetGangs() or {}
    local opts = {}
    for _, gang in ipairs(sortedKeys(PlayerData.gangs)) do
        local grade = PlayerData.gangs[gang]
        local data = sharedGangs[gang]
        local gradeData = getGradeData(data, grade)
        if gradeData then
            local isDisabled = PlayerData.gang.name == gang
            opts[#opts + 1] = {
                title = data.label,
                description = ('%s [%s]'):format(gradeData.name, grade),
                icon = Config.GangIcons[gang] or defaultGangIcon,
                arrow = true,
                disabled = isDisabled,
                event = 'randol_multijob:client:choiceMenu',
                args = { gangLabel = data.label, gang = gang, grade = grade },
            }
        end
    end

    registerAndShow({ id = 'gang_menu', menu = 'multi_main', title = 'Current Gang', options = opts })
end

local function viewJobs()
    local PlayerData = ensurePlayerData()
    if not PlayerData then return end

    local sharedJobs = qbx:GetJobs() or {}
    local onDuty = PlayerData.job.onduty
    local jobMenu = {
        id = 'job_menu',
        title = 'Current Employment',
        menu = 'multi_main',
        options = {
            {
                title = 'Duty Status',
                description = ('You are currently %s'):format(onDuty and 'On Duty' or 'Off Duty'),
                icon = onDuty and 'fa-solid fa-toggle-on' or 'fa-solid fa-toggle-off',
                iconColor = onDuty and '#5ff5b4' or 'red',
                onSelect = function()
                    TriggerServerEvent('QBCore:ToggleDuty')
                    Wait(200)
                    viewJobs()
                end
            }
        }
    }
    local seenJobs = {}
    for _, job in ipairs(sortedKeys(PlayerData.jobs)) do
        local grade = PlayerData.jobs[job]
        local data = sharedJobs[job]
        local gradeData = getGradeData(data, grade)
        if gradeData then
            jobMenu.options[#jobMenu.options + 1] = {
                title = data.label,
                description = ('%s [%s]\n$%s per paycheck'):format(gradeData.name, grade, gradeData.payment),
                icon = Config.JobIcons[job] or defaultIcon,
                arrow = true,
                disabled = PlayerData.job.name == job,
                event = 'randol_multijob:client:choiceMenu',
                args = { jobLabel = data.label, job = job, grade = grade },
            }
            seenJobs[job] = true
        end
    end
    if sharedJobs.unemployed and not seenJobs.unemployed then
        local data = sharedJobs.unemployed
        local gradeData = getGradeData(data, 0)
        if gradeData then
            jobMenu.options[#jobMenu.options + 1] = {
                title = data.label,
                description = ('%s [%s]\n$%s per paycheck'):format(gradeData.name, 0, gradeData.payment),
                icon = Config.JobIcons.unemployed or defaultIcon,
                arrow = true,
                disabled = PlayerData.job.name == 'unemployed',
                event = 'randol_multijob:client:choiceMenu',
                args = { jobLabel = data.label, job = 'unemployed', grade = 0 },
            }
        end
    end

    registerAndShow(jobMenu)
end

local function showMainMenu()
    registerAndShow({
        id = 'multi_main',
        title = 'Job Management',
        options = {
            {
                title = 'Current Employment',
                description = 'View and manage your current job(s)',
                icon = 'fa-solid fa-briefcase',
                arrow = true,
                onSelect = viewJobs
            },
            {
                title = 'Gang Affiliations',
                description = 'View and manage your gang involvement',
                icon = 'fa-solid fa-user-ninja',
                arrow = true,
                onSelect = viewGangs
            }
        }
    })
end

AddEventHandler('randol_multijob:client:choiceMenu', function(args)
    local isJob = args.job ~= nil
    local title = isJob and 'Job Actions' or 'Gang Actions'
    local menu = isJob and 'job_menu' or 'gang_menu'
    local options = {
        {
            title = isJob and 'Switch Job' or 'Switch Gang',
            description = isJob and ('Change your employment to %s'):format(args.jobLabel) or ('Change your affiliation to %s'):format(args.gangLabel),
            icon = 'fa-solid fa-circle-check',
            onSelect = function()
                TriggerServerEvent(isJob and 'randol_multijob:server:changeJob' or 'randol_multijob:server:changeGang', isJob and args.job or args.gang)
                Wait(200)
                if isJob then viewJobs() else viewGangs() end
            end
        }
    }
    if isJob then
        if args.job ~= "unemployed" then
            table.insert(options, {
                title = 'Quit Job',
                description = ('Quit your job at %s'):format(args.jobLabel),
                icon = 'fa-solid fa-trash-can',
                onSelect = function()
                    TriggerServerEvent('randol_multijob:server:deleteJob', args.job)
                    Wait(200)
                    viewJobs()
                end
            })
        end
    else
        table.insert(options, {
            title = 'Quit Gang',
            description = ('Leave your homies at %s behind'):format(args.gangLabel),
            icon = 'fa-solid fa-trash-can',
            onSelect = function()
                TriggerServerEvent('randol_multijob:server:deleteGang', args.gang)
                Wait(200)
                viewGangs()
            end
        })
    end
    registerAndShow({ id = 'choice_menu', title = title, menu = menu, options = options })
end)

lib.addKeybind({
    name = 'multi',
    description = 'Job/Gang Management',
    defaultKey = 'J',
    onPressed = showMainMenu
})
