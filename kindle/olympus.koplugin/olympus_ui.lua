--[[--
Olympus screens for KOReader: main screen, incubator, temple, character
profile, hatch, tier complete, companion status (also used as sleep screen).

Layout is designed on a 480x800 grid (the Xteink X4 Pro screen) and scaled by
U = min(width/480, height/800), so it fits any Kindle screen.
Everything is tap only (no swipes). Back key closes a screen.
--]]

local L = require("olympus_i18n").L
local Blitbuffer = require("ffi/blitbuffer")
local ConfirmBox = require("ui/widget/confirmbox")
local Device = require("device")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local FrameContainer = require("ui/widget/container/framecontainer")
local InputContainer = require("ui/widget/container/inputcontainer")
local ProgressWidget = require("ui/widget/progresswidget")
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local Widget = require("ui/widget/widget")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local Screen = Device.screen

local Art = require("olympus_art")
local R = require("olympus_rules")
local Store = require("olympus_store")

local BLACK = Blitbuffer.COLOR_BLACK
local WHITE = Blitbuffer.COLOR_WHITE
local GRAY = Blitbuffer.COLOR_DARK_GRAY
local LIGHT = Blitbuffer.COLOR_LIGHT_GRAY

local UI = {}

---------------------------------------------------------------------------
-- Geometry: W, H of the target surface and the design unit U.
---------------------------------------------------------------------------
local W, H, U = 480, 800, 1

local function setGeom(w, h)
    W, H = w, h
    U = math.min(W / 480, H / 800)
end

local function px(n) return math.max(1, math.floor(n * U + 0.5)) end

-- Bundled fonts (fonts/): Alegreya for text, Cormorant SC for titles and names.
-- Falls back to KOReader's UI fonts if a file is missing.
local FONT_FILES = { body = "Alegreya-Regular.ttf", bold = "Alegreya-Bold.ttf", display = "CormorantSC-Bold.ttf" }
local font_ok = {}
local function fontPath(kind)
    local dir = UI.font_dir
    if not dir then return nil end
    local path = dir .. FONT_FILES[kind]
    if font_ok[path] == nil then
        local f = io.open(path, "rb")
        font_ok[path] = f ~= nil
        if f then f:close() end
    end
    return font_ok[path] and path or nil
end

-- Returns the face and whether KOReader should still embolden it.
-- kind: nil (regular/bold body text) or "display".
local function face(size, bold, kind)
    local dpi_scale = Screen:scaleBySize(1000) / 1000
    local s = math.max(7, math.floor(size * U / dpi_scale + 0.5))
    local path = fontPath(kind == "display" and "display" or (bold and "bold" or "body"))
    -- Alegreya runs small next to KOReader's sans fonts: nudge body text up.
    if path and kind ~= "display" then s = math.floor(s * 1.12 + 0.5) end
    if path then return Font:getFace(path, s), false end
    return Font:getFace(bold and "tfont" or "cfont", s), bold
end

---------------------------------------------------------------------------
-- Small building blocks
---------------------------------------------------------------------------

-- Fixed-size box that aligns its single child.
local Box = WidgetContainer:extend{ w = 0, h = 0, halign = "center", valign = "center" }
function Box:getSize() return Geom:new{ w = self.w, h = self.h } end
function Box:paintTo(bb, x, y)
    self.dimen = Geom:new{ x = x, y = y, w = self.w, h = self.h }
    local c = self[1]
    if not c then return end
    local s = c:getSize()
    local cx = self.halign == "left" and 0 or (self.halign == "right" and self.w - s.w or math.floor((self.w - s.w) / 2))
    local cy = self.valign == "top" and 0 or (self.valign == "bottom" and self.h - s.h or math.floor((self.h - s.h) / 2))
    c:paintTo(bb, x + cx, y + cy)
end

local function box(w, h, child, halign, valign)
    return Box:new{ w = math.floor(w), h = math.floor(h), halign = halign, valign = valign, child }
end

-- Tappable area around a widget.
local Tap = InputContainer:extend{ on_tap = nil, on_hold = nil }
function Tap:init()
    local range = function() return self.dimen end
    self.ges_events = {
        TapSelect = { GestureRange:new{ ges = "tap", range = range } },
    }
    if self.on_hold then
        self.ges_events.HoldSelect = { GestureRange:new{ ges = "hold", range = range } }
    end
end
function Tap:onTapSelect()
    if self.on_tap then UIManager:nextTick(self.on_tap) end
    return true
end
function Tap:onHoldSelect()
    if self.on_hold then UIManager:nextTick(self.on_hold) end
    return true
end

local function tap(widget, on_tap, on_hold)
    return Tap:new{ on_tap = on_tap, on_hold = on_hold, widget }
end

local function text(str, size, bold, max_w, color, kind)
    local f, b = face(size, bold, kind)
    return TextWidget:new{ text = str, face = f, bold = b, max_width = max_w and math.floor(max_w),
                           fgcolor = color or BLACK }
end

local function para(str, size, w, align, bold, color, bg)
    local f, b = face(size, bold)
    return TextBoxWidget:new{ text = str, face = f, bold = b, width = math.floor(w),
                              alignment = align or "left", fgcolor = color or BLACK, bgcolor = bg or WHITE }
end

local function vspace(n) return VerticalSpan:new{ width = px(n) } end
local function hspace(n) return HorizontalSpan:new{ width = px(n) } end

-- Frame of exact outer size w x h around a child aligned inside.
local function card(w, h, child, opts)
    opts = opts or {}
    local b = opts.border or px(2)
    local pad = opts.pad or 0
    return FrameContainer:new{
        bordersize = b, padding = 0, margin = 0,
        radius = opts.radius or px(10),
        color = opts.color or BLACK,
        background = opts.bg or WHITE,
        box(w - 2 * b, h - 2 * b, opts.pad and FrameContainer:new{ bordersize = 0, padding = pad, child } or child,
            opts.halign, opts.valign),
    }
end

-- Left and right text on one row of width w.
local function row(left, right, w)
    local lw = left:getSize().w
    local rw = right and right:getSize().w or 0
    return HorizontalGroup:new{ align = "center", left, HorizontalSpan:new{ width = math.max(0, w - lw - rw) }, right }
end

-- Pill label: black with white text, or outlined.
local function pill(str, size, inverted)
    return FrameContainer:new{
        bordersize = px(1.5), radius = px(8), padding = 0,
        padding_left = px(7), padding_right = px(7), padding_top = 0, padding_bottom = 0,
        background = inverted and BLACK or WHITE,
        text(str, size, true, nil, inverted and WHITE or BLACK),
    }
end

-- A button: outlined, or black when primary. Tap only.
local function button(str, w, on_tap, primary, enabled)
    if enabled == nil then enabled = true end
    local h = px(36)
    local b = px(2)
    local label = text(str, 15, true, w - px(12), primary and WHITE or (enabled and BLACK or GRAY))
    local frame = FrameContainer:new{
        bordersize = b, padding = 0, radius = px(8),
        background = primary and BLACK or WHITE,
        color = enabled and BLACK or GRAY,
        box(w - 2 * b, h - 2 * b, label),
    }
    if not enabled then return frame end
    return tap(frame, on_tap)
