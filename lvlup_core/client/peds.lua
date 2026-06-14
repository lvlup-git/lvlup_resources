local PedDistance = 100.0

local Peds = {
    {
        model = 's_m_y_cop_01',
        coords = {
            vec4(1770.2, 2555.15, 45.57, 90.0), -- Prison
        }
    },
    {
        model = 's_m_y_chef_01',
        coords = {
            vec4(1770.12, 2556.8, 45.57, 84.83), -- Prison
        }
    }
}

local ActivePeds = {}

local function loadModel(model)
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(10) end
    return HasModelLoaded(model)
end

local function SpawnPed(pedIndex, coordIndex)
    local data = Peds[pedIndex]
    local coord = data.coords[coordIndex]
    local modelHash = GetHashKey(data.model)

    if not loadModel(modelHash) then return end

    local ped = CreatePed(4, modelHash, coord.x, coord.y, coord.z - 1.0, coord.w, false, false)

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)

    SetModelAsNoLongerNeeded(modelHash)

    ActivePeds[pedIndex] = ActivePeds[pedIndex] or {}
    ActivePeds[pedIndex][coordIndex] = ped
end

local function RemovePed(pedIndex, coordIndex)
    local ped = ActivePeds[pedIndex] and ActivePeds[pedIndex][coordIndex]
    if ped and DoesEntityExist(ped) then
        DeleteEntity(ped)
        ActivePeds[pedIndex][coordIndex] = nil
    end
end

local function RemoveAllPeds()
    for pedIndex, group in pairs(ActivePeds) do
        for coordIndex, ped in pairs(group) do
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
        end
    end
    ActivePeds = {}
end

CreateThread(function()
    local playerPed, playerCoords
    local dist

    while true do
        playerPed = PlayerPedId()
        playerCoords = GetEntityCoords(playerPed)

        for pedIndex = 1, #Peds do
            local pedData = Peds[pedIndex]
            for coordIndex = 1, #pedData.coords do
                local coord = pedData.coords[coordIndex]
                dist = #(playerCoords - vector3(coord.x, coord.y, coord.z))

                local pedExists = ActivePeds[pedIndex] and ActivePeds[pedIndex][coordIndex] and DoesEntityExist(ActivePeds[pedIndex][coordIndex])

                if dist > PedDistance and pedExists then
                    RemovePed(pedIndex, coordIndex)
                elseif dist <= PedDistance and not pedExists then
                    SpawnPed(pedIndex, coordIndex)
                end
            end
        end

        Wait(1000)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        RemoveAllPeds()
    end
end)
