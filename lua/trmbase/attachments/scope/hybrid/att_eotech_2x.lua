ATTACHMENT.Base = "att_hybrid"
ATTACHMENT.Category = "att_sight"

ATTACHMENT.Name = "2x Eotech"
ATTACHMENT.Model = Model("models/trm_attachments/optic/2x_eotech.mdl")
ATTACHMENT.Selectable = true -- Leave false for Release(WIP)
ATTACHMENT.Pos = Vector(-0, 0, 0)
ATTACHMENT.Sight = {
    Pos = Vector(0.00, 0, 0.25),
    Align = "reticle",
    Offset = Vector(-0   ,0 ,  0) ,
    Material = Material("models/weapons/tfa_ins2/optics/eotech_reticule"),
    Size = 5,
    Color = Color(255, 0, 0),
    HideMaterial = { 2 }, --Material Index
}
ATTACHMENT.Scale = 0.5
ATTACHMENT.Scope = {
    Zoom = 3.0,
    Offset = Vector(0, 0, 0),
    Angle = Angle(0, 0, -90),
    Lens = { "aimpoint_lense" } ,
    Size = 40 
}

ATTACHMENT.HybridSight = {
    Bodygroup = "scope",
    Pos = Vector(0, 0, 0.275)
}