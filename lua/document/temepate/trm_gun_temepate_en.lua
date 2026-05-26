SWEP.Base = "trm_gun_base"

SWEP.Category = "TriggerBase Weapon" -- Where you want the weapon in the menu (submenu not implemented yet)
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "Weapon Name"
SWEP.Author = "Author Name"
SWEP.Purpose = ""
SWEP.DrawCrosshair = false
SWEP.DrawCrossHairIS = false

-- Models
SWEP.ViewModel = "models/weapons/xxx.mdl" -- Path to the model
SWEP.UseHands = true
SWEP.ViewModelFOV = 70
SWEP.WorldModel = "models/weapons/xxx.mdl"

-- Base Properties
-- SWEP.IconHeightRadio = 1.5 -- Parameter placeholder, though icons are not yet implemented
SWEP.Slot = 2

-- Ammunition
SWEP.Primary.ClipSize = 30
SWEP.Primary.Chamber = 1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Ammo = "ar2"
SWEP.Primary.SpecialAmmo = -1
SWEP.Primary.RPM = 700
SWEP.Primary.Automatic = true
SWEP.Primary.Damage = 34
SWEP.Primary.Force = 1
SWEP.Primary.NumBullets = 1
-- SWEP.Primary.Trigger = {
--     Time = 0 ,
--     Type = "Hold", -- or "Tap"
--     Sound = Sound() ,
-- }

-- Sound Effects
-- For custom sound effects, you need to create them via Lua (you can place a Lua file in lua/autorun or simply include it)
SWEP.Primary.Sound = Sound("Weapon.Fire")
SWEP.Primary.SliencedSound = Sound("Weapon.SilencedFire")
SWEP.Primary.Slienced = false -- Attachments modify this data to toggle silenced sound effects

-- Advanced sound effect principles not yet understood, not implemented yet

-- Reload Type
SWEP.ReloadType = "Magazine" -- "Magazine" or "Single" - Logic for weapon reload execution

-- Viewmodel Offset
SWEP.VMOffset = {
    Idle = { Pos = Vector(0, 2, 1), Ang = Angle(0, 0, 0) },
    Sprint = { Pos = Vector(0, 0, 0), Ang = Angle(0, 0, 0) },
    Crouch = { Pos = Vector(-2, 0, 3), Ang = Angle(0, 0, -15) }
}

-- Effects
SWEP.Effects = {
    Muzzle = {
        effect = "MuzzleEffect",
        attachment = "muzzle"
    },
    Shell = {
        attachment = "shell",
        effect = "RifleShellEject",
        Pos = Vector(0, 0, 0),
        Ang = Angle(20, 0, 0),
        Magnitude = 10,
        Primary = true,
    }
}

SWEP.HoldType = "ar2"

-- World Model Offset - Achieved by offsetting bones
SWEP.WorldModelOffsets = {
    Bone = "tag_sling",
    Angles = Angle(180, 90, 0),
    Pos = Vector(-1, 9.5, -5)
}

-- Aiming Configuration
SWEP.Sight = {
    Origin = "muzzle",
    Align = nil, -- Aiming reference attachment point, replace with your viewmodel's ironsight attachment name. Not yet used, unclear
    Angles = Angle(0, 0, -90),
    Pos = Vector(-3.07, -1, 0.1),
    Type = "Attachment",
    PoseParameter = { "aim_offset" } -- Adjust PoseParameter when aiming
}

-- Recoil
SWEP.Recoil = {
    Vertical = { 2, 2 },
    Horizontal = { -0.3, 0.3 },
    AdsMultiplier = 0.1,
    KickDown = 1,
    Shake = 0.8,
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
    -- } -- Place a custom recoil function here
}

-- Visual Recoil
SWEP.VisualRecoil = {
    Vertical = { 1, 1 },
    Horizontal = { -0.1, 0.1 },
    Backward = { 0.1, 0.1, 1 },
    RecoverSpeed = 0.1,
    RecoverDelay = 0.1,
    AdsMultiplier = 1,
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
    -- Same as above
}

-- Spread
SWEP.Spread = {
    Base = 0.009,
    Vertical = 1.0,
    Horizontal = 1.0,
    Max = 0.2,
    Increase = 0.01,
    Recover = 0.3,
    Delay = 0.1,
}

