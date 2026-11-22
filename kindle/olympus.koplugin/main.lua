--[[--
Olympus: a reading game for KOReader (Kindle, Kobo, PocketBook...).

Read books to hatch eggs and collect 90 characters from Greek mythology, then
keep a companion on the sleep screen by reading every day.
Port of the Olympus game from the CrossPoint firmware for the Xteink X4 Pro.

@module koplugin.Olympus
--]]

local L = require("olympus_i18n").L
local ConfirmBox = require("ui/widget/confirmbox")
local Dispatcher = require("dispatcher")
local DocSettings = require("docsettings")
local DocumentRegistry = require("document/documentregistry")
local InfoMessage = require("ui/widget/infomessage")
local Notification = require("ui/widget/notification")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local lfs = require("libs/libkoreader-lfs")
local logger = require("logger")

local Art = require("olympus_art")
local R = require("olympus_rules")
local Store = require("olympus_store")
local UI = require("olympus_ui")

local SAVE_EVERY_UPDATES = 5

local Olympus = WidgetContainer:extend{
    name = "olympus",
    is_doc_only = false,
}

---------------------------------------------------------------------------
-- Sleep screen: hook KOReader's screensaver once per session.
---------------------------------------------------------------------------
local function patchScreensaver()
    local Screensaver = require("ui/screensaver")
    if Screensaver._olympus_patched then return end
    Screensaver._olympus_patched = true
    local orig_setup = Screensaver.setup
    Screensaver.setup = function(self, event, event_message)
        orig_setup(self, event, event_message)
        -- Only for a normal suspend (not power off / reboot).
        if event ~= nil or not G_reader_settings:isTrue("olympus_sleep_screen") then return end
        local ok, bb = pcall(UI.renderSleep)
        if ok and bb then
            self.image = bb
            self.image_file = nil
            self.screensaver_type = "cover"
            self.screensaver_background = "white"
            -- No "Sleeping" message box over the Olympus screen.
            self.show_message = false
        else
            logger.warn("Olympus: could not render sleep screen", bb)
        end
    end
end

---------------------------------------------------------------------------
-- Plugin life cycle
---------------------------------------------------------------------------
function Olympus:init()
    Art.dir = self.path .. "/sprites/"
    -- KOReader gives plugins a relative path ("plugins/olympus.koplugin"), but
    -- Font:getFace only treats paths starting with "/" or "./" as files: make it absolute.
    local base = self.path
    if base:sub(1, 1) ~= "/" then
        local cwd = lfs.currentdir()
        base = cwd and (cwd .. "/" .. base) or ("./" .. base)
    end
    UI.font_dir = base .. "/fonts/"
    Store.load()
    UI.plugin = self
    patchScreensaver()
    self:onDispatcherRegisterActions()
    self.ui.menu:registerToMainMenu(self)
    UIManager:nextTick(function() self:syncGestures() end)
    -- Library: long-press a book -> "Đặt vào lò ấp"
    -- (plugins are created before the file browser builds its list, so only
    -- check that this is the file manager, not that file_chooser exists yet)
    if self.ui.addFileDialogButtons and not self.ui.document then
        self.ui:addFileDialogButtons("olympus", function(file, is_file)
            if not is_file or not DocumentRegistry:hasProvider(file) then return end
            return {
                {
                    text = L("Đặt vào lò ấp (Olympus)"),
                    callback = function()
                        Olympus.closeTopDialog()
                        self:placeFile(file)
                    end,
                },
            }
        end)
    end
end

-- Closes the long-press dialog (library, history, collections or search).
function Olympus.closeTopDialog()
    local ok, ButtonDialog = pcall(require, "ui/widget/buttondialog")
    local stack = UIManager._window_stack
    if not ok or type(stack) ~= "table" then return end
    for i = #stack, 1, -1 do
        local w = stack[i].widget
        local mt = w and getmetatable(w)
        while mt do
            if mt == ButtonDialog then
                UIManager:close(w)
                return
            end
            mt = getmetatable(mt)
        end
    end
end

-- Olympus opens with one gesture only: long-press on the top-right corner,
-- both in the file browser and in the reader. KOReader keeps the two sets of
-- gestures apart, so set it in both and remove Olympus from every other gesture.
local OLYMPUS_ACTIONS = { "olympus_open", "olympus_incubator", "olympus_temple" }
local OLYMPUS_GESTURE = "hold_top_right_corner"

