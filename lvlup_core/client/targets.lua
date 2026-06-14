local DEFAULT_DISABLE = {move = false, car = false, combat = false, mouse = false, sprint = false}
local targetZones = {}
local targetModels = {}

local function handleProgress(progress)
    if not progress then return true end
    local config = {duration = progress.duration or 5000, label = progress.label or 'Processing...', useWhileDead = false, canCancel = progress.canCancel ~= false, disable = progress.disable or DEFAULT_DISABLE}
    if progress.style == 'circle' then
        config.position = 'bottom'
        return lib.progressCircle(config)
    end
    return lib.progressBar(config)
end

local function handleAction(action)
    local ped = cache.ped
    if not ped then return end
    if action.emote then exports['rpemotes-reborn']:EmoteCommandStart(action.emote) end
    local completed = handleProgress(action.progress)
    if action.emote and (action.cancelEarly or not completed) then exports['rpemotes-reborn']:EmoteCancel() end
    if not completed then return end
    if action.type == 'event' and action.event then TriggerEvent(action.event) end
end

local function buildOptions(actions)
    local options = {}
    for i = 1, #actions do
        local action = actions[i]
        options[#options + 1] = {name = action.name, label = action.label, icon = action.icon, onSelect = function() handleAction(action) end}
    end
    return options
end

local function getOptionNames(options)
    local names = {}
    for i = 1, #options do
        names[#names + 1] = options[i].name
    end
    return names
end

CreateThread(function()
    for _, zone in pairs(lvlup_config_target.Zones) do
        local options = buildOptions(zone.actions)
        local optionNames = getOptionNames(options)
        if zone.coords and zone.radius then
            for _, coord in ipairs(zone.coords) do
                targetZones[#targetZones + 1] = exports.ox_target:addSphereZone({coords = coord, radius = zone.radius, options = options})
            end
        end
        if zone.models then
            exports.ox_target:addModel(zone.models, options)
            targetModels[#targetModels + 1] = {models = zone.models, optionNames = optionNames}
        end
        if zone.modelHashes then
            exports.ox_target:addModel(zone.modelHashes, options)
            targetModels[#targetModels + 1] = {models = zone.modelHashes, optionNames = optionNames}
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for i = 1, #targetZones do
        exports.ox_target:removeZone(targetZones[i])
    end
    for i = 1, #targetModels do
        exports.ox_target:removeModel(targetModels[i].models, targetModels[i].optionNames)
    end
end)
