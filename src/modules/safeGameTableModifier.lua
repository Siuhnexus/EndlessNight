---Prefixes a given key string for use in global contexts (e. g. game tables)
---@param key string
---@return string
function PrefixGlobal(key)
    return "Siuhnexus_EndlessNight_" .. key
end

---@type { object: table, keys: string[], values: any[] }[]
local alteredValues = {}

---@alias TrackedValue { get: (fun(): any), set: (fun(value: any)), original: any }
---Keeps track of changed values in game tables and provides an easy API to work with them
---@param object table
---@param keys string | string[]
---@return TrackedValue, TrackedValue, TrackedValue, TrackedValue, TrackedValue, TrackedValue, TrackedValue, TrackedValue, TrackedValue, TrackedValue
function RegisterValues(object, keys)
    local values = {}
    local tracked = {}
    if type(keys) == "string" then keys = { keys } end

    for _, key in ipairs(keys) do
        local value = object[key]
        table.insert(values, value)
        table.insert(tracked, {
            get = function ()
                return object[key]
            end,
            set = function (value)
                object[key] = value
                log("SafeGameTableModifier: Key " .. key .. " was set", LogLevel.Info)
            end,
            original = value,
        })
    end

    table.insert(alteredValues, { object = object, keys = keys, values = values })
    log("SafeGameTableModifier: Registered " .. #values .. " values", LogLevel.Info)
    return table.unpack(tracked)
end

---Restores original values to all registered objects
function RestoreDefaults()
    for _, t in ipairs(alteredValues) do
        for i, key in ipairs(t.keys) do
            t.object[key] = t.values[i]
        end
    end
    log("SafeGameTableModifier: Restored all values", LogLevel.Info)
end

function FlushRegistry()
    RestoreDefaults()
    alteredValues = {}
end