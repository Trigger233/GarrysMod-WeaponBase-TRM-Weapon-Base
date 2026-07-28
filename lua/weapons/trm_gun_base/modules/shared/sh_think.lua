local cvar_holster = CreateConVar("trmbase_sv_holster_on_ladder", 1, { FCVAR_ARCHIVE }, "", 0, 1)

function SWEP:Think()
    -- 原有逻辑...
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return end
    self:SetWeaponHoldType(self.HoldType)
    self:UpdatePoseParameters()
    self:TaskTick()
    self:bThink()
    self:DoAnimationEvents()
    self:DoCameraRecoil()
    self:Recover()

    self:AimThink()
    self:BipodLogic()

    --ladder
    if (self:GetOwner():GetMoveType() == MOVETYPE_LADDER || (owner:WaterLevel() >= 2 and owner:IsSprinting())) and cvar_holster:GetBool() then
        self:AddFlag("OnLadder")
        self:Holster()
    else
        if (self:HasFlag("OnLadder")) then
            self:Deploy()
            self:RemoveFlag("OnLadder")
        end
    end

    self:TrySetTask("Rechamber")
end

local SprintDelta = 0
function SWEP:bThink()
    local seq = self:GetPlayingSequence()
    local owner = self:GetOwner()
    local task = self:GetCurrentTaskName() or ""
    local sprint = owner:IsSprinting()

    if owner and owner:KeyPressed(IN_ATTACK) and self:IsReloading() and self.ReloadType == "Single" then
        self:SetNextAnimationTime(0)
        self:TrySetTask("ReloadEnd")
    end

    if owner and (not owner:KeyDown(IN_ATTACK) or self:IsEmpty()) and task ~= "Charge" then
        self.m_NextFireTime = nil
        self.s_TriggerSound = false
    end


    SprintDelta = Lerp(50, SprintDelta,
        sprint and owner:OnGround() and owner:GetVelocity():Length2D() > owner:GetWalkSpeed() and self:CanSprint() and 1 or
        0)
    self:SetSprintDelta(SprintDelta)
end