end

-- Greek key (meander) border line.
local Meander = Widget:extend{ w = 0, h = 0 }
function Meander:getSize() return Geom:new{ w = self.w, h = self.h } end
function Meander:paintTo(bb, x, y)
    self.dimen = Geom:new{ x = x, y = y, w = self.w, h = self.h }
    local h = self.h
    local t = math.max(1, math.floor(h / 6))
    bb:paintRect(x, y, self.w, t, BLACK)
    bb:paintRect(x, y + h - t, self.w, t, BLACK)
    local step = h
    local inner = h - 4 * t
    local xx = x
    while xx + step <= x + self.w do
        -- one key: a hook rising from the bottom line
        local k = math.floor(step * 0.6)
        bb:paintRect(xx, y + 2 * t, t, inner, BLACK)
        bb:paintRect(xx, y + 2 * t, k, t, BLACK)
        bb:paintRect(xx + k - t, y + 2 * t, t, inner - t, BLACK)
        bb:paintRect(xx + math.floor(k / 2) - t, y + h - 3 * t, math.floor(k / 2), t, BLACK)
        bb:paintRect(xx + math.floor(k / 2) - t, y + 3 * t + math.floor(inner / 3), t, h - 6 * t - math.floor(inner / 3), BLACK)
        xx = xx + step
    end
end
local function meander(w) return Meander:new{ w = math.floor(w), h = px(12) } end

-- Missed-day dots: filled for missed days.
local Dots = Widget:extend{ n = 3, filled = 0, r = 6 }
function Dots:getSize() return Geom:new{ w = self.n * (2 * self.r + self.r), h = 2 * self.r + 2 } end
function Dots:paintTo(bb, x, y)
    self.dimen = Geom:new{ x = x, y = y, w = self:getSize().w, h = self:getSize().h }
    for i = 1, self.n do
        local cx = x + self.r + (i - 1) * 3 * self.r
        local cy = y + self.r + 1
        if i <= self.filled then
            bb:paintCircle(cx, cy, self.r, BLACK)
        else
            bb:paintCircle(cx, cy, self.r, BLACK, math.max(1, math.floor(self.r / 3)))
        end
    end
end

-- Ring of dots (tier complete).
local DotRing = Widget:extend{ size = 100 }
function DotRing:getSize() return Geom:new{ w = self.size, h = self.size } end
function DotRing:paintTo(bb, x, y)
    self.dimen = Geom:new{ x = x, y = y, w = self.size, h = self.size }
    local r = self.size / 2
    local dot = math.max(2, math.floor(self.size / 50))
    for i = 0, 47 do
        local a = i / 48 * 2 * math.pi
        bb:paintCircle(math.floor(x + r + (r - dot - 1) * math.cos(a)), math.floor(y + r + (r - dot - 1) * math.sin(a)), dot, BLACK)
    end
end

local Line = Widget:extend{ w = 0, h = 2 }
function Line:getSize() return Geom:new{ w = self.w, h = self.h } end
function Line:paintTo(bb, x, y) bb:paintRect(x, y, self.w, self.h, BLACK) end
local function hline(w, thick) return Line:new{ w = math.floor(w), h = thick or px(2) } end

local function progressBar(w, frac)
    return ProgressWidget:new{
        width = math.floor(w), height = px(12),
        percentage = math.max(0, math.min(frac or 0, 1)),
        margin_h = 0, margin_v = 0, radius = px(3), bordersize = px(1.5),
        fillcolor = BLACK, bgcolor = WHITE,
    }
end

-- Character art: sprite of a hatched character, or the locked silhouette.
local function charArt(id, size, locked)
    if locked then return Art.widget("locked", size) end
    return Art.widget(Store.char(id).key, size)
end

---------------------------------------------------------------------------
-- Base full-screen window
---------------------------------------------------------------------------
UI.open_windows = setmetatable({}, { __mode = "k" })

local Window = InputContainer:extend{
    covers_fullscreen = true,
    plugin = nil,
}

function Window:init()
    UI.open_windows[self] = true
    if Device:hasKeys() then
        self.key_events.Close = { { Device.input.group.Back } }
    end
    self:rebuild()
end

function Window:rebuild()
    setGeom(Screen:getWidth(), Screen:getHeight())
    self.dimen = Geom:new{ x = 0, y = 0, w = W, h = H }
    local content = self:build()
    self[1] = FrameContainer:new{
        bordersize = 0, padding = 0, margin = 0, background = WHITE,
        box(W, H, content, "center", "top"),
    }
end

function Window:refresh()
    self:rebuild()
    UIManager:setDirty(self, "ui")
end

function Window:onClose()
    UI.open_windows[self] = nil
    UIManager:close(self, "ui")
    if self.on_close then self.on_close() end
    return true
end

-- Standard page: header + body (given its height) + footer buttons.
-- header_fn(w) returns header widget; body_fn(w, h) the body; footer: list of {text, cb, primary, enabled}.
function Window:page(header, body_fn, footer)
    local M = px(20)
    local inner = W - 2 * M
    local top = VerticalGroup:new{ align = "left", vspace(14), header }
    local foot = HorizontalGroup:new{ align = "center" }
    local n = #footer
    local bw = n == 1 and px(150) or math.floor((inner - px(8) * (n - 1)) / n)
    for i, f in ipairs(footer) do
        if i > 1 then table.insert(foot, hspace(8)) end
        table.insert(foot, button(f[1], f.width or bw, f[2], f[3], f[4]))
    end
    local foot_h = px(36) + px(24)
    local body_h = H - top:getSize().h - foot_h - px(8)
    return HorizontalGroup:new{
        hspace(20),
        VerticalGroup:new{
            align = "left",
            top,
            vspace(8),
            box(inner, body_h, body_fn(inner, body_h), "center", "top"),
            box(inner, foot_h, foot, "center", "center"),
        },
    }
end

-- Title row: big title left, small text right, optional subtitle, meander line.
local function header(w, title, right, subtitle, icon)
    local left = HorizontalGroup:new{ align = "center" }
    if icon then
        table.insert(left, Art.widget(icon, px(40)))
        table.insert(left, hspace(8))
    end
    local tg = VerticalGroup:new{ align = "left", text(title, 26, true) }
    if subtitle then table.insert(tg, text(subtitle, 12, false, w - px(60))) end
    table.insert(left, tg)
    local g = VerticalGroup:new{ align = "left",
        row(left, right and text(right, 15, true) or nil, w),
        vspace(6),
        meander(w),
    }
    return g
end

---------------------------------------------------------------------------
-- Main screen (Olympus hub)
---------------------------------------------------------------------------
local Hub = Window:extend{}
UI.Hub = Hub

local function incubatorSummary(s)
    local best = 0
    for i = 1, R.SLOT_COUNT do
        local sl = s.slots[i]
        if sl.used and sl.pages > 0 then best = math.max(best, math.floor(sl.read_pages * 100 / sl.pages)) end
    end
    local used = R.usedSlots(s)
    if used == 0 then return L("Lò ấp đang trống") end
    return string.format(L("%d/3 ô đang ấp · gần nở nhất %d%%"), used, best)
