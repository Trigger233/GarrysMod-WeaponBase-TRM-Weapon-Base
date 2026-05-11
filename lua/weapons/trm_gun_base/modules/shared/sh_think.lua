function SWEP:Think()
    --self:RefreshAttTable()
    --self:AimFunc()
    self:AttachmentsThink()
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

    end

    --self:IconThink()
end

function SWEP:AttachmentsThink()

end

function SWEP:bDownThink()
    local seq = self.m_CurrentSequence
    if self:GetOwner() and self:GetOwner():KeyDown(IN_ATTACK) and seq == "Reload" and self.ReloadType == "Single" then
        self:SetCurrentTask("ReloadEnd")
    end

    if self.BoltAction and self.Animations.Rechamber and self:GetChamberAmmo() <= 0 and self:CanRechamber() then
        self:SetCurrentTask("Rechamber")
    end

end

function SWEP:OwnerStatThink()
    self.m_SprintDelta = self.m_SprintDelta or 0
    self.m_SprintDelta = Lerp(FrameTime() * 10, self.m_SprintDelta, self:GetOwner():IsSprinting() and 1 or 0)
    self:SetSprintDelta(self.m_SprintDelta)

    -- IconThink 里已有相同逻辑，此处不再重复
    -- self.WepSelectIcon = Material("vgui/hud/"..self:GetClass())

    

end

function SWEP:IconThink()
    if not IsValid(self.WepSelectIcon) then
        self.WepSelectIcon = Material("vgui/hud/" .. self:GetClass())
    end
end
