SetFlashLightKeepOnWhileMoving(true)
DisableIdleCamera(true)
DisableVehiclePassengerIdleCamera(true)
NetworkSetLocalPlayerSyncLookAt(true)
-- SetWeaponDamageModifier(`WEAPON_MUSKET`, 0.1)

local trainTracks = { 0, 3 }
for _, track in ipairs(trainTracks) do
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

local function applyWorldSuppression()
    for _, scenario in ipairs(disabledScenarios) do
        SetScenarioTypeEnabled(scenario, false)
    end

    for _, emitter in ipairs(disabledEmitters) do
        SetStaticEmitterEnabled(emitter, false)
    end
end

local function ensureAudioSceneActive(name)
    if not IsAudioSceneActive(name) then
        StartAudioScene(name)
    end
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()

        SetAudioFlag("DisableFlightMusic", true)
        SetAudioFlag("PoliceScannerDisabled", true)
        SetRandomEventFlag(false)

        applyWorldSuppression()

        ensureAudioSceneActive("CHARACTER_CHANGE_IN_SKY_SCENE")
        ensureAudioSceneActive("DLC_MPHEIST_TRANSITION_TO_APT_FADE_IN_RADIO_SCENE")
        ensureAudioSceneActive("FBI_HEIST_H5_MUTE_AMBIENCE_SCENE")

        DistantCopCarSirens(false)
        OverrideReactionToVehicleSiren(true, 1)
        SetMaxWantedLevel(0)
        DisablePlayerVehicleRewards(ped)

        Wait(5000)
    end
end)

lib.onCache('ped', function(ped)
    if ped then
        SetPedConfigFlag(ped, 35, false)
        SetPedResetFlag(ped, 337, true)
    end
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedInCover(ped) and not IsPedAimingFromCover(ped) then
            DisableControlAction(2, 24, true)
            DisableControlAction(2, 142, true)
            DisableControlAction(2, 257, true)
            Wait(1)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedUsingActionMode(ped) then
            SetPedUsingActionMode(ped, false, -1, 'DEFAULT_ACTION')
            Wait(1)
        else
            Wait(5000)
        end
    end
end)

RegisterCommand('propstuck', function()
    local ped = PlayerPedId()
    for _, obj in pairs(GetGamePool('CObject')) do
        if IsEntityAttachedToEntity(ped, obj) then
            SetEntityAsMissionEntity(obj, true, true)
            DeleteObject(obj)
        end
    end
end)

RegisterCommand('record', function(_, args)
    local action = args[1]
    if action == 'start' then StartRecording(1)
    elseif action == 'stop' then StopRecordingAndSaveClip()
    elseif action == 'discard' then StopRecordingAndDiscardClip() end
end)

RegisterCommand('rockstareditor', ActivateRockstarEditor)
RegisterCommand('picture', function()
    BeginTakeHighQualityPhoto()
    SaveHighQualityPhoto(-1)
    FreeMemoryForHighQualityPhoto()
end)

RegisterKeyMapping('record start', '(Rockstar editor) Start Recording', 'keyboard', '')
RegisterKeyMapping('record stop', '(Rockstar editor) Stop Recording', 'keyboard', '')
RegisterKeyMapping('record discard', '(Rockstar editor) Discard Recording', 'keyboard', '')
RegisterKeyMapping('picture', '(Rockstar editor) Take a Picture', 'keyboard', '')

local vehicleClassDisableControl = {
    [0] = true, [1] = true, [2] = true, [3] = true,
    [4] = true, [5] = true, [6] = true, [7] = true,
    [8] = false, [9] = true, [10] = true, [11] = true,
    [12] = true, [13] = false, [14] = false, [15] = false,
    [16] = false, [17] = true, [18] = true, [19] = false
}

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0 then
            local class = GetVehicleClass(vehicle)

            if GetPedInVehicleSeat(vehicle, -1) == ped and vehicleClassDisableControl[class] then
                if IsEntityInAir(vehicle) or IsEntityUpsidedown(vehicle) then
                    DisableControlAction(2, 59, true)
                    DisableControlAction(2, 60, true)
                end
            end
        end

        Wait(1000)
    end
end)
