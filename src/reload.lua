---@meta _

-- this file will be reloaded if it changes during gameplay,
-- 	so only assign to values or define things here.

import "modules/biomeShortener.lua"
import "modules/runManager.lua"
FlushRegistry()
InitShorteners()

-- Indicate endless run
RunStartVoicelines = RegisterValues(GlobalVoiceLines, "StartNewRunVoiceLines")
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

InsaneDamageName = PrefixGlobal("InsaneDamage")
InsaneDamageMultiplier = {
    Name = InsaneDamageName,
    InheritFrom = { "BaseTrait", "EarthBoon" },
	Icon = "Boon_Hera_37",
    AddOutgoingDamageModifiers = {
        GlobalMultiplier = 100
    }
}
ProcessDataInheritance(InsaneDamageMultiplier, TraitData)
TraitData[InsaneDamageName] = InsaneDamageMultiplier

function StartEndlessRun(base, usee, args)
    --args.StartingBiome = "P" -- faster first run for testing
    value = base(usee, args)
    InitEndlessRun()
    ApplyShortening(GetRouteDepth())
    AddTraitToHero({ TraitData = InsaneDamageMultiplier })
    for i = 1, 51, 1 do
        AddTraitToHero({
            TraitName = "AirEssence",
            ReportValues = { ReportedTraitName = "TraitName" }
        })
    end
    AddTraitToHero({ TraitName = "ElementalDodgeBoon" })
    return value
end

function CheckEndlessSave(base, ...)
    result = base(...)
    if CurrentRun ~= nil and GetRouteDepth() ~= nil then
        InitEndlessRun(true)
        ApplyShortening(GetRouteDepth())
    end
    return result
end

function EndlessPylonObjective(base, room, args)
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

---@type TrackedValue
local tartarusEndFunction, tartarusEndArgs, tartarusEndSkip, tartarusEndEvents = nil, nil, nil, nil
---@type TrackedValue
local summitEndFunction, summitEndArgs, summitEndSkip, summitEndEvents1, summitEndEvents2 = nil, nil, nil, nil, nil
function ConnectEndToOtherStart(base, currentRun, door)
    if CurrentRun.CurrentRoom.Name == "I_Boss01" then
        if not NextRoute() then
            if tartarusEndEvents ~= nil then tartarusEndEvents.set(tartarusEndEvents.original) end
            return base(currentRun, door)
        end
        ApplyShortening(GetRouteDepth())

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
            if summitEndEvents1 ~= nil then summitEndEvents1.set(summitEndEvents1.original) end
            if summitEndEvents2 ~= nil then summitEndEvents2.set(summitEndEvents2.original) end
            return base(currentRun, door)
        end
        ApplyShortening(GetRouteDepth())
        
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