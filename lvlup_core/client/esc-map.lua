local isAnimating = false
local pauseMenuOpen = false

local function stopAnimation()
    if not isAnimating then return end

    ClearPedTasks(PlayerPedId())
    ExecuteCommand('e c')
    isAnimating = false
end

local function startMapAnimation()
    if isAnimating then return end

    ExecuteCommand('e map2')
    isAnimating = true
end

CreateThread(function()
    while true do
        local paused = IsPauseMenuActive()

        if paused ~= pauseMenuOpen then
            pauseMenuOpen = paused

            if paused then
                startMapAnimation()
            else
                stopAnimation()
            end
        end

        Wait(250)
    end
end)

AddEventHandler('gameEventTriggered', function(event, data)
    if event == 'CEventDeath' and isAnimating then
        stopAnimation()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isAnimating then
        stopAnimation()
    end
end)
