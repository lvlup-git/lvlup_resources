local activeScenes = {}

local function ensureAudioSceneActive(name)
    if not activeScenes[name] and not IsAudioSceneActive(name) then
        StartAudioScene(name)
        activeScenes[name] = true
    end
end

local function InitWorldSettings()
    SetAudioFlag("DisableFlightMusic", true)
    SetAudioFlag("PoliceScannerDisabled", true)

    SetFlashLightKeepOnWhileMoving(true)
    DisableIdleCamera(true)
    DisableVehiclePassengerIdleCamera(true)

    NetworkSetLocalPlayerSyncLookAt(true)
    SetRandomEventFlag(false)
    SetMaxWantedLevel(0)
    DistantCopCarSirens(false)
    -- OverrideReactionToVehicleSiren(true, 1)

    SetGlobalPassengerMassMultiplier(0.0)

    ensureAudioSceneActive("CHARACTER_CHANGE_IN_SKY_SCENE")
    ensureAudioSceneActive("DLC_MPHEIST_TRANSITION_TO_APT_FADE_IN_RADIO_SCENE")
    ensureAudioSceneActive("FBI_HEIST_H5_MUTE_AMBIENCE_SCENE")
end

CreateThread(function()
    InitWorldSettings()

    for _, track in ipairs({ 0, 3 }) do
        SwitchTrainTrack(track, true)
        SetTrainTrackSpawnFrequency(track, 120000)
    end
    SetRandomTrains(true)

    local disabledScenarios = {
        "WORLD_VEHICLE_BIKE_OFF_ROAD_RACE",
        "WORLD_VEHICLE_BUSINESSMEN",
        "WORLD_VEHICLE_EMPTY",
        "WORLD_VEHICLE_MECHANIC",
        "WORLD_VEHICLE_MILITARY_PLANES_BIG",
        "WORLD_VEHICLE_MILITARY_PLANES_SMALL",
        "WORLD_VEHICLE_POLICE_BIKE",
        "WORLD_VEHICLE_POLICE_CAR",
        "WORLD_VEHICLE_POLICE_NEXT_TO_CAR",
        "WORLD_VEHICLE_SALTON_DIRT_BIKE",
        "WORLD_VEHICLE_SALTON",
        "WORLD_VEHICLE_STREETRACE"
    }

    local disabledEmitters = {
        "LOS_SANTOS_VANILLA_UNICORN_01_STAGE",
        "LOS_SANTOS_VANILLA_UNICORN_02_MAIN_ROOM",
        "LOS_SANTOS_VANILLA_UNICORN_03_BACK_ROOM",
        "se_dlc_aw_arena_construction_01",
        "se_dlc_aw_arena_crowd_background_main",
        "se_dlc_aw_arena_crowd_exterior_lobby",
        "se_dlc_aw_arena_crowd_interior_lobby"
    }

    for i = 1, #disabledScenarios do
        SetScenarioTypeEnabled(disabledScenarios[i], false)
    end

    for i = 1, #disabledEmitters do
        SetStaticEmitterEnabled(disabledEmitters[i], false)
    end
end)

CreateThread(function()
    local lastSuppression = 0

    while true do
        local waitTime = 750
        local ped = PlayerPedId()

        if GetGameTimer() - lastSuppression > 10000 then
            DisablePlayerVehicleRewards(ped)

            ensureAudioSceneActive("CHARACTER_CHANGE_IN_SKY_SCENE")
            ensureAudioSceneActive("DLC_MPHEIST_TRANSITION_TO_APT_FADE_IN_RADIO_SCENE")
            ensureAudioSceneActive("FBI_HEIST_H5_MUTE_AMBIENCE_SCENE")

            lastSuppression = GetGameTimer()
        end

        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            local class = GetVehicleClass(vehicle)

            if (
                class <= 7 or
                class == 9 or
                class == 10 or
                class == 11 or
                class == 12 or
                class == 17 or
                class == 18
            ) then
                if IsEntityInAir(vehicle) or IsEntityUpsidedown(vehicle) then
                    DisableControlAction(2, 59, true) -- Move left/right
                    DisableControlAction(2, 60, true) -- Move up/down
                    waitTime = 0
                end
            end
        end

        Wait(waitTime)
    end
end)

lib.onCache('ped', function(ped)
    if not ped then return end

    SetPedResetFlag(ped, 200, true) -- Disable combat locomotion
    SetPedResetFlag(ped, 337, true) -- Disable combat rolls

    SetPedConfigFlag(ped, 35,  false) -- Disable gesture animations
    SetPedConfigFlag(ped, 184, true)  -- Disable cover usage
    SetPedConfigFlag(ped, 78,  true)  -- Disable evasive dive
    SetPedConfigFlag(ped, 185, true)  -- Disable melee events
    SetPedConfigFlag(ped, 293, true)  -- Disable jumping out of vehicles
    SetPedConfigFlag(ped, 188, true)  -- Disable crouch aiming
    SetPedConfigFlag(ped, 32,  false) -- Allow ragdoll
    SetPedConfigFlag(ped, 142, true)  -- Disable ambient melee reactions
    SetPedConfigFlag(ped, 26,  false) -- Allow head tracking
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()

        if IsPedInCover(ped) and not IsPedAimingFromCover(ped) then
            DisableControlAction(2, 24, true)
            DisableControlAction(2, 142, true)
            DisableControlAction(2, 257, true)
            Wait(0)
        else
            Wait(750)
        end
    end
end)

RegisterCommand("propstuck", function()
    local ped = PlayerPedId()
    local pool = GetGamePool("CObject")

    for i = 1, #pool do
        local obj = pool[i]
        if IsEntityAttachedToEntity(ped, obj) then
            SetEntityAsMissionEntity(obj, true, true)
            DeleteObject(obj)
        end
    end

    lib.notify({
        title = 'Props',
        description = 'Stuck props cleared!',
        type = 'success'
    })
end, false)

RegisterCommand("record", function(_, args)
    local action = args[1]

    if action == "start" then
        StartRecording(1)
    elseif action == "stop" then
        StopRecordingAndSaveClip()
    elseif action == "discard" then
        StopRecordingAndDiscardClip()
    end
end, false)

RegisterCommand("rockstareditor", ActivateRockstarEditor, false)

RegisterCommand("picture", function()
    BeginTakeHighQualityPhoto()
    SaveHighQualityPhoto(-1)
    FreeMemoryForHighQualityPhoto()
end, false)

RegisterKeyMapping("record start", "(Rockstar Editor) Start Recording", "keyboard", "")
RegisterKeyMapping("record stop", "(Rockstar Editor) Stop Recording", "keyboard", "")
RegisterKeyMapping("record discard", "(Rockstar Editor) Discard Recording", "keyboard", "")
RegisterKeyMapping("picture", "(Rockstar Editor) Take a Picture", "keyboard", "")

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for name in pairs(activeScenes) do
        if IsAudioSceneActive(name) then
            StopAudioScene(name)
        end
    end

    activeScenes = {}
end)
