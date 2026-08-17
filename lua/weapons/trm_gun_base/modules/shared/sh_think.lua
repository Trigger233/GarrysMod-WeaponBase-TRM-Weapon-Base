local cvar_holster = CreateConVar("trmbase_sv_holster_on_ladder", 1, { FCVAR_ARCHIVE }, "", 0, 1)
local Tick = engine.TickInterval
function SWEP:Think()
    local dt = Tick()
    local owner = self:GetOwner()
    self:SetWeaponHoldType(self.HoldType)
    self:TaskTick()
    self:OnPostThink()
    self:DoAnimationEvents()
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

    self:NextThink(CurTime())

    if CLIENT then
        self:LocoMotion(dt)
        self:SetNextClientThink(CurTime())
    end


    return true
end

local SprintDelta = 0
function SWEP:OnPostThink()
    if CLIENT then return end
    local seq = self:GetPlayingSequence()
    local owner = self:GetOwner()
    if ! IsValid(owner) then return end
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


    SprintDelta = sprint and owner:OnGround() and self:CanSprint() and 1 or 0
    self:SetSprintDelta(SprintDelta)
    self:Sprint()
end
