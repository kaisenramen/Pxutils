local util = require("commands.util")

local FNV_OFFSET = 2166136261
local FNV_PRIME  = 16777619

local TEXT_COLOR = app.theme.color["text"]
local SEMIBLACK = Color{ r=0, g=0, b=0, a=63 }
local OTHERS_COLOR = Color{ r=127, g=127, b=127, a=15 }

local LEGEND_MAX = 18
local BASE_W = 340
local BASE_H = 325
local RANK_W = 11
local SWATCH_W = 10
local COLOR_W = 66
local FREQ_W = 32
local PCT_W  = 32
local HEADER_H = 16
local PAD = 4
local CELL_PAD = 3
local ROW_H = SWATCH_W + 2*CELL_PAD
local TABLE_GUTTER = 12
local SEGMENTS = 40

---Generates a numeric hash for a given palette's colors. Unordered and considers unique colors only.
---@param palette Palette The palette to hash.
---@return string hash
local function fnv1a(palette)
    local seen = {}
    local colors = {}

    for c in util.eachColor(palette) do
        local argb = c.rgbaPixel & 0xFFFFFFFF
        if not seen[argb] then
            seen[argb] = true
            colors[#colors + 1] = argb
        end
    end
    table.sort(colors)

    local h = FNV_OFFSET
    for _, argb in ipairs(colors) do
        for shift = 24, 0, -8 do
            h = (h ~ ((argb >> shift) & 0xFF)) & 0xFFFFFFFF
            h = (h * FNV_PRIME) & 0xFFFFFFFF
        end
    end
    return "p_" .. string.format("%08x", h)
end

local _colors = util.imageIteratorHelper(function(_, color, counterObj)
    local counter = counterObj.counter
    local c = counter[color]
    if c then
        counter[color] = c + 1
    else
        counter[color] = 1
        counterObj.numColors = counterObj.numColors + 1
    end
    counterObj.size = counterObj.size + 1
end)

---Counts each color in a cel. Optionally constrain the counting region by supplying a selection.
---@param cel Cel              The cel to scan.
---@param selection? Selection Selection to constrain scan region. Empty or nil selections are treated as full selections.
---@param threshhold? integer  Alpha threshhold for counting translucent colors. Unstable at 0. Default 255.
---@return table<pixelColor, integer> counter, integer numColors, integer size
local function colors(cel, selection, threshhold)
    local counterObj = { counter = {}, numColors = 0, size = 0 }
    _colors(cel.image, cel.bounds, selection, threshhold, counterObj)
    return counterObj.counter, counterObj.numColors, counterObj.size
end

---@param plugin Plugin
local function main(plugin)
    local spr = app.sprite
    local cel = app.cel

    local pal = spr.palettes[1]
    local key = fnv1a(pal)

    local dir = app.fs.joinPath(plugin.path, "resources", "palettes")
    plugin.preferences.public = plugin.preferences.public or {}
    local public = plugin.preferences.public
    if public.palettes == nil then
        local names, paths = util.scanGPLs(dir)
        public.palettes = { names = names, paths = paths }
    end

    plugin.preferences.colors = plugin.preferences.colors or {}
    local private = plugin.preferences.colors
    private.paths = private.paths or {}
    private.threshholds = private.threshholds or {}

    local path = private.paths[key]
    local paletteMap = path and util.parseGPL(path) or nil
    local threshhold = path and private.threshholds[key] or nil

    if not paletteMap then
        private.paths[key] = nil
        local indlg = Dialog{ title = "Colors" }
        indlg:separator{
            id = "palette",
            text = "Palette:"
        }
        indlg:combobox{
            id = "gpl",
            label = "GPL:",
            option = "Pxls C76 \"Current\"",
            options = public.palettes.names
        }
        indlg:button{
            id = "refresh",
            text = "Rescan folder",
            onclick = function()
                local names, paths = util.scanGPLs(dir)
                public.palettes = { names = names, paths = paths }
                indlg:modify{
                id = "gpl",
                options = table.unpack(public.palettes.names)
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
            value = 255
        }
        indlg:separator{
            id = "remember",
            text = "Don't Show Again for Active Palette:"
        }
        indlg:check{
            id = "hide",
            label = "Yes / No:",
            selected = false
        }
        indlg:newrow()
        indlg:button{ id = "ok", text = "OK", focus = true }
        indlg:button{ id = "cancel", text = "Cancel" }
        indlg:show{ wait = true }

        if not indlg.data.ok then return end

        local selected = indlg.data.gpl
        local idx = nil
        for i, name in ipairs(public.palettes.names) do
            if name == selected then
                idx = i
                break
            end
        end
        if idx then
            local palettePath = public.palettes.paths[idx]
            threshhold = indlg.data.threshhold
            paletteMap = util.parseGPL(palettePath)
            if paletteMap then
                if indlg.data.hide then
                    private.paths[key] = palettePath
                    private.threshholds[key] = threshhold
                end
            else
                return app.alert("Failed to load palette: " .. tostring(selected))
            end
        else
            return app.alert("Selected palette not found")
        end
    end

    local counts, colorCount, size = colors(cel, spr.selection, threshhold)
    if colorCount == 0 then return app.alert("No non-transparent pixels found") end

    local sorted = {}
    local rgba = spr.colorMode ~= ColorMode.GRAY
    local format
    if threshhold == 255 then
        format = rgba and "#%02X%02X%02X" or "#%02X"
    end
    for c, n in pairs(counts) do
        local label = paletteMap[c] or util.getHexCode(c, rgba, format)
        table.insert(sorted, { color = c, count = n, label = label })
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)

    local entries = {}
    local others = 0
    for i, entry in ipairs(sorted) do
        if i <= 2*LEGEND_MAX - 1 then
            table.insert(entries, entry)
        else
            others = others + entry.count
        end
    end
    if others > 0 then
        table.insert(entries, { color = OTHERS_COLOR, count = others, label = "Other" })
    end

    local rows = #entries
    local tables, numRows
    if rows <= LEGEND_MAX then
        tables = 1
        numRows = rows
    else
        tables = 2
        numRows = math.ceil(rows / 2)
    end

    local cols = { RANK_W, SWATCH_W, COLOR_W, FREQ_W, PCT_W }
    local tableInnerWidth = 0
    for _, w in ipairs(cols) do
        tableInnerWidth = tableInnerWidth + w + CELL_PAD
    end

    local tableWidth = tableInnerWidth + CELL_PAD + 2
    local tablesWidth = tables * tableWidth + ((tables - 1) * TABLE_GUTTER)

    local col_x = {}
    local acc = CELL_PAD
    for i, cw in ipairs(cols) do
        col_x[i] = acc
        acc = acc + cw + CELL_PAD
    end

    local outdlg = Dialog("Colors")
    outdlg:canvas{
        id = "chart",
        width = BASE_W + tablesWidth,
        height = BASE_H,
        onpaint = function(ev)
            local gc = ev.context
            gc.antialias = true
            gc.strokeWidth = 1
            gc:save()

            local w, h = gc.width, gc.height
            local pieSize = math.min(0.55*w, h - 2*PAD)
            local cx = PAD + 0.5*pieSize
            local cy = PAD + 0.5*pieSize
            local radius = 0.5*pieSize

            local thetaStart = -0.5*math.pi
            for _, entry in ipairs(entries) do
                local frac = entry.count / size
                local thetaEnd = thetaStart + 2*math.pi*frac

                gc:beginPath()
                gc:moveTo(cx, cy)

                local steps = math.max(2, math.floor(SEGMENTS * frac + 1))
                for s = 0, steps do
                    local t = s / steps
                    local a = thetaStart + t * (thetaEnd - thetaStart)
                    local x = cx + radius * math.cos(a)
                    local y = cy + radius * math.sin(a)
                    gc:lineTo(x, y)
                end

                gc:closePath()
                gc.color = entry.color
                gc:fill()

                gc.color = SEMIBLACK
                gc:stroke()

                thetaStart = thetaEnd
            end

            local tx0 = cx + radius + PAD + 10
            local idx = 1
            for t = 1, tables do
                local tableRows = numRows
                if t == 2 then
                    tableRows = rows - numRows
                end

                local tx = tx0 + (t-1) * (tableWidth + TABLE_GUTTER)
                local ty = PAD

                local tableHeight = HEADER_H + tableRows * ROW_H
                gc.color = SEMIBLACK
                gc:strokeRect(Rectangle(tx, ty, tableWidth, tableHeight))

                -- vertical separators
                for i = 1, #cols do
                    local xsep = tx + col_x[i] - CELL_PAD/2
                    gc:beginPath()
                    gc:moveTo(xsep, ty)
                    gc:lineTo(xsep, ty + tableHeight)
                    gc:stroke()
                end
                local right = tx + tableWidth
                gc:beginPath()
                gc:moveTo(right, ty)
                gc:lineTo(right, ty + tableHeight)
                gc:stroke()

                -- horizontal separators
                local headerBottom = ty + HEADER_H
                gc:beginPath()
                gc:moveTo(tx, headerBottom)
                gc:lineTo(tx + tableWidth, headerBottom)
                gc:stroke()
                for r = 1, tableRows do
                    local ysep = headerBottom + r * ROW_H
                    gc:beginPath()
                    gc:moveTo(tx, ysep)
                    gc:lineTo(tx + tableWidth, ysep)
                    gc:stroke()
                end

                gc.color = TEXT_COLOR
                local labels = { "#", " ", "Color", "Freq", "%" }
                for i, label in ipairs(labels) do
                    local hx = tx + col_x[i]
                    local hy = ty + (HEADER_H - PAD) / 2
                    gc:fillText(label, hx + 2, hy)
                end

                for r = 1, tableRows do
                    local entry = entries[idx]
                    if not entry then break end
                    local top = headerBottom + (r-1) * ROW_H

                    if idx < 2*LEGEND_MAX then
                        local rankTxt = tostring(idx)
                        local rw = gc:measureText(rankTxt).width
                        local rank_x = tx + col_x[1] + cols[1] - rw - 1
                        gc:fillText(rankTxt, rank_x, top + (ROW_H - PAD)/2)
                    end

                    local sw_x = tx + col_x[2]
                    local sw_y = top + (ROW_H - SWATCH_W)/2
                    gc.color = entry.color
                    gc:fillRect(Rectangle(sw_x, sw_y, SWATCH_W, SWATCH_W))
                    gc.color = SEMIBLACK
                    gc:strokeRect(Rectangle(sw_x, sw_y, SWATCH_W, SWATCH_W))

                    gc.color = TEXT_COLOR
                    gc:fillText(entry.label, tx + col_x[3] + 2, top + (ROW_H - PAD)/2)

                    local freqTxt = tostring(entry.count)
                    local fw = gc:measureText(freqTxt).width
                    local freq_x = tx + col_x[4] + cols[4] - fw
                    gc:fillText(freqTxt, freq_x, top + (ROW_H - PAD)/2)

                    local percentage = (entry.count / size) * 100
                    local pctTxt = string.format("%.2f%%", percentage)
                    local pw = gc:measureText(pctTxt).width
                    local pct_x = tx + col_x[5] + cols[5] - pw + 2
                    gc:fillText(pctTxt, pct_x, top + (ROW_H - PAD)/2)

                    idx = idx + 1
                end
            end

            local footer = string.format("Total pixels: %d   Unique colors: %d", size, colorCount)
            local ms = gc:measureText(footer)
            gc:fillText(footer, w - PAD - ms.width, h - PAD - 2)
            gc:restore()
        end
    }
    outdlg:button{ id="ok", text="OK" }
    outdlg:button{ id="full", text="Show Full", onclick=function()
        -- this is a temporary implmentation
        for i, c in ipairs(sorted) do
            print(string.format("%d %s %d", i, c.label, c.count))
        end
    end}
    outdlg:show()
end

return {fnv1a = fnv1a, colors = colors, main = main}