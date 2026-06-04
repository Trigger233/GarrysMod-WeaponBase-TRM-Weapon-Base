SWEP.Base = "trm_gun_base"


SWEP.Category = "TriggerBase Weapon" --你想把武器放在菜单哪（次级菜单还没做）
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "武器名称"
SWEP.Author = "作者名"
SWEP.Purpose = ""
SWEP.DrawCrossHairIS = false

-- 模型
SWEP.ViewModel = "models/weapons/xxx.mdl" --- 都是路径的名字
SWEP.UseHands = true
SWEP.ViewModelFOV = 70
SWEP.WorldModel = "models/weapons/xxx.mdl"

-- 基础属性
-- SWEP.IconHeightRadio = 1.5 --虽然图标还没做好但是先放个参数在这里
SWEP.Slot = 2

-- 弹药
SWEP.Primary.ClipSize = 30
SWEP.Primary.Chamber = 1 -- 预装弹药数量，0表示不预装，1表示预装一发
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
-- 音效
-- 
-- -- SWEP.Reverb = {
--     RoomScale = 50000, --(hu)
--     --how big should an area be before it is categorized as 'outside'?
--     --h36_fire_reflection h36_fire_layer
--     Sounds = {
--         Outside = {
--             Layer = Sound("Atmo_AR.Outside"),
--             Reflection = Sound("sound_atom"),
-- --             LayerSup = Sound("Reflection_AR.Inside"),
--             ReflectionSup = Sound("sound_atom_sup")
--         },

--         Inside = {
--             Layer = Sound("Reflection_AR.Inside"),
--             Reflection = Sound("sound_atom_sup"),
--             LayerSup = Sound("Reflection_AR.Inside"),
--             ReflectionSup = Sound("sound_atom_sup")
--         }
--     }
-- }
--
-- 如果是自定义的音效 你需要在自己通过lua创建音效（你可以放个lua在lua/autorun 也可以直接include）
SWEP.Primary.Sound = Sound("武器.开火")
SWEP.Primary.SliencedSound = Sound("武器.消音开火")
SWEP.Primary.Slienced = false --配件通过修改这个数据实现消音音效切换

--高级的音效我还不知道原理，先不做

-- 换弹类型
SWEP.ReloadType = "Magzine" -- "Magzine " or "Single" 武器换弹执行动作的逻辑
--

-- 视角偏移
SWEP.VMOffset = {
    Idle = { Pos = Vector(0, 2, 1), Ang = Angle(0, 0, 0) },
    Sprint = { Pos = Vector(0, 0, 0), Ang = Angle(0, 0, 0) },
    Crouch = { Pos = Vector(-2, 0, 3), Ang = Angle(0, 0, -15) }
}

-- 特效
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

-- 世界模型偏移 通过偏移骨骼实现

SWEP.WorldModelOffsets = {
    Bone = "tag_sling",
    Angles = Angle(180, 90, 0),
    Pos = Vector(-1, 9.5, -5)
}
-- 瞄准配置
SWEP.Sight = {
    Origin = "muzzle",
    Align = nil, -- 瞄准参考附件点，替换为你的 viewmodel 上的 ironsight 附件名 不过我好像还没用上 不清楚
    Angles = Angle(0, 0, -90),
    Pos = Vector(-3.07, -1, 0.1),
    Type = "Attachment" ,
    PoseParameter = { "aim_offset" } -- 瞄准时调整PoseParameter
}

-- 后坐力
SWEP.Recoil = {
    Vertical = { 2, 2 }, -- 每次开火增加的后坐力范围
    Horizonal = { -0.3, 0.3 },  -- 水平后坐力范围，负数向左，正数向右
    AdsMultiplier = 0.1, -- 瞄准时后坐力的倍率
    KickDown = 1, -- 开火时枪口向下的程度
    Shake = 0.8, -- 开火时屏幕震动的程度
    Recover = 0.04, -- 后坐力恢复速度，数值越大恢复越快
    Factor = 0.2, -- 后坐力不平滑增加的程度，数值越大后坐力增加越快

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
    -- } -- 这里可以放置一个自定义的后坐力函数

}

