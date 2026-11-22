--[[--
Olympus text in English and Vietnamese.
Vietnamese strings are the keys; English is looked up here.
Language: setting "olympus_language" = "auto" | "en" | "vi".
"auto" follows KOReader's UI language (Vietnamese if KOReader is in Vietnamese, English otherwise).
--]]

local EN = {
    ["Đặt vào lò ấp (Olympus)"] = "Put in incubator (Olympus)",
    ["Olympus: Lò ấp"] = "Olympus: Incubator",
    ["Olympus: Đền thờ"] = "Olympus: Temple",
    ["Mở Olympus"] = "Open Olympus",
    ["Lò ấp"] = "Incubator",
    ["Đền thờ"] = "Temple",
    ["Đặt sách đang đọc vào lò ấp"] = "Put this book in the incubator",
    ["Dùng Olympus làm màn hình chờ"] = "Use Olympus as sleep screen",
    ["Khi máy ngủ, hiện bạn đồng hành (hoặc lò ấp) thay cho hình chờ của KOReader. Trên Kindle có quảng cáo (Special Offers), KOReader không vẽ được màn hình chờ."] = "When the device sleeps, show your companion (or the incubator) instead of KOReader's sleep screen. On Kindles with Special Offers, KOReader cannot draw the sleep screen.",
    ["Xem trước màn hình chờ"] = "Preview sleep screen",
    ["Chơi lại từ đầu"] = "Start over",
    ["Xoá toàn bộ tiến trình Olympus (lò ấp, Đền thờ, bạn đồng hành)? Không thể hoàn tác."] = "Delete all Olympus progress (incubator, Temple, companion)? This cannot be undone.",
    ["Xoá"] = "Delete",
    ["Huỷ"] = "Cancel",
    ["Lò ấp đã đầy (3/3). Đọc xong hoặc bỏ một quả trứng trước đã."] = "The incubator is full (3/3). Finish a book or remove an egg first.",
    ["Cuốn này đang ở trong lò ấp."] = "This book is already in the incubator.",
    ["Đã đủ 90 nhân vật nên Lò ấp đã đóng. Vào Đền thờ để đổi bạn đồng hành."] = "All 90 characters are collected, so the incubator is closed. Visit the Temple to change your companion.",
    ["Không đọc được số trang của cuốn sách này."] = "Could not read the page count of this book.",
    ["Đã đặt vào lò ấp: %s (%d trang).\nĐọc tới cuối sách để trứng nở."] = "Placed in the incubator: %s (%d pages).\nRead to the end of the book to hatch it.",
    ["\n\nLưu ý: bộ %s đã đủ 30/30 nên quả trứng này sẽ không nở ra gì."] = "\n\nNote: the %s set is complete (30/30), so this egg will hatch nothing.",
    ["Cuốn này chưa mở lần nào nên chưa biết số trang.\nMở sách để đếm trang và đặt vào lò ấp?"] = "This book has never been opened, so its page count is unknown.\nOpen it to count the pages and put it in the incubator?",
    ["Mở sách"] = "Open book",
    ["Chạm vào sách để đặt vào lò ấp"] = "Tap a book to put it in the incubator",
    ["%s đã được ăn hôm nay!"] = "%s has been fed today!",
    ["Đuốc của %s đã được châm dầu!"] = "%s's torch has been refilled!",
    ["Lò ấp đang trống"] = "The incubator is empty",
    ["%d/3 ô đang ấp · gần nở nhất %d%%"] = "%d/3 eggs incubating · closest to hatching %d%%",
    ["nuôi"] = "fed",
    ["đuốc tàn,"] = "torch out,",
    ["đuốc cháy"] = "torch lit",
    ["%s · %s %d ngày · %d/%d trang"] = "%s · %s %d days · %d/%d pages",
    ["%s đã về Đền thờ"] = "%s went back to the Temple",
    ["Chưa có. Vào Đền thờ để chọn một nhân vật."] = "None yet. Visit the Temple to choose a character.",
    ["%d/90 · Đã sưu tầm đủ"] = "%d/90 · Collection complete",
    ["%d/90 nhân vật"] = "%d/90 characters",
    ["Bạn đồng hành"] = "Companion",
    ["Bộ sưu tập 90/90 · chọn bạn đồng hành"] = "Collection 90/90 · choose a companion",
    ["Bộ sưu tập · %d/90 · có %d nhân vật mới"] = "Collection · %d/90 · %d new",
    ["Bộ sưu tập · %d/90"] = "Collection · %d/90",
    ["MỚI"] = "NEW",
    ["Muốn ấp thêm trứng: chạm một ô trống trong Lò ấp, hoặc trong Thư viện nhấn giữ một cuốn sách và chọn \"Đặt vào lò ấp\"."] = "To incubate another egg: tap an empty slot in the Incubator, or long-press a book in the library and choose \"Put in incubator\".",
    ["Quay lại"] = "Back",
    ["Còn %d trang để nở"] = "%d pages to hatch",
    ["Còn %d trang tới vết nứt"] = "%d pages to the next crack",
    ["Chỉ trang đọc trong 3 cuốn này mới làm trứng nứt"] = "Only pages read in these 3 books crack the eggs",
    ["Đã đủ bộ: trứng này không nở ra gì"] = "Set complete: this egg hatches nothing",
    ["Trứng nguội: %d ngày chưa đọc"] = "Cold egg: not read for %d days",
    ["Ô trống · Đặt sách vào lò ấp"] = "Empty slot · Add a book",
    ["Chạm để chọn sách trong thư viện"] = "Tap to choose a book from your library",
    ["Bỏ trứng?\n\nTrứng của \"%s\" sẽ mất. Nhân vật trong trứng được giữ chỗ và sẽ nở từ quả trứng tiếp theo cùng bậc."] = "Remove egg?\n\nThe egg of \"%s\" will be lost. The character inside is kept for you and will hatch from your next egg of the same tier.",
    ["Bỏ trứng"] = "Remove egg",
    ["‹ Trước"] = "‹ Prev",
    ["Sau ›"] = "Next ›",
    ["Trang %d/%d"] = "Page %d/%d",
    ["Đang ở màn chờ"] = "On sleep screen",
    ["Đặt làm màn chờ"] = "Set as sleep screen",
    ["XUẤT THÂN"] = "ORIGIN",
    ["KHẢ NĂNG"] = "POWERS",
    ["BIỂU TƯỢNG"] = "SYMBOLS",
    ["THẦN THOẠI"] = "MYTH",
    ["LỜI BAN PHƯỚC"] = "BLESSING",
    ["LỜI NHẮN"] = "IN THEIR WORDS",
    ["Chưa nở"] = "Not hatched yet",
    ["GỢI Ý"] = "HINT",
    ["Nở từ %s (%s, %s). Bạn còn %d nhân vật chưa gặp ở bậc này."] = "Hatches from a %s (%s, %s). %d characters in this tier still to meet.",
    ["Đặt %s làm màn chờ?"] = "Set %s as your sleep screen?",
    ["Nhân vật sẽ thành bạn đồng hành. Chỉ tính %s (%s), mục tiêu %d trang mỗi ngày. Bạn đồng hành cũ về lại đền, chuỗi ngày bắt đầu từ 0."] = "This character becomes your companion. Only %s count (%s), with a goal of %d pages a day. Your old companion returns to the Temple and the streak starts from 0.",
    ["Đặt"] = "Set",
    ["Trứng đã mở"] = "Egg opened",
    ["Trứng đã nở!"] = "Your egg hatched!",
    ["Bạn đã đọc xong \"%s\""] = "You finished \"%s\"",
    ["Đọc tiếp"] = "Keep reading",
    ["Xem hồ sơ"] = "View profile",
    ["Bộ %s đã đủ 30/30 nên quả trứng này không nở ra gì."] = "The %s set is already complete (30/30), so this egg hatched nothing.",
    ["%s gia nhập Đền thờ"] = "%s joins the Temple",
    ["Đã sưu tầm đủ bộ %s!"] = "%s set complete!",
    ["Đủ 90/90! Lò ấp đóng lại. Vào Đền thờ để chọn một bạn đồng hành và giữ thói quen đọc mỗi ngày."] = "90/90! The incubator closes. Visit the Temple to choose a companion and keep up your daily reading.",
    ["Tất cả 30 nhân vật bậc này đã về Đền thờ. Từ giờ %s đặt vào lò ấp sẽ không nở thêm nhân vật."] = "All 30 characters of this tier are in the Temple. From now on, %s placed in the incubator will hatch nothing.",
    ["Bộ còn thiếu: Đất sét %d · Bạc %d · Vàng %d"] = "Still missing: Clay %d · Silver %d · Gold %d",
    ["Chuỗi nuôi: %d ngày"] = "Fed streak: %d days",
    ["Đuốc: than tàn"] = "Torch: embers",
    ["Đuốc cháy %d ngày"] = "Torch lit %d days",
    ["MỤC TIÊU HÔM NAY"] = "TODAY'S GOAL",
    ["%d/%d trang"] = "%d/%d pages",
    ["Chỉ tính %s (%s)"] = "Only %s count (%s)",
    ["Ngày lỡ"] = "Missed days",
    ["%s đang chơi đùa"] = "%s is playing",
    ["%s đang chờ bữa ăn"] = "%s is waiting for a meal",
    ["%s đói bụng"] = "%s is hungry",
    ["Đuốc của %s đang cháy"] = "%s's torch is burning",
    ["Đuốc của %s cháy yếu"] = "%s's torch is burning low",
    ["Đuốc của %s đã thành than"] = "%s's torch has burned out",
    ["Đã lỡ %d ngày. Còn %d ngày để đọc %d trang %s, nếu không %s sẽ về đền."] = "Days missed: %d. You have %d days to read %d pages of %s, or %s will go back to the Temple.",
    ["Đã lỡ %d ngày. Hôm nay đọc %d trang %s, nếu không %s sẽ về đền."] = "Days missed: %d. Read %d pages of %s today, or %s will go back to the Temple.",
    ["Hôm nay %s chưa được ăn. Đọc đủ %d trang để cho nó ăn nhé."] = "%s hasn't eaten today. Read %d pages to feed it.",
    ["%s đang giận. Đọc %d trang %s để thắp lại đuốc."] = "%s is angry. Read %d pages of %s to relight the torch.",
    ["Đã lỡ %d ngày. Hôm nay đọc %d trang %s, nếu không đuốc sẽ thành than."] = "Days missed: %d. Read %d pages of %s today, or the torch will burn out.",
    ["%d ngày liền chưa đọc đủ %d trang nên %s đã về Đền thờ. Vào Đền thờ để chọn lại %s nhé."] = "%d days in a row without reading %d pages, so %s went back to the Temple. Visit the Temple to choose %s again.",
    ["Bấm nút nguồn để đọc tiếp"] = "Press the power button to keep reading",
    ["Bật máy · vào Đền thờ"] = "Wake up · visit the Temple",
    ["Chưa có nhân vật nào nở"] = "No character has hatched yet",
    ["Trống"] = "Empty",
    ["Vào Olympus, mở hồ sơ một nhân vật trong Đền thờ và chạm \"Đặt làm màn chờ\" để có bạn đồng hành."] = "In Olympus, open a character's profile in the Temple and tap \"Set as sleep screen\" to get a companion.",
    ["Đọc xong một cuốn trong lò ấp để nở nhân vật đầu tiên. Sau đó vào Đền thờ để chọn nhân vật cho màn hình chờ."] = "Finish a book in the incubator to hatch your first character. Then visit the Temple to choose one for your sleep screen.",
    ["Đã đủ 90/90"] = "90/90 collected",
    ["Lò ấp đã đóng. Vào Olympus, mở hồ sơ một nhân vật trong Đền thờ và chạm Đặt làm màn chờ để nhận bạn đồng hành."] = "The incubator is closed. In Olympus, open a character's profile in the Temple and tap Set as sleep screen to get a companion.",
    ["Trứng đất sét"] = "Clay egg",
    ["Trứng bạc"] = "Silver egg",
    ["Trứng vàng"] = "Gold egg",
    ["TRỨNG ĐẤT SÉT"] = "CLAY EGG",
    ["TRỨNG BẠC"] = "SILVER EGG",
    ["TRỨNG VÀNG"] = "GOLD EGG",
    ["Đất sét"] = "Clay",
    ["Bạc"] = "Silver",
    ["Vàng"] = "Gold",
    ["Sinh vật"] = "Creature",
    ["Thần"] = "God",
    ["Titan"] = "Titan",
    ["SINH VẬT"] = "CREATURE",
    ["THẦN OLYMPUS"] = "OLYMPIAN GOD",
    ["TITAN"] = "TITAN",
    ["Sinh vật và tiểu thần"] = "Creatures and minor deities",
    ["Thần Olympus"] = "Olympian gods",
    ["Titan và thần nguyên thuỷ"] = "Titans and primordials",
    ["tới 200 trang"] = "up to 200 pages",
    ["sách mỏng"] = "short books",
    ["sách vừa"] = "medium books",
    ["sách dày"] = "long books",
    ["201 đến 499 trang"] = "201 to 499 pages",
    ["từ 500 trang"] = "500+ pages",
    ["%d trứng"] = "%d eggs",
    ["%d trang · %s"] = "%d pages · %s",
    ["%d trang"] = "%d pages",
    ["%d%%  ·  trang %d/%d"] = "%d%%  ·  page %d/%d",
    ["Ngôn ngữ / Language"] = "Ngôn ngữ / Language",
}

local M = {}

function M.setting()
    return G_reader_settings and G_reader_settings:readSetting("olympus_language") or "auto"
end

function M.detect()
    local s = M.setting()
    if s == "en" or s == "vi" then return s end
    local ui = G_reader_settings and G_reader_settings:readSetting("language") or ""
    if type(ui) == "string" and ui:sub(1, 2) == "vi" then return "vi" end
    return "en"
end

M.current = M.detect()

function M.L(s)
    if M.current == "vi" then return s end
    return EN[s] or s
end

M.EN = EN
return M
