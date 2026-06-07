function SWEP:Think()
    -- 原有逻辑...
    local owner = self:GetOwner()
    if IsValid(owner) and owner:IsPlayer() then
        self:SetWeaponHoldType(self.HoldType)
        self:UpdatePoseParameters()
        self:AimThink()
        self:TaskThink()
        self:bThink()
        self:DoAnimationEvents()
        self:DoCameraRecoil()
        self:Recover()
    end
end

function SWEP:bThink()
    local seq = self.m_CurrentSequence
    local owner = self:GetOwner()
    local task = self:GetCurrentTaskName() or ""
    local sprint = owner:IsSprinting()
    if owner and owner:KeyDown(IN_ATTACK) and seq == "Reload" and self.ReloadType == "Single" then
        self:TrySetTask("ReloadEnd")
    end

    if self.Primary.BoltAction and self.Animations.Rechamber and self:GetChamberAmmo() <= 0 and self:CanRechamber() and not self:IsReloading() and task ~= "Rechamber" then
        self:TrySetTask("Rechamber")
    end

    if owner and (not owner:KeyDown(IN_ATTACK) or self:IsEmpty()) and task ~= "Charge" then
        self.m_NextFireTime = nil
        self.s_TriggerSound = false
    end

    self.m_SprintDelta = self.m_SprintDelta or 0
    self.m_SprintDelta = Lerp(FrameTime() * 10, self.m_SprintDelta,
        sprint and owner:OnGround() and owner:GetVelocity():Length2D() > owner:GetWalkSpeed() and self:CanSprint() and 1 or 0)
    self:SetSprintDelta(self.m_SprintDelta)
end
