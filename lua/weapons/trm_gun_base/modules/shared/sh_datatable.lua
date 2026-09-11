function SWEP:HasFlag(name)
    local flag = self.WeaponFlags[name]

    if not flag then
        return false
    end

    return bit.band(self:GetWeaponFlag(), flag) == flag
end

function SWEP:AddFlag(name)
    local flag = self.WeaponFlags[name]

    if not flag then
        return false
    end

    self:SetWeaponFlag(bit.bor(self:GetWeaponFlag(), flag))
    return true
end

function SWEP:RemoveFlag(name)
    local flag = self.WeaponFlags[name]

    if not flag then
        return false
    end

    self:SetWeaponFlag(bit.band(self:GetWeaponFlag(), bit.bnot(flag)))
    return true
end

function SWEP:ToggleFlag(name)
    if self:HasFlag(name) then
        self:RemoveFlag(name)
    else
        self:AddFlag(name)
    end
end

SWEP.WeaponFlags = {
    ["OnLadder"] = 1,
    ["Tacsight"] = 2,
    ["HybridOn"] = 4,
    ["FlashLightOn"] = 8,
    ['Aiming'] = 16,
    ['MeleeTriggered'] = 32,
    ['BipodDeployed'] = 64,
    ['TriggerPulled'] = 128,
    ['AkimboFired'] = 256,
}
function SWEP:SetupDataTables()
    self:NetworkVar("Int", "WeaponFlag")

    self:NetworkVar("Float", "AimDelta")
    self:NetworkVar("Float", "SprintDelta")
    self:NetworkVar("Float", "NextAnimationTime")
    self:NetworkVar("Float", "LastFireTime")
    self:NetworkVar("Float", "Spread")
    self:NetworkVar("Float", "SpreadVertical")
    self:NetworkVar("Float", "SpreadHorizonal")
    self:NetworkVar("Float", "NextRecoil")
    self:NetworkVar("Float", "RecoilUp")
    self:NetworkVar("Float", "RecoilSide")
    self:NetworkVar("Float", "CurrentCycle")
    self:NetworkVar("Entity", "NextWeapon")
    self:NetworkVar("Entity", "ShieldEntity")
    self:NetworkVar("Int", "ChamberAmmo")
    self:NetworkVar("Int", "SecondaryChamberAmmo")

    self:NetworkVar("Int", "BrustCount")
    self:NetworkVar("Int", "SprayRound")
    self:NetworkVar("Int", "CurrentTask")
    self:NetworkVar("Bool", "Grip1")
    self:NetworkVar("Bool", "Grip2")
    self:NetworkVar("Bool", "FirstDeployed")
    self:NetworkVar("Bool", "Underbarrel")
    self:NetworkVar("String", "Status")
    self:NetworkVar("Bool", "CanSwitch")
    self:NetworkVar("Angle", "VisualRecoil")

    self:NetworkVar("Int", "PenetrationCount")
    self:NetworkVar("Int", "FiremodeIndex")

    self:NetworkVar("Float", "ReloadProgress")
end

concommand.Add("trm_list_table", function(ply)
    local wep = ply:GetActiveWeapon()
    PrintTable(wep:GetTable())
end)
