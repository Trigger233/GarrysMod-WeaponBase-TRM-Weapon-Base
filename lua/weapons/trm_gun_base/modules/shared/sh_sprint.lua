local cvar_sprint_reload = CreateConVar("trmbase_allow_sprintreload", 0, { FCVAR_ARCHIVE })

function SWEP:CanSprint()
    local vm = self:GetViewModel(0)
    if not IsValid(vm) then return false end

    local owner = self:GetOwner()
    if not IsValid(owner) then return false end
    local seq = self:GetPlayingSequence() or ""
    local task = self:GetCurrentTaskName() or ""

    -- 动画是否播放完毕
    local animFinished = self:GetNextAnimationTime() <= CurTime()

    -- 如果动画没播完，有些动作不能冲刺
    if not animFinished then
        -- 换弹动画未完成时，根据 cvar 决定
        if string.find(seq, "Reload") or string.find(task, "Reload") then
            return cvar_sprint_reload:GetBool()
        end

        -- 这些动画未完成时绝对不能冲刺
        local forbidAnims = { "Deploy", "Holster", "Inspect", "Melee", "Draw" }
        for _, v in ipairs(forbidAnims) do
            if string.find(seq, v) or string.find(task, v) then
                return false
            end
        end
    end

    local blacklist = {  "Inspect" , "Holster"}
    for _, v in ipairs(blacklist) do
        if string.find(task, v) or string.find(seq, v) then
            return false
        end
    end

    return true
end

function SWEP:Sprint()
    local currentTask = self:GetCurrentTaskName() or ""
    local speed = self:GetOwner():GetVelocity():Length2D()
    local runSpeed = self:GetOwner():GetRunSpeed()
    local radio = speed / runSpeed
    local sequence = self:GetPlayingSequence()
    -- 已经在冲刺相关状态中，不要干扰
    if currentTask == "SprintIn" or currentTask == "Sprint" or currentTask == "SprintOut" or string.find(currentTask, "Reload") then
        return
    end

    if self:GetOwner():KeyDown(IN_SPEED) and self:CanSprint() and radio > 0.8 and self:GetOwner():OnGround() then
        self:TrySetTask("SprintIn")
    end
end
