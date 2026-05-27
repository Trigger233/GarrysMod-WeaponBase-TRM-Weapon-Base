if SERVER then return end

TRM_ScopePiP = TRM_ScopePiP or {}

local P = TRM_ScopePiP

P.Config = P.Config or {}
P.Config.RTNamePrefix = "youraddon_elcan_pip_rt_"
P.Config.MaterialNamePrefix = "youraddon_scope_pip_mat_"
P.Config.SkipNeedles = { "parallax_mask", "reticule", "reticle" }
P.Config.FallbackReticle = "models/weapons/tfa_ins2/optics/elcan_reticule"
P.Config.ReticleMaterial = "youraddon/scopes/elcan_reticle"
P.Config.MaskMaterial = "youraddon/scopes/elcan_mask"
P.Config.LensOverlayMaterial = "youraddon/scopes/elcan_lens_overlay"
P.Config.AimThreshold = 0.55
P.Config.UseAttachmentCamera = false
P.Config.ElcanPiPOffsetPos = Vector(0, 0, 0)
P.Config.ElcanPiPOffsetAng = Angle(0, 0, 0)
P.Config.DefaultLensRadius = 0.49
P.Config.DefaultReticleRadius = 0.72
P.Config.DefaultEdgeSoftness = 0.09
P.Config.DefaultReticleOffset = Vector(0, 0, 0)
P.Config.ScopeProfiles = {
    -- att_ins_elcan = {
    --     FOV = 14,
    --     LensNeedles = { "lense_rt", "optic_lense" },
    --     Reticle = "models/weapons/tfa_ins2/optics/elcan_reticule",
    --     FlipX = false,
    --     FlipY = false,
    --     LensRadius = 0.49,
    --     ReticleRadius = 0.72,
    --     ReticleOffset = Vector(0, 0.00, 0),
    --     EdgeSoftness = 0.09,
    --     EdgeAlpha = 190,
    --     CounterRollScale = 0.25,
    --     CounterRollMax = 4,
    --     CounterRollSmooth = 8,
    --     AutoRecoilBackScale = 0.04,
    --     AutoRecoilAngleScale = 0.08,
    --     AutoRecoilMaxBack = 0.025,
    --     AutoRecoilSmooth = 42
    -- }
}

P.CVars = P.CVars or {
    enable = CreateClientConVar("cl_youraddon_elcan_pip_enable", "1", true, false,
        "Enable the ELCAN-only PiP render target."),
    res = CreateClientConVar("cl_youraddon_elcan_pip_res", "512", true, false,
        "ELCAN PiP RT resolution: 256, 512, or 1024."),
    fps = CreateClientConVar("cl_youraddon_elcan_pip_fps", "60", true, false, "ELCAN PiP max update FPS."),
    fov = CreateClientConVar("cl_youraddon_elcan_pip_fov", "14", true, false, "ELCAN PiP camera FOV."),
    reticle = CreateClientConVar("cl_youraddon_elcan_pip_reticle", "1", true, false,
        "Draw ELCAN reticle inside the PiP RT."),
    mask = CreateClientConVar("cl_youraddon_elcan_pip_mask", "1", true, false, "Draw ELCAN PiP lens mask/vignette."),
    debug = CreateClientConVar("cl_youraddon_elcan_pip_debug", "0", true, false, "Print ELCAN PiP debug output.")
}

function P.GetBool(name, fallback)
    local cv = P.CVars and P.CVars[name]
    if not cv then return fallback end
    return cv:GetBool()
end

function P.GetFloat(name, fallback)
    local cv = P.CVars and P.CVars[name]
    if not cv then return fallback end
    return cv:GetFloat()
end

function P.GetResolution()
    return 1024
end

function P.DebugPrint(...)
    if not P.GetBool("debug", false) then return end
    print("[TRM ELCAN PiP]", ...)
end