function Olympus:syncGestures()
    local g = self.ui and self.ui.gestures
    local data = g and g.data
    if not data then return end
    local changed = false
    for _, mode in ipairs({ "gesture_fm", "gesture_reader" }) do
        if type(data[mode]) ~= "table" then data[mode] = {} end
        local set = data[mode]
        for ges, actions in pairs(set) do
            if ges ~= OLYMPUS_GESTURE and type(actions) == "table" then
                for _, a in ipairs(OLYMPUS_ACTIONS) do
                    if actions[a] ~= nil then
                        actions[a] = nil
                        changed = true
                    end
                end
                if actions.settings and type(actions.settings.order) == "table" then
                    for i = #actions.settings.order, 1, -1 do
                        for _, a in ipairs(OLYMPUS_ACTIONS) do
                            if actions.settings.order[i] == a then table.remove(actions.settings.order, i) end
                        end
                    end
                end
                local left = false
                for k in pairs(actions) do
                    if k ~= "settings" then left = true break end
                end
                if not left then set[ges] = nil end
            end
        end
        local cur = set[OLYMPUS_GESTURE]
        local only_open = type(cur) == "table" and cur.olympus_open
        if only_open then
            for k in pairs(cur) do
                if k ~= "olympus_open" and k ~= "settings" then only_open = false end
            end
        end
        if not only_open then
            set[OLYMPUS_GESTURE] = { olympus_open = true }
            changed = true
        end
    end
    if changed then
        g.updated = true
        if g.onFlushSettings then pcall(g.onFlushSettings, g) end
        logger.info("Olympus: long-press top-right corner opens Olympus (file browser and reader)")
    end
end

function Olympus:onDispatcherRegisterActions()
    Dispatcher:registerAction("olympus_open", { category = "none", event = "OlympusOpen", title = "Olympus", general = true })
    Dispatcher:registerAction("olympus_incubator", { category = "none", event = "OlympusIncubator", title = L("Olympus: Lò ấp"), general = true })
    Dispatcher:registerAction("olympus_temple", { category = "none", event = "OlympusTemple", title = L("Olympus: Đền thờ"), general = true })
end

function Olympus:addToMainMenu(menu_items)
    menu_items.olympus = {
        text_func = function() return "Olympus · " .. Store.summary() end,
        sorting_hint = "tools",
        sub_item_table = {
            {
                text = L("Mở Olympus"),
                callback = function() self:onOlympusOpen() end,
            },
            {
                text = L("Lò ấp"),
                callback = function() self:onOlympusIncubator() end,
            },
            {
                text = L("Đền thờ"),
                callback = function() self:onOlympusTemple() end,
            },
            {
                text = L("Đặt sách đang đọc vào lò ấp"),
                enabled_func = function() return self.ui.document ~= nil end,
                callback = function() self:placeCurrent(true) end,
                separator = true,
            },
            {
                text = L("Dùng Olympus làm màn hình chờ"),
                checked_func = function() return G_reader_settings:isTrue("olympus_sleep_screen") end,
                callback = function() G_reader_settings:flipNilOrFalse("olympus_sleep_screen") end,
                help_text = L("Khi máy ngủ, hiện bạn đồng hành (hoặc lò ấp) thay cho hình chờ của KOReader. Trên Kindle có quảng cáo (Special Offers), KOReader không vẽ được màn hình chờ."),
            },
            {
                text = L("Xem trước màn hình chờ"),
                callback = function() UI.show(UI.Companion) end,
                separator = true,
            },
            {
                text = "Ngôn ngữ / Language",
                sub_item_table = (function()
                    local items = {}
                    for _, opt in ipairs({ { "auto", "Tự động / Auto" }, { "vi", "Tiếng Việt" }, { "en", "English" } }) do
                        table.insert(items, {
                            text = opt[2],
                            radio = true,
                            checked_func = function() return require("olympus_i18n").setting() == opt[1] end,
                            callback = function()
                                G_reader_settings:saveSetting("olympus_language", opt[1])
                                UIManager:show(InfoMessage:new{
                                    text = "Khởi động lại KOReader để đổi ngôn ngữ.\nRestart KOReader to change the language.",
                                })
                            end,
                        })
                    end
                    return items
                end)(),
                separator = true,
            },
            {
                text = L("Chơi lại từ đầu"),
                keep_menu_open = true,
                callback = function()
                    UIManager:show(ConfirmBox:new{
                        text = L("Xoá toàn bộ tiến trình Olympus (lò ấp, Đền thờ, bạn đồng hành)? Không thể hoàn tác."),
                        ok_text = L("Xoá"),
                        cancel_text = L("Huỷ"),
                        ok_callback = function() Store.reset() end,
                    })
                end,
            },
        },
    }
end

