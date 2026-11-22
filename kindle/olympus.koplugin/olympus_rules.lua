--[[--
Olympus reading game: rules and saved state.

Pure Lua, no KOReader dependencies, so it can be unit tested on a PC.
Port of OlympusRules.cpp from the CrossPoint (Xteink X4 Pro) firmware.

Character ids are 1..90: 1-30 clay (creatures), 31-60 silver (gods),
61-90 gold (Titans and primordials). Tiers are 1 clay, 2 silver, 3 gold.
--]]

local bit = require("bit")

local R = {}

R.TIER_COUNT = 3
R.PER_TIER = 30
R.TOTAL = 90
R.SLOT_COUNT = 3
R.COLD_EGG_DAYS = 7      -- days without reading before an egg frosts over
R.MAX_MISSED_DAYS = 3    -- creature leaves / torch turns to embers
R.PAGES_PER_FOOD = 5
R.HATCH_AT = 0.95        -- reading position that counts as finishing the book
R.CLAY, R.SILVER, R.GOLD = 1, 2, 3

function R.tierForPages(pages)
    if pages <= 200 then return R.CLAY end
    if pages <= 499 then return R.SILVER end
    return R.GOLD
end

local GOALS = { 5, 10, 20 }
function R.dailyGoal(tier) return GOALS[tier] or 5 end

function R.tierOf(id) return math.floor((id - 1) / R.PER_TIER) + 1 end
function R.indexInTier(id) return (id - 1) % R.PER_TIER + 1 end

-- 0 whole, 1 small crack (25%), 2 clear crack (50%), 3 shaking with eyes (75%).
function R.crackStage(read_pages, pages)
    if not pages or pages <= 0 then return 0 end
    local pct = math.floor(read_pages * 100 / pages)
    if pct >= 75 then return 3 end
    if pct >= 50 then return 2 end
    if pct >= 25 then return 1 end
    return 0
end

-- Today's day number in local time (days since the epoch), and month number.
function R.today(now)
    local t = os.date("*t", now)
    return math.floor(os.time{ year = t.year, month = t.month, day = t.day, hour = 12 } / 86400)
end
function R.month(now)
    local t = os.date("*t", now)
    return t.year * 12 + t.month - 1
end

---------------------------------------------------------------------------
-- Page log: which pages of one book have been seen. A page counts once,
-- the first time any screen covering its middle is shown.
---------------------------------------------------------------------------
local PageLog = {}
PageLog.__index = PageLog
R.PageLog = PageLog

function PageLog.new(pages)
    local self = setmetatable({}, PageLog)
    self:reset(pages)
    return self
end

function PageLog:reset(pages)
    self.n = math.max(0, math.min(math.floor(pages or 0), 60000))
    self.read = 0
    self.bytes = {}
    for i = 1, math.floor((self.n + 7) / 8) do self.bytes[i] = 0 end
end

function PageLog:isRead(page) -- page is 0-based
    if page < 0 or page >= self.n then return false end
    local b = self.bytes[bit.rshift(page, 3) + 1]
    return bit.band(bit.rshift(b, bit.band(page, 7)), 1) == 1
end

function PageLog:mark(page)
    if page < 0 or page >= self.n or self:isRead(page) then return 0 end
    local i = bit.rshift(page, 3) + 1
    self.bytes[i] = bit.bor(self.bytes[i], bit.lshift(1, bit.band(page, 7)))
    self.read = self.read + 1
    return 1
end

-- Marks the pages whose midpoints fall in [startf, endf) of the book
-- (fractions 0..1), plus the page holding startf. Returns how many were new.
function PageLog:markSpan(startf, endf)
    if self.n <= 0 then return 0 end
    startf = math.max(0, math.min(startf, 1))
    endf = math.max(startf, math.min(endf, 1))
    local n = self.n
    local added = self:mark(math.min(n - 1, math.floor(startf * n)))
    local first = math.max(0, math.floor(startf * n - 0.5))
    for i = first, n - 1 do
        local mid = (i + 0.5) / n
        if mid >= endf then break end
        if mid >= startf then added = added + self:mark(i) end
    end
    return added
end

function PageLog:serialize()
    local hex = {}
    for i = 1, #self.bytes do hex[i] = string.format("%02x", self.bytes[i]) end
    return { n = self.n, bits = table.concat(hex) }
end

function PageLog.deserialize(t)
    if type(t) ~= "table" or type(t.n) ~= "number" or type(t.bits) ~= "string" then return nil end
    local self = PageLog.new(t.n)
    if #t.bits ~= #self.bytes * 2 then return nil end
    for i = 1, #self.bytes do
        local b = tonumber(t.bits:sub(2 * i - 1, 2 * i), 16) or 0
        self.bytes[i] = b
        while b > 0 do
            self.read = self.read + bit.band(b, 1)
            b = bit.rshift(b, 1)
        end
    end
    return self
