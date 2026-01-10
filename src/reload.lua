---@meta _

-- this file will be reloaded if it changes during gameplay,
-- 	so only assign to values or define things here.

import "modules/biomeShortener.lua"
import "modules/statScaler.lua"
import "modules/runManager.lua"

patchExecuted = false
function RunHistoryPatch()
    if patchExecuted then return end
    patchExecuted = true
    for _, runData in ipairs(GameState.RunHistory) do
        if runData.KeepsakeCache ~= nil and #runData.KeepsakeCache > 4 then
            log("Run history with too many keepsakes detected", LogLevel.Warning)
            local shortenedKeepsakes = {}
            for i = 1, 4 do
                shortenedKeepsakes[i] = runData.KeepsakeCache[i]
            end
            runData.KeepsakeCache = shortenedKeepsakes
            log("Keepsakes limited to first four", LogLevel.Success)
        end
    end
end

EndlessRunActive = false

function EndlessPylonObjective(base, room, args)
    if not EndlessRunActive then return base(room, args) end
    args = args or {}

	if not IsGameStateEligible( room, NamedRequirementsData.PylonObjectiveRevealed ) then
		return
	end

	wait( args.Delay, RoomThreadName )

	wait(1.3, RoomThreadName)

	if room.Leaving then
		return
	end

	CheckObjectiveSet("BiomeNBossUnlock")
	local objectiveText = 0
	local numPylons = CurrentRun.SpawnRecord.SoulPylon or 0

	numPylons = numPylons - #GetIdsByType({ Name ="SoulPylon" })

	UpdateObjectiveDescription( "BiomeNPylons", "Objective_BiomeNPylons", "Pylons", ControlValues.NeededPylons - numPylons )

	wait(1.3, RoomThreadName)

	if numPylons >= ControlValues.NeededPylons then
		MarkObjectiveComplete("BiomeNPylons")
	end
end

function ControlMedeaEncounterCorrectly(room, args)
    if EndlessRunActive and not IsRoomEligible(CurrentRun, CurrentRun.CurrentRoom, RoomData.N_Story01) then
        log("Removing Medea encounter as it has already appeared", LogLevel.Success)
        modutil.mod.Path.Wrap("GetAllKeys", function(base, dict)
            if dict == nil then
                return
            end

            local keys = {}
            for k, v in pairs( dict ) do
                if not (v == "N_Story01") then
                    table.insert( keys, k )
                else
                    log("Medea encounter appeared in predetermined rooms table", LogLevel.Success)
                    room.UnavailableDoors[k] = true
                end
            end
            return keys
        end)
    end
end

---Sets up all overrides to make endless running possible
---@param RegisterValues TrackedValueRegisterer
function EndlessGameTableOverrides(RegisterValues)
    InitShorteners(RegisterValues)
    InitStatHooks(RegisterValues)

    for _, name in ipairs({ "I_Boss01", "Q_Boss01", "Q_Boss02" }) do
        endFunction, endArgs, endSkip, endEvents, overwriteSelf = RegisterValues(RoomData[name], { "ExitFunctionName", "ExitFunctionArgs", "SkipLoadNextMap", "LeavePostPresentationEvents", "UnthreadedEvents" })
        endFunction.set(nil)
        endArgs.set(nil)
        endSkip.set(nil)
        endEvents.set(nil)
        -- Prevent self override when story is completed
        toFilter = RoomData[name].UnthreadedEvents
        filtered = {}
        for i, event in ipairs(toFilter) do
            if event.FunctionName ~= "OverwriteSelf" then table.insert(filtered, event) end
        end
        overwriteSelf.set(filtered)
    end
end

function SetupEndlessRun(BountyRunData, FromSave, scaler)
    if FromSave then
        local routeDepth = GetRouteDepth(BountyRunData)
        ApplyShortening(routeDepth)
        ScaleStats(scaler(routeDepth))
    else
        InitEndlessRun(BountyRunData)
    end
    EndlessRunActive = true
end

function ConnectEndToStart(BountyRunData, RoomName, scaler, mix)
    if RoomName ~= "I_Boss01" and RoomName ~= "Q_Boss01" and RoomName ~= "Q_Boss02" then return end
    
    NextRoute(BountyRunData)
    local newDepth = GetRouteDepth(BountyRunData)
    ApplyShortening(newDepth)
    ScaleStats(scaler(newDepth))

    underworld = RoomName == "I_Boss01"
    if mix then underworld = not underworld end

    if underworld then
        return ChooseStartingRoom(CurrentRun, { StartingBiome = "F" })
    else
        return "N_Opening01"
    end
end

function Dying(BountyRunData)
    EndEndlessRun(BountyRunData)
    FlushShorteners()
    FlushStatHooks()
    EndlessRunActive = false
end