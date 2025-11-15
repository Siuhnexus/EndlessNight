---@alias Biome "F"|"G"|"H"|"I"|"N"|"O"|"P"|"Q"
---@alias BiomeShortener { set: (fun(value: integer)), max: integer }
---@alias BiomeRegisterer fun(biome: Biome): BiomeShortener | nil

---@type Biome[]
Biomes = { "F", "G", "H", "I", "N", "O", "P", "Q" }
---@type table<Biome, string>
BiomeNames = {
    F = "Erebus",
    G = "Oceanus",
    H = "Fields of Mourning",
    I = "Tartarus",
    N = "Ephyra",
    O = "Rift of Thessaly",
    P = "Mount Olympus",
    Q = "The Summit"
}


---Shortens biomes based on the maxdepth spawn of the final shop
---@type BiomeRegisterer
local function RegularRegisterer(biome)
    local roomNameStart = biome .. "_" .. "PreBoss"
    for name, data in pairs(RoomData) do
        if string.find(name, roomNameStart) == nil then goto next end

        local forceMin, forceMax = RegisterValues(data, { "ForceAtBiomeDepthMin", "ForceAtBiomeDepthMax" })
        do return {
            set = function (value)
                forceMin.set(value)
                forceMax.set(value)
                log("BiomeShortener: Run depth of final shop for " .. BiomeNames[biome] .. " was set to " .. value, LogLevel.Success)
            end,
            max = forceMin.original
        } end
        ::next::
    end
    log("BiomeShortener: Final shop for " .. BiomeNames[biome] .. " could not be found", LogLevel.Error)
    return nil
end

---Shortens Mourning Fields based on the sum of cleared locations
---@type BiomeRegisterer
local function FieldsRegisterer(biome)
    local roomNameStart = biome .. "_" .. "PreBoss"
    for name, data in pairs(RoomData) do
        if string.find(name, roomNameStart) == nil then goto next end

        local gameStateReq = data.GameStateRequirements[1]
        local force = RegisterValues(gameStateReq, "Value")
        do return {
            set = function (value)
                force.set(value)
                log("BiomeShortener: Run depth of final shop for " .. BiomeNames[biome] .. " was set to " .. value, LogLevel.Success)
            end,
            max = force.original
        } end
        ::next::
    end
    log("BiomeShortener: Final shop for " .. BiomeNames[biome] .. " could not be found", LogLevel.Error)
    return nil
end

---Shortens Tartarus biome by changing the amount of clockwork goals
---@type BiomeRegisterer
local function ClockworkRegisterer(biome)
    local roomNameStart = biome .. "_" .. "Intro"
    for name, data in pairs(RoomData) do
        if string.find(name, roomNameStart) == nil then goto next end

        for _, event in ipairs(data.StartUnthreadedEvents) do
            if event.FunctionName ~= "InitClockworkGoalReward" then goto next2 end
            
            local clockworkSettings = event.Args
            local goals, nonMin, nonMax = RegisterValues(clockworkSettings, { "GoalRewards", "MinNonGoalRewards", "MaxNonGoalRewards" })

            do return {
                set = function (value)
                    goals.set(value)
                    local dist = goals.original - value
                    nonMin.set(math.max(nonMin.original - dist, 1))
                    nonMax.set(math.max(nonMax.original - 2 * dist, 1))
                    log("BiomeShortener: Clockwork goals for " .. BiomeNames[biome] .. " were set to " .. value, LogLevel.Success)
                end,
                max = goals.original
            } end
            ::next2::
        end
        ::next::
    end
    log("BiomeShortener: Initial room for " .. BiomeNames[biome] .. " could not be found", LogLevel.Error)
    return nil
end

ControlValues = {
    NeededPylons = 6
}

