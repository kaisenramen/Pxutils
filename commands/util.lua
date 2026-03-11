local util = {}

local rgbaR = app.pixelColor.rgbaR
local rgbaG = app.pixelColor.rgbaG
local rgbaB = app.pixelColor.rgbaB
local rgbaA = app.pixelColor.rgbaA
local grayaV = app.pixelColor.grayaV
local grayaA = app.pixelColor.grayaA

---@class PixelIterator
---@field x integer
---@field y integer
---@operator call: fun(self: PixelIterator): pixelColor
---@operator call: fun(self: PixelIterator, val: pixelColor)

--- Takes coords relative to a reference cel and returns the absolute.
--- 
--- @param x integer          The x-coordinate of the point.
--- @param y integer          The y-coordinate of the point.
--- @param bounds Rectangle   The cel bounds that `(x, y)` is relative to.
--- @return integer x, integer y
function util.abs(x, y, bounds)
    return x + bounds.x, y + bounds.y
end

--- Takes absolute coords and returns them relative to a reference cel. 
--- 
--- @param x integer          The x-coordinate of the point.
--- @param y integer          The y-coordinate of the point.
--- @param bounds Rectangle   The cel bounds that `(x, y)` is relative to.
--- @return integer x, integer y
function util.rel(x, y, bounds)
    return x - bounds.x, y - bounds.y
end

--- Creates a specialized image iterator that applies a function to each
--- pixel of a cel that satisfies optional selection and alpha constraints.
---
--- The returned iterator scans the pixels of `cel.image` within the cel's
--- bounds, optionally intersected with a supplied `Selection`. For each pixel
--- whose alpha value meets or exceeds the specified threshold, `func` is
--- invoked.
---
--- Additional arguments passed to the returned iterator are forwarded to
--- `func` unchanged.
---
---@param func fun(pixel: PixelIterator, color: pixelColor, ...)
---@return fun(image: Image, bounds: Rectangle, selection?: Selection, threshold?: integer, ...)
function util.imageIteratorHelper(func)
    local alpha = rgbaA

    return function(image, bounds, selection, threshold, ...)
        selection = selection or Selection()
        threshold = math.max(0, math.min(threshold or 255, 255))

        local rect = bounds
        local empty = selection.isEmpty

        if not empty then
            rect = rect:intersect(selection.bounds)
        end

        rect.x = rect.x - bounds.x
        rect.y = rect.y - bounds.y

        if empty then
            for pixel in image:pixels(rect) do
                local color = pixel()
                if alpha(color) >= threshold then
                    func(pixel, color, ...)
                end
            end
        else
            for pixel in image:pixels(rect) do
                local color = pixel()
                if alpha(color) >= threshold
                ---@diagnostic disable-next-line: param-type-mismatch
                and selection:contains(util.abs(pixel.x, pixel.y, bounds)) then
                    func(pixel, color, ...)
                end
            end
        end
    end
end

--- Iterates over each color in a given palette. Returns `Color` objects. Therefore,
--- unsuitable for performance-heavy tasks.
---
--- @param palette Palette The palette to iterate over.
--- @return fun(): Color | nil
function util.eachColor(palette)
    local color = palette.getColor
    local i = 0
    local n = #palette
    return function()
        if i < n then
            local c = color(palette, i)
            i = i + 1
            return c
        end
    end
end

--- Calculates the square Euclidean distance between two RGB colors.
--- 
--- @param color1 pixelColor An integer.
--- @param color2 pixelColor An integer.
--- @return integer distance
function util.euclideanRGB(color1, color2)
    local dr = rgbaR(color2) - rgbaR(color1)
    local dg = rgbaG(color2) - rgbaG(color1)
    local db = rgbaB(color2) - rgbaB(color1)

    return dr*dr + dg*dg + db*db
end

--- Calculates the square Euclidean distance between two RGBA colors.
--- 
--- @param color1 pixelColor An integer.
--- @param color2 pixelColor An integer.
--- @return number distance
function util.euclideanRGBA(color1, color2)
    local dr = rgbaR(color2) - rgbaR(color1)
    local dg = rgbaG(color2) - rgbaG(color1)
    local db = rgbaB(color2) - rgbaB(color1)
    local af = (rgbaA(color1) + rgbaA(color2)) / 510

    return af*(dr*dr + dg*dg + db*db)
end