end

local function companionSummary(s)
    local c = s.companion
    if c.char then
        local ch = Store.char(c.char)
        local tier = R.tierOf(c.char)
        local word = tier == R.CLAY and L("nuôi") or (c.ember and L("đuốc tàn,") or L("đuốc cháy"))
        return string.format(L("%s · %s %d ngày · %d/%d trang"), ch.name, word, c.streak, c.today_pages, R.dailyGoal(tier))
    elseif c.left_char then
        return string.format(L("%s đã về Đền thờ"), Store.char(c.left_char).name)
    end
    return L("Chưa có. Vào Đền thờ để chọn một nhân vật.")
end

function Hub:build()
    local s = Store.refreshDay()
    local total = R.totalHatched(s)
    local phase2 = R.phase2(s)
    local hdr_right = phase2 and string.format(L("%d/90 · Đã sưu tầm đủ"), total) or string.format(L("%d/90 nhân vật"), total)
    local hdr = header(W - 2 * px(20), "Olympus", nil, hdr_right, "logo_96")
    return self:page(hdr, function(w, h)
        local g = VerticalGroup:new{ align = "center" }
        local has_comp = s.companion.char or s.companion.left_char
        local cards = phase2 and 2 or (has_comp and 3 or 2)
        local card_h = math.min(px(170), math.floor((h - px(110)) / cards) - px(14))
        local function bigCard(icon_widget, title, sub, badge, cb)
            local tw = w - px(40) - icon_widget:getSize().w - px(16)
            local tg = VerticalGroup:new{ align = "left", text(title, 24, true), vspace(4), para(sub, 13, tw) }
            if badge then table.insert(tg, vspace(4)); table.insert(tg, pill(badge, 11, true)) end
            local content = HorizontalGroup:new{ align = "center", icon_widget, hspace(16), tg }
            return tap(card(w, card_h, content, { halign = "left", pad = px(16) }), cb)
        end
        local icon = math.min(px(96), card_h - px(30))
        -- Card 1: incubator (phase 1) or companion (phase 2)
        if not phase2 then
            local eggs = HorizontalGroup:new{ align = "bottom" }
            for i = 1, R.SLOT_COUNT do
                local sl = s.slots[i]
                if sl.used then
                    local cold = R.isColdEgg(sl, Store.today())
                    table.insert(eggs, Art.widget(Art.eggName(sl.tier, R.crackStage(sl.read_pages, sl.pages), cold), math.floor(icon * 0.5)))
                end
            end
            if #eggs == 0 then table.insert(eggs, Art.widget("egg_clay_0", math.floor(icon * 0.6))) end
            table.insert(g, bigCard(eggs, L("Lò ấp"), incubatorSummary(s), nil, function() UI.show(UI.Incubator) end))
            table.insert(g, vspace(14))
        end
        if phase2 or has_comp then
            local cid = s.companion.char or s.companion.left_char
            local cicon = s.companion.char and Art.widget(Store.char(cid).key, icon) or Art.widget("logo_96", icon)
            table.insert(g, bigCard(cicon, L("Bạn đồng hành"), companionSummary(s), nil, function() UI.show(UI.Companion) end))
            table.insert(g, vspace(14))
        end
        local fresh = 0
        for id = 1, R.TOTAL do if s.fresh[id] then fresh = fresh + 1 end end
        local tsub = phase2 and L("Bộ sưu tập 90/90 · chọn bạn đồng hành")
            or (fresh > 0 and string.format(L("Bộ sưu tập · %d/90 · có %d nhân vật mới"), total, fresh)
                or string.format(L("Bộ sưu tập · %d/90"), total))
        table.insert(g, bigCard(Art.widget("logo_96", icon), L("Đền thờ"), tsub, fresh > 0 and L("MỚI") or nil,
            function() UI.show(UI.Temple) end))
        table.insert(g, vspace(14))
        local hint = phase2 and L("Đã đủ 90 nhân vật nên Lò ấp đã đóng. Vào Đền thờ để đổi bạn đồng hành.")
            or L("Muốn ấp thêm trứng: chạm một ô trống trong Lò ấp, hoặc trong Thư viện nhấn giữ một cuốn sách và chọn \"Đặt vào lò ấp\".")
        table.insert(g, card(w, px(80), para(hint, 12, w - px(32)), { border = px(1), pad = px(14), halign = "left" }))
        return g
    end, { { L("Quay lại"), function() self:onClose() end } })
end

---------------------------------------------------------------------------
-- Incubator
---------------------------------------------------------------------------
local Incubator = Window:extend{}
UI.Incubator = Incubator

local function pagesToNext(sl)
    local stage = R.crackStage(sl.read_pages, sl.pages)
    if stage >= 3 then
        return string.format(L("Còn %d trang để nở"), math.max(0, math.ceil(sl.pages * R.HATCH_AT) - sl.read_pages))
    end
    local target = math.ceil(sl.pages * (stage + 1) * 25 / 100)
    return string.format(L("Còn %d trang tới vết nứt"), math.max(1, target - sl.read_pages))
end

function Incubator:build()
    local s = Store.refreshDay()
    local hdr = header(W - 2 * px(20), L("Lò ấp"), nil, L("Chỉ trang đọc trong 3 cuốn này mới làm trứng nứt"))
    return self:page(hdr, function(w, h)
        local g = VerticalGroup:new{ align = "center" }
        if R.phase2(s) then
            table.insert(g, vspace(40))
            table.insert(g, para(L("Đã đủ 90 nhân vật nên Lò ấp đã đóng. Vào Đền thờ để đổi bạn đồng hành."), 16, w, "center"))
            return g
        end
        local ch = math.min(px(190), math.floor((h - 2 * px(12)) / 3))
        local today = Store.today()
        for i = 1, R.SLOT_COUNT do
            local sl = s.slots[i]
            if i > 1 then table.insert(g, vspace(12)) end
            if sl.used then
                local egg_size = math.min(ch - px(24), px(120))
                local stage = R.crackStage(sl.read_pages, sl.pages)
                local cold = R.isColdEgg(sl, today)
                local tw = w - egg_size - px(48)
                local pct = sl.pages > 0 and math.floor(sl.read_pages * 100 / sl.pages) or 0
                local info = VerticalGroup:new{ align = "left",
                    pill(Store.TIER_EGG_UPPER[sl.tier], 10, true), vspace(4),
                    text(Store.bookTitle(sl.path), 17, true, tw),
                    text(string.format(L("%d trang"), sl.pages), 11, false, tw), vspace(6),
                    progressBar(tw, sl.pages > 0 and sl.read_pages / sl.pages or 0), vspace(4),
                    text(string.format(L("%d%%  ·  trang %d/%d"), pct, sl.read_pages, sl.pages), 14, true, tw),
                    text(pagesToNext(sl), 11, false, tw),
                }
                if sl.char == nil then
                    table.insert(info, text(L("Đã đủ bộ: trứng này không nở ra gì"), 11, true, tw))
                elseif cold then
                    table.insert(info, text(string.format(L("Trứng nguội: %d ngày chưa đọc"), today - sl.last_read_day), 11, true, tw))
                end
                local content = HorizontalGroup:new{ align = "center",
                    Art.widget(Art.eggName(sl.tier, stage, cold), egg_size), hspace(12), info }
                table.insert(g, tap(card(w, ch, content, { halign = "left", pad = px(10) }),
                    function() self.plugin:openBook(sl.path) end,
                    function() self:askDiscard(i) end))
            else
                local content = VerticalGroup:new{ align = "center",
                    text("+", 30, true),
                    text(L("Ô trống · Đặt sách vào lò ấp"), 15, true, w - px(20)),
                    text(L("Chạm để chọn sách trong thư viện"), 11, false, w - px(20)),
                }
                table.insert(g, tap(card(w, ch, content, { color = GRAY, border = px(2) }),
                    function() self.plugin:chooseBook() end))
            end
        end
        return g
    end, { { L("Quay lại"), function() self:onClose() end } })