end

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
local function emptySlot() return { used = false } end

local function emptyCompanion()
    return { char = nil, day = -1, today_pages = 0, missed = 0, streak = 0,
             goal_met = false, ember = false, left_char = nil }
end

function R.newState()
    local s = {
        version = 1,
        hatched = {},   -- [id] = true
        fresh = {},     -- hatched, profile not opened yet ("MỚI")
        reserved = {},  -- from discarded eggs; hatch from the next egg of their tier
        slots = { emptySlot(), emptySlot(), emptySlot() },
        last_discard_month = -1,
        sleep_char = nil,
        companion = emptyCompanion(),
        rng = 0x4F4C5950,
    }
    return s
end

-- Fills in any fields missing from an older or hand-edited save.
function R.normalize(s)
    local fresh = R.newState()
    if type(s) ~= "table" then return fresh end
    for k, v in pairs(fresh) do
        if s[k] == nil or type(s[k]) ~= type(v) then s[k] = v end
    end
    for i = 1, R.SLOT_COUNT do
        if type(s.slots[i]) ~= "table" then s.slots[i] = emptySlot() end
    end
    for k, v in pairs(emptyCompanion()) do
        if s.companion[k] == nil and v ~= nil then s.companion[k] = v end
    end
    return s
end

function R.hatchedCount(s, tier)
    local n = 0
    local base = (tier - 1) * R.PER_TIER
    for i = 1, R.PER_TIER do
        if s.hatched[base + i] then n = n + 1 end
    end
    return n
end

function R.totalHatched(s)
    local n = 0
    for i = 1, R.TOTAL do
        if s.hatched[i] then n = n + 1 end
    end
    return n
end

function R.anyFresh(s)
    for i = 1, R.TOTAL do
        if s.fresh[i] then return true end
    end
    return false
end

function R.phase2(s) return R.totalHatched(s) >= R.TOTAL end

function R.usedSlots(s)
    local n = 0
    for i = 1, R.SLOT_COUNT do
        if s.slots[i].used then n = n + 1 end
    end
    return n
end

function R.slotForPath(s, path)
    for i = 1, R.SLOT_COUNT do
        if s.slots[i].used and s.slots[i].path == path then return i end
    end
    return nil
end

local function nextRandom(s)
    local x = s.rng ~= 0 and s.rng or 0x1E3779B9
    x = bit.bxor(x, bit.lshift(x, 13))
    x = bit.bxor(x, bit.rshift(x, 17))
    x = bit.bxor(x, bit.lshift(x, 5))
    s.rng = x
    -- bit ops return signed 32-bit numbers; make it non-negative
    return x % 0x7FFFFFFF
end

local function inAnySlot(s, id)
    for i = 1, R.SLOT_COUNT do
        if s.slots[i].used and s.slots[i].char == id then return true end
    end
    return false
end

