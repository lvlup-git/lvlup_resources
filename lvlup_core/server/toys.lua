CreateThread(function()
    exports.qbx_core:CreateUseableItem('uwu_plushiebox', function(source)
        local src = source
        local Pools = {
            { items = {'uwu_smoker_small', 'uwu_princessbubblegum_small', 'uwu_master_small', 'uwu_wasabi_small'}, chance = 1 }, -- 1%
            { items = {'uwu_saki_small', 'uwu_poopie_small', 'uwu_muffy_small', 'uwu_humpy_small', 'uwu_grindy_small'}, chance = 1 }, -- 1%
            { items = {'uwu_smoker', 'uwu_princessbubblegum', 'uwu_master', 'uwu_wasabi'}, chance = 3 }, -- 3%
            { items = {'uwu_saki', 'uwu_poopie', 'uwu_muffy', 'uwu_humpy', 'uwu_grindy'}, chance = 95 } -- 95%
        }

        local roll = math.random(100)
        local cumulative = 0
        local selectedPool

        for _, pool in ipairs(Pools) do
            cumulative += pool.chance
            if roll <= cumulative then
                selectedPool = pool.items
                break
            end
        end

        if not selectedPool then return end

        local rewardItem = selectedPool[math.random(#selectedPool)]

        if not exports.ox_inventory:CanCarryItem(src, rewardItem, 1) then
            exports.qbx_core:Notify(src, 'Your pockets are too full and won\'t be able to carry that', 'error', 7000)
            return
        end

        if not exports.ox_inventory:RemoveItem(src, 'uwu_plushiebox', 1) then return end

        exports.ox_inventory:AddItem(src, rewardItem, 1)
    end)

    exports.qbx_core:CreateUseableItem('start_package', function(source)
        local src = source
        local startItems = {
            'phone',
            'heart_stopper',
            'iced_coffee', 'iced_coffee',
            'bandage', 'bandage', 'bandage',
            'wallet'
        }

        local itemCounts = {}
        for _, item in ipairs(startItems) do
            itemCounts[item] = (itemCounts[item] or 0) + 1
        end

        for item, amount in pairs(itemCounts) do
            if not exports.ox_inventory:CanCarryItem(src, item, amount) then
                exports.qbx_core:Notify(src, 'Your pockets are too full and won\'t be able to carry that', 'error', 7000)
                return
            end
        end

        if not exports.ox_inventory:RemoveItem(src, 'start_package', 1) then return end

        for item, amount in pairs(itemCounts) do
            exports.ox_inventory:AddItem(src, item, amount)
        end
    end)

    exports.qbx_core:CreateUseableItem('rejected_parcel', function(source)
        local src = source
        local rejectedItems = {
            { name = 'steel', amount = math.random(15) },
            { name = 'iron', amount = math.random(15) },
            { name = 'copper', amount = math.random(15) },
            { name = 'copper_wire', amount = math.random(15) },
            { name = 'aluminum', amount = math.random(15) },
            { name = 'rubber', amount = math.random(15) },
            { name = 'plastic', amount = math.random(15) },
            { name = 'glass', amount = math.random(15) },
            { name = 'metalscrap', amount = math.random(15) },
            { name = 'cloth', amount = math.random(15) },
            { name = 'screwdriver', amount = math.random(2) },
            { name = 'small_motor', amount = math.random(2) },
            { name = 'lubricant', amount = math.random(2) },
            { name = 'bandage', amount = math.random(10) },
            { name = 'backpack_small', amount = 1 },
            { name = 'backpack_medium', amount = 1 },
            { name = 'backpack_large', amount = 1 },
            { name = 'lockpick', amount = math.random(5) },
            { name = 'weaponrepairkit', amount = 1 },
            { name = 'cleaningkit', amount = 1 },
            { name = 'tirekit', amount = 1 },
            { name = 'repairkit', amount = 1 },
            { name = 'parachute', amount = 1 },
            { name = 'binoculars', amount = 1 },
            { name = 'kq_tow_rope', amount = 1 },
            { name = 'md_ancientcoin', amount = 1 },
            { name = 'md_presidentialwatch', amount = 1 },
            { name = 'md_relicrevolver', amount = 1 },
            { name = 'ls_military_helmet', amount = 1 },
            { name = 'ls_bottle_of_rum', amount = 1 },
            { name = 'ls_ancient_artifact', amount = 1 }
        }

        local entry = rejectedItems[math.random(#rejectedItems)]
        local item = entry.name
        local amount = entry.amount

        if not exports.ox_inventory:CanCarryItem(src, item, amount) then
            exports.qbx_core:Notify(src, 'Your pockets are too full and won\'t be able to carry that', 'error', 7000)
            return
        end

        if not exports.ox_inventory:RemoveItem(src, 'rejected_parcel', 1) then return end
        exports.ox_inventory:AddItem(src, item, amount)
    end)

    for k, v in pairs(lvlup_config_toys.Toys) do
        local itemName = k
        exports.qbx_core:CreateUseableItem(itemName, function(source)
            TriggerClientEvent('core:client:UseToy', source, itemName)
        end)
    end

    for k, v in pairs(lvlup_config_toys.SmallToys) do
        local itemName = k
        exports.qbx_core:CreateUseableItem(itemName, function(source)
            TriggerClientEvent('core:client:UseSmallToy', source, itemName)
        end)
    end
end)