end

function Incubator:askDiscard(i)
    local s = Store.get()
    local sl = s.slots[i]
    if not sl or not sl.used then return end
    UIManager:show(ConfirmBox:new{
        text = string.format(L("Bỏ trứng?\n\nTrứng của \"%s\" sẽ mất. Nhân vật trong trứng được giữ chỗ và sẽ nở từ quả trứng tiếp theo cùng bậc."),
            Store.bookTitle(sl.path)),
        ok_text = L("Bỏ trứng"),
        cancel_text = L("Huỷ"),
        ok_callback = function()
            R.discardSlot(s, i, Store.month())
            Store.save()
            self:refresh()
        end,
    })
end

---------------------------------------------------------------------------
-- Temple (collection)
---------------------------------------------------------------------------
local Temple = Window:extend{ tier = 1, page_no = 1 }
UI.Temple = Temple

function Temple:build()
    local s = Store.get()
    local total = R.totalHatched(s)
    local hdr = header(W - 2 * px(20), L("Đền thờ"), string.format("%d/90", total))
    return self:page(hdr, function(w, h)
        local g = VerticalGroup:new{ align = "center" }
        -- Tabs
        local tabs = HorizontalGroup:new{ align = "center" }
        local tab_w = math.floor((w - 2 * px(8)) / 3)
        for t = 1, 3 do
            if t > 1 then table.insert(tabs, hspace(8)) end
            local label = string.format("%s %d/30", Store.TIER_TAB[t], R.hatchedCount(s, t))
            local sel = t == self.tier
            local f = FrameContainer:new{ bordersize = px(2), radius = px(8), padding = 0,
                background = sel and BLACK or WHITE,
                box(tab_w - 2 * px(2), px(34), text(label, 14, true, tab_w - px(10), sel and WHITE or BLACK)) }
            table.insert(tabs, tap(f, function() self.tier = t; self.page_no = 1; self:refresh() end))
        end
        table.insert(g, tabs)
        table.insert(g, vspace(10))
        -- Grid
        local cols = W > H and 6 or 4
        local gap = px(8)
        local cw = math.floor((w - gap * (cols - 1)) / cols)
        local chh = math.floor(cw * 1.3)
        local nav_h = px(44)
        local rows = math.max(1, math.floor((h - px(44) - nav_h + gap) / (chh + gap)))
        local per = cols * rows
        local pages = math.ceil(R.PER_TIER / per)
        self.page_no = math.max(1, math.min(self.page_no, pages))
        local first = (self.page_no - 1) * per + 1
        local base = (self.tier - 1) * R.PER_TIER
        for r = 0, rows - 1 do
            local hg = HorizontalGroup:new{ align = "top" }
            for c = 0, cols - 1 do
                local idx = first + r * cols + c
                if c > 0 then table.insert(hg, HorizontalSpan:new{ width = gap }) end
                if idx <= R.PER_TIER then
                    table.insert(hg, self:cell(s, base + idx, cw, chh))
                else
                    table.insert(hg, HorizontalSpan:new{ width = cw })
                end
            end
            if first + r * cols <= R.PER_TIER then
                table.insert(g, hg)
                table.insert(g, VerticalSpan:new{ width = gap })
            end
        end
        if pages > 1 then
            local prev = self.page_no > 1 and button(L("‹ Trước"), px(110), function() self.page_no = self.page_no - 1; self:refresh() end)
                or HorizontalSpan:new{ width = px(110) }
            local nxt = self.page_no < pages and button(L("Sau ›"), px(110), function() self.page_no = self.page_no + 1; self:refresh() end)
                or HorizontalSpan:new{ width = px(110) }
            local mid = box(w - 2 * px(110), px(36), text(string.format(L("Trang %d/%d"), self.page_no, pages), 13))
            table.insert(g, HorizontalGroup:new{ align = "center", prev, mid, nxt })
        end
        return g
    end, { { L("Quay lại"), function() self:onClose() end } })
end

function Temple:cell(s, id, cw, chh)
    local hatched = s.hatched[id]
    local is_comp = s.companion.char == id
    local num = text(Store.number(id), 10, true)
    local top
    if s.fresh[id] then
        local p = pill(L("MỚI"), 8, true)
        local gap = math.max(0, cw - px(10) - num:getSize().w - p:getSize().w)
        top = HorizontalGroup:new{ align = "center", num, HorizontalSpan:new{ width = gap }, p }
    else
        top = HorizontalGroup:new{ align = "center", num }
    end
    local name_h = px(18)
    local art = math.max(px(20), math.min(cw - px(10), chh - px(10) - top:getSize().h - name_h))
    local content = VerticalGroup:new{ align = "center",
        box(cw - px(10), top:getSize().h, top, "left"),
        charArt(id, art, not hatched),
        text(hatched and Store.char(id).name or "???", 10, hatched, cw - px(8)),
    }
    return tap(card(cw, chh, content, { border = is_comp and px(3) or px(1), radius = px(6), valign = "center" }),
        function() UI.show(UI.Profile, { char = id, from_temple = self }) end)
end

---------------------------------------------------------------------------
-- Character profile
---------------------------------------------------------------------------
local Profile = Window:extend{ char = 1 }
UI.Profile = Profile

