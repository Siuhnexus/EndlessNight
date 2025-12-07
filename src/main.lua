---@meta _
-- grabbing our dependencies,
-- these funky (---@) comments are just there
--	 to help VS Code find the definitions of things

---@diagnostic disable-next-line: undefined-global
local mods = rom.mods

---@module 'LuaENVY-ENVY-auto'
mods['LuaENVY-ENVY'].auto()
-- ^ this gives us `public` and `import`, among others
--	and makes all globals we define private to this plugin.
---@diagnostic disable: lowercase-global

---@diagnostic disable-next-line: undefined-global
rom = rom
---@diagnostic disable-next-line: undefined-global
_PLUGIN = _PLUGIN

-- get definitions for the game's globals
---@module 'game'
game = rom.game
---@module 'game-import'
import_as_fallback(game)

---@module 'SGG_Modding-SJSON'
sjson = mods['SGG_Modding-SJSON']
---@module 'SGG_Modding-ModUtil'
modutil = mods['SGG_Modding-ModUtil']

---@module 'SGG_Modding-Chalk'
chalk = mods["SGG_Modding-Chalk"]
---@module 'SGG_Modding-ReLoad'
reload = mods['SGG_Modding-ReLoad']

---@module "Siuhnexus-BountyAPI"
bountyAPI = mods["Siuhnexus-BountyAPI"]

---@module 'config'
config = chalk.auto 'config.lua'
-- ^ this updates our `.cfg` file in the config folder!
public.config = config -- so other mods can access our config

LogLevel = {
    Error = 1,
    Warning = 2,
    Success = 3,
    Info = 4
}

---Prints a message using the appropriate color
---@param msg string
---@param level? 1|2|3|4
function log(msg, level)
    level = level or 3
    if level > config.loglevel then return end
    color = "34"
    if level == LogLevel.Error then color = "31" end
    if level == LogLevel.Warning then color = "33" end
    if level == LogLevel.Success then color = "32" end

    local colorEscape = "\x1b[1;" .. color .. "m"
    local reset = "\x1b[0m"
    print(colorEscape .. msg .. reset)
end

function dumpTable(tbl, indent)
    local result = ""
    if not tbl then return result end
    if not indent then indent = 0 end

    local keys = {}
    for k in pairs(tbl) do
        keys[#keys + 1] = k
    end

    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)

    for _, k in ipairs(keys) do
        local v = tbl[k]
        local formatting = string.rep("  ", indent) .. tostring(k) .. ": "
        if type(v) == "table" then
            result = result .. formatting .. "\n" .. dumpTable(v, indent + 1)
        else
            result = result .. formatting .. tostring(v) .. "\n"
        end
    end
    return result
end

local function on_ready()
	-- what to do when we are ready, but not re-do on reload.
	if config.enabled == false then return end
	mod = modutil.mod.Mod.Register(_PLUGIN.guid)

	import 'ready.lua'
end

local function on_reload()
	-- what to do when we are ready, but also again on every reload.
	-- only do things that are safe to run over and over.
	if config.enabled == false then return end

	import 'reload.lua'
end

-- this allows us to limit certain functions to not be reloaded.
local loader = reload.auto_single()

-- this runs only when modutil and the game's lua is ready
modutil.once_loaded.game(function()
	loader.load(on_ready, on_reload)
end)
