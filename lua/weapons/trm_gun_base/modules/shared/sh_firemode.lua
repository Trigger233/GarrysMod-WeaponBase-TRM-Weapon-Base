if SERVER then
    util.AddNetworkString("TRMBase_FiremodeCall")
end


function SWEP:Task_Firemode(cycle)
    local stat = self.Firemode
    if stat and self:IsAnimFinished() then
        local max = #stat
        local index = self:GetFiremodeIndex()
        if index >= max then
            index = 1
        else
            index = index + 1
        end
        self:SetFiremodeIndex(index)

        --print("Task : ChangeIndex", self:GetFiremodeIndex(), "IsServer", SERVER)
        local info = stat[index]
        if info and info.Animation then
            self:SetNextAnimationTime(0)
            self:PlayAnimation(self:ChooseAnim(info.Animation), true)
        end

        self:FireModeStat(index)
        net.Start("TRMBase_FiremodeCall")
        net.WriteInt(index, 8)
        net.WriteEntity(self)
        net.Send(self:GetOwner())
    end

    self:SetCurrentTask("Finished")
end

if CLIENT then
    net.Receive("TRMBase_FiremodeCall", function(len, ply)
        local index = net.ReadInt(8)
        local weapon = net.ReadEntity()
        weapon:FireModeStat(index)
    end)
end

function SWEP:FireModeStat(index)
    if not index then return end
    self:GetOriginStat()
    self:DeepObjectCopy(self.m_OriginalStat.Primary, self.Primary)
    self:DeepObjectCopy(self.m_OriginalStat.Secondary, self.Secondary)
    if self.Firemode and self.Firemode[index] and self.Firemode[index].OnSet then
        self.Firemode[index].OnSet(self)
    end
    --print("Firemode : ", self.Primary.Automatic, "IsServer", SERVER, "Index", index)
end

local function defmode(w)
    local defName
    if w.Primary.Burst then
        defName = (w.Primary.BrustNum or 3) .. "Round Brust"
    elseif not w.Primary.BoltAction then
        defName = w.Primary.Automatic and "FullAuto" or "SemiAuto"
    else
        defName = "Bolt-Action"
    end
    return defName
end
function SWEP:GetFiremodeName()
    local index = self:GetFiremodeIndex()
    local def = defmode(self)
    local stat = self.Firemode and self.Firemode[index] and self.Firemode[index].Name or false
    local name = stat or def
    return name
end

concommand.Add("+trmbase_cycle_firemode", function(ply)
    local weapon = ply:GetActiveWeapon()
    if not util.IsTRMBase(weapon) or not IsValid(weapon) then return end
    weapon:SetCurrentTask("Firemode")
end)