---Shortens Ephyra by reducing required pylons
---@type BiomeRegisterer
local function PylonRegisterer(biome)
    local roomNameStart = biome .. "_" .. "Hub"
    for name, data in pairs(RoomData) do
        if string.find(name, roomNameStart) == nil then goto next end

        local pylons = RegisterValues(ControlValues, "NeededPylons")
        local exit = RegisterValues(ObstacleData.EphyraExitBossDoor.AvailableRequirements[1], "Value")
        ---@type TrackedValue[]
        local pylonDependent = {}

        -- Alter the hub fountain use check
        for _, event in ipairs(ObstacleData.HealthFountainN.SetupEvents) do
            if event.FunctionName == "HealthFountainNExitCheck" then
                table.insert(pylonDependent, RegisterValues(event.GameStateRequirements[1], "Value"))
                break
            end
        end

        -- Disable barrier and lock exits of hub appropriately when first entering the hub
        local threaded = RegisterValues(data, "ThreadedEvents")
        local newThreaded = ShallowCopyTable(threaded.original) or {}
        for _, event in ipairs(data.PostCombatReloadThreadedEvents) do
            table.insert(newThreaded, event)
            local path = nil
            if event.GameStateRequirements ~= nil and event.GameStateRequirements[1] ~= nil then path = event.GameStateRequirements[1].Path end
            if path == nil or path[1] ~= "CurrentRun" or path[2] ~= "SpawnRecord" or path[3] ~= "SoulPylon" then goto next2 end

            table.insert(pylonDependent, RegisterValues(event.GameStateRequirements[1], "Value"))
            if event.FunctionName == "LockEphyraExits" then
                table.insert(pylonDependent, RegisterValues(event.Args, "LockAtSoulPylonCount"))
            end
            ::next2::
        end
        threaded.set(newThreaded)

        -- Disable barrier parts at the right time
        for _, obstacle in pairs(data.ObstacleData) do
            local path = nil
            if obstacle.SetupEvents ~= nil and obstacle.SetupEvents[1] ~= nil and obstacle.SetupEvents[1].GameStateRequirements ~= nil and obstacle.SetupEvents[1].GameStateRequirements[1] ~= nil then path = obstacle.SetupEvents[1].GameStateRequirements[1].Path end
            if path == nil or path[1] ~= "CurrentRun" or path[2] ~= "SpawnRecord" or path[3] ~= "SoulPylon" then goto next2 end
            
            table.insert(pylonDependent, RegisterValues(obstacle.SetupEvents[1].GameStateRequirements[1], "Value"))
            ::next2::
        end

        do return {
            set = function (value)
                pylons.set(value)
                exit.set(value)
                local dist = pylons.original - value
                for _, var in ipairs(pylonDependent) do
                    var.set(var.original - dist)
                end
                log("BiomeShortener: Soul pylon amount for " .. BiomeNames[biome] .. " was set to " .. value, LogLevel.Success)
            end,
            max = pylons.original
        } end
        ::next::
    end
    log("BiomeShortener: Hub room for " .. BiomeNames[biome] .. " could not be found", LogLevel.Error)
    return nil
end

---Shortens The Summit based on the depth spawn of the final shop
---@type BiomeRegisterer
local function SummitRegisterer(biome)
    local roomNameStart = biome .. "_" .. "PreBoss"
    for name, data in pairs(RoomData) do
        if string.find(name, roomNameStart) == nil then goto next end

        local force = RegisterValues(data, "ForceAtBiomeDepth")
        do return {
            set = function (value)
                force.set(value)
                log("BiomeShortener: Run depth of final shop for " .. BiomeNames[biome] .. " was set to " .. value, LogLevel.Success)
            end,
            max = force.original
        } end
        ::next::
    end
    log("BiomeShortener: Final shop for " .. BiomeNames[biome] .. " could not be found", LogLevel.Error)
    return nil
end

---@type { Biome: { min: integer, step: integer, registerer: BiomeRegisterer|nil }}
local BiomeShorteningInfo = {
    F = {
        min = 2,
        step = 2,
        registerer = RegularRegisterer,
    },
    G = {
        min = 2,
        step = 1,
        registerer = RegularRegisterer,
    },
    H = {
        min = 1,
        step = 1,
        registerer = FieldsRegisterer
    },
    I = {
        min = 1,
        step = 1,
        registerer = ClockworkRegisterer
    },
    N = {
        min = 0,
        step = 1,
        registerer = PylonRegisterer
    },
    O = {
        min = 2,
        step = 1,
        registerer = RegularRegisterer,
    },
    P = {
        min = 2,
        step = 2,
        registerer = RegularRegisterer,
    },
    Q = {
        min = 4,
        step = 3,
        registerer = SummitRegisterer
    }
}

---@type table<Biome, BiomeShortener|nil>
local BiomeShorteners = {}

---Initializes hooks into game tables for biome shortening
function InitShorteners()
    for _, biome in ipairs(Biomes) do
        local info = BiomeShorteningInfo[biome]
        if info.registerer ~= nil then
            BiomeShorteners[biome] = info.registerer(biome)
            log("BiomeShortener: Registerer for " .. BiomeNames[biome] .. " was successfully executed", LogLevel.Success)
        else
            log("BiomeShortener: Registerer for " .. BiomeNames[biome] .. " was not found", LogLevel.Warning)
        end
    end
end

---Applies shortening based on the current run depth
---@param runDepth integer
function ApplyShortening(runDepth)
    for biome, shortener in pairs(BiomeShorteners) do
        if shortener ~= nil then
            local info = BiomeShorteningInfo[biome]
            local newValue = math.max(shortener.max - runDepth * info.step, info.min)
            shortener.set(newValue)
        end
    end
end