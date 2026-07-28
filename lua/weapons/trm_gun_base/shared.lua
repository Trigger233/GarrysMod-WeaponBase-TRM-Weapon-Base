if SERVER then
    AddCSLuaFile()
    util.AddNetworkString("TRMBase_Attachment")
    util.AddNetworkString("TRMBase_SyncAttachment")
    util.AddNetworkString("TRMBase_SyncAllAttachments")

    -- 注册服务端桩命令，使这些命令在控制台中可识别（实际逻辑在客户端执行）
end

require("trm_utils")
-- ==========================================
-- 包含所有 shared 文件（服务端+客户端都执行）
-- ==========================================
local SHARED_PRIORITY = {
    "sh_tasks.lua", "sh_datatable.lua",
}

local function IncludeSharedFiles()
    -- print("start load")
    local folder = "weapons/trm_gun_base/modules/shared/"
    local allFiles, _ = file.Find(folder .. "*.lua", "LUA")

    -- 排序：优先级高的放前面，其他按原顺序
    table.sort(allFiles, function(a, b)
        local aPriority = table.HasValue(SHARED_PRIORITY, a)
        local bPriority = table.HasValue(SHARED_PRIORITY, b)
        if aPriority ~= bPriority then
            return aPriority -- 优先级高的排前面
        end
        return a < b         -- 同优先级按名字排序
    end)

    for _, fileName in ipairs(allFiles) do
        local fullPath = folder .. fileName
        if SERVER then AddCSLuaFile(fullPath) end
        include(fullPath)
        -- print("load trm gun base : ", fullPath)
    end
end


local function IncludeTaskFiles()
    local folder = "weapons/trm_gun_base/modules/shared/tasks/"
    local files, _ = file.Find(folder .. "*.lua", "LUA")
    for _, fileName in ipairs(files) do
        local fullPath = folder .. fileName
        if SERVER then
            AddCSLuaFile(fullPath)
        end
        include(fullPath)
    end
end

-- ==========================================
-- 包含所有 client 文件（只在客户端执行，但需要发送给客户端）
-- ==========================================
local function IncludeClientFiles()
    local folder = "weapons/trm_gun_base/modules/client/"
    local files, _ = file.Find(folder .. "*.lua", "LUA")
    for _, fileName in ipairs(files) do
        local fullPath = folder .. fileName
        if SERVER then
            AddCSLuaFile(fullPath) -- 发送给客户端
        end
        if CLIENT then
            include(fullPath) -- 客户端执行
        end
    end
end

local function IncludeClientAttachmentsFiles()
    local folder = "weapons/trm_gun_base/modules/client/attachments/"
    local files, _ = file.Find(folder .. "*.lua", "LUA")
    for _, fileName in ipairs(files) do
        local fullPath = folder .. fileName
        if SERVER then
            AddCSLuaFile(fullPath) -- 发送给客户端
        end
        if CLIENT then
            include(fullPath) -- 客户端执行
        end
    end
end


if CLIENT then
    CreateClientConVar("trmbase_cl_keybind_melee", 0, true, false, "Melee keybind")
    CreateClientConVar("trmbase_cl_keybind_inspect", 0, true, false, "Inspect keybind")
    CreateClientConVar("trmbase_cl_keybind_customize", 0, true, false, "Customize keybind")
    CreateClientConVar("trmbase_cl_keybind_firemode", 0, true, false, "Firemode keybind")
end
IncludeClientAttachmentsFiles()
IncludeSharedFiles()
IncludeTaskFiles()
IncludeClientFiles()

SWEP.IsTRMWeapon = true

SWEP.Category = "TriggerBase Weapon"
SWEP.Spawnable = false
SWEP.AdminOnly = false
SWEP.PrintName = "TRM Base Weapon"
SWEP.Author = "TriggerMiku"
SWEP.Purpose = "A base weapon for TRM weapons."

SWEP.AutoSwitchTo = true
SWEP.DrawCrosshair = false
SWEP.DrawCrossHairIS = false

SWEP.ViewModel = nil
SWEP.UseHands = true
SWEP.ViewModelFOV = 55
SWEP.WorldModel = nil

