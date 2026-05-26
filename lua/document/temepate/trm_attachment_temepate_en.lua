-- Attachment Template - Should be placed in lua/trmbase/attachments/ directory (supports subdirectories)
-- Base attachment - Other attachments can inherit from this base
-- You can also create your own Base attachment for other attachments to inherit from
-- You can define attachment properties in this file by modifying these attributes
-- If the following attachments use specific features, they need ATTACHMENT.Base = "att_base" to inherit from this Base attachment

ATTACHMENT.Name =
"att_base"                   -- Attachment name - will be displayed in the attachment slot, can be localized (GetPhrase already available in vgui)
ATTACHMENT.Category = nil    -- Attachment category - determines which slots this attachment can be installed on. Define Category in your weapon's Attachments to allow installing matching attachments
ATTACHMENT.Selectable = true -- Whether players can choose to install this attachment. Some attachments are only used to modify weapon properties or are called by other attachments, these don't need Selectable

ATTACHMENT.Description = nil -- Not implemented yet

-- Rendering related fields
ATTACHMENT.Model = nil             -- Model path
ATTACHMENT.Bonemerge = nil         -- true(default) = EF_BONEMERGE follows animation, false = FollowBone + offset. Can be used for weapon-specific attachments

ATTACHMENT.Pos = Vector(0, 0, 0)   -- Model position offset. If Bonemerge is false, this position is relative to Bone offset. If Bonemerge is true, this position is relative to the bone position when the attachment is installed
ATTACHMENT.Angles = Angle(0, 0, 0) -- Model angle offset. If Bonemerge is false, this angle is relative to Bone offset. If Bonemerge is true, this angle is relative to the bone angle when the attachment is installed

-- Laser Attachment Related Fields - You can define a Laser field to have the attachment automatically draw a laser during rendering. The specific rendering logic is already written in trmbase. Just define this field and set the parameters

ATTACHMENT.Laser = { -- Laser related settings - att_laser can automatically draw a laser during rendering by defining this field
    Attach = "Laser",
    Color = Color(255, 0, 0, 197),
    Width = 1,
    DotSize = 4,
}

-- Material cache (stored on the attachment table, not self) - Laser materials
local lineMat = nil
local dotMat = nil

function ATTACHMENT:GetLineMat()
    if not lineMat then
        lineMat = Material("sprites/physbeam")
    end
    return lineMat
end

function ATTACHMENT:GetDotMat()
    if not dotMat then
        dotMat = CreateMaterial("trmbase_laserdot", "UnLitGeneric", {
            ["$basetexture"] = "sun/overlay",
            ['$additive'] = 1,
            ['$vertexalpha'] = 1,
            ['$vertexcolor'] = 1,
        })
    end
    return dotMat
end

-- Global
function ATTACHMENT:ChangeWeaponStats(weapon)
    -- Modify weapon properties here. This function is called when the attachment is installed and uninstalled
end

-- Reticle Attachment Related Fields - You can define a Sight field to have the attachment automatically draw a reticle during rendering. The specific rendering logic is already written in trmbase. Just define this field and set the parameters
ATTACHMENT.Sight = {
    Pos = Vector(0.00, 0, -0.45), -- Reticle position offset - this position is relative to the player's view offset. Adjust this position to align the view with the reticle
    Align = "reticle",            -- Attachment name for reticle alignment
    Material = Material(),        -- Reticle material - set a material here to display a reticle for this attachment. If not set or set to nil, no reticle will be displayed
    Size = 2.56,                  -- Reticle size - this value is multiplied by screen height to calculate the actual reticle size. Adjust this value to make the reticle larger or smaller
    Color = Color(255, 0, 0),     -- Reticle color - this color is multiplied by the material's color to calculate the actual reticle color. Adjust this color to change the reticle to different colors
    HideMaterial = { 2 },         -- Not implemented yet - this field is a table of material indices. You can set some material indices here to automatically hide certain materials on the weapon model when this attachment is installed. For example, you can use it to hide the original reticle material to avoid overlapping with the new reticle. You need to know the indices of the materials you want to hide in the model to use this feature
    Rotate = 90,                  -- Reticle rotation - this is the rotation angle of the reticle. Adjust this value to rotate the reticle to different angles
}

function ATTACHMENT:Render(weapon, model) -- Render function - called when the attachment is installed. model is the attachment's model. You can modify the model to change its appearance, such as adjusting position or hiding certain submodels
    model:DrawModel()
end

function ATTACHMENT:ScaleTableValue(tableData, mul) -- This function can be used to recursively scale all numeric values in a table. For example, you can use it to proportionally adjust the impact of an attachment on weapon properties
    if not tableData then return end
    for key, val in pairs(tableData) do
        if istable(val) then
            self:ScaleTableValue(val, mul)
        else
            tableData[key] = val * mul -- ✅ Directly modify the original table's value
        end
    end
end

function ATTACHMENT:Remove(weapon, model) -- Uninstall function - called when the attachment is uninstalled. model is the attachment's model. You can modify the model to change its appearance, such as adjusting position or hiding certain submodels
    model:Remove()
end
