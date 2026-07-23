if SERVER then
    util.AddNetworkString("TRMBase_SwitchHybrid")

    net.Receive("TRMBase_SwitchHybrid", function(len, ply)
        local weapon = net.ReadEntity()
        local forceDown =net.ReadBool()
        if weapon.Hybrid then
            weapon:Hybrid(forceDown)
        end
    end)
end

function SWEP:Hybrid(ForceOff)
    if ForceOff then
        self:RemoveFlag("HybridOn")
        return
    end
    self:ToggleFlag("HybridOn")
end

function SWEP:CanAim()
    local seq = self:GetPlayingSequence()
    if self:GetSprintDelta() > 0.5 or (self.IronsightReload == false and self:IsReloading()) or string.find(seq, "Melee") or string.find(seq, "Holster") or string.find(seq, "Draw") then return false end
    return true
end

local cvar_aimspeed = CreateConVar("trmbase_sv_mod_aimspeed", 1, FCVAR_ARCHIVE, "", 0, 10)
function SWEP:GetAimSpeed()
    return FrameTime() / self.Aim.Time * cvar_aimspeed:GetFloat()
end

function SWEP:GetAimTime()
    return self.Aim.Time / cvar_aimspeed:GetFloat()
end

function SWEP:AimIn()
    if self.Aim.Type == "Linear" then
        self.m_AimDelta = math.Approach(self.m_AimDelta, 1, self:GetAimSpeed())
    else
        self.m_AimDelta = Lerp(2.5 * self:GetAimSpeed(), self.m_AimDelta, 1)
    end
    if not self.m_Aiming then
        if self:IsAnimFinished() then
            self:TrySetTask("AdsIn")
        end
        self.m_Aiming = true
        self:AddFlag("Aiming")
    end
end

function SWEP:AimOut()
    if self.Aim.Type == "Linear" then
        self.m_AimDelta = math.Approach(self.m_AimDelta, 0, self:GetAimSpeed())
    else
        self.m_AimDelta = Lerp(2.5 * self:GetAimSpeed(), self.m_AimDelta, 0)
    end
    if self.m_Aiming then
        if self:IsAnimFinished() then
            self:TrySetTask("AdsOut")
        end
        self.m_Aiming = false
        self:RemoveFlag("Aiming")
    end
end

local cvar_toggle = CreateClientConVar("trmbase_toggle_aim", 0, true, true, "", 0, 1)
function SWEP:AimLogic()
    if SERVER and not IsFirstTimePredicted() then return end
    if self.DisableIronsight then
        return
    end
    if not cvar_toggle:GetBool() then
        -- 这里是按住开镜
        if self:GetOwner():KeyDown(IN_ATTACK2) and self:CanAim() then
            self:AimIn()
        else
            self:AimOut()
        end
    else
        if (self:GetOwner():KeyPressed(IN_ATTACK2) and self:CanAim()) then
            self.m_AimToggle = not self.m_AimToggle or false
        end

        if (self.m_AimToggle && self:CanAim()) then
            self:AimIn()
        else
            self:AimOut()
            self.m_AimToggle = false
        end
    end

    if SERVER then
        self:SetAimDelta(self.m_AimDelta)
    end

    return true
end

function SWEP:AimThink()
    if SERVER and IsFirstTimePredicted() then
        self:AimLogic()
    end
end

function SWEP:CycleTacSight()
    self:ToggleFlag("Tacsight")
    if self:HasFlag("HybridOn") then
        self:RemoveFlag("HybridOn")
    end
end



concommand.Add("+trmbase_cycle_tacsight", function(ply)
    local weapon = ply:GetActiveWeapon()



    if weapon.CycleTacSight then
        weapon:CycleTacSight()
        return
    end
end)