SWEP.BodyGroup = {

}
SWEP.Skin = 0

SWEP.RenderGroup = RENDERGROUP_OPAQUE
SWEP.RenderMode = RENDERMODE_NORMAL

SWEP.BobScale = 0
SWEP.SwayScale = 0

SWEP.Slot = 3




SWEP.IconHeightRadio = 1.5

--icon
if CLIENT then
    -- 重绘武器选择界面
    function SWEP:DrawWeaponSelection(x, y, w, h, alpha)
        local iconID = Material("vgui/hud/" .. self:GetClass())
        --self.WepSelectIcon = iconID
        local base, vertical = iconID:Width(), iconID:Height()
        if iconID then
            surface.SetDrawColor(255, 255, 255, alpha)
            surface.SetMaterial(iconID)

            surface.DrawTexturedRect(x, y, w, h * (vertical / base) * self.IconHeightRadio)
        end
    end
end
SWEP.m_WeaponDeploySpeed = 1
SWEP.Primary.ClipSize = 8
SWEP.Primary.ChamberSize = 1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Ammo = ""
SWEP.Primary.SpecialAmmo = -1
SWEP.Primary.RPM = 600
SWEP.Primary.Automatic = false
-- SWEP.Primary.Trigger = {
--     Time = 0 ,
--     Type = "Hold", -- or "Tap"
--     Sound = Sound() ,
-- }

--

SWEP.Primary.BoltAction = false

SWEP.m_EjectDelay = 0.0

SWEP.Primary.Damage = 8



-- SWEP.Primary.Range = 5000
SWEP.Primary.Force = 1
SWEP.Primary.Velocity = 500
SWEP.Primary.Sound = Sound("")
SWEP.Primary.SliencedSound = nil
SWEP.Slienced = false

-- SWEP.Reverb = {
--     RoomScale = 50000, --(hu)
--     --how big should an area be before it is categorized as 'outside'?
--     --h36_fire_reflection h36_fire_layer
--     Sounds = {
--         Outside = {
--             Layer = Sound("Atmo_AR.Outside"),
--             Reflection = Sound("sound_atom"),
-- --             LayerSup = Sound("Reflection_AR.Inside"),
--             ReflectionSup = Sound("sound_atom")

--         },

--         Inside = {
--             Layer = Sound("Reflection_AR.Inside"),
--             Reflection = Sound("sound_atom"),
--             LayerSup = Sound("Reflection_AR.Inside"),
--             ReflectionSup = Sound("sound_atom")
--         }
--     }
-- }

SWEP.Primary.NumBullets = 6

SWEP.Primary.FireMode = "FullAuto"
SWEP.Primary.BrustNum = 3
SWEP.Primary.BrustDelay = 0.25
SWEP.Primary.BrustMode = "Single"     -- Single / Auto
SWEP.Primary.BrustModeOnce = "Single" -- Single / Full

SWEP.Secondary.ClipSize = 0
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Ammo = -1

SWEP.HoldType = "shotgun"
SWEP.ReloadType = "Single"

SWEP.IronsightReload = true

SWEP.Effects = {
    Muzzle = {
        effect = "MuzzleEffect",
        ParticleEffect = "trm_muzzleflash",
        ParticleSuppressed = "trm_suppressor",
        attachment = "muzzle",
        Tracer = {
            IsParticle = true,
            Name = "trm_tracer"
        }
    },
    Shell = {
        attachment = "shell",  -- Attachment 名称
        effect = "ShellEject",
        Pos = Vector(0, 0, 0), -- 位置微调
        Ang = Angle(0, 0, 0),  -- 角度微调
        Magnitude = 10,        -- 弹出力度
        Primary = true,
    }                          -- 是否在开火时弹壳

}

SWEP.Offset = {
    -- Pos = Vector(1,19,-2),
    -- Ang = Angle(0,-0,180)
}
SWEP.WorldModelOffsets = {   --alternative
    Bone = "tag_weapon",     -- 武器模型上的骨骼名
    Pos = Vector(0, 0, 0),   -- 位置偏移
    Angles = Angle(0, 0, 0), -- 角度偏移
}


SWEP.Sight = {
    Ang = Angle(0, 0, -0),
    Pos = Vector(0, 0, 0),
}

