AddCSLuaFile()

SWEP.Animations = {
    --Example Here
    --[[
    ["Defined_Animation_Class"] = {
     sequence = {"model's sequence"},
     Length = 1 , 
     RealLength = 1 ,Override Sequence Length By Time in Second
     Speed = 1 , PlayRate Default 1
     events = {

     }
]]

    ["Idle"] = {
        sequence = {"idle"}
    },
    ["Draw"] = {
        sequence = { "draw" }
    },
    ["Holster"] = {
        sequence = { "holster" }
    },
    ["Fire"] = {
        sequence = {"fire"}
    },
    ["Reload"] = {
        sequence = {"reload"} ,
        events = {
            {time = 0.5 , callback = function(Weapon)
                    Weapon:MagzineLoaded()
                end
            }
        }
    },
    --You Can Define it 
    -- ["Reload_Empty"] = {
    --     sequence = {"reload_empty"} ,
    --     events = {
    --         {time = 0.5 , callback = function(Weapon)
    --                 Weapon:MagzineLoaded()
    --             end
    --         }
    --     }
    -- },    

    ["Melee"] = {
            sequence = {"melee"} ,
        events = {
            {time = 0.5 , callback = function(Weapon)
                    Weapon:DealMeleeDamage()
                end
            }
        }    
    }

}

-- 武器自身的 PoseParameter（按需填写，模型没有对应骨骼就留空）
SWEP.BasePoseParameter = {
    Sprint = { "sprint_offset", "sprint_loop" },
    Empty = { "empty_offset" },
    Walk = { "jog_offset", "jog_loop" }
}

-- 配件 Grip 用 PoseParameter（默认留空即可，由配件系统自动处理）
SWEP.GripPoseParameters = {}
