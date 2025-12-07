---@meta _

function prefix(key)
    return "Siuhnexus-EndlessNight_" .. key
end

modutil.mod.Path.Wrap("HandlePylonObjective", function(base, ...)
    return EndlessPylonObjective(base, ...)
end)

modutil.mod.Path.Context.Wrap("ChooseAvailableN_HubDoors", function(room, args)
    ControlMedeaEncounterCorrectly(room, args)
end)

modutil.mod.Path.Wrap("MapStateInit", function (base, ...)
    RunHistoryPatch()
    return base(...)
end)

EndlessRunActive = false

local easyLifeScale = function (routeDepth)
    return 10 ^ (routeDepth / 5)
end

bountyAPI.RegisterBounty({
    Id = prefix("EasyUnderworld"),
    Title = "Easy Endless Below",
    Description = "Repeatedly face Chronos after clearing the Underworld while enemies grow stronger with each clear",
    Difficulty = 2,
    IsStandardBounty = false,
    BiomeChar = "F",
    BaseData = {
		BiomeIcon = "GUI\\Screens\\BountyBoard\\Biome_Underworld",
		BiomeText = "BountyBoard_UnderworldRun",
    },

    DataOverrides = function (RegisterValues)
        return EndlessGameTableOverrides(RegisterValues)
    end,
    SetupFunctions = function (BountyRunData, FromSave)
        return SetupEndlessRun(BountyRunData, FromSave, easyLifeScale)
    end,
    RoomTransition = function (BountyRunData, RoomName)
        return ConnectEndToStart(BountyRunData, RoomName, easyLifeScale, false)
    end,
    CanEnd = function (BountyRunData, RoomName)
        return ShouldEndEndlessRun()
    end,
    EndFunctions = function (BountyRunData, Cleared)
        Dying(BountyRunData)
    end
})
bountyAPI.RegisterBounty({
    Id = prefix("EasySurface"),
    Title = "Easy Endless Above",
    Description = "Repeatedly face Typhon after clearing the Surface while enemies grow stronger with each clear",
    Difficulty = 2,
    IsStandardBounty = false,
    BiomeChar = "N",
    BaseData = {
		BiomeIcon = "GUI\\Screens\\BountyBoard\\Biome_Surface",
		BiomeText = "BountyBoard_SurfaceRun",
    },

    DataOverrides = function (RegisterValues)
        return EndlessGameTableOverrides(RegisterValues)
    end,
    SetupFunctions = function (BountyRunData, FromSave)
        return SetupEndlessRun(BountyRunData, FromSave, easyLifeScale)
    end,
    RoomTransition = function (BountyRunData, RoomName)
        return ConnectEndToStart(BountyRunData, RoomName, easyLifeScale, false)
    end,
    CanEnd = function (BountyRunData, RoomName)
        return ShouldEndEndlessRun()
    end,
    EndFunctions = function (BountyRunData, Cleared)
        Dying(BountyRunData)
    end
})
bountyAPI.RegisterBounty({
    Id = prefix("EasyBoth"),
    Title = "Easy Endless Both",
    Description = "Repeatedly face your ultimate adversaries after clearing both routes while enemies grow stronger with each clear (starting with the Underworld)",
    Difficulty = 2,
    IsStandardBounty = false,
    BiomeChar = "F",
    BaseData = {
		BiomeIcon = "GUI\\Screens\\BountyBoard\\Biome_Underworld",
		BiomeText = "Both Routes",
    },

    DataOverrides = function (RegisterValues)
        return EndlessGameTableOverrides(RegisterValues)
    end,
    SetupFunctions = function (BountyRunData, FromSave)
        return SetupEndlessRun(BountyRunData, FromSave, easyLifeScale)
    end,
    RoomTransition = function (BountyRunData, RoomName)
        return ConnectEndToStart(BountyRunData, RoomName, easyLifeScale, true)
    end,
    CanEnd = function (BountyRunData, RoomName)
        return ShouldEndEndlessRun()
    end,
    EndFunctions = function (BountyRunData, Cleared)
        Dying(BountyRunData)
    end
})