SWEP.TacSight = {
    Pos = Vector(-2, 0, -2),
    Ang = Angle(0, 0, -45)
}



SWEP.Melee = {
    Enabled = true,
    Damage = 50,
    Range = 200, --hu
    Radius = 100,
    Force = 8000,
    Sound = Sound("weapons/knife/knife_hitwall1.wav")
}

SWEP.Aim = {
    Spread = 0.03,
    SpreadFollowPrimary = false,
    Scale = 1.15,
    Time = 0.25,
    Type = "Linear" -- "Linear" or "Lerp"
}

SWEP.ShootPosOffset = Vector(0, -0, -0)
SWEP.ShootPosOffsetAim = Vector(0, -0, -0)

SWEP.Spread = {
    Base = 0.05,
    Vertical = 1.0,
    Horizontal = 1.0,
    Max = 0.2,
    Increase = 0.12,
    Recover = 0.3,
    Delay = 0.3,
    MoveMultiplier = 2.6,
    AirMultiplier = 5,


}

SWEP.Bullet = {
    HeadShotMultiplier = 4,
    Penetration = {
        Max = 2,
        DamageMultiplier = 0.5,
        ArmorPenetrateDamage = 0.01,
    }
}



SWEP.Recoil = {
    Vertical = { 5.5, 5.5 },
    Horizonal = { -0.0, 0.0 },
    AdsMultiplier = 0.7,
    KickDown = 1,
    Shake = 1,
    Functional = {
        Increase = 0.2,
        Recover = 0.4,
        RecoverDelay = 0.5,
        Func = function(self, progress)
            local pitch, yaw = 0, 0

            return pitch, yaw
        end
    }

}

SWEP.VisualRecoil = {
    Vertical = { 3, 3 },
    Horizonal = { -0, 0 },
    Backward = { 5, 5 }, --random 1 and 2 , max 3
    RecoverSpeed = 0.6,
    AdsMultiplier = 0.7,
    -- Functional = {
    --     Increase = 0.2 ,
    --     Recover = 0.4,
    --     RecoverDelay = 0.5,
    --     Func = function(self,progress)
    --         local pitch ,yaw ,back= 0, 0 , 0
    --         if progress >= 0.8 then
    --             yaw = math.random(1,1.2)
    --             pitch = math.random(1,1.2)
    --         end
    --         return pitch , -yaw , back
    --     end
    -- }

}

SWEP.ViewmodelRecoil = {
    Pos = Vector(0, -0, -0),
    Ang = Angle(-0.0, 0, 0),
    AdsMultiplier = 0.25,
}

