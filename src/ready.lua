---@meta _

import "modules/safeGameTableModifier.lua"

modutil.mod.Path.Wrap("MapStateInit", function (base, ...)
    return CheckEndlessSave(base, ...)
end)

modutil.mod.Path.Wrap("UseEscapeDoor", function (base, ...)
    return StartEndlessRun(base, ...)
end)

modutil.mod.Path.Wrap("HandlePylonObjective", function(base, ...)
    return EndlessPylonObjective(base, ...)
end)

modutil.mod.Path.Wrap("LeaveRoom", function(base, ...)
    return ConnectEndToOtherStart(base, ...)
end)

modutil.mod.Path.Wrap("OpenRunClearScreen", function(base, ...)
    return PreventVictoryScreen(base, ...)
end)