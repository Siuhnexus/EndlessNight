NumberOfOlympians = 9
InitialGodPool = 4
---@alias EndlessData { Holdout: { EncountersOccurredCache: table, RoomsEntered: table, SoulPylon: number }, Depth: number }


---Inits the endless run storage
---@param BountyRunData EndlessData
function InitEndlessRun(BountyRunData)
    BountyRunData.Holdout = {
        EncountersOccurredCache = {},
        RoomsEntered = {},
        SoulPylon = 0
    }
    BountyRunData.Depth = 0
    CurrentRun.MaxGodsPerRun = InitialGodPool
    log("RunManager: Endless run started", LogLevel.Success)
end

---Extracts the current endless depth from bounty storage
---@param BountyRunData EndlessData
---@return number
function GetRouteDepth(BountyRunData)
    return BountyRunData.Depth
end

---To be called after beating the final boss of a route to prepare for another route
---@param BountyRunData EndlessData
function NextRoute(BountyRunData)
    -- Clear encounter cache to allow for choosing a random starting room in Erebus
    for key, value in pairs(CurrentRun.EncountersOccurredCache) do
        BountyRunData.Holdout.EncountersOccurredCache[key] = (BountyRunData.Holdout.EncountersOccurredCache[key] or 0) + value
    end
    CurrentRun.EncountersOccurredCache = {}

    -- Clear rooms entered log to allow for different minibosses in repeated routes and to fix issues with the shop forcing in the fields of mourning
    for key, value in pairs(CurrentRun.RoomsEntered) do
        BountyRunData.Holdout.RoomsEntered[key] = (BountyRunData.Holdout.RoomsEntered[key] or 0) + value
    end
    CurrentRun.RoomsEntered = {}

    -- Reset soul pylon spawn count
    BountyRunData.Holdout.SoulPylon = BountyRunData.Holdout.SoulPylon + (CurrentRun.SpawnRecord.SoulPylon or 0)
    CurrentRun.SpawnRecord.SoulPylon = 0
    -- Reopen closed Ephyra doors
    CurrentRun.ClosedDoors = {}

    -- Increase route depth for shortening and max god limit
    BountyRunData.Depth = BountyRunData.Depth + 1

    -- Increase god pool
    CurrentRun.MaxGodsPerRun = InitialGodPool + GetRouteDepth(BountyRunData)
end

---Determines whether the current endless run should end after the current route is cleared
---@return boolean ShouldEnd Indicates whether the run should end
function ShouldEndEndlessRun()
    return CurrentRun.MaxGodsPerRun >= NumberOfOlympians
end

---Combines the data from previous routes with the current one
---@param BountyRunData EndlessData
function EndEndlessRun(BountyRunData)
    NextRoute(BountyRunData)

    -- Reapply tables to CurrentRun for statistics
    CurrentRun.EncountersOccurredCache = BountyRunData.Holdout.EncountersOccurredCache
    CurrentRun.RoomsEntered = BountyRunData.Holdout.RoomsEntered
    CurrentRun.SpawnRecord.SoulPylon = BountyRunData.Holdout.SoulPylon

    -- Limit cached keepsakes to four to not crash the game when reviewing old runs
    local shortenedKeepsakes = {}
    for i = 1, 4 do
        shortenedKeepsakes[i] = CurrentRun.KeepsakeCache[i]
    end
    CurrentRun.KeepsakeCache = shortenedKeepsakes
end