SWEP.CameraShake = {
    Angle = Angle(0, 0, 0),
    AdsMult = 0.25,
}
SWEP.CameraAttachment = "Camera"
SWEP.CameraOffset = Angle(0, 0, 0)
SWEP.CameraReserve = false
SWEP.MoveSpeed = {
    Walk = 0.95,
    Run = 1,
    Aim = 0.5,
}
SWEP.AltSwitch = false
SWEP.Animations = {
    -- ["Draw"] = {
    --     sequence = {"draw"} ,

    -- },
    -- ["Draw_First"] = {
    --     sequence = {"base_ready","ready2"}
    -- },
    -- ["Melee"] = {
    --     sequence = {"base_melee_bash"},
    --     events = {
    --         {time = 0.2 , callback= function(self)
    --             self:DealMeleeDamage()
    --         end}
    --     },

    -- },
    -- ["Melee_Empty"] = {
    --     sequence = {"base_melee_bash_empty"},
    --     events = {
    --         {time = 0.2 , callback= function(self)
    --             self:DealMeleeDamage()
    --         end}
    --     },
    -- },
    -- ["Holster"] = {
    --     sequence = {"holster"} ,
    -- },
    -- ["Idle"] = {
    --     sequence = {"base_idle" } ,
    -- },
    -- ["Iron_Idle"] = {
    --     sequence = {"base_idle"}
    -- },
    -- ["Iron_Idle_Empty"] = {
    --     sequence = {"iron_empty_idle"}
    -- },
    -- ["Idle_Empty"] = {
    --     sequence = {"empty_idle"}
    -- },
    -- ["Sprint"] = {
    --     sequence = {"base_sprint"},
    --     Speed = 1.1,

    -- },
    -- ["Sprint_Empty"] = {
    --     sequence = {"empty_sprint"} ,
    --     Speed = 1.1,

    -- },
    -- ["Fire"] = {
    --     sequence = {"fire2"},
    -- },
    -- ["Fire_Last"] = {
    --     sequence = {"firelast"}
    -- },
    -- ["Iron_Fire_Last"] = {
    --     sequence = {"iron_firelast"}
    -- },
    -- ["Iron_Fire"] = {
    --     sequence = {"iron_fire"}
    -- },
    -- ["Reload_Empty"] = {
    --     sequence = {"reload_empty"},
    --     Length = 2.5 ,
    --     events ={
    --         {time = 0.5 , callback = function(self)
    --             self:SingleLoaded()
    --         end}
    --     }
    -- },
    -- ["Reload"] = {
    --     sequence = {"reload"},
    --     Speed = 0.3,
    --     Length = 0.3 ,
    --     events = {
    --         { time = 0.2 , callback = function(self) self:SingleLoaded()   end},
    --         { time = 0.35 , callback = function(self) self:EmitSound("m1014shell1")   end},
    --         { time = 0.35 , callback = function(self) self:SingleLoaded()   end},
    --     }
    -- },
    -- ["Reload_End"] = {
    --     sequence = { "reload_shotgun_finish"}
    -- },
    -- ["Reload_Start"] = {
    --     sequence = {"reload_shotgun_start"}
    -- },
    -- ["Inspect"] = {
    --     sequence = {"inspect"} ,
    --     events = {
    --         {time = 0.1 , callback = function(self)
    --             self:SetClip1(self:Clip1() - 1 )
    --             local owner = self:GetOwner()
    --             owner:SetAmmo(owner:GetAmmoCount(self.Primary.Ammo) + 1 , self.Primary.Ammo )
    --         end},
    --         {time = 0.7 , callback = function(self)
    --             self:SetClip1(self:Clip1() + 1 )
    --             local owner = self:GetOwner()
    --             owner:SetAmmo(owner:GetAmmoCount(self.Primary.Ammo) - 1 , self.Primary.Ammo )
    --         end},
    --     }
    -- },
    -- ["Inspect_Empty"] = {
    --     sequence = {"inspect_empty"}
    -- },
}
SWEP.CustomizeDelta = 0.15

SWEP.VMOffset = {

    Idle = {
        Pos = Vector(2, -2, 0.5),
        Ang = Angle(-0, 0, -0)
    },
    Sprint = {
        Pos = Vector(-0, -0, -0),
        Ang = Angle(-0, 0, -0)
    },
    Crouch = {
        Pos = Vector(0, -0, 0),
        Ang = Angle(0, 0, 0)
    }
}

SWEP.GripPoseParameters = {

}

SWEP.BasePoseParameters = {
    idle = { "a_idle_active" },
    aim = { "aim_offset" },
    walk = { "walk_offset", "walk_loop" },
    jog = { "jog_offset", "jog_loop" },
    sprint = { "sprint_offset", "sprint_loop" }
}

SWEP.HUDElement = {
    Bullet = color_white
}

function SWEP:GetHUDElement(name)
    return self.HUDElement[name]
end