function Profile:build()
    local s = Store.get()
    local id = self.char
    local ch = Store.char(id)
    local tier = R.tierOf(id)
    local hatched = s.hatched[id]
    if hatched and s.fresh[id] then
        s.fresh[id] = nil
        Store.save()
        if self.from_temple then self.from_temple.dirty_on_return = true end
    end
    local M = px(20)
    local w = W - 2 * M
    local hdr = VerticalGroup:new{ align = "left",
        row(text(Store.number(id), 15, true), text(Store.TIER_EGG_UPPER[tier] .. " · " .. Store.TIER_KIND_UPPER[tier], 11), w) }
    local footer = { { L("Quay lại"), function() self:onClose() end } }
    if hatched then
        local on_screen = s.companion.char == id
        table.insert(footer, { on_screen and L("Đang ở màn chờ") or L("Đặt làm màn chờ"), function() self:askCompanion() end,
            not on_screen, not on_screen })
    end
    return self:page(hdr, function(bw, bh)
        local details = VerticalGroup:new{ align = "left" }
        local function section(label, body)
            if not body or body == "" then return end
            table.insert(details, text(label, 11, true))
            table.insert(details, para(body, 12, bw))
            table.insert(details, vspace(4))
        end
        local title, sub
        if hatched then
            title = ch.name
            sub = Store.TIER_KIND[tier] .. " · " .. Store.TIER_EGG[tier]
            section(L("XUẤT THÂN"), ch.origin)
            section(L("KHẢ NĂNG"), ch.ability)
            section(L("BIỂU TƯỢNG"), ch.symbols)
            section(L("THẦN THOẠI"), ch.myth)
            if tier ~= R.CLAY then section(L("LỜI BAN PHƯỚC"), ch.blessing) end
        else
            title = "???"
            sub = L("Chưa nở")
            local hint = VerticalGroup:new{ align = "left", text(L("GỢI Ý"), 11, true), para("“" .. ch.hint .. "”", 14, bw - px(28)) }
            table.insert(details, card(bw, hint:getSize().h + px(28), hint, { pad = px(14), halign = "left" }))
            table.insert(details, vspace(10))
            local left = R.PER_TIER - R.hatchedCount(s, tier)
            table.insert(details, para(string.format(L("Nở từ %s (sách %s). Bạn còn %d nhân vật chưa gặp ở bậc này."),
                Store.TIER_EGG[tier], Store.TIER_RANGE[tier], left), 12, bw))
        end
        local name_g = VerticalGroup:new{ align = "center", text(title, 28, true, bw), text(sub, 12) }
        local art = math.floor(math.min(bw * 0.6, bh - details:getSize().h - name_g:getSize().h - px(16)))
        art = math.max(px(64), art)
        return VerticalGroup:new{ align = "center",
            charArt(id, art, not hatched),
            name_g,
            vspace(10),
            box(bw, details:getSize().h, details, "left", "top"),
        }
    end, footer)
end

function Profile:askCompanion()
    local s = Store.get()
    local id = self.char
    local tier = R.tierOf(id)
    local ch = Store.char(id)
    UIManager:show(ConfirmBox:new{
        text = string.format(L("Đặt %s làm màn chờ?"), ch.name) .. "\n\n" .. string.format(
            L("Nhân vật sẽ thành bạn đồng hành. Chỉ tính sách %s, mục tiêu %d trang mỗi ngày. Bạn đồng hành cũ về lại đền, chuỗi ngày bắt đầu từ 0."),
            Store.TIER_RANGE[tier], R.dailyGoal(tier)),
        ok_text = L("Đặt"),
        cancel_text = L("Huỷ"),
        ok_callback = function()
            R.chooseCompanion(s, id, Store.today())
            Store.save()
            G_reader_settings:makeTrue("olympus_sleep_screen")
            self:refresh()
            if self.plugin then self.plugin:onCompanionChanged() end
        end,
    })
end

function Profile:onClose()
    UIManager:close(self, "ui")
    if self.from_temple then self.from_temple:refresh() end
    return true
end

---------------------------------------------------------------------------
-- Hatch screen (shown over the reader)
---------------------------------------------------------------------------
local Hatch = Window:extend{ event = nil }
UI.Hatch = Hatch

function Hatch:build()
    local ev = self.event
    local s = Store.get()
    local M = px(20)
    local w = W - 2 * M
    local title = Store.bookTitle(ev.book_path)
    local hdr = VerticalGroup:new{ align = "center",
        box(w, px(40), text(ev.empty and L("Trứng đã mở") or L("Trứng đã nở!"), 28, true)),
        box(w, px(20), text(string.format(L("Bạn đã đọc xong \"%s\""), title), 12, false, w)),
        box(w, px(18), text(string.format(L("%d trang · %s"), ev.book_pages, Store.TIER_EGG[ev.tier]), 11)),
    }
    local footer
    if ev.empty then
        footer = { { L("Đọc tiếp"), function() self:onClose() end }, { L("Đền thờ"), function() self:goTemple() end, true } }
    else
        footer = {
            { L("Đọc tiếp"), function() self:onClose() end },
            { L("Xem hồ sơ"), function() self:goProfile() end, true },
            { L("Đền thờ"), function() self:goTemple() end },
        }
    end
    return self:page(hdr, function(bw, bh)
        if ev.empty then
            return VerticalGroup:new{ align = "center",
                vspace(20),
                Art.widget(Art.eggName(ev.tier, 4), math.floor(math.min(bw * 0.6, bh * 0.5))),
                vspace(16),
                para(string.format(L("Bộ %s đã đủ 30/30 nên quả trứng này không nở ra gì."), Store.TIER_TAB[ev.tier]), 15, bw, "center"),
            }
        end
        local ch = Store.char(ev.char)
        local banner_g = VerticalGroup:new{ align = "center",
            text(string.format(L("%s gia nhập Đền thờ"), ch.name), 17, true, bw - px(20), WHITE),
            text(string.format("%s · %s %d/30", Store.number(ev.char), Store.TIER_EGG[ev.tier], R.hatchedCount(s, ev.tier)), 11, false, nil, WHITE),
        }
        local banner = card(bw * 0.85, banner_g:getSize().h + px(20), banner_g, { bg = BLACK })
        local shell = math.floor(math.min(px(96), bh * 0.15))
        local art = math.floor(math.min(bw * 0.75, bh - banner:getSize().h - shell - px(30)))
        return VerticalGroup:new{ align = "center",
            Art.widget(ch.key, art),
            Art.widget(Art.eggName(ev.tier, 4), shell),
            vspace(10),
            banner,
        }
    end, footer)
end

function Hatch:goProfile()
    local id = self.event.char
    self:onClose()
    UI.show(UI.Profile, { char = id })
end

function Hatch:goTemple()
    local tier = self.event.tier
    self:onClose()
    UI.show(UI.Temple, { tier = tier })
end

function Hatch:onClose()
    UIManager:close(self, "ui")
    local ev = self.event
    if (ev.tier_completed or ev.all_completed) and not self.completion_shown then
        self.completion_shown = true
        UI.show(UI.TierComplete, { event = ev })
    end
    return true
end

---------------------------------------------------------------------------
-- Tier complete
---------------------------------------------------------------------------
local TierComplete = Window:extend{ event = nil }
UI.TierComplete = TierComplete

