if not CLIENT then return end

local FONT_FAMILY = "Hitmarker Text"
local function CreateFont()
    local scale = ScreenScale(0.25)
    surface.CreateFont("TRM_HUD_Firemode", {
        font = FONT_FAMILY,
        size = 30 * scale,
        weight = 800,
        antialias = true,
    })
    surface.CreateFont("TRM_HUD_Button", {
        font = FONT_FAMILY,
        size = 40,
        weight = 800,
        antialias = true,
    })
    surface.CreateFont("TRM_HUD_Hint", {
        font = FONT_FAMILY,
        size = 30,
        weight = 800,
        shadow = true,
    })

    surface.CreateFont("TRM_HUD_Small", {
        font = FONT_FAMILY,
        size = 18,
        weight = 800,

    })
end
CreateFont()

hook.Add("OnScreenSizeChanged", "TRM_HUD_Text", function(oldWidth, oldHeight, newWidth, newHeight)
    CreateFont()
end)
