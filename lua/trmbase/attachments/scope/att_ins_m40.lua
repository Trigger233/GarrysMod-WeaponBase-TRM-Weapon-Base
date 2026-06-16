ATTACHMENT.Name = "M40 Scope 8x"
ATTACHMENT.Category = "att_sight"
ATTACHMENT.Base = "att_scope"
ATTACHMENT.Selectable = true
ATTACHMENT.Model = Model("models/trm_attachments/optic/a_optic_m40.mdl")
ATTACHMENT.Angles = Angle(-180, 180, 180)
ATTACHMENT.Pos = Vector(0, 0, 0)

ATTACHMENT.Sight = {
    Pos = Vector(0, 4, 1.0),
    Align = "scope_origin",
    Size = 45,
    Color = Color(255, 255, 255) ,
    Material = Material("models/weapons/tfa_ins2/optics/mk4_crosshair"),
}

ATTACHMENT.Scope = {
    Align = "scope_origin",
    Zoom = 8,
    Offset = Vector(0,0,0) ,
    Angle = Angle(0,0,-90),
    DrawAt = 0.35,
    Lens = {"lense_rt"} ,
    Max = 16 ,
    DynamicCrosshair = true
}
function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Aim.Time = weapon.Aim.Time * 1.1
end


--[[
ATTACHMENT.Scope = {
    Align = "scope_origin",
    Zoom = 4,
    FOV = 12,
    RTSize = 512,
    ScreenScale = 0.62,
    ReticleSize = 230,
    LensSize = 2.1,
    ReticleLineColor = Color(0, 0, 0, 245),
    BackdropAlpha = 245,
    RTAttachment = "scope_origin",
    RTAttachmentRadius = 0.1,
    RTAttachmentOffset = -2.2,
    RTAttachmentSegments = 10,
    RTFlipU = true,
    RTFlipV = true,
    RTTextureRotate = 90,
    DrawAttachmentReticle = false,
    UseAttachmentReticleMaterial = true,
    AttachmentReticleMaterialScale = 1.5,
    AttachmentReticleColor = Color(255, 0, 0, 235),
    AttachmentReticleOffset = -0.03,
    AttachmentReticleGap = 0.035,
    AttachmentReticleLength = 0.56,
    AttachmentReticlePost = 0.74,
    HideScopeGlass = true,
    HideReticleMaterial = true,
    UseMaterialReticle = false,
    UseMaterialReticle3D = false,
    TextureRotate = 0,
    DrawAt = 0.35,
    CameraForward = 0,
    ZNear = 1
}
    function ATTACHMENT:Render(wep, model)
--     if CLIENT and TRM_ScopePiP and TRM_ScopePiP.RenderScopeAttachment then
--         return TRM_ScopePiP.RenderScopeAttachment(wep, model, self)
--     end

--     if IsValid(model) then
--         model:DrawModel()
--     end
end
]]