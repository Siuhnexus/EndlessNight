---@meta _

-- this file will be reloaded if it changes during gameplay,
-- 	so only assign to values or define things here.

import "modules/biomeShortener.lua"
import "modules/statScaler.lua"
import "modules/runManager.lua"

FlushRegistry()
InitShorteners()
InitStatHooks()

function RunHistoryPatch()
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

-- Indicate endless run
RunStartVoicelines, SurfaceRunStartVoicelines = RegisterValues(GlobalVoiceLines, { "StartNewRunVoiceLines", "StartSurfaceRunVoiceLines" })
EndlessRunStartVoicelines = {
    {
        BreakIfPlayed = true,
		PreLineWait = 0.3,
		UsePlayerSource = true,
		ThreadName = "RoomThread",
        { Cue = "/VO/Nyx_0006", Text = "{#Emph}...My will be done...", Source = { LineHistoryName = "NPC_NyxVoice_01", SubtitleColor = Color.NyxVoice }, }
    }
}
RunStartVoicelines.set(EndlessRunStartVoicelines)
SurfaceRunStartVoicelines.set(EndlessRunStartVoicelines)

local statScaleFunction = function (routeDepth)
    return 10 ^ (routeDepth / 5)
end

function StartEndlessRun(base, usee, args)
    if not config.enabled then return base(usee, args) end
    value = base(usee, args)
    InitEndlessRun()
    return value
end

function CheckEndlessSave(base, ...)
    -- Check if run history contains runs that are not displayable without cutting keepsakes
    RunHistoryPatch()
    if not config.enabled then return base(...) end
    result = base(...)
    if RunIsEndlessRun() and CurrentEndlessRun == nil then
        InitEndlessRun(true)
        local routeDepth = GetRouteDepth()
        ApplyShortening(routeDepth)
        ScaleStats(statScaleFunction(routeDepth))
    end
    return result
end

function EndlessPylonObjective(base, room, args)
    if GetRouteDepth() == nil then return base(room, args) end
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
    if RunIsEndlessRun() and not IsRoomEligible(CurrentRun, RoomData.N_Story01) then
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

---@type TrackedValue
local tartarusEndFunction, tartarusEndArgs, tartarusEndSkip, tartarusEndEvents = nil, nil, nil, nil
---@type TrackedValue
local summitEndFunction, summitEndArgs, summitEndSkip, summitEndEvents1, summitEndEvents2 = nil, nil, nil, nil, nil
function ConnectEndToOtherStart(base, currentRun, door)
    if not config.enabled then return base(currentRun, door) end
    if CurrentRun.CurrentRoom.Name == "I_Boss01" then
        if not NextRoute() then
            RestoreDefaults()
            return base(currentRun, door)
        end
        local newDepth = GetRouteDepth()
        ApplyShortening(newDepth)
        ScaleStats(statScaleFunction(newDepth))

        tartarusEndFunction, tartarusEndArgs, tartarusEndSkip = RegisterValues(currentRun.CurrentRoom, { "ExitFunctionName", "ExitFunctionArgs", "SkipLoadNextMap" })
        if tartarusEndEvents == nil then
            tartarusEndEvents = RegisterValues(RoomData["I_Boss01"], "LeavePostPresentationEvents")
        end

        tartarusEndFunction.set(nil)
        tartarusEndArgs.set(nil)
        tartarusEndSkip.set(false)
        tartarusEndEvents.set(nil)
        door.Room = CreateRoom(RoomData.N_Opening01)
    elseif CurrentRun.CurrentRoom.Name == "Q_Boss01" or CurrentRun.CurrentRoom.Name == "Q_Boss02" then
        if not NextRoute() then
            RestoreDefaults()
            return base(currentRun, door)
        end
        local newDepth = GetRouteDepth()
        ApplyShortening(newDepth)
        ScaleStats(statScaleFunction(newDepth))
        
        summitEndFunction, summitEndArgs, summitEndSkip = RegisterValues(currentRun.CurrentRoom, { "ExitFunctionName", "ExitFunctionArgs", "SkipLoadNextMap" })
        if summitEndEvents1 == nil or summitEndEvents2 == nil then
            summitEndEvents1 = RegisterValues(RoomData["Q_Boss01"], "LeavePostPresentationEvents")
            summitEndEvents2 = RegisterValues(RoomData["Q_Boss02"], "LeavePostPresentationEvents")
        end

        summitEndFunction.set(nil)
        summitEndArgs.set(nil)
        summitEndSkip.set(false)
        summitEndEvents1.set(nil)
        summitEndEvents2.set(nil)
        door.Room = CreateRoom(ChooseStartingRoom(currentRun, { StartingBiome = "F" }))
    end
    return base(currentRun, door)
end

function PreventVictoryScreen(base, ...)
    if GetRouteDepth() == nil then return base(...) end
    if (CurrentRun.MaxGodsPerRun or 4) < NumberOfOlympians then return end
    return base(...)
end

function HeroDying(base, ...)
    EndEndlessRun()
    return base(...)
end