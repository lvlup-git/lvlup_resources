local cam = nil
local isPreloading = false
local PreloadLocations = Config.PreloadLocations

local function createCam(location, shouldActivate)
    if not cam then
        cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    end

    SetCamCoord(cam, location.pos.x, location.pos.y, location.pos.z)
    PointCamAtCoord(cam, location.lookAt.x, location.lookAt.y, location.lookAt.z + 1.0)

    if shouldActivate then
        SetCamActive(cam, true)
        RenderScriptCams(true, true, 1500, true, true)
    end
end

local function cleanup(ped, originalCoords, originalHeading)
    SetEntityCoords(ped, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, true)
    SetEntityHeading(ped, originalHeading)
    SetEntityVisible(ped, true)
    FreezeEntityPosition(ped, false)

    RenderScriptCams(false, true, 3000, true, true)
    if cam then
        DestroyCam(cam, true)
        cam = nil
    end
end

local function PreloadAreas()
    if isPreloading then
        lib.notify({ description = 'A preload run is already in progress.', type = 'info' })
        return
    end

    isPreloading = true
    local ped = cache.ped
    local originalCoords = GetEntityCoords(ped)
    local originalHeading = GetEntityHeading(ped)

    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false)

    local freezing = true

    CreateThread(function()
        while freezing do
            Wait(0)
            if cam then
                local camCoords = GetCamCoord(cam)
                SetEntityCoordsNoOffset(ped, camCoords.x, camCoords.y, camCoords.z - 10.0, false, false, false)
                SetEntityHeading(ped, originalHeading)
                if IsPedRagdoll(ped) or IsPedFalling(ped) then ClearPedTasksImmediately(ped) end
            end
        end
    end)

    local firstCam = true
    for _, loc in ipairs(PreloadLocations) do
        createCam(loc, firstCam)
        firstCam = false
        Wait(Config.WaitTime)
    end

    freezing = false
    cleanup(ped, originalCoords, originalHeading)
    isPreloading = false
end

RegisterCommand('preload', function()
    local confirm = lib.alertDialog({
        header = 'Preload',
        content = 'Starting preload will set you invisible and teleport you to multiple locations to download items in the area (makes it easier to drive through highly conjested areas) Once it\'s finished, you will be brought right back here.',
        centered = true,
        cancel = true
    })

    if confirm == 'confirm' then PreloadAreas() end
end, false)
