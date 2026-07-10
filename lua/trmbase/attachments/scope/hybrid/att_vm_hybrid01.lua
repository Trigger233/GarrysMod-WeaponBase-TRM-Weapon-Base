ATTACHMENT.Base = "att_hybrid"
ATTACHMENT.Category = "att_sight"

ATTACHMENT.Name = "Hybrid 01"
ATTACHMENT.Model = Model("models/trm_attachments/optic/hybrid01.mdl")
ATTACHMENT.Selectable = true -- Leave false for Release(WIP)
ATTACHMENT.Pos = Vector(-0, -0.25, -1)
ATTACHMENT.Sight = {
    Pos = Vector(0.00, -0, 0.45),
    Align = "reticle",
    Offset = Vector(-0   ,0 ,  0) ,
    Material = Material("models/weapons/tfa_ins2/optics/eotech_reticule"),
    Size = 5,
    Color = Color(255, 0, 0),
    HideMaterial = { 2 }, --Material Index
}
ATTACHMENT.Scope = {
    Zoom = 3.0,
    Offset = Vector(0, 0, 0),
    Angle = Angle(0, 0, -90),
    Lens = { "lens_rt" } ,
    Size = 40 ,
    ParallaxSize = 700 ,
}

ATTACHMENT.HybridSight = {
    PoseParameter = "hybrid_offset" ,
    Pos = Vector(0, -0, 0.2)
} 