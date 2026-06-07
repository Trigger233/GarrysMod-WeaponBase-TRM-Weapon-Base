if SERVER then
    util.AddNetworkString("TRMBase_FiremodeCall")
end

if CLIENT then
    net.Receive("TRMBase_FiremodeCall", function(len, ply)
        local index = net.ReadInt(4)
        local weapon = net.ReadEntity()
        weapon:FireModeStat(index)
    end)
end

function SWEP:FireModeStat(index)
    if not index then return end
    if self.Firemode and self.Firemode[index] and self.Firemode[index].OnSet then
        self.Firemode[index].OnSet(self)
    end
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
    weapon:TrySetTask("Firemode")
end)