--- Calculates the square Euclidean distance between two GRAY colors.
--- 
--- @param color1 pixelColor An integer.
--- @param color2 pixelColor An integer.
--- @return integer distance
function util.euclideanGRAY(color1, color2)
    local dv = grayaV(color2) - grayaV(color1)

    return dv*dv
end

--- Calculates the sqaure Euclidean distance between two GRAYA colors.
--- 
--- @param color1 pixelColor An integer.
--- @param color2 pixelColor An integer.
--- @return number distance
function util.euclideanGRAYA(color1, color2)
    local dv = grayaV(color2) - grayaV(color1)
    local af = (grayaA(color1) + grayaA(color2)) / 510

    return af*dv*dv
end

--- Returns the hex code of `color`. This is formatted in Aseprite's style,
--- that is, `#000000 A0` through `#FFFFFF A255`.
--- 
--- You may optionally specify the colormode. If `false`, `color` will be
--- treated as a 16-bit grayscale-alpha color. This defaults to `true`,
--- which corresponds to RGBA.
--- 
--- You may optionally include a format string. By default, this is
--- `#%02X%02X%02X A%u` for RGBA, and "#%02X A%u" for GRAYA.
--- 
--- @param color Color | pixelColor May either be a `Color` object or a `pixelColor`.
--- @param rgba? boolean            Defaults to `true`. Use `false` for GRAYA.
--- @param format? string           A C-style format string.
--- @return string code             The resulting hex code.
function util.getHexCode(color, rgba, format)
    if rgba ~= false then
        if type(color) ~= "number" then
            color = color.rgbaPixel
        end
        local r = rgbaR(color)
        local g = rgbaG(color)
        local b = rgbaB(color)
        local a = rgbaA(color)

        format = format or "#%02X%02X%02X A%u"
        return string.format(format, r, g, b, a)
    else
        if type(color) ~= "number" then
            color = color.grayPixel
        end
        local V = grayaV(color)
        local A = grayaA(color)

        format = format or "#%02X A%u"
        return string.format(format, V, A)
    end
end

---Parses GPL file and returns its Name field. If it lacks one, the file's name is returned instead.
---If the file can't be read or can't be found, retuns nil.
---@param path string The file to read.
---@return string|nil name
function util.nameOfGPL(path)
    local f = io.open(path, "r")
    if not f then return nil end

    for line in f:lines() do
        local name = line:match("^Name:%s*(.+)")
        if name then
            f:close()
            return name
        end
    end
    f:close()
    return app.fs.fileTitle(path)
end

---Parses GPL file and returns map of pixelColors to their names.
---If the file can't be read or can't be found, returns nil.
---@param path string The file to read.
---@return table<pixelColor>|nil paletteMap
function util.parseGPL(path)
    local f = io.open(path, "r")
    if not f then return nil end

    local rgba = app.pixelColor.rgba
    local paletteMap = {}

    for line in f:lines() do
        line = line:match("^%s*(.-)%s*$")
        if line:match("^%d") then
            local r, g, b, n = line:match("^(%d+)%s+(%d+)%s+(%d+)%s*(.*)$")
            if n and n ~= "" then
                paletteMap[rgba(r, g, b)] = n
            end
        end
    end

    f:close()
    return paletteMap
end

---Scans a directory and returns an array of names, and a map of names to paths.
---@param dir string The directory to scan.
---@return table<string> paletteNames
---@return table<string> palettePaths
function util.scanGPLs(dir)
    local paletteNames = {}
    local palettePaths = {}

    for _, file in pairs(app.fs.listFiles(dir)) do
        if app.fs.fileExtension(file):lower() == "gpl" then
            local path = app.fs.joinPath(dir, file)
            local name = util.nameOfGPL(path)
            if name ~= nil then
                table.insert(paletteNames, name)
                table.insert(palettePaths, path)
            end
        end
    end

    return paletteNames, palettePaths
end

-- Generic helper functions --

function util.dump(t)
    if type(t) ~= "table" then
        print(t)
        return
    end

    for k, v in pairs(t) do
        print(string.format("%s %s %s", k, v, type(v)))
    end
end

function util.delimit(integer, format)
    format = format or "%1,%2"
    local n, k = integer, nil
    while true do
        n, k = string.gsub(n, "^(-?%d+)(%d%d%d)", format)
        if k == 0 then break end
    end
    return n
end

return util