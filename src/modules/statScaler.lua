---@type TrackedValue[]
local statHooks = {}

---Hooks into game tables to prepare stat scaling
function InitStatHooks()
    for _, data in pairs(EnemyData) do
        local keysToAlter = {}

        -- Hook into health and armor of all enemies
        if data.MaxHealth ~= nil then table.insert(keysToAlter, "MaxHealth") end
        if data.HealthBuffer ~= nil then table.insert(keysToAlter, "HealthBuffer") end

        for _, tracked in ipairs(table.pack(RegisterValues(data, keysToAlter))) do
            table.insert(statHooks, tracked)
        end

        -- Account for rivals overrides of health for bosses
        if data.SetupEvents ~= nil then
            for _, setup in ipairs(data.SetupEvents) do
                if setup.Args ~= nil and setup.Args.MaxHealth ~= nil then
                    table.insert(statHooks, RegisterValues(setup.Args, "MaxHealth"))
                end
            end
        end

        -- Account for bosses with multiple stages
        if data.AIStages == nil then goto next end
        for _, stage in ipairs(data.AIStages) do
            if stage.NewMaxHealth ~= nil then
                table.insert(statHooks, RegisterValues(stage, "NewMaxHealth"))
            end
            -- Account for rivals overrides of later stages
            if stage.EMStageDataOverrides ~= nil and stage.EMStageDataOverrides.NewMaxHealth ~= nil then
                table.insert(statHooks, RegisterValues(stage.EMStageDataOverrides, "NewMaxHealth"))
            end
        end

        ::next::
    end
end

---Scales health and armor of all enemies
---@param scaleRelativeToOriginal number
function ScaleStats(scaleRelativeToOriginal)
    for _, hook in ipairs(statHooks) do
        hook.set(hook.original * scaleRelativeToOriginal)
    end
end