function Olympus:onOlympusOpen() UI.show(UI.Hub) return true end
function Olympus:onOlympusIncubator() UI.show(UI.Incubator) return true end
function Olympus:onOlympusTemple() UI.show(UI.Temple) return true end

function Olympus:onCompanionChanged()
    -- nothing to recompute: the sleep screen is drawn from the saved state when the device sleeps
end

---------------------------------------------------------------------------
-- Placing books in the incubator
---------------------------------------------------------------------------
local RESULT_TEXT = {
    full = L("Lò ấp đã đầy (3/3). Đọc xong hoặc bỏ một quả trứng trước đã."),
    already = L("Cuốn này đang ở trong lò ấp."),
    closed = L("Đã đủ 90 nhân vật nên Lò ấp đã đóng. Vào Đền thờ để đổi bạn đồng hành."),
    bad = L("Không đọc được số trang của cuốn sách này."),
}

function Olympus:reportPlacement(result, slot)
    local s = Store.get()
    local msg
    if result == "placed" or result == "placed_empty" then
        local sl = s.slots[slot]
        msg = string.format(L("Đã đặt vào lò ấp: %s (%d trang).\nĐọc tới cuối sách để trứng nở."),
            Store.TIER_EGG[sl.tier], sl.pages)
        if result == "placed_empty" then
            msg = msg .. string.format(L("\n\nLưu ý: bộ %s đã đủ 30/30 nên quả trứng này sẽ không nở ra gì."), Store.TIER_TAB[sl.tier])
        end
    else
        msg = RESULT_TEXT[result] or result
    end
    UIManager:show(InfoMessage:new{ text = msg, timeout = result == "placed" and 4 or nil })
    for w in pairs(UI.open_windows) do
        if w.refresh then w:refresh() end
    end
end

-- Places the book open in the reader.
function Olympus:placeCurrent(report)
    if not self.ui.document then return end
    self:ensureLog()
    local s = Store.get()
    local file = self.ui.document.file
    local n = self.ui.document:getPageCount()
    local p = self.ui:getCurrentPage() or 1
    local frac = n > 0 and p / n or 0
    local pages = self.log.n
    local result, slot = R.placeBook(s, file, pages, math.floor(frac * pages), Store.today())
    if result == "placed" or result == "placed_empty" then Store.save() end
    if report then self:reportPlacement(result, slot) end
    return result, slot
end

-- Places any book file. Uses the page count KOReader saved the last time the
-- book was open; a book never opened is opened first to count its pages.
function Olympus:placeFile(file)
    local reader = require("apps/reader/readerui").instance
    if reader and reader.document and reader.document.file == file then
        local plugin = reader.olympus
        if plugin then return plugin:placeCurrent(true) end
    end
    local pages, frac
    if DocSettings:hasSidecarFile(file) then
        local ds = DocSettings:open(file)
        local log = ds:readSetting("olympus_log")
        pages = (log and log.n) or ds:readSetting("doc_pages")
        frac = ds:readSetting("percent_finished") or 0
    end
    if pages and pages > 0 then
        local s = Store.get()
        local result, slot = R.placeBook(s, file, pages, math.floor(frac * pages), Store.today())
        if result == "placed" or result == "placed_empty" then Store.save() end
        self:reportPlacement(result, slot)
        return
    end
    local s = Store.get()
    if R.phase2(s) then return self:reportPlacement("closed") end
    if R.usedSlots(s) >= R.SLOT_COUNT then return self:reportPlacement("full") end
    UIManager:show(ConfirmBox:new{
        text = L("Cuốn này chưa mở lần nào nên chưa biết số trang.\nMở sách để đếm trang và đặt vào lò ấp?"),
        ok_text = L("Mở sách"),
        cancel_text = L("Huỷ"),
        ok_callback = function()
            Olympus.pending_place = file
            self:openBook(file)
        end,
    })
end