-- Aiming
SWEP.Aim = {
    Spread = 0.005,
    SpreadFollowPrimary = false,
    Scale = 1.3,
    Time = 0.4,
}

SWEP.MoveSpeed = { Walk = 0.95, Run = 1, Aim = 0.8 }
SWEP.CameraAttachment = "Camera"
SWEP.AltSwitch = false

-- Animations
SWEP.Animations = { -- Some animations are for older model types and are optional
    ["Draw"] = { sequence = { "base_draw" } },
    ["Draw_First"] = { sequence = { "base_ready" } },
    ["Holster"] = { sequence = { "base_holster" } },
    ["Idle"] = { sequence = { "base_idle" } },
    ["Idle_Empty"] = { sequence = { "empty_idle" } },
    ["Iron_Idle"] = { sequence = { "base_idle" } },
    ["Sprint"] = { sequence = { "base_sprint" }, Speed = 1.1 },
    ["Sprint_Empty"] = { sequence = { "empty_sprint" }, Speed = 1.1 },
    ["Fire"] = { sequence = { "base_fire" } },
    ["Fire_Last"] = { sequence = { "base_fire_last" } },
    ["Iron_Fire"] = { sequence = { "iron_fire" } },
    ["Iron_Fire_Last"] = { sequence = { "iron_fire_last" } },
    ["Reload"] = {
        sequence = { "base_reload" },
        Speed = 1.2,
        Length = 1,
        events = { {
            time = 0.5,
            callback = function(self)
                self:MagazineLoaded() -- The animation executes this function to perform reload. Another option for single-shot loading is SWEP:SingleLoad(num) where num defaults to 0 for the number of rounds loaded at once
            end
        } }
    },
    ["Reload_Empty"] = {
        sequence = { "base_reloadempty" },
        Speed = 1.2,
        Length = 1,
        events = { {
            time = 0.5,
            callback = function(self)
                self:MagazineLoaded()
            end
        } }
    },
    -- ["ExampleAnim"] = {
    --     sequence = { "base_reloadempty" }, -- Animation sequence - can be a string or an array of strings. If an array, it will play randomly
    --     Speed = 1.2, -- Execution speed
    --     Length = 1, -- Animation length (ratio) - if your animation length doesn't match the actual action, adjust this parameter to execute events at the correct time
    --     RealLength = 1 , -- Time (seconds) - if your animation length is not 1 second, or you want to execute events at specific time points, adjust this parameter to achieve that
    --     events = { {
    --         time = 0.5   ,   callback = function(self)   self:MagazineLoaded()    end
    --     } } -- Animation events - this is an array. You can execute a function at any time point during the animation. Adjust the Length or RealLength parameters above to execute at the correct time points
    -- },
    -- Useful functions you might need:
    --[[
            SWEP:SetGrip1( bool ) Enable/disable left hand PoseParameter
            SWEP:SetGrip2( bool ) Enable/disable right hand PoseParameter
            SWEP:MagazineLoaded() Execute this function during reload animation to perform reload
            SWEP:SingleLoad(num) Execute this function during reload animation for single-shot loading - num defaults to 0 for the number of rounds loaded at once
            SWEP:EmitSound( sound ) Play sound effect
    ]]
}

-- Basic weapon PoseParameters - left/right hands need to be enabled via attachments
SWEP.BasePoseParameter = {
    -- Sprint = { "sprint_loop", "sprint_offset" },
    -- Empty = { "empty_offset" },
    -- Walk = { "jog_offset", "jog_loop" }
}

-- Attachment Slots
SWEP.Attachments = {
    -- {
    --     Name = "Optic", -- Slot display name - can be localized (GetPhrase already available in vgui)
    --     Category = { "att_sight" }, -- Categories of attachments that can be installed
    --     Ang = Angle(-90, 180, 90),  -- Attachment model angle offset
    --     Pos = Vector(0,0,0) -- Model position offset
    --     SightPos = Vector(-0.0, 0, -1.2), -- Aiming position offset
    --     SightAng = Angle(-0.0, 0, -0), -- Aiming angle offset
    --     Default = "default_sight",   -- Default installed attachment (ignores Category)
    --     Bone = "tag_reflex"  -- If your attachment doesn't use bone merging, specify which bone to install on
    -- },
    -- Not all data fields are required!
}