function SWEP:Initialize()
    self.m_ViewModel = Model(self.ViewModel)


    self:SetHoldType(self.HoldType)
    self:SetWeaponHoldType("ar2")
    self.m_HoldType = self.HoldType
    self:SetHoldType(self.m_HoldType)
    self.m_FirstDeployed = true
    self.m_bTaskCache = {}
    -- self:UpdateSelectIcon()
    self.m_LastEmptySoundTime = 0
    self.m_ViewModelFOV = self.ViewModelFOV
    self:SetFirstDeployed(true)
    self.m_CrouchLerp = 0
    self.m_AimDelta = 0
    self.m_Aiming = false
    self.m_AimTime = self.Aim.Time
    self.m_AimSpread = 0

    self.m_WalkDeltaLerp = 0

    self.m_WalkPose = 0

    self.m_SprintDeltaLerp = 0
    self.m_SprintPose = 0

    self.WeaponFlags = {}

    self.m_MoveSpeed = self.MoveSpeed
    self.m_Spread = self.Spread.Base

    self.m_Recoil = Angle(0, 0, 0)
    self.m_CurrentRecoil = Angle(0, 0, 0)

    self.m_VRecoil = Angle(0, 0, 0)
    self.m_CameraShake = 0
    self.m_MoveSpeedWalk = self.MoveSpeed.Walk
    self.m_MoveSpeedRun = self.MoveSpeed.Run
    self.m_MoveSpeedAim = self.MoveSpeed.Aim
    self:ResetChamberRound()

    self:SetFiremodeIndex(1)
    self:FireModeStat(1)

    self:SetBrustCount(self.Primary.BrustNum)
    self.ZeroDistance = 50

    self.m_Attachment = {}
    self.m_Bone = {}
    self.m_Particles = {}

    self.CurrentAttachments = self.CurrentAttachments or {}
    self.Attachments = self.Attachments or {}
    self:SetClip1(self.Primary.ClipSize)
    self:SetClip2(self.Secondary.ClipSize)

    -- 迁移旧格式：CurrentAttachments 存字符串 → 改存 {Class=...}
    for k, v in pairs(self.CurrentAttachments) do
        if type(v) == "string" then
            self.CurrentAttachments[k] = { Class = v }
        end
    end

    self:EquipDefaultAttachments()
    timer.Simple(0.5, function()
        if IsValid(self) then
            self:BuildCustomizedGun()
        end
    end)
end

SWEP.Attachments = {}
function SWEP:GetViewModel(index)
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return nil end
    return owner:GetViewModel(index or 0) or false
end

local cvar_attachment = GetConVar("trmbase_load_attachment_on_pickup")

function SWEP:Equip()
    self:SetFirstDeployed(true)
    -- 服务端同步配件给客户端
    if cvar_attachment:GetBool() then
        self:LoadAttachmentPreset()
    end
    self:BuildCustomizedGun()
end

function SWEP:Deploy()
    self:GetOwner():SetSaveValue("m_flNextAttack", 0)
    self:BuildCustomizedGun()
    self:GetViewModel().m_CustomDelta = 1
    self:TrySetTask("Deploy")
    self:SetCanSwitch(false)
    self:SetAimDelta(0)
    return true
end

function SWEP:OnDrop(owner)
    --owner:SetActiveWeapon(NULL)
    if CLIENT then
        if IsValid(TRM_AttachMenu_Instance) then
            TRM_AttachMenu_Instance:Close()
        end
        self:CleanupFlashLights()
    end
    return true
end

function SWEP:OnReloaded()
    self:OnAttachmentChanged(true)
end

function SWEP:OnRestore()
    timer.Simple(FrameTime() * 5, function()
        if SERVER and cvar_attachment:GetBool() then
            -- 先加载保存的配件配置
            self:EquipDefaultAttachments()
            self:LoadAttachmentPreset()
        end
        self:BuildCustomizedGun()
        self:SetNextRecoil(0)
    end)
end

function SWEP:CanPrimaryAttack()

end

local cvar = CreateConVar("trmbase_autoreload", 1, FCVAR_ARCHIVE)


function SWEP:PrimaryAttack()
    if not IsFirstTimePredicted() then return end

    if self:GetUnderbarrel() then
        if not self:CanSecondaryFire() then
            if self:Clip2() == 0 and cvar:GetInt() == 1 then
                self:Reload()
            end
            return false
        end
        self:TrySetTask("UnderbarrelFire")
    else
        if self:IsEmpty() and cvar:GetInt() == 1 then
            self:Reload()

            return false
        end
        if self.Primary.Trigger then
            self:TrySetTask("Charge")
        else
            self:TrySetTask("PrimaryFire")
        end
    end
end

function SWEP:SecondaryAttack()

end

function SWEP:Reload()
    if self:GetUnderbarrel() then
        self:TrySetTask("UnderBarrel_Reload")
        return true
    end
    self:TrySetTask("Reload")
    return true
end

