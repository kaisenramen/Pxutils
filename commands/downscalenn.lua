---Computes the greatest common factor of two integers.
---
---@param a integer Positive.
---@param b integer Positive.
---@return integer gcf
local function gcf(a, b)
    while b ~= 0 do
        a, b = b, a % b
    end
    return a
end

---Downscales an image by computing both the horizontal GCF and vertical
---GCF resizing uniformly by whichever is larger.
---
---@param cel Cel   The cel whose image will be replaced with the reduced version.
---@param img Image The source image to analyze and prune. Typically `cel.image`.
local function downscale(cel, img)
    local colorAt = img.getPixel
    local w, h = img.width - 1, img.height - 1

    local maxCommonWidth, currWidth = 0, 1
    for y = 0, h do
        for x = 1, w do
            if colorAt(img, x, y) == colorAt(img, x - 1, y) then
                currWidth = currWidth + 1
            else
                maxCommonWidth = gcf(currWidth, maxCommonWidth)
                if maxCommonWidth == 1 then break end
                currWidth = 1
            end
        end
        maxCommonWidth = gcf(currWidth, maxCommonWidth)
        if maxCommonWidth == 1 then break end
        currWidth = 1
    end

    local maxCommonHeight, currHeight = 0, 1
    for x = 0, w do
        for y = 1, h do
            if colorAt(img, x, y) == colorAt(img, x, y - 1) then
                currHeight = currHeight + 1
            else
                maxCommonHeight = gcf(currHeight, maxCommonHeight)
                if maxCommonHeight == 1 then break end
                currHeight = 1
            end
        end
        maxCommonHeight = gcf(currHeight, maxCommonHeight)
        if maxCommonHeight == 1 then break end
        currHeight = 1
    end

    local factor = math.max(maxCommonWidth, maxCommonHeight)
    app.transaction("Downscale", function()
        img:resize(img.width // factor, img.height // factor)
    end)
    app.refresh()
end

---@param plugin Plugin
local function main(plugin)
    local cel = app.cel
    local img = cel.image

    downscale(cel, img)
end

return {downscale = downscale, main = main}