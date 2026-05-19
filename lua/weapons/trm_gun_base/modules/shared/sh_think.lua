function SWEP:Think()
    self:SetWeaponHoldType(self.HoldType)

    -- 缓存当前播放序列，供 bDownThink / CanAim / CanSprint 等复用
    self.m_CurrentSequence = self:GetPlayingSequence()

    if self:GetOwner() and self:GetOwner():IsPlayer() then
        self:AimThink()
        self:TaskThink()
        self:bDownThink()
        self:DoAnimationEvents()
        self:OwnerStatThink()
        self:DoCameraRecoil()
        self:Recover()
        self:UpdatePoseParameters()
    end

end



function SWEP:bDownThink()
    local seq = self.m_CurrentSequence
    if self:GetOwner() and self:GetOwner():KeyDown(IN_ATTACK) and seq == "Reload" and self.ReloadType == "Single" then
        self:SetCurrentTask("ReloadEnd")
    end

    if self.BoltAction and self.Animations.Rechamber and self:GetChamberAmmo() <= 0 and self:CanRechamber() and not self:IsReloading() then
        self:SetCurrentTask("Rechamber") 
    end

end

function SWEP:OwnerStatThink()
    self.m_SprintDelta = self.m_SprintDelta or 0
    local owner = self:GetOwner()
    self.m_SprintDelta = Lerp(FrameTime() * 10, self.m_SprintDelta, owner:IsSprinting() and owner:OnGround() and owner:GetVelocity():Length2D() > owner:GetWalkSpeed() and 1 or 0)
    self:SetSprintDelta(self.m_SprintDelta)
 
end


