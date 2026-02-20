local Config = lib.require('config')

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

    -- Multi-job resources can sometimes leave the table nil until the player joins
    playerData.jobs = playerData.jobs or {}
    playerData.gangs = playerData.gangs or {}
    return playerData
end

local function viewGangs()
    local PlayerData = ensurePlayerData()
    if not PlayerData then return end

    local sharedGangs = qbx:GetGangs()
    local opts = {}
    for gang, grade in pairs(PlayerData.gangs) do
        local data = sharedGangs[gang]
        if data and data.grades and data.grades[grade] then
            local isDisabled = PlayerData.gang.name == gang
            opts[#opts + 1] = {
                title = data.label,
                description = ('%s [%s]'):format(data.grades[grade].name, grade),
                icon = Config.GangIcons[gang] or 'fa-solid fa-user-ninja',
                arrow = true,
                disabled = isDisabled,
                event = 'randol_multijob:client:choiceMenu',
                args = {gangLabel = data.label, gang = gang, grade = grade},
            }
        end
    end
    lib.registerContext({id = 'gang_menu', menu = 'multi_main', title = 'Current Gang', options = opts})
    lib.showContext('gang_menu')
end

local function viewJobs()
    local PlayerData = ensurePlayerData()
    if not PlayerData then return end

    local sharedJobs = qbx:GetJobs()
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
    for job, grade in pairs(PlayerData.jobs) do
        local data = sharedJobs[job]
        local gradeData = data and data.grades and data.grades[grade]
        if gradeData then
            jobMenu.options[#jobMenu.options + 1] = {
                title = data.label,
                description = ('%s [%s]\n$%s per paycheck'):format(gradeData.name, grade, gradeData.payment),
                icon = Config.JobIcons[job] or 'fa-solid fa-briefcase',
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
        local gradeData = data.grades and data.grades[0]
        if gradeData then
            jobMenu.options[#jobMenu.options + 1] = {
                title = data.label,
                description = ('%s [%s]\n$%s per paycheck'):format(gradeData.name, 0, gradeData.payment),
                icon = Config.JobIcons.unemployed or 'fa-solid fa-user-slash',
                arrow = true,
                disabled = PlayerData.job.name == 'unemployed',
                event = 'randol_multijob:client:choiceMenu',
                args = { jobLabel = data.label, job = 'unemployed', grade = 0 },
            }
        end
    end
    lib.registerContext(jobMenu)
    lib.showContext('job_menu')
end

local function showMainMenu()
    lib.registerContext({
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
    lib.showContext('multi_main')
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
    lib.registerContext({id = 'choice_menu', title = title, menu = menu, options = options})
    lib.showContext('choice_menu')
end)

lib.addKeybind({name = 'multi', description = 'Job/Gang Management', defaultKey = 'J', onPressed = function(self) showMainMenu() end})