function TierComplete:build()
    local ev = self.event
    local s = Store.get()
    local tier = ev.tier
    local w = W - 2 * px(20)
    return self:page(VerticalGroup:new{}, function(bw, bh)
        local ring = math.floor(math.min(bw * 0.55, bh * 0.35))
        local inside = VerticalGroup:new{ align = "center",
            text(ev.all_completed and "90/90" or "30/30", 30, true),
            text(Store.TIER_EGG_UPPER[tier], 12, true),
            text(Store.TIER_GROUP[tier], 11),
        }
        local g = VerticalGroup:new{ align = "center",
            vspace(20),
            require("ui/widget/overlapgroup"):new{
                dimen = Geom:new{ w = ring, h = ring },
                DotRing:new{ size = ring },
                box(ring, ring, inside),
            },
            vspace(20),
            text(string.format(L("Đã sưu tầm đủ bộ %s!"), Store.TIER_EGG[tier]), 17, true, bw),
            vspace(10),
        }
        -- A few faces of the completed tier
        local faces = HorizontalGroup:new{ align = "center" }
        local fs = math.floor(bw / 7)
        for i = 1, 6 do
            table.insert(faces, Art.widget(Store.char((tier - 1) * R.PER_TIER + i).key, fs))
        end
        table.insert(g, faces)
        table.insert(g, vspace(12))
        if ev.all_completed then
            table.insert(g, para(L("Đủ 90/90! Lò ấp đóng lại. Vào Đền thờ để chọn một bạn đồng hành và giữ thói quen đọc mỗi ngày."), 14, bw, "center"))
        else
            table.insert(g, para(string.format(L("Tất cả 30 nhân vật bậc này đã về Đền thờ. Từ giờ sách %s đặt vào lò ấp sẽ không nở thêm nhân vật."),
                Store.TIER_RANGE[tier]), 13, bw, "center"))
            table.insert(g, vspace(10))
            table.insert(g, text(string.format(L("Bộ còn thiếu: Đất sét %d · Bạc %d · Vàng %d"),
                30 - R.hatchedCount(s, 1), 30 - R.hatchedCount(s, 2), 30 - R.hatchedCount(s, 3)), 13, true, bw))
        end
        return g
    end, {
        { L("Đọc tiếp"), function() self:onClose() end },
        { L("Đền thờ"), function() UIManager:close(self, "ui"); UI.show(UI.Temple, { tier = tier }) end, true },
    })
end

---------------------------------------------------------------------------
-- Companion status: used as the sleep screen, and in the app.
---------------------------------------------------------------------------

-- God / Titan shrine: the character stands on a statue plinth with its name
-- carved in it, between two pillars topped by braziers. level: 2 = burning
-- (both lit), 1 = weak (one lit), 0 = ember (both burnt out).
local STONE = Blitbuffer.Color8(0xD8)
local STONE_DARK = Blitbuffer.Color8(0x99)
local Shrine = Widget:extend{ w = 0, art = 0, art_id = nil, name = "", level = 2 }
function Shrine:init()
    local a = self.art
    self.cap_h = math.max(4, math.floor(a * 0.06))
    self.body_h = math.max(18, math.floor(a * 0.22))
    self.base_h = math.max(4, math.floor(a * 0.06))
    self.feet_y = math.floor(a * 0.97)
    self.h = self.feet_y + self.cap_h + self.body_h + self.base_h
    self.label = text(self.name, 26, true, math.floor(a * 0.66), BLACK, "display")
    self.god = Art.widget(self.art_id, a)
    local fs = math.floor(a * 0.32)
    self.fs = fs
    local left = self.level >= 1 and (self.level == 2 and "flame_2" or "flame_1") or "flame_0"
    local right = self.level == 2 and "flame_2" or "flame_0"
    self.flames = { Art.widget(left, fs), Art.widget(right, fs) }
end
function Shrine:getSize() return Geom:new{ w = self.w, h = self.h } end
local function slab(bb, x, y, w, h, fill)
    bb:paintRect(x, y, w, h, fill)
    bb:paintBorder(x, y, w, h, math.max(2, math.floor(h / 8)), BLACK)
end
function Shrine:paintTo(bb, x, y)
    self.dimen = Geom:new{ x = x, y = y, w = self.w, h = self.h }
    local a, cx = self.art, x + math.floor(self.w / 2)
    local bw = px(2)
    -- pillars with braziers
    local col_w = math.floor(a * 0.17)
    local gap = math.floor(a * 0.10)
    local top = y + math.floor(a * 0.52)
    local bottom = y + self.h
    for i, side in ipairs({ -1, 1 }) do
        local px0 = side < 0 and (cx - math.floor(a / 2) - gap - col_w) or (cx + math.floor(a / 2) + gap)
        local capital = math.max(4, math.floor(a * 0.05))
        slab(bb, px0 - math.floor(col_w * 0.2), top, col_w + math.floor(col_w * 0.4), capital, STONE_DARK)
        bb:paintRect(px0, top + capital, col_w, bottom - top - 2 * capital, STONE)
        for k = 1, 3 do
            bb:paintRect(px0 + math.floor(col_w * k / 4), top + capital + bw, math.max(1, math.floor(bw / 2) + 1), bottom - top - 2 * capital - 2 * bw, STONE_DARK)
        end
        bb:paintBorder(px0, top + capital, col_w, bottom - top - 2 * capital, bw, BLACK)
        slab(bb, px0 - math.floor(col_w * 0.2), bottom - capital, col_w + math.floor(col_w * 0.4), capital, STONE_DARK)
        self.flames[i]:paintTo(bb, px0 + math.floor((col_w - self.fs) / 2), top - self.fs + math.floor(self.fs * 0.08))
    end
    -- plinth: cap, carved body with the name, base
    local yy = y + self.feet_y
    slab(bb, cx - math.floor(a * 0.44), yy, math.floor(a * 0.88), self.cap_h, STONE_DARK)
    yy = yy + self.cap_h
    local body_w = math.floor(a * 0.74)
    bb:paintRect(cx - math.floor(body_w / 2), yy, body_w, self.body_h, STONE)
    bb:paintBorder(cx - math.floor(body_w / 2), yy, body_w, self.body_h, bw, BLACK)
    local ls = self.label:getSize()
    self.label:paintTo(bb, cx - math.floor(ls.w / 2), yy + math.floor((self.body_h - ls.h) / 2))
    yy = yy + self.body_h
    slab(bb, cx - math.floor(a * 0.48), yy, math.floor(a * 0.96), self.base_h, STONE_DARK)
    -- the god, standing on the plinth
    self.god:paintTo(bb, cx - math.floor(a / 2), y)
end

-- Creature altar: the creature stands behind a low offering stone with its
-- name carved in it. state: "fed" (full libation bowl, honey cake, incense),
-- "waiting" / "hungry" (empty bowl), "left" (mossy stone, tipped bowl, only a
-- faded outline of the creature remains).
local Altar = Widget:extend{ w = 0, art = 0, art_id = nil, name = "", state = "waiting" }
function Altar:init()
    local a = self.art
    self.top_y = math.floor(a * 0.90)
    self.cap_h = math.max(4, math.floor(a * 0.05))
    self.body_h = math.max(18, math.floor(a * 0.24))
    self.base_h = math.max(4, math.floor(a * 0.05))
    self.item = math.floor(a * 0.30)
    self.h = self.top_y + self.cap_h + self.body_h + self.base_h
    self.label = text(self.name, 24, true, math.floor(a * 0.8), BLACK, "display")
    self.creature = Art.widget(self.art_id, a)
    if self.state == "left" then self.creature.dim = true end
    local st = self.state
    self.bowl = Art.widget(st == "fed" and "offer_bowl_full" or (st == "left" and "offer_bowl_tipped" or "offer_bowl_empty"), self.item)
    if st == "fed" then
        self.cake = Art.widget("offer_cake", self.item)
        self.smoke = Art.widget("offer_smoke", math.floor(self.item * 0.9))
    end
