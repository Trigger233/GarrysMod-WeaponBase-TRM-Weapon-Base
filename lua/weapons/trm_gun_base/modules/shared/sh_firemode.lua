function SWEP:FireModeStat(index)
    if not index then return end


    if self.Firemode and self.Firemode[index] and self.Firemode[index].OnSet then
        local stat = self.Firemode[index].OnSet(self)
                self.Primary.BrustEnabled = false

        if( stat != nil) then
            if stat == -1 then
                self.Primary.Automatic = false
            elseif stat == 0 then
                self.Primary.Automatic = true
            elseif stat > 0 then
                self.Primary.BrustEnabled = true
            end
        end
    end
end

if SERVER then
    util.AddNetworkString("TRMBase_FiremodeCall")
end

if CLIENT then
    net.Receive("TRMBase_FiremodeCall", function(len, ply)
        local index = net.ReadInt(4)
        local weapon = net.ReadEntity()
        if weapon.FireModeStat then
            weapon:FireModeStat(index)
        end
    end)
end



local function defmode(w, mode)
    local defName
    if w[mode].Burst then
        defName = (w[mode].BrustNum or 3) .. "Round Burst"
    elseif not w[mode].BoltAction then
        defName = w[mode].Automatic and "FullAuto" or "SemiAuto"
    else
        defName = "Bolt-Action"
    end
    return defName
end

function SWEP:GetFiremodeName()
    -- 如果是下挂模式
    if self:GetUnderbarrel() then
        return ("UnderBarrel-" .. defmode(self, "Secondary"))
    end

    -- 正常主武器模式
    local index = self:GetFiremodeIndex()
    local stat = self.Firemode and self.Firemode[index] and self.Firemode[index].Name or false
    if stat then
        return stat
    end

    return defmode(self, "Primary")
end

concommand.Add("+trmbase_cycle_firemode", function(ply)
    local weapon = ply:GetActiveWeapon()
    if not util.IsTRMBase(weapon) or not IsValid(weapon) then return end
    weapon:TrySetTask("Firemode")
end)
