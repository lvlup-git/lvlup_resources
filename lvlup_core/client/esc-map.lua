local preventPropSpaz = false
local isAnimating = false

local function clearAnimation()
    ClearPedTasks(PlayerPedId())
    ExecuteCommand('e c')
    isAnimating = false
end

local function startAnimation()
    if not preventPropSpaz then
        ExecuteCommand('e map2')
        isAnimating = true
        preventPropSpaz = true
    end
end

CreateThread(function()
    while true do
        if IsPauseMenuActive() then
            startAnimation()
            Wait(1)
        else
            if isAnimating then clearAnimation() end
            preventPropSpaz = false
            Wait(1000)
        end
    end
end)
