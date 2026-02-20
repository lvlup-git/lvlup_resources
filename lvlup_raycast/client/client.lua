local screenX, screenY = 0.75, 0.5
local enabled = false
local lastEntityPos = vector3(0, 0, 0)
local boundingBoxCache = nil

local boxColor, lineColor, highlightColor =
    Config.BoxColor, Config.LineColor, Config.HighlightedLineColor

RegisterNetEvent('v-raycast:client:toggle', function()
    enabled = not enabled
    local state = enabled and "^2enabled^7" or "^1disabled^7"
    print(("[v-raycast] Raycast %s."):format(state))
end)

local function RotationToDirection(rot)
    local rad = vector3(math.rad(rot.x), math.rad(rot.y), math.rad(rot.z))
    local cosX = math.abs(math.cos(rad.x))
    return vector3(-math.sin(rad.z) * cosX, math.cos(rad.z) * cosX, math.sin(rad.x))
end

local function RayCastFromCamera(distance)
    local camRot, camPos = GetGameplayCamRot(), GetGameplayCamCoord()
    local dir = RotationToDirection(camRot)
    local dest = camPos + (dir * distance)
    local ray = StartShapeTestRay(camPos.x, camPos.y, camPos.z, dest.x, dest.y, dest.z, -1, PlayerPedId(), 0)
    local _, hit, endCoords, _, entity = GetShapeTestResult(ray)
    return hit == 1, endCoords, entity
end

local function DrawEntityBoundingBox(entity)
    if not DoesEntityExist(entity) then return end
    local model = GetEntityModel(entity)
    if not model or model == 0 then return end

    local min, max = GetModelDimensions(model)
    local p = {
        GetOffsetFromEntityInWorldCoords(entity, min.x, min.y, min.z),
        GetOffsetFromEntityInWorldCoords(entity, max.x, min.y, min.z),
        GetOffsetFromEntityInWorldCoords(entity, min.x, max.y, min.z),
        GetOffsetFromEntityInWorldCoords(entity, max.x, max.y, min.z),
        GetOffsetFromEntityInWorldCoords(entity, min.x, min.y, max.z),
        GetOffsetFromEntityInWorldCoords(entity, max.x, min.y, max.z),
        GetOffsetFromEntityInWorldCoords(entity, min.x, max.y, max.z),
        GetOffsetFromEntityInWorldCoords(entity, max.x, max.y, max.z)
    }

    local function line(a, b)
        DrawLine(p[a].x, p[a].y, p[a].z, p[b].x, p[b].y, p[b].z, boxColor.r, boxColor.g, boxColor.b, boxColor.a)
    end

    line(1, 2) line(2, 4) line(4, 3) line(3, 1)
    line(5, 6) line(6, 8) line(8, 7) line(7, 5)
    line(1, 5) line(2, 6) line(3, 7) line(4, 8)
end

local function Draw2DText(x, y, text)
    SetTextScale(0.55, 0.55)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

CreateThread(function()
    while true do
        if enabled then
            local ped = PlayerPedId()
            local hit, hitCoords, entity = RayCastFromCamera(1000.0)
            local playerCoords = GetEntityCoords(ped)
            local lineCol = lineColor

            if hit then
                local coordsText = ('%.2f, %.2f, %.2f'):format(hitCoords.x, hitCoords.y, hitCoords.z)

                if entity and DoesEntityExist(entity)
                    and (IsEntityAnObject(entity) or IsEntityAVehicle(entity) or IsEntityAPed(entity)) then

                    lineCol = highlightColor
                    local coords = GetEntityCoords(entity)
                    local heading = GetEntityHeading(entity)
                    local hash = GetEntityModel(entity)

                    Draw2DText(screenX, screenY, ('%.2f, %.2f, %.2f, %.2f\nHash: %s\nPress [E] to copy coords')
                        :format(coords.x, coords.y, coords.z, heading, hash))

                    if IsControlJustPressed(0, 46) then
                        lib.setClipboard(coordsText)
                    end

                    DrawEntityBoundingBox(entity)
                else
                    Draw2DText(screenX, screenY, coordsText .. '\nPress [E] to copy coords')
                    if IsControlJustPressed(0, 46) then
                        lib.setClipboard(coordsText)
                    end
                end

                -- Draw line and marker for hit
                DrawLine(playerCoords.x, playerCoords.y, playerCoords.z,
                         hitCoords.x, hitCoords.y, hitCoords.z,
                         lineCol.r, lineCol.g, lineCol.b, lineCol.a)

                DrawMarker(28, hitCoords.x, hitCoords.y, hitCoords.z,
                           0.0, 0.0, 0.0, 0.0, 180.0, 0.0,
                           0.1, 0.1, 0.1, lineCol.r, lineCol.g, lineCol.b, lineCol.a,
                           false, true, 2, nil, nil, false)
            end
        end
        Wait(0)
    end
end)
