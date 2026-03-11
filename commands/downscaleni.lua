---Downscales an image by removing duplicate adjacent rows and columns.
---This may damage the image.
---
---@param cel Cel   The cel whose image will be replaced with the reduced version.
---@param img Image The source image to analyze and prune. Typically `cel.image`.
local function downscale(cel, img)
    local m, n = img.width - 1, img.height - 1

    local mat = {}

    local np = 0
    local x = 0

    local row = {}
    local last = nil

    for pixel in img:pixels() do
        row[x] = pixel()
        if x == m then
            local same = false
            if last then
                same = true
                for j = 0, m do
                    if row[j] ~= last[j] then
                        same = false
                        break
                    end
                end
            end

            if not same then
                mat[np] = row
                last = row
                np = np + 1
            end

            row = {}
            x = 0
        else
            x = x + 1
        end
    end

    np = np - 1

    local keep = {}
    local lastj = nil

    for j = 0, m do
        local same = false
        if lastj ~= nil then
            same = true
            for i = 0, np do
                local row_ = mat[i]
                if row_[j] ~= row_[lastj] then
                    same = false
                    break
                end
            end
        end

        if not same then
            keep[#keep+1] = j
            lastj = j
        end
    end

    local mp = #keep - 1

    app.transaction("Downscale", function()
        if mp == m and np == n then return end

        local new = Image(mp + 1, np + 1, img.colorMode)

        for pixel in new:pixels() do
            pixel(mat[pixel.y][keep[pixel.x + 1]])
        end

        cel.image = new
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