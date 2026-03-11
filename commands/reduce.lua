local util = require("commands.util")

local ACTIVE_PALETTE = "Active Palette"

local _reduce = util.imageIteratorHelper(function(pixel, color, palette, map, dist)
    local mapped = map[color]

    if not mapped then
        local idx = 1
        local min = 195076

        for i = 1, #palette do
            local distance = dist(palette[i], color)
            if distance < min then
                idx = i
                min = distance
            end
        end

        mapped = palette[idx]
        map[color] = mapped
    end

    pixel(mapped)
end)

---Maps each color in a region to the closest available color from `colors`.
---@param palette table<pixelColor> The list of colors as `pixelColor`s.
---@param cel Cel                   The cel to scan.
---@param selection? Selection      Selection to constrain cel region. Empty or nil selections are treated as full selections.
---@param threshhold? integer       Alpha threshhold for counting translucent colors. Unstable at 0. Default 255.
local function reduce(palette, cel, selection, threshhold)
    threshhold = threshhold or 255

    local has0 = false
    for _, c in ipairs(palette) do
        if c == 0 then
            has0 = true
            break
        end
    end

    local p = palette
    if not has0 then
        p = {0}
        for i, c in ipairs(palette) do
            p[#p+1] = c
        end
    end

    local map = {}
    for _, c in ipairs(palette) do
        map[c] = c
    end

    local dist = util.euclideanRGB
    if cel.sprite.colorMode ~= ColorMode.GRAY then
        if threshhold < 255 then
            dist = util.euclideanRGBA
        end
    else
        if threshhold < 255 then
            dist = util.euclideanGRAYA
        else
            dist = util.euclideanGRAY
        end
    end

    app.transaction("Reduce", function()
        local copy = cel.image:clone()

        _reduce(copy, cel.bounds, selection, threshhold, p, map, dist)

        cel.image = copy
    end)
    app.refresh()
end

---@param plugin Plugin
local function main(plugin)
    local spr = app.sprite
    local cel = app.cel

    local palette = {}

    local dir = app.fs.joinPath(plugin.path, "resources", "palettes")
    plugin.preferences.public = plugin.preferences.public or {}
    local public = plugin.preferences.public
    if public.palettes == nil then
        local names, paths = util.scanGPLs(dir)
        public.palettes = { names = names, paths = paths }
    end

    plugin.preferences.reduce = plugin.preferences.reduce or {}
    local private = plugin.preferences.reduce
    private.threshhold = private.threshhold or 255

    local indlg = Dialog{ title = "Reduce" }
    indlg:separator{
        id = "palette",
        text = "Palette:"
    }
    indlg:combobox{
        id = "gpl",
        label = "GPL:",
        option = ACTIVE_PALETTE,
        options = { ACTIVE_PALETTE, table.unpack(public.palettes.names) }
    }
    indlg:button{
        id = "refresh",
        text = "Rescan folder",
        onclick = function()
            local names, paths = util.scanGPLs(dir)
            public.palettes = { names = names, paths = paths }
            indlg:modify{
                id = "gpl",
                options = { ACTIVE_PALETTE, table.unpack(public.palettes.names) }
            }
        end
    }
    indlg:separator{
        id = "alpha",
        text = "Alpha Channel:"
    }
    indlg:slider{
        id = "threshhold",
        label = "Threshhold:",
        min = 0,
        max = 255,
        value = private.threshhold
    }
    indlg:newrow()
    indlg:button{ id = "ok", text = "OK", focus = true }
    indlg:button{ id = "cancel", text = "Cancel" }
    indlg:show{ wait = true }

    if not indlg.data.ok then return end
    private.threshhold = indlg.data.threshhold

    local selected = indlg.data.gpl
    if selected == ACTIVE_PALETTE then
        local pal = spr.palettes[1]
        for color in util.eachColor(pal) do
            table.insert(palette, color.rgbaPixel)
        end
    else
        local idx = nil
        for i, name in ipairs(public.palettes.names) do
            if name == selected then
                idx = i
                break
            end
        end

        if idx then
            local palettePath = public.palettes.paths[idx]
            local paletteMap = util.parseGPL(palettePath)
            if not paletteMap then
                return app.alert("Failed to load palette: " .. tostring(selected))
            end

            for k in pairs(paletteMap) do
                table.insert(palette, k)
            end
        else
            return app.alert("Selected palette not found")
        end
    end

    reduce(palette, cel, spr.selection, private.threshhold)
end

return {reduce = reduce, main = main}