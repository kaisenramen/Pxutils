if app.apiVersion == nil or app.apiVersion < 27 then
    app.alert("Pxutils requires Aseprite 1.3.3 or greater.")
    return
end

-- ----------------------------------------------------------- --
--     Command Name         -- Menu Group         -- Version   --
-- Pxls ------------------- -- ------------------ -- --------- --
--     Import Pxls Canvas   -- File > Import      -- Planned   --
--     Import Pxls Template -- File > Import      -- Planned   --
--     Export Pxls Template -- File > Export      -- Planned   --
-- Pixel Art -------------- -- ------------------ -- --------- --
--     Colors               -- Edit > Pxutils     -- Added 1.0 --
--     Reduce               -- Edit > Pxutils     -- Added 1.0 --
--     Visual Size          -- Sprite             -- Added 1.0 --
--     Nearest-Neighbor     -- Sprite > Downscale -- Added 1.0 --
--     Non-Integer          -- Sprite > Downscale -- Added 1.0 --
--     Seam Carving         -- Sprite > Downscale -- Planned   --
-- ----------------------------------------------------------- --

local commands = require("commands.init")

local FILE_IMPORT = "file_import_1"
local FILE_EXPORT = "file_export_2"
local EDIT_INSERT = "edit_insert"
local SPRITE_SIZE = "sprite_size"
local PXUTILS = "pxutils"
local DOWNSCALE = "downscale"

local function isCanvasAvailable()
    return app.sprite ~= nil and app.cel ~= nil
end

function init(plugin)
    local function plug(command) return function() command(plugin) end end
    -- plugin:newMenuSeparator{ group=FILE_IMPORT }
    -- plugin:newCommand{
    --     id="import_pxls_canvas",
    --     title="Import Canvas",
    --     group=FILE_IMPORT,
    --     onclick=function()
    --         app.alert("Error: not implemented")
    --     end
    -- }
    -- plugin:newCommand{
    --     id="import_pxls_template",
    --     title="Import Pxls Template",
    --     group=FILE_IMPORT,
    --     onclick=function()
    --         app.alert("Error: not implemented")
    --     end
    -- }

    -- plugin:newMenuSeparator{ group=FILE_EXPORT }
    -- plugin:newCommand{
    --     id="export_pxls_template",
    --     title="Export Pxls Template",
    --     group=FILE_EXPORT,
    --     onclick=function()
    --         app.alert("Error: not implemented")
    --     end,
    --     onenabled=isCanvasAvailable
    -- }

    plugin:newMenuSeparator{ group=EDIT_INSERT }
    plugin:newMenuGroup{
        id=PXUTILS,
        title="Pxutils",
        group=EDIT_INSERT
    }
    plugin:newCommand{
        id="pxutils_colors",
        title="Colors...",
        group=PXUTILS,
        onclick=plug(commands.colors.main),
        onenabled=isCanvasAvailable
    }
    plugin:newCommand{
        id="pxutils_reduce",
        title="Reduce...",
        group=PXUTILS,
        onclick=plug(commands.reduce.main),
        onenabled=isCanvasAvailable
    }
    plugin:newMenuSeparator{ group=PXUTILS }
    plugin:newCommand{
        id="pxutils_restore",
        title="Restore Defaults",
        group=PXUTILS,
        onclick=function()
            if app.alert{
                title = "Warning",
                text = "Restore default settings?",
                buttons = {"OK", "Cancel"}
            } == 1 then
                plugin.preferences.colors = nil
                plugin.preferences.reduce = nil
                plugin.preferences.size = nil
            end
        end
    }

    plugin:newCommand{
        id="visual_size",
        title="Visual Size...",
        group=SPRITE_SIZE,
        onclick=plug(commands.size.main),
        onenabled=isCanvasAvailable
    }

    plugin:newMenuGroup{
        id=DOWNSCALE,
        title="Downscale",
        group=SPRITE_SIZE,
    }
    plugin:newCommand{
        id="downscale_nearest_neighbor",
        title="Nearest-Neighbor",
        group=DOWNSCALE,
        onclick=plug(commands.downscalenn.main),
        onenabled=isCanvasAvailable
    }
    plugin:newCommand{
        id="downscale_non_integer",
        title="Non-Integer",
        group=DOWNSCALE,
        onclick=plug(commands.downscaleni.main),
        onenabled=isCanvasAvailable
    }
end

function exit(plugin) end