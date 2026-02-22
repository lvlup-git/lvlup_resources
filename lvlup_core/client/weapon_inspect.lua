local sharedAnim = {
    dict = 'weapons@first_person@aim_idle@p_m_zero@pistol@shared@fidgets@c',
    anim = 'fidget_med_loop'
}

local inspectAnims = {
    [`GROUP_PISTOL`] = sharedAnim,
    [`GROUP_THROWN`] = sharedAnim,
    [`GROUP_SHOTGUN`] = sharedAnim,
    [`GROUP_SMG`] = sharedAnim,
    [`GROUP_RIFLE`] = sharedAnim,
    [`GROUP_SNIPER`] = sharedAnim,
    [`GROUP_MELEE`] = sharedAnim,
    [`GROUP_MG`] = sharedAnim,
    [`GROUP_STUNGUN`] = sharedAnim,
    [`GROUP_HEAVY`] = sharedAnim
}

local function DoWeaponInspect()
    local ped = PlayerPedId()
    if not IsPedArmed(ped, 7) then return end
    local weapon = GetSelectedPedWeapon(ped)
    local weaponGroup = GetWeapontypeGroup(weapon)
    local animData = inspectAnims[weaponGroup]
    if not animData then return end
    local dict, anim = animData.dict, animData.anim
    if IsEntityPlayingAnim(ped, dict, anim, 3) then return end
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(10) end
    end
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 48, 0, false, false, false)
    CreateThread(function()
        while IsEntityPlayingAnim(ped, dict, anim, 3) do
            if IsPedShooting(ped) then
                StopAnimTask(ped, dict, anim, 1.0)
                break
            end
            Wait(0)
        end
    end)
end

RegisterCommand('_inspectweapon', DoWeaponInspect, false)
RegisterKeyMapping('_inspectweapon', 'Inspect weapon', 'keyboard', '')