-- 视觉后坐力
SWEP.VisualRecoil = {
    Vertical = { 1, 1 },
    Horizonal = { -0.1, 0.1 },
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
    -- 同上
}

-- 散布
SWEP.Spread = {
    Base = 0.009,
    Vertical = 1.0,
    Horizontal = 1.0,
    Max = 0.2,
    Increase = 0.01,
    Recover = 0.3,
    Delay = 0.1,
}

-- 瞄准
SWEP.Aim = {
    Spread = 0.005,
    SpreadFollowPrimary = false,
    Scale = 1.3,
    Time = 0.4,
}

SWEP.MoveSpeed = { Walk = 0.95, Run = 1, Aim = 0.8 }
SWEP.CameraAttachment = "Camera"
SWEP.AltSwitch = false

-- 动画
SWEP.Animations = { --有些动作是给老一派的模型用的，没有也行
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
            callback = function(
                self)
                self:MagzineLoaded() -- 动画通过执行这个函数实现换弹 另外一个可以逐发装填的是 SWEP:SingleLoad(num) num默认取0，一次上弹的数量
            end
        } }
    },
    ["Reload_Empty"] = {
        sequence = { "base_reloadempty" },
        Speed = 1.2,
        Length = 1,
        events = { {
            time = 0.5,
            callback = function(
                self)
                self:MagzineLoaded()
            end
        } }
    },
    -- ["ExampleAnim"] = {
    --     sequence = { "base_reloadempty" }, --动画序列 可以是一个字符串或者一个字符串数组 如果是数组会随机播放
    --     Speed = 1.2, --执行的速度
    --     Length = 1, --动画长度(比例) 如果你的动画长度和实际动作不符可以通过调整这个参数来让它在正确的时间执行事件
    --     RealLength = 1 , --时间（秒） 如果你的动画长度不为1秒，或者你想让它在特定的时间点执行事件，可以通过调整这个参数来实现
    --     events = { {
    --         time = 0.5   ,   callback = function(self)   self:MagzineLoaded()    end
    --     } } --动画事件 这是个数组 你可以在动画的任意时间点执行一个函数 通过调整上面的Length或者RealLength参数来让它在正确的时间点执行
    -- },
    --你可能会用到的函数：
    --[[
            SWEP:SetGrip1( bool ) 禁用/启用左手的PoseParameter
            SWEP:SetGrip1( bool ) 禁用/启用右手的PoseParameter
            SWEP:MagzineLoaded() 换弹动画中执行这个函数来实现换弹
            SWEP:SingleLoad(num) 换弹动画中执行这个函数来实现逐发装填 num默认取0，一次上弹的数量
            SWEP:EmitSound( sound ) 播放音效
    ]]
}


--这里写武器基本的PoseParameter 左右手的要用配件启用
SWEP.BasePoseParameter = {
    -- Sprint = { "sprint_loop", "sprint_offset" },
    -- Empty = { "empty_offset" },
    -- Walk = { "jog_offset", "jog_loop" }
}


-- 配件槽位
SWEP.Attachments = {
    -- {
    --     Name = "Optic", --槽位显示的名字 可以本地化，vgui里已经有GetPhrase了
    --     Category = { "att_sight" }, --可以安装的配件分类
    --     Ang = Angle(-90, 180, 90),  --配件模型角度偏移
    --     Pos = Vector(0,0,0) --模型位置偏移
    --     SightPos = Vector(-0.0, 0, -1.2), --瞄准位置偏移
    --     SightAng = Angle(-0.0, 0, -0), --瞄准角度偏移
    --     Default = "default_sight",   --默认安装的配件（无视Category）
    --     Bone = "tag_reflex"  --如果你的配件不使用骨骼合并，安装在哪一个骨骼
    -- },
    --不需要所有数据都有！
}
