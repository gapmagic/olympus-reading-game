--[[--
Olympus saved state: one small Lua file in KOReader's settings folder
(koreader/settings/olympus.lua). Page logs live in each book's own sidecar
(.sdr) settings under the key "olympus_log".
--]]

local L = require("olympus_i18n").L
local DataStorage = require("datastorage")
local LuaSettings = require("luasettings")
local R = require("olympus_rules")
local I18N = require("olympus_i18n")
local Roster = I18N.current == "en" and require("olympus_roster_en") or require("olympus_roster")

local Store = {
    settings = nil,
    state = nil,
}

function Store.path()
    return DataStorage:getSettingsDir() .. "/olympus.lua"
end

function Store.load()
    if Store.state then return Store.state end
    Store.settings = LuaSettings:open(Store.path())
    Store.state = R.normalize(Store.settings:readSetting("state"))
    return Store.state
end

function Store.get()
    return Store.state or Store.load()
end

function Store.save()
    if not Store.settings then Store.load() end
    Store.settings:saveSetting("state", Store.state)
    Store.settings:flush()
end

function Store.today() return R.today() end
function Store.month() return R.month() end

-- Rolls the companion's day over; saves when something changed.
function Store.refreshDay()
    local s = Store.get()
    local before_day, before_char = s.companion.day, s.companion.char
    R.rollover(s, Store.today())
    if before_day ~= s.companion.day or before_char ~= s.companion.char then Store.save() end
    return s
end

function Store.reset()
    Store.state = R.newState()
    Store.save()
end

-- Text helpers shared by the screens --------------------------------------
Store.TIER_EGG = { L("Trứng đất sét"), L("Trứng bạc"), L("Trứng vàng") }
Store.TIER_EGG_UPPER = { L("TRỨNG ĐẤT SÉT"), L("TRỨNG BẠC"), L("TRỨNG VÀNG") }
Store.TIER_TAB = { L("Đất sét"), L("Bạc"), L("Vàng") }
Store.TIER_KIND = { L("Sinh vật"), L("Thần"), L("Titan") }
Store.TIER_KIND_UPPER = { L("SINH VẬT"), L("THẦN OLYMPUS"), L("TITAN") }
Store.TIER_GROUP = { L("Sinh vật và tiểu thần"), L("Thần Olympus"), L("Titan và thần nguyên thuỷ") }
Store.TIER_RANGE = { L("0 đến 200 trang"), L("201 đến 499 trang"), L("từ 500 trang") }

function Store.char(id) return Roster[id] end

function Store.number(id)
    return string.format("#%03d", R.indexInTier(id))
end

function Store.bookTitle(path)
    if not path then return "" end
    local name = path:match("([^/]+)$") or path
    name = name:gsub("%.[^%.]+$", "")
    -- Prefer the title KOReader already knows, when the book has been opened.
    local ok, DocSettings = pcall(require, "docsettings")
    if ok and DocSettings:hasSidecarFile(path) then
        local ds = DocSettings:open(path)
        local props = ds:readSetting("doc_props")
        if props and props.title and props.title ~= "" then return props.title end
    end
    return name
end

-- Home menu summary, e.g. "2 trứng · 12/90 •"
function Store.summary()
    local s = Store.get()
    local parts = {}
    if not R.phase2(s) then
        table.insert(parts, string.format(L("%d trứng"), R.usedSlots(s)))
    elseif s.companion.char then
        table.insert(parts, Roster[s.companion.char].name)
    end
    table.insert(parts, string.format("%d/90", R.totalHatched(s)))
    local text = table.concat(parts, " · ")
    if R.anyFresh(s) then text = text .. " •" end
    return text
end

return Store