end
function Altar:getSize() return Geom:new{ w = self.w, h = self.h } end
function Altar:paintTo(bb, x, y)
    self.dimen = Geom:new{ x = x, y = y, w = self.w, h = self.h }
    local a, cx = self.art, x + math.floor(self.w / 2)
    local bw = px(2)
    self.creature:paintTo(bb, cx - math.floor(a / 2), y)
    -- offering stone: ledge, carved body, base
    local sw = math.floor(a * 1.56)
    local yy = y + self.top_y
    bb:paintRect(cx - math.floor(sw / 2), yy, sw, self.cap_h, STONE_DARK)
    bb:paintBorder(cx - math.floor(sw / 2), yy, sw, self.cap_h, bw, BLACK)
    yy = yy + self.cap_h
    local body_w = math.floor(a * 1.40)
    bb:paintRect(cx - math.floor(body_w / 2), yy, body_w, self.body_h, STONE)
    bb:paintBorder(cx - math.floor(body_w / 2), yy, body_w, self.body_h, bw, BLACK)
    if self.state == "left" then
        -- a crack running down the abandoned stone
        local m = math.max(2, math.floor(a * 0.018))
        local x0 = cx - math.floor(body_w / 2) + math.floor(body_w * 0.12)
        local pts = { { 0, 0 }, { 0.05, 0.3 }, { -0.02, 0.55 }, { 0.06, 0.8 }, { 0.03, 1 } }
        for i = 1, #pts - 1 do
            local ax, ay = x0 + pts[i][1] * a, yy + pts[i][2] * self.body_h
            local bx, by = x0 + pts[i + 1][1] * a, yy + pts[i + 1][2] * self.body_h
            local n = math.max(1, math.floor(math.max(math.abs(bx - ax), math.abs(by - ay)) / m * 2))
            for k = 0, n do
                local t = k / n
                bb:paintRect(math.floor(ax + (bx - ax) * t), math.floor(ay + (by - ay) * t), m, m, BLACK)
            end
        end
    end
    local ls = self.label:getSize()
    self.label:paintTo(bb, cx - math.floor(ls.w / 2), yy + math.floor((self.body_h - ls.h) / 2))
    yy = yy + self.body_h
    bb:paintRect(cx - math.floor(a * 0.8), yy, math.floor(a * 1.6), self.base_h, STONE_DARK)
    bb:paintBorder(cx - math.floor(a * 0.8), yy, math.floor(a * 1.6), self.base_h, bw, BLACK)
    -- offerings on the ledge
    local it = self.item
    local ledge = y + self.top_y + math.floor(it * 0.12)
    self.bowl:paintTo(bb, cx - math.floor(sw / 2) + math.floor(sw * 0.03), ledge - it)
    if self.cake then
        local kx = cx + math.floor(sw / 2) - math.floor(sw * 0.03) - it
        self.cake:paintTo(bb, kx, ledge - it)
        self.smoke:paintTo(bb, kx + math.floor(it * 0.05), ledge - it - math.floor(it * 0.75))
    end
end

