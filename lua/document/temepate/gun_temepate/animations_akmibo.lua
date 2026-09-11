AddCSLuaFile()
SWEP.Animations = {
    ["Draw"] = {
        sequence = { "deploy" },

    },

    ["Melee"] = {
        sequence = { "melee" },
        Length = 0.5,
        events = {
            {
                time = 0.2,
                callback = function(self)
                    self:DealMeleeDamage()
                end
            }
        },

    },
    -- ["Melee_Empty"] = {
    --     sequence = {"base_melee_bash_empty"},
    --     events = {
    --         {time = 0.2 , callback= function(self)
    --             self:DealMeleeDamage()
    --         end}
    --     },
    -- },
    ["Holster"] = {
        sequence = { "holster" },
    },
    ["Idle"] = {
        sequence = { "idle" },
    },
    ["Idle_Empty"] = {
        sequence = { "idle_empty" },
    },
    ["Idle_Empty2"] = {
        sequence = { "idle_leftempty" },
    },
    ["Fire"] = {
        sequence = { "shoot_left" },
    },
    ["Fire_Last"] = {
        sequence = { "shoot_leftlast" }
    },
    ["Fire2"] = {
        sequence = { "shoot_right" },
    },
    ["Fire_Last2"] = {
        sequence = { "shoot_rightlast" }
    },
    -----------------------------Reload--------------------------------------------------------------
    ["Reload_Empty"] = {
        sequence = { "reload_empty" },
        Length = 0.9,

        events = {
            { time = 0.0, callback = function(self) self:SetGrip1(false) end },
            { time = 0.8, callback = function(self) self:SetGrip1(true) end },
            {
                time = 0.4,
                callback = function(self)
                    self:DropMagazine()
                end
            },
            {
                time = 0.55,
                callback = function(self)
                    self:MagzineLoaded()
                end
            }
        }
    },

    ["Reload"] = {
        sequence = { "reload" },
        Length = 0.9,
        events = {
            { time = 0.00, callback = function(self) self:SetGrip1(false) end },
            { time = 0.8,  callback = function(self) self:SetGrip1(true) end },
            { time = 0.45, callback = function(self) self:MagzineLoaded() end },
        }
    },





    ---------------------------------------------------------------------------------------------------
    ["Inspect"] = {
        sequence = { "inspect" },
        events = {
            { time = 0.0,  callback = function(self) self:SetGrip1(false) end },
            { time = 0.80, callback = function(self) self:SetGrip1(true) end },
        }
    },

    ["Inspect_Empty"] = {
        sequence = { "inspect_empty" },
        events = {
            { time = 0.0,  callback = function(self) self:SetGrip1(false) end },
            { time = 0.80, callback = function(self) self:SetGrip1(true) end },
        }
    },
    -----------------------------------------------------------------------------------------------------
    ["Ads_In"] = {
        sequence = { "ads_in" },
        Length = 0.5,
    },
    ["Ads_Out"] = {
        sequence = { "ads_out" },
        Length = 0.5,

    },


    ["Sprint"] = {
        sequence = { "idle_raw" }
    },

}

SWEP.BasePoseParameter = {
    -- Sprint = { "sprint_loop" },
    Empty = { "empty_offset" },
    -- Walk = { "jog_offset", "jog_loop" }
}

SWEP.GripPoseParameters = {
}

