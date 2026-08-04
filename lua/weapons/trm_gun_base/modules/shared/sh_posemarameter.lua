-- =============================================
-- Pose 参数更新（合并四合一，减少重复 GetViewModel / GetVelocity）
-- =============================================

function SWEP:LookupRangeCache(name)
    if not self.vm_PoseParameterRangeCache then
        self.vm_PoseParameterRangeCache = {}
    end
    if not self.vm_PoseParameterRangeCache[name] then
        local vm = self:GetViewModel()
        local min, max = vm:GetPoseParameterRange(vm:LookupPoseParameter(name))
        self.vm_PoseParameterRangeCache[name] = max
    else
        return self.vm_PoseParameterRangeCache[name]
    end
    return 1
end

local aimPose = 0
local sprintPose = 0
local emptyPose = 0
local walkPose = 0
local grip1Pose = 0
local grip2Pose = 0

function SWEP:UpdatePoseParameters(deltaTime)
    if not CLIENT then return end

    local vm = self:GetViewModel()
    if not IsValid(vm) then return end
    --vm:ClearPoseParameters()
    -- 速度乘相关（只算一次）
    local owner = self:GetOwner()
    local speed = IsValid(owner) and owner:GetVelocity():Length2D() or 0
    local runSpeed = IsValid(owner) and owner:GetRunSpeed() or 1
    local walkSpeed = IsValid(owner) and owner:GetWalkSpeed() or 1
    local dt = deltaTime *1
    -- Aim Pose
    if self.Sight and self.Sight.PoseParameter then
        aimPose = Lerp(dt * 10, aimPose, self:GetAimDelta())
        for _, Pose in pairs(self.Sight.PoseParameter) do
            vm:SetPoseParameter(Pose, aimPose)
        end
    end

    -- Sprint Pose
    if self.BasePoseParameter and self.BasePoseParameter.Sprint then
        local sprintVal = self:CanSprint() and speed > walkSpeed and self:GetSprintDelta() or 0
        sprintPose = math.Approach(sprintPose, sprintVal, dt *2 )
        for _, Pose in pairs(self.BasePoseParameter.Sprint) do
            local max = self:LookupRangeCache(Pose) or 1
            vm:SetPoseParameter(Pose, sprintPose * max)
        end
    end

    -- Empty Pose
    if self.BasePoseParameter and self.BasePoseParameter.Empty then
        emptyPose = math.Approach(emptyPose, self:IsEmpty() and 1 or 0, dt * 10)
        for _, Pose in pairs(self.BasePoseParameter.Empty) do
            vm:SetPoseParameter(Pose, emptyPose)
        end
    end

    -- Walk Pose
    if self.BasePoseParameter and self.BasePoseParameter.Walk then
        local walkVal = self:GetAimDelta() < 0.25 and (speed / walkSpeed) * (1 - self:GetSprintDelta()) or 0
        walkPose = math.Approach(walkPose, walkVal, dt *2)
        for _, Pose in pairs(self.BasePoseParameter.Walk) do
            vm:SetPoseParameter(Pose, walkPose)
        end
    end


    -- ======== 配件 Pose 参数（Grip1） ========
    grip1Pose = Lerp(dt * 5, grip1Pose or 0, (self:GetGrip1() and 1 or 0))


    -- 再设置当前配件的 pose
    if self.m_PoseParameter then
        for _, poseName in pairs(self.m_PoseParameter) do
            local val = self:LookupRangeCache(poseName) * grip1Pose
            vm:SetPoseParameter(poseName, val)
        end
    end

    -- ======== 配件 Pose 参数（Grip2） ========
    grip2Pose = Lerp(dt * 5, grip2Pose or 0, (self:GetGrip2() and 1 or 0))


    if self.m_PoseParameter2 then
        for _, poseName in pairs(self.m_PoseParameter2) do
            local val = self:LookupRangeCache(poseName) * grip2Pose
            vm:SetPoseParameter(poseName, val)
        end
    end

    --firemode 
    local firemode  = self:GetFiremodeIndex()
    local stat = self.Firemode
    if stat then
        local info = stat[firemode] 
        if info and info.PoseParameter then
            for pose , value in pairs(info.PoseParameter or {}) do
                vm:SetPoseParameter(pose,value)
            end
        end      
    end
end


function SWEP:ResetPose()
    local vm = self:GetViewModel()
    if not IsValid(vm) then return end

    vm:ClearPoseParameters()
end