-- Builds the status panel of size w x h. for_sleep marks the sleep-screen version.
function UI.buildStatus(w, h, for_sleep)
    local s = Store.refreshDay()
    local c = s.companion
    local inner_w = w - 2 * px(28)
    local g = VerticalGroup:new{ align = "center" }
    local function add(x) table.insert(g, x) end

    local function message(str, warning)
        local tb = para(str, 13, inner_w - px(36), "center", warning, warning and WHITE or BLACK, warning and BLACK or WHITE)
        return card(inner_w, tb:getSize().h + px(28), tb, { bg = warning and BLACK or WHITE, radius = px(14) })
    end

    local function goalPanel()
        local tier = R.tierOf(c.char)
        local goal = R.dailyGoal(tier)
        local pw = inner_w - px(32)
        local missed = c.goal_met and 0 or c.missed
        local right
        if tier == R.CLAY then right = string.format(L("Chuỗi nuôi: %d ngày"), c.streak)
        elseif c.ember then right = L("Đuốc: than tàn")
        else right = string.format(L("Đuốc cháy %d ngày"), c.streak) end
        local pg = VerticalGroup:new{ align = "left",
            row(text(L("MỤC TIÊU HÔM NAY"), 11, true), text(string.format(L("%d/%d trang"), math.min(c.today_pages, 999), goal), 16, true), pw),
            vspace(4),
            progressBar(pw, c.today_pages / goal),
            vspace(6),
            text(string.format(L("Chỉ tính sách %s"), Store.TIER_RANGE[tier]), 11),
            vspace(4),
            row(HorizontalGroup:new{ align = "center", text(L("Ngày lỡ"), 11, true), hspace(8), Dots:new{ n = R.MAX_MISSED_DAYS, filled = missed, r = px(6) } },
                text(right, 11, true), pw),
        }
        return card(inner_w, pg:getSize().h + px(28), pg, { pad = px(14), halign = "left" })
    end

    local top_line = nil
    local art_id, art_name, extra, msg, warning
    local ch
    if c.char then
        ch = Store.char(c.char)
        local tier = R.tierOf(c.char)
        local goal = R.dailyGoal(tier)
        local mood = R.companionMood(s)
        art_id = ch.key
        if mood == "happy" then
            top_line = (c.today_pages >= goal and L("%s đang chơi đùa") or L("%s đang chờ bữa ăn")):format(ch.name)
        elseif mood == "hungry" then top_line = (L("%s đói bụng")):format(ch.name)
        elseif mood == "blessing" then top_line = (L("Đuốc của %s đang cháy")):format(ch.name)
        elseif mood == "weak" then top_line = (L("Đuốc của %s cháy yếu")):format(ch.name)
        else top_line = (L("Đuốc của %s đã thành than")):format(ch.name) end
        if tier == R.CLAY then
            extra = { altar = c.today_pages >= goal and "fed" or (mood == "hungry" and "hungry" or "waiting") }
            if c.today_pages >= goal then
                msg = (L("No căng bụng rồi! Hôm nay %s đã được ăn.")):format(ch.name)
            elseif mood == "hungry" then
                warning = true
                local left = R.MAX_MISSED_DAYS - c.missed
                if left > 1 then
                    msg = (L("Đã lỡ %d ngày. Còn %d ngày để đọc %d trang sách %s, nếu không %s sẽ bỏ về đền.")):format(
                        c.missed, left, goal, Store.TIER_RANGE[tier], ch.name)
                else
                    msg = (L("Đã lỡ %d ngày. Đọc %d trang sách %s hôm nay, nếu không %s sẽ bỏ về đền.")):format(
                        c.missed, goal, Store.TIER_RANGE[tier], ch.name)
                end
            else
                msg = (L("Hôm nay %s chưa được ăn. Đọc đủ %d trang để cho nó ăn nhé.")):format(ch.name, goal)
            end
        else
            local level = mood == "ember" and 0 or (mood == "weak" and 1 or 2)
            extra = "flame_" .. level
            if mood == "ember" then
                warning = true
                msg = (L("%s đang giận, không ban phước. Đọc %d trang sách %s để thắp lại đuốc.")):format(ch.name, goal, Store.TIER_RANGE[tier])
            elseif mood == "weak" then
                warning = true
                msg = (L("Đã lỡ %d ngày. Đọc %d trang sách %s hôm nay, nếu không đuốc sẽ thành than.")):format(c.missed, goal, Store.TIER_RANGE[tier])
            else
                msg = "“" .. ch.blessing .. "”"
            end
        end
    elseif c.left_char then
        local name = Store.char(c.left_char).name
        top_line = (L("%s đã về Đền thờ")):format(name)
        art_id = Store.char(c.left_char).key
        ch = Store.char(c.left_char)
        extra = { altar = "left" }
        msg = (L("%d ngày liền chưa đọc đủ %d trang nên %s đã về Đền thờ. Vào Đền thờ để chọn lại %s nhé.")):format(
            R.MAX_MISSED_DAYS, R.dailyGoal(R.CLAY), name, name)
    end

    if art_id then
        -- Companion layout: label, character (+ flame / food), line, message, goal panel.
        local msg_w = message(msg, warning)
        local panel = c.char and goalPanel() or nil
        local label = text(top_line, 16, true, inner_w, BLACK, "display")
        local fixed = label:getSize().h + msg_w:getSize().h + (panel and panel:getSize().h or px(50)) + px(90)
        local art = math.floor(math.max(px(96), math.min(inner_w * 0.75, h - fixed - px(60))))
        if type(extra) == "string" then
            -- room for the pillars on both sides and the plinth below
            art = math.floor(math.min(art, inner_w * 0.56, (h - fixed - px(60)) / 1.32))
        elseif type(extra) == "table" and extra.altar then
            art = math.floor(math.min(art, inner_w * 0.60, (h - fixed - px(60)) / 1.24))
        end
        add(vspace(8))
        add(label)
        add(vspace(8))
        if type(extra) == "string" then -- god / Titan on its shrine
            add(Shrine:new{ w = inner_w, art = art, art_id = art_id, name = ch.name:upper(),
                            level = tonumber(extra:match("%d")) or 2 })
        elseif type(extra) == "table" and extra.altar then -- creature behind its offering stone
            add(Altar:new{ w = inner_w, art = art, art_id = art_id, name = ch.name:upper(), state = extra.altar })
        else
            add(Art.widget(art_id, art))
            add(hline(inner_w - px(40)))
        end
        add(vspace(14))
        add(msg_w)
        add(vspace(14))
        if panel then
            add(panel)
        else
            add(pill(L("Bật máy · vào Đền thờ"), 12, true))
        end
    elseif not R.phase2(s) then
        add(vspace(40))
        add(text(L("Lò ấp"), 26, true))
        add(text(L("Chưa có nhân vật nào nở"), 12))
        add(vspace(30))
        local row_g = HorizontalGroup:new{ align = "top" }
        local egg = math.floor(math.min(px(110), inner_w / 4))
        for i = 1, R.SLOT_COUNT do
            if i > 1 then table.insert(row_g, hspace(20)) end
            local sl = s.slots[i]
            local col = VerticalGroup:new{ align = "center" }
            if sl.used then
                table.insert(col, Art.widget(Art.eggName(sl.tier, R.crackStage(sl.read_pages, sl.pages), R.isColdEgg(sl, Store.today())), egg))
                table.insert(col, text(string.format("%d%%", sl.pages > 0 and math.floor(sl.read_pages * 100 / sl.pages) or 0), 15, true))
            else
                table.insert(col, box(egg, egg, text("+", 30, true)))
                table.insert(col, text(L("Trống"), 15, true))
            end
            table.insert(row_g, col)
        end
        add(row_g)
        add(vspace(30))
        if R.totalHatched(s) > 0 then
            add(para(L("Vào Olympus, mở hồ sơ một nhân vật trong Đền thờ và chạm \"Đặt làm màn chờ\" để có bạn đồng hành."), 13, inner_w, "center"))
        else
            add(para(L("Đọc xong một cuốn trong lò ấp để nở nhân vật đầu tiên. Sau đó vào Đền thờ để chọn nhân vật cho màn hình chờ."), 13, inner_w, "center"))
        end
    else
        add(vspace(200))
        add(text(L("Đã đủ 90/90"), 26, true))
        add(vspace(10))
        add(para(L("Lò ấp đã đóng. Vào Olympus, mở hồ sơ một nhân vật trong Đền thờ và chạm Đặt làm màn chờ để nhận bạn đồng hành."), 13, inner_w, "center"))
    end

    -- Frame with meanders at top and bottom
    local fb = px(3)
    local frame_inner_w = w - 2 * px(10) - 2 * fb
    local frame_inner_h = h - 2 * px(10) - 2 * fb
    local m_top, m_bot = meander(frame_inner_w - px(20)), meander(frame_inner_w - px(20))
    local body_h = frame_inner_h - 2 * m_top:getSize().h - px(24)
    local content = VerticalGroup:new{ align = "center",
        vspace(6), m_top,
        box(frame_inner_w, body_h, g, "center", "center"),
        m_bot,
    }
    return FrameContainer:new{
        margin = px(10), bordersize = fb, padding = 0, background = WHITE, radius = 0,
        box(frame_inner_w, frame_inner_h, content, "center", "top"),
    }
end

-- Renders the sleep screen into a new portrait BlitBuffer.
function UI.renderSleep()
    local sw, sh = Screen:getWidth(), Screen:getHeight()
    if sw > sh then sw, sh = sh, sw end
    local saved = { W, H, U }
    setGeom(sw, sh)
    local widget = FrameContainer:new{ bordersize = 0, padding = 0, margin = 0, background = WHITE,
        box(sw, sh, UI.buildStatus(sw, sh, true)) }
    local bb = Blitbuffer.new(sw, sh, Screen.bb:getType())
    bb:fill(WHITE)
    widget:paintTo(bb, 0, 0)
    widget:free()
    W, H, U = saved[1], saved[2], saved[3]
    return bb
end

local Companion = Window:extend{}
UI.Companion = Companion

function Companion:build()
    local foot_h = px(60)
    local panel = UI.buildStatus(W, H - foot_h, false)
    local foot = HorizontalGroup:new{ align = "center",
        button(L("Quay lại"), px(150), function() self:onClose() end),
        hspace(8),
        button(L("Đền thờ"), px(150), function() self:onClose(); UI.show(UI.Temple) end, true),
    }
    return VerticalGroup:new{ align = "center", panel, box(W, foot_h, foot) }
end

---------------------------------------------------------------------------
-- Navigation helpers
---------------------------------------------------------------------------
UI.plugin = nil -- set by main.lua

function UI.show(class, opts)
    opts = opts or {}
    opts.plugin = opts.plugin or UI.plugin
    local w = class:new(opts)
    UIManager:show(w, "full")
    return w
end

-- Closes every Olympus window (used before opening a book).
function UI.closeAll()
    for w in pairs(UI.open_windows) do
        UIManager:close(w)
        UI.open_windows[w] = nil
    end
end

return UI
