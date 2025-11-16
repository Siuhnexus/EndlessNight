local RouteDepthKey = PrefixGlobal("RouteDepth")
NumberOfOlympians = 9
InitialGodPool = 4
---@type { EncountersOccurredCache: table, RoomsEntered: table, SoulPylon: number }
CurrentEndlessRun = nil

function InitEndlessRun(saved)
    saved = saved or false
    CurrentEndlessRun = {
        EncountersOccurredCache = {},
        RoomsEntered = {},
        SoulPylon = 0
    }
    if saved then return end
    CurrentRun[RouteDepthKey] = 0
    log("RunManager: Endless run started", LogLevel.Success)
end

function GetRouteDepth()
    return CurrentRun[RouteDepthKey]
end

---To be called after beating the final boss of a route to prepare for another route
---@return boolean Finish Indicating whether the run should be stopped
function NextRoute()
    -- Clear encounter cache to allow for choosing a random starting room in Erebus
    for key, value in pairs(CurrentRun.EncountersOccurredCache) do
        CurrentEndlessRun.EncountersOccurredCache[key] = (CurrentEndlessRun.EncountersOccurredCache[key] or 0) + value
    end
    CurrentRun.EncountersOccurredCache = {}

    -- Clear rooms entered log to allow for different minibosses in repeated routes and to fix issues with the shop forcing in the fields of mourning
    for key, value in pairs(CurrentRun.RoomsEntered) do
        CurrentEndlessRun.RoomsEntered[key] = (CurrentEndlessRun.RoomsEntered[key] or 0) + value
    end
    CurrentRun.RoomsEntered = {}

    -- Reset soul pylon spawn count
    CurrentEndlessRun.SoulPylon = CurrentEndlessRun.SoulPylon + (CurrentRun.SpawnRecord.SoulPylon or 0)
    CurrentRun.SpawnRecord.SoulPylon = 0
    -- Reopen closed Ephyra doors
    CurrentRun.ClosedDoors = {}

    -- Increase route depth for shortening and max god limit
    CurrentRun[RouteDepthKey] = CurrentRun[RouteDepthKey] + 1

    -- Increase god pool
    CurrentRun.MaxGodsPerRun = InitialGodPool + GetRouteDepth()

    if CurrentRun.MaxGodsPerRun > NumberOfOlympians then
        EndEndlessRun()
        return false
    end
    return true
end

function EndEndlessRun()
    -- Reapply tables to CurrentRun for statistics
    CurrentRun.EncountersOccurredCache = CurrentEndlessRun.EncountersOccurredCache
    CurrentRun.RoomsEntered = CurrentEndlessRun.RoomsEntered
    CurrentRun.SpawnRecord.SoulPylon = CurrentEndlessRun.SoulPylon

    -- Limit cached keepsakes to four to not crash the game when reviewing old runs
    local shortenedKeepsakes = {}
    for i = 1, 4 do
        shortenedKeepsakes[i] = CurrentRun.KeepsakeCache[i]
    end
    CurrentRun.KeepsakeCache = shortenedKeepsakes

    CurrentEndlessRun = nil
end