if not CLIENT then return end

local FONT_FAMILY = "Hitmarker Text"
local function CreateFont()
    local scale = ScreenScale(0.25)
    surface.CreateFont("TRM_HUD_Firemode", {
        font = FONT_FAMILY,
        size = 30 ,
        weight = 800,
        antialias = true,
    })
    surface.CreateFont("TRM_HUD_Button", {
        font = FONT_FAMILY,
        size = 30,
        weight = 800,
        antialias = true,
    })
    surface.CreateFont("TRM_HUD_Hint", {
        font = FONT_FAMILY,
        size = 25,
        weight = 800,
        shadow = true,
    })

    surface.CreateFont("TRM_HUD_Small", {
        font = FONT_FAMILY,
        size = 16,
        weight = 800,

    })
    surface.CreateFont("TRM_Mod_Title", {
        font = FONT_FAMILY,
        size = 30,
        weight = 800,
        antialias = true,
    })

    surface.CreateFont("TRM_Mod_Subtitle", {
        font = FONT_FAMILY,
        size = 21,
        weight = 750,
        antialias = true,
    })

    surface.CreateFont("TRM_Mod_Small", {
        font = FONT_FAMILY,
        size = 17,
        weight = 700,
        antialias = true,
    })

    surface.CreateFont("TRM_Mod_Tiny", {
        font = FONT_FAMILY,
        size = 14,
        weight = 650,
        antialias = true,
    })
end
CreateFont()

hook.Add("OnScreenSizeChanged", "TRM_HUD_Text", function(oldWidth, oldHeight, newWidth, newHeight)
    CreateFont()
end)
