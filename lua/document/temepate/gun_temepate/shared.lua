SWEP.Base = "trm_gun_base"
-- 音效和动画文件放在和 shared.lua 同级的目录下
include("sound.lua")
include("animations.lua")
SWEP.Category = "Your Category Name"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.SubCategory = "Your SubCategory Name"
SWEP.PrintName = "PrintName"
SWEP.Author = "Author Name"
SWEP.Purpose = ""


SWEP.DrawCrosshair = false

SWEP.DrawCrossHairIS = false

SWEP.ViewModelFOV = 75
SWEP.ViewModel = Model("your_vmodel_path")
SWEP.WorldModel = Model("your_wmodel_path")
SWEP.UseHands = true
SWEP.BodyGroups = {

}

if CLIENT then
    SWEP.WepSelectIcon = Material("yourMaterialPath")
end


SWEP.Slot = 2


SWEP.Primary.ClipSize = 30
SWEP.Primary.Chamber = 1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Ammo = "ar2"
SWEP.Primary.SpecialAmmo = -1
SWEP.Primary.RPM = 600
SWEP.Primary.Automatic = true


SWEP.Primary.Damage = 30
-- SWEP.Primary.Range = 5000
SWEP.Primary.Force = 1


SWEP.Primary.Sound = Sound("SoundPath")
SWEP.Primary.SliencedSound = Sound("SoundPath")
SWEP.Slienced = false -- Default Path


SWEP.Primary.NumBullets = 1


SWEP.Primary.BrustEnabled = false
SWEP.Primary.BrustNum = 3
SWEP.Primary.BrustDelay = 0.25
SWEP.Primary.BrustMode = "Single"     -- Single / Auto
SWEP.Primary.BrustModeOnce = "Single" -- Single / Full

-- SWEP.Firemode = {
--     {
--         Name = "FireModeName",
--         OnSet = function(w)

--             return FireMode_Enum
--         end,
--          Animation = "Semi_Off"
--     }
-- }



SWEP.WorldModelOffsets = {
    Bone = "tag_sling", -- false to use RenderOriginOffset
    Angles = Angle(175, 90, 0),
    Pos = Vector(1.7, 9, -4.2)
}

SWEP.VMOffset = {

    Idle = {
        Pos = Vector(0, -0, -0.5),
        Ang = Angle(-0.1, 0.5, 0),
    },
    Inspect = {
        Pos = Vector(0, -0, 0.0),
        Ang = Angle(-0.1, 0.5, 0),
    },
    Sprint = {
        Pos = Vector(-0, -0, -0),
        Ang = Angle(-0, 0, -0)
    },
    Crouch = {
        Pos = Vector(-3.5, -1, -3.5),
        Ang = Angle(0, 0, -60),
    }
}

SWEP.Effects = {
    Muzzle = {
        effect = "MuzzleFlash",
        attachment = "muzzle",
    },
    Shell = {
        attachment = "shell_eject", -- Attachment 名称
        effect = "RifleShellEject",
        Pos = Vector(0, 0, 0),      -- 位置微调
        Ang = Angle(20, 0, 0),      -- 角度微调
        Magnitude = 10,             -- 弹出力度
        Primary = true,
        Scale = 0.1,
    } -- 是否在开火时弹壳

}
SWEP.HoldType = "ar2"



SWEP.Sight = {
    Pos = Vector(-0, -0, 0),
    Ang = Angle(-0, 0, 0),
    PoseParameter = { "aim_offset" },
}
SWEP.ReloadType = "Magzine"

SWEP.IronsightReload = true

SWEP.Melee = {
    Enabled = true,
    Damage = 50,
    Range = 50, --hu
    Radius = 100,
    Force = 100,
    Sound = Sound("weapons/knife/knife_hitwall1.wav")
}

SWEP.Aim = {
    Spread = 0.005,
    SpreadFollowPrimary = false,
    Scale = 1.15,
    Time = 0.25,
    Type = "Linear",
}
SWEP.TacSight = {
    Pos = Vector(-3, 4, -3),
    Ang = Angle(0, 0, -45)
}
SWEP.Spread = {
    Base = 0.008,
    Vertical = 1.0,
    Horizontal = 1.0,
    Max = 0.15,
    Increase = 0.006,
    Recover = 0.08,
    Delay = 0.02,


}


SWEP.Recoil = {
    Vertical = { 2, 2 },
    Horizonal = { -1, 1 },
    AdsMultiplier = 0.6,
    KickDown = 0.5,
    Shake = 0.2,
    Factor = 0.7,
    -- Functional = {
    --     Increase = 0.2 ,
    --     Recover = 0.4,
    --     RecoverDelay = 0.2,
    --     Func = function(self,progress)
    --         local pitch ,yaw = -5, 0
    --         if progress >= 0.8 then
    --             pitch = 0
    --         end
    --         return pitch , -yaw
    --     end
    -- }

}

SWEP.VisualRecoil = {
    Vertical = { 1, 1 },
    Horizonal = { 1.6, -1.6 },
    Backward = { 2, 2 }, --random 1 and 2 , max 3
    RecoverSpeed = 1,
    RecoverDelay = 0.05,
    AdsMultiplier = 0.5,
    -- Functional = {
    --     Increase = 0.1 ,
    --     Recover = 1 ,
    --     RecoverDelay = 0.5,
    --     Func = function(self,progress)
    --         local pitch ,yaw ,back= 0, 0 , 0
    --         if progress < 0.1 then
    --             pitch = 2.5
    --         end

    --         return pitch , -yaw , back
    --     end
    -- }
}

SWEP.ViewmodelRecoil = {
    Pos = Vector(0, -1, -0.1),
    Ang = Angle(0, 0, 0),
    AdsMultiplier = 1,
    YawMultiplier = 1,
    PitchMultiplier = 1,

}

SWEP.CameraAttachment = "Camera"
SWEP.CameraReserve = false
SWEP.MoveSpeed = {
    Walk = 0.95,
    Run = 1,
    Aim = 0.8,
}



SWEP.CustomizeDelta = 0.15

SWEP.Attachments = {

    {
        Name = "Your Slot Name",
        Default = "", --- If you need
        Category = { "your_attachment_category" },
        ----Sight Offset
        SightPos = Vector(0, 0, 0),
        SightAng = Angle(0, 0, 0),
        --Model Offset
        Ang = Angle(0, 0, 0) ,
        Pos = Vector(0, 0, 0) ,
    } ,

}
