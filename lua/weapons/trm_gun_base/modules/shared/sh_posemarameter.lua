-- =============================================
-- Pose 参数更新（合并四合一，减少重复 GetViewModel / GetVelocity）
-- =============================================

function SWEP:UpdatePoseParameters()
    if SERVER  then return end
    local vm = self:GetViewModel()
    if not IsValid(vm) then return end

    -- 速度乘相关（只算一次）
    local owner = self:GetOwner()
    local speed = IsValid(owner) and owner:GetVelocity():Length2D() or 0
    local runSpeed = IsValid(owner) and owner:GetRunSpeed() or 1
    local walkSpeed = IsValid(owner) and owner:GetWalkSpeed() or 1
    local dt = engine.TickInterval() * 2
    -- Aim Pose
    if self.Sight and self.Sight.PoseParameter then
        self.m_AimPose = Lerp(  dt * 20, self.m_AimPose or 0, self:GetAimDelta()) or 0
        for _, Pose in pairs(self.Sight.PoseParameter) do
            vm:SetPoseParameter(Pose, self.m_AimPose)
        end
    end

    -- Sprint Pose
    if self.BasePoseParameter and self.BasePoseParameter.Sprint then
        local sprintVal = self:CanSprint() and (speed / runSpeed) > 0.7 and self:GetSprintDelta() or 0
        self.m_SprintPose = Lerp( dt , self.m_SprintPose or 0, sprintVal) or 0
        for _, Pose in pairs(self.BasePoseParameter.Sprint) do
            vm:SetPoseParameter(Pose, self.m_SprintPose)
        end
    end

    -- Empty Pose
    if self.BasePoseParameter and self.BasePoseParameter.Empty then
        self.m_EmptyPose = Lerp( dt, self.m_EmptyPose or 0, self:IsEmpty() and 1 or 0) or 0
        for _, Pose in pairs(self.BasePoseParameter.Empty) do
            vm:SetPoseParameter(Pose, self.m_EmptyPose)
        end
    end

    -- Walk Pose
    if self.BasePoseParameter and self.BasePoseParameter.Walk then
        local walkVal = self:GetAimDelta() < 0.25 and (speed / walkSpeed) * ( 1 - self:GetSprintDelta() ) or 0
        self.m_WalkPose = Lerp( dt, self.m_WalkPose or 0, walkVal) or 0
        for _, Pose in pairs(self.BasePoseParameter.Walk) do
            vm:SetPoseParameter(Pose, self.m_WalkPose)
        end
    end
end