function SWEP:IsEmpty()
    return (self:Clip1() <= 0)
end

function SWEP:IsFull()
    return (self:Clip1() >= (self.Primary.ClipSize + self.Primary.ChamberSize))
end

SWEP.BasePoseParameter = {
    -- Sprint = {"sprint_loop" , "sprint_offset"} ,
    -- Empty = {"empty_offset"} ,
    -- Walk = {"jog_offset","jog_loop"}
}

hook.Add("PlayerPostThink", "PoseParameterControl", function(ply)
    local weapon = ply:GetActiveWeapon()
    if not weapon then return end
    if not util.IsTRMBase(weapon) then
        return
    end

    --weapon:bThink()
    weapon:Sprint()
end)


SWEP.Attachments = {
    -- ["#TrmBase_Sight"] = {
    --     Category = {"Ins2_ksg_optic","att_optic"},
    --     Pos = Vector(0,0,0) ,
    --     Ang = Angle(0,0,0) ,
    --     DefaultAttachment = "ins2_ksg_ironsight" ,
    --     Bone = "A_Optic" ,
    -- },
}




-- 放在 shared.lua 的 SERVER 块中
if SERVER then
    -- 初始化玩家移速倍率表
    local function InitMoveData(ply)
        if not ply.TRM_MoveSpeed then
            ply.TRM_MoveSpeed = {
                Run = 1.0,
                Walk = 1.0,
            }
        end
    end

    function SWEP:SetPlayerMoveMult(ply, runMult, walkMult)
        if not IsValid(ply) then return end
        InitMoveData(ply)
        ply.TRM_MoveSpeed.Run = runMult or 1.0
        ply.TRM_MoveSpeed.Walk = walkMult or 0.95
    end

    -- Hook Move
    hook.Add("Move", "TRM_MoveSpeed", function(ply, mv)
        if not IsValid(ply) then return end

        local wep = ply:GetActiveWeapon()
        if wep and wep.GetPlayerMoveMult then
            local runMult, walkMult = wep:GetPlayerMoveMult(ply)
            if runMult then
                -- 只需要修改 MaxSpeed，这是真正影响移动速度的值
                mv:SetMaxSpeed(mv:GetMaxSpeed() * runMult)
            end
        end
    end)
end

local cvar_reload_slowmove = CreateConVar("trmbase_sv_reload_slowdown", 0, { FCVAR_ARCHIVE }, "helptext", 0, 1)
-- 在武器文件中
function SWEP:GetPlayerMoveMult(ply)
    local aimDelta = self:GetAimDelta() or 0
    local sprintDelta = self:GetSprintDelta() or 0

    local runMult = 1.0
    local walkMult = self.MoveSpeed.Walk or 0.95

    if sprintDelta > 0.5 then
        runMult = self.MoveSpeed.Sprint or 1.1
    elseif aimDelta > 0.5 then
        runMult = Lerp(aimDelta, 1.0, self.MoveSpeed.Aim or 0.5)
    else
        runMult = self.MoveSpeed.Run or 1.0
    end

    if cvar_reload_slowmove:GetBool() and self:IsReloading() then
        runMult = 0.7
    end

    return runMult, walkMult
end

function SWEP:ShouldDropOnDie(arguments)
    return true
end

function SWEP:OnDrop(owner)
    self:BuildCustomizedGun()
end

function SWEP:OnRemove()
    self:RemoveAllAttachementModels()

    if CLIENT then
        self:CleanupFlashLights()
    end
end

local Path = "autorun/trm_loader.lua"

if (SERVER) then
    util.AddNetworkString("TRMBase_UpdateAttachments")
else
    net.Receive("TRMBase_UpdateAttachments", function(len, ply)
        BASE_TRM_ATTS = {}

        include(Path)
    end)
end


concommand.Add("trmbase_reload_atts", function()
    TRMWeaponBase:UpdateAllAttachment()
end)

TRMWeaponBase = TRMWeaponBase or {}

function TRMWeaponBase:UpdateAllAttachment()
    BASE_TRM_ATTS = {}
    AddCSLuaFile(Path)
    include(Path)
    net.Start("TRMBase_UpdateAttachments")
    net.Broadcast()
end
