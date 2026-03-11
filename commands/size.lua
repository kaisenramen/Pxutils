local util = require("commands.util")

local _size = util.imageIteratorHelper(function(_, _, sizeObj)
    sizeObj[1] = sizeObj[1] + 1
end)

---Maps each color in a region to the closest available color from `colors`.
---@param cel Cel              The cel to scan.
---@param selection? Selection Selection to constrain cel region. Empty or nil selections are treated as full selections.
---@param threshhold? integer  Alpha threshhold for counting translucent colors. Unstable at 0. Default 255.
---@return integer size
local function size(cel, selection, threshhold)
    local sizeObj = { 0 }
    _size(cel.image, cel.bounds, selection, threshhold, sizeObj)
    return sizeObj[1]
end

---@param plugin Plugin
local function main(plugin)
    local spr = app.sprite
    local cel = app.cel

    plugin.preferences.size = plugin.preferences.size or {}
    local private = plugin.preferences.size
    private.threshhold = private.threshhold or 255

    local indlg = Dialog{ title = "Visible Size" }
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

    local n = size(cel, spr.selection, private.threshhold)
    local w, h = cel.bounds.width, cel.bounds.height

    local outdlg = Dialog{ title = "Visible Size" }
    outdlg:label{
        id = "size",
        label = "Visible pixels:",
        text = util.delimit(n)
    }
    outdlg:label{
        id = "box",
        label = "Bounding box:",
        text = string.format(
            "%s x %s (%s)",
            util.delimit(w),
            util.delimit(h),
            util.delimit(w * h)
        )
    }
    outdlg:button{ id = "ok", text = "OK", focus = true }
    outdlg:show{ wait = true }
end

return {size = size, main = main}