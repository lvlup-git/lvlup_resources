CreateThread(function()
    exports.qbx_core:CreateUseableItem('plushiebox', function(source)
        local src = source

        local SmallLegendaryItems = {'uwu_smoker_small', 'uwu_princessbubblegum_small', 'uwu_master_small', 'uwu_wasabi_small'}
        local SmallCommonItems = {'uwu_saki_small', 'uwu_poopie_small', 'uwu_muffy_small', 'uwu_humpy_small', 'uwu_grindy_small'}
        local LegendaryItems = {'uwu_smoker', 'uwu_princessbubblegum', 'uwu_master', 'uwu_wasabi'}
        local CommonItems = {'uwu_saki', 'uwu_poopie', 'uwu_muffy', 'uwu_humpy', 'uwu_grindy'}

        local rewardItem = nil
        local roll = math.random(100)

        if roll <= 1 then
            rewardItem = SmallLegendaryItems[math.random(1, #SmallLegendaryItems)]
        elseif roll <= 2 then
            rewardItem = SmallCommonItems[math.random(1, #SmallCommonItems)]
        elseif roll <= 5 then
            rewardItem = LegendaryItems[math.random(1, #LegendaryItems)]
        else
            rewardItem = CommonItems[math.random(1, #CommonItems)]
        end

        if exports.ox_inventory:CanCarryItem(src, rewardItem, 1) then
            exports.ox_inventory:RemoveItem(src, 'plushiebox', 1)
            exports.ox_inventory:AddItem(src, rewardItem, 1)
        else
            exports.qbx_core:Notify(src, 'Your pockets are too full and won\'t be able to carry that', 'error', 7000)
        end
    end)

    for k, v in pairs(Config.Toys) do
        exports.qbx_core:CreateUseableItem(k, function(source, item) TriggerClientEvent('core:client:UseToy', source, item.name) end)
    end

    for k, v in pairs(Config.SmallToys) do
        exports.qbx_core:CreateUseableItem(k, function(source, item) TriggerClientEvent('core:client:UseSmallToy', source, item.name) end)
    end
end)