-- Character hidden in a new egg of `tier`: a reserved one first, otherwise a
-- random one that is neither hatched nor already in an egg. nil when the tier is complete.
function R.pickCharacter(s, tier)
    local base = (tier - 1) * R.PER_TIER
    local candidates = {}
    for pass = 1, 2 do
        for i = 1, R.PER_TIER do
            local id = base + i
            if not s.hatched[id] and not inAnySlot(s, id) and ((pass == 1) == (s.reserved[id] == true)) then
                table.insert(candidates, id)
            end
        end
        if #candidates > 0 then break end
    end
    if #candidates == 0 then return nil end
    return candidates[nextRandom(s) % #candidates + 1]
end

-- Places a book. read_pages: progress already made (counts toward the egg).
-- Returns result, slot. result: "placed", "placed_empty", "already", "full", "closed", "bad".
function R.placeBook(s, path, pages, read_pages, today)
    if R.phase2(s) then return "closed" end
    if not path or path == "" or not pages or pages <= 0 then return "bad" end
    local existing = R.slotForPath(s, path)
    if existing then return "already", existing end
    local free
    for i = 1, R.SLOT_COUNT do
        if not s.slots[i].used then free = i break end
    end
    if not free then return "full" end
    local tier = R.tierForPages(pages)
    local slot = {
        used = true,
        tier = tier,
        pages = math.min(math.floor(pages), 60000),
        read_pages = math.max(0, math.min(math.floor(read_pages or 0), pages)),
        last_read_day = today,
        path = path,
    }
    slot.char = R.pickCharacter(s, tier)
    s.slots[free] = slot
    if slot.char then s.reserved[slot.char] = nil end
    return slot.char and "placed" or "placed_empty", free
end

-- No limit: an egg can be discarded any time. Its character stays reserved for its tier.
function R.discardSlot(s, i, month)
    local slot = s.slots[i]
    if not slot or not slot.used then return false end
    if slot.char then s.reserved[slot.char] = true end
    s.slots[i] = emptySlot()
    s.last_discard_month = month or -1
    return true
end

function R.isColdEgg(slot, today)
    return slot.used and today and today >= 0 and slot.last_read_day and slot.last_read_day >= 0
        and today - slot.last_read_day >= R.COLD_EGG_DAYS
end

-- Records the incubating book's progress: read_pages is the reading position in
-- game pages (follows the reader back and forth), new_pages the pages seen for
-- the first time. The egg hatches when at_end is true (>= 95% or last page).
-- Returns a hatch event table or nil.
function R.noteSlotPages(s, i, new_pages, read_pages, at_end, today)
    local slot = s.slots[i]
    if not slot or not slot.used then return nil end
    slot.read_pages = math.max(0, math.min(math.floor(read_pages), slot.pages))
    if new_pages > 0 and today and today >= 0 then slot.last_read_day = today end
    if not at_end then return nil end
    local ev = {
        char = slot.char,
        tier = slot.tier,
        empty = slot.char == nil,
        book_path = slot.path,
        book_pages = slot.pages,
        tier_completed = false,
        all_completed = false,
    }
    if not ev.empty then
        s.hatched[slot.char] = true
        s.fresh[slot.char] = true
        s.reserved[slot.char] = nil
        ev.tier_completed = R.hatchedCount(s, slot.tier) == R.PER_TIER
    end
    s.slots[i] = emptySlot()
    if R.phase2(s) then
        ev.all_completed = not ev.empty
        -- The incubator closes for good.
        for k = 1, R.SLOT_COUNT do s.slots[k] = emptySlot() end
    end
    return ev
end

---------------------------------------------------------------------------
-- Companion (the character on the sleep screen)
---------------------------------------------------------------------------
function R.isCompanionBook(s, book_pages)
    local c = s.companion
    -- Any book feeds the companion; only the number of pages depends on its tier.
    return c.char ~= nil and book_pages and book_pages > 0 and true or false
end

-- Daily bookkeeping. today < 0 means the clock is unknown.
function R.rollover(s, today)
    local c = s.companion
    if not today or today < 0 then return end
    if c.char == nil or c.day < 0 then
        c.day = today
        return
    end
    if today <= c.day then return end -- same day, or the clock went back
    local missed_now = (c.goal_met and 0 or 1) + (today - c.day - 1)
    c.day = today
    c.today_pages = 0
    c.goal_met = false
    if missed_now <= 0 then return end
    local total = c.missed + missed_now
    c.missed = math.min(total, R.MAX_MISSED_DAYS)
    if total < R.MAX_MISSED_DAYS then return end
    c.streak = 0
    if R.tierOf(c.char) == R.CLAY then
        c.left_char = c.char
        c.char = nil
        c.missed = 0
        if s.sleep_char == c.left_char then s.sleep_char = nil end
    else
        c.ember = true
    end
end

-- Pages read today from a book of `book_pages` pages. Returns true when this read met the goal.
function R.noteCompanionPages(s, book_pages, new_pages, today)
    if not today or today < 0 or new_pages <= 0 then return false end
    R.rollover(s, today)
    if not R.isCompanionBook(s, book_pages) then return false end
    local c = s.companion
    c.today_pages = math.min(c.today_pages + new_pages, 60000)
    if c.goal_met or c.today_pages < R.dailyGoal(R.tierOf(c.char)) then return false end
    c.goal_met = true
    c.missed = 0
    c.ember = false
    c.streak = c.streak + 1
    return true
end

function R.chooseCompanion(s, id, today)
    s.companion = emptyCompanion()
    s.companion.char = id
    s.companion.day = today or -1
    s.sleep_char = id
end

-- "happy", "hungry", "left", "blessing", "weak", "ember", or "none".
function R.companionMood(s)
    local c = s.companion
    if c.char == nil then return c.left_char and "left" or "none" end
    local behind = c.missed > 0 and not c.goal_met
    if R.tierOf(c.char) == R.CLAY then return behind and "hungry" or "happy" end
    if c.ember then return "ember" end
    return behind and "weak" or "blessing"
end

-- Food portions eaten today (clay): one per 5 pages, at most 4 shown.
function R.foodToday(s)
    return math.min(4, math.floor(s.companion.today_pages / R.PAGES_PER_FOOD))
end

return R
