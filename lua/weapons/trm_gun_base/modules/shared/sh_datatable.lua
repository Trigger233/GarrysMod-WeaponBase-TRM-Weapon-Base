


function SWEP:SetupDataTables()

    self:NetworkVar("Float", "AimDelta")
    self:NetworkVar("Int", "ChamberAmmo")
    self:NetworkVar("Int", "SecondaryChamberAmmo")
    self:NetworkVar("Float", "SprintDelta")
    self:NetworkVar("Float", "NextAnimationTime")
    self:NetworkVar("Float", "NextReadyTime")
    self:NetworkVar("Entity", "NextWeapon")
    self:NetworkVar("Bool", "Grip1")
    self:NetworkVar("Bool", "Grip2")
    self:NetworkVar("Bool", "FirstDeployed")
    self:NetworkVar("Bool", "Underbarrel")
    self:NetworkVar("Int", "CurrentTask")
    self:NetworkVar("String", "PlayingSequence")
    self:NetworkVar("Bool", "CanSwitch")
    self:NetworkVar("Float", "LastFireTime")
    self:NetworkVar("Float", "Spread")
    self:NetworkVar("Float", "SpreadVertical")
    self:NetworkVar("Float", "SpreadHorizonal")
    self:NetworkVar("Angle", "Recoil")
    self:NetworkVar("Float", "RecoilProgress") -- for custom recoil
    self:NetworkVar("Float", "NextRecoil")
    self:NetworkVar("Angle", "VisualRecoil")
    self:NetworkVar("Float", "VisualRecoilProgress") -- for custom recoil
    self:NetworkVar("Float", "VisualRecoilBackward")

    self:NetworkVar("Int", "PenetrationCount")
    self:NetworkVar("Int", "FiremodeIndex")
    self:NetworkVar("Bool", "TacSight")
    self:NetworkVar("Bool", "OnLadder")
    self:NetworkVar("Bool", "FlashLightOn")
    for _ , task in pairs(self.Tasks) do
        if task.SetupDataTables then
            task:SetupDataTables(self)
        end
    end
end