-- Tap on an empty incubator slot: pick a book in the library.
function Olympus:chooseBook()
    local PathChooser = require("ui/widget/pathchooser")
    local home = G_reader_settings:readSetting("home_dir") or require("apps/filemanager/filemanagerutil").getDefaultDir()
    -- One tap on a book places it (KOReader's chooser normally needs a long press).
    local plugin = self
    local BookChooser = PathChooser:extend{}
    function BookChooser:onMenuSelect(item)
        local path = item and item.path
        if path and path:sub(-2) ~= "/." and lfs.attributes(path, "mode") == "file" then
            UIManager:close(self)
            UIManager:nextTick(function() plugin:placeFile(path) end)
            return true
        end
        return PathChooser.onMenuSelect(self, item)
    end
    local chooser = BookChooser:new{
        title = L("Chạm vào sách để đặt vào lò ấp"),
        select_directory = false,
        select_file = true,
        path = home,
        file_filter = function(f) return DocumentRegistry:hasProvider(f) end,
        onConfirm = function(file) self:placeFile(file) end,
    }
    UIManager:show(chooser)
end

function Olympus:openBook(file)
    UI.closeAll()
    local ReaderUI = require("apps/reader/readerui")
    if ReaderUI.instance then
        if ReaderUI.instance.document and ReaderUI.instance.document.file == file then return end
        ReaderUI.instance:switchDocument(file)
    else
        ReaderUI:showReader(file)
    end
end

---------------------------------------------------------------------------
-- Reading: page logs and egg progress (reader only)
---------------------------------------------------------------------------

-- Per-book log of pages seen. Its page count is frozen the first time, so a
-- font change does not change the book's tier.
function Olympus:ensureLog()
    if self.log then return self.log end
    local doc = self.ui.document
    if not doc then return end
    local s = Store.get()
    local log = R.PageLog.deserialize(self.ui.doc_settings:readSetting("olympus_log"))
    local slot = R.slotForPath(s, doc.file)
    if not log then
        local n = slot and s.slots[slot].pages or doc:getPageCount()
        log = R.PageLog.new(n)
    end
    self.log = log
    return log
end

function Olympus:onReaderReady()
    if not self.ui.document then return end
    self:ensureLog()
    if Olympus.pending_place == self.ui.document.file then
        Olympus.pending_place = nil
        UIManager:nextTick(function() self:placeCurrent(true) end)
    end
    self:onPageUpdate(self.ui:getCurrentPage())
end

function Olympus:onPageUpdate(pageno)
    if not self.ui.document or not pageno or self.hatch_pending then return end
    local log = self:ensureLog()
    if not log or log.n <= 0 then return end
    local n = self.ui.document:getPageCount()
    if not n or n <= 0 then return end
    pageno = math.max(1, math.min(pageno, n))
    local startf, endf = (pageno - 1) / n, pageno / n
    local added = log:markSpan(startf, endf)
    if added > 0 then self.log_dirty = true end

    local s = Store.get()
    local today = Store.today()
    local file = self.ui.document.file
    local changed = added > 0
    local i = R.slotForPath(s, file)
    if i then
        local sl = s.slots[i]
        local at_end = pageno >= n or endf >= R.HATCH_AT
        local pos = at_end and sl.pages or math.floor(endf * sl.pages)
        if pos ~= sl.read_pages then changed = true end
        local ev = R.noteSlotPages(s, i, added, pos, at_end, today)
        if ev then
            if added > 0 then R.noteCompanionPages(s, log.n, added, today) end
            Store.save()
            self:showHatch(ev)
            return
        end
    end
    if added > 0 and s.companion.char then
        local was_met = s.companion.goal_met
        if R.noteCompanionPages(s, log.n, added, today) and not was_met then
            local ch = Store.char(s.companion.char)
            local tier = R.tierOf(s.companion.char)
            local txt = string.format(tier == R.CLAY and L("%s đã được ăn hôm nay!") or L("Đuốc của %s đã được châm dầu!"), ch.name)
            UIManager:show(Notification:new{ text = "Olympus: " .. txt })
            Store.save()
            return
        end
    end
    if changed then
        self.updates = (self.updates or 0) + 1
        if self.updates >= SAVE_EVERY_UPDATES then
            self.updates = 0
            Store.save()
        end
    end
end

-- Continuous (scroll) mode only sends PosUpdate while scrolling; count the
-- page under the top of the screen whenever it changes.
function Olympus:onPosUpdate(pos, pageno)
    if not pageno or pageno == self.last_scroll_page then return end
    self.last_scroll_page = pageno
    self:onPageUpdate(pageno)
end

function Olympus:showHatch(ev)
    self.hatch_pending = true
    UIManager:nextTick(function()
        self.hatch_pending = nil
        UI.show(UI.Hatch, { event = ev })
    end)
end

function Olympus:saveLog()
    if self.ui.document and self.log and self.ui.doc_settings then
        self.ui.doc_settings:saveSetting("olympus_log", self.log:serialize())
        self.log_dirty = false
    end
end

function Olympus:onSaveSettings()
    self:saveLog()
    Store.save()
end

function Olympus:onCloseDocument()
    Store.save()
end

function Olympus:onSuspend()
    if self.ui.document then self:saveLog() end
    Store.save()
end

return Olympus
