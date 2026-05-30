function SWEP:Task_Firemode(cycle)
    local stat = self.Firemode
    if stat then
        local max = #stat
        local index = self:GetFiremodeIndex()
        if index >= max then
            self:SetFiremodeIndex(1)
        else
            self:SetFiremodeIndex(index + 1)
        end
        local info = stat[index]
        if info and info.Animation then
            self:SetNextAnimationTime(0)
            self:PlayAnimation(self:ChooseAnim(info.Animation), true)
        end

        self:FireModeStat() 
    end

    self:SetCurrentTask("Finished")
end     



function SWEP:FireModeStat()
    if SERVER then
        self:CallOnClient("FireModeStat")
    end
    local index = self:GetFiremodeIndex()
    if self.Firemode and self.Firemode[index] and self.Firemode[index].OnSet then
        self.Firemode[index].OnSet(self)
    end
end
local function defmode(w)
    local defName
    if w.Primary.Burst then
        defName = (w.Primary.BrustNum or 3) .. "Round Brust"
    elseif not w.BoltAction then
        defName = w.Primary.Automatic and "FullAuto" or "SemiAuto"
    else
        defName = "Bolt-Action"
    end
    return defName
end
function SWEP:GetFiremodeName()
    local index = self:GetFiremodeIndex()
    local def = defmode(self)
    local stat = self.Firemode[index] and self.Firemode[index].Name or false
    local name = stat or def
    return name
end

concommand.Add("+trmbase_cycle_firemode", function(ply)
    local weapon = ply:GetActiveWeapon()
    if not util.IsTRMBase(weapon) or not IsValid(weapon) then return end
    weapon:SetCurrentTask("Firemode")
end)
