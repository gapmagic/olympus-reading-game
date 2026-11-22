--[[--
Pixel-art sprites (96x96, 4 gray tones) scaled with nearest neighbour so they
stay crisp on any Kindle screen. Scaled copies are cached.
--]]

local Blitbuffer = require("ffi/blitbuffer")
local RenderImage = require("ui/renderimage")
local ImageWidget = require("ui/widget/imagewidget")
local logger = require("logger")

local Art = {
    dir = nil,      -- set by main.lua: plugin path .. "/sprites/"
    _src = {},      -- name -> 96x96 gray table (array of rows) or false
    _cache = {},    -- name@size -> BlitBuffer
    _cache_count = 0,
}

local SRC = 96

local function loadSource(name)
    local cached = Art._src[name]
    if cached ~= nil then return cached end
    local bb = RenderImage:renderImageFile(Art.dir .. name .. ".png", false)
    if not bb then
        logger.warn("Olympus: missing sprite", name)
        Art._src[name] = false
        return false
    end
    local w, h = bb:getWidth(), bb:getHeight()
    local px = { w = w, h = h }
    for y = 0, h - 1 do
        local row = {}
        for x = 0, w - 1 do
            row[x] = bb:getPixel(x, y):getColor8().a
        end
        px[y] = row
    end
    bb:free()
    Art._src[name] = px
    return px
end

-- Returns a BlitBuffer of `size` x `size` (rounded down to a multiple of 96 when
-- that is at least 75% of the size asked, to keep pixels square and even).
function Art.bb(name, size)
    size = math.max(8, math.floor(size))
    local key = name .. "@" .. size
    local hit = Art._cache[key]
    if hit then return hit end
    local px = loadSource(name)
    local out = Blitbuffer.new(size, size, Blitbuffer.TYPE_BB8)
    out:fill(Blitbuffer.COLOR_WHITE)
    if px then
        local k = math.floor(size / px.w)
        local draw = size
        if k >= 1 and k * px.w >= size * 0.75 then draw = k * px.w end
        local off = math.floor((size - draw) / 2)
        for y = 0, px.h - 1 do
            local y0 = off + math.floor(y * draw / px.h)
            local y1 = off + math.floor((y + 1) * draw / px.h)
            local row = px[y]
            for x = 0, px.w - 1 do
                local v = row[x]
                if v < 250 then
                    local x0 = off + math.floor(x * draw / px.w)
                    local x1 = off + math.floor((x + 1) * draw / px.w)
                    out:paintRect(x0, y0, x1 - x0, y1 - y0, Blitbuffer.Color8(v))
                end
            end
        end
    end
    if Art._cache_count > 60 then
        -- Drop references only: widgets on screen may still use them; the GC frees them.
        Art._cache = {}
        Art._cache_count = 0
    end
    Art._cache[key] = out
    Art._cache_count = Art._cache_count + 1
    return out
end

function Art.widget(name, size)
    return ImageWidget:new{
        image = Art.bb(name, size),
        image_disposable = false,
        width = math.floor(size),
        height = math.floor(size),
    }
end

function Art.eggName(tier, stage, cold)
    local t = ({ "clay", "silver", "gold" })[tier] or "clay"
    if cold then return "egg_" .. t .. "_cold" end
    return "egg_" .. t .. "_" .. (stage or 0)
end

function Art.clear()
    Art._cache = {}
    Art._cache_count = 0
end